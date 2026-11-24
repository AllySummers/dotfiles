---
name: code-review
description: Review a diff, pull request, or selected code for correctness and maintainability. Use when asked for code review or a cleanup review.
disable-model-invocation: true
---

# Code review

Start a standalone review only when the user invokes `code-review`. An explicitly invoked `cross-model-review` can use the criteria below. An editor-provided reference to this file is context only.

Start with what the change promises its callers. For a named file or function, start there. For a branch or PR, use the supplied patch or compare its commits with `git diff <base>...<head>`. Read callers and tests at the reviewed head.

For a working-tree review, run Git from the repository root and inspect both sets of changes unless the user asks for one. Use `git --no-optional-locks` for Git reads when the index must stay untouched.

- **Staged** changes are in `git diff --cached`. When a file also has unstaged edits, read its staged version with `git show :path/to/file`.
- **Unstaged** changes to tracked files are in `git diff`. Also read relevant new files listed by `git ls-files --others --exclude-standard`, unless the user limited the review to tracked files.

Keep the comparisons separate when the same file has both kinds of edits. An unstaged edit can undo a staged one. Identify which version a finding affects. Follow the actual entry points and check whether callers still get the results and errors they rely on.

## Choose the relevant criteria

Read and apply the **Simplify code** criteria in every review, along with the other linked **Review criteria** sections that are relevant. If the host stores skills separately, locate the linked skill by name. Edit files only when the user asks for fixes.

- [Simplify code](../simplify-code/SKILL.md#review-criteria) for names, control flow, abstractions, fallbacks, and refactors that could make the whole change easier to follow.
- [Simplify tests](../simplify-tests/SKILL.md#review-criteria) when tests change or a change in behavior raises a question about coverage.
- [Clarify docs](../clarify-docs/SKILL.md#review-criteria) when prose changes, a documented promise might be stale, or a reader needs guidance.
- [Write better comments](../write-better-comments/SKILL.md#review-criteria) when a comment may mislead a maintainer or a non-obvious constraint needs explaining.

## Report findings

Include all concrete findings in the first review response, including bugs, simplification opportunities, optional refactors, and relevant findings about tests, docs, or comments. Lead with the most consequential finding. For each finding, give the file and line or symbol, the behavior or maintenance cost you verified, and a concrete improvement. Distinguish bugs from optional improvements. A larger change is worth proposing when you can name the callers it simplifies or the duplication it removes. Respect the requested edit scope even when a recommendation reaches beyond it.

Group findings that have one cause. For example, if a fallback exists only to satisfy a mock, check the real caller before recommending changes to the fallback, the test, or the docs describing it. Give one recommendation that accounts for all three.

Use the terms people use in this project. Skip speculative issues and style preferences with no concrete benefit. If there are no findings, say so briefly. Mention any material limit on what you could verify.
