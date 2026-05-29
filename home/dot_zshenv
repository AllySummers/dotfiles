# Minimal environment for every zsh invocation.

typeset -UTx PATH path :
typeset -UTx FPATH fpath :
typeset -UTx MANPATH manpath :
typeset -UTx INFOPATH infopath :
typeset -UTx PKG_CONFIG_PATH pkg_config_path :

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export ZSH_CONFIG_DIR="${ZSH_CONFIG_DIR:-$XDG_CONFIG_HOME/zsh}"

source "$ZSH_CONFIG_DIR/env.zsh"

if ! [[ -o interactive ]] && command -v mise >/dev/null 2>&1; then
  eval "$(mise hook-env -s zsh)"
fi