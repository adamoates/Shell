# Branch Strategy (MANDATORY)

## Overview

Each feature/test/improvement happens on **one focused branch**, merged sequentially into `main`.

**No feature branches sitting around. No merge conflicts. No architectural drift.**

## Branch Naming Convention

```
test/NN-descriptive-name
```

Where:
- `NN` = zero-padded number (01, 02, 03, ...)
- `descriptive-name` = kebab-case description of what's being built/tested

### Examples
```
test/01-storyboard-ui
test/02-swift-language
test/03-architecture-foundation
test/04-uikit-programmatic
test/05-swiftui-foundations
test/06-swiftui-advanced
test/07-testing-xctest
test/08-networking
test/09-coredata
test/10-performance
test/11-security
test/12-debugging
```

## Branch Rules

### 1. One Branch = One Vertical Slice

Each branch implements ONE complete, working feature or test area:
- Domain layer
- Data layer
- Presentation layer
- Tests for all layers
- Documentation

**Don't merge half-finished work.**

### 2. Branches Are Sequential

```
main → test/01 → main → test/02 → main → test/03 → main
```

- Start from `main`
- Complete the branch
- Merge to `main`
- Start next branch from updated `main`

**Don't stack branches or work on multiple in parallel (unless explicitly designing for it).**

### 3. Branches Must Be Mergeable Independently

Each branch should be able to:
- Build and run on its own
- Pass all tests
- Work as a standalone feature

Prefer **optional** feature additions over breaking changes.

### 4. No Long-Lived Branches

- Aim to complete each branch in **1-3 days max**
- If longer, break into smaller branches

## Branch Content Requirements

Every branch MUST include:

### 1. Working Code
- Compiles with zero warnings
- Runs without crashes
- Implements the stated feature completely

### 2. Tests
- Unit tests for domain/data layers
- ViewModel tests for presentation
- Integration tests where appropriate
- UI test for critical path (if applicable)

### 3. Documentation
Create `Docs/Test-NN.md` containing:
- Purpose of the branch
- What was built
- Design patterns used (with justification)
- How to run and test
- Acceptance criteria
- Known limitations or follow-ups

### 4. README Update
If the branch changes architecture or adds major features, update `README.md`.

### 5. Clean Git History
- Meaningful commit messages
- Squash WIP commits before merging
- No "fix typo" or "oops" commits in final history

## Branch Workflow

### Starting a New Branch

```bash
# 1. Ensure main is up to date
git checkout main
git pull

# 2. Create branch
git checkout -b test/03-architecture-foundation

# 3. Verify clean start
git status
```

### During Development

```bash
# Commit frequently (will squash later)
git add .
git commit -m "Add NoteRepository protocol"

git add .
git commit -m "Implement DefaultNoteRepository"

# Push to remote (if using remote)
git push -u origin test/03-architecture-foundation
```

### Before Merging

```bash
# 1. Build succeeds
xcodebuild build -project Shell.xcodeproj -scheme Shell

# 2. All tests pass
xcodebuild test -project Shell.xcodeproj -scheme Shell

# 3. SwiftLint passes
swiftlint lint --strict

# 4. Documentation written
ls Docs/Test-03.md

# 5. Squash WIP commits (optional)
git rebase -i main
```

### Merging to Main

```bash
# 1. Switch to main
git checkout main

# 2. Merge (no fast-forward to keep branch history)
git merge --no-ff test/03-architecture-foundation

# 3. Push
git push origin main

# 4. Delete merged branch (optional)
git branch -d test/03-architecture-foundation
```

## Branch-Specific Guidelines

### test/01-storyboard-ui
**Focus**: Storyboard + Auto Layout + iOS UI patterns
**Delivers**:
- 3-screen flow (Login → List → Detail)
- Proper constraints for all devices
- Dynamic Type support
- Empty states, pull-to-refresh
- Full accessibility

**Tests**: Primarily visual verification, some UI tests

---

### test/02-swift-language
**Focus**: Swift language mastery
**Delivers**:
- Protocol-oriented SDK module
- Generics and async/await
- Memory management (no leaks)
- Value vs reference type justifications

**Tests**: Unit tests for all components, Instruments leak check

---

### test/03-architecture-foundation
**Focus**: Clean Architecture setup
**Delivers**:
- Domain layer (entities, use cases, protocols)
- Data layer skeleton
- Presentation layer skeleton
- DI container
- Coordinator protocol

**Tests**: Architecture tests (dependency rules), basic use case tests

---

### test/04-uikit-programmatic
**Focus**: Programmatic UIKit with modern patterns
**Delivers**:
- UICollectionView with diffable data source
- Compositional layout
- Custom cells
- Interactive animations

**Tests**: Snapshot tests (optional), UI tests for interactions

---

### test/05-swiftui-foundations
**Focus**: SwiftUI basics integrated properly
**Delivers**:
- One SwiftUI feature (Note Editor or similar)
- Proper state management
- Coordinator integration
- UIHostingController embedding

**Tests**: ViewModel tests, preview tests

---

### test/06-swiftui-advanced
**Focus**: Advanced SwiftUI techniques
**Delivers**:
- Custom layouts or matched geometry
- Accessibility
- Localization
- Complex animations

