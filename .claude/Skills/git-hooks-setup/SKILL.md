---
name: git-hooks-setup
description: Create fast, helpful Git hooks for Shell that improve quality without slowing you down. Use during initial setup or when standardizing pre-commit/pre-push checks.
argument-hint: [pre-commit|pre-push|all]
---

# Git Hooks Setup Skill

Create fast, helpful Git hooks for Shell that improve quality without slowing you down.

## When to use

- Initial project setup on a new machine.
- When you want pre-commit / pre-push checks standardized.
- After adding new Skills (lint, tests) you want to hook into Git.

## Goals

- Lightweight local hooks that:
  - Catch obvious issues before commit/push.
  - Respect developer speed (no heavy operations on every commit).

## Hooks to set up

- `pre-commit`:
  - Optional: SwiftLint on changed Swift files.
  - Optional: `swiftformat` / basic formatting checks.
- `pre-push`:
  - Optional: run fast tests (e.g., regression suite or feature tests).
  - Confirm no TODO/DEBUG markers in committed code (if desired).

## Steps

1. Confirm repo and hooks directory

   - Ensure we're in the Shell repo root.
   - Ensure `.git/hooks/` exists.

2. Propose `pre-commit` hook

   - Create or update `.git/hooks/pre-commit` with something like:

     ```bash
     #!/bin/sh
     # Shell pre-commit hook: fast local checks

     echo "Running Shell pre-commit checks..."

     # 1. SwiftLint on staged Swift files (if swiftlint is installed)
     if command -v swiftlint >/dev/null 2>&1; then
       STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$' || true)
       if [ -n "$STAGED_FILES" ]; then
         echo "SwiftLint on staged files..."
         echo "$STAGED_FILES" | xargs swiftlint lint --quiet --path
       fi
     else
       echo "SwiftLint not found (skipping lint)."
     fi

     # 2. Optional: prevent committing TODO / FIXME
     FORBIDDEN=$(git diff --cached --name-only --diff-filter=ACM | xargs grep -nE 'TODO|FIXME' || true)
     if [ -n "$FORBIDDEN" ]; then
       echo "Found TODO/FIXME markers in staged files:"
       echo "$FORBIDDEN"
       echo "Commit aborted. Please address or remove TODO/FIXME or commit with --no-verify if intentional."
       exit 1
     fi

     exit 0
     ```

   - Mark it executable:

     ```bash
     chmod +x .git/hooks/pre-commit
     ```

3. Propose `pre-push` hook (optional)

   - Create or update `.git/hooks/pre-push` with something like:

     ```bash
     #!/bin/sh
     # Shell pre-push hook: quick sanity checks

     echo "Running Shell pre-push checks..."

     # Optionally run a fast regression suite or feature tests:
     # (Adjust the command to your preferred subset or call the regression-suite Skill logic.)
     xcodebuild test \
       -scheme Shell \
       -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
       -only-testing:ShellTests/LoginViewModelTests \
       -only-testing:ShellTests/Features/Items \
       -only-testing:ShellTests/Features/Profile

     STATUS=$?
     if [ $STATUS -ne 0 ]; then
       echo "Tests failed. Push aborted."
       exit $STATUS
     fi

     exit 0
     ```

   - Mark it executable:

     ```bash
     chmod +x .git/hooks/pre-push
     ```

4. Keep hooks fast

   - Emphasize in comments:
     - Hooks should run in seconds, not minutes.
     - Heavy operations (full test suite, `git gc`) should be triggered manually or via CI, not every commit.

5. Summarize

   - Which hooks were created/updated.
   - What they do.
   - How to temporarily bypass them if needed:

     ```bash
     git commit --no-verify
     git push --no-verify
     ```

   - Recommend using bypass only in emergencies, then fixing issues and re-enabling normal flow.
