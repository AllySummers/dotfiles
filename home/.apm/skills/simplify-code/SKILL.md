---
name: simplify-code
description: Review or simplify code that is hard to follow, repeats a rule, or handles failures it cannot usefully recover from.
---

# Simplify code

For a review, explain the proposed improvements. For a cleanup, keep edits within scope and preserve supported inputs and caller-visible results, errors, and side effects. Check the changes through the usual entry points.

## Review criteria

- Trace a representative call from input to result. Use the project's names for the things it works with. Prefer a clear branch or a named intermediate value when a compact expression makes the reader work backwards.
- Imagine removing a helper. If its callers would repeat the same decision, the helper earns its place. If each caller would become a straightforward call to an existing operation, consider inlining it. Avoid adding options, hooks, or extension points without a current use.
- Look on both sides of the diff for an existing implementation of the same rule. Before consolidating, compare inputs, ordering, errors, and side effects. Keep code separate when the two rules have different reasons to change.
- Trace each questionable guard, retry, default, or catch to a real failure and its caller. Keep validation where untrusted data enters and recovery that provides an outcome the caller can use. If a failed lookup becomes an empty list, check whether callers must distinguish an outage from a successful search with no matches. If surfacing the error would improve the contract, name the affected callers and propose the behavior change separately.
- Consider changing the surrounding design when a small patch adds another workaround. Name what the broader refactor removes and who benefits.
