---
name: release-notes
description: Generate structured release notes for Shell based on git history. Use before tagging a new release or when preparing changelog entries.
argument-hint: [from-tag] [to-tag]
---

# Release Notes Skill

Generate structured release notes for Shell based on git history.

## When to use

- Before tagging a new release (e.g., v1.1.0, v2.0.0).
- When preparing changelog entries.

## Steps

1. Ask the user for the release range:

   - From tag/commit: e.g., `v1.0.0` to `HEAD`.
   - Or use the most recent tag as the base by default.

2. Collect commits in that range:

   ```bash
   git log <from>..<to> --oneline
   ```

3. Classify commits based on message prefixes (if present):

   - `feat:` → Features.
   - `fix:` → Bug fixes.
   - `refactor:` → Refactors.
   - `docs:` → Documentation.
   - `test:` → Testing.
   - `chore:` → Chores / infra.

4. Generate structured notes, for example:

   ```markdown
   # Shell v1.1.0

   ## Features
   - …

   ## Bug Fixes
   - …

   ## Architecture & Refactors
   - …

   ## Documentation
   - …

   ## Testing
   - …
   ```

5. Highlight important technical changes:

   - New patterns (e.g., HTTP repositories, new Skills).
   - Significant architecture changes.
   - New dependencies or Swift version updates.

6. Output:

   - Markdown block suitable for:
     - `CHANGELOG.md`
     - GitHub/GitLab release notes.
     - Tag annotations.

7. Optionally, offer to:

   - Append to `CHANGELOG.md`.
   - Create an annotated tag with these notes.
