# MVVM Enforcer Skill

Audit new or modified code to ensure it follows Shell's MVVM + Clean Architecture guidelines.

## When to use

- Before committing new UI or feature code.
- After a refactor touching controllers, view models, or use cases.
- When reviewing PRs that add presentation logic.

## Scope

Focus on files under:

- `Shell/Features/*/Presentation/`
- `Shell/Features/*/Domain/UseCases/`
- `Shell/Features/*/Domain/Entities/`
- `Shell/Features/*/Infrastructure/Repositories/`
- Matching test files under `ShellTests/Features/*/`

## Rules

### 1. ViewControllers (UIKit)

**Allowed:**

- Wiring UI elements, layout, and styling.
- Observing `ViewModel` state (Combine/KVO) and updating views.
- Forwarding user interactions to the `ViewModel`.

**Forbidden:**

- Direct calls to repositories, Core Data, HTTP clients, or UserDefaults.
- Business logic (validation, branching on domain rules).
- Constructing domain entities directly (beyond simple mapping of UI input).

**Checks:**

- Ensure each `*ViewController` depends on a `*ViewModel` (not use cases or repos).
- Verify `viewDidLoad`/`viewWillAppear` only:
  - Calls `viewModel` methods (e.g., `load()`, `refresh()`).
  - Sets up bindings from `viewModel.$state` to UI.

### 2. SwiftUI Views

**Allowed:**

- Displaying data from `@ObservedObject` / `@StateObject` ViewModel.
- Forwarding user actions to ViewModel methods.
- Local, purely visual state.

**Forbidden:**

- Direct use of repositories, use cases, or HTTP clients.
- Business rules or validation logic (should live in ViewModel / domain).

**Checks:**

- Each SwiftUI view should have a `@StateObject` or `@ObservedObject` ViewModel.
- No `@State` properties that hold domain entities (use ViewModel instead).
- No `.task { }` blocks that call use cases directly—delegate to ViewModel.

### 3. ViewModels

**Allowed:**

- Holding UI-specific state (`@Published` properties).
- Calling use case methods to fetch/mutate data.
- Transforming domain models into display models.
- Validation of user input before passing to use cases.

**Forbidden:**

- Direct database or network calls.
- Instantiating repositories or HTTP clients.
- Complex business logic (that should be in a use case).

**Checks:**

- Must be marked `@MainActor` (Swift 6 concurrency safety).
- Must be `final class` conforming to `ObservableObject`.
- Dependencies injected via initializer (use cases, not repositories).
- All `@Published` properties must be UI state (loading, error, data).

### 4. Use Cases

**Allowed:**

- Defining business operations (Create, Fetch, Update, Delete).
- Calling repository methods.
- Domain validation and business rules.
- Returning domain entities or throwing domain errors.

**Forbidden:**

- UI concerns (no `@Published`, no UI state).
- Direct UIKit/SwiftUI imports.
- Holding mutable state (unless isolated by `actor`).

**Checks:**

- Must be a protocol defining the contract.
- Implementation must be an `actor` (for thread safety).
- Methods must use `async` (no completion handlers).
- Must depend on repository protocols (not concrete implementations).

### 5. Repositories

**Allowed:**

- Data persistence (in-memory, HTTP, Core Data, etc.).
- Mapping between domain entities and storage models.
- Throwing repository-specific errors (network, storage).

**Forbidden:**

- Business logic or validation.
- UI concerns.
- Direct use by ViewControllers or Views.

**Checks:**

- Must be defined as a protocol in `Domain/Contracts/`.
- Implementation must be an `actor` in `Infrastructure/Repositories/`.
- Methods must use `async throws`.
- Must be injected into use cases, not ViewModels.

### 6. Domain Entities

**Allowed:**

- Plain Swift types (struct, enum, class).
- Conformance to `Sendable`, `Codable`, `Equatable`, `Identifiable`.
- Immutable or value semantics preferred.

**Forbidden:**

- UIKit/SwiftUI imports.
- Mutable reference types (unless explicitly designed).
- Business logic (move to use cases).

**Checks:**

- Must conform to `Sendable` (Swift 6 concurrency).
- Should be `struct` unless there's a compelling reason for `class`.
- No computed properties with side effects.

## Audit Workflow

### Step 1: Identify Changed Files

```bash
# Get list of modified files
git diff --name-only HEAD

# Or get staged files
git diff --cached --name-only
```

### Step 2: Run Focused Checks

For each file in scope, apply the relevant rule set from above.

**Example: Auditing a ViewController**

```bash
# Read the file
cat Shell/Features/VideoPlayer/Presentation/VideoPlayerViewController.swift
```

**Check for violations:**

- ❌ Does it import repositories or use cases directly?
- ❌ Does it have `import Foundation` without a ViewModel?
- ❌ Does `viewDidLoad` contain business logic?
- ❌ Are there direct `UserDefaults` or `URLSession` calls?

**Example: Auditing a ViewModel**

