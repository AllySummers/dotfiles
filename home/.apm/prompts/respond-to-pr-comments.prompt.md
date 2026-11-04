---
description: Triage and fix PR review comments pasted into chat.
---

# respond-to-pr-comments

You are helping the user triage and fix comments from a GitHub PR that they have pasted directly into the chat.

## Step 1: Parse the pasted comments

The user will paste one or more PR review comments directly into the chat. Each comment may include:

- The author's name or handle
- The file path and/or line number the comment references
- The comment body

There is no need to fetch anything from GitHub — work entirely from what the user has provided.

## Step 2: Analyze every comment

For **each comment**, categorize it as one of:

- **✅ Fixed** — You made code changes to address the feedback
- **⏭️ Skipped (not applicable)** — The comment is outdated, already addressed, purely informational, a compliment, or a question with no action required
- **🤔 Needs decision** — Ambiguous, involves a design tradeoff, or requires the user to make a product/architecture call before you can act

When a comment is fixable:

- Read the relevant file(s) mentioned in the comment (search the codebase if no exact path is given)
- Apply the fix directly in the codebase
- Mark as ✅ Fixed

When a comment is **not applicable**, briefly note why (e.g. "already addressed in code", "informational only").

When a comment **needs a decision**, summarize the tradeoff or question clearly so the user can quickly decide.

## Step 3: Report fixes and ask before committing

Before committing anything, present the summary from Step 4 below, then ask:

> I've made the following fixes locally. Would you like me to commit and push them?

Only proceed with committing if the user says yes.

If the repo uses Graphite (`.git/.graphite_repo_config` exists) and the user confirms:

```bash
gt modify -a
gt submit --stack
```

If not using Graphite and the user confirms:

```bash
git add -A
git commit -m "fix: address PR review comments"
git push
```

## Step 4: Report to the user

Present a clear summary table:

```
## PR Comment Summary

### ✅ Fixed (N)
- [Comment by @author on `file.ts:42`] Brief description of what was fixed

### ⏭️ Skipped — Not applicable (N)
- [Comment by @author] Reason it was skipped

### 🤔 Needs your decision (N)
- [Comment by @author] Summary of the tradeoff/question
  → Options: A) ... B) ...
```

## Notes

- Only fix comments that are clearly valid — do not make speculative changes based on vague or ambiguous feedback without first flagging it as "needs decision".
- If a file path is mentioned in the comment, read that file before making changes. If only a snippet or description is given, search the codebase to locate the relevant code.
- Do not post any GitHub replies — this command works entirely offline from pasted input.
