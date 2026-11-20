---
name: write-better-comments
description: Review or rewrite existing inline comments, docstrings, and API doc comments in source files for clarity, accuracy, and lasting value.
---

# Write better comments

Use the files or selection the user identified. If the target is unclear, ask which comments to review. In a review, recommend changes. For a comments-only cleanup, edit existing comments and leave executable code alone. Suggest a rename, refactor, or missing comment separately when it would help.

## Review criteria

- Read the surrounding code and check the claim. Remove comments that narrate obvious steps, describe the author's process, or repeat a name or type. Replace stale history with the constraint that still matters.
- Keep the detail a future maintainer could accidentally break. Explain a non-obvious invariant, trade-off, workaround, or externally imposed behavior close to the decision it affects. For example, “The provider can return 404 briefly after creation, so retry this lookup” explains why the retry belongs here.
- Use ordinary words and the same names as the code. If a clearer identifier would carry the whole meaning, recommend it. When an issue or specification explains a workaround, include the essential reason in the comment and use the link for further detail or its removal condition.
- Preserve meaningful API documentation about units, ownership, errors, side effects, or obligations callers cannot infer from a signature. A useful public example can earn its length.
- Check whether tools consume a comment before editing it. Preserve the parts that tools rely on and their placement. For type directives, lint suppressions, build tags, doctests, generated-file markers, and license notices, edit only the surrounding explanatory prose.
