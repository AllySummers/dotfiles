#!/usr/bin/env bash
# Cursor Shell-tool hook -> Atuin history recorder.
#
# Cursor's agent runs shell commands in a non-interactive zsh, so Atuin's
# normal preexec/precmd shell integration never loads there (.zshrc bails
# out early via `[[ -o interactive ]] || return 0`, before atuin.zsh is
# sourced). This script bridges Cursor's preToolUse/postToolUse/
# postToolUseFailure hook events (wired up in ../hooks.json, matched to the
# Shell tool) to `atuin history start`/`end` directly, so agent commands are
# still recorded.
#
# Entries are tagged author=cursor so they stay out of everyday Ctrl+R
# search (see [search] authors in atuin/config.toml) while remaining fully
# searchable via `atuin search --author cursor`.
#
# Cursor invokes this as a subprocess, not through the login shell, so it
# won't have mise's shims on PATH via .zshenv the way an interactive/zsh -c
# invocation would -- add them explicitly.
export PATH="$HOME/.local/share/mise/shims:$PATH"

set -uo pipefail

command -v atuin >/dev/null 2>&1 || { printf '{"permission":"allow"}'; exit 0; }
command -v jq >/dev/null 2>&1 || { printf '{"permission":"allow"}'; exit 0; }

STATE_DIR="${TMPDIR:-/tmp}/cursor-atuin-hooks"
mkdir -p "$STATE_DIR"
# Best-effort cleanup of state left behind by hook runs that crashed/timed
# out before they could clean up after themselves.
find "$STATE_DIR" -type f -mmin +1440 -delete 2>/dev/null || true

input="$(cat)"
event="$(jq -r '.hook_event_name // empty' <<<"$input")"
tool_use_id="$(jq -r '.tool_use_id // empty' <<<"$input")"

ms_to_ns() {
  local ms="${1:-0}"
  ms="${ms%%.*}"
  [ -n "$ms" ] || ms=0
  echo $(( ms * 1000000 ))
}

case "$event" in
preToolUse)
  command_text="$(jq -r '.tool_input.command // empty' <<<"$input")"
  if [ -z "$command_text" ]; then
    printf '{"permission":"allow"}'
    exit 0
  fi

  cwd="$(jq -r '.cwd // .tool_input.working_directory // empty' <<<"$input")"
  # agent_message is the closest thing Cursor exposes to "why" the agent is
  # running this command -- used as Atuin's --intent. Optional; the agent
  # doesn't always set it.
  intent="$(jq -r '.agent_message // empty' <<<"$input")"

  if [ -n "$intent" ]; then
    history_id="$(cd "${cwd:-$HOME}" 2>/dev/null && atuin history start --author cursor --intent "$intent" -- "$command_text" 2>/dev/null)"
  else
    history_id="$(cd "${cwd:-$HOME}" 2>/dev/null && atuin history start --author cursor -- "$command_text" 2>/dev/null)"
  fi

  if [ -n "$history_id" ] && [ -n "$tool_use_id" ]; then
    printf '%s' "$history_id" >"$STATE_DIR/$tool_use_id"
  fi
  printf '{"permission":"allow"}'
  ;;

postToolUse)
  if [ -z "$tool_use_id" ] || [ ! -f "$STATE_DIR/$tool_use_id" ]; then
    printf '{}'
    exit 0
  fi
  history_id="$(cat "$STATE_DIR/$tool_use_id")"

  exit_code="$(jq -r '.tool_output // empty' <<<"$input" | jq -r '.exitCode // 0' 2>/dev/null)"
  [ -n "$exit_code" ] || exit_code=0
  duration_ms="$(jq -r '.duration // 0' <<<"$input")"

  atuin history end --exit "$exit_code" --duration "$(ms_to_ns "$duration_ms")" "$history_id" >/dev/null 2>&1
  rm -f "$STATE_DIR/$tool_use_id"
  printf '{}'
  ;;

postToolUseFailure)
  if [ -z "$tool_use_id" ] || [ ! -f "$STATE_DIR/$tool_use_id" ]; then
    printf '{}'
    exit 0
  fi
  history_id="$(cat "$STATE_DIR/$tool_use_id")"

  failure_type="$(jq -r '.failure_type // "error"' <<<"$input")"
  duration_ms="$(jq -r '.duration // 0' <<<"$input")"
  case "$failure_type" in
    timeout) exit_code=124 ;;
    permission_denied) exit_code=126 ;;
    *) exit_code=1 ;;
  esac

  atuin history end --exit "$exit_code" --duration "$(ms_to_ns "$duration_ms")" "$history_id" >/dev/null 2>&1
  rm -f "$STATE_DIR/$tool_use_id"
  printf '{}'
  ;;

*)
  printf '{}'
  ;;
esac
