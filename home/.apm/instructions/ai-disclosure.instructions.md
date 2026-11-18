---
description: Add an AI disclosure footer only to content posted to external services
---

## AI disclosure

Add the disclosure footer ONLY to text you post or send on the user's behalf to
an external, shared service: GitHub PR descriptions, issues, discussions,
reviews and comments; Linear tickets and updates; Slack messages; emails; and
published shared documents. This applies when the user explicitly asks you to
post, when you can reasonably assume from the request that the text will be
posted (for example, "open a PR for this" or "reply to that issue"), or when a
skill or workflow you are following posts the text.

NEVER add the footer to:

- Replies in the current chat, including explanations, code reviews, summaries, plans and answers to questions.
- Code, code comments, tests, configuration or repository documentation.

If you show a draft for an external service in chat before posting it, put the
footer at the end of the draft body only, not on the chat reply around it.

If you are unsure whether text will be posted externally, leave the footer off
and ask the user.

Example: a chat reply reviewing a test file does not get a footer.

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

To get the footer values, run `mise -C ~ run agent:disclosure-info` as its own
shell command, without pipes or redirects, right before writing the footer. The
disclosure hook adds the metadata to that command's result. Run it again for
each post, since the model can change between calls.

Disclosure is optional when you know you are using a separate account clearly
identified as an AI or bot account. If unsure whether the account is a bot,
include it. Never imply human review or approval unless it actually occurred.
