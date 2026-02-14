---
name: scaffold-use-case
description: Generate a new use case with protocol, implementation, tests, and mock. Use when adding business logic or a new operation to an existing feature.
argument-hint: [UseCaseName] [FeatureName]
---

# Scaffold Use Case

Generate a complete use case following Shell's patterns: protocol + default implementation + tests + mock.

Read `.claude/Context/design-patterns.md` (Pattern 3: Use Case) and `.claude/Context/tdd-requirements.md` for standards.

## Input

- `$0` = Use case name (e.g., "DeleteItem", "UpdateProfile", "ValidateScreenName")
- `$1` = Feature it belongs to (e.g., "Items", "Profile", "Auth")

If arguments not provided, ask for both.

## Steps

### 1. Determine Use Case Type

Based on the name:
- **Query** (Fetch, Get, Find, Search, Validate) — returns data, no side effects
- **Command** (Create, Update, Delete, Save, Complete) — mutates state

### 2. Generate Protocol

Create `Shell/Features/<Feature>/Domain/UseCases/<UseCaseName>UseCase.swift`:

```swift
import Foundation

protocol <UseCaseName>UseCase {
    func execute(<parameters>) async throws -> <ReturnType>
}
```

Rules:
- Single `execute()` method
- `async throws` always
- Parameters are domain types, not DTOs
- No UIKit/SwiftUI imports

### 3. Generate Default Implementation

```swift
final class Default<UseCaseName>UseCase: <UseCaseName>UseCase {
    private let repository: <Feature>Repository

    init(repository: <Feature>Repository) {
        self.repository = repository
    }

    func execute(<parameters>) async throws -> <ReturnType> {
        // Validation (if command)
        // Business logic
        // Repository call
    }
}
```

Rules:
- `Default` prefix for implementation class name
- Constructor injection of dependencies
- Validation before repository calls
- Map errors to domain error types

### 4. Generate Tests (TDD)

Create `ShellTests/Features/<Feature>/Domain/UseCases/<UseCaseName>UseCaseTests.swift`:

```swift
import XCTest
@testable import Shell

final class <UseCaseName>UseCaseTests: XCTestCase {

    private var sut: Default<UseCaseName>UseCase!
    private var repository: InMemory<Feature>Repository!

    override func setUp() async throws {
        repository = InMemory<Feature>Repository()
        sut = Default<UseCaseName>UseCase(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
    }

    // MARK: - Success Cases
    func testExecute_withValidInput_succeeds() async throws { }

    // MARK: - Validation Failures
    func testExecute_withInvalidInput_throwsValidationError() async { }

    // MARK: - Repository Failures
    func testExecute_whenRepositoryFails_propagatesError() async { }
}
```

Generate tests for: success path, each validation failure, repository errors, edge cases.

### 5. Generate Mock

```swift
private final class Mock<UseCaseName>UseCase: <UseCaseName>UseCase {
    var executeCallCount = 0
    var resultToReturn: <ReturnType>?
    var errorToThrow: Error?

    func execute(<parameters>) async throws -> <ReturnType> {
        executeCallCount += 1
        if let error = errorToThrow { throw error }
        return resultToReturn!
    }
}
```

### 6. Print Wiring Reminder

```
Use case scaffolded: <UseCaseName>UseCase

Add to AppDependencyContainer:

    func make<UseCaseName>UseCase() -> <UseCaseName>UseCase {
        Default<UseCaseName>UseCase(repository: shared<Feature>Repository)
    }

Update coordinator to receive this use case via init.
```

### 7. Run Tests

```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/<UseCaseName>UseCaseTests
```
