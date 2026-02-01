# Shell - iOS Modernization Toolkit

## Purpose
Production-ready iOS boilerplate demonstrating Clean Architecture + MVVM for migrating legacy apps to modern Swift 6 with strict concurrency.

## Architecture Overview

```
Shell/
├── Features/           # Feature modules (Auth, Items, Profile)
│   ├── {Feature}/
│   │   ├── Domain/             # Business logic layer
│   │   │   ├── Entities/       # Core domain models (Sendable)
│   │   │   └── UseCases/       # Business logic (protocols + implementations)
│   │   ├── Presentation/       # UI layer
│   │   │   ├── ViewModels/     # MVVM ViewModels (@MainActor, ObservableObject)
│   │   │   └── Views/          # UIKit ViewControllers or SwiftUI Views
│   │   └── Infrastructure/     # External concerns
│   │       └── Repositories/   # Data access implementations
├── Core/               # Shared infrastructure
│   ├── DI/            # Dependency Injection (AppDependencyContainer)
│   ├── Contracts/     # Shared protocols (Repository, UseCase patterns)
│   └── Infrastructure/# HTTP clients, Config, Navigation
└── SwiftSDK/          # Reusable utilities (Validator, Observer, Storage)
```

### Layer Responsibilities

**Domain Layer** (Pure business logic, no dependencies)
- **Entities**: Immutable, Sendable structs (e.g., `Item`, `UserProfile`)
- **Use Cases**: Protocol + Default implementation (e.g., `CreateItemUseCase`)
- **Repository Protocols**: Abstract data access (e.g., `ItemsRepository`)
- **Domain Errors**: Typed errors (e.g., `ItemError`, `ProfileError`)

**Presentation Layer** (UI concerns)
- **ViewModels**: `@MainActor`, `ObservableObject`, `@Published` properties
- **ViewControllers**: UIKit programmatic UI with Auto Layout
- **Coordinators**: Navigation and flow coordination

**Infrastructure Layer** (External integrations)
- **Repository Implementations**: `InMemoryItemsRepository`, `HTTPItemsRepository`
- **HTTP Clients**: `URLSessionItemsHTTPClient`, DTOs for API mapping
- **Configuration**: `APIConfig`, `RepositoryConfig` with feature flags

## Critical Rules

### 1. Never Speculate - Always Read First
```swift
// ❌ DON'T: Guess at implementation
"I assume Item has a title field..."

// ✅ DO: Read the file first
Read Shell/Features/Items/Domain/Entities/Item.swift
// Now you know: Item has `name`, not `title`
```

### 2. Plan First - Wait for Approval
```
// ❌ DON'T: Jump straight to coding
User: "Add email validation"
[Immediately edits code]

// ✅ DO: Research → Plan → Approve → Implement
User: "Add email validation"
1. Read Validator.swift to understand existing patterns
2. Create plan: "Add emailValidator to Validator.swift, update ProfileEditorViewModel"
3. Wait for approval
4. Implement after approval
```

### 3. Minimal Scope - Only Touch What's Necessary
```swift
// ❌ DON'T: "Improve" unrelated code
User: "Fix ItemEditor crash"
[Fixes crash + refactors ListViewController + adds comments to DetailView]

// ✅ DO: Fix only what's asked
User: "Fix ItemEditor crash"
[Only modifies ItemEditorViewController.swift to fix the crash]
```

### 4. Test Coverage - 100% for Domain/Infrastructure
```
// After implementing CreateItemUseCase
✅ Also update: CreateItemUseCaseTests.swift
✅ Run: xcodebuild test -only-testing:ShellTests/CreateItemUseCaseTests
❌ Don't skip: "Tests will be added later"
```

### 5. Swift 6 Compliance - Strict Concurrency
```swift
// ✅ All ViewModels
@MainActor
final class ItemEditorViewModel: ObservableObject { }

// ✅ All repository implementations
actor HTTPItemsRepository: ItemsRepository { }

// ✅ All domain entities
struct Item: Sendable, Identifiable { }

// ❌ Never
class ItemViewModel: ObservableObject { } // Missing @MainActor
var unsafeGlobal: [Item] = []            // Not thread-safe
```

