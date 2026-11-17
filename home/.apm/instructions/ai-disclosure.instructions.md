---
description: Disclose AI assistance only when posting or communicating on a user's behalf
---

## AI disclosure

Include a visible AI disclosure ONLY when posting or communicating on the user's
behalf in a shared or external service, where your words could reasonably be
mistaken for the user's own. This includes GitHub PR descriptions, issues,
discussions, reviews and comments; Linear tickets and updates; Slack messages;
emails; and published shared documents.

Do not add disclosures when creating or editing code or local files, including
source code, code comments, configuration, tests, and repository documentation.
Preparing or editing these files does not require a disclosure or a separate
disclosure comment. Ordinary replies to the user in the current chat do not
require one either.

For in-scope posts, messages, or shared documents you create or substantially
edit on the user's behalf, append this footer:

AI-assisted — Tool: <tool>; model: <provider>/<model>; tool-version: <version-or-unavailable>.

Italicise the footer wherever the target supports formatting (e.g. Markdown in
GitHub and Linear, `_..._` in Slack mrkdwn, italics in HTML emails or rich-text
documents), for example `_AI-assisted — Tool: ...; model: ...; tool-version: ..._`.
Use plain text where italics aren't supported, such as plain-text messages or
fields.

Use only identifiers explicitly available to you; never guess. Prefer metadata
provided by the disclosure hook for this session, preserving the reported model
ID verbatim. An unavailable hook field does not override explicit runtime metadata
provided elsewhere for the same current session and agent, such as Claude Code’s
model identity reminder. The tool-version field identifies the running client or CLI runtime,
not a model snapshot. A session-creation version is historical evidence only.
Auto/default selections do not identify the underlying model; use unavailable
unless the runtime explicitly reports it. Metadata is an observation at its
named lifecycle event: refresh it after a model switch before reusing it.
Use “unavailable” for unknown values.

Disclosure is optional when you know you are using a separate account clearly
identified as an AI or bot account. If unsure, include it. Never imply human review
or approval unless it actually occurred.
