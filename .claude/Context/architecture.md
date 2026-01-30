# Architecture Rules (NON-NEGOTIABLE)

## Core Architecture: Clean Architecture + MVVM + Coordinator

This app uses a **layered architecture** with strict dependency rules.

## The Three Layers

### 1. Domain Layer (Core)
**Purpose**: Business logic and entities
**Contains**:
- Entities (domain models)
- Use Cases (application business rules)
- Repository Protocols (boundaries)
- Domain Errors

**Dependencies**: NONE
- Domain knows nothing about UI or Data layers
- Domain defines protocols that Data layer implements
- Pure Swift, no imports except Foundation basics

**Example**:
```swift
// Domain/Entities/Note.swift
struct Note {
    let id: UUID
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
}

// Domain/UseCases/FetchNotesUseCase.swift
protocol FetchNotesUseCase {
    func execute() async throws -> [Note]
}

// Domain/Repositories/NoteRepository.swift
protocol NoteRepository {
    func fetchAll() async throws -> [Note]
    func save(_ note: Note) async throws
    func delete(id: UUID) async throws
}
```

### 2. Data Layer (Infrastructure)
**Purpose**: Data access and external systems
**Contains**:
- Repository Implementations
- Data Sources (Remote, Local)
- DTOs (Data Transfer Objects)
- Mappers (DTO ↔ Domain)
- Adapters (URLSession, CoreData, Keychain)

**Dependencies**: Domain only
- Implements Domain protocols
- Maps between DTOs and Domain entities
- Handles platform-specific concerns

**Example**:
```swift
// Data/Repositories/DefaultNoteRepository.swift
final class DefaultNoteRepository: NoteRepository {
    private let remoteDataSource: RemoteNoteDataSource
    private let localDataSource: LocalNoteDataSource

    init(
        remoteDataSource: RemoteNoteDataSource,
        localDataSource: LocalNoteDataSource
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }

    func fetchAll() async throws -> [Note] {
        // Try remote, fall back to local
        do {
            let dtos = try await remoteDataSource.fetchAll()
            let notes = dtos.map { $0.toDomain() }
            try await localDataSource.save(notes)
            return notes
        } catch {
            return try await localDataSource.fetchAll()
        }
    }
}
```

### 3. Presentation Layer (UI)
**Purpose**: User interface and interaction
**Contains**:
- ViewControllers / Views
- ViewModels
- Coordinators
- UI Models (if different from Domain)

**Dependencies**: Domain only
- ViewModels use Domain use cases
- ViewModels transform Domain entities to UI models
- No direct data access

**Example**:
```swift
// Presentation/NotesListViewModel.swift
final class NotesListViewModel {
    private let fetchNotesUseCase: FetchNotesUseCase
    @Published private(set) var notes: [NoteUIModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    init(fetchNotesUseCase: FetchNotesUseCase) {
        self.fetchNotesUseCase = fetchNotesUseCase
    }

    func loadNotes() async {
        isLoading = true
        error = nil

        do {
            let domainNotes = try await fetchNotesUseCase.execute()
            notes = domainNotes.map { NoteUIModel(from: $0) }
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
```

## Design Patterns (INTENTIONAL USE)

### Patterns We Use and Why

#### 1. MVVM (Model-View-ViewModel)
**Purpose**: Separate presentation logic from views
**When**: All screens
**Why**: Testability, reusability, clarity

```swift
// ViewModel owns presentation logic
// View observes ViewModel
// ViewModel uses Use Cases
```

#### 2. Coordinator
**Purpose**: Centralize navigation logic
**When**: All navigation
**Why**: ViewControllers shouldn't know about each other

```swift
protocol Coordinator: AnyObject {
    func start()
}

final class NotesCoordinator: Coordinator {
    private let navigationController: UINavigationController
    private let dependencies: AppDependencies

    func start() {
        let viewModel = makeNotesListViewModel()
        let viewController = NotesListViewController(
            viewModel: viewModel,
            coordinator: self
        )
        navigationController.setViewControllers([viewController], animated: false)
    }

    func showDetail(for noteID: UUID) {
        // Create and push detail screen
    }
}
```

#### 3. Use Case (Interactor)
**Purpose**: Encapsulate single business operation
**When**: Any business logic
**Why**: Single responsibility, testable, reusable

```swift
final class CreateNoteUseCase {
    private let repository: NoteRepository
    private let idGenerator: IDGenerator
    private let clock: Clock

    func execute(title: String, content: String) async throws -> Note {
        let note = Note(
            id: idGenerator.generate(),
            title: title,
            content: content,
            createdAt: clock.now(),
            updatedAt: clock.now()
        )
        try await repository.save(note)
        return note
    }
}
```

#### 4. Repository
**Purpose**: Abstract data source complexity
**When**: All data access
**Why**: Domain doesn't care where data comes from

```swift
// Protocol in Domain
protocol NoteRepository {
    func fetchAll() async throws -> [Note]
}

// Implementation in Data
final class DefaultNoteRepository: NoteRepository {
    // Can switch between remote/local/cache
}
```

