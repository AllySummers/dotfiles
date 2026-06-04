import { dirname, join } from 'jsr:@std/path@1.1.5';
import { parse as parseToml } from 'jsr:@std/toml@1.0.11';
import type { CLIOptions, CustomCompletionFn, MiseToolInfo, Shell } from './shared.ts';

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

/**
 * global — discovers tools from `mise ls --global`.
 * local  — discovers tools from `mise ls --local` in an optional cwd; callers must
 *          supply a separate outDir (not the shared global completions dir).
 */
export type DiscoverMode =
  | { type: 'global' }
  | { type: 'local'; cwd?: string };

const ALL_SHELLS: Shell[] = ['zsh', 'bash', 'fish'];

// ── Shell filename convention ─────────────────────────────────────────────────

const completionFile = (tool: string, shell: Shell): string => {
  const base = tool.split('/').at(-1)!.replaceAll('@', '');
  if (shell === 'zsh') return `_${base}`;
  if (shell === 'fish') return `${base}.fish`;
  return base;
};

// ── Subprocess helper ─────────────────────────────────────────────────────────

const exec = async (
  argv: string[],
  opts?: { cwd?: string },
): Promise<{ out: string; ok: boolean }> => {
  try {
    const proc = new Deno.Command(argv[0]!, {
      args: argv.slice(1),
      stdout: 'piped',
      stderr: 'null',
      cwd: opts?.cwd,
    });
    const result = await proc.output();
    return { out: new TextDecoder().decode(result.stdout), ok: result.success };
  } catch {
    return { out: '', ok: false };
  }
};

// ── State management ──────────────────────────────────────────────────────────

const readState = async (statePath: string): Promise<State> => {
  try {
    return JSON.parse(await Deno.readTextFile(statePath));
  } catch {
    return { schema_version: 1, tools: {} };
  }
};

const saveState = async (s: State, statePath: string): Promise<void> => {
  await Deno.mkdir(dirname(statePath), { recursive: true });
  await Deno.writeTextFile(statePath, `${JSON.stringify(s, null, 2)}\n`);
};

// ── Registry ──────────────────────────────────────────────────────────────────

const loadRegistry = async (registryPath: string): Promise<Registry> =>
  parseToml(
    await Deno.readTextFile(registryPath),
  ) as unknown as Registry;

const resolveCmd = (tool: string, shell: Shell, reg: Registry): string | null => {
  const entry = reg.tools[tool];
  if (!entry) return null;
  const map: ShellMap = typeof entry === 'string' ? (reg.patterns[entry] ?? {}) : entry;
  const tmpl = map[shell];
  return tmpl != null ? tmpl.replaceAll('{}', tool) : null;
};

// ── Custom completions ────────────────────────────────────────────────────────

const loadCustom = async (): Promise<Record<string, CustomCompletionFn>> => {
  return (await import('./custom-completions.ts')).handlers;
};

// ── Tool discovery ────────────────────────────────────────────────────────────

const discoverTools = async (
  mode: DiscoverMode = { type: 'global' },
): Promise<Record<string, MiseToolInfo>> => {
  const args = [
    'mise',
    'ls',
    mode.type === 'global' ? '--global' : '--local',
    '--json',
  ];

  const opts = { cwd: mode.type === 'local' ? mode.cwd : undefined };

  const { out, ok } = await exec(args, opts);
  if (!ok || !out.trim()) return {};
  const raw: Record<string, MiseToolInfo[]> = JSON.parse(out);
  return Object.fromEntries(
    Object.entries(raw).flatMap(([name, list]) => {
      const active = list.find((t) => t.active) ?? list.at(-1);
      return active ? [[name, active]] : [];
    }),
  );
};

/**
 * mise itself doesn't appear in `mise ls` since it IS the runtime. Detect the
 * running version via `mise --version`. stdout example: "2026.5.6 macos-arm64
 * (2026-05-11)"
 */
const addMiseSelf = async (tools: Record<string, MiseToolInfo>): Promise<void> => {
  const { out, ok } = await exec(['mise', '--version']);
  if (!ok) return;
  const version = out.trim().split(/\s+/).at(0) ?? '';
  tools.mise = { version, install_path: '', installed: true, active: true };
};

// ── Write completions ─────────────────────────────────────────────────────────

const writeCompletion = async (
  tool: string,
  shell: Shell,
  content: string,
  baseDir: string,
): Promise<void> => {
  const dir = join(baseDir, shell);
  await Deno.mkdir(dir, { recursive: true });
  await Deno.writeTextFile(join(dir, completionFile(tool, shell)), content);
};

// ── Main ──────────────────────────────────────────────────────────────────────

export const cli = async (
  { taskDir, statePath, completionsPath, force = false, verbose = false, shell }: CLIOptions,
) => {
  const shellName = shell ?? Deno.env.get('SHELL')?.split('/').at(-1);
  if (!shellName || !(ALL_SHELLS as string[]).includes(shellName)) {
    throw new Error(
      `Cannot determine shell: $SHELL=${
        Deno.env.get('SHELL') ?? '(unset)'
      }, pass --shell explicitly`,
    );
  }
  const shells = [shellName as Shell];

  const log = (...msg: unknown[]) => {
    if (verbose) console.log(...msg);
  };

  const [state, registry, custom, tools] = await Promise.all([
    readState(statePath),
    loadRegistry(join(taskDir, 'registry.toml')),
    loadCustom(),
    discoverTools({ type: 'global' }),
  ]);

  await addMiseSelf(tools);

  let updated = 0, skipped = 0, failed = 0;

  for (const [name, info] of Object.entries(tools)) {
    if (!force && state.tools[name] === info.version) {
      log(`  skip   ${name}@${info.version}`);
      skipped++;
      continue;
    }

    let written = false;
    let tried = false;

    for (const sh of shells) {
      let content: string | null = null;

      if (custom[name]) {
        tried = true;
        try {
          content = await custom[name](info, sh);
          if (content !== null) log(`  custom ${name} (${sh})`);
        } catch (error) {
          log(`  error  ${name} custom handler (${sh}): ${error}`);
          continue;
        }
      }

      if (content === null) {
        const cmd = resolveCmd(name, sh, registry);
        if (!cmd) {
          log(`  no-cmd ${name} (${sh})`);
          continue;
        }
        tried = true;
        const { out, ok } = await exec(cmd.split(/\s+/));
        if (!ok || !out.trim()) {
          log(`  fail   ${name} (${sh}): ${cmd}`);
          continue;
        }
        content = out;
      }

      if (content?.trim()) {
        await writeCompletion(name, sh, content, completionsPath);
        log(`  wrote  ${name}@${info.version} → ${sh}/${completionFile(name, sh)}`);
        written = true;
      }
    }

    if (written) {
      state.tools[name] = info.version;
      updated++;
    } else if (tried) {
      console.warn(`  WARN   ${name}: completion generation failed for all shells`);
      failed++;
    }
  }

  await saveState(state, statePath);

  const parts = [`updated: ${updated}`, `skipped: ${skipped}`];
  if (failed) parts.push(`failed: ${failed}`);
  console.log(`sync-completions: ${parts.join(', ')}`);
};
