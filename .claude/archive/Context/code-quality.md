# Code Quality Standards (NO EXCEPTIONS)

## The Quality Bar

**Every line of code in this project must meet staff-level standards.**

This means:
- Zero build warnings
- Zero technical debt
- Production-ready from day one
- Maintainable for years
- Readable by anyone

No exceptions. No "we'll fix it later."

## Core Principles

### 1. Clarity Over Cleverness
```swift
// ❌ Clever but unclear
let v = d.filter { $0.t > n }.map(\.i)

// ✅ Clear and explicit
let recentNotes = allNotes
    .filter { $0.timestamp > cutoffDate }
    .map { $0.identifier }
```

### 2. Explicit Over Implicit
```swift
// ❌ Implicit behavior
func process() {
    // Does this throw? Return nil? Crash?
}

// ✅ Explicit contract
func processNotes() async throws -> [Note] {
    // Clear: async, throws, returns notes
}
```

### 3. Small Over Large
```swift
// ❌ God function
func handleUserAction() {
    // 200 lines of mixed concerns
}

// ✅ Composed small functions
func handleUserAction() {
    validateInput()
    processData()
    updateUI()
}
```

### 4. Named Over Anonymous
```swift
// ❌ Magic numbers
if age > 18 && score > 75 {

// ✅ Named constants
let minimumAge = 18
let passingScore = 75
if age > minimumAge && score > passingScore {
```

## Naming Conventions

### Types (Classes, Structs, Enums, Protocols)
```swift
// PascalCase, descriptive, role-revealing
class NotesListViewController { }
struct UserCredentials { }
enum NetworkError { }
protocol NoteRepository { }

// Protocols: noun (capability) or -able/-ible (trait)
protocol Cacheable { }
protocol DataSource { }
```

### Functions and Methods
```swift
// camelCase, verb-based, intention-revealing
func fetchNotes() async throws -> [Note]
func validate(email: String) -> Bool
func transform(notes: [Note]) -> [NoteUIModel]

// Boolean getters: is/has/should/can
var isLoading: Bool
var hasChanges: Bool
func shouldRefresh() -> Bool
func canEdit() -> Bool
```

### Variables and Constants
```swift
// camelCase, descriptive
let maximumRetryCount = 3
var currentPage = 1
let apiBaseURL = URL(string: "https://api.example.com")!

// Avoid abbreviations unless universally known
let id: UUID // ✅ OK (universally known)
let url: URL // ✅ OK
let req: Request // ❌ BAD (use 'request')
let vc: UIViewController // ❌ BAD (use 'viewController')
```

### Collections
```swift
// Plural nouns
let notes: [Note]
let userIDs: [UUID]
let errorMessages: [String]

// Not: noteArray, userIDList, errorMessageCollection
```

## Function Guidelines

### Size Limits
- **Maximum 50 lines** per function
- **Ideal: 10-20 lines**
- If longer, extract helper functions

```swift
// ❌ TOO LONG (100+ lines)
func processUserRegistration() {
    // validation
    // network request
    // error handling
    // success handling
    // analytics
    // navigation
}

// ✅ COMPOSED
func processUserRegistration() {
    let credentials = validateInput()
    let response = try await registerUser(credentials)
    trackRegistrationSuccess()
    navigateToHome()
}
```

### Single Responsibility
Each function does ONE thing:

```swift
// ❌ Multiple responsibilities
func saveAndUploadNote() {
    // Saves locally
    // Uploads remotely
    // Updates UI
}

// ✅ Single responsibility
func saveNote() { }
func uploadNote() { }
func updateNotesList() { }
```

### Parameters
- **Maximum 3 parameters** (ideal)
- **Use 4-5 only when necessary**
- **6+ parameters**: Create a parameter object

```swift
// ❌ Too many parameters
func createUser(
    name: String,
    email: String,
    password: String,
    age: Int,
    country: String,
    newsletter: Bool
)

// ✅ Parameter object
struct UserRegistrationData {
    let name: String
    let email: String
    let password: String
    let age: Int
    let country: String
    let subscribeToNewsletter: Bool
}

func createUser(data: UserRegistrationData)
```

### Return Types
- Explicit return types always
- Use `Result` for sync operations that can fail
- Use `async throws` for async operations
- Never return optionals AND throw

```swift
// ✅ Clear error handling
func loadNotes() async throws -> [Note]

// ✅ Result for sync fallible operations
func parseJSON(data: Data) -> Result<User, ParseError>

// ❌ Unclear (optional OR throws?)
func getData() throws -> Data?
```

## Class/Struct Guidelines

### Size Limits
- **Maximum 300 lines** per type
- **Ideal: 100-200 lines**
- Extract protocols, extensions, or helper types

