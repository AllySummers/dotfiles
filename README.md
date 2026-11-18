# dotfiles

> **Work in progress** — this repo is very much incomplete. Things may be missing, broken, or subject to change.

My personal dotfiles, managed with [mise](https://mise.jdx.dev) `[dotfiles]`.

## what's in here

- **zsh** — shell config, aliases, env vars, and options split across tidy files
- **mise** — tool version pinning for node, python, go, rust, bun, deno, and a bunch of CLI utilities
- **sheldon** — zsh plugin manager
- **atuin** — shell history
- **git** — base gitconfig with machine-local overrides via include
- **Cursor / VS Code / VS Code Insiders** — shared JSONC settings and editor-specific keys, merged per platform
- **AI agents** — shared APM instructions and Context7 MCP (set up manually with `mise run dotfiles:agent:setup`; use `mise run dotfiles:apm:setup` for APM only)

`mise run dotfiles:agent:setup --force` forwards `--force` to APM setup. Context7’s `ctx7` CLI installs on first use through mise; its setup may open a browser for authentication.

## agent hooks and Atuin MCP

```sh
mise run dotfiles:agent:hooks     # disclosure hooks and Atuin command recording
mise run agent:atuin-setup:hooks # install recording and disclosure hooks
mise run agent:atuin-setup:mcp   # apply MCP registrations
mise run agent:atuin-setup       # run both setup tasks in order
```

The disclosure task is TypeScript, run directly by the Node 26 already declared
in the global mise config, using its native type stripping. Hook installation is
a Bash task using jq. The Cursor Atuin adapter is also Bash, using jq, OpenSSL,
and timeout, with its hook event supplied as a Usage argument. MCP configuration,
the MCP server command, and the combined setup are TOML tasks.
`agent:atuin-mcp` is a TOML task that runs `exec atuin mcp`, inheriting the global
Atuin installation. Its stdio stays unprefixed. Agents launch it through the
absolute mise path from the user's home, so project tasks cannot shadow it.

`dotfiles:agent:setup` includes these hooks and Atuin MCP alongside the APM and
Context7 setup. Bootstrap also installs the recording hooks. Restart agent
sessions after applying; remote execution environments need their own setup.

### Disclosure metadata

Agents see disclosure metadata only when they ask for it. The instruction tells
them to run `mise -C ~ run agent:disclosure-info` before writing a footer. That
task prints a marker, and each agent's post-tool hook runs `agent:disclosure`,
which replies only when a line of the tool output is exactly the marker, so
reading files that mention it does not count. Every other tool
call gets no context, and the hook never parses the command line.

| Agent | Hook and evidence |
|-------|-------------------|
| Codex | `PostToolUse` (`Bash`) reports the model from the hook input |
| Cursor | `postToolUse` (`Shell`) reports the host's model ID and client version |
| Claude Code | `PostToolUse` (`Bash\|PowerShell`) matches `tool_use_id` to the exact assistant response in that agent's transcript |
| GitHub Copilot | `postToolUse` (`bash\|powershell`) matches `toolCallId` in the hook's own session log, falling back to its selection |

Claude's matching record supplies `message.model` and its recorded runtime
`version`. Child tool calls use the child transcript, not the parent's newest
response. Reads retry briefly for a transcript write;
a missing match stays unknown. Claude's source keeps the command under
`SessionStart` only so the hook installer can copy the rendered command; the
script returns nothing for that event.

Codex and Claude settings are merged, and merges never delete keys, so their
sources set events earlier versions used to empty arrays. Codex asks you to
trust the new `PostToolUse` hook in `/hooks`.

Observations include available session, agent, prompt, turn, and tool-call IDs.
They identify the reported model for that observation, not a hidden revision or
every model that contributed earlier. Adding hook context does not retroactively
rewrite a pending outgoing message's arguments. No shared current-model cache is
used. Auto and unresolved aliases remain unknown.

For current Codex and Copilot versions, command hooks inspect only their
own process ancestors and query that exact CLI executable. They never substitute
another installation found on PATH or label a runtime version as the GUI build.
Copilot's session-creation version is labelled historical, not current. These
log formats are internal interfaces and may change; no prompt contents are emitted.

The canonical APM disclosure instruction uses `tool-version`. The normal
`dotfiles:apm:setup` publishes that wording.

### Atuin recording and search

The setup task uses upstream `atuin hook install` for Claude Code, Codex, and
Copilot. Codex's installer also maintains its hook trust entries. Claude's
disclosure `PostToolUse` hook is appended alongside existing hooks, preserving Atuin
and user handlers instead of replacing their arrays.

Cursor uses `agent:cursor-atuin` to record shell commands with
`--author cursor --author-kind agent`. Its pending command state is keyed by
conversation and tool-call IDs, so parallel conversations cannot overwrite one
another. Mise renders the entire Cursor hooks config from
`home/.cursor/hooks.json`; edit that source to change its hooks.

Atuin MCP is registered through property merges for Codex, Claude Code, Cursor,
Copilot (also used by VS Code's native Copilot harness), and Claude Desktop on
macOS/Windows. Only the Atuin server entry is managed; existing servers remain.
This setup does not enable optional command-output or conversation capture.

References: [Atuin hooks](https://docs.atuin.sh/latest/guide/agent-hooks/),
[Atuin MCP](https://docs.atuin.sh/latest/ai/mcp/),
[mise merges](https://mise.jdx.dev/dotfiles/edits.html),
[Claude hooks](https://code.claude.com/docs/en/hooks).

## quick start

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/AllySummers/dotfiles/main/setup.sh)
```

The script installs git + mise, clones this repo to `~/.dotfiles`, seeds the global mise config symlink, and runs `mise bootstrap --yes`. Works on macOS, Arch, Ubuntu, and Debian.

Flags:

```
--repo <url>      Use a different dotfiles repo.
--branch <branch> Check out a specific branch.
```

Environment:

```
DOTFILES_SOURCE   If set to an existing directory, links it as the dotfiles
                  root instead of cloning --repo. Useful for testing local
                  uncommitted changes inside a VM or container.
```

## how it works

`mise bootstrap` does everything in order:

1. **`[bootstrap.packages]`** — installs apt/pacman/dnf packages (Linux) or brew formulae and casks (macOS)
2. **`[dotfiles]` apply** — creates symlinks and merges editor settings
3. **`[bootstrap.settings.macos.defaults]`** — writes macOS system preferences
4. **`[bootstrap.user]`** — sets the login shell to zsh
5. **`mise install [tools]`** — installs all pinned tools from the global config
6. **`[tasks.bootstrap]`** — installs atuin agent hooks and applies custom app icons on macOS

## repo layout

```
home/.zshenv                          -> ~/.zshenv
home/.zprofile                        -> ~/.zprofile
home/.zshrc                           -> ~/.zshrc
home/.gitconfig                       -> ~/.gitconfig
home/.config/zsh/                     -> ~/.config/zsh/  (symlink-each; keeps untracked secrets.zsh / local.zsh)
home/.config/sheldon/plugins.toml     -> ~/.config/sheldon/plugins.toml
home/.config/atuin/config.toml        -> ~/.config/atuin/config.toml
home/.config/mise/config.toml         -> ~/.config/mise/config.toml  (self-managed symlink)
home/.config/mise/config.<os>.toml    -> ~/.config/mise/config.<os>.toml
templates/editors/settings.jsonc (shared editor settings and portable mise path)
templates/editors/cursor.json         (Cursor update mode and theme)
templates/editors/vscode.json         (VS Code / Insiders update mode and theme)
home/.vscode/extensions/cursor-dotfiles/ -> ~/.vscode/extensions/cursor-dotfiles
                                       -> ~/.vscode-insiders/extensions/cursor-dotfiles
```

Editor settings use mise JSONC merges (`merge = true`, `format = "jsonc"`). `templates/editors/settings.jsonc` holds shared settings and renders the platform-specific `mise.binPath`; `cursor.json` and `vscode.json` hold editor-specific overrides, including `update.mode` and `workbench.colorTheme`. VS Code stable and Insiders use the same overrides. Comments and keys outside these sources stay in each editor's file. Managed keys are restored on apply; removing a key from a source leaves its existing value in the editor's file.

Editor merge entries live in `home/.config/mise/config.<os>.toml`, loaded through `auto_env`:

| Platform | Settings directory (`<editor>/User/settings.json`) |
|----------|--------------------------------------------------|
| Linux    | `~/.config/<editor>/User/settings.json` |
| macOS    | `~/Library/Application Support/<editor>/User/settings.json` |
| Windows  | `~/AppData/Roaming/<editor>/User/settings.json` |

`<editor>` is `Cursor`, `Code`, or `Code - Insiders`. Other platform-specific configuration lives in the matching `config.<os>.toml` file alongside the global `config.toml`.

Preview or apply only the editor settings on macOS:

```sh
mise dotfiles diff "$HOME/Library/Application Support/"{Cursor,Code,"Code - Insiders"}/User/settings.json
mise dotfiles apply "$HOME/Library/Application Support/"{Cursor,Code,"Code - Insiders"}/User/settings.json
```

The local **Cursor (Dotfiles)** theme is a standalone extension in
`home/.vscode/extensions/cursor-dotfiles/`. It contains only a manifest and the
combined theme JSON. Syntax rules and the default code-text colour come from
`cursor-theme.json`; all other colours, including the editor background, come
from `vscode-2026-theme.json`. The combined file is self-contained and does not
depend on either temporary source file. Mise links the directory into both VS
Code extension folders; the shared VS Code / Insiders overrides select it
automatically.

Install or update just the theme links:

```sh
mise dotfiles apply "$HOME/.vscode/extensions/cursor-dotfiles" "$HOME/.vscode-insiders/extensions/cursor-dotfiles"
```

Apply the editor settings as shown above on macOS (use the paths in the table on
other platforms), or select **Cursor (Dotfiles)** with **Preferences: Color
Theme**. Run **Developer: Reload Window** after installing or editing the theme;
restart VS Code if the new extension is not discovered. No build or Marketplace
installation is needed.

On macOS, bootstrap applies custom icons to apps in `/Applications`:

- [VS Code and Insiders](assets/vscode-icons/README.md): dark blue and green icons
  from [dhanishgajjar/vscode-icons](https://github.com/dhanishgajjar/vscode-icons).
- [Kitty](assets/kitty-icon/README.md): Outrun (Neue) from
  [k0nserv/kitty-icon](https://github.com/k0nserv/kitty-icon).

The app tasks share a mise task template, use task-local vars, and skip missing
apps. The aggregate task selects them by the `app-icon` tag. `fileicon` is a
macOS-only mise tool, installed through its npm backend. Its verified upstream
package has a scoped allowance for mise's low-download check.

```sh
mise run dotfiles:icons        # apply all three, or reapply after an app update
mise run dotfiles:icons:kitty  # apply only Kitty
```

Individual VS Code tasks are `dotfiles:icons:vscode` and
`dotfiles:icons:vscode-insiders`.

Git stores the source `.icns` assets; the tasks apply macOS custom-icon metadata.
An app update may remove that metadata. After `dotfiles:icons` finishes,
`dotfiles:icons:refresh` clears your Dock icon cache and restarts the Dock once.
Individual app tasks do not refresh the Dock. You can also run the refresh task
directly. Reopen running apps if their icons remain stale.

The Kitty asset is also linked to `~/.config/kitty/kitty.app.icns` so Kitty can
apply it at startup.

On macOS, formulae and applications are declared under `[bootstrap.packages]` in `config.macos.toml`; there is no Brewfile. Preview changes with `mise bootstrap packages apply --dry-run`, then install missing packages with `mise bootstrap packages apply`. Existing Homebrew-installed casks remain Homebrew-owned, so use Homebrew or the app updater to maintain them.

## machine-local overrides (not tracked)

```
~/.config/zsh/secrets.zsh   # secrets, API keys
~/.config/zsh/local.zsh     # machine-specific aliases / PATH additions
~/.gitconfig.local          # per-machine git identity / signing key
```

## license

MIT — do whatever you want with it.

That said, if you do something cool with this stuff, I'd genuinely love to hear about it. No obligation, just share if you feel like it. :)