#### 5. Adapter
**Purpose**: Convert between incompatible interfaces
**When**: Platform boundaries (URLSession, Keychain, CoreData)
**Why**: Domain remains platform-agnostic

```swift
// Adapt URLSession to our domain needs
final class URLSessionAdapter: HTTPClient {
    private let session: URLSession

    func request(_ request: HTTPRequest) async throws -> HTTPResponse {
        // Convert domain HTTPRequest to URLRequest
        // Execute
        // Convert URLResponse to domain HTTPResponse
    }
}
```

#### 6. Decorator
**Purpose**: Add behavior without changing interface
**When**: Cross-cutting concerns (auth, retry, logging)
**Why**: Composable, testable, single responsibility

```swift
final class AuthenticatedHTTPClient: HTTPClient {
    private let decorated: HTTPClient
    private let tokenProvider: TokenProvider

    func request(_ request: HTTPRequest) async throws -> HTTPResponse {
        var authenticatedRequest = request
        authenticatedRequest.headers["Authorization"] = "Bearer \(tokenProvider.token)"
        return try await decorated.request(authenticatedRequest)
    }
}

// Usage: chain decorators
let client = LoggingHTTPClient(
    decorated: RetryHTTPClient(
        decorated: AuthenticatedHTTPClient(
            decorated: URLSessionAdapter()
        )
    )
)
```

#### 7. Strategy
**Purpose**: Encapsulate interchangeable algorithms
**When**: Behavior varies (caching, retry, sorting)
**Why**: Open/closed principle, easy to test

```swift
protocol CacheStrategy {
    func shouldCache(_ response: HTTPResponse) -> Bool
    func cacheKey(for request: HTTPRequest) -> String
}

final class TimeBoundCacheStrategy: CacheStrategy {
    // Implementation
}

final class SizeLimitedCacheStrategy: CacheStrategy {
    // Implementation
}
```

#### 8. Factory
**Purpose**: Centralize object creation
**When**: Creating complex objects, screens
**Why**: Hide construction complexity, DI

```swift
protocol ViewControllerFactory {
    func makeNotesListViewController() -> NotesListViewController
    func makeNoteDetailViewController(noteID: UUID) -> NoteDetailViewController
}

final class DefaultViewControllerFactory: ViewControllerFactory {
    private let dependencies: AppDependencies

    func makeNotesListViewController() -> NotesListViewController {
        let viewModel = NotesListViewModel(
            fetchNotesUseCase: dependencies.useCases.fetchNotes
        )
        return NotesListViewController(viewModel: viewModel)
    }
}
```

#### 9. Facade
**Purpose**: Simplify complex subsystem
**When**: CoreDataStack, APIClient, SecureStorage
**Why**: Hide complexity, provide simple interface

```swift
final class SecureStorage {
    private let keychain: KeychainWrapper

    func save(token: String) throws {
        // Handle all keychain complexity internally
    }

    func retrieveToken() throws -> String? {
        // Hide query complexity
    }
}
```

## Dependency Rules (STRICT)

### Rule 1: Dependencies Point Inward
```
UI → Domain ← Data
```
- UI depends on Domain
- Data depends on Domain
- Domain depends on nothing

### Rule 2: No Singletons (Except Apple)
```swift
// ❌ BAD
class NetworkManager {
    static let shared = NetworkManager()
}

// ✅ GOOD
final class NetworkManager {
    init(configuration: NetworkConfiguration) {
        // Injected dependencies
    }
}
```

### Rule 3: Constructor Injection
```swift
// ✅ Always inject dependencies via init
final class NotesListViewModel {
    private let fetchNotesUseCase: FetchNotesUseCase

    init(fetchNotesUseCase: FetchNotesUseCase) {
        self.fetchNotesUseCase = fetchNotesUseCase
    }
}

// ❌ Never use property injection without justification
```

### Rule 4: Protocols for Boundaries
```swift
// Domain defines protocol
protocol NoteRepository {
    func fetchAll() async throws -> [Note]
}

// Data implements
final class DefaultNoteRepository: NoteRepository {
    // Implementation
}

// UI receives protocol
final class NotesListViewModel {
    init(repository: NoteRepository) {
        // Works with any implementation
    }
}
```

### Rule 5: Composition Root
All concrete types are wired in ONE place:

```swift
// AppDependencies.swift
final class AppDependencies {
    // Shared
    let httpClient: HTTPClient
    let storage: SecureStorage

    // Repositories
    let noteRepository: NoteRepository

    // Use Cases
    let fetchNotesUseCase: FetchNotesUseCase
    let createNoteUseCase: CreateNoteUseCase

    init() {
        // Wire up concrete implementations
        let session = URLSession.shared
        let adapter = URLSessionAdapter(session: session)
        let authClient = AuthenticatedHTTPClient(decorated: adapter)
        self.httpClient = LoggingHTTPClient(decorated: authClient)

        self.storage = KeychainStorage()

        let remoteSource = RemoteNoteDataSource(client: httpClient)
        let localSource = LocalNoteDataSource(coreData: coreDataStack)
        self.noteRepository = DefaultNoteRepository(
            remote: remoteSource,
            local: localSource
        )

        self.fetchNotesUseCase = DefaultFetchNotesUseCase(
            repository: noteRepository
        )

        // ... etc
    }
}
```