### Single Responsibility
```swift
// ❌ God object
class NotesManager {
    func fetchNotes() { }
    func saveNote() { }
    func deleteNote() { }
    func exportToPDF() { }
    func sendEmail() { }
    func trackAnalytics() { }
}

// ✅ Focused types
class NoteRepository { }
class NoteExporter { }
class EmailComposer { }
class AnalyticsTracker { }
```

### Struct vs Class
```swift
// ✅ Struct for value types (immutable data)
struct Note {
    let id: UUID
    let title: String
    let content: String
}

// ✅ Class for reference types (identity matters)
final class NotesListViewModel: ObservableObject {
    @Published var notes: [Note] = []
}

// Always 'final' unless designed for inheritance
```

## Error Handling

### Typed Errors
```swift
// ✅ Explicit error types
enum NoteError: Error {
    case notFound(id: UUID)
    case invalidContent(reason: String)
    case storageFailure(underlyingError: Error)
}

// ❌ Generic errors
throw NSError(domain: "com.app", code: -1, userInfo: nil)
```

### Error Mapping at Boundaries
```swift
// Map framework errors to domain errors at the boundary
func fetchNotes() async throws -> [Note] {
    do {
        return try await coreDataStack.fetchNotes()
    } catch let coreDataError as NSError {
        throw NoteError.storageFailure(underlyingError: coreDataError)
    }
}
```

### Handle Errors, Don't Silence
```swift
// ❌ Silencing errors
try? dangerousOperation()

// ✅ Handle or propagate
do {
    try dangerousOperation()
} catch {
    logger.error("Operation failed: \(error)")
    throw NoteError.operationFailed(underlying: error)
}
```

## Optionals

### Force Unwrap Policy
```swift
// ❌ NEVER in production code
let note = notes.first!

// ✅ Guard or if-let
guard let note = notes.first else {
    return
}

// ⚠️ Acceptable ONLY when provably impossible to be nil
// AND in test code or initialization
let bundle = Bundle(for: type(of: self))! // rare exception
```

### Optional Chaining
```swift
// ✅ Use optional chaining
user?.profile?.avatar?.url

// ✅ Provide defaults
let username = user?.name ?? "Guest"

// ✅ Guard early
guard let user = currentUser else {
    return
}
// Now work with non-optional user
```

## Comments

### When to Comment
```swift
// ✅ Why, not what
// Retry with exponential backoff to handle rate limiting
func retryWithBackoff() { }

// ✅ Non-obvious decisions
// Using O(n²) algorithm because dataset is always < 10 items
// and code clarity matters more than micro-optimization

// ✅ Workarounds
// WORKAROUND: iOS 17.2 bug - UICollectionView crashes on empty updates
// See: rdar://FB12345678
```

### When NOT to Comment
```swift
// ❌ Obvious statements
// Set the title
title = "Notes"

// ❌ Commented-out code
// oldFunction()
// let unused = 42

// ❌ Noisy comments
////////////////////////////////////////
//     SECTION: USER FUNCTIONS       //
////////////////////////////////////////
```

### Self-Documenting Code
```swift
// ❌ Needs comments
func p(u: User, t: Int) -> Bool {
    return u.a > t
}

// ✅ Self-documenting
func isUserActive(user: User, thresholdDays: Int) -> Bool {
    return user.daysSinceLastActivity < thresholdDays
}
```

## Code Organization

### File Structure
```swift
// 1. Imports
import UIKit
import Combine

// 2. Type definition
final class NotesListViewController: UIViewController {

    // 3. Properties (grouped)
    // MARK: - UI Components
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()

    // MARK: - Dependencies
    private let viewModel: NotesListViewModel
    private let coordinator: NotesCoordinator

    // MARK: - State
    private var cancellables = Set<AnyCancellable>()

    // 4. Initialization
    // MARK: - Initialization
    init(viewModel: NotesListViewModel, coordinator: NotesCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    // 5. Lifecycle
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }

    // 6. Setup methods
    // MARK: - Setup
    private func setupUI() { }
    private func bindViewModel() { }

    // 7. Actions
    // MARK: - Actions
    @objc private func refreshTriggered() { }

    // 8. Helper methods
    // MARK: - Helpers
    private func configureCell() { }
}

// 9. Extensions (conformances)
// MARK: - UITableViewDataSource
extension NotesListViewController: UITableViewDataSource {
    // ...
}
```

### Extension Organization
```swift
// Group by conformance, not by function type
// ✅ GOOD
extension NotesListViewController: UITableViewDataSource {
    func tableView(/* ... */) { }
    func numberOfSections(/* ... */) { }
}

// ❌ BAD
extension NotesListViewController {
    func allTheTableViewMethods() { }
    func andOtherStuffToo() { }
}
```

## Access Control

