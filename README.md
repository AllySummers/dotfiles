# dotfiles

> **Work in progress** — this repo is very much incomplete. Things may be missing, broken, or subject to change.

My personal dotfiles, managed with [chezmoi](https://chezmoi.io).

## what's in here

- **zsh** — shell config, aliases, env vars, and options split across tidy files
- **mise** — tool version pinning for node, python, go, rust, bun, deno, and a bunch of CLI utilities
- **sheldon** — zsh plugin manager
- **atuin** — shell history
- **git** — base gitconfig with machine-local overrides via include
- **Cursor** — editor settings template

## quick start

```sh
bash <(curl -fsSL https://raw.githubusercontent.com/AllySummers/dotfiles/main/setup.sh)
```

The script installs Homebrew (macOS), bootstraps mise, applies the dotfiles via chezmoi, and runs `mise install`. Works on macOS, Arch, Ubuntu, and Debian.

Flags:

```
--gui             Also install GUI apps (macOS casks). Off by default.
--repo <url>      Use a different dotfiles repo.
--branch <branch> Check out a specific branch.
```

## repo layout

```
home/dot_zshenv                  -> ~/.zshenv
home/dot_zprofile                -> ~/.zprofile
home/dot_zshrc                   -> ~/.zshrc
home/dot_gitconfig               -> ~/.gitconfig
home/dot_config/zsh/             -> ~/.config/zsh/
home/dot_config/sheldon/         -> ~/.config/sheldon/
home/dot_config/mise/            -> ~/.config/mise/
home/dot_config/atuin/           -> ~/.config/atuin/
```

Machine-local overrides (not tracked):

```
~/.config/zsh/secrets.zsh
~/.config/zsh/local.zsh
~/.gitconfig.local
```

## license

MIT — do whatever you want with it.

That said, if you do something cool with this stuff, I'd genuinely love to hear about it. No obligation, just share if you feel like it. :)
