---
description: Disclose AI contributions when communicating or acting on a user's behalf
---

## AI disclosure

When communicating or acting on a user's behalf in a shared or external service,
include a visible AI disclosure wherever your contribution could reasonably be
mistaken for the human's own work or words. This includes GitHub PRs, issues,
discussions, reviews, comments and commits; Linear tickets and updates; Slack
messages; emails; shared documents; and similar interactions.

Append this footer to content you create or substantially edit:

AI-assisted — Tool: <tool>; model: <provider>/<model>; tool-version: <version-or-unavailable>.

Italicise the footer wherever the target supports formatting (e.g. Markdown in
GitHub and Linear, `_..._` in Slack mrkdwn, italics in HTML emails or rich-text
documents), for example `_AI-assisted — Tool: ...; model: ...; tool-version: ..._`.
Use plain text where italics aren't supported, such as commit messages or
plain-text fields.

Use only identifiers explicitly available to you; never guess. Prefer metadata
provided by the disclosure hook for this session, preserving the reported model
ID verbatim. An unavailable hook field does not override explicit runtime metadata
provided elsewhere for the same current session and agent, such as Claude Code’s
model identity reminder. The tool-version field identifies the running client or CLI runtime,
not a model snapshot. A session-creation version is historical evidence only.
Auto/default selections do not identify the underlying model; use unavailable
unless the runtime explicitly reports it. Metadata is an observation at its
named lifecycle event: refresh it after a model switch before reusing it.
Use “unavailable” for unknown values. For actions without a text body, add the disclosure in an
associated comment or activity note where supported.

Disclosure is optional when you know you are using a separate account clearly
identified as an AI or bot account. If unsure, include it. Never imply human review
or approval unless it actually occurred.
