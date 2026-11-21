#!/usr/bin/env bash
#MISE description="Install Atuin recording and disclosure hooks"
#MISE raw=true

set -euo pipefail
umask 077

mise dotfiles apply \
  "$HOME/.config/mise/tasks/agent" \
  "$HOME/.codex/config.toml" \
  "$HOME/.claude/settings.json" \
  "$HOME/.cursor/hooks.json" \
  "$HOME/.copilot/hooks/ai-disclosure.json"

atuin setup --only --no-import --agent-history --agents claude-code,codex,copilot

# Append the disclosure handler without replacing Atuin or user hook arrays.
# SessionStart in the source only carries the rendered command, and the script
# answers it with nothing. Copies earlier versions added to other events are removed.
settings="$HOME/.claude/settings.json"
temp=$(mktemp "$settings.disclosure.XXXXXX")
trap 'rm -f "$temp"' EXIT
jq '
  ([.hooks.SessionStart[]?.hooks[]?.command |
    select(type == "string") | select(contains("agent:disclosure claude"))] | first) as $command |
  if $command == null then
    error("Apply the Claude disclosure source before installing its tool hooks")
  else
    .hooks |= with_entries(
      if .key == "SessionStart" then .
      else .value |= map(.hooks = [.hooks[]? | select(.command != $command)] | select(.hooks | length > 0))
      end) |
    .hooks.PostToolUse += [{
      matcher: "Bash|PowerShell",
      hooks: [{type: "command", command: $command, timeout: 5}]
    }]
  end
' "$settings" > "$temp"
if ! cmp -s "$settings" "$temp"; then
  mv "$temp" "$settings"
fi
