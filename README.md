# dotfiles

Compact chezmoi-ready shell dotfiles.

This repo uses `.chezmoiroot` with `home/` as the managed home tree:

```text
home/dot_zshenv                  -> ~/.zshenv
home/dot_zprofile                -> ~/.zprofile
home/dot_zshrc                   -> ~/.zshrc
home/dot_gitconfig               -> ~/.gitconfig
home/dot_config/zsh/aliases.zsh  -> ~/.config/zsh/aliases.zsh
home/dot_config/zsh/env.zsh      -> ~/.config/zsh/env.zsh
home/dot_config/zsh/options.zsh  -> ~/.config/zsh/options.zsh
home/dot_config/sheldon          -> ~/.config/sheldon
home/dot_config/mise             -> ~/.config/mise
home/dot_config/atuin            -> ~/.config/atuin
```

`dot_zshenv` loads the shared environment and runs `mise hook-env` for
non-interactive shells so editor and agent commands get project env/PATH.
Interactive shells use `mise activate zsh` from `dot_zshrc`.

Machine-local overrides live in ignored files:

```text
home/dot_config/zsh/secrets.zsh
home/dot_config/zsh/local.zsh
home/dot_gitconfig.local
```

`dot_gitconfig` is tracked and `[include]`s `~/.gitconfig.local` last, so
per-machine git settings (signing key, credential helpers) override the base.
Git does not merge `~/.gitconfig` with `~/.config/git/config` — if the former
exists the latter is ignored — so the explicit include is required.