## Workflow Patterns

### When Adding a New Feature
Use `/new-feature` skill, or follow this structure:

```
1. Domain Layer
   - Create entity in Shell/Features/{Feature}/Domain/Entities/{Entity}.swift
   - Create use case protocol in Domain/UseCases/{Action}{Entity}UseCase.swift
   - Create repository protocol in Domain/Repositories/{Feature}Repository.swift

2. Infrastructure Layer
   - Implement InMemory repository in Infrastructure/In Memory{Feature}Repository.swift
   - (Later) Implement HTTP repository in Infrastructure/Repositories/HTTP{Feature}Repository.swift

3. Presentation Layer
   - Create ViewModel in Presentation/{Feature}ViewModel.swift (@MainActor, @Published)
   - Create View in Presentation/{Feature}ViewController.swift (UIKit) or {Feature}View.swift (SwiftUI)

4. Wire in DI Container
   - Add factory methods to AppDependencyContainer.swift
   - Add feature flag to RepositoryConfig if needed

5. Tests (parallel with implementation)
   - Domain: {Action}{Entity}UseCaseTests.swift
   - Infrastructure: HTTP{Feature}RepositoryTests.swift (with URLProtocol mocking)
   - Presentation: {Feature}ViewModelTests.swift
```

### When Fixing Bugs
```
1. Reproduce: Read the failing code and understand the bug
2. Write failing test: Add test case that exposes the bug
3. Fix: Make minimal change to fix the issue
4. Verify: Run tests to confirm fix
5. Commit: One commit with fix + test
```

### When Migrating Schema
```
Example: Epic 3 - Items Schema Migration (title/subtitle → name/description/isCompleted)

1. Update Domain entity (Item.swift)
2. Update Use Cases (CreateItemUseCase, UpdateItemUseCase)
3. Update Infrastructure (InMemoryItemsRepository, HTTPItemsRepository, DTOs)
4. Update Presentation (ViewModels, ViewControllers)
5. Update ALL tests in same commit
6. Build and run: xcodebuild build + xcodebuild test
```

## Code Style Guidelines

### Swift Conventions
```swift
// ✅ Naming
protocol ItemsRepository { }               // Protocol: {Feature}Repository
final class InMemoryItemsRepository { }    // Implementation: {Pattern}{Feature}Repository
func execute(name: String) async throws    // Use Cases: execute()
@Published var errorMessage: String?       // Published: descriptive, optional for errors

// ✅ Error Handling
enum ItemError: Error {
    case notFound
    case validationFailed(String)
    case createFailed
}

// Never force unwrap (!)
// Never try! (use try with do-catch)
// Never as! (use as? with guard)

// ✅ Async/Await
func fetchItems() async throws -> [Item] { }  // Async functions throw

// ✅ Sendable & Thread Safety
actor HTTPItemsRepository { }                  // Actors for shared state
struct Item: Sendable { }                      // Sendable for cross-actor
@MainActor class ViewModel: ObservableObject { } // @MainActor for UI

// ❌ Don't
class GlobalState { var items: [Item] = [] }  // Unsafe global mutable state
```

### Testing Patterns
```swift
// ✅ Arrange-Act-Assert
func testCreateItemSuccess() async throws {
    // Arrange (Given)
    let repository = InMemoryItemsRepository()
    let useCase = DefaultCreateItemUseCase(repository: repository)

    // Act (When)
    let item = try await useCase.execute(
        name: "Test Item",
        description: "Test Description",
        isCompleted: false
    )

    // Assert (Then)
    XCTAssertEqual(item.name, "Test Item")
    XCTAssertFalse(item.isCompleted)
}

// ✅ Test error cases
func testCreateItemEmptyNameThrows() async throws {
    let useCase = DefaultCreateItemUseCase(repository: repository)

    do {
        _ = try await useCase.execute(name: "", description: "Test", isCompleted: false)
        XCTFail("Should have thrown validation error")
    } catch ItemError.validationFailed {
        // Expected error
    }
}

// ✅ Mock with URLProtocol for HTTP tests
class MockURLProtocol: URLProtocol {
    static var mockResponse: (Data, HTTPURLResponse, Error?)?
    // ... implement URLProtocol methods
}
```

