/**
 * Custom completion handlers for mise tools.
 *
 * Add entries here to override registry.toml commands or handle tools that need
 * special logic (fetching from a URL, reading bundled files, etc.).
 *
 * Keys are mise tool names as reported by `mise ls --json` (e.g. "gh", "mise",
 * "mise-completions-sync").
 *
 * Each handler receives: - tool — the active mise tool info for this tool -
 * shell — "zsh" | "bash" | "fish"
 *
 * Return the completion file contents as a string, or null to skip that shell.
 */

import type { CustomCompletionFn } from './shared.ts';

export const handlers: Record<string, CustomCompletionFn> = {
  // ── Example: fetch completions from a remote URL ───────────────────────────
  // "my-tool": async (tool, shell) => {
  //   if (shell !== "zsh") return null;
  //   const res = await fetch(
  //     `https://example.com/completions/v${tool.version}/my-tool.zsh`,
  //   );
  //   return res.ok ? res.text() : null;
  // },
  // ── Example: read completions bundled inside the tool's install directory ──
  // "another-tool": async (tool, shell) => {
  //   const paths: Record<Shell, string> = {
  //     zsh:  `${tool.install_path}/completions/_another-tool`,
  //     bash: `${tool.install_path}/completions/another-tool.bash`,
  //     fish: `${tool.install_path}/completions/another-tool.fish`,
  //   };
  //   try {
  //     return await Deno.readTextFile(paths[shell]);
  //   } catch {
  //     return null;
  //   }
  // },
};
