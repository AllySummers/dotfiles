setopt auto_pushd
setopt pushd_ignore_dups
setopt extended_glob
setopt glob_dots
setopt bang_hist
setopt extended_history
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_verify
setopt inc_append_history
setopt share_history
setopt ignore_eof
setopt prompt_sp
setopt prompt_subst
setopt beep
unsetopt list_beep
unsetopt hist_beep

PROMPT_EOL_MARK=''

# zsh-autosuggestions performance knobs (must be set before the plugin loads).
# BUFFER_MAX_SIZE: skip history scan for long buffers (pastes are almost always
# longer than this, so no expensive search fires at all).
# MANUAL_REBIND: don't rebind every widget on each precmd — big perf win.
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_MANUAL_REBIND=1

# bracketed-paste-magic: only call through the built-in self-insert during paste,
# skipping zsh-autosuggestions' and other plugins' self-insert wrappers.
# This is the key setting that kept paste instant in the old config.
zstyle ':bracketed-paste-magic' active-widgets '.self-*'

# fast-syntax-highlighting: cap token analysis so large pastes don't stall the
# highlighter. Highlighting still applies, just truncated for very long lines.
typeset -gA FAST_HIGHLIGHT
FAST_HIGHLIGHT[max-syntax-tokens]=100

zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'
zstyle ':completion:*' special-dirs false
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion:*' ignored-patterns '.' '..'