## Project-Specific Context

### Current State (Epic 3 Complete)
- ✅ **Items Module**: Reference implementation with HTTP repository
- ✅ **Backend API**: Docker Postgres + Node.js at http://localhost:3000/v1
- ✅ **Schema Aligned**: iOS Item model matches backend API
- ⚠️ **Profile Module**: Read-only (needs edit features)
- ⚠️ **Auth Module**: Placeholder (needs full implementation)

### Feature Flags
Located in `Shell/Core/Infrastructure/Config/APIConfig.swift`:

```swift
struct RepositoryConfig {
    static var useRemoteRepository: Bool        // Profile: In-memory vs Remote
    static var useHTTPItemsRepository: Bool     // Items: In-memory vs HTTP
}
```

Toggle these to switch between implementations without code changes.

### Reference Implementation: Items
Use Items module as template for new features:
- Domain: `Item` entity, `CreateItemUseCase`, `ItemsRepository` protocol
- Infrastructure: `InMemoryItemsRepository`, `HTTPItemsRepository`
- Presentation: `ItemEditorViewModel`, `ListViewController`
- Coordinator: `ItemsCoordinator` for navigation flow
- Tests: 55 passing tests (domain, infrastructure, presentation)

### Backend Integration
```bash
# Start backend
cd backend && docker compose up -d

# Verify
curl http://localhost:3000/health
curl http://localhost:3000/v1/items

# Items API endpoints
GET    /v1/items           # Fetch all
POST   /v1/items           # Create
PUT    /v1/items/:id       # Update
DELETE /v1/items/:id       # Delete
```

### Test Categories
```bash
# Run all tests
xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17'

# Run specific test class
xcodebuild test -only-testing:ShellTests/CreateItemUseCaseTests

# Skip UI tests (they fail due to .claude Skills in bundle)
xcodebuild test -skip-testing:ShellUITests
```

## Do NOT

### ❌ Speculate About Code
- Don't guess field names, function signatures, or implementations
- Always Read files before proposing changes
- Use Grep to find patterns if unsure

### ❌ Refactor Unnecessarily
- Don't "improve" code unless explicitly asked
- Don't add docstrings to unchanged functions
- Don't extract abstractions prematurely
- Don't rename variables for "clarity"

### ❌ Over-Engineer Solutions
- Don't add feature flags for one-time changes
- Don't create protocols for single implementations
- Don't add error handling for impossible cases
- Don't design for hypothetical future requirements

### ❌ Mix Concerns in Commits
```
// ❌ Bad commit
"Fix ItemEditor crash + refactor ListViewController + update Profile"

// ✅ Good commits
Commit 1: "fix: ItemEditor crash when saving empty name"
Commit 2: "refactor: Extract reusable components from ListViewController"
Commit 3: "feat: Add edit mode to Profile"
```

### ❌ Skip Tests
- Never commit implementation without tests
- Never modify code without updating corresponding tests
- Never assume "manual testing is enough"

### ❌ Break Swift 6 Concurrency
- No force unwraps (!)
- No try! or as!
- No global mutable state
- Always @MainActor for UI
- Always Sendable for cross-actor types

## Validation Framework (SwiftSDK)

### Architecture
- **Validator Protocol**: Generic, composable validators with associated types
- **Type-Erased Composition**: Use `.and()` to chain validators with different error types
- **Built-in Validators**: StringLength, Regex, CharacterSet, Range, DateAge
- **100% Test Coverage**: All validators have comprehensive test coverage

### Usage in Domain Layer

Compose validators for business logic:

```swift
// Create composed validator
let usernameValidator = StringLengthValidator(minimum: 3, maximum: 20)
    .and(CharacterSetValidator(allowedCharacters: .alphanumerics))

// In Use Case
func execute(username: String) async throws -> User {
    let result = usernameValidator.validate(username)

    switch result {
    case .success(let validUsername):
        return try await repository.create(username: validUsername)
    case .failure(let error):
        throw ValidationError.invalidUsername
    }
}
```

### Common Validation Patterns

