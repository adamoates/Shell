# Shell - iOS Modernization Toolkit

**Technical Reference • Architecture • Patterns**

> **For daily workflow, see [PLAYBOOK.md](PLAYBOOK.md)**

---

## Purpose

Production-ready iOS boilerplate demonstrating **Clean Architecture + MVVM** for modern Swift 6 with strict concurrency.

---

## Architecture

```
Shell/
├── Features/              # Feature modules (vertical slices)
│   └── {Feature}/
│       ├── Domain/        # Business logic (pure, no dependencies)
│       ├── Presentation/  # UI (ViewModels, Views, Coordinators)
│       └── Infrastructure/# External (Repositories, HTTP, Storage)
├── Core/                  # Shared infrastructure
│   ├── DI/               # AppDependencyContainer
│   ├── Contracts/        # Repository, UseCase protocols
│   └── Infrastructure/   # Config, Navigation, HTTP base
└── SwiftSDK/             # Reusable utilities
```

### Layer Rules

**Domain → Infrastructure ← Presentation**

- **Domain**: Pure Swift, no UIKit/SwiftUI, no external dependencies
- **Infrastructure**: Implements domain protocols, handles external systems
- **Presentation**: Uses domain use cases, never imports infrastructure

---

## iOS Development Configuration

### Tech Stack
- **Language**: Swift 6 (strict concurrency enabled)
- **UI Framework**: UIKit (programmatic, no storyboards)
- **Architecture**: Clean Architecture + MVVM + Coordinator pattern
- **Dependency Manager**: Swift Package Manager (SPM)
- **Testing**: XCTest (unit + integration tests)
- **Minimum Target**: iOS 26.2

### Build & Test Commands

**Build**:
```bash
xcodebuild build -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Test** (with verification):
```bash
xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skip-testing:ShellUITests 2>&1 | tee /tmp/shell_last_test.log
date +%s > /tmp/shell_last_test_time
```

**Launch in Simulator**:
```bash
xcodebuild build -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcrun simctl launch booted com.adamcodertrader.Shell
xcrun simctl io booted screenshot /tmp/shell-verify.png
```

### Verification Loop (Critical for iOS)

**After every code change**:
1. **Build**: Run `xcodebuild build`
2. **Test**: Run `xcodebuild test`
3. **Verify**: Check for `** TEST SUCCEEDED **`
4. **Launch**: Start app in simulator
5. **Screenshot**: Capture UI state with `xcrun simctl io booted screenshot`
6. **Review**: Read screenshot to verify UI matches expectations

**NEVER assume** a build or test passes. iOS compilation errors are common and must be caught early.

### iOS Coding Rules

- **Value Types First**: Prefer `struct` over `class` unless reference semantics needed
- **Concurrency**: Use `async/await` + actors; avoid completion handlers
- **Main Actor**: All UI code must be `@MainActor`
- **Sendable**: Cross-actor types must conform to `Sendable`
- **No Force Unwrap**: Never use `!`, `try!`, or `as!`
- **No Storyboards**: All UI is programmatic with Auto Layout
- **No Global State**: Use dependency injection via AppDependencyContainer

### Common Xcode Issues

**Issue**: "Cannot find 'X' in scope"
**Fix**: File not added to target → Check Xcode target membership

**Issue**: Tests fail with "No such module"
**Fix**: Missing `@testable import Shell` or target dependencies

**Issue**: Simulator not booting
**Fix**: `xcrun simctl list devices` → `xcrun simctl boot <device-id>`

**Issue**: App not installing
**Fix**: Clean: `xcodebuild clean` then rebuild

---

## Patterns

### Navigation
**Coordinator Pattern** - Encapsulates navigation flows

### Presentation
**MVVM** - `@MainActor` ViewModels with `@Published` properties

### Business Logic
**Use Case Pattern** - One use case = one operation
```swift
protocol CreateItemUseCase {
    func execute(name: String, description: String, isCompleted: Bool) async throws -> Item
}
```

### Data Access
**Repository Pattern** - Abstract data access behind protocols
```swift
protocol ItemsRepository {
    func create(_ item: Item) async throws -> Item
    func fetchAll() async throws -> [Item]
    func update(_ item: Item) async throws -> Item
    func delete(id: UUID) async throws
}
```

### Dependency Injection
**Service Locator** - `AppDependencyContainer` for lazy dependency creation

---

## Swift 6 Compliance

### Strict Concurrency

```swift
// ✅ ViewModels
@MainActor
final class ItemEditorViewModel: ObservableObject { }

// ✅ Repositories
actor HTTPItemsRepository: ItemsRepository { }

