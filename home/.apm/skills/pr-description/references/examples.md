# Examples

These are fictional examples. Assume the facts were checked against the diff and available evidence. PR numbers and paths are illustrative. Add the required AI-disclosure footer when publishing.

## Small fix

Title: `Keep clause suggestions before the first heading`

```markdown
## Overview

- Retain valid suggestions anchored to introductory paragraphs; these were discarded when no section heading preceded them.
- Group them under the first section in the review panel while preserving their insertion position.
```

Required CI already covers routine checks. There is no Testing section. Add media only if it helps or is requested.

## Moved code with a behavior change

Title: `Share retry handling and stop retrying rejected requests`

```markdown
## Overview

- Move the retry loop from `client.ts` into `retry.ts` for both clients to use. Most of the apparent diff is this move.
- Stop retrying 400 responses. Transient server failures keep the existing retry schedule.
```

Check the move with the commands in [diff-inspection.md](diff-inspection.md). Do not call the whole change behavior-neutral.

If indentation also inflates the diff, a short review note can say: “Most remaining changes reindent the moved code; hiding whitespace makes the changed error branch easier to see.” Link “hiding whitespace” to the actual PR's Files changed URL with `?w=1` (or `&w=1` if it already has a query). Inspect meaningful whitespace separately.

## Ordinary stack

A lower layer adds an export endpoint. This layer adds the button and UI feedback.

Title: `Add CSV export to the results page`

```markdown
## Overview

- Let users download the current results from the results page.
- Disable the export button while the download starts and offer a retry if it fails.
```

The endpoint belongs to the parent. There is no stack alert or navigation tutorial.

## Stack with an important dependency

This layer adds a screen behind a disabled flag. A later layer supplies the permission checks.

Title: `Add the account export screen behind a feature flag`

```markdown
> [!IMPORTANT]
> Keep `accountExport` disabled until #123 adds the permission checks.

## Overview

- Let users choose a date range and follow download progress on the new export screen.
```

The alert explains the constraint without retelling the other PR.

## UI comparison with missing screenshots

Title: `Show field errors beside the account settings inputs`

```markdown
## Overview

- Put validation errors beside the affected fields so users can see what needs correcting.
- Preserve entered values when saving fails.

## Screenshots

Before

TODO screenshot: settings form showing the old invalid-email error

After

TODO screenshot: same invalid email with the new inline error
```

Chat handoff: “Drafted the title and body. Two visible screenshot TODOs remain: the old invalid-email error in Before, and the new inline error in After. Replace each TODO with its image.”

Keep each image or placeholder in its own block. If one image is available, include it and leave a visible TODO for the other only when the comparison matters. A pair or a few assets does not need a table; reserve tables for large collections that are clearly easier to scan when grouped. Do not use a broken image link as a placeholder.

## Required recording with no asset

Title: `Restore redirect authentication in the desktop add-in`

```markdown
## Overview

- Restore the previous sign-in redirect after the handoff sometimes returned users to the sign-in screen.
- Accept the brief navigation flash while the original failure remains unexplained.

## Demo

TODO video: show the sign-in handoff opening the add-in without a second login
```

Chat handoff: “The required sign-in recording is still missing. Replace the visible TODO video line in Demo with the recording.”

If the supplied clip uses mocked services, identify it as a controlled UI demonstration. Do not claim that it proves native integration.

## Evidence outside required CI

Assume an observed run used a 10,000-row staging dataset and measured the values below. Required CI covers functional behavior only.

Title: `Start CSV downloads before reading every result`

```markdown
## Overview

- Stream rows as they are read so large exports can start downloading sooner.

## Performance

On the 10,000-row staging dataset, time to first byte fell from 4.2 s to 0.7 s. Total export time was not measured.
```

Link the actual experiment if available. Do not reuse these fictional numbers. If the author supplied the results, say “The author reports…”; if they predate the current revision, state that limit. Planned measurements do not belong here as results.

## Documentation that helps review

A PR adopts an unfamiliar library feature. Put a descriptive link beside the bullet explaining how the change uses it. Link the exact feature documentation for the version in the diff, and explain any relevant restriction in the bullet itself.

A generic library homepage adds little. A migration guide explaining a changed error contract can save the reviewer substantial investigation. Neither needs a References section by default.

## Replace mechanism with review decisions

For a task-assignment UI, the endpoint URL and cache helper names usually add little. The conditions and destructive effects matter.

Title: `Assign a super verifier from the document Tasks page`

```markdown
## Overview

- Let users with assignment permission choose an eligible super verifier once the document is verified and has a verifier assigned.
- Assigning someone replaces the open super verification task.
```

No automatic Validation section follows. “I did not open a browser” alone does not justify one. If the ticket forbids replacing an open task, flag that mismatch to the user rather than describing it as an accepted choice.