## Layer Responsibilities

### Domain Layer
✅ **Does**:
- Define business entities
- Define business rules (use cases)
- Define contracts (protocols)
- Validate business constraints

❌ **Does NOT**:
- Import UIKit or SwiftUI
- Know about databases or APIs
- Handle presentation logic
- Deal with frameworks

### Data Layer
✅ **Does**:
- Implement repository protocols
- Make network requests
- Access databases
- Map DTOs to domain
- Cache data

❌ **Does NOT**:
- Import UIKit or SwiftUI (except for platform types)
- Contain business logic
- Make decisions about presentation
- Expose DTOs to domain

### Presentation Layer
✅ **Does**:
- Display UI
- Handle user input
- Transform domain to UI models
- Navigate between screens
- Observe ViewModels

❌ **Does NOT**:
- Access repositories directly
- Contain business logic
- Make network requests
- Access database directly

## Testing Strategy Per Layer

### Domain Layer Tests
```swift
// Pure unit tests, no mocks needed
func testNoteValidation() {
    let note = Note(title: "", content: "test")
    XCTAssertThrowsError(try note.validate())
}

// Use case tests with mock repository
func testFetchNotesUseCase() async throws {
    let mockRepo = MockNoteRepository()
    mockRepo.stubbedNotes = [Note(/* ... */)]

    let useCase = DefaultFetchNotesUseCase(repository: mockRepo)
    let notes = try await useCase.execute()

    XCTAssertEqual(notes.count, 1)
}
```

### Data Layer Tests
```swift
// Integration tests with in-memory storage
func testRepositorySavesAndFetches() async throws {
    let context = NSPersistentContainer.inMemory()
    let repository = CoreDataNoteRepository(context: context)

    let note = Note(/* ... */)
    try await repository.save(note)

    let fetched = try await repository.fetchAll()
    XCTAssertEqual(fetched.first?.id, note.id)
}

// Network tests with URLProtocol stub
func testRemoteDataSourceFetchesNotes() async throws {
    let stubClient = StubHTTPClient()
    stubClient.stubbedResponse = HTTPResponse(/* ... */)

    let dataSource = RemoteNoteDataSource(client: stubClient)
    let dtos = try await dataSource.fetchAll()

    XCTAssertEqual(dtos.count, 2)
}
```

### Presentation Layer Tests
```swift
// ViewModel tests with mock use cases
func testNotesListViewModel() async {
    let mockUseCase = MockFetchNotesUseCase()
    mockUseCase.stubbedNotes = [Note(/* ... */)]

    let viewModel = NotesListViewModel(useCase: mockUseCase)

    await viewModel.loadNotes()

    XCTAssertEqual(viewModel.notes.count, 1)
    XCTAssertFalse(viewModel.isLoading)
}
```

## Anti-Patterns to Avoid

### ❌ God Objects
```swift
// BAD: One ViewModel does everything
class AppViewModel {
    var notes: [Note]
    var user: User
    var settings: Settings
    func login() { }
    func fetchNotes() { }
    func updateSettings() { }
}

// GOOD: Focused ViewModels
class NotesListViewModel {
    var notes: [Note]
    func fetchNotes() { }
}
```

### ❌ Feature Envy
```swift
// BAD: ViewModel reaches into model
viewModel.note.repository.save()

// GOOD: ViewModel uses use case
viewModel.saveNote()
```

### ❌ Primitive Obsession
```swift
// BAD
func createUser(email: String, password: String) { }

// GOOD
struct Email { let value: String }
struct Password { let value: String }
func createUser(email: Email, password: Password) { }
```

### ❌ Leaky Abstractions
```swift
// BAD: Domain knows about HTTP
protocol NoteRepository {
    func fetch() async throws -> URLResponse
}

// GOOD: Domain uses domain types
protocol NoteRepository {
    func fetch() async throws -> [Note]
}
```

## Decision Framework

When adding new code, ask:

1. **Which layer?** Domain, Data, or UI?
2. **Dependencies?** Does it only depend on inner layers?
3. **Tested?** Can I unit test this easily?
4. **Protocol?** Should this be behind a protocol?
5. **Pattern?** Does a pattern reduce complexity here?

If you can't answer clearly, the design needs work.

## Summary

- **Clean Architecture**: Domain → Data ← UI
- **MVVM**: For presentation logic
- **Coordinator**: For navigation
- **Patterns**: Used to solve problems, not show off
- **Dependencies**: Always injected
- **Testing**: Every layer testable
- **Quality**: Zero warnings, zero shortcuts

This is non-negotiable.
