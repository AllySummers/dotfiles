#!/usr/bin/env node
/* eslint-disable no-console -- CLI script: console output is intentional */
//MISE description="Sync shell completions for all installed mise tools"
//MISE alias="sync-completions"
//USAGE flag "--force -f" help="Regenerate all completions regardless of cached version"
//USAGE flag "--verbose -v" help="Print per-tool status"
//USAGE flag "--shell <shell>" help="Limit sync to a specific shell" {
//USAGE   choices "zsh" "bash" "fish"
//USAGE }

import { execFile as execFileCb } from 'node:child_process';
import { access, mkdir, readFile, writeFile } from 'node:fs/promises';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { promisify } from 'node:util';
import { parse as parseToml } from '@std/toml';

const execFileAsync = promisify(execFileCb);

// ── Public types (imported by custom-completions.ts) ─────────────────────────

export interface MiseToolInfo {
  version: string;
  requested_version?: string;
  install_path: string;
  source?: { type: string; path: string };
  installed: boolean;
  active: boolean;
}

export type Shell = 'zsh' | 'bash' | 'fish';

/**
 * Return the completion file content for a given tool + shell, or null to skip
 * that shell entirely.
 */
export type CustomCompletionFn = (
  tool: MiseToolInfo,
  shell: Shell,
) => Promise<string | null>;

// ── Internal types ────────────────────────────────────────────────────────────

interface ShellMap {
  zsh?: string;
  bash?: string;
  fish?: string;
}

interface Registry {
  schema_version: number;
  patterns: Record<string, ShellMap>;
  tools: Record<string, string | ShellMap>;
}

interface State {
  schema_version: 1;
  tools: Record<string, string>;
}

// ── Config ────────────────────────────────────────────────────────────────────

const TASK_DIR = import.meta.dirname ?? '';
const ALL_SHELLS: Shell[] = ['zsh', 'bash', 'fish'];

// eslint-disable-next-line n/no-process-env
const { HOME = '', usage_force, usage_shell, usage_verbose } = process.env;

const BASE_DIR = join(HOME, '.local', 'share', 'mise-completions');
const STATE_PATH = join(BASE_DIR, '.state.json');

// Respect env vars set by the `usage` CLI when available, fall back to raw args
const args = process.argv.slice(2);

const force =
  usage_force === 'true' || args.some((a) => a === '--force' || a === '-f');

const verbose =
  usage_verbose === 'true' || args.some((a) => a === '--verbose' || a === '-v');

const shellFlagIdx = args.indexOf('--shell');
const shellArg =
  usage_shell || (shellFlagIdx !== -1 ? args[shellFlagIdx + 1] : undefined);

const SHELLS: Shell[] =
  shellArg && (ALL_SHELLS as string[]).includes(shellArg)
    ? [shellArg as Shell]
    : ALL_SHELLS;

// ── Logging ───────────────────────────────────────────────────────────────────

const log = (...msg: unknown[]) => {
  if (verbose) {
    console.log(...msg);
  }
};

// ── Shell filename convention ─────────────────────────────────────────────────

function completionFile(tool: string, shell: Shell): string {
  // Use only the last path segment so scoped packages don't break filenames
  const base = (tool.split('/').at(-1) ?? tool).replaceAll('@', '');
  if (shell === 'zsh') {
    return `_${base}`;
  }
  if (shell === 'fish') {
    return `${base}.fish`;
  }
  return base;
}

// ── Subprocess helper ─────────────────────────────────────────────────────────

async function exec(argv: string[]): Promise<{ out: string; ok: boolean }> {
  const [cmd, ...cmdArgs] = argv;
  try {
    const { stdout } = await execFileAsync(cmd, cmdArgs, { encoding: 'utf8' });
    return { out: stdout, ok: true };
  } catch (error: unknown) {
    const e = error as { stdout?: string };
    return { out: e.stdout ?? '', ok: false };
  }
}

// ── State management ──────────────────────────────────────────────────────────

async function readState(): Promise<State> {
  try {
    return JSON.parse(await readFile(STATE_PATH, 'utf8')) as State;
  } catch {
    return { schema_version: 1, tools: {} };
  }
}

async function saveState(s: State): Promise<void> {
  await mkdir(BASE_DIR, { recursive: true });
  await writeFile(STATE_PATH, `${JSON.stringify(s, null, 2)}\n`, 'utf8');
}

// ── Registry ──────────────────────────────────────────────────────────────────

