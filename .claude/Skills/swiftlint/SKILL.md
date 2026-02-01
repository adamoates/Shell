---
name: swiftlint
description: Run SwiftLint (or a lightweight style check) to keep Shell's Swift code consistent and clean. Use before committing, after refactors, or when code-quality warnings creep in.
argument-hint: [--autocorrect]
---

# SwiftLint Skill

Run SwiftLint (or a lightweight style check) to keep Shell's Swift code consistent and clean.

## When to use

- Before committing Swift changes.
- After large refactors.
- When code-quality warnings start to creep in.

## Prerequisites

- Prefer: `brew install swiftlint`
- If SwiftLint is not installed, fall back to simple `swift format` / custom grep checks where possible.

## Steps

1. Detect SwiftLint availability:

   - Run `swiftlint version`.
   - If it fails, inform the user:
     - "SwiftLint is not installed. You can install it with: `brew install swiftlint` (recommended for Shell)."

2. If SwiftLint is available, run:

   ```bash
   swiftlint lint --quiet
   ```

3. Collect and group results:

   - Group by:
     - File path.
     - Rule identifier (e.g., `line_length`, `force_cast`).

4. Present a summary:

   - Number of violations per rule.
   - Top 5 files with most violations.

5. For each violation type, provide guidance:

   - `line_length`: Suggest breaking lines or extracting helpers.
   - `force_unwrapping` / `force_cast`: Suggest safe optional handling or casting.
   - `cyclomatic_complexity`: Suggest splitting methods or refactoring logic.
   - Any custom rules used in Shell's `.swiftlint.yml` (if present).

6. Optionally, run SwiftLint autocorrect (ONLY if user confirms or passes `--autocorrect`):

   ```bash
   swiftlint autocorrect
   ```

   - Warn the user that autocorrect may cause large diffs and should be followed by:
     - `git diff`
     - Re-running tests.
