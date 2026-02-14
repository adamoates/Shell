# Commit Skill

Create a well-formatted git commit following Shell project conventions.

## When to use

When you've completed a logical unit of work and need to commit changes to the repository.

## Steps

### 1. Run pre-commit checks

Before creating any commit, verify the current state:

```bash
# Check git status (never use -uall flag)
git status

# See staged and unstaged changes
git diff HEAD

# Review recent commits to understand commit message style
git log --oneline -5
```

### 2. Analyze changes and draft commit message

Review all changes that will be included in the commit:

**Principles:**
- Focus on **why** the change was made, not just **what** changed
- Use imperative mood ("Add feature" not "Added feature")
- Keep first line under 72 characters
- Add detailed explanation in body if needed
- Follow existing commit style from git log

**Commit message format:**
```
<type>: <short summary>

<optional detailed explanation>
<why this change was needed>
<what problem it solves>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Common commit types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code restructuring without behavior change
- `test:` - Adding or updating tests
- `docs:` - Documentation changes
- `chore:` - Build, dependencies, tooling
- `style:` - Formatting, whitespace (no code change)

**Examples:**

```
feat: Add SwiftUI ProfileEditorView with validation

Implements ProfileEditorViewModel using Combine for reactive form validation.
Integrates with existing CompleteIdentitySetupUseCase via coordinator.
Validates screen name (2-20 chars, alphanumeric) and birthday (13+ years old).

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

```
fix: Resolve type mismatch in ProfileCoordinator

Updates SetupIdentityUseCase reference to CompleteIdentitySetupUseCase.
Adds missing setupIdentity parameter to AppDependencyContainer factory method.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

```
test: Add ProfileEditorViewModel validation tests

Covers screen name length, character validation, and age requirements.
Tests reactive isSaveEnabled state and error message handling.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### 3. Stage files

Review untracked and modified files, then stage relevant changes:

```bash
# Stage specific files
git add <file1> <file2> <file3>

# Or stage all relevant changes (be careful with this)
git add .
```

**Important:** Never stage files that likely contain secrets:
- `.env` files
- `credentials.json`
- `*_key.pem`
- `secrets.yml`
- Private keys or tokens

If the user requests committing these files, warn them and ask for confirmation.

### 4. Create commit

Use a heredoc to ensure proper formatting:

```bash
git commit -m "$(cat <<'EOF'
<type>: <short summary>

<optional detailed body>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**IMPORTANT:**
- NEVER use `--amend` unless explicitly requested
- NEVER use `--no-verify` to skip hooks unless explicitly requested
- NEVER use `--force-push` unless explicitly requested
- ALWAYS create NEW commits by default

### 5. Verify commit success

After committing, verify the commit was created:

```bash
# Check that working tree is clean
git status

# View the commit that was just created
git log -1 --stat
```

### 6. Handle pre-commit hook failures

If the commit fails due to a pre-commit hook:

```
❌ Pre-commit hook failed!

<error output from hook>
```

**Action:**
1. Read the hook error carefully
2. Fix the issue (formatting, linting, test failures)
3. Stage the fixes
4. Create a NEW commit (do not use --no-verify)

**Example:**

```bash
# Hook failed due to SwiftFormat issues
# Fix formatting
swiftformat Shell/ ShellTests/ --swiftversion 6

# Stage formatting fixes
git add .

# Create NEW commit with original message plus fix note
git commit -m "$(cat <<'EOF'
feat: Add SwiftUI ProfileEditorView with validation

Implements ProfileEditorViewModel using Combine for reactive form validation.
Applies SwiftFormat to maintain code style consistency.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

### 7. Display commit summary

Print a formatted summary for the user:

```
✅ Commit created successfully!

📝 Commit: <short SHA>
📋 Type: <commit type>
📄 Files changed: <count>
➕ Insertions: <count>
➖ Deletions: <count>

Message:
<commit message>

Next steps:
- Review commit: git show HEAD
- Push to remote: git push origin <branch>
- Continue working on next task
```

## Safety Checks

### Before committing:

- ✅ Run `git status` to see what will be committed
- ✅ Run `git diff HEAD` to review all changes
- ✅ Verify no sensitive files are staged
- ✅ Ensure commit message follows conventions
- ✅ Always include Co-Authored-By line

### Never do:

- ❌ Skip hooks with `--no-verify` (unless user explicitly requests)
- ❌ Force push to main/master
- ❌ Amend commits (unless user explicitly requests)
- ❌ Commit empty changes (unless user explicitly requests)
- ❌ Commit files with secrets or credentials

## Advanced Options

### Commit specific files only

```bash
git add Shell/Features/Profile/Presentation/Editor/ProfileEditorView.swift
git add Shell/Features/Profile/Presentation/Editor/ProfileEditorViewModel.swift
git commit -m "$(cat <<'EOF'
feat: Add ProfileEditorView SwiftUI implementation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

### Commit with detailed body

```bash
git commit -m "$(cat <<'EOF'
refactor: Rename SetupIdentityUseCase to CompleteIdentitySetupUseCase

The new name better reflects that this use case completes the full identity
setup flow, including validation, profile creation, and persistence.

Changes:
- Renamed protocol from SetupIdentityUseCase to CompleteIdentitySetupUseCase
- Updated DefaultCompleteIdentitySetupUseCase implementation
- Changed API to accept IdentityData instead of raw parameters
- Updated all call sites in coordinators and view models

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

### Interactive staging (use with caution)

**Note:** NEVER use interactive commands like `git add -i` or `git rebase -i` as they require terminal interaction that is not supported.

Instead, stage files explicitly:

```bash
git add <specific-file-path>
```

## Notes

- Commits should represent logical, atomic changes
- One commit = one concern (feature, bug fix, refactor)
- Don't mix multiple unrelated changes in one commit
- Run tests before committing (use test-feature Skill)
- Follow the project's existing commit message patterns
- Always include the Co-Authored-By line for Claude contributions
- Pre-commit hooks are your friend - don't skip them