```bash
# Read the file
cat Shell/Features/VideoPlayer/Presentation/VideoPlayerViewModel.swift
```

**Check for violations:**

- ❌ Is it missing `@MainActor`?
- ❌ Does it depend on concrete repositories instead of use cases?
- ❌ Does it have `URLSession` or `UserDefaults` imports?
- ❌ Are there non-UI `@Published` properties (domain logic)?

**Example: Auditing a Use Case**

```bash
# Read the file
cat Shell/Features/VideoPlayer/Domain/UseCases/FetchVideoUseCase.swift
```

**Check for violations:**

- ❌ Is the implementation not an `actor`?
- ❌ Does it import UIKit or SwiftUI?
- ❌ Does it have mutable state without actor isolation?
- ❌ Are methods synchronous (missing `async`)?

### Step 3: Report Violations

For each violation found, report:

```
❌ Violation: <Rule Name>
File: <file_path>:<line_number>
Issue: <description>
Fix: <recommendation>
```

**Example Report:**

```
❌ Violation: ViewModel Missing @MainActor
File: Shell/Features/VideoPlayer/Presentation/VideoPlayerViewModel.swift:12
Issue: Class is not marked @MainActor, violating Swift 6 concurrency safety
Fix: Add @MainActor annotation before class declaration

❌ Violation: Business Logic in View
File: Shell/Features/VideoPlayer/Presentation/VideoPlayerViewController.swift:145
Issue: viewWillAppear contains direct UserDefaults access
Fix: Move to ViewModel.refresh() method and bind to $state

✅ Compliant: Use Case Actor Isolation
File: Shell/Features/VideoPlayer/Domain/UseCases/FetchVideoUseCase.swift:8
```

### Step 4: Pass/Fail Summary

```
📊 MVVM Audit Results

Files audited: 8
✅ Compliant: 6
❌ Violations: 2

Next steps:
1. Fix violations listed above
2. Re-run audit: /mvvm-enforcer
3. Run tests: /test-feature VideoPlayer
4. Commit when clean: /commit
```

## Integration with Other Skills

### Before `/commit`

Always run `/mvvm-enforcer` to catch architectural drift before it enters the repository.

### After `/new-feature`

Run `/mvvm-enforcer` on the newly scaffolded files to ensure they follow conventions.

### During PR Review

Use `/mvvm-enforcer` to validate that PR changes don't violate MVVM boundaries.

## Common Violations and Fixes

### Violation: Direct Repository Use in ViewModel

**Bad:**

```swift
final class ItemsListViewModel: ObservableObject {
    private let repository: ItemsRepositoryProtocol  // ❌ Skip use case layer

    func loadItems() async {
        let items = try? await repository.fetchAll()  // ❌ Direct repo call
    }
}
```

**Good:**

```swift
@MainActor
final class ItemsListViewModel: ObservableObject {
    private let fetchItems: FetchItemsUseCase  // ✅ Use case dependency

    func loadItems() async {
        let items = try? await fetchItems.execute()  // ✅ Use case call
    }
}
```

### Violation: Business Logic in View

**Bad:**

```swift
final class ItemsListViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // ❌ Business logic in view
        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            loadItems()
        } else {
            showOnboarding()
        }
    }
}
```

**Good:**

```swift
final class ItemsListViewController: UIViewController {
    private let viewModel: ItemsListViewModel

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBindings()

        // ✅ Delegate to ViewModel
        Task {
            await viewModel.load()
        }
    }
}
```

### Violation: Missing @MainActor

**Bad:**

```swift
final class ProfileViewModel: ObservableObject {  // ❌ No @MainActor
    @Published var profile: UserProfile?

    func load() async {
        // This can cause UI updates from background thread
    }
}
```

**Good:**

```swift
@MainActor  // ✅ Explicit main actor isolation
final class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?

    func load() async {
        // Guaranteed to run on main thread
    }
}
```

### Violation: Non-Actor Use Case

**Bad:**

```swift
protocol FetchItemsUseCase {
    func execute() async throws -> [Item]
}

final class DefaultFetchItemsUseCase: FetchItemsUseCase {  // ❌ Not an actor
    private var cache: [Item] = []  // ❌ Mutable state without isolation

    func execute() async throws -> [Item] {
        return cache
    }
}
```

**Good:**

```swift
protocol FetchItemsUseCase: Actor {  // ✅ Actor protocol
    func execute() async throws -> [Item]
}

actor DefaultFetchItemsUseCase: FetchItemsUseCase {  // ✅ Actor implementation
    private var cache: [Item] = []  // ✅ Actor-isolated state

    func execute() async throws -> [Item] {
        return cache
    }
}
```

## Notes

- This skill enforces **compile-time safety** wherever possible (actors, Sendable, @MainActor).
- Violations are architectural, not stylistic—they can cause crashes or make code untestable.
- Run this audit **before** `/commit` to maintain clean architecture.
- For complex violations, create a separate refactoring task rather than blocking the commit.
- Shell's architecture is "opinionated by default"—these rules are non-negotiable for consistency.