// ✅ Entities
struct Item: Sendable, Identifiable, Codable { }
```

### Never Use

- ❌ Force unwrap (`!`)
- ❌ `try!` or `as!`
- ❌ Global mutable state
- ❌ Singletons (except Apple APIs)

---

## Testing

### Test Pyramid

1. **Domain Tests** - Use cases, business logic (100% coverage)
2. **Infrastructure Tests** - Repositories, HTTP clients (80%+ coverage)
3. **Presentation Tests** - ViewModels (100% coverage)
4. **UI Tests** - Critical paths only (selective)

### Test Structure

```swift
func testCreateItemSuccess() async throws {
    // Arrange
    let repository = InMemoryItemsRepository()
    let useCase = DefaultCreateItemUseCase(repository: repository)

    // Act
    let item = try await useCase.execute(
        name: "Test",
        description: "Description",
        isCompleted: false
    )

    // Assert
    XCTAssertEqual(item.name, "Test")
}
```

### Testing Verification Protocol (Critical)

**NEVER** claim tests pass without proving it. Follow this protocol:

1. **Verification Loop** (The Golden Rule)
   - ❌ DON'T: Say "tests pass" or "all tests passing"
   - ✅ DO: Run `xcodebuild test` and show `** TEST SUCCEEDED **` output
   - ✅ DO: Count actual passing tests from grep output
   - ❌ NEVER: Assume, simulate, or hallucinate test results

2. **Red-Green TDD Workflow**
   ```
   1. RED:   Write failing test first
   2. VERIFY: Run test, confirm it fails with expected error
   3. GREEN:  Write implementation to make test pass
   4. VERIFY: Run test, confirm it passes with real output
   5. REFACTOR: Improve code, verify tests still pass
   ```

3. **Test Execution Commands**
   ```bash
   # All tests
   xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skip-testing:ShellUITests

   # Specific feature
   xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:ShellTests/DogListViewModelTests

   # Verify success
   echo $? # Must be 0 for success
   ```

4. **Integration vs Unit Tests**
   - **Unit tests** mock dependencies → can pass while app is broken
   - **Integration tests** use real implementations → catch wiring issues
   - **ALWAYS** write integration tests for critical flows:
     - Authentication flow
     - Navigation between features
     - Data persistence
     - Network requests (with URLProtocol mocking)

5. **Definition of "Tests Pass"**
   - ✅ Exit code 0 from xcodebuild
   - ✅ `** TEST SUCCEEDED **` in output
   - ✅ No `** TEST FAILED **` messages
   - ✅ All expected tests executed (not skipped)
   - ✅ App launches in simulator without crashes
   - ✅ Critical user flows work end-to-end

6. **When You Cannot Verify**
   - If simulator is not available: State "I cannot verify this without a running simulator"
   - If tests require manual setup: State "Manual verification required: [steps]"
   - NEVER guess or assume verification

---

## Code Standards

### Naming

- **Protocols**: `{Feature}Repository`, `{Action}{Entity}UseCase`
- **Implementations**: `InMemory{Feature}Repository`, `HTTP{Feature}Repository`
- **ViewModels**: `{Feature}ViewModel`, `{Feature}EditorViewModel`
- **Use Cases**: `Default{Action}{Entity}UseCase`

### Size Limits

- Functions: < 50 lines
- Classes: < 300 lines
- Cyclomatic complexity: < 10

### Error Handling

```swift
enum ItemError: Error {
    case notFound
    case validationFailed(String)
    case createFailed
    case networkError(Error)
}
```

---

## Feature Structure

Every feature follows this structure:

```
Features/{Feature}/
├── Domain/
│   ├── Entities/{Entity}.swift
│   ├── UseCases/{Action}{Entity}UseCase.swift
│   └── Repositories/{Feature}Repository.swift (protocol)
├── Infrastructure/
│   └── Repositories/
│       ├── InMemory{Feature}Repository.swift
│       └── HTTP{Feature}Repository.swift (optional)
└── Presentation/
    ├── {Feature}Coordinator.swift
    ├── ViewModels/{Feature}ViewModel.swift
    └── Views/{Feature}ViewController.swift
```

---

## Backend Integration

### Local API
```bash
cd backend && docker compose up -d
```

### Endpoints
- Health: `GET http://localhost:3000/health`
- Items: `GET/POST/PUT/DELETE http://localhost:3000/v1/items`

### Feature Flags
```swift
// Shell/Core/Infrastructure/Config/APIConfig.swift
struct RepositoryConfig {
    static var useHTTPItemsRepository: Bool = true
    static var useRemoteRepository: Bool = false
}
```

---

## Reference Implementation

**Items Module** is the reference for all new features:
- Domain: `Item`, `CreateItemUseCase`, `ItemsRepository`
- Infrastructure: `InMemoryItemsRepository`, `HTTPItemsRepository`
- Presentation: `ItemEditorViewModel`, `ListViewController`
- Coordinator: `ItemsCoordinator`
- Tests: 55 passing tests

**Use Items as a template for new features.**

---

## Commit Format

```
<type>: <subject>

<body>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

**Types:** `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

---

## Quick Commands

```bash
# Build
xcodebuild build -scheme Shell

# Test all
xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17'

# Test specific
xcodebuild test -only-testing:ShellTests/CreateItemUseCaseTests

# Skip UI tests (they fail due to .claude directory)
xcodebuild test -skip-testing:ShellUITests
```

---

## Project State

✅ **Complete:**
- Clean Architecture implementation
- Items module with HTTP integration
- Profile module (read-only)
- Auth module (placeholder)
- Offline support (Core Data + Network monitoring)

⚠️ **Next:**
- Profile editing features
- Full auth implementation
- Additional feature modules

---

## When to Use This Document

Use CLAUDE.md when you need:
- ✅ Architecture reference
- ✅ Pattern examples
- ✅ Code standards
- ✅ Technical details

Use [PLAYBOOK.md](PLAYBOOK.md) for:
- ✅ Daily workflow
- ✅ Feature planning
- ✅ Decision making
- ✅ What to focus on

---

## Product Development Templates

Shell is a **reusable architecture toolkit**.

When building **real-world products** on Shell, these templates help:

### [Context/product-strategy.md](Context/product-strategy.md)
Define niche, persona, MVP scope for products like Rover, Field Notes, etc.

### [Context/workflow-product.md](Context/workflow-product.md)
Vertical slice development, test-first approach, definition of done

### [Context/booking-scheduling.md](Context/booking-scheduling.md)
Domain model for scheduling systems (appointments, bookings, care routines)

### [Context/team-scaling.md](Context/team-scaling.md)
Scale from 1 to 15 engineers using vertical ownership

**These keep Shell general-purpose while supporting specific product domains.**

---

**Last Updated:** 2026-02-14
**Version:** Swift 6, iOS 26.2, Xcode 16.3
