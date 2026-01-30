# TDD Requirements (EXTREME)

## Core Principle

**Tests are written FIRST.**

Exception: Purely visual layout code (Storyboard UI, programmatic constraints).
Everything else: **test-first, no exceptions.**

## The TDD Cycle

### Red → Green → Refactor

1. **Red**: Write a failing test
2. **Green**: Write minimal code to pass
3. **Refactor**: Improve code while keeping tests green

```swift
// 1. RED: Write failing test
func testFetchNotesReturnsNotesFromRepository() async throws {
    // Arrange
    let mockRepo = MockNoteRepository()
    mockRepo.stubbedNotes = [Note(id: UUID(), title: "Test")]
    let useCase = DefaultFetchNotesUseCase(repository: mockRepo)

    // Act
    let notes = try await useCase.execute()

    // Assert
    XCTAssertEqual(notes.count, 1)
    XCTAssertEqual(notes.first?.title, "Test")
}

// 2. GREEN: Make it pass
final class DefaultFetchNotesUseCase: FetchNotesUseCase {
    private let repository: NoteRepository

    init(repository: NoteRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Note] {
        return try await repository.fetchAll()
    }
}

// 3. REFACTOR: Improve (tests still green)
```

## What MUST Be Tested

### 1. Domain Layer (100% Coverage Target)

#### Use Cases
```swift
// ✅ Required tests for every use case
class CreateNoteUseCaseTests: XCTestCase {
    func testExecuteCreatesNoteWithCorrectData() async throws
    func testExecuteSavesNoteToRepository() async throws
    func testExecuteThrowsWhenRepositoryFails() async throws
    func testExecuteGeneratesUniqueID() async throws
    func testExecuteSetsCreatedAndUpdatedTimestamps() async throws
}
```

#### Entities/Models
```swift
// ✅ Required tests for validation logic
class NoteTests: XCTestCase {
    func testInitializationSetsAllProperties()
    func testValidationFailsWithEmptyTitle()
    func testValidationFailsWithTooLongContent()
    func testEqualityComparesIDs()
    func testHashableUsesID()
}
```

### 2. Data Layer (80%+ Coverage)

#### Repositories
```swift
// ✅ Integration tests with in-memory storage
class NoteRepositoryTests: XCTestCase {
    func testFetchAllReturnsAllNotes() async throws
    func testSaveAddsNewNote() async throws
    func testSaveUpdatesExistingNote() async throws
    func testDeleteRemovesNote() async throws
    func testFetchByIDReturnsCorrectNote() async throws
    func testFetchByIDThrowsWhenNotFound() async throws

    // Offline/cache scenarios
    func testFetchAllFallsBackToLocalWhenRemoteFails() async throws
    func testSaveUpdatesBothLocalAndRemote() async throws
}
```

#### Data Sources
```swift
// ✅ Network tests with URLProtocol stub
class RemoteNoteDataSourceTests: XCTestCase {
    func testFetchAllReturnsDecodedNotes() async throws
    func testFetchAllThrowsOnNetworkError() async throws
    func testFetchAllThrowsOnInvalidJSON() async throws
    func testCreateNotesendsCorrectRequest() async throws
}
```

### 3. Presentation Layer (100% ViewModel Coverage)

#### ViewModels
```swift
// ✅ Required tests for every ViewModel
class NotesListViewModelTests: XCTestCase {
    func testInitialStateIsEmpty()
    func testLoadNotesUpdatesNotesArray() async
    func testLoadNotesSetsLoadingStateCorrectly() async
    func testLoadNotesHandlesError() async
    func testDeleteNoteRemovesFromList() async
    func testDeleteNoteCallsUseCase() async
    func testSearchFiltersNotesByTitle() async
}
```

#### Coordinators
```swift
// ✅ Navigation logic tests
class NotesCoordinatorTests: XCTestCase {
    func testStartPushesNotesListViewController()
    func testShowDetailPushesDetailViewController()
    func testShowDetailPassesCorrectNoteID()
    func testLogoutPopsToRoot()
}
```

### 4. UI Tests (Critical Paths Only)

