export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

typeset -UTx PATH path :
typeset -UTx FPATH fpath :
typeset -UTx MANPATH manpath :
typeset -UTx INFOPATH infopath :
typeset -UTx PKG_CONFIG_PATH pkg_config_path :

export ZDOTDIR="$HOME"
export ZSH_HOME="$HOME/.zsh"
export XDG_CONFIG_HOME="$HOME/.config"
export KERNEL_NAME=$(uname | tr '[:upper:]' '[:lower:]')

export ZSH="$ZSH_HOME/oh-my-zsh"
export ZSH_CACHE="$ZSH_HOME/cache"
export ZSH_COMPDUMP=$ZSH_CACHE/zcompdump-$HOST
export ZSH_COMPDUMP_FILE="$ZSH_CACHE/zcompdump"
export BASH_COMPDUMP_FILE="$ZSH_CACHE/bcompdump"
export _comp_dumpfile="$ZSH_COMPDUMP_FILE"
export ZSH_DISABLE_COMPFIX="true"
export ZSH_CACHE_DIR="$ZSH_HOME/cache"
export HISTFILE="$ZSH_HOME/zsh_history"
export HISTSIZE=10000000
export SAVEHIST="$HISTSIZE"

# https://gist.github.com/bulletinmybeard/8a3ad86c0a31fb7b3e55d659b7a6f446
# gets rid of annoying %
export PROMPT_CR
export PROMPT_SP
export PROMPT_EOL_MARK=''
