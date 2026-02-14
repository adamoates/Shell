---
name: regression-suite
description: Run a curated set of tests that cover Shell's critical flows. Use before merging bigger changes, before tagging a release, or after updating dependencies.
argument-hint: [additional-test-pattern]
---

# Regression Suite Skill

Run a curated set of tests that cover Shell's critical flows.

## When to use

- Before merging bigger changes (e.g., new features, major refactors).
- Before tagging a release.
- After updating dependencies or Swift versions.

## Scope

Focus on high-value, end-to-end aspects:

- Auth/Login flow.
- Items list and editing (Epic 2).
- Profile viewing and editing (including SwiftUI ProfileEditor).
- Any future high-risk areas (e.g., networking once Epic 3 is in).

## Steps

1. Define or confirm the regression test list:

   - Unit/integration tests:
     - `LoginViewModelTests`
     - `Items*UseCaseTests`
     - `ItemsRepositoryTests`
     - `ProfileViewModelTests`
     - `ProfileEditorViewModelTests`
   - UI tests (once meaningful UI tests are added).

2. Ask the user:

   - "Do you want the default regression suite, or specify additional tests?"

3. Run the subset via `xcodebuild`:

   - Example (adjust to project's test structure):

     ```bash
     xcodebuild test \
       -scheme Shell \
       -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
       -only-testing:ShellTests/LoginViewModelTests \
       -only-testing:ShellTests/Items... \
       -only-testing:ShellTests/Profile...
     ```

   - Or run all unit tests but skip known-placeholder UI tests, if that is more reliable.

4. Summarize:

   - Total tests in regression suite.
   - Pass/fail.
   - Any failing test names and error messages.

5. Recommend actions on failure:

   - Inspect failing test files.
   - Check recent diffs for affected features.
   - Re-run regression suite after fixes.

6. Optionally, maintain a `Docs/RegressionSuite.md`:

   - Keep an up-to-date list of which tests count as "regression-critical".
   - This Skill can read and use that list to stay in sync.
