# Login-shell session setup. Keep interactive behavior in .zshrc.

# macOS's /etc/zprofile runs `path_helper` before this file, which rebuilds
# PATH from /etc/paths(.d) and shoves /usr/bin etc. ahead of Homebrew,
# undoing the ordering env.zsh set up in .zshenv. Re-source it here (the
# first user-controlled file after path_helper runs) to restore our order.
# `typeset -U` in .zshenv keeps this idempotent/deduped.
source "$ZSH_CONFIG_DIR/env.zsh"
