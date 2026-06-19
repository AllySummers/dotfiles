[[ -o interactive ]] || return 0

mkdir -p "$ZSH_CACHE_DIR/completions" "$ZSH_STATE_DIR"

autoload -Uz colors add-zsh-hook compinit bashcompinit
colors

source "$ZSH_CONFIG_DIR/options.zsh"
source "$ZSH_CONFIG_DIR/bash-ctrl-d.zsh"
source "$ZSH_CONFIG_DIR/editors.zsh"

if [[ -z "${SHELDON_PROFILE:-}" ]]; then
  case "$OSTYPE" in
    darwin*)
      if command -v docker >/dev/null 2>&1; then
        export SHELDON_PROFILE=macos-docker
      else
        export SHELDON_PROFILE=macos
      fi
      ;;
    *)
      command -v docker >/dev/null 2>&1 && export SHELDON_PROFILE=docker
      ;;
  esac
fi

# First compinit defines compdef for plugins that call it at load time.
compinit -d "$ZSH_COMPDUMP_FILE"
bashcompinit -d "$BASH_COMPDUMP_FILE"

eval "$(mise exec -- sheldon source)"

# fast-syntax-highlighting (loaded via zsh-defer) overrides the bracketed-paste
# widget that OMZ sets up, breaking instant paste. Re-queue it last so it wins
# after all deferred plugins have loaded.
zsh-defer -c 'autoload -Uz bracketed-paste-magic && zle -N bracketed-paste bracketed-paste-magic'

# Re-run after sheldon so plugin-provided completions (zsh-completions,
# mac-zsh-completions, jq, ...) added to fpath get registered.
compinit -d "$ZSH_COMPDUMP_FILE"

source "$ZSH_CONFIG_DIR/aliases.zsh"
[[ -r "$ZSH_CONFIG_DIR/local.zsh" ]] && source "$ZSH_CONFIG_DIR/local.zsh"

eval "$(mise activate zsh)"

source "$ZSH_CONFIG_DIR/atuin.zsh"

autoload -Uz vcs_info
zstyle ':vcs_info:git:*' formats ' (%b)'
precmd_vcs_info() {
  vcs_info
}
precmd_functions+=(precmd_vcs_info)
PROMPT='%F{green}%~%F{blue}${vcs_info_msg_0_}%f '

export GPG_TTY="$(tty)"
