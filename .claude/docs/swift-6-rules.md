# Swift 6 Concurrency Rules

**Purpose**: Ensure thread-safe code with Swift 6 strict concurrency

---

## Core Patterns

### ViewModels
```swift
@MainActor
final class ItemEditorViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var isLoading = false

    // All UI state must be on MainActor
}
```

### Repositories
```swift
actor HTTPItemsRepository: ItemsRepository {
    private var cache: [UUID: Item] = [:]

    func fetch(id: UUID) async throws -> Item {
        // Actor-isolated, thread-safe
    }
}
```

### Entities
```swift
struct Item: Sendable, Identifiable, Codable {
    let id: UUID
    var name: String

    // Sendable = can safely cross actor boundaries
}
```

---

## Never Use

❌ **Force Unwrap**: `let x = optional!` (use `guard let` or `if let`)
❌ **Force Try**: `try! riskyOperation()` (use proper error handling)
❌ **Force Cast**: `obj as! MyType` (use `as?` with guard)
❌ **Global Mutable State**: `var sharedData = []` (use actors or @MainActor)
❌ **Singletons**: Except Apple APIs (use dependency injection)

---

## Async/Await

✅ **Prefer** async/await over completion handlers:
```swift
// ✅ Good
func fetchData() async throws -> Data {
    try await URLSession.shared.data(from: url).0
}

// ❌ Avoid
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    // Legacy pattern
}
```

---

## Actor Isolation

**MainActor** (UI thread):
- All ViewModels
- All ViewControllers
- Any UI state

**Actor** (background):
- Repositories
- Network clients
- Heavy computation

**Sendable** (cross-actor):
- All domain entities
- DTOs
- Value types only (struct, enum)

---

## Common Mistakes

### ❌ Accessing actor property from nonisolated context
```swift
actor Repository {
    var items: [Item] = []
}

let repo = Repository()
print(repo.items) // ❌ Error: actor-isolated property
```

### ✅ Use await
```swift
let items = await repo.items // ✅ Correct
```

### ❌ Missing @MainActor on ViewModel
```swift
class ViewModel: ObservableObject { // ❌ Warning: Main actor required
    @Published var text = ""
}
```

### ✅ Add @MainActor
```swift
@MainActor // ✅ Correct
class ViewModel: ObservableObject {
    @Published var text = ""
}
```

---

## Testing with Actors

```swift
@MainActor
final class ViewModelTests: XCTestCase {
    func testViewModel() async throws {
        let viewModel = ViewModel() // On MainActor

        // Access actor properties with await
        let count = await repository.itemCount
        XCTAssertEqual(count, 0)
    }
}
```

---

**Key Principle**: If it touches UI → @MainActor. If it's shared state → actor. If it crosses boundaries → Sendable.
