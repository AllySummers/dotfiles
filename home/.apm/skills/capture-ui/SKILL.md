---
name: capture-ui
description: Capture screenshots, before-and-after comparisons, or short recordings of real UI changes on a local dev server. Use headless Playwright for local demos, bug fixes, and PR media.
---

# Capture UI changes

## Pick the states to show

- Read the request, the relevant diff, and the repo's local development and browser-test instructions. Capture the changed state. Add a before screenshot when the old behavior helps explain the change, the user asks for it, or the PR template requires it. Capture motion when timing or a sequence of actions matters.
- For a PR, use the head and base in scope. For a stacked PR, use this layer's immediate parent. For local changes, use the revision that precedes the requested change, which may be HEAD for a working-tree-only change.
- Run the baseline in a separate checkout or worktree so you can preserve in-progress changes. Use separate dev-server ports for parallel runs and separate databases if the revisions need incompatible migrations. If a needed baseline cannot run, capture the changed state and report the specific blocker.

## Run the local app

- Start or reuse the repo's dev server. Verify which checkout, port, and configuration it is serving. Keep app navigation on the local dev server, including through a verified workspace port forward when needed. Never capture against a deployed app, including a preview deployment. If the local app redirects to a deployed app, fix the local configuration or report the blocker.
- Before seeding or taking actions with side effects, verify the effective database and other write targets the dev server actually uses. Localhost alone proves very little about upstream services. Use local Supabase, local Postgres configured for Neon development, or a repo-supported Neon development setup whose upstream is verified to be an isolated test branch for local development. A Neon Local proxy can also point at an existing hosted branch. Verify its actual upstream before writing. Keep production, staging, and shared databases out of the capture workflow.
- Insert whatever synthetic records the scenario needs in the verified local development database. Prefer existing seed and test-auth workflows. Use scoped inserts or upserts for new fixtures and equivalent data for both revisions. Work around missing services with repo-supported mocks when they can demonstrate the requested UI, and identify them in the handoff.

## Capture with Playwright

- Use headless Playwright for all browser interaction and capture. Never open Chrome or another browser interactively or use browser-use or computer-use tools. If Playwright cannot run, report the blocker.
- Use the repo's Playwright, browser fixtures, and test login when available. For a simple page that is ready without extra actions, use the Playwright screenshot CLI. Use a temporary Playwright script or an existing Playwright flow for interactions. Use the [recording recipe](references/recording.md) for motion and standalone Playwright setup.
- Match the viewport, device settings, theme, role, fixtures, and interaction state across a comparison. Use role- or label-based locators and wait for the data or UI you intend to show. For stills, save PNG with `page.screenshot()` or `locator.screenshot()`. Use `animations: 'disabled'` if movement makes the frame unstable. Frame the UI with enough context to make the change clear.
- Aim for 2560×1440 on full-viewport desktop captures and keep at least 1920×1080 when feasible. Preserve the intended layout for responsive and component shots. For PNGs, use a higher device scale factor when you need more pixels at the same CSS viewport.
- Save deliverables in the requested artifact location or a scratch directory outside tracked source. Inspect the saved media locally for legibility, the intended state or interaction, and accidental exposure of real data, credentials, or tokens. Stop any dev servers started solely for the capture when finished.

## Hand back the media

Return the files with short captions explaining what to notice. For a comparison, label them Before and After and identify the revisions. Mention any mocks or setup differences that affect interpretation.

When working with `pr-description`, hand over the files and captions for its media section. Upload only when the user's request authorizes it.

Use the GitHub CLI for GitHub uploads. Run `gh pr create --attach <file>` or `gh pr edit <pr> --attach <file>` for PRs, repeating `--attach` for each file. Preserve the existing PR body when adding media. To place media in the intended section, use `--body-file` with local Markdown references to the attached files. GitHub CLI rewrites the references to uploaded URLs. Put a video reference such as `![](./demo.mp4)` on its own line so it renders as a player. [GitHub CLI attachment docs](https://docs.github.com/en/github-cli/github-cli/attaching-files-with-github-cli)

Read back the saved PR body with `gh pr view <pr> --json body`. If an upload fails, read back the body before retrying because some attachments may already be saved. If `gh` cannot attach the media, return the local files and report the blocker.
