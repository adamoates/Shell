# Design Patterns Reference

## Purpose

This document is a quick reference for design patterns used in the Shell iOS app.

**Each pattern here serves a specific purpose. Use patterns to solve problems, not to show off.**

## Pattern Catalog

### 1. MVVM (Model-View-ViewModel)
**Category**: Architectural
**Purpose**: Separate presentation logic from views
**When**: Every screen in the app
**Why**: Testability, reusability, clarity

**Structure**:
```swift
// Model (Domain Entity)
struct Note {
    let id: UUID
    let title: String
    let content: String
}

// ViewModel (Presentation Logic)
final class NotesListViewModel: ObservableObject {
    @Published private(set) var notes: [NoteUIModel] = []
    @Published private(set) var isLoading = false

    private let fetchNotesUseCase: FetchNotesUseCase

    init(fetchNotesUseCase: FetchNotesUseCase) {
        self.fetchNotesUseCase = fetchNotesUseCase
    }

    func loadNotes() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let domainNotes = try await fetchNotesUseCase.execute()
            notes = domainNotes.map { NoteUIModel(from: $0) }
        } catch {
            // Handle error
        }
    }
}

// View (UI)
final class NotesListViewController: UIViewController {
    private let viewModel: NotesListViewModel

    init(viewModel: NotesListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    // View observes ViewModel, triggers actions
}
```

**Key Points**:
- ViewModel never imports UIKit/SwiftUI
- View is as dumb as possible
- ViewModel is 100% unit testable

---

### 2. Coordinator
**Category**: Architectural
**Purpose**: Centralize navigation logic
**When**: All navigation between screens
**Why**: ViewControllers shouldn't know about each other

**Structure**:
```swift
protocol Coordinator: AnyObject {
    func start()
}

final class NotesCoordinator: Coordinator {
    private let navigationController: UINavigationController
    private let dependencies: AppDependencies

    init(
        navigationController: UINavigationController,
        dependencies: AppDependencies
    ) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let viewModel = makeNotesListViewModel()
        let viewController = NotesListViewController(
            viewModel: viewModel,
            coordinator: self
        )
        navigationController.setViewControllers([viewController], animated: false)
    }

    func showDetail(for noteID: UUID) {
        let viewModel = makeNoteDetailViewModel(noteID: noteID)
        let viewController = NoteDetailViewController(
            viewModel: viewModel,
            coordinator: self
        )
        navigationController.pushViewController(viewController, animated: true)
    }

    private func makeNotesListViewModel() -> NotesListViewModel {
        NotesListViewModel(
            fetchNotesUseCase: dependencies.fetchNotesUseCase
        )
    }
}
```

**Key Points**:
- Coordinator owns the navigation stack
- ViewControllers call coordinator for navigation
- Factory methods keep construction localized

---

### 3. Use Case (Interactor)
**Category**: Domain
**Purpose**: Encapsulate single business operation
**When**: Any business logic
**Why**: Single responsibility, testable, reusable

**Structure**:
```swift
// Protocol in Domain
protocol FetchNotesUseCase {
    func execute() async throws -> [Note]
}

// Implementation
final class DefaultFetchNotesUseCase: FetchNotesUseCase {
    private let repository: NoteRepository

    init(repository: NoteRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Note] {
        return try await repository.fetchAll()
    }
}
```

**When to Create**:
- Any business operation (create, read, update, delete)
- Complex validation or transformation
- Operations that combine multiple repositories

**When NOT to Create**:
- Simple property access
- Pure data transformation (use mappers)
- UI-only logic (use ViewModels)

---

### 4. Repository
**Category**: Domain Boundary
**Purpose**: Abstract data source complexity
**When**: All data access
**Why**: Domain doesn't care where data comes from

**Structure**:
```swift
// Protocol in Domain
protocol NoteRepository {
    func fetchAll() async throws -> [Note]
    func save(_ note: Note) async throws
    func delete(id: UUID) async throws
}

// Implementation in Data
final class DefaultNoteRepository: NoteRepository {
    private let remoteDataSource: RemoteNoteDataSource
    private let localDataSource: LocalNoteDataSource

    func fetchAll() async throws -> [Note] {
        // Try remote first, fall back to local
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

**Key Points**:
- Protocol in Domain, implementation in Data
- Hides data source complexity (remote/local/cache)
- Returns Domain entities, not DTOs

---

### 5. Adapter
**Category**: Structural
**Purpose**: Convert between incompatible interfaces
**When**: Platform boundaries (URLSession, Core Data, Keychain)
**Why**: Keep domain platform-agnostic

**Structure**:
```swift
// Domain protocol
protocol HTTPClient {
    func request(_ request: HTTPRequest) async throws -> HTTPResponse
}