**Tests**: Behavior tests, accessibility tests

---

### test/07-testing-xctest
**Focus**: Comprehensive test coverage
**Delivers**:
- Test pyramid (unit, integration, UI)
- TDD example
- Test doubles (mocks, stubs, fakes)
- Parallel test execution

**Tests**: Meta - this branch IS about testing

---

### test/08-networking
**Focus**: Networking layer
**Delivers**:
- API client with typed errors
- Retry logic
- Auth token handling
- Request/response logging

**Tests**: URLProtocol stub tests, integration tests

---

### test/09-coredata
**Focus**: Core Data persistence
**Delivers**:
- Core Data stack
- Repository implementation
- Background context handling
- Migration

**Tests**: In-memory Core Data tests, migration tests

---

### test/10-performance
**Focus**: Performance optimization
**Delivers**:
- Intentional bottleneck
- Instruments profiling
- Fix with before/after metrics
- Performance tests

**Tests**: Performance tests, measurement baselines

---

### test/11-security
**Focus**: Security best practices
**Delivers**:
- Keychain storage
- Biometric authentication
- Secure token handling
- Data protection

**Tests**: Security behavior tests, no secrets in logs verification

---

### test/12-debugging
**Focus**: Debugging techniques and tools
**Delivers**:
- Debug diagnostics screen
- Reproducible crash
- Constraint warning example
- LLDB breakpoint examples

**Tests**: Crash reproduction (in controlled manner), debug helpers

## Merge Checklist

Before merging any branch to `main`, verify:

### Build & Tests
- [ ] Compiles with zero warnings
- [ ] All tests pass
- [ ] SwiftLint strict passes
- [ ] No commented-out code
- [ ] No debug print statements left

### Architecture
- [ ] Clean Architecture boundaries respected
- [ ] Dependencies properly injected
- [ ] No singletons (except Apple APIs)
- [ ] Proper layer separation

### Testing
- [ ] Unit tests for use cases and ViewModels
- [ ] Integration tests for repositories
- [ ] UI test for critical path (if applicable)
- [ ] Tests are deterministic and fast

### Documentation
- [ ] `Docs/Test-NN.md` created and complete
- [ ] README updated if needed
- [ ] Design decisions documented
- [ ] Tradeoffs explained
- [ ] Known limitations stated

### Code Quality
- [ ] Functions under 50 lines
- [ ] Classes under 300 lines
- [ ] Cyclomatic complexity under 10
- [ ] Clear, descriptive names
- [ ] Proper error handling

### Git
- [ ] Clean commit history
- [ ] Meaningful commit messages
- [ ] Branch builds on latest main
- [ ] No merge conflicts

## Handling Breaking Changes

If a branch would break existing code:

### Option 1: Adapter Pattern (Preferred)
Add new interface alongside old, deprecate old:

```swift
// Old (deprecated)
@available(*, deprecated, message: "Use NoteRepository instead")
class OldDataManager { }

// New
protocol NoteRepository { }
```

### Option 2: Feature Flags
Guard new behavior:

```swift
if FeatureFlags.useNewArchitecture {
    // New code path
} else {
    // Old code path
}
```

### Option 3: Migration Branch
Create explicit migration branch that updates all call sites.

## Viewing Branch Progress

```bash
# List all branches
git branch -a

# Compare branches
git diff main..test/03-architecture-foundation

# See commit history for branch
git log main..test/03-architecture-foundation

# See files changed in branch
git diff --name-only main..test/03-architecture-foundation
```

## Parallel Branches (Advanced)

In some cases, you may work on branches in parallel:

### Rules for Parallel Work
1. Branches must be **independent** (no shared code changes)
2. Each must be mergeable into main on its own
3. Merge order doesn't matter
4. Resolve conflicts when second branch merges

### Example: Independent Features
```
main
├── test/08-networking (independent)
└── test/11-security (independent)
```

Both can be developed in parallel and merged in any order.

### Example: Dependent Features
```
main
└── test/03-architecture-foundation
    └── test/04-feature-auth (depends on 03)
```

These must be sequential: merge 03, then start 04.

## Branch Naming Beyond Test Branches

### Feature Branches
```
feature/user-profile
feature/offline-sync
```

### Bug Fixes
```
fix/login-crash
fix/memory-leak-in-list
```

### Refactoring
```
refactor/coordinator-pattern
refactor/extract-use-cases
```

### Chores
```
chore/update-dependencies
chore/ci-configuration
```

## Summary

### Branch Strategy Principles
1. ✅ One branch = one vertical slice
2. ✅ Sequential merges to main
3. ✅ Each branch independently runnable
4. ✅ Complete documentation per branch
5. ✅ All quality checks before merge

### Commands to Remember
```bash
# Start branch
git checkout -b test/NN-name

# Verify quality
xcodebuild build && xcodebuild test && swiftlint

# Merge to main
git checkout main && git merge --no-ff test/NN-name

# Start next
git checkout -b test/NN+1-name
```

### Every Branch Delivers
- ✅ Working code
- ✅ Passing tests
- ✅ Documentation
- ✅ Clean history
- ✅ Zero warnings

**This is the standard. No half-finished merges.**
