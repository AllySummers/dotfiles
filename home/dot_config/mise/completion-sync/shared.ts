export type Shell = 'zsh' | 'bash' | 'fish';

export interface CLIOptions {
  home: string;
  taskDir: string;
  statePath: string;
  completionsPath: string;
  force?: boolean;
  verbose?: boolean;
  shell?: Shell;
}

export interface MiseToolInfo {
  version: string;
  requested_version?: string;
  install_path: string;
  source?: { type: string; path: string };
  installed: boolean;
  active: boolean;
}

export type CustomCompletionFn = (tool: MiseToolInfo, shell: Shell) => Promise<string | null>;
