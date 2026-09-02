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

# `completions-override` holds only `_git`, so prepending it to fpath wins the
# lookup race against the stripped-down 295-line `_git` in the
# clarketm/zsh-completions sheldon plugin -- which has no `_git-checkout` at
# all -- without shadowing any of that plugin's other completions (macOS/Go/
# etc.), since fpath lookup is per function name.
#
# The override is a real symlink to the full `_git` (the one that defines
# `_git-checkout` with proper `heads`/`remote-branches`/`tags` completion tags,
# which the zstyles below target), rather than a wrapper script, so zsh's
# normal completion-autoload caching applies: the ~9000-line file is read once
# per session, not re-parsed on every TAB press.
#
# It's (re)created here at shell startup instead of committed to git as a fixed
# symlink, because the real target is machine-specific: Homebrew's zsh keeps it
# unversioned under opt/homebrew/share/zsh/functions, the OS-bundled zsh under a
# versioned /usr/share/zsh/<version>/functions, and Linux distros differ again.
# The check below is a single stat, so this is a no-op on every startup except
# the first one and after a zsh upgrade moves the target.
_git_completion_override="$ZSH_CONFIG_DIR/completions-override/_git"
if [[ ! -e "$_git_completion_override" ]]; then
  mkdir -p "${_git_completion_override:h}"
  for _git_impl_dir in $fpath; do
    [[ -r "$_git_impl_dir/_git" ]] || continue
    grep -q '_git-checkout' "$_git_impl_dir/_git" 2>/dev/null || continue
    ln -sf "$_git_impl_dir/_git" "$_git_completion_override"
    break
  done
  unset _git_impl_dir
fi
unset _git_completion_override

fpath=("$ZSH_CONFIG_DIR/completions-override" $fpath)

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
# git checkout/switch: only offer local branch heads, and hide Graphite's
# internal graphite-base/* bookkeeping branches.
zstyle ':completion:*:*:git-checkout:*' tag-order 'heads'
zstyle ':completion:*:*:git-checkout:*:*' ignored-patterns 'graphite-base/*'
zstyle ':completion:*:*:git-switch:*' tag-order 'heads'
zstyle ':completion:*:*:git-switch:*:*' ignored-patterns 'graphite-base/*'
