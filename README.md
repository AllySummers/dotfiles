# dotfiles

> **Work in progress** — this repo is very much incomplete. Things may be missing, broken, or subject to change.

My personal dotfiles, managed with [mise](https://mise.jdx.dev) `[dotfiles]`.

## what's in here

- **zsh** — shell config, aliases, env vars, and options split across tidy files
- **mise** — tool version pinning for node, python, go, rust, bun, deno, and a bunch of CLI utilities
- **sheldon** — zsh plugin manager
- **atuin** — shell history
- **git** — base gitconfig with machine-local overrides via include
- **Cursor** — editor settings (Tera template, rendered per platform)

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
2. **`[dotfiles]` apply** — creates symlinks and renders the Cursor settings template
3. **`[bootstrap.macos.defaults]`** — writes macOS system preferences
4. **`[bootstrap.user]`** — sets the login shell to zsh
5. **`mise install [tools]`** — installs all pinned tools from the global config
6. **`[tasks.bootstrap]`** — installs atuin agent hooks and GUI casks

## repo layout

```
home/.zshenv                          -> ~/.zshenv
home/.zprofile                        -> ~/.zprofile
home/.zshrc                           -> ~/.zshrc
home/.gitconfig                       -> ~/.gitconfig
home/.Brewfile                        -> ~/.Brewfile
home/.config/zsh/                     -> ~/.config/zsh/  (symlink-each; keeps untracked secrets.zsh / local.zsh)
home/.config/sheldon/plugins.toml     -> ~/.config/sheldon/plugins.toml
home/.config/atuin/config.toml        -> ~/.config/atuin/config.toml
home/.config/mise/config.toml         -> ~/.config/mise/config.toml  (self-managed symlink)
home/.config/Cursor/User/settings.json.tmpl  (Tera template, rendered per platform — see below)
```

The Cursor settings template is rendered to a platform-specific path by mise:

| Platform | Target path |
|----------|-------------|
| Linux    | `~/.config/Cursor/User/settings.json` |
| macOS    | `~/Library/Application Support/Cursor/User/settings.json` |
| Windows  | `~/AppData/Roaming/Cursor/User/settings.json` |

Platform-specific dotfiles entries live in the matching `config.<os>.toml` file alongside the global `config.toml`.

## machine-local overrides (not tracked)

```
~/.config/zsh/secrets.zsh   # secrets, API keys
~/.config/zsh/local.zsh     # machine-specific aliases / PATH additions
~/.gitconfig.local          # per-machine git identity / signing key
```

## license

MIT — do whatever you want with it.

That said, if you do something cool with this stuff, I'd genuinely love to hear about it. No obligation, just share if you feel like it. :)