// Adapter wraps URLSession
final class URLSessionAdapter: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request(_ request: HTTPRequest) async throws -> HTTPResponse {
        // Convert HTTPRequest → URLRequest
        let urlRequest = try makeURLRequest(from: request)

        // Execute
        let (data, response) = try await session.data(for: urlRequest)

        // Convert URLResponse → HTTPResponse
        return try makeHTTPResponse(data: data, response: response)
    }

    private func makeURLRequest(from request: HTTPRequest) throws -> URLRequest {
        // Conversion logic
    }

    private func makeHTTPResponse(data: Data, response: URLResponse) throws -> HTTPResponse {
        // Conversion logic
    }
}
```

**Use Cases**:
- URLSession → HTTPClient
- Core Data → Repository
- Keychain → SecureStorage
- Any external framework integration

---

### 6. Decorator
**Category**: Structural
**Purpose**: Add behavior without changing interface
**When**: Cross-cutting concerns (auth, retry, logging)
**Why**: Composable, testable, single responsibility

**Structure**:
```swift
// Base protocol
protocol HTTPClient {
    func request(_ request: HTTPRequest) async throws -> HTTPResponse
}

// Decorator adds authentication
final class AuthenticatedHTTPClient: HTTPClient {
    private let decorated: HTTPClient
    private let tokenProvider: TokenProvider

    init(decorated: HTTPClient, tokenProvider: TokenProvider) {
        self.decorated = decorated
        self.tokenProvider = tokenProvider
    }

    func request(_ request: HTTPRequest) async throws -> HTTPResponse {
        var authenticatedRequest = request
        authenticatedRequest.headers["Authorization"] = "Bearer \(tokenProvider.token)"
        return try await decorated.request(authenticatedRequest)
    }
}

// Decorator adds logging
final class LoggingHTTPClient: HTTPClient {
    private let decorated: HTTPClient
    private let logger: Logger

    func request(_ request: HTTPRequest) async throws -> HTTPResponse {
        logger.log("Request: \(request.url)")
        let response = try await decorated.request(request)
        logger.log("Response: \(response.statusCode)")
        return response
    }
}

// Compose decorators
let client = LoggingHTTPClient(
    decorated: RetryHTTPClient(
        decorated: AuthenticatedHTTPClient(
            decorated: URLSessionAdapter()
        )
    )
)
```

**Use Cases**:
- HTTP request authentication
- Request/response logging
- Retry logic
- Rate limiting
- Caching

---

### 7. Strategy
**Category**: Behavioral
**Purpose**: Encapsulate interchangeable algorithms
**When**: Behavior varies (caching, retry, sorting)
**Why**: Open/closed principle, easy to test

**Structure**:
```swift
// Strategy protocol
protocol RetryStrategy {
    func shouldRetry(attempt: Int, error: Error) -> Bool
    func delayBeforeRetry(attempt: Int) -> TimeInterval
}

// Concrete strategies
final class ExponentialBackoffStrategy: RetryStrategy {
    private let maxAttempts: Int
    private let baseDelay: TimeInterval

    func shouldRetry(attempt: Int, error: Error) -> Bool {
        return attempt < maxAttempts
    }

    func delayBeforeRetry(attempt: Int) -> TimeInterval {
        return baseDelay * pow(2.0, Double(attempt))
    }
}

final class ConstantDelayStrategy: RetryStrategy {
    private let maxAttempts: Int
    private let delay: TimeInterval

    func shouldRetry(attempt: Int, error: Error) -> Bool {
        return attempt < maxAttempts
    }

    func delayBeforeRetry(attempt: Int) -> TimeInterval {
        return delay
    }
}

// Context uses strategy
final class RetryHTTPClient: HTTPClient {
    private let decorated: HTTPClient
    private let strategy: RetryStrategy

