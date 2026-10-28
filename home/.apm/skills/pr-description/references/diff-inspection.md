# Inspect moves, splits, and reverts

Use the relevant read-only commands when moves, renames, file splits, or formatting inflate a diff, or when checking whether a revert restores an earlier version. These are inspection aids, not a mandatory command checklist.

Replace `<base>` below with the verified base. Use `HEAD` only when it is the head being described; otherwise substitute the verified remote head SHA in every command. Keep both refs the same across comparisons.

Spot renames and moves:

```sh
git diff -M --stat <base>...HEAD
```

Look for rename notation such as `{old => new}`. A renamed file with `| 0` has no content changes; its new path can still affect behavior.

If a source file survives a split, try copy detection and inspect both paths:

```sh
git diff -M -C --stat <base>...HEAD
git diff -M -C <base>...HEAD -- <old-path> <new-path>
```

`-M` alone can miss this case. `-C` can identify an extraction from a source modified in the same change. If the source is unchanged, `--find-copies-harder` broadens the search but can be expensive. Similarity percentages and changed-line counts are heuristics, not measures of semantic change. Read the actual edits; do not add moved-line counting machinery just to write a description.

Compare the stats with and without whitespace changes:

```sh
git diff --stat <base>...HEAD
git diff -w --stat <base>...HEAD
```

A large drop suggests formatting or indentation churn. If helpful, link the PR's Files changed view with `?w=1` (or `&w=1` if it already has a query) so reviewers can hide whitespace changes. Still inspect whitespace that affects meaning, such as Python indentation or spaces inside strings.

Inspect moved blocks and edits within them:

```sh
git diff --color-moved=zebra --color-moved-ws=allow-indentation-change <base>...HEAD
```

Use a color-capable terminal, or add `--color=always` when capturing output. Treat the highlights as clues; read the old and new code before claiming behavior is unchanged.

To check an exact restoration, compare the file trees directly:

```sh
git diff <commit-before-original-change> HEAD -- <reverted-paths>
```

An empty diff establishes identical content only for those paths. It does not prove that all surrounding behavior is restored or that the original root cause is fixed. Name the limited scope if other files differ.

Describe the move and any behavior changes separately. Do not tell reviewers to ignore moved code wholesale.
