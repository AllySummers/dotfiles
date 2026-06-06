import { dirname, join } from 'jsr:@std/path@1.1.5';
import { parse as parseToml } from 'jsr:@std/toml@1.0.11';
import type { CLIOptions, MiseToolInfo, Shell } from './shared.ts';
import { handlers as custom } from './custom-completions.ts';

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

// ── Shell filename convention ─────────────────────────────────────────────────

const completionFile = (tool: string, shell: Shell): string => {
  const base = tool.split('/').at(-1)!.replaceAll('@', '');
  if (shell === 'zsh') {
    return `_${base}`;
  }
  if (shell === 'fish') {
    return `${base}.fish`;
  }
  return base;
};

// ── Subprocess helper ─────────────────────────────────────────────────────────

const exec = async (
  [cmd, ...args]: string[],
  opts?: { cwd?: string },
): Promise<{ out: string; ok: boolean }> => {
  if (!cmd) {
    throw new Error('cmd is required');
  }
  try {
    const proc = new Deno.Command(cmd, {
      args,
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
  if (!entry) {
    return null;
  }
  const map: ShellMap = typeof entry === 'string' ? (reg.patterns[entry] ?? {}) : entry;
  const tmpl = map[shell];
  return tmpl != null ? tmpl.replaceAll('{}', tool) : null;
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
  if (!ok || !out.trim()) {
    return {};
  }
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
  if (!ok) {
    return;
  }
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
  const log = (...msg: unknown[]) => {
    if (verbose) {
      console.log(...msg);
    }
  };

  const [state, registry, tools] = await Promise.all([
    readState(statePath),
    loadRegistry(join(taskDir, 'registry.toml')),
    discoverTools({ type: 'global' }),
  ]);

  await addMiseSelf(tools);

  const statuses = await Promise.all(
    Object.entries(tools).map(async ([name, info]) => {
      if (!force && state.tools[name] === info.version) {
        log(`  skip   ${name}@${info.version}`);
        return 'skipped' as const;
      }

      let content: string | null = null;

      if (custom[name]) {
        try {
          content = await custom[name](info, shell);
          if (content !== null) {
            log(`  custom ${name} (${shell})`);
          }
        } catch (error) {
          log(`  error  ${name} custom handler (${shell}): ${error}`);
          console.warn(`  WARN   ${name}: completion generation failed`);
          return 'failed' as const;
        }
      }

      if (content === null) {
        const cmd = resolveCmd(name, shell, registry);
        if (!cmd) {
          log(`  no-cmd ${name} (${shell})`);
          if (custom[name]) {
            console.warn(`  WARN   ${name}: completion generation failed`);
            return 'failed' as const;
          }
          return null;
        }
        const { out, ok } = await exec(cmd.split(/\s+/));
        if (!ok || !out.trim()) {
          log(`  fail   ${name} (${shell}): ${cmd}`);
          console.warn(`  WARN   ${name}: completion generation failed`);
          return 'failed' as const;
        }
        content = out;
      }

      if (!content.trim()) {
        console.warn(`  WARN   ${name}: completion generation failed`);
        return 'failed' as const;
      }

      await writeCompletion(name, shell, content, completionsPath);
      log(`  wrote  ${name}@${info.version} → ${shell}/${completionFile(name, shell)}`);
      state.tools[name] = info.version;
      return 'updated' as const;
    }),
  );

  await saveState(state, statePath);

  const count = (s: string) => statuses.filter((r) => r === s).length;
  const parts = [`updated: ${count('updated')}`, `skipped: ${count('skipped')}`];
  if (count('failed')) {
    parts.push(`failed: ${count('failed')}`);
  }
  console.log(`sync-completions: ${parts.join(', ')}`);
};
