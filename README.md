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
6. **`[tasks.bootstrap]`** — installs atuin agent hooks

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
```

Editor settings use mise JSONC merges (`merge = true`, `format = "jsonc"`). `templates/editors/settings.jsonc` holds shared settings and renders the platform-specific `mise.binPath`; `cursor.json` and `vscode.json` contain only `update.mode` and `workbench.colorTheme`. VS Code stable and Insiders use the same overrides. Comments and keys outside these sources stay in each editor's file. Managed keys are restored on apply; removing a key from a source leaves its existing value in the editor's file.

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
