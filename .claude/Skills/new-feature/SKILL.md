---
name: new-feature
description: Scaffold a new feature module following Shell's vertical slice architecture (Clean Architecture + MVVM + Repository + Coordinator). Use when the user wants to add a new feature like Notes, Watchlist, Alerts, etc.
argument-hint: [FeatureName]
---

# New Feature Scaffold

Scaffold a new feature following Shell's vertical slice architecture (Clean Architecture + MVVM + Repository + Coordinator patterns).

Read `.claude/Context/architecture.md` and `.claude/Context/design-patterns.md` for the full architectural rules.

## Input

- **Feature name** from `$ARGUMENTS` (PascalCase singular, e.g., "Note" not "Notes")
- If no argument provided, ask the user for:
  - Feature name (PascalCase singular)
  - Primary screens (e.g., "List", "Detail", "Editor")

## Steps

### 1. Create Feature Folder Structure

Create folders under `Shell/Features/<FeatureName>/`:

```
Features/<FeatureName>/
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   ├── Contracts/
│   └── Errors/
├── Infrastructure/
│   └── Repositories/
└── Presentation/
    ├── List/          (if needed)
    ├── Detail/        (if needed)
    └── Editor/        (if needed)
```

### 2. Create Test Folder Structure

Mirror under `ShellTests/Features/<FeatureName>/`:

```
ShellTests/Features/<FeatureName>/
├── Domain/
│   ├── Entities/
│   └── UseCases/
├── Infrastructure/
│   └── Repositories/
└── Presentation/
```

### 3. Generate Domain Layer

#### Entity (`Domain/Entities/<FeatureName>.swift`)

```swift
import Foundation

struct <FeatureName>: Identifiable, Sendable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

#### Repository Protocol (`Domain/Contracts/<FeatureName>Repository.swift`)

```swift
import Foundation

protocol <FeatureName>Repository: Actor {
    func fetchAll() async throws -> [<FeatureName>]
    func fetch(id: UUID) async throws -> <FeatureName>?
    func create(_ item: <FeatureName>) async throws
    func update(_ item: <FeatureName>) async throws
    func delete(id: UUID) async throws
}
```

#### Errors (`Domain/Errors/<FeatureName>Error.swift`)

Typed enums conforming to `Error` and `LocalizedError` with validation and repository error cases.

#### Use Cases (`Domain/UseCases/`)

Generate `Fetch<FeatureName>sUseCase.swift` and `Create<FeatureName>UseCase.swift`:
- Protocol + `Default` implementation
- Repository injected via init
- `async throws`
- Validation before repository calls

### 4. Generate Infrastructure Layer

#### In-Memory Repository (`Infrastructure/Repositories/InMemory<FeatureName>Repository.swift`)

Actor-based, thread-safe implementation of the repository protocol with CRUD operations.

### 5. Generate Presentation Layer

#### ViewModel (`Presentation/List/<FeatureName>ListViewModel.swift`)

Follow `Shell/Features/Items/Presentation/ListViewModel.swift` pattern:
- `@MainActor final class` with `ObservableObject`
- `@Published` state: items, isLoading, errorMessage
- Dependencies injected via init
- Weak coordinator reference
- `async` methods for data loading

#### ViewController (`Presentation/List/<FeatureName>ListViewController.swift`)

Follow `Shell/Features/Auth/Presentation/Login/LoginViewController.swift` pattern:
- Programmatic UI (no storyboard)
- `init(viewModel:)` constructor injection
- `setupUI()` and `bindViewModel()` in `viewDidLoad()`
- Combine bindings to `@Published` properties
- Delegate pattern for coordinator communication

### 6. Generate Coordinator

`Shell/App/Coordinators/<FeatureName>Coordinator.swift`:

Follow `Shell/App/Coordinators/ItemsCoordinator.swift` pattern:
- Conform to `Coordinator` protocol
- Constructor injection
- `start()` shows list screen
- Navigation methods for detail/editor
- Delegate protocol for parent communication

### 7. Generate Test Files

For each production file, create matching test:
- Use case tests: success, validation errors, repository errors
- Repository tests: CRUD operations
- ViewModel tests: state management, loading, errors

All tests follow: AAA pattern, `sut` naming, `setUp()`/`tearDown()` isolation, private mock classes.

### 8. Print Integration Checklist

```
Feature scaffolded: <FeatureName>

Next steps:
1. Wire in AppDependencyContainer (repository, use cases, coordinator factory)
2. Add navigation entry point in AppCoordinator
3. Add Route case if using type-safe routing
4. Add files to Xcode project
5. Run tests
```
