---
name: cross-model-review
description: Run an independent OpenAI and Anthropic code review when the user asks for both model families, then verify and consolidate the findings.
disable-model-invocation: true
---

# Cross-model review

Launch reviewers only when the user invokes `cross-model-review`. An editor-provided reference to this file is context only.

Use [code-review](../code-review/SKILL.md) as the review standard. If skills live in separate packages, locate it by name. The two reviewers inspect the code independently. You check their findings and give the user one report.

## Give both reviewers the same brief

Give both reviewers the same checkout and file scope. For a branch or PR, specify the base and head commits. For local work, point them to the working tree that contains the edits and specify staged, unstaged, or both. A working-tree review defaults to both and includes relevant untracked files.

Let each reviewer obtain its own diff with Git. If either lacks Git access, cannot see the requested revision or local edits, or the checkout is changing during review, capture the patch once and give it to both. For local changes, label the staged and unstaged patches and include relevant untracked file contents within scope. Supply matching caller and test excerpts as needed. If a reviewer reports missing input after launch, provide the shared material and resume the review.

Include the user's constraints, the repository instructions that apply to the files under review, and the locations of the review skill and its specialists. Put the relevant criteria or source excerpts directly in the brief when a reviewer cannot read them.

## Run the reviewers

Start one read-only subagent per model family, each in a fresh context with the same brief. When the host supports parallel runs, submit both launches in one batch or make two nonblocking launch calls before waiting for either result. Run them sequentially only when the host requires it. Collect both results without sharing either reviewer's findings with the other.

Ask each for findings with a location, the affected behavior or maintenance cost, and supporting evidence. Use the configured models at their usual effort for routine changes. For a risky migration, concurrency change, or cross-module redesign, request higher effort from both when the host allows it.

In Cursor, Copilot, and VS Code Local, delegate to the named subagents `review-openai` and `review-anthropic`.

- **Cursor** uses the model in each agent's definition and can substitute another when account or plan restrictions apply.
- **Copilot CLI** needs a concrete parent model for a two-family review. With Auto, subagents can inherit the same resolved session model. A required model that is unavailable can also prevent dispatch.
- **Copilot in VS Code** can omit the required-model policy, strict tool list, and repository-instruction setting when it converts an agent definition. Check the effective reviewer tools and use a read-only session if needed.
- **VS Code Local** accepts a model on each `runSubagent` call. Pass the qualified model name available in the session for each named reviewer, using GPT for `review-openai` and Claude for `review-anthropic`. Honor a requested model or effort when supported.
- **Paseo** is an option when the user requests it or is already running the review there without a native pair. Choose one Codex and one Claude Code reviewer from the available profiles or providers. Give both the same checkout and a read-only mode. Outside Paseo, report a missing native reviewer as a partial review.

Report the model confirmed by the runtime for each reviewer. If only the configured model is visible, label it “configured only.” If a reviewer fails or both run the same family, report the partial coverage and continue with the findings you can verify.

## Verify and report

Check every distinct claim, including those raised by just one reviewer. Trace the real caller, read the relevant assertion, or run a focused check when that settles the question. Agreement alone is insufficient evidence. For example, recommend deleting a test for overlap only after checking that surviving assertions catch every distinct regression it covers.

Report verified findings in priority order using the code-review format. Combine findings with the same cause, separate optional refactors from defects, and surface a material unresolved question only when you can say what evidence is missing. A clean review can say so in one sentence. Briefly identify the reviewers and any coverage limits.