### Default to Private
```swift
// Start private, increase visibility only when needed
private let internalHelper: String
fileprivate let sharedInFile: Int
internal let moduleDefault: Bool  // default, explicit not needed
public let exposedAPI: Data

// Prefer 'private' unless you have a reason
```

### Protocol-First Public API
```swift
// Public interfaces should be protocols
public protocol NoteRepository {
    func fetchAll() async throws -> [Note]
}

// Concrete implementations stay internal/private
final class DefaultNoteRepository: NoteRepository {
    // internal by default
}
```

## Performance Considerations

### Lazy Evaluation
```swift
// ✅ Lazy for expensive computed properties
private lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()
```

### Avoid Premature Optimization
```swift
// ❌ Micro-optimization that hurts readability
let s = d.reduce(0) { $0 + $1.c }

// ✅ Clear code (optimize only if profiled)
let totalCount = items.reduce(0) { sum, item in
    return sum + item.count
}
```

### Profile Before Optimizing
```swift
// Document performance decisions
// PERFORMANCE: Using Set for O(1) lookup instead of Array.contains
// Profiled with 10k items: 0.01ms vs 150ms
private let cachedIDs: Set<UUID>
```

## SwiftLint Rules (Enforced)

```yaml
# .swiftlint.yml (key rules)

line_length: 120
file_length:
  warning: 500
  error: 1000

function_body_length:
  warning: 50
  error: 100

type_body_length:
  warning: 300
  error: 500

cyclomatic_complexity:
  warning: 10
  error: 20

force_unwrapping: error
force_cast: error
implicitly_unwrapped_optional: warning
```

## Complexity Metrics

### Cyclomatic Complexity
- **Maximum: 10** (per function)
- If higher, extract functions

```swift
// ❌ High complexity (CC = 12)
func validate(user: User) -> Bool {
    if user.name.isEmpty { return false }
    if user.email.isEmpty { return false }
    if !user.email.contains("@") { return false }
    if user.age < 0 { return false }
    if user.age > 150 { return false }
    if user.country.isEmpty { return false }
    // ... more conditions
}

// ✅ Lower complexity (CC = 4)
func validate(user: User) -> Bool {
    return validateName(user.name)
        && validateEmail(user.email)
        && validateAge(user.age)
        && validateCountry(user.country)
}
```

## Code Review Checklist

Before committing, verify:

### Basics
- [ ] Zero compiler warnings
- [ ] Zero SwiftLint warnings (strict mode)
- [ ] All tests pass
- [ ] No commented-out code
- [ ] No debug print statements

### Naming
- [ ] Types are PascalCase
- [ ] Functions are camelCase and verb-based
- [ ] Variables are descriptive, not abbreviated
- [ ] Booleans use is/has/can/should

### Structure
- [ ] Functions under 50 lines
- [ ] Classes under 300 lines
- [ ] Cyclomatic complexity under 10
- [ ] Max 3 parameters (or parameter object)

### Architecture
- [ ] Dependencies injected (not singletons)
- [ ] Proper layer separation
- [ ] Protocols for boundaries
- [ ] No business logic in UI

### Error Handling
- [ ] Typed errors
- [ ] No silenced errors (try?)
- [ ] Errors mapped at boundaries
- [ ] No force unwraps in production

### Testing
- [ ] Public API tested
- [ ] Edge cases covered
- [ ] Error paths tested
- [ ] No flaky tests

### Documentation
- [ ] Complex logic explained
- [ ] Tradeoffs documented
- [ ] No obvious comments
- [ ] README updated if needed

## Anti-Patterns (NEVER DO THIS)

### Magic Numbers
```swift
// ❌
if items.count > 5 {

// ✅
let maximumVisibleItems = 5
if items.count > maximumVisibleItems {
```

### Boolean Flags
```swift
// ❌
func fetch(notes: Bool) {
    if notes { /* ... */ } else { /* ... */ }
}

// ✅
enum DataType { case notes, tasks }
func fetch(type: DataType) {
    switch type { /* ... */ }
}
```

### Stringly-Typed
```swift
// ❌
func load(type: String) {
    if type == "note" { }
}

// ✅
enum ContentType { case note, task }
func load(type: ContentType) {
    switch type { }
}
```

### God Objects
```swift
// ❌
class AppManager {
    func doEverything() { }
}

// ✅
class NotesManager { }
class AuthManager { }
class SettingsManager { }
```

## Summary Checklist

Every file you write must:
- ✅ Compile without warnings
- ✅ Pass SwiftLint strict
- ✅ Be under size limits
- ✅ Have clear names
- ✅ Handle errors properly
- ✅ Have tests
- ✅ Follow architecture
- ✅ Be review-ready

**This is the standard. No exceptions.**
