# Daily Development Workflow

**Quick reference for daily tasks**

---

## Definition of Done

A feature is DONE when ALL of these are true:

- [ ] Domain logic complete with tests
- [ ] Repository implemented
- [ ] ViewModel + UI working
- [ ] Navigation integrated
- [ ] Error handling works
- [ ] Tests **PROVEN** to pass (`** TEST SUCCEEDED **`)
- [ ] No compiler warnings
- [ ] App launches in simulator
- [ ] Critical user flow tested E2E
- [ ] Committed to `main`

**No partial features. No TODOs. Ship complete vertical slices.**

---

## Quick Commands

### Build
```bash
xcodebuild build -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Test
```bash
xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skip-testing:ShellUITests 2>&1 | tee /tmp/shell_last_test.log && date +%s > /tmp/shell_last_test_time
```

### Launch
```bash
xcrun simctl launch booted com.adamcodertrader.Shell
```

### Skills
- `/new-feature` - Scaffold vertical slice
- `/test-feature` - Run tests for feature
- `/simulator-ui-review` - Capture and analyze UI

---

## Workflow: Adding a Feature

### 1. Plan
- Read existing patterns (`Features/Items/` for reference)
- Identify dependencies
- Sketch vertical slice structure

### 2. Build (Domain First)
```
Features/{Feature}/
├── Domain/
│   ├── Entities/{Feature}.swift
│   ├── UseCases/*.swift
│   └── Errors/{Feature}Error.swift
├── Infrastructure/
│   └── Repositories/InMemory{Feature}Repository.swift
└── Presentation/
    ├── List/{Feature}ListViewModel.swift
    └── List/{Feature}ListViewController.swift
```

Use `/new-feature {FeatureName}` to scaffold.

### 3. Test (Red-Green)
1. Write failing test
2. Run: `xcodebuild test -only-testing:ShellTests/{TestClass}`
3. Confirm failure
4. Write implementation
5. Run test again
6. Confirm `** TEST SUCCEEDED **`

### 4. Wire (DI Container)
```swift
// Add to AppDependencyContainer.swift
func make{Feature}Repository() -> {Feature}Repository
func make{Feature}UseCase() -> {Feature}UseCase
func make{Feature}ViewModel() -> {Feature}ViewModel
func make{Feature}Coordinator() -> {Feature}Coordinator
```

### 5. Navigate (Coordinator)
- Create {Feature}Coordinator
- Wire into AppCoordinator
- Add delegate protocols

### 6. Verify
```bash
# Build
xcodebuild build ...

# Test
xcodebuild test ... | tee /tmp/shell_last_test.log

# Verify
grep -F "** TEST SUCCEEDED **" /tmp/shell_last_test.log

# Launch
xcrun simctl launch booted com.adamcodertrader.Shell

# Screenshot
xcrun simctl io booted screenshot /tmp/verify.png
```

### 7. Commit
```bash
git add Features/{Feature}/ ShellTests/Features/{Feature}/
git commit -m "feat: Add {Feature} with CRUD operations

- Created domain entities and use cases
- Implemented repository
- Added ViewModels and Views
- Integration tests passing

Tests: X passing

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Workflow: Fixing a Bug

### 1. Reproduce
- Read the failing code
- Understand the bug

### 2. Write Failing Test
```swift
func testBugReproduction() async throws {
    // Arrange: Set up conditions that trigger bug
    // Act: Perform the action
    // Assert: Verify bug exists (test should FAIL)
}
```

### 3. Run Test (Confirm Failure)
```bash
xcodebuild test -only-testing:ShellTests/{TestClass}/{testBugReproduction}
# Should see ** TEST FAILED **
```

### 4. Fix
Make minimal change to fix the issue.

### 5. Run Test (Confirm Pass)
```bash
xcodebuild test -only-testing:ShellTests/{TestClass}/{testBugReproduction}
# Should see ** TEST SUCCEEDED **
```

### 6. Commit
```bash
git commit -m "fix: {Brief description of bug}

{Explanation of what was wrong and how it's fixed}

Tests: Added {TestClass}/{testMethod} to prevent regression

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## What NOT to Do

❌ **Don't** assume tests passed (always verify)
❌ **Don't** commit failing tests
❌ **Don't** skip the verification protocol
❌ **Don't** push without running tests locally
❌ **Don't** mix multiple features in one commit
❌ **Don't** leave TODO comments (finish it or don't commit)
❌ **Don't** commit commented-out code (delete it)
❌ **Don't** force push to main (ever)

---

## Common Tasks

### Run Specific Test
```bash
/test-feature {FeatureName}
```

### Check UI
```bash
/simulator-ui-review
```

### New Feature
```bash
/new-feature {FeatureName}
```

### Code Review
```bash
@code-reviewer
```

### Plan Architecture
```bash
@planner
```

---

## Pre-Commit Checklist

Before every commit:

- [ ] Tests pass (`** TEST SUCCEEDED **`)
- [ ] App builds without warnings
- [ ] SwiftLint passes
- [ ] App launches in simulator
- [ ] Changes are atomic
- [ ] Commit message follows conventions
- [ ] Co-Authored-By included (if Claude helped)

**Pre-commit hook enforces this automatically.**

---

**Key Principle**: Ship complete, tested, working features. No half-done work.
