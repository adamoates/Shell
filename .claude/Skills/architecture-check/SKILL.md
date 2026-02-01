---
name: architecture-check
description: Verify code follows Shell's Clean Architecture layer rules (Domain/Data/UI separation, dependency direction, protocol boundaries). Use when reviewing code, after writing new files, or when checking architectural compliance.
allowed-tools: Read, Grep, Glob
---

# Architecture Check

Audit the Shell codebase for Clean Architecture compliance. Read `.claude/Context/architecture.md` for the full rule set.

## Checks to Perform

### 1. Layer Dependency Direction

The rule: `UI -> Domain <- Data`. Domain depends on nothing.

**Scan Domain layer files** (`Shell/Features/*/Domain/**/*.swift` and `Shell/Core/Contracts/**/*.swift`):

- VIOLATION if any file imports `UIKit`, `SwiftUI`, or `CoreData`
- VIOLATION if any file references concrete repository implementations
- ALLOWED imports: `Foundation`, `Combine`

**Scan Presentation layer files** (`Shell/Features/*/Presentation/**/*.swift`):

- VIOLATION if any file imports or references a concrete repository directly
- VIOLATION if any file creates a concrete data source
- ViewModels must depend on use case protocols or repository protocols, never concrete types

**Scan Infrastructure layer files** (`Shell/Features/*/Infrastructure/**/*.swift`, `Shell/Core/Infrastructure/**/*.swift`):

- VIOLATION if any file imports `UIKit` or `SwiftUI`
- Must implement Domain protocols only

### 2. Protocol Boundaries

For each repository in the codebase:
- There MUST be a protocol in `Domain/Contracts/` or `Core/Contracts/`
- The concrete implementation MUST be in `Infrastructure/` or `Data/`
- All consumers (use cases, ViewModels) MUST reference the protocol, not the concrete type

### 3. Constructor Injection

Scan all `init()` methods in ViewModels, UseCases, Coordinators, and Repositories:
- VIOLATION if dependencies are created internally (e.g., `let repo = InMemoryRepository()` inside a ViewModel)
- VIOLATION if using `static let shared` singleton pattern (except Apple framework types like `URLSession.shared`)
- All dependencies must be parameters of `init()`

### 4. Feature Isolation

For each feature in `Shell/Features/`:
- VIOLATION if a feature imports types from another feature directly
- Cross-feature communication must go through coordinators or shared Domain protocols in `Core/Contracts/`

### 5. No Business Logic in UI

Scan ViewControllers (`*ViewController.swift`, `*View.swift`):
- VIOLATION if they contain validation logic
- VIOLATION if they call repository methods directly
- VIOLATION if they contain data transformation logic
- ViewControllers should only: bind to ViewModel, forward user actions, update UI

## Output Format

Report findings as:

```
## Architecture Check Results

### Violations Found: N

1. **[LAYER_VIOLATION]** `Shell/Features/Auth/Domain/SomeFile.swift:12`
   - Domain file imports UIKit
   - Fix: Remove UIKit import, use Foundation types instead

2. **[DI_VIOLATION]** `Shell/Features/Items/Presentation/ListViewModel.swift:25`
   - ViewModel creates concrete repository internally
   - Fix: Inject repository protocol via init()

### Clean: M files checked, no violations
```

If no violations found, confirm the codebase is architecturally clean.
