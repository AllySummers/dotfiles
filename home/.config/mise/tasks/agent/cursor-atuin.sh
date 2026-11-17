#!/usr/bin/env bash
#MISE description="Record Cursor shell tool calls in Atuin"
#MISE raw=true
#MISE quiet=true
#USAGE arg "<event>" {
#USAGE   choices "preToolUse" "postToolUse" "postToolUseFailure"
#USAGE }

set -euo pipefail
umask 077

# Supplied and validated by mise Usage.
# shellcheck disable=SC2154
event="$usage_event"
# Recording errors must never block Cursor or corrupt its JSON response.
reply() {
  if [[ $event == preToolUse ]]; then
    printf '{"permission":"allow"}\n'
  else
    printf '{}\n'
  fi
}
trap 'reply; exit 0' EXIT
exec 2>/dev/null

input="$(cat)"
tool_use_id="$(jq -r '.tool_use_id // empty' <<<"$input")"
[[ -n $tool_use_id ]] || exit 0

state_dir="${TMPDIR:-/tmp}/cursor-atuin-hooks-$UID"
mkdir -p "$state_dir"
chmod 700 "$state_dir"
find "$state_dir" -type f -mmin +1440 -delete
# Include the conversation so parallel agents can reuse tool-call IDs safely.
key="$(jq -cj '[.conversation_id // null, .tool_use_id]' <<<"$input" | openssl dgst -sha256)"
state="$state_dir/${key##* }"

case "$event" in
preToolUse)
  command_text="$(jq -r '.tool_input.command // empty' <<<"$input")"
  [[ -n $command_text ]] || exit 0
  cwd="$(jq -r '.cwd // .tool_input.working_directory // empty' <<<"$input")"
  cwd="${cwd:-$HOME}"
  intent="$(jq -r '.agent_message // empty' <<<"$input")"

  args=(history start --author cursor --author-kind agent)
  [[ -z $intent ]] || args+=(--intent "$intent")
  history_id="$(cd "$cwd" && timeout 2s atuin "${args[@]}" -- "$command_text")"
  if [[ -n $history_id ]]; then
    jq -n --arg historyId "$history_id" --arg cwd "$cwd" '$ARGS.named' > "$state"
  fi
  ;;

postToolUse | postToolUseFailure)
  [[ -f $state ]] || exit 0
  history_id="$(jq -r '.historyId' "$state")"
  cwd="$(jq -r '.cwd' "$state")"

  if [[ $event == postToolUseFailure ]]; then
    failure_type="$(jq -r '.failure_type // "error"' <<<"$input")"
    case "$failure_type" in
      timeout) exit_code=124 ;;
      permission_denied) exit_code=126 ;;
      *) exit_code=1 ;;
    esac
  else
    exit_code="$(jq -r '
      .tool_output | if type == "string" then (fromjson? // {}) else . end |
      .exitCode // .exit_code // 0 |
      if type == "number" and isfinite and floor == . then . else 0 end
    ' <<<"$input")"
  fi
  duration="$(jq -r '
    .duration | if type == "number" and isfinite then ([0, floor] | max) * 1000000 else 0 end
  ' <<<"$input")"

  (cd "$cwd" && timeout 2s atuin history end --exit "$exit_code" --duration "$duration" "$history_id") >/dev/null || true
  rm -f "$state"
  ;;
esac
