---
name: git-maintenance
description: Keep the Shell repo fast and healthy by automating safe Git maintenance. Use periodically, after big features, or when Git operations feel slow.
argument-hint: [--gc]
---

# Git Maintenance Skill

Keep the Shell repo fast and healthy by automating safe Git maintenance.

## When to use

- Periodically (e.g., once a week).
- After finishing a big feature branch.
- When Git operations (status, fetch, log) start feeling slow.

## Goals

- Remove stale remote branches.
- Clean up local merged branches (with your approval).
- Keep objects packed and repo size under control, without risky operations.

## Steps

1. Show current repo status

   - Run:

     ```bash
     git status
     git remote -v
     ```

   - Confirm we are in the expected repository (Shell iOS project).

2. Prune remote tracking branches

   - Run:

     ```bash
     git fetch --prune
     git remote prune origin
     ```

   - Explain: this removes local references to branches that were deleted on the remote.

3. Suggest local branch cleanup

   - List merged local branches:

     ```bash
     git branch --merged main
     ```

   - Exclude important branches:
     - `main`
     - `develop` (if it exists)
     - Any `epic/*` unless user confirms.

   - Ask the user which merged branches to delete, then run:

     ```bash
     git branch -d <branch-name>
     ```

4. Optional: pack objects and clean up

   - Ask the user if they want to run lightweight garbage collection (or check for `--gc` argument):

     ```bash
     git gc
     ```

   - Explain:
     - This repacks objects and cleans up unnecessary files.
     - Recommended occasionally; avoid `--aggressive` unless repo is extremely large and user explicitly requests it.

5. Check for large files (optional)

   - Run a simple size scan, for example:

     ```bash
     git rev-list --objects --all | sort -k 2 > /tmp/git-objects.txt
     ```

   - Optionally warn if obviously large binary assets (e.g., > 5–10 MB) are found and suggest:
     - Moving them out of the repo.
     - Or using Git LFS if that ever becomes necessary.

6. Summarize maintenance

   - Number of remote refs pruned.
   - Local branches deleted.
   - Whether `git gc` was run.
   - Any warnings about large files or unusual conditions.
