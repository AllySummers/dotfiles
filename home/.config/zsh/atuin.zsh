# Atuin: Ctrl+R opens the full TUI; Up/Down cycle history in-place via atuin search.
#
# Based on tyalie's gist for https://github.com/atuinsh/atuin/issues/798
# - Empty line: cycle recent history (no prefix filter)
# - Edit the line first: prefix-filter from what you typed
# - Keep pressing up on an unmodified history entry: keep cycling (no re-filter)
if ! command -v atuin >/dev/null 2>&1; then
  return 0
fi

eval "$(atuin init zsh --disable-up-arrow)"

: "${ATUIN_HISTORY_SEARCH_FILTER_MODE:=global}"

# Atuin's own "$all-user" author filter (and the [search] authors config
# default) only excludes its hardcoded known-agent list (claude-code, codex,
# copilot, pi) -- neither actually excludes "cursor" here. Cursor's agent
# commands are tagged author=cursor by ~/.cursor/hooks/atuin-history.sh (see
# that script for why), so every interactive surface below filters by this
# literal username explicitly instead of trusting "$all-user"/config
# defaults. Confirmed by testing: an unfiltered `atuin search` and the
# up-arrow's own query both surfaced author=cursor entries despite
# `[search] authors = ["Ally"]` being set in atuin/config.toml.
: "${ATUIN_HISTORY_SEARCH_AUTHOR:=$USER}"

# --- Ctrl+R interactive search ------------------------------------------------
# atuin init's generated __atuin_search_cmd (what Ctrl+R actually calls) passes
# no --author at all, so it shows every author unfiltered. Wrap it rather than
# reimplement it, to keep upstream's tmux-popup/bracketed-paste handling intact.
if (( $+functions[__atuin_search_cmd] )); then
  functions -c __atuin_search_cmd __atuin_search_cmd_upstream
  __atuin_search_cmd() {
    __atuin_search_cmd_upstream --author "$ATUIN_HISTORY_SEARCH_AUTHOR" "$@"
  }
fi

# --- zsh-autosuggestions ghost text -------------------------------------------
# atuin init's generated suggestion strategy hardcodes --author '$all-user',
# which has the same "cursor" blind spot described above. Override wholesale.
if (( $+functions[_zsh_autosuggest_strategy_atuin] )); then
  _zsh_autosuggest_strategy_atuin() {
    suggestion=$(ATUIN_QUERY="$1" atuin search --cmd-only --author "$ATUIN_HISTORY_SEARCH_AUTHOR" --limit 1 --search-mode prefix 2>/dev/null)
  }
fi

typeset -g -i _atuin_history_match_index
typeset -g _atuin_history_search_result
typeset -g _atuin_history_search_query
typeset -g _atuin_history_refresh_display

_atuin_history_precmd() {
  _atuin_history_match_index=0
  _atuin_history_search_result=''
  _atuin_history_search_query=''
  _atuin_history_refresh_display=''
}

add-zsh-hook precmd _atuin_history_precmd

_atuin_history_search_begin() {
  _atuin_history_refresh_display=

  # Still stepping through matches — don't reset the query.
  if [[ -n $BUFFER && $BUFFER == ${_atuin_history_search_result:-} ]]; then
    return 0
  fi

  _atuin_history_search_result=''

  if [[ -z $BUFFER ]]; then
    _atuin_history_search_query=
  else
    _atuin_history_search_query=$BUFFER
  fi

  _atuin_history_match_index=0
}

_atuin_history_search_end() {
  if (( _atuin_history_match_index <= 0 )); then
    _atuin_history_search_result=$_atuin_history_search_query
  fi

  if [[ $_atuin_history_refresh_display == 1 ]]; then
    BUFFER=$_atuin_history_search_result
    CURSOR=$#BUFFER
  fi
}

_atuin_history_up_buffer() {
  local buflines XLBUFFER xlbuflines
  buflines=(${(f)BUFFER})
  XLBUFFER=$LBUFFER"x"
  xlbuflines=(${(f)XLBUFFER})

  if (( ${#buflines[@]} > 1 && CURSOR != $#BUFFER && ${#xlbuflines[@]} != 1 )); then
    zle up-line-or-history
    return 0
  fi

  return 1
}

_atuin_history_down_buffer() {
  local buflines XRBUFFER xrbuflines
  buflines=(${(f)BUFFER})
  XRBUFFER="x"$RBUFFER
  xrbuflines=(${(f)XRBUFFER})

  if (( ${#buflines[@]} > 1 && CURSOR != $#BUFFER && ${#xrbuflines[@]} != 1 )); then
    zle down-line-or-history
    return 0
  fi

  return 1
}

_atuin_history_do_search() {
  local offset=$1 query=$2
  (( offset < 0 )) && return 1

  local -a args=(
    --cmd-only
    --filter-mode "$ATUIN_HISTORY_SEARCH_FILTER_MODE"
    --search-mode prefix
    --author "$ATUIN_HISTORY_SEARCH_AUTHOR"
    --limit 1
    --offset "$offset"
  )

  if [[ -n "$query" ]]; then
    args+=("$query")
  fi

  ATUIN_LOG=error atuin search "${args[@]}" 2>/dev/null
}

_atuin_history_up_search() {
  (( _atuin_history_match_index++ ))

  local search_result offset=$(( _atuin_history_match_index - 1 ))
  search_result=$(_atuin_history_do_search "$offset" "$_atuin_history_search_query")

  if [[ -z "$search_result" ]]; then
    (( _atuin_history_match_index-- ))
    return 1
  fi

  _atuin_history_refresh_display=1
  _atuin_history_search_result=$search_result
  return 0
}

_atuin_history_down_search() {
  (( _atuin_history_match_index <= 0 )) && return 1

  _atuin_history_refresh_display=1
  (( _atuin_history_match_index-- ))

  local offset=$(( _atuin_history_match_index - 1 ))
  if (( _atuin_history_match_index <= 0 )); then
    return 0
  fi

  _atuin_history_search_result=$(_atuin_history_do_search "$offset" "$_atuin_history_search_query")
  return 0
}

_atuin_history_up() {
  _atuin_history_search_begin
  _atuin_history_up_buffer || _atuin_history_up_search
  _atuin_history_search_end
}

_atuin_history_down() {
  _atuin_history_search_begin
  _atuin_history_down_buffer || _atuin_history_down_search
  _atuin_history_search_end
}

zle -N atuin-history-up _atuin_history_up
zle -N atuin-history-down _atuin_history_down

_atuin_bind_history() {
  bindkey -M emacs '^[[A' atuin-history-up
  bindkey -M emacs '^[OA' atuin-history-up
  bindkey -M emacs '^[[B' atuin-history-down
  bindkey -M emacs '^[OB' atuin-history-down
  bindkey -M viins '^[[A' atuin-history-up
  bindkey -M viins '^[OA' atuin-history-up
  bindkey -M viins '^[[B' atuin-history-down
  bindkey -M viins '^[OB' atuin-history-down
  bindkey -M vicmd 'k' atuin-history-up
  bindkey -M vicmd 'j' atuin-history-down
}

_atuin_bind_history
