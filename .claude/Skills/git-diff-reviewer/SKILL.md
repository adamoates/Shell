---
name: git-diff-reviewer
description: AI-powered diff reviewer that classifies changes and flags risky modifications. Use before commits/PRs to catch potential issues.
argument-hint: [base-branch]
---

# Git Diff Reviewer Skill

An AI-powered diff reviewer that analyzes your changes, classifies them, and flags risky modifications.

## When to use

- Before creating a pull request.
- Before committing major changes.
- When you want a second pair of eyes on your changes.
- To understand what changed in a feature branch.

## What it does

- Shows diff for current branch vs main (or specified base branch).
- Classifies changes by type (feature, refactor, tests, docs, config).
- Flags risky changes that need extra scrutiny.
- Provides a summary of the impact and scope.

## Steps

1. Determine base branch

   - Use argument if provided (e.g., `main`, `develop`).
   - Otherwise default to `main`.
   - Confirm the base branch exists.

2. Collect diff statistics

   - Run:

     ```bash
     git diff --stat <base-branch>...HEAD
     ```

   - Show:
     - Number of files changed.
     - Insertions/deletions.
     - Which directories are affected.

3. Get detailed diff

   - Run:

     ```bash
     git diff <base-branch>...HEAD
     ```

   - Limit output to reasonable size (e.g., first 10,000 lines if needed).

4. Classify changes

   Analyze the diff and group changes into categories:

   **Features:**
   - New ViewModels, Views, or Use Cases.
   - New API endpoints or repositories.
   - New domain models or business logic.

   **Refactors:**
   - Code moves or renames.
   - Extraction of methods/classes.
   - Architecture improvements (e.g., coordinator changes).

   **Tests:**
   - New test files or test cases.
   - Test fixture updates.
   - Mock/spy implementations.

   **Documentation:**
   - README updates.
   - Code comments.
   - Architecture docs.

   **Configuration:**
   - `.xcodeproj` changes.
   - Build settings.
   - Dependencies (package manifests).
   - CI/CD config.

5. Flag risky changes

   Automatically flag for extra scrutiny:

   **High Risk:**
   - `.xcodeproj` modifications (merge conflicts common).
   - Repository implementations (data integrity).
   - Concurrency-sensitive code (`actor`, `Task`, `await`, threading).
   - Authentication/security code.
   - Database migrations or schema changes.

   **Medium Risk:**
   - Coordinator changes (navigation flow impacts).
   - Dependency injection container changes.
   - Error handling modifications.
   - Public API changes.

   **Low Risk:**
   - UI-only changes (views, styling).
   - Test additions (no production code changes).
   - Documentation updates.
   - Comment additions.

6. Analyze specific patterns

   Search for potentially problematic patterns:

   - Force unwraps (`!`) added.
   - `TODO` or `FIXME` comments added.
   - Large functions added (>50 lines).
   - Commented-out code blocks.
   - Print statements or debug code.
   - Hard-coded values (URLs, credentials).

7. Generate review summary

   Provide a structured summary:

   ```markdown
   # Git Diff Review: <branch-name> → <base-branch>

   ## Summary
   - **Files changed:** X
   - **Insertions:** +XXX
   - **Deletions:** -XXX
   - **Main areas:** Feature/Domain/Tests/Config

   ## Change Classification

   ### Features (X files)
   - New HTTPItemsRepository implementation
   - Added profile editor view

   ### Refactors (X files)
   - Extracted validation logic to IdentityData
   - Renamed SetupIdentityUseCase → CompleteIdentitySetupUseCase

   ### Tests (X files)
   - Added HTTPItemsRepositoryTests
   - Updated ProfileEditorViewModelTests

   ### Documentation (X files)
   - Updated README with backend setup
   - Added ARCHITECTURE.md

   ## Risk Flags

   ### 🔴 High Risk
   - **Shell.xcodeproj/project.pbxproj** - Project file changes (merge conflicts likely)
   - **HTTPItemsRepository.swift** - New repository implementation (test thoroughly)

   ### 🟡 Medium Risk
   - **ProfileCoordinator.swift** - Navigation flow changes
   - **AppDependencyContainer.swift** - DI changes affect entire app

   ### 🟢 Low Risk
   - **ProfileEditorView.swift** - UI-only changes
   - **README.md** - Documentation update

   ## Patterns to Review

   - ❌ 3 force unwraps added (file.swift:42, file.swift:87, file.swift:103)
   - ⚠️  2 TODO comments added
   - ✅ No commented-out code
   - ✅ No hard-coded credentials

   ## Recommendations

   1. Review `.xcodeproj` changes carefully for merge conflicts
   2. Ensure HTTPItemsRepository has comprehensive tests
   3. Consider refactoring force unwraps to safe optional handling
   4. Address TODO comments before merging
   ```

8. Offer next actions

   - Run specific tests: `/test-feature Items`
   - Check architecture: `/architecture-check`
   - Lint code: `/swiftlint`
   - Create PR (if review looks good)
   - Address flagged issues first

## Tips

- Run this before creating PRs to catch issues early.
- Use with `/ci-checklist` for complete pre-merge validation.
- Diff review + simulator review gives full picture (code + visual).
