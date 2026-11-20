---
name: clarify-docs
description: Review or edit technical guides, READMEs, and reference pages so readers can complete their task. Clarify the prose and cut duplication with code or other pages.
---

# Clarify docs

Identify the reader and what they came to do. For a review, point out passages that get in their way and suggest a replacement or a better home. For an edit, revise the relevant pages and check the claims and links you touched.

## Review criteria

- Keep the instructions, examples, and decisions a reader needs to use, operate, or troubleshoot the software. Check commands, defaults, names, and promised behavior against the current source. Preserve details that change what the reader should do.
- Give each fact a home. For example, a setup guide can show the two settings needed to get started and link to the complete configuration reference. For a maintainer who needs the implementation, link to a stable file or name the owning symbol. Give users the public answer directly when they cannot reasonably get it from the source.
- Question standalone Markdown that walks through functions in order, repeats a diff, or records a finished task. Check what would be lost if it went away. A lasting constraint may belong next to the code. If its new home is outside the requested files, suggest the move and keep the explanation until readers can find it there. Check incoming links before removing a page.
- Use the project's vocabulary and concrete verbs. Replace “the service facilitates graceful degradation” with what the reader will observe, such as “if the server is offline, the app opens the last saved copy.” Verify the replacement is true. Keep precise technical terms and explain unfamiliar ones when the audience needs it.
- Cut preambles, repeated conclusions, and examples that all teach the same thing. Add an example when it answers a real question more clearly than another paragraph.