## A specific validation gap

A change affects cancellation during a real upload. The agent ran only mocked component tests, and required CI does not cover this interaction.

A useful review note could say: “Cancellation while a real upload is in flight remains unverified.” Keep it only if this is a consequential uncertainty, and phrase it as the limits of available evidence. Do not claim nobody tested it.

A screenshot of the cancel button does not resolve that gap. If the author later reports testing that interaction, attribute the result. If required CI already covers it, omit the routine validation report.

## Exact revert, unresolved cause

Assume file comparison confirms the authentication file matches its version before the original change, and the ticket explicitly accepts the brief redirect flash.

```markdown
## Overview

- Restore the earlier redirect sign-in flow after intermittent handoffs returned users to the sign-in screen; the cause remains unresolved.
- Restore the authentication file exactly to its earlier version. The brief redirect flash returns and is accepted for now.
```

Name the restored behavior and the accepted cost. Do not claim the entire application is restored, or the root cause fixed, from a comparison of one file.

## Replacing existing media

The user asks to replace one existing screenshot with a placeholder:

```markdown
## Screenshots

TODO screenshot: Feedback tab showing the latest score and feedback cards
```

Chat handoff: “Replaced the screenshot with a visible TODO for the Feedback tab. Add the new image there.”

Do not add placeholders to sibling PRs that had no screenshots, or invent extra scenarios. If another capture would materially help, suggest it separately. If a retained asset cannot be viewed, keep its existing caption and disclose that limit instead of guessing.

## Detail selection

| Draft content | Editorial decision |
| --- | --- |
| Lint, typecheck, and required tests passed locally and in CI | Remove the routine status report. |
| A required CI integration run passed | Omit the routine result, including when someone triggered it manually. |
| Every PR has “not checked in a browser” under Validation | Remove generic boilerplate; retain only a specific, consequential gap supported by evidence. |
| The agent did not run a check, so nobody did | Do not make that inference. Ask only if the missing fact matters. |
| A screenshot means navigation and permissions were tested | State only what the capture demonstrates. |
| Useful evidence ran on a child PR | Identify its scope if inclusion is justified; do not imply the parent alone was tested. |
| A check is still running | Put transient status in the handoff; keep any consequential acceptance requirement in the body. |
| A regression test was added | Describe the case if it matters; do not imply the test ran. |
| The author says a manual check passed | Attribute it; do not turn it into an observed result. |
| A proposed check is listed as validation | Label it as work still to do, if the gap matters. |
| A mock Office demo proves the Word integration works | State only the UI behavior shown and retain the mock limitation. |
| An older revision's benchmark proves current HEAD is faster | Keep the revision limit or omit the claim. |
| Local commits are newer than the PR's remote head | Describe the remote head; do not fold local work into it. |
| A wrong stack base exposes earlier PR changes | Report the scope problem; do not repair branches to write the body. |
| A rollback improves the observed symptom but its cause is unresolved | Keep that distinction once. |
| Historical cohorts, rejected candidates, and rebase hashes | Keep the useful result and limits; link the detailed record. |
| A source file survives an extraction | Try copy detection and inspect both paths; explain moved code without asserting semantic equivalence from similarity. |
| An implementation contradicts the ticket | Flag the mismatch; do not label it deliberate without evidence. |
| A large extraction also changes one error branch | Explain the move and the behavior change separately. |
| A new API's restriction affects this implementation | Explain the restriction and link the relevant docs section. |
| Any missing image, recording, link, or fact needs a placeholder | Use regular visible TODO text and list it in the chat handoff; never hide it in an HTML comment. |
| A useful UI comparison lacks before/after assets | Put visible TODOs in separate Before and After blocks. |
| Images, videos, or media placeholders are put in a table | Use standalone blocks by default; consider a table only for a large collection where grouping clearly helps. |
| A supplied asset cannot be viewed | Preserve its caption without adding claims; tell the user. |
| A request replaces one existing screenshot | Replace that asset; do not silently add capture tasks elsewhere. |
| An Overview lists endpoints, helpers, fields, and cache keys | Keep only the exact details needed to assess behavior, risk, or a surprising choice. |
| An incidental @name | Use backticks to avoid an unintended mention. |
| This PR comprehensively improves a robust, seamless workflow | Replace it with the concrete behavior; cut the opener and filler. |
| Internal cleanup described as a better user experience | State the actual maintainer benefit. |
| “Safe” or “low risk” without supporting evidence | Remove the assurance; describe any specific remaining risk. |
| A closing sentence promising easier maintenance | Cut it; put a concrete maintenance benefit in Overview if it matters. |
| A diagram or code dump repeats a short explanation | Keep the clearer explanation. |
| Review coverage, graph-refresh counts, and green-light reports | Remove review-tool machinery and approval-like claims. |
