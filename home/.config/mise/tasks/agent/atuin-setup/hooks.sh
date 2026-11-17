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

for agent in claude-code codex copilot; do
  atuin hook install "$agent"
done

# Append disclosure handlers without replacing Atuin or user hook arrays.
settings="$HOME/.claude/settings.json"
temp=$(mktemp "$settings.disclosure.XXXXXX")
trap 'rm -f "$temp"' EXIT
jq '
  ([.hooks.SessionStart[]?.hooks[]?.command |
    select(type == "string") | select(contains("agent:disclosure claude"))] | first) as $command |
  if $command == null then
    error("Apply the Claude disclosure source before installing its tool hooks")
  else
    reduce ["PreToolUse", "PostToolUse", "SubagentStart"][] as $event (.;
      .hooks[$event] //= [] |
      if any(.hooks[$event][]?.hooks[]?; .command == $command) then .
      else .hooks[$event] += [{hooks: [{type: "command", command: $command, timeout: 5}]}]
      end)
  end
' "$settings" > "$temp"
if ! cmp -s "$settings" "$temp"; then
  mv "$temp" "$settings"
fi
