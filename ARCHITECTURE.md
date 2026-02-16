# Shell Architecture Guide

This document provides a detailed explanation of Shell's architecture, design patterns, and implementation strategies.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Clean Architecture Layers](#clean-architecture-layers)
3. [MVVM Pattern](#mvvm-pattern)
4. [Repository Pattern](#repository-pattern)
5. [Coordinator Pattern](#coordinator-pattern)
6. [Dependency Injection](#dependency-injection)
7. [SwiftUI Integration](#swiftui-integration)
8. [Concurrency Model](#concurrency-model)
9. [Feature Organization](#feature-organization)
10. [Testing Strategy](#testing-strategy)

---

## Architecture Overview

Shell implements **Clean Architecture** with strict layer separation, ensuring:
- **Testability** - Domain logic isolated from frameworks
- **Independence** - Business rules don't depend on UI or infrastructure
- **Flexibility** - Easy to swap implementations (in-memory → HTTP → Core Data)
- **Maintainability** - Clear separation of concerns

### High-Level Layer Diagram

```
┌─────────────────────────────────────────────────────────┐
│                   Presentation Layer                    │
│                                                           │
│  • ViewControllers (UIKit)                               │
│  • Views (SwiftUI)                                       │
│  • ViewModels (@Published properties, Combine)           │
│  • Coordinators (Navigation)                             │
│                                                           │
│  Dependencies: Domain only (protocols, entities, errors) │
└─────────────────────────────────────────────────────────┘
                            │
                            │ Uses protocols from
                            ↓
┌─────────────────────────────────────────────────────────┐
│                      Domain Layer                       │
│                                                           │
│  • Entities (Item, UserProfile, Identity)                │
│  • Use Cases (Business logic)                            │
│  • Repository Protocols (Contracts/Interfaces)           │
│  • Domain Errors (Validation, business rules)            │
│                                                           │
│  Dependencies: NONE (pure Swift, no frameworks)          │
└─────────────────────────────────────────────────────────┘
                            ↑
                            │ Implements protocols
                            │
┌─────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                   │
│                                                           │
│  • Repository Implementations (InMemory, future HTTP)    │
│  • API Clients (URLSession-based)                         │
│  • Persistence (UserDefaults, Keychain, Core Data)       │
│  • External Framework Adapters                           │
│                                                           │
│  Dependencies: Domain protocols (via protocol conformance)│
└─────────────────────────────────────────────────────────┘
```

### Dependency Rule

**The Dependency Rule**: Source code dependencies point **inward only**.

- ✅ **Presentation** depends on **Domain**
- ✅ **Infrastructure** depends on **Domain** (via protocols)
- ❌ **Domain** NEVER depends on Presentation or Infrastructure

This ensures domain logic remains pure, testable, and independent of frameworks.

---

## Current Source of Truth

`ARCHITECTURE.md` is the canonical architecture reference for this repository.
When examples in other docs drift, align those docs to this file and to current code.

### Canonical Dependency Direction

- Presentation depends inward on Domain contracts/entities/use cases.
- Infrastructure depends inward on Domain contracts/entities.
- Domain does not depend on Presentation or Infrastructure.
- Concrete dependency wiring happens in `Shell/Core/DI/AppDependencyContainer.swift`.

### Canonical Folder Map (Current Repo)

```
Shell/
├── App/
│   ├── Boot/
│   ├── Coordinators/
│   └── Navigation/
├── Core/
│   ├── Contracts/
│   ├── Coordinator/
│   ├── DI/
│   ├── Infrastructure/
│   ├── Navigation/
│   └── Presentation/
└── Features/
    └── {Feature}/
        ├── Domain/            # Contracts, Entities, UseCases, optional Errors
        ├── Infrastructure/    # Repositories, API/HTTP adapters (as needed)
        └── Presentation/      # Screen folders with ViewModel + VC/View pairs
```

### Allowed Exceptions Policy

Temporary deviations from the architecture are allowed only when:

- The deviation is explicitly documented with file path and reason.
- The intended migration target is named.
- The deviation is removed in a follow-up change.

Current documented deviation:

- `Shell/App/Coordinators/AuthCoordinator.swift` contains a direct forgot-password network call using `URLSession`. Planned migration: move this call behind an auth use case + repository/client abstraction, then keep coordinator focused on routing/orchestration only.

---

## Clean Architecture Layers

### 1. Domain Layer

**Location**: `Features/{FeatureName}/Domain/`

**Purpose**: Contains **business logic**, **entities**, and **contracts**. This layer is the heart of the application and must remain framework-independent.

**Components**:

#### Entities (`Domain/Entities/`)
Plain Swift types representing business concepts.

```swift
// Features/Items/Domain/Entities/Item.swift
struct Item: Identifiable, Sendable {
    let id: UUID
    var name: String
    var isCompleted: Bool
}
```

#### Use Cases (`Domain/UseCases/`)
Encapsulate single business operations.

```swift
// Features/Items/Domain/UseCases/CreateItemUseCase.swift
actor CreateItemUseCase {
    private let repository: ItemsRepository

    init(repository: ItemsRepository) {
        self.repository = repository
    }

    func execute(name: String) async throws -> Item {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ItemValidationError.emptyName
        }

        let item = Item(id: UUID(), name: name, isCompleted: false)
        try await repository.create(item)
        return item
    }
}
```

**Key Characteristics**:
- Actors for thread-safe async operations
- Single responsibility (one business operation)
- Depend on repository **protocols**, not implementations

#### Repository Protocols (`Domain/Contracts/`)
Define data access contracts.

```swift
// Features/Items/Domain/Contracts/ItemsRepository.swift
protocol ItemsRepository: Actor {
    func fetchAll() async throws -> [Item]
    func create(_ item: Item) async throws
    func update(_ item: Item) async throws
    func delete(id: UUID) async throws
}
```

**Why Protocols?**
- Domain defines the contract
- Infrastructure provides the implementation
- Easy to swap implementations (in-memory → HTTP → Core Data)
- Enables testability (mock repositories in tests)

#### Domain Errors (`Domain/Errors/`)
Business rule violations.

```swift
// Features/Auth/Domain/Errors/AuthError.swift
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError
    case serverError(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password."
        case .networkError:
            return "Network connection appears to be offline."
        case .serverError(let message):
            return message
        case .unknown:
            return "An unexpected error occurred."
        }
    }
}
```

---

### 2. Presentation Layer

**Location**: `Features/{FeatureName}/Presentation/`

**Purpose**: Handles **UI**, **user interactions**, and **presentation logic**. Displays data from ViewModels, sends user actions to ViewModels.

**Components**:

#### ViewModels (`Presentation/{ScreenName}/`)
Presentation logic, state management, and Combine publishers.

```swift
// Features/Items/Presentation/List/ListViewModel.swift
@MainActor
final class ListViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies (Use Cases)
    private let fetchItemsUseCase: FetchItemsUseCase
    private let deleteItemUseCase: DeleteItemUseCase

    init(fetchItemsUseCase: FetchItemsUseCase, deleteItemUseCase: DeleteItemUseCase) {
        self.fetchItemsUseCase = fetchItemsUseCase
        self.deleteItemUseCase = deleteItemUseCase
    }

    // MARK: - Actions
    func loadItems() async {
        isLoading = true
        errorMessage = nil

        do {
            items = try await fetchItemsUseCase.execute()
        } catch {
            errorMessage = "Failed to load items"
        }

        isLoading = false
    }

    func deleteItem(id: UUID) async {
        do {
            try await deleteItemUseCase.execute(id: id)
            items.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete item"
        }
    }
}
```

**Key Characteristics**:
- `@MainActor` for UI updates on main thread
- `ObservableObject` for Combine integration
- `@Published` properties trigger UI updates
- Async functions for business operations
- Depends on **Use Cases**, not repositories directly

#### ViewControllers (UIKit) (`Presentation/{ScreenName}/`)
Thin view layer, only handles UI updates.

```swift
// Features/Items/Presentation/List/ListViewController.swift
final class ListViewController: UIViewController {
    private let viewModel: ListViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: ListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()

        Task {
            await viewModel.loadItems()
        }
    }

    private func bindViewModel() {
        // Observe @Published properties
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.updateTableView(with: items)
            }
            .store(in: &cancellables)

        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.showError(message)
            }
            .store(in: &cancellables)
    }
}
```

**Responsibilities**:
- Setup UI (Auto Layout, styling)
- Bind to ViewModel `@Published` properties via Combine
- Forward user actions to ViewModel
- **NO business logic** - only presentation

#### SwiftUI Views (`Presentation/{ScreenName}/`)
Declarative UI with SwiftUI.

```swift
// Features/Profile/Presentation/Editor/ProfileEditorView.swift
struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel

    var body: some View {
        Form {
            Section(header: Text("Identity")) {
                TextField("Screen Name", text: $viewModel.screenName)
                DatePicker("Birthday", selection: $viewModel.birthday, displayedComponents: .date)
            }

            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                }
            }

            Section {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .disabled(!viewModel.isSaveEnabled)
            }
        }
        .navigationTitle("Edit Profile")
    }
}
```

**Key Characteristics**:
- `@ObservedObject` for ViewModel binding
- Two-way binding with `$` syntax
- Declarative UI updates automatically when ViewModel state changes

---

### 3. Infrastructure Layer

**Location**: `Features/{FeatureName}/Infrastructure/`

**Purpose**: Implements **repository protocols** from Domain, handles external dependencies (network, database, frameworks).

#### Repository Implementations (`Infrastructure/Repositories/`)

```swift
// Features/Items/Infrastructure/InMemoryItemsRepository.swift
actor InMemoryItemsRepository: ItemsRepository {
    private var items: [Item] = []

    func fetchAll() async throws -> [Item] {
        return items
    }

    func create(_ item: Item) async throws {
        guard !items.contains(where: { $0.id == item.id }) else {
            throw ItemError.createFailed
        }
        items.append(item)
    }

    func update(_ item: Item) async throws {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw ItemError.notFound
        }
        items[index] = item
    }

    func delete(id: UUID) async throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw ItemError.notFound
        }
        items.remove(at: index)
    }
}
```

**Current State**: In-memory implementations for v1.0
**Future**: HTTP repositories, Core Data repositories

**Example HTTP Repository (v2.0)**:

```swift
// Future: Features/Items/Infrastructure/Repositories/HTTPItemsRepository.swift
actor HTTPItemsRepository: ItemsRepository {
    private let apiClient: ItemsHTTPClient

    init(apiClient: ItemsHTTPClient) {
        self.apiClient = apiClient
    }

    func fetchAll() async throws -> [Item] {
        let response: ItemsResponse = try await apiClient.request(
            HTTPEndpoint(path: "items", method: .get),
            responseType: ItemsResponse.self
        )
        return response.items
    }

    func create(_ item: Item) async throws {
        let payload = try JSONEncoder().encode(item)
        try await apiClient.request(
            HTTPEndpoint(path: "items", method: .post, body: payload)
        )
    }

    // ... HTTP implementations
}
```

**Swappability**: Change from in-memory to HTTP by updating dependency injection:

```swift
// In AppDependencyContainer
// v1.0: In-memory
let itemsRepository = InMemoryItemsRepository()

// v2.0: HTTP
let itemsRepository = HTTPItemsRepository(apiClient: apiClient)
```

ViewModels and Use Cases **don't change** - they depend on the protocol, not the implementation.

---

## MVVM Pattern

**Model-View-ViewModel** separates presentation logic from UI.

### Layers in MVVM

```
┌──────────────────┐
│      View        │  UIViewController or SwiftUI View
│  (Presentation)  │  - Displays data
│                  │  - Captures user input
│                  │  - Observes ViewModel via Combine
└──────────────────┘
         ↓ binds to
┌──────────────────┐
│    ViewModel     │  ObservableObject with @Published properties
│  (Presentation)  │  - Presentation logic
│                  │  - State management
│                  │  - Calls Use Cases
└──────────────────┘
         ↓ calls
┌──────────────────┐
│    Use Cases     │  Business logic actors
│     (Domain)     │  - Validates business rules
│                  │  - Orchestrates repositories
└──────────────────┘
         ↓ calls
┌──────────────────┐
│   Repository     │  Data access protocol
│ (Infrastructure) │  - Fetch, create, update, delete
└──────────────────┘
```

### Example Flow: Creating an Item

1. **User Action**: User taps "Add Item" button in `ListViewController`
2. **View → ViewModel**: `await viewModel.createItem(name: "Buy milk")`
3. **ViewModel → Use Case**: `try await createItemUseCase.execute(name: "Buy milk")`
4. **Use Case → Repository**: `try await repository.create(item)`
5. **Repository**: Stores item in memory
6. **Use Case → ViewModel**: Returns created `Item`
7. **ViewModel**: Updates `@Published var items` array
8. **ViewModel → View**: Combine publisher triggers UI update
9. **View**: Table view reloads with new item

---

## Repository Pattern

The Repository Pattern abstracts data access, allowing the domain to remain independent of infrastructure.

### Why Repositories?

**Problem**: ViewModels shouldn't know if data comes from:
- In-memory storage
- HTTP API
- Core Data database
- Realm
- SQLite

**Solution**: ViewModels depend on **repository protocols**, infrastructure provides **implementations**.

### Protocol in Domain, Implementation in Infrastructure

```
Domain Layer (Protocol):
Features/Items/Domain/Contracts/ItemsRepository.swift

Infrastructure Layer (Implementation):
Features/Items/Infrastructure/InMemoryItemsRepository.swift
Features/Items/Infrastructure/Repositories/HTTPItemsRepository.swift (future)
```

### Benefits

1. **Testability**: Mock repositories in tests
2. **Swappability**: Change implementations without changing ViewModels
3. **Clear boundaries**: Domain doesn't depend on frameworks
4. **Incremental migration**: Start with in-memory, add HTTP later

### Example: Swapping Repositories

```swift
// v1.0: In-memory repository
let repository = InMemoryItemsRepository()
let fetchUseCase = FetchItemsUseCase(repository: repository)
let viewModel = ListViewModel(fetchItemsUseCase: fetchUseCase, ...)

// v2.0: HTTP repository (same ViewModel code!)
let repository = HTTPItemsRepository(apiClient: apiClient)
let fetchUseCase = FetchItemsUseCase(repository: repository)
let viewModel = ListViewModel(fetchItemsUseCase: fetchUseCase, ...)
```

**ViewModel doesn't change** - it depends on `ItemsRepository`, not the concrete type.

---

## Coordinator Pattern

**Problem**: ViewControllers managing navigation creates tight coupling:
- ViewControllers know about other ViewControllers
- Difficult to change navigation flow
- Hard to test navigation logic

**Solution**: Coordinators own navigation, ViewControllers are isolated.

### Coordinator Structure

```swift
// Core/Coordinator/Coordinator.swift
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}
```

### Example: ItemsCoordinator

```swift
// App/Coordinators/ItemsCoordinator.swift
final class ItemsCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let dependencies: AppDependencyContainer

    init(navigationController: UINavigationController, dependencies: AppDependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        showItemsList()
    }

    func showItemsList() {
        let viewModel = ListViewModel(fetchItems: dependencies.makeFetchItemsUseCase())
        viewModel.coordinator = self

        let viewController = ListViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showItemEditor(item: Item?) {
        let viewModel = ItemEditorViewModel(
            createItem: dependencies.makeCreateItemUseCase(),
            updateItem: dependencies.makeUpdateItemUseCase(),
            itemToEdit: item
        )

        let viewController = ItemEditorViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showItemDetail(item: Item) {
        let viewController = DetailViewController(item: item)
        navigationController.pushViewController(viewController, animated: true)
    }
}
```

### ViewModel → Coordinator Communication

```swift
// ViewModel requests navigation
protocol ListViewModelCoordinator: AnyObject {
    func showItemEditor(item: Item?)
    func showItemDetail(item: Item)
}

@MainActor
final class ListViewModel: ObservableObject {
    weak var coordinator: ListViewModelCoordinator?

    func addItemTapped() {
        coordinator?.showItemEditor(item: nil) // Create new item
    }

    func itemTapped(_ item: Item) {
        coordinator?.showItemDetail(item: item)
    }
}
```

### Benefits

1. **Decoupling**: ViewControllers don't know about other ViewControllers
2. **Testability**: Mock coordinators in ViewModel tests
3. **Type-safe navigation**: Compile-time checked routes
4. **Centralized navigation logic**: Easy to change flow

---

## Dependency Injection

Shell uses **constructor injection** with a **composition root** pattern.

### Composition Root: AppDependencyContainer

```swift
// Core/DI/AppDependencyContainer.swift
@MainActor
final class AppDependencyContainer {
    // MARK: - Repositories
    let itemsRepository: InMemoryItemsRepository
    let userProfileRepository: InMemoryUserProfileRepository

    // MARK: - Use Cases
    let fetchItemsUseCase: FetchItemsUseCase
    let createItemUseCase: CreateItemUseCase
    let updateItemUseCase: UpdateItemUseCase
    let deleteItemUseCase: DeleteItemUseCase

    let setupIdentityUseCase: CompleteIdentitySetupUseCase
    let fetchUserProfileUseCase: FetchProfileUseCase

    init() {
        // Create repositories
        itemsRepository = InMemoryItemsRepository()
        userProfileRepository = InMemoryUserProfileRepository()

        // Create use cases with repository dependencies
        fetchItemsUseCase = DefaultFetchItemsUseCase(repository: itemsRepository)
        createItemUseCase = DefaultCreateItemUseCase(repository: itemsRepository)
        updateItemUseCase = DefaultUpdateItemUseCase(repository: itemsRepository)
        deleteItemUseCase = DefaultDeleteItemUseCase(repository: itemsRepository)

        setupIdentityUseCase = DefaultCompleteIdentitySetupUseCase(repository: userProfileRepository)
        fetchUserProfileUseCase = DefaultFetchProfileUseCase(repository: userProfileRepository)
    }
}
```

### Dependency Flow

```
AppDelegate
    ↓ creates
AppDependencyContainer
    ↓ passed to
Coordinators
    ↓ inject into
ViewModels
    ↓ inject into
ViewControllers
```

### Example: Creating ListViewController

```swift
// In ItemsCoordinator
func showItemsList() {
    // 1. Create ViewModel with injected Use Cases
    let viewModel = ListViewModel(
        fetchItemsUseCase: dependencies.fetchItemsUseCase,
        deleteItemUseCase: dependencies.deleteItemUseCase
    )

    // 2. Create ViewController with injected ViewModel
    let viewController = ListViewController(viewModel: viewModel)

    // 3. Push onto navigation stack
    navigationController.pushViewController(viewController, animated: true)
}
```

### Benefits

1. **Explicit dependencies**: Constructor parameters show what's needed
2. **Single source of truth**: AppDependencyContainer is the only place dependencies are created
3. **Testability**: Inject mocks in tests
4. **Compile-time safety**: Missing dependencies won't compile

---

## SwiftUI Integration

Shell demonstrates **hybrid UIKit/SwiftUI** architecture using `UIHostingController`.

### Why Hybrid?

- Incremental SwiftUI adoption without full rewrite
- Use SwiftUI for new screens while keeping UIKit navigation
- Leverage existing UIKit infrastructure (coordinators, navigation controllers)

### UIHostingController Bridge

```swift
// Wrapping SwiftUI View in UIKit
let swiftUIView = ProfileEditorView(viewModel: viewModel)
let hostingController = UIHostingController(rootView: swiftUIView)
navigationController.pushViewController(hostingController, animated: true)
```

### Example: Profile Editor (SwiftUI)

```swift
// Features/Profile/Presentation/Editor/ProfileEditorView.swift
struct ProfileEditorView: View {
    @ObservedObject var viewModel: ProfileEditorViewModel

    var body: some View {
        Form {
            Section(header: Text("Identity")) {
                TextField("Screen Name", text: $viewModel.screenName)
                DatePicker("Birthday", selection: $viewModel.birthday, displayedComponents: .date)
            }

            Section {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .disabled(!viewModel.isSaveEnabled)
            }
        }
        .navigationTitle("Edit Profile")
    }
}
```

### ProfileCoordinator with SwiftUI

```swift
// App/Coordinators/ProfileCoordinator.swift
final class ProfileCoordinator: Coordinator {
    func showProfileEditor(userID: String) {
        let viewModel = ProfileEditorViewModel(
            userID: userID,
            setupIdentityUseCase: dependencies.setupIdentityUseCase
        )

        // Wrap SwiftUI view in UIHostingController
        let view = ProfileEditorView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: view)

        // Push onto UIKit navigation stack
        navigationController.pushViewController(hostingController, animated: true)
    }
}
```

### Benefits

1. **Gradual migration**: Add SwiftUI one screen at a time
2. **Shared ViewModel**: Same ViewModel works with UIKit or SwiftUI
3. **Coordinator pattern preserved**: Navigation logic remains centralized
4. **No full rewrite**: Leverage existing architecture

---

## Concurrency Model

Shell uses **Swift 6 strict concurrency** with **actors** and **async/await**.

### Key Principles

1. **Repositories are Actors**: Thread-safe data access
2. **Use Cases are Actors**: Thread-safe business logic
3. **ViewModels are @MainActor**: UI updates on main thread
4. **Sendable conformance**: Safe data passing between actors

### Example: Actor-Based Repository

```swift
actor InMemoryItemsRepository: ItemsRepository {
    private var items: [Item] = [] // Isolated to actor

    func fetchAll() async throws -> [Item] {
        return items // Safe: accessed within actor
    }

    func create(_ item: Item) async throws {
        items.append(item) // Safe: mutation within actor
    }
}
```

**Why Actor?** Prevents data races when multiple tasks access the repository concurrently.

### Example: Async Use Case

```swift
actor CreateItemUseCase {
    private let repository: ItemsRepository

    func execute(name: String) async throws -> Item {
        // Validate on actor
        guard !name.isEmpty else {
            throw ItemValidationError.emptyName
        }

        let item = Item(id: UUID(), name: name, isCompleted: false)

        // Await repository call (crosses actor boundary)
        try await repository.create(item)

        return item
    }
}
```

### Example: MainActor ViewModel

```swift
@MainActor
final class ListViewModel: ObservableObject {
    @Published private(set) var items: [Item] = [] // Main thread

    func loadItems() async {
        // Suspends on main actor, resumes when use case completes
        let fetchedItems = try await fetchItemsUseCase.execute()

        // Updates @Published property on main thread
        items = fetchedItems
    }
}
```

### Sendable Types

```swift
struct Item: Sendable { // Safe to pass between actors
    let id: UUID
    var name: String
    var isCompleted: Bool
}
```

### Benefits

1. **Zero warnings**: Swift 6 strict concurrency enforced
2. **Data race prevention**: Compiler guarantees thread safety
3. **Clear concurrency boundaries**: Actors, @MainActor, Sendable
4. **Modern async/await**: No completion handlers or callback hell

---

## Feature Organization

Shell organizes features using **vertical slices** - each feature contains all its layers.

### Feature Structure

```
Features/Items/
├── Domain/
│   ├── Contracts/
│   │   └── ItemsRepository.swift
│   ├── Entities/
│   │   └── Item.swift
│   └── UseCases/
│       ├── FetchItemsUseCase.swift
│       ├── CreateItemUseCase.swift
│       ├── UpdateItemUseCase.swift
│       └── DeleteItemUseCase.swift
├── Infrastructure/
│   └── Repositories/
│       └── InMemoryItemsRepository.swift
└── Presentation/
    ├── List/
    │   ├── ListViewController.swift
    │   └── ListViewModel.swift
    ├── Detail/
    │   └── DetailViewController.swift
    └── ItemEditor/
        ├── ItemEditorViewController.swift
        └── ItemEditorViewModel.swift
```

### Why Vertical Slices?

1. **Feature cohesion**: All code for a feature lives together
2. **Easy to navigate**: Find everything related to Items in one folder
3. **Scalability**: Add new features without touching existing ones
4. **Clear boundaries**: Domain, Infrastructure, Presentation clearly separated

### Shared Code Organization

```
Core/
├── Coordinator/               # Base Coordinator protocol
├── Contracts/                 # Domain-owned shared protocols
│   ├── Configuration/
│   ├── Navigation/
│   ├── Networking/
│   └── Security/
├── DI/                        # Dependency injection
├── Infrastructure/            # Shared implementations
│   ├── Configuration/
│   ├── Navigation/
│   ├── Networking/
│   └── Security/
├── Navigation/                # Type-safe routing
└── Presentation/              # Shared UI components

SwiftSDK/                      # Reusable SDK components
├── Storage/                   # Generic storage framework
├── Validation/                # Validation framework
└── Observation/               # Observer pattern
```

---

## Testing Strategy

Shell includes **195+ tests** covering domain, infrastructure, and presentation layers.

### Testing Philosophy

1. **Test business logic, not frameworks**: Focus on domain use cases
2. **Test repositories for thread safety**: Actor isolation, concurrent access
3. **Test ViewModels for state management**: @Published properties, error handling
4. **Test validation comprehensively**: Edge cases, error conditions

### Test Organization

```
ShellTests/
├── Features/
│   ├── Auth/
│   │   ├── Domain/
│   │   │   └── UseCases/
│   │   │       └── LoginUseCaseTests.swift
│   │   └── Presentation/
│   │       └── Login/
│   │           └── LoginViewModelTests.swift
│   ├── Items/
│   │   ├── Domain/
│   │   │   └── UseCases/
│   │   │       ├── CreateItemUseCaseTests.swift
│   │   │       ├── FetchItemsUseCaseTests.swift
│   │   │       └── DeleteItemUseCaseTests.swift
│   │   ├── Infrastructure/
│   │   │   └── Repositories/
│   │   │       └── InMemoryItemsRepositoryTests.swift
│   │   └── Presentation/
│   │       └── List/
│   │           └── ListViewModelTests.swift
│   └── Profile/
│       ├── Domain/
│       │   ├── Entities/
│       │   │   └── IdentityTests.swift
│       │   └── UseCases/
│       │       └── CompleteIdentitySetupUseCaseTests.swift
│       └── Presentation/
│           └── Editor/
│               └── ProfileEditorViewModelTests.swift
└── SwiftSDK/
    ├── Storage/
    │   └── InMemoryStorageTests.swift
    ├── Validation/
    │   └── ValidatorTests.swift
    └── Observation/
        └── ObservableTests.swift
```

### Example: Use Case Test

```swift
// ShellTests/Features/Items/Domain/UseCases/CreateItemUseCaseTests.swift
final class CreateItemUseCaseTests: XCTestCase {
    var repository: InMemoryItemsRepository!
    var useCase: CreateItemUseCase!

    override func setUp() async throws {
        repository = InMemoryItemsRepository()
        useCase = CreateItemUseCase(repository: repository)
    }

    func testCreateItemSuccess() async throws {
        // When
        let item = try await useCase.execute(name: "Buy milk")

        // Then
        XCTAssertEqual(item.name, "Buy milk")
        XCTAssertFalse(item.isCompleted)

        let allItems = try await repository.fetchAll()
        XCTAssertEqual(allItems.count, 1)
        XCTAssertEqual(allItems.first?.name, "Buy milk")
    }

    func testCreateItemWithEmptyNameThrowsError() async {
        // When/Then
        await assertThrowsError(
            try await useCase.execute(name: ""),
            expectedError: ItemValidationError.emptyName
        )
    }
}
```

### Example: Repository Test (Thread Safety)

```swift
// Example actor-isolation repository test
final class InMemoryItemsRepositoryTests: XCTestCase {
    func testConcurrentWrites() async throws {
        let repository = InMemoryItemsRepository()

        // Create 100 items concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let item = Item(id: UUID(), name: "Item \(i)", isCompleted: false)
                    try? await repository.create(item)
                }
            }
        }

        // Verify all 100 items created (no data races)
        let items = try await repository.fetchAll()
        XCTAssertEqual(items.count, 100)
    }
}
```

### Example: ViewModel Test

```swift
// ShellTests/Features/Items/Presentation/List/ListViewModelTests.swift
@MainActor
final class ListViewModelTests: XCTestCase {
    func testLoadItemsSuccess() async {
        // Given
        let repository = InMemoryItemsRepository()
        let item = Item(id: UUID(), name: "Test", isCompleted: false)
        try! await repository.create(item)

        let fetchUseCase = FetchItemsUseCase(repository: repository)
        let viewModel = ListViewModel(fetchItemsUseCase: fetchUseCase, ...)

        // When
        await viewModel.loadItems()

        // Then
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.name, "Test")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
}
```

---

## Summary

Shell demonstrates production-ready iOS architecture:

✅ **Clean Architecture** - Domain, Presentation, Infrastructure layers
✅ **MVVM** - ViewModels for presentation logic, Views for UI
✅ **Repository Pattern** - Protocol-based data abstraction
✅ **Coordinator Pattern** - Type-safe navigation
✅ **Dependency Injection** - Composition root pattern
✅ **SwiftUI Hybrid** - Incremental SwiftUI adoption
✅ **Swift 6 Concurrency** - Actors, async/await, Sendable
✅ **Vertical Slices** - Feature-based organization
✅ **Comprehensive Testing** - 195+ tests

### Key Takeaways

1. **Domain is independent** - No framework dependencies
2. **Repositories are swappable** - In-memory → HTTP → Core Data
3. **ViewModels don't change when infrastructure changes**
4. **Coordinators centralize navigation** - ViewControllers are isolated
5. **Actors prevent data races** - Swift 6 strict concurrency
6. **SwiftUI and UIKit coexist** - Hybrid architecture via UIHostingController

For implementation guides, see:
- [README.md](README.md) - Quick start and overview
- [Docs/QuickStart.md](Docs/QuickStart.md) - Adding new features step-by-step

---

**Shell v1.0.0** - Production-ready iOS architecture foundation.
