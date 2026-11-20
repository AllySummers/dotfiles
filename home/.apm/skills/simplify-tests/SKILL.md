---
name: simplify-tests
description: Review or simplify tests when coverage overlaps, fixtures and mocks obscure behavior, or it is unclear which regressions a test would catch.
---

# Simplify tests

For a review, identify tests worth keeping, simplifying, or removing where the choice needs explanation. For a cleanup, make the supported changes and run the affected tests. Keep the size of the suite proportional to the behavior it protects.

## Review criteria

- Name a plausible change that would break the behavior and make this test fail. Check what the assertion actually observes. A test can pass for the wrong reason when its mock supplies the answer, its expected value comes from the function under test, or an earlier guard rejects the input. If a mock supplies the very behavior being asserted, replace the assertion when that contract still needs coverage. Otherwise remove it.
- Before deleting a test for overlap, account for every distinct outcome it protects. For each, point to a surviving assertion that catches the same regression or explain why the behavior is no longer required. If two tests check the return value but only one reads the value back from storage, keep the persistence check. Remove a duplicate assertion on its own when the rest of the test still catches a different regression.
- Prefer the simplest fixture and public entry point that exercise the behavior. Replace assertions about private calls with checks on outcomes when possible. Keep interaction checks when the interaction itself matters, for example charging a customer exactly once.
- Combine cases that exercise the same rule when a short table makes their meaningful differences obvious. Keep cases separate when their setups, failure modes, or explanations differ. Remove setup and test-only helpers that the remaining tests no longer need.
- Before proposing a new test, see whether an existing one already catches the regression or could cover it with a clearer assertion. A one-line pass-through already exercised by its caller, or a refactor that preserves behavior, may need no new test. Give particular weight to prior bugs and distinct boundary cases. A failing test is evidence to investigate before changing it.
