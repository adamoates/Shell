---
name: ci-checklist
description: Ensure Shell is in a CI-ready state - builds, tests, lint, and settings all clean. Use before merging to main, before tagging a release, or when preparing CI pipeline.
argument-hint: [feature-name]
---

# CI Checklist Skill

Ensure Shell is in a CI-ready state: builds, tests, lint, and settings all clean.

## When to use

- Before merging to `main`.
- Before tagging a release (e.g., v1.1.0, v2.0.0).
- When preparing or updating your CI pipeline.

## Steps

1. Confirm clean working tree:

   - Run `git status`.
   - If there are uncommitted changes, show them and ask:
     - "Do you want to continue CI checks on this dirty tree, or should we commit/stash first?"

2. Run full unit test suite:

   ```bash
   xcodebuild test \
     -scheme Shell \
     -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
   ```

   - Capture:
     - Success/failure.
     - Duration.
     - Number of tests run.
     - First failing test (if any).

3. Optionally run feature-focused tests:

   - If the user specifies a feature (e.g., "Items" or "Profile"), call the logic from the `test-feature` Skill to run those tests as well.

4. Run SwiftLint (if available):

   - Re-use the logic from the `swiftlint` Skill.
   - Summarize any blocking issues (e.g., force unwraps, serious style violations).

5. Verify key build settings:

   - Parse project settings via `xcodebuild -showBuildSettings` for the `Shell` target.
   - Check:
     - Swift version set to 6.
     - Deployment target matches project standard.
     - No obvious misconfigurations (e.g., `ENABLE_TESTABILITY` disabled for tests).

6. Output a CI readiness report:

   - ✅ / ❌ Build & tests.
   - ✅ / ❌ Lint (if configured).
   - ✅ / ❌ Key build settings.
   - Recommended CI command block for the future pipeline:

     ```bash
     xcodebuild test \
       -scheme Shell \
       -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
     swiftlint lint --quiet   # if using SwiftLint
     ```