```swift
// ✅ One stable end-to-end flow
class NotesUITests: XCTestCase {
    func testCreateAndViewNote() {
        let app = XCUIApplication()
        app.launch()

        // Login
        app.textFields["usernameField"].tap()
        app.textFields["usernameField"].typeText("test@example.com")
        app.secureTextFields["passwordField"].tap()
        app.secureTextFields["passwordField"].typeText("password")
        app.buttons["loginButton"].tap()

        // Create note
        app.buttons["createNoteButton"].tap()
        app.textFields["noteTitleField"].tap()
        app.textFields["noteTitleField"].typeText("Test Note")
        app.textViews["noteContentField"].tap()
        app.textViews["noteContentField"].typeText("Test content")
        app.buttons["saveButton"].tap()

        // Verify
        XCTAssertTrue(app.staticTexts["Test Note"].exists)
    }
}
```

## Test Structure: AAA Pattern

### Arrange → Act → Assert

```swift
func testNotesListViewModelLoadsNotes() async {
    // ARRANGE: Set up test doubles and dependencies
    let mockUseCase = MockFetchNotesUseCase()
    let expectedNotes = [
        Note(id: UUID(), title: "Note 1", content: "Content 1"),
        Note(id: UUID(), title: "Note 2", content: "Content 2")
    ]
    mockUseCase.stubbedResult = .success(expectedNotes)
    let viewModel = NotesListViewModel(fetchNotesUseCase: mockUseCase)

    // ACT: Execute the behavior being tested
    await viewModel.loadNotes()

    // ASSERT: Verify the outcome
    XCTAssertEqual(viewModel.notes.count, 2)
    XCTAssertEqual(viewModel.notes[0].title, "Note 1")
    XCTAssertFalse(viewModel.isLoading)
    XCTAssertNil(viewModel.error)
}
```

## Test Naming Convention

### Pattern: `test_whenX_thenY` or `testMethodName_condition_expectedResult`

```swift
// ✅ GOOD: Clear, descriptive names
func testFetchNotes_whenRepositoryReturnsNotes_returnsNotesArray() async throws
func testCreateNote_whenTitleIsEmpty_throwsValidationError() async throws
func testViewModel_whenLoadNotesFails_setsErrorMessage() async
func testCoordinator_whenShowDetailCalled_pushesDetailViewController()

// ❌ BAD: Vague names
func testFetch()
func testError()
func testViewModel()
```

### Name Components
1. **test** prefix (required)
2. **What** you're testing (method/behavior)
3. **When** (condition/scenario)
4. **Then** (expected outcome)

```swift
func test_saveNote_whenNetworkUnavailable_savesLocally() async throws {
    // Test implementation
}
```

## Test Doubles

### Use the Right Type

#### Mock: Verify behavior (how many times called, with what arguments)
```swift
final class MockNoteRepository: NoteRepository {
    var saveCallCount = 0
    var lastSavedNote: Note?

    func save(_ note: Note) async throws {
        saveCallCount += 1
        lastSavedNote = note
    }
}

// Usage
func testCreateNoteCallsSaveOnRepository() async throws {
    let mockRepo = MockNoteRepository()
    let useCase = CreateNoteUseCase(repository: mockRepo)

    try await useCase.execute(title: "Test", content: "Content")

    XCTAssertEqual(mockRepo.saveCallCount, 1)
    XCTAssertEqual(mockRepo.lastSavedNote?.title, "Test")
}
```

#### Stub: Provide canned responses
```swift
final class StubNoteRepository: NoteRepository {
    var stubbedNotes: [Note] = []
    var stubbedError: Error?

    func fetchAll() async throws -> [Note] {
        if let error = stubbedError {
            throw error
        }
        return stubbedNotes
    }
}

// Usage
func testLoadNotes_whenRepositoryReturnsNotes_updatesNotesArray() async {
    let stubRepo = StubNoteRepository()
    stubRepo.stubbedNotes = [Note(/*...*/)]
    let viewModel = NotesListViewModel(repository: stubRepo)

    await viewModel.loadNotes()

    XCTAssertEqual(viewModel.notes.count, 1)
}
```

#### Fake: Working implementation (simplified)
```swift
final class FakeNoteRepository: NoteRepository {
    private var notes: [UUID: Note] = [:]

    func fetchAll() async throws -> [Note] {
        return Array(notes.values)
    }

    func save(_ note: Note) async throws {
        notes[note.id] = note
    }

    func delete(id: UUID) async throws {
        notes.removeValue(forKey: id)
    }
}

// Usage: Integration-like tests without real database
```

