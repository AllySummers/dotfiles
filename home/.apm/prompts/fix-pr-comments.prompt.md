---
description: Triage and fix review comments from a GitHub or Graphite PR URL.
---

# fix-pr-comments

You are helping the user triage and fix comments on a GitHub or Graphite PR.

## Step 1: Parse the PR link

The user will provide a GitHub PR URL (e.g. `https://github.com/owner/repo/pull/123`) or a Graphite PR URL (e.g. `https://app.graphite.dev/github/pr/owner/repo/123`). Extract:
- `owner` — the GitHub org or user
- `repo` — the repository name
- `pullNumber` — the PR number

## Step 2: Fetch PR data

Using the GitHub MCP server, fetch in parallel:
1. PR details: `pull_request_read` with `method: "get"` — to understand the PR's purpose, title, and description
2. Review comments: `pull_request_read` with `method: "get_review_comments"` — inline code review threads
3. General comments: `pull_request_read` with `method: "get_comments"` — top-level PR discussion comments
4. Changed files: `pull_request_read` with `method: "get_files"` — to understand what was changed

## Step 3: Check out the correct branch

If the repo uses Graphite (`.git/.graphite_repo_config` exists), use `gt checkout <branch>`. Otherwise use `git checkout <branch>`. Get the branch name from the PR details fetched in Step 2.

## Step 4: Analyze every comment

For **each comment** (both review threads and general comments), categorize it as one of:

- **✅ Fixed** — You made code changes to address the feedback
- **⏭️ Skipped (not applicable)** — The comment is outdated, already addressed, purely informational, a compliment, or a question with no action required
- **🤔 Needs decision** — Ambiguous, involves a design tradeoff, or requires the user to make a product/architecture call before you can act

When a comment is fixable:
- Read the relevant file(s) and the diff context from the comment
- Apply the fix directly in the codebase
- Mark as ✅ Fixed

When a comment is **not applicable**, briefly note why (e.g. "already addressed in code", "informational only", "resolved thread").

When a comment **needs a decision**, summarize the tradeoff or question clearly so the user can quickly decide.

## Step 5: Report fixes and ask before committing

Before committing anything, present the summary from Step 6 below, then ask:

> I've made the following fixes locally. Would you like me to commit and push them?

Only proceed with committing if the user says yes.

If the repo uses Graphite and the user confirms:
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

## Step 6: Report to the user

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

## Step 7: Ask about replies

After presenting the summary, ask:

> Would you like me to reply to any of these comments on GitHub? I can reply to:
> - All fixed comments (marking them as addressed)
> - Specific comments you choose
> - Comments that need a decision (to ask a clarifying question)

If the user says yes (to all or specific ones), use `add_reply_to_pull_request_comment` from the GitHub MCP server to post replies.

For **fixed comments**, reply with a short note explaining what was changed, e.g.:
> "Fixed — [brief description of the change made]. Thanks!"

For **needs-decision comments**, reply with a clarifying question or ask for guidance.

**Important:** Append the current AI disclosure footer to every GitHub reply, using only known identifiers and `unavailable` for unknown values:
> _AI-assisted — Tool: <tool>; model: <provider>/<model>; version: <version-or-unavailable>._

## Notes

- Always use the **GitHub MCP server** for all GitHub operations (reading comments, posting replies). Do not use the `gh` CLI.
- If the Graphite MCP server is available, prefer it for navigating branches, but use the GitHub MCP for comment/review operations.
- Only fix comments that are clearly valid — do not make speculative changes based on vague or ambiguous feedback without first flagging it as "needs decision".
- If a review thread is already marked as resolved (`isResolved: true`), skip it unless the comment itself clearly still applies.
- Do not resolve threads on GitHub yourself — let the PR author (user) do that after reviewing your fixes.
