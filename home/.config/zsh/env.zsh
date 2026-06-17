export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-$XDG_CACHE_HOME/zsh}"
export ZSH_DATA_DIR="${ZSH_DATA_DIR:-$XDG_DATA_HOME/zsh}"
export ZSH_STATE_DIR="${ZSH_STATE_DIR:-$XDG_STATE_HOME/zsh}"

export ZSH_COMPDUMP_FILE="${ZSH_COMPDUMP_FILE:-$ZSH_CACHE_DIR/zcompdump-${HOST:-zsh}}"
export BASH_COMPDUMP_FILE="${BASH_COMPDUMP_FILE:-$ZSH_CACHE_DIR/bcompdump-${HOST:-zsh}}"
export _comp_dumpfile="$ZSH_COMPDUMP_FILE"
export ZSH_DISABLE_COMPFIX=true

export HISTFILE="${HISTFILE:-$ZSH_STATE_DIR/history}"
export HISTSIZE="${HISTSIZE:-10000000}"
export SAVEHIST="${SAVEHIST:-$HISTSIZE}"

export DO_NOT_TRACK=1
export DO_NO_TRACK=1
export MISE_CONFIG_DIR="${MISE_CONFIG_DIR:-$XDG_CONFIG_HOME/mise}"
export MISE_CACHE_DIR="${MISE_CACHE_DIR:-$XDG_CACHE_HOME/mise}"
export MISE_DATA_DIR="${MISE_DATA_DIR:-$XDG_DATA_HOME/mise}"
export MISE_STATE_DIR="${MISE_STATE_DIR:-$XDG_STATE_HOME/mise}"
export MISE_TRUSTED_CONFIG_PATHS="${MISE_TRUSTED_CONFIG_PATHS:-$MISE_CONFIG_DIR/config.toml:~/.config/mise/config.toml}"

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export EDITOR="${EDITOR:-hx}"
export PAGER="${PAGER:-bat}"
export LESS="${LESS:--R}"
export FX_SHOW_SIZE=true
export FZF_CTRL_T_COMMAND="${FZF_CTRL_T_COMMAND:-true}"
export FZF_ALT_C_COMMAND="${FZF_ALT_C_COMMAND:-true}"

homebrew_prefix="${HOMEBREW_PREFIX:-/opt/homebrew}"

if [[ -d "$homebrew_prefix" ]]; then
  export HOMEBREW_PREFIX="$homebrew_prefix"
  export HOMEBREW_REPOSITORY="${HOMEBREW_REPOSITORY:-$HOMEBREW_PREFIX}"
  export HOMEBREW_CELLAR="${HOMEBREW_CELLAR:-$HOMEBREW_PREFIX/Cellar}"
  export HOMEBREW_OPT="${HOMEBREW_OPT:-$HOMEBREW_PREFIX/opt}"
  export HOMEBREW_LIB="${HOMEBREW_LIB:-$HOMEBREW_PREFIX/lib}"
  export HOMEBREW_BUNDLE_DUMP_DESCRIBE="${HOMEBREW_BUNDLE_DUMP_DESCRIBE:-true}"
  export HOMEBREW_BUNDLE_FILE_GLOBAL="${HOMEBREW_BUNDLE_FILE_GLOBAL:-$HOME/.Brewfile}"
  export TERMINFO="$HOMEBREW_OPT/ncurses/share/terminfo:/Applications/kitty.app/Contents/Resources/terminfo"
fi

path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/.bin"
  "$homebrew_prefix/bin"
  "$homebrew_prefix/sbin"
  "$homebrew_prefix/opt/util-linux/bin"
  "$homebrew_prefix/opt/util-linux/sbin"
  "/usr/local/bin"
  "/usr/local/sbin"
  "/opt/local/bin"
  "/opt/local/sbin"
  $path
)

fpath=(
  "$XDG_DATA_HOME/mise-completions/zsh"
  "$ZSH_CONFIG_DIR/completions"
  "$homebrew_prefix/share/zsh/site-functions"
  "$homebrew_prefix/share/zsh/functions"
  $fpath
)

manpath=(
  "$homebrew_prefix/share/man"
  "/opt/local/man"
  $manpath
)

infopath=(
  "$homebrew_prefix/share/info"
  $infopath
)

pkg_config_path=(
  "$homebrew_prefix/lib/pkgconfig"
  "$homebrew_prefix/opt/ncurses/lib/pkgconfig"
  $pkg_config_path
)

if [[ ! -d "$homebrew_prefix" ]]; then
  path=(${path:#"$homebrew_prefix"/*})
  fpath=(${fpath:#"$homebrew_prefix"/*})
  manpath=(${manpath:#"$homebrew_prefix"/*})
  infopath=(${infopath:#"$homebrew_prefix"/*})
  pkg_config_path=(${pkg_config_path:#"$homebrew_prefix"/*})
fi

unset homebrew_prefix

source "$ZSH_CONFIG_DIR/editors.zsh"

if [[ -z "${BROWSER:-}" ]]; then
  if command -v open >/dev/null 2>&1; then
    export BROWSER="open"
  elif command -v xdg-open >/dev/null 2>&1; then
    export BROWSER="xdg-open"
  fi
fi

# remove empty paths
path=(${path:#})

if [[ -r "$ZSH_CONFIG_DIR/secrets.zsh" ]]; then
  source "$ZSH_CONFIG_DIR/secrets.zsh"
fi