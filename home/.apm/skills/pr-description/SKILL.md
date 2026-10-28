---
name: pr-description
description: Write concise app PR titles and descriptions from the actual diff, including stacked PRs. Use when drafting, updating, or shortening PR text. Keep Overview bullets, omit routine CI results, and explain details that help a human review.
---

# Concise PR titles and descriptions

Tell the reviewer what changes and why it matters. Keep the details they need to judge the change.

## Read the right diff

Read the repository instructions, PR template, current title/body, and full diff. Use the issue and relevant discussion to understand intent. Check the old description against the code. If the implementation conflicts with the ticket, flag the discrepancy to the user; do not call it an accepted tradeoff without evidence of that decision.

For an existing PR, describe its remote head. Do not silently include unpushed commits or uncommitted files. For a proposed PR, establish which local changes belong in it.

For a stack, compare this layer with its immediate parent; use the target trunk for the bottom layer. Get the parent through the available stack skill or PR metadata. If a stale or wrong base pulls earlier changes into the diff, report it. Do not repair the stack just to write its description.

Use available GitHub, Graphite/stack skills such as `gh-stack`, `pr-stack`, or `stacked-pr-gh`, and repository instructions to resolve parents or create/update PRs. Use a media skill such as `github-pr-media` for uploads. These names are examples: use them only when available and applicable.

Fallback when no skill applies: read `gh pr view <pr> --json baseRefName,headRefOid,title,body` and available stack metadata; if the intended parent is still unclear, ask.

## Explain misleading diff sizes

When moves, renames, file splits, or formatting inflate a diff, use the relevant commands in [references/diff-inspection.md](references/diff-inspection.md). Tell the reviewer plainly when existing code accounts for much of the apparent addition/deletion, then name the behavior changes. For a revert, explain what returns and what remains unresolved; verify any claim of an exact restoration. Check the code before claiming behavior is unchanged; do not tell reviewers to ignore moved code wholesale.

## Write the title and Overview

Name the affected behavior with a short active phrase: `Keep clause suggestions before the first heading`. Follow required repository prefixes and ticket conventions. Avoid vague titles such as `Improve handling` or `Address feedback`. For internal work, name the maintainer benefit without inventing a user-facing change.

Every body needs `## Overview` and a flat `-` bullet list. An optional one- or two-sentence introduction can explain the problem before the bullets. Omit it when the bullets already supply the context.

Usually two to five short bullets suffice; one is fine for a small fix. Explain the trigger and outcome. Keep permissions, destructive effects, and surprising choices. Omit endpoint paths, helper names, field inventories, cache mechanics, and routine loading states unless their exact form matters to review. Let useful information set the length, not a bullet quota.

Add sections such as `Screenshots`, `Rollout`, or `Performance` only when they make important information easier to find. Keep relevant permission and data boundaries, breaking changes, migrations or backfills, deploy order, feature flags, accepted tradeoffs, and known limitations. Avoid unsupported claims that a change is safe or low risk. State each caveat once, beside its claim.

Link documentation when a new or particularly relevant feature, API, or behavior needs explanation. Prefer the specific official section for the version used; a design decision, migration guide, or focused article may explain the choice better. Verify the link and place it beside the relevant point. Explain enough that the PR still makes sense without opening it. Skip generic homepages and a default References section.

Keep useful issue links, attachments, and tool-managed content, including stack blocks. Use issue-closing keywords only when closure is intended. Retain required repository information without copying empty sections or generic checklists. Use equivalent template headings where useful. A generic request for validation does not override the user's instruction to omit routine CI results or make a Validation section necessary.

## Keep evidence honest

Do not repeat CI-enforced validation, even if it also passed locally. Omit routine lint, format, typecheck, build, test counts, coverage figures, and “checks passed/pending” reports. Do not add a default Testing or Validation section, or run tests just to fill one.

Check the CI configuration when needed to tell what it covers. Include additional testing evidence only when it resolves an important uncertainty that required CI does not cover; hosting a run in GitHub Actions is not itself a reason to include it. Describe regression coverage if it explains the change or is itself the purpose of the PR.

Do not replace CI boilerplate with generic “not tested” boilerplate. Mention a gap only when you can name the specific behavior or risk left unresolved. Keep transient run status in the chat handoff; retain an unresolved acceptance requirement when it matters to review.

Keep these distinctions clear:

- Tests added describe coverage in the diff.
- Tests observed running support only the result and revision actually checked.
- Author-reported results must stay attributed.
- Proposed checks are work still to do.

Missing results do not prove that tests never ran. “I did not test this” does not establish that nobody did. Screenshots show only what was captured; they do not establish interaction testing or resolve an unrelated validation gap. Mocks and demos do not prove real integration. Benchmarks from an older revision do not prove current `HEAD`.

Keep useful manual results or benchmarks with their conditions and limits; link the detailed record. If relevant evidence ran on another revision or a child PR, identify that scope. This is an accuracy rule, not a reason to include CI results. Ask about missing facts that matter instead of guessing.

## Add stack context only when it matters

Describe this layer's changes in the title and Overview. Do not claim changes from earlier PRs. Reviewers can already navigate the stack; skip stack inventories and instructions to review bottom-up.

When a dependency changes how someone should review or use this change, add a short NOTE or IMPORTANT alert above Overview:

```markdown
> [!IMPORTANT]
> Keep `accountExport` disabled until #123 adds the permission checks.
```

Omit the alert for routine parent/child relationships. Recheck the scope when a rebase, split, or merge changes the base.

## Show useful media

Use screenshots when they help assess a UI change or are required. Use a video when required or when the interaction needs motion. Reuse an accurate existing asset, with a short caption explaining what to notice. If you cannot view it, preserve the existing caption without adding claims and tell the user.

Put images, videos, and media placeholders in standalone blocks with short captions by default. For a useful UI comparison, put Before and After one below the other. Use a media table only for a large collection where grouping clearly makes it easier to scan; a single before/after pair or a few assets is not enough. Keep videos standalone when a table would interfere with playback. Do not add media just to fill a layout.

Use regular, visible text for every placeholder, including missing media, links, or facts. Never hide placeholders in HTML comments: editors such as Graphite may conceal them. For example:

```markdown
Before

TODO screenshot: settings form with the old invalid-email error

After

TODO screenshot: same form showing the new inline error
```

For a new screen or a required recording, use a standalone line such as `TODO video: show the complete sign-in handoff`. Put video links on their own lines so they can render as players. Keep placeholders plain; no alert boxes are needed.

A request to replace existing screenshots covers those assets, not every PR or possible scenario. Suggest extra captures in chat only when they would help; do not silently add them to the capture list.

Do not invent URLs, put local paths in GitHub, or present generated mockups as execution evidence. Briefly identify mocks or an older recording when that limits what the media shows. Skip recording specifications unless they affect the comparison.

## Cut the AI writing habits

Do not use:

- “This PR…” openers or a first sentence that restates the title.
- “Not just X, but Y” constructions or groups of three added for rhythm.
- Scattered inline bolding, bold labels on every bullet, or decorative emoji.
- Wrap-up or closing sentences. Stop after the last useful detail; keep required links and disclosure footers.
- Filler such as “comprehensive”, “robust”, “seamless”, “leverage”, “significantly”, or “production-ready”.

Remove file tours, function-call narration, development history, rejected experiments, and repeated explanations. Cut pasted code and diagrams when a short explanation is clearer. Omit “N/A” sections and lists of unchanged behavior unless they prevent a likely misunderstanding. Keep precise terms and real uncertainty.

Do not hard-wrap PR prose: GitHub renders single line breaks. Keep each paragraph and bullet on one source line; retain deliberate Markdown breaks and code formatting. Wrap `@names` in backticks unless intentionally pinging someone.

Read the finished draft against the diff and checked sources. For each sentence, ask what it helps the reviewer understand or decide. Cut mechanism before cutting a consequential condition. Correct unsupported claims; do not turn possible bugs into settled design decisions.

## Hand it back

Draft or publish according to the user's request, using the relevant operation skill. Writing a description does not authorize code changes, branch repairs, reviews, merges, or extra public comments.

Fallback for an authorized edit: recheck `baseRefName`, `headRefOid`, and the current body; preserve others' edits, pass multiline text through a structured API argument or `--body-file`, and read back the saved title/body.

Follow the applicable disclosure rules. For a human account, append the italic footer below using known runtime identifiers and `unavailable` for unknown fields:

`_AI-assisted — Tool: <tool>; model: <provider>/<model>; version: <version-or-unavailable>._`

In chat, list every unfilled placeholder and anything else the user must edit or supply, including relevant claims or media you could not verify. Flag suspected bugs or acceptance mismatches separately; do not conceal known limitations that matter to review. Placeholders must remain visible in the description and be listed in the handoff. Claim a remote update or upload only after it succeeds.

Read [references/examples.md](references/examples.md) when you need examples of length, stack context, media placeholders, or what to cut.
