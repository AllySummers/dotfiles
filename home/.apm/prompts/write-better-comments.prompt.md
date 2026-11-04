---
description: Improve existing code comments within the requested scope without changing code.
---

# Write Better Comments

Review the existing comments in `$ARGUMENTS` and improve only the comments. If no scope is supplied, use the currently open or selected files; if that is unclear, ask for a scope before editing.

Treat comments as durable documentation for a future maintainer:

- Remove comments that merely restate the code, narrate obvious implementation details, or describe the task, plan, refactor history, or agent reasoning.
- Rewrite useful comments to be concise, local, and evergreen. Keep comments only when they explain a non-obvious constraint, invariant, workaround, trade-off, or externally imposed behaviour.
- Prefer clear names, types, and small functions over explanatory comments. Do not change executable code merely to avoid a comment.
- Preserve and improve meaningful API documentation; do not delete documentation just because it is longer than an inline comment.
- GitHub or Linear issue references are allowed for a durable workaround, follow-up, or removal condition, but the comment must state the essential reason without requiring the reader to open the issue.

Examples:

```ts
// Bad: This was added in step 3 of the migration plan.
// Bad: Loop through users and add each user to the result.
// Good: The provider may return 404 while a new object is propagating; retry briefly. See GH-482.
```

Do not add comments while doing this pass. After editing, report the files reviewed and briefly summarize comments removed or rewritten.