```swift
// Email validation
let emailValidator = RegexValidator(
    pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$",
    options: .caseInsensitive
)

// Password requirements
let passwordValidator = StringLengthValidator(minimum: 8, maximum: 128)
    .and(RegexValidator(pattern: ".*[A-Z].*"))  // Uppercase required
    .and(RegexValidator(pattern: ".*[0-9].*"))  // Number required

// Age verification (COPPA compliance)
let ageValidator = DateAgeValidator(minimumAge: 13, maximumAge: 120)

// Numeric range
let scoreValidator = RangeValidator(minimum: 0, maximum: 100)
```

### Testing Validators

```swift
func testComposedValidator() {
    let validator = StringLengthValidator(minimum: 3, maximum: 10)
        .and(CharacterSetValidator(allowedCharacters: .alphanumerics))

    XCTAssertNoThrow(try validator.validate("abc123").get())
    XCTAssertThrowsError(try validator.validate("ab").get())  // Too short
    XCTAssertThrowsError(try validator.validate("abc_123").get())  // Invalid char
}
```

See: `Shell/SwiftSDK/Validation/README.md` for detailed documentation

## Common Tasks

### Add Repository Feature Flag
```swift
// 1. Add flag to RepositoryConfig
struct RepositoryConfig {
    static var useHTTPItemsRepository: Bool {
        #if DEBUG
        return true
        #else
        return true
        #endif
    }
}

// 2. Update AppDependencyContainer
private lazy var sharedItemsRepository: ItemsRepository = {
    if RepositoryConfig.useHTTPItemsRepository {
        let httpClient = URLSessionItemsHTTPClient(...)
        return HTTPItemsRepository(httpClient: httpClient)
    } else {
        return InMemoryItemsRepository()
    }
}()
```

### Mock HTTP Requests in Tests
```swift
// Use URLProtocol-based mocking (see HTTPItemsRepositoryTests.swift)
class MockURLProtocol: URLProtocol {
    static var mockResponse: (Data, HTTPURLResponse, Error?)?
    // Intercept requests and return mock data
}

// Configure in setUp()
let configuration = URLSessionConfiguration.ephemeral
configuration.protocolClasses = [MockURLProtocol.self]
mockURLSession = URLSession(configuration: configuration)
```

## Claude Code Skills Available

Located in `.claude/skills/`:
- `/architecture-check` - Validate Clean Architecture compliance
- `/ci-checklist` - Pre-merge validation
- `/code-quality-check` - Swift best practices audit
- `/coordinator-review` - Navigation flow analysis
- `/di-audit` - Dependency injection review
- `/git-diff-reviewer` - AI-powered diff analysis
- `/http-repo` - HTTP repository scaffolding
- `/new-feature` - Full feature scaffolding
- `/regression-suite` - Run critical tests
- `/swiftlint` - Code style enforcement
- `/test-feature` - Test suite runner

Use these to maintain quality and consistency.

## Commit Guidelines

### Format
```
<type>: <subject>

<body>

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Types
- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code restructuring (no behavior change)
- `test:` - Adding/updating tests
- `docs:` - Documentation updates
- `chore:` - Build, dependencies, tooling

### Examples
```bash
feat: Add HTTP Items repository with full CRUD operations

- Created URLSessionItemsHTTPClient actor for thread-safe networking
- Implemented HTTPItemsRepository with error mapping
- Added ItemDTO for API <-> Domain conversion
- Tests: 9 HTTP repository tests passing

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

## Questions to Ask Before Implementing

1. **Have I read all relevant files?**
2. **Do I understand the existing patterns?**
3. **Have I created a plan and gotten approval?**
4. **Am I only modifying what's necessary?**
5. **Have I written/updated tests?**
6. **Does this follow Clean Architecture?**
7. **Is this Swift 6 compliant?**
8. **Will this commit message be clear in 6 months?**

## Getting Help

- Read existing code in Items module as reference
- Check `.claude/Context/` for architecture documentation
- Use Skills for automated checks
- Ask clarifying questions before implementing
- When in doubt, create a plan first

---

**Last Updated**: 2026-02-01 (Epic 3 Complete)
**Project Version**: Swift 6, iOS 26.2, Xcode 16.3
