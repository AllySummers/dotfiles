---
name: code-review
description: Review a diff, pull request, or selected code for correctness and maintainability. Use when asked for code review or a cleanup review.
---

# Code review

Start with what the change promises its callers. Read the diff against the intended base for a branch or PR. For a working-tree review, include staged, unstaged, and relevant new files. For a named file or function, start there. Follow the actual entry points and check whether existing callers still get the results and errors they rely on.

## Choose the relevant criteria

Read the linked **Review criteria** sections as needed. Each belongs to a standalone skill. If the host stores skills separately, locate the linked skill by name. During a review, use its criteria to assess the change and collect findings. Edit files only when the user asks for fixes.

- [Simplify code](../simplify-code/SKILL.md#review-criteria) for names, control flow, abstractions, fallbacks, and refactors that could make the whole change easier to follow.
- [Simplify tests](../simplify-tests/SKILL.md#review-criteria) when tests change or a change in behavior raises a question about coverage.
- [Clarify docs](../clarify-docs/SKILL.md#review-criteria) when prose changes, a documented promise might be stale, or a reader needs guidance.
- [Write better comments](../write-better-comments/SKILL.md#review-criteria) when a comment may mislead a maintainer or a non-obvious constraint needs explaining.

## Report findings

Lead with the most consequential finding. Give the file and line or symbol, the behavior or maintenance cost you verified, and a concrete improvement. Distinguish bugs from optional refactors. A larger change is worth proposing when you can name the callers it simplifies or the duplication it removes. Respect the requested edit scope even when a recommendation reaches beyond it.

Group findings that have one cause. For example, if a fallback exists only to satisfy a mock, check the real caller before recommending changes to the fallback, the test, or the docs describing it. Give one recommendation that accounts for all three.

Use the terms people use in this project. Skip speculative issues and style preferences with no concrete benefit. If there are no findings, say so briefly. Mention any material limit on what you could verify.
