# Commit Conventions

**Format**: Conventional Commits + Co-Authored-By

---

## Commit Message Format

```
<type>: <subject>

<body>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

---

## Types

- `feat:` - New feature (user-facing)
- `fix:` - Bug fix (user-facing)
- `refactor:` - Code restructuring (no behavior change)
- `test:` - Adding/updating tests
- `docs:` - Documentation only
- `chore:` - Build, dependencies, tooling

---

## Subject Line

- Keep under 72 characters
- Use imperative mood ("Add feature" not "Added feature")
- Don't end with period
- Capitalize first word

**Good**:
- `feat: Add logout functionality to Dog list`
- `fix: Prevent navigation freeze on back button`
- `refactor: Extract reusable UI components`

**Bad**:
- `Added a new feature.` (not imperative, has period)
- `fixed bug` (not capitalized, vague)
- `WIP` (meaningless)

---

## Body

- Explain **what** and **why**, not **how** (code shows how)
- Wrap at 72 characters
- Separate from subject with blank line
- Use bullet points for multiple changes

**Example**:
```
feat: Add Dog feature with session validation

- Created Dog domain entities and use cases
- Implemented CRUD operations with InMemoryDogRepository
- Added DogListViewModel and DogEditorViewModel
- Created DogCoordinator with session validation
- Added logout functionality with proper session clearing

Tests: 37 passing (33 unit + 4 integration)
```

---

## Co-Authored-By

**Always include** when Claude Code assists:

```
Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Why**: Attribution, transparency, compliance

---

## Using HEREDOC for Multi-Line

```bash
git commit -m "$(cat <<'EOF'
feat: Add Dog feature with session validation

- Created Dog domain entities and use cases
- Implemented CRUD operations
- Added integration tests

Tests: 37 passing

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

**Benefit**: Proper formatting, no escaping needed

---

## Atomic Commits

**One commit = One logical change**

✅ **Good**:
```
Commit 1: feat: Add Dog entity and use cases
Commit 2: feat: Add Dog ViewModels and Views
Commit 3: test: Add integration tests for Dog feature
```

❌ **Bad**:
```
Commit 1: Add Dog + Fix bug + Update docs + Refactor Items
```

---

## When to Commit

- After completing a feature (vertical slice)
- After fixing a bug (with test)
- After refactoring (tests still pass)
- Before switching contexts
- **Never**: Broken code, failing tests

---

## Pre-Commit Checklist

Before committing:

- [ ] Tests pass (`** TEST SUCCEEDED **`)
- [ ] Code builds (`xcodebuild build`)
- [ ] No SwiftLint warnings
- [ ] Changes are atomic (one logical unit)
- [ ] Commit message follows format
- [ ] Co-Authored-By included (if Claude helped)

**Pre-commit hook** enforces this automatically.

---

## Examples

### Feature
```
feat: Add HTTP Items repository with full CRUD

- Created URLSessionItemsHTTPClient actor
- Implemented HTTPItemsRepository with error mapping
- Added ItemDTO for API <-> Domain conversion
- Tests: 9 HTTP repository tests passing

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Bug Fix
```
fix: Prevent session validation crash on nil session

Added nil check in DogCoordinator.hasValidSession()
to prevent crash when session repository returns nil.

Tests: Updated integration tests to cover nil case

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Refactor
```
refactor: Extract reusable form components from ViewControllers

Created FormTextField and FormButton components to reduce
duplication across Login, DogEditor, and ProfileEditor views.

No behavior changes. All tests still passing.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Test
```
test: Add integration tests for authentication flow

- testLoginCreatesValidSession
- testLogoutClearsSession
- testDogCoordinatorRequiresValidSession
- testDogCoordinatorAllowsAccessWithValidSession

All 4 tests passing

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Documentation
```
docs: Add iOS development optimization guide

Created IOS-CLAUDE-OPTIMIZATION.md documenting:
- CLAUDE.md configuration
- Verification loops
- TDD enforcement
- Simulator interaction

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

---

## What NOT to Include in Commits

❌ Xcode workspace state files (`.xcuserstate`)
❌ Build artifacts (`DerivedData/`)
❌ Temporary files (`/tmp/`, `.DS_Store`)
❌ Sensitive data (API keys, credentials)
❌ Commented-out code (delete it)
❌ Merge conflict markers

**Use `.gitignore`** to exclude these automatically.

---

**Key Principle**: Clear commit history is documentation. Future you will thank present you.