    func request(_ request: HTTPRequest) async throws -> HTTPResponse {
        var attempt = 0
        while true {
            do {
                return try await decorated.request(request)
            } catch {
                if strategy.shouldRetry(attempt: attempt, error: error) {
                    attempt += 1
                    let delay = strategy.delayBeforeRetry(attempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                } else {
                    throw error
                }
            }
        }
    }
}
```

**Use Cases**:
- Retry strategies
- Caching strategies
- Sorting/filtering strategies
- Animation strategies

---

### 8. Factory
**Category**: Creational
**Purpose**: Centralize object creation
**When**: Creating complex objects, screens
**Why**: Hide construction complexity, enable DI

**Structure**:
```swift
protocol ViewControllerFactory {
    func makeNotesListViewController() -> NotesListViewController
    func makeNoteDetailViewController(noteID: UUID) -> NoteDetailViewController
    func makeLoginViewController() -> LoginViewController
}

final class DefaultViewControllerFactory: ViewControllerFactory {
    private let dependencies: AppDependencies

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    func makeNotesListViewController() -> NotesListViewController {
        let viewModel = NotesListViewModel(
            fetchNotesUseCase: dependencies.useCases.fetchNotes,
            deleteNoteUseCase: dependencies.useCases.deleteNote
        )
        return NotesListViewController(viewModel: viewModel)
    }

    func makeNoteDetailViewController(noteID: UUID) -> NoteDetailViewController {
        let viewModel = NoteDetailViewModel(
            noteID: noteID,
            fetchNoteUseCase: dependencies.useCases.fetchNote,
            updateNoteUseCase: dependencies.useCases.updateNote
        )
        return NoteDetailViewController(viewModel: viewModel)
    }
}
```

**Key Points**:
- Centralizes construction logic
- Hides complex dependency graphs
- Easy to swap implementations
- Testable (can inject mock factory)

---

### 9. Facade
**Category**: Structural
**Purpose**: Simplify complex subsystem
**When**: Core Data stack, API client, SecureStorage
**Why**: Hide complexity, provide simple interface

**Structure**:
```swift
final class SecureStorage {
    private let keychain: KeychainWrapper

    init(keychain: KeychainWrapper = KeychainWrapper()) {
        self.keychain = keychain
    }

    func save(token: String) throws {
        let data = token.data(using: .utf8)!
        try keychain.set(
            data,
            forKey: "authToken",
            withAccess: .whenUnlockedThisDeviceOnly
        )
    }

    func retrieveToken() throws -> String? {
        guard let data = try keychain.data(forKey: "authToken") else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    func deleteToken() throws {
        try keychain.delete(forKey: "authToken")
    }
}

// Usage
let storage = SecureStorage()
try storage.save(token: "abc123")
let token = try storage.retrieveToken()
```

**Use Cases**:
- Core Data stack management
- API client configuration
- Keychain access
- Biometric authentication

---

### 10. Observer (Combine)
**Category**: Behavioral
**Purpose**: Notify dependents of state changes
**When**: Reactive data binding (ViewModel → View)
**Why**: Decoupled, declarative, reactive

**Structure**:
```swift
import Combine

final class NotesListViewModel: ObservableObject {
    @Published private(set) var notes: [NoteUIModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private var cancellables = Set<AnyCancellable>()

    func loadNotes() async {
        isLoading = true
        // Load notes...
        isLoading = false
    }
}

// View observes changes
final class NotesListViewController: UIViewController {
    private let viewModel: NotesListViewModel
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.$notes
            .sink { [weak self] notes in
                self?.updateUI(with: notes)
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .sink { [weak self] isLoading in
                self?.showLoadingIndicator(isLoading)
            }
            .store(in: &cancellables)
    }
}
```

**Key Points**:
- Use `@Published` for observable properties
- Use `.sink` or `.assign` to observe
- Store cancellables to prevent leaks
- Use `[weak self]` in closures

---

### 11. Dependency Injection
**Category**: Principle/Pattern
**Purpose**: Provide dependencies from outside
**When**: Always (no singletons)
**Why**: Testability, flexibility, composition

**Structure**:
```swift
// ❌ BAD: Singleton
class NetworkManager {
    static let shared = NetworkManager()
    func fetchData() { }
}

class ViewModel {
    func loadData() {
        NetworkManager.shared.fetchData()  // Hard dependency
    }
}

// ✅ GOOD: Constructor injection
protocol DataFetcher {
    func fetchData() async throws -> Data
}

class NetworkManager: DataFetcher {
    func fetchData() async throws -> Data {
        // Implementation
    }
}

class ViewModel {
    private let dataFetcher: DataFetcher