#### Spy: Record information about calls
```swift
final class SpyNoteRepository: NoteRepository {
    var fetchAllCalls: [Void] = []
    var saveCalls: [Note] = []

    func fetchAll() async throws -> [Note] {
        fetchAllCalls.append(())
        return []
    }

    func save(_ note: Note) async throws {
        saveCalls.append(note)
    }
}

// Usage: Verify call order, frequency, etc.
```

### When to Use What

- **Stub**: Testing queries (read operations)
- **Mock**: Testing commands (write operations, side effects)
- **Fake**: Integration tests, complex scenarios
- **Spy**: Tracking call patterns, order

## Async Testing

### async/await
```swift
func testAsyncOperation() async throws {
    let result = try await someAsyncFunction()
    XCTAssertEqual(result, expectedValue)
}
```

### Combine Publishers
```swift
func testPublisher() {
    let expectation = expectation(description: "Publisher emits value")
    var receivedValue: String?

    let cancellable = publisher
        .sink { value in
            receivedValue = value
            expectation.fulfill()
        }

    wait(for: [expectation], timeout: 1.0)
    XCTAssertEqual(receivedValue, "expected")
}
```

### Testing ViewModel State Changes
```swift
func testViewModelPublishesStateChanges() async {
    let viewModel = NotesListViewModel(/*...*/)
    let expectation = expectation(description: "Notes loaded")

    var receivedStates: [Bool] = []
    let cancellable = viewModel.$isLoading
        .sink { isLoading in
            receivedStates.append(isLoading)
            if receivedStates.count == 3 {
                expectation.fulfill()
            }
        }

    await viewModel.loadNotes()
    await fulfillment(of: [expectation], timeout: 1.0)

    XCTAssertEqual(receivedStates, [false, true, false])
}
```

## Test Independence

### Each Test Must Be Independent

```swift
// ❌ BAD: Tests depend on execution order
class BadTests: XCTestCase {
    var sharedState: [Note] = []

    func test1_addNote() {
        sharedState.append(Note(/*...*/))
        XCTAssertEqual(sharedState.count, 1)
    }

    func test2_removeNote() {
        // Depends on test1 running first!
        sharedState.removeLast()
        XCTAssertEqual(sharedState.count, 0)
    }
}

// ✅ GOOD: Tests are independent
class GoodTests: XCTestCase {
    var repository: FakeNoteRepository!

    override func setUp() {
        super.setUp()
        repository = FakeNoteRepository()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testAddNote() async throws {
        let note = Note(/*...*/)
        try await repository.save(note)
        let notes = try await repository.fetchAll()
        XCTAssertEqual(notes.count, 1)
    }

    func testRemoveNote() async throws {
        // Set up its own state
        let note = Note(/*...*/)
        try await repository.save(note)

        try await repository.delete(id: note.id)
        let notes = try await repository.fetchAll()
        XCTAssertEqual(notes.count, 0)
    }
}
```

## Test Data Builders

### Make Test Setup Easy

```swift
// ✅ Test data builder
extension Note {
    static func make(
        id: UUID = UUID(),
        title: String = "Test Note",
        content: String = "Test content",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Note {
        Note(
            id: id,
            title: title,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// Usage in tests
func testSaveNote() async throws {
    let note = Note.make(title: "Custom Title")
    try await repository.save(note)
    // ...
}
```

## Integration Tests

### Core Data (In-Memory)
```swift
extension NSPersistentContainer {
    static func inMemory() -> NSPersistentContainer {
        let container = NSPersistentContainer(
            name: "Shell",
            managedObjectModel: ShellModel.managedObjectModel
        )
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }

        return container
    }
}

// Usage
func testCoreDataRepository() async throws {
    let container = NSPersistentContainer.inMemory()
    let repository = CoreDataNoteRepository(context: container.viewContext)

    let note = Note.make()
    try await repository.save(note)

    let fetched = try await repository.fetchAll()
    XCTAssertEqual(fetched.count, 1)
}
```

