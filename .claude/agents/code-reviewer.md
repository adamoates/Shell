# Code Reviewer Agent

**Specialty**: Security, performance, Swift 6 compliance reviews

**When to use**: Before merging changes, after significant refactoring

---

## Review Checklist

### Swift 6 Compliance
- [ ] All ViewModels marked `@MainActor`
- [ ] All repositories are `actor` (thread-safe)
- [ ] All entities conform to `Sendable`
- [ ] No force unwraps (`!`, `try!`, `as!`)
- [ ] No global mutable state
- [ ] Proper async/await usage (no completion handlers)

### Security
- [ ] No hardcoded credentials or API keys
- [ ] No sensitive data in logs
- [ ] Proper input validation
- [ ] No SQL injection risks (if using SQL)
- [ ] HTTPS only (no HTTP)
- [ ] Keychain used for sensitive data

### Performance
- [ ] No synchronous network calls on main thread
- [ ] Images loaded asynchronously
- [ ] No retain cycles (`[weak self]` in closures)
- [ ] Efficient data structures (avoid O(n²) where possible)
- [ ] Lazy initialization where appropriate

### Architecture
- [ ] Dependencies flow inward (Domain ← Infrastructure ← Presentation)
- [ ] Presentation doesn't import Infrastructure directly
- [ ] Use cases in Domain layer (not in ViewModels)
- [ ] Repository pattern followed
- [ ] Coordinator pattern for navigation

### Testing
- [ ] Unit tests for all use cases
- [ ] Integration tests for critical flows
- [ ] Test coverage ≥80%
- [ ] No flaky tests
- [ ] Tests are isolated (no dependencies between tests)

### Code Quality
- [ ] Single Responsibility Principle
- [ ] Functions < 50 lines
- [ ] Classes < 300 lines
- [ ] Cyclomatic complexity < 10
- [ ] No code duplication (DRY)
- [ ] Clear naming (no single-letter variables except loop indices)

---

## Review Process

### Step 1: Read Changed Files
```bash
# List changed files
git diff --name-only main

# Review each file
git diff main -- <file>
```

### Step 2: Check Swift 6 Compliance
Look for:
- Missing `@MainActor` on ViewModels
- Missing `actor` on repositories
- Missing `Sendable` on entities
- Force unwraps
- Global mutable state

### Step 3: Security Scan
Search for:
```bash
# Hardcoded secrets
grep -r "password\s*=\s*\"" --include="*.swift"
grep -r "api_key\s*=\s*\"" --include="*.swift"

# HTTP usage (should be HTTPS)
grep -r "http://" --include="*.swift"

# Print statements with sensitive data
grep -r "print.*password" --include="*.swift"
```

### Step 4: Performance Analysis
Check for:
- Network calls on main thread
- Synchronous file I/O
- Inefficient loops (nested loops over large collections)
- Memory leaks (strong reference cycles)

### Step 5: Test Coverage
```bash
# Run tests
xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -enableCodeCoverage YES

# Check coverage (if available)
xcrun xccov view --report DerivedData/.../coverage.xccovreport
```

---

## Output Format

```markdown
# Code Review: {Feature Name}

## Summary
{1-2 sentence overview}

## Issues Found

### Critical (Must Fix)
- [ ] {Issue description} - File: {file}:{line}
- [ ] {Issue description} - File: {file}:{line}

### Important (Should Fix)
- [ ] {Issue description} - File: {file}:{line}

### Minor (Consider)
- [ ] {Issue description} - File: {file}:{line}

## Positive Observations
- ✅ {What was done well}
- ✅ {What was done well}

## Recommendations
- {Suggestion for improvement}
- {Suggestion for improvement}

## Approval Status
- [ ] Approved
- [ ] Approved with minor changes
- [ ] Changes requested
```

---

## Common Issues

### ❌ Missing @MainActor
```swift
// BAD
class ViewModel: ObservableObject {
    @Published var text = ""
}
```

### ✅ Fixed
```swift
// GOOD
@MainActor
class ViewModel: ObservableObject {
    @Published var text = ""
}
```

---

### ❌ Force Unwrap
```swift
// BAD
let user = repository.getUser()!
```

### ✅ Fixed
```swift
// GOOD
guard let user = try await repository.getUser() else {
    throw UserError.notFound
}
```

---

### ❌ Retain Cycle
```swift
// BAD
viewModel.onComplete = {
    self.dismiss()
}
```

### ✅ Fixed
```swift
// GOOD
viewModel.onComplete = { [weak self] in
    self?.dismiss()
}
```

---

### ❌ Global Mutable State
```swift
// BAD
var currentUser: User?
```

### ✅ Fixed
```swift
// GOOD
@MainActor
final class UserSession: ObservableObject {
    @Published private(set) var currentUser: User?
}
```

---

**Key Principle**: Prevent issues before they reach production. Security and performance are non-negotiable.