    init(dataFetcher: DataFetcher) {  // Injected
        self.dataFetcher = dataFetcher
    }

    func loadData() async {
        try await dataFetcher.fetchData()
    }
}

// Easy to test with mock
class MockDataFetcher: DataFetcher {
    func fetchData() async throws -> Data {
        return Data()
    }
}

let viewModel = ViewModel(dataFetcher: MockDataFetcher())
```

**Types of DI**:
1. **Constructor Injection** (preferred): Pass via init
2. **Property Injection**: Set after construction (rare)
3. **Method Injection**: Pass to method (uncommon)

---

## Pattern Selection Guide

### "Which pattern should I use?"

**For navigation**:
→ Coordinator

**For presentation logic**:
→ MVVM (ViewModel)

**For business logic**:
→ Use Case

**For data access**:
→ Repository (protocol in Domain, impl in Data)

**For platform integration**:
→ Adapter (URLSession, Core Data, Keychain)

**For adding behavior (auth, logging, retry)**:
→ Decorator

**For interchangeable algorithms**:
→ Strategy

**For object creation**:
→ Factory

**For simplifying complex subsystems**:
→ Facade

**For reactive updates**:
→ Observer (Combine)

---

## Anti-Patterns to Avoid

### 1. Singleton Abuse
```swift
// ❌ BAD
class DataManager {
    static let shared = DataManager()
}

// ✅ GOOD
class DataManager {
    init(dependencies: Dependencies) {
        // Constructor injection
    }
}
```

### 2. Massive View Controller
```swift
// ❌ BAD: 1000-line view controller with business logic
class MassiveViewController {
    func validateEmail() { }
    func saveToDatabase() { }
    func callAPI() { }
    // ... 900 more lines
}

// ✅ GOOD: Thin view controller, fat viewmodel
class CleanViewController {
    private let viewModel: ViewModel
    // Only UI code
}

class ViewModel {
    // Presentation logic
}
```

### 3. God Object
```swift
// ❌ BAD: One object does everything
class AppManager {
    func login() { }
    func fetchNotes() { }
    func saveSettings() { }
    func processPayment() { }
}

// ✅ GOOD: Focused objects
class AuthManager { }
class NotesManager { }
class SettingsManager { }
class PaymentManager { }
```

### 4. Premature Abstraction
```swift
// ❌ BAD: Abstract before you need to
protocol StringProviding {
    func provideString() -> String
}

class HelloProvider: StringProviding {
    func provideString() -> String { "Hello" }
}

// ✅ GOOD: Start simple
let greeting = "Hello"
```

---

## Pattern Combinations

### Common Patterns Together

#### MVVM + Coordinator + Use Case
```
ViewController
     │
     ├─ owns ViewModel
     │       │
     │       ├─ uses UseCase
     │       │       │
     │       │       └─ uses Repository
     │
     └─ calls Coordinator for navigation
```

#### Repository + Data Source + Mapper
```
Repository
     │
     ├─ owns RemoteDataSource
     │       │
     │       └─ returns DTOs
     │
     ├─ owns LocalDataSource
     │       │
     │       └─ returns DTOs
     │
     └─ uses Mapper (DTO → Domain)
```

#### HTTPClient + Decorators
```
URLSessionAdapter (base)
     │
     └─ wrapped by AuthenticatedHTTPClient
             │
             └─ wrapped by RetryHTTPClient
                     │
                     └─ wrapped by LoggingHTTPClient
```

---

## Summary

### Core Patterns (Use Everywhere)
- **MVVM**: All screens
- **Coordinator**: All navigation
- **Use Case**: All business logic
- **Repository**: All data access
- **Dependency Injection**: Always

### Supporting Patterns (Use When Needed)
- **Adapter**: Platform integration
- **Decorator**: Cross-cutting concerns
- **Strategy**: Interchangeable behavior
- **Factory**: Complex construction
- **Facade**: Simplify subsystems

### Remember
- Use patterns to solve problems, not to show off
- Start simple, add patterns when complexity demands it
- Every pattern should reduce coupling or increase testability
- If a pattern makes code more complex without benefit, don't use it

**Intentional patterns. Not pattern soup.**