### Network (URLProtocol Stub)
```swift
final class StubURLProtocol: URLProtocol {
    static var stubbedResponse: (Data, HTTPURLResponse)?
    static var stubbedError: Error?

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        if let error = Self.stubbedError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        if let (data, response) = Self.stubbedResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() { }
}

// Usage
func testNetworkRequest() async throws {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StubURLProtocol.self]
    let session = URLSession(configuration: config)

    let jsonData = """
    {"notes": [{"id": "123", "title": "Test"}]}
    """.data(using: .utf8)!

    let response = HTTPURLResponse(
        url: URL(string: "https://api.example.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )!

    StubURLProtocol.stubbedResponse = (jsonData, response)

    let dataSource = RemoteNoteDataSource(session: session)
    let notes = try await dataSource.fetchAll()

    XCTAssertEqual(notes.count, 1)
}
```

## Code Coverage

### Targets
- **Domain layer**: 100%
- **Data layer**: 80%+
- **Presentation (ViewModels)**: 100%
- **UI layer (Views)**: Not measured (test via UI tests)

### Viewing Coverage
```bash
xcodebuild test \
  -project Shell.xcodeproj \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES

# View in Xcode: Report Navigator → Coverage tab
```

## Test Performance

### Tests Must Be Fast
- Unit tests: < 0.01s each
- Integration tests: < 0.1s each
- UI tests: < 5s each

### Measure Performance
```swift
func testPerformanceOfSearch() {
    let viewModel = NotesListViewModel(/*...*/)

    measure {
        viewModel.search(query: "test")
    }
}
```

## UI Test Best Practices

### Use Accessibility Identifiers
```swift
// In production code
button.accessibilityIdentifier = "loginButton"
textField.accessibilityIdentifier = "usernameField"

// In UI tests
app.buttons["loginButton"].tap()
app.textFields["usernameField"].typeText("user")
```

### No Sleeps
```swift
// ❌ BAD
sleep(2)
XCTAssertTrue(app.buttons["nextButton"].exists)

// ✅ GOOD
let button = app.buttons["nextButton"]
XCTAssertTrue(button.waitForExistence(timeout: 5))
```

### Page Object Pattern
```swift
struct LoginScreen {
    let app: XCUIApplication

    var usernameField: XCUIElement {
        app.textFields["usernameField"]
    }

    var passwordField: XCUIElement {
        app.secureTextFields["passwordField"]
    }

    var loginButton: XCUIElement {
        app.buttons["loginButton"]
    }

    func login(username: String, password: String) {
        usernameField.tap()
        usernameField.typeText(username)
        passwordField.tap()
        passwordField.typeText(password)
        loginButton.tap()
    }
}

// Usage
func testLogin() {
    let app = XCUIApplication()
    let loginScreen = LoginScreen(app: app)

    loginScreen.login(username: "test", password: "password")
    XCTAssertTrue(app.navigationBars["Notes"].exists)
}
```

## What NOT to Test

### Don't Test
- ❌ Framework behavior (UIKit, SwiftUI, Foundation)
- ❌ Third-party libraries
- ❌ Pure layout code with no logic
- ❌ Trivial getters/setters
- ❌ Generated code

### Focus On
- ✅ Business logic
- ✅ Data transformations
- ✅ Error handling
- ✅ Edge cases
- ✅ Integration points

## Test Quality Checklist

Every test must:
- [ ] Be deterministic (same input → same output)
- [ ] Be fast (< 0.1s for unit tests)
- [ ] Be independent (can run in any order)
- [ ] Have a clear name (test_when_then)
- [ ] Test one thing
- [ ] Follow AAA pattern
- [ ] Use appropriate test doubles
- [ ] Clean up resources (tearDown)

## Summary

### Required Test Coverage
- ✅ Use Cases: 100%
- ✅ ViewModels: 100%
- ✅ Repositories: 80%+
- ✅ Data Sources: 80%+
- ✅ Critical UI flows: 1+ E2E test

### Required Test Quality
- ✅ Tests written first (TDD)
- ✅ Deterministic (no flakiness)
- ✅ Fast (total suite < 30s)
- ✅ Independent (no shared state)
- ✅ Clear names (intention-revealing)

### Commands to Run
```bash
# All tests
xcodebuild test \
  -project Shell.xcodeproj \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Unit tests only
xcodebuild test \
  -project Shell.xcodeproj \
  -scheme Shell \
  -only-testing:ShellTests

# UI tests only
xcodebuild test \
  -project Shell.xcodeproj \
  -scheme Shell \
  -only-testing:ShellUITests

# With coverage
xcodebuild test \
  -project Shell.xcodeproj \
  -scheme Shell \
  -enableCodeCoverage YES
```

**This is the standard. Write tests first. No exceptions.**