async function loadRegistry(): Promise<Registry> {
  return parseToml(
    await readFile(join(TASK_DIR, 'registry.toml'), 'utf8'),
  ) as unknown as Registry;
}

function resolveCmd(tool: string, shell: Shell, reg: Registry): string | null {
  const entry = reg.tools[tool];
  if (!entry) {
    return null;
  }
  const map: ShellMap =
    typeof entry === 'string' ? (reg.patterns[entry] ?? {}) : entry;
  const tmpl = map[shell];
  return tmpl !== undefined ? tmpl.replaceAll('{}', tool) : null;
}

// ── Custom completions ────────────────────────────────────────────────────────

async function loadCustom(): Promise<Record<string, CustomCompletionFn>> {
  const path = join(TASK_DIR, 'custom-completions.ts');
  try {
    await access(path);
    const mod = await import(pathToFileURL(path).href);
    return (mod.default ?? {}) as Record<string, CustomCompletionFn>;
  } catch {
    return {};
  }
}

// ── Tool discovery ────────────────────────────────────────────────────────────

async function discoverTools(): Promise<Record<string, MiseToolInfo>> {
  const { out, ok } = await exec(['mise', 'ls', '--global', '--json']);
  if (!ok || !out.trim()) {
    return {};
  }
  const raw = JSON.parse(out) as Record<string, MiseToolInfo[]>;
  return Object.fromEntries(
    Object.entries(raw).flatMap(([name, list]) => {
      const active = list.find((t) => t.active) ?? list.at(-1);
      return active ? [[name, active]] : [];
    }),
  );
}

/**
 * mise itself doesn't appear in `mise ls` since it IS the runtime. Detect the
 * running version via `mise --version`. stdout example: "2026.5.6 macos-arm64
 * (2026-05-11)"
 */
async function addMiseSelf(tools: Record<string, MiseToolInfo>): Promise<void> {
  const { out, ok } = await exec(['mise', '--version']);
  if (!ok) {
    return;
  }
  const [version = ''] = out.trim().split(/\s+/);
  tools.mise = { version, install_path: '', installed: true, active: true };
}

// ── Write completions ─────────────────────────────────────────────────────────

async function writeCompletion(
  tool: string,
  shell: Shell,
  content: string,
): Promise<void> {
  const dir = join(BASE_DIR, shell);
  await mkdir(dir, { recursive: true });
  await writeFile(join(dir, completionFile(tool, shell)), content, 'utf8');
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main(): Promise<void> {
  const [state, registry, custom, tools] = await Promise.all([
    readState(),
    loadRegistry(),
    loadCustom(),
    discoverTools(),
  ]);

  await addMiseSelf(tools);

  let failed = 0,
    skipped = 0,
    updated = 0;

  for (const [name, info] of Object.entries(tools)) {
    if (!force && state.tools[name] === info.version) {
      log(`  skip   ${name}@${info.version}`);
      skipped += 1;
      continue;
    }

    let written = false;
    let tried = false;

    for (const shell of SHELLS) {
      let content: string | null = null;

      // 1. Custom handler takes priority over the registry
      if (Object.hasOwn(custom, name)) {
        tried = true;
        try {
          content = await custom[name](info, shell);
          if (content !== null) {
            log(`  custom ${name} (${shell})`);
          }
        } catch (error: unknown) {
          log(`  error  ${name} custom handler (${shell}): ${String(error)}`);
          continue;
        }
      }

      // 2. Fall back to the registry command
      if (content === null) {
        const cmd = resolveCmd(name, shell, registry);
        if (!cmd) {
          log(`  no-cmd ${name} (${shell})`);
          continue;
        }
        tried = true;
        const { out, ok } = await exec(cmd.split(/\s+/));
        if (!ok || !out.trim()) {
          log(`  fail   ${name} (${shell}): ${cmd}`);
          continue;
        }
        content = out;
      }

      if (content.trim()) {
        await writeCompletion(name, shell, content);
        log(
          `  wrote  ${name}@${info.version} → ${shell}/${completionFile(name, shell)}`,
        );
        written = true;
      }
    }

    if (written) {
      state.tools[name] = info.version;
      updated += 1;
    } else if (tried) {
      console.warn(
        `  WARN   ${name}: completion generation failed for all shells`,
      );
      failed += 1;
    }
    // Not in registry + no custom handler → silently ignored
  }

  await saveState(state);

  const parts = [`updated: ${updated}`, `skipped: ${skipped}`];
  if (failed) {
    parts.push(`failed: ${failed}`);
  }
  console.log(`sync-completions: ${parts.join(', ')}`);
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
