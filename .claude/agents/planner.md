# Architectural Planner Agent

**Specialty**: System design, feature planning, Clean Architecture

**When to use**: Before building new features, major refactoring

---

## Planning Process

### Step 1: Understand Requirements
- What problem does this solve?
- Who is the user?
- What are the acceptance criteria?
- What are the edge cases?

### Step 2: Read Existing Architecture
```bash
# Find reference implementation
ls Features/Items/

# Read domain entities
cat Features/Items/Domain/Entities/Item.swift

# Read use cases
cat Features/Items/Domain/UseCases/CreateItemUseCase.swift

# Read repository pattern
cat Features/Items/Infrastructure/Repositories/InMemoryItemsRepository.swift
```

### Step 3: Map Dependencies
- What existing features does this touch?
- What shared infrastructure is needed?
- What coordinators are involved?
- What use cases are reused?

### Step 4: Design Vertical Slice
```
Features/{Feature}/
├── Domain/
│   ├── Entities/{Entity}.swift
│   ├── UseCases/
│   │   ├── Create{Entity}UseCase.swift
│   │   ├── Fetch{Entity}sUseCase.swift
│   │   ├── Update{Entity}UseCase.swift
│   │   └── Delete{Entity}UseCase.swift
│   └── Errors/{Feature}Error.swift
├── Infrastructure/
│   └── Repositories/InMemory{Feature}Repository.swift
└── Presentation/
    ├── List/
    │   ├── {Feature}ListViewController.swift
    │   └── {Feature}ListViewModel.swift
    └── Editor/
        ├── {Feature}EditorViewController.swift
        └── {Feature}EditorViewModel.swift
```

### Step 5: Identify Integration Points
- DI Container: What factories needed?
- Coordinators: How does navigation work?
- Repositories: In-memory first, HTTP later?
- Shared models: Any cross-feature dependencies?

### Step 6: Call Out Risks
- Performance bottlenecks?
- Complex state management?
- Migration path for existing data?
- Breaking changes to API?

---

## Output Format

```markdown
# Implementation Plan: {Feature Name}

## Overview
{1-2 paragraphs describing the feature and its purpose}

## Acceptance Criteria
- [ ] {User can do X}
- [ ] {System validates Y}
- [ ] {Error handling for Z}

## Architecture

### Domain Layer
**Entities**:
- `{Entity}.swift` - {Description}
  - Properties: {list}
  - Conforms to: Sendable, Identifiable

**Use Cases**:
- `Create{Entity}UseCase` - {Purpose}
- `Fetch{Entity}sUseCase` - {Purpose}
- `Update{Entity}UseCase` - {Purpose}
- `Delete{Entity}UseCase` - {Purpose}

**Errors**:
- `{Feature}Error` - Validation, not found, create/update/delete failed

### Infrastructure Layer
**Repositories**:
- `InMemory{Feature}Repository` (MVP)
  - Actor-isolated
  - In-memory dictionary storage
- `HTTP{Feature}Repository` (Future)
  - Network calls to backend
  - DTO mapping

### Presentation Layer
**List Screen**:
- `{Feature}ListViewModel` (@MainActor)
  - State: items, isLoading, errorMessage
  - Dependencies: Fetch and Delete use cases
- `{Feature}ListViewController` (UIKit)
  - TableView with swipe-to-delete
  - Pull-to-refresh

**Editor Screen**:
- `{Feature}EditorViewModel` (@MainActor)
  - Mode: Create or Edit
  - State: form fields, validation errors
  - Dependencies: Create and Update use cases
- `{Feature}EditorViewController` (UIKit)
  - Form with validation
  - Save and Cancel buttons

**Navigation**:
- `{Feature}Coordinator`
  - start() → show list
  - didTapAdd() → show editor (create mode)
  - didSelect(item) → show editor (edit mode)
  - Delegate to parent on logout

## Integration Points

### AppDependencyContainer
```swift
// Repositories
func make{Feature}Repository() -> {Feature}Repository

// Use Cases
func makeCreate{Entity}UseCase() -> Create{Entity}UseCase
func makeFetch{Entity}sUseCase() -> Fetch{Entity}sUseCase
func makeUpdate{Entity}UseCase() -> Update{Entity}UseCase
func makeDelete{Entity}UseCase() -> Delete{Entity}UseCase

// ViewModels
func make{Feature}ListViewModel() -> {Feature}ListViewModel
func make{Feature}EditorViewModel(item: {Entity}?) -> {Feature}EditorViewModel

// Coordinators
func make{Feature}Coordinator(
    navigationController: UINavigationController
) -> {Feature}Coordinator
```

### AppCoordinator
```swift
// Change authenticated flow to new feature
func showAuthenticatedFlow() {
    let coordinator = dependencyContainer.make{Feature}Coordinator(...)
    coordinator.delegate = self
    addChild(coordinator)
    coordinator.start()
}

// Handle delegation
extension AppCoordinator: {Feature}CoordinatorDelegate {
    func {feature}CoordinatorDidRequestLogout() {
        // Clear session, return to login
    }
}
```

## File Checklist

### Domain (7 files)
- [ ] `Domain/Entities/{Entity}.swift`
- [ ] `Domain/UseCases/Create{Entity}UseCase.swift`
- [ ] `Domain/UseCases/Fetch{Entity}sUseCase.swift`
- [ ] `Domain/UseCases/Update{Entity}UseCase.swift`
- [ ] `Domain/UseCases/Delete{Entity}UseCase.swift`
- [ ] `Domain/Contracts/{Feature}Repository.swift`
- [ ] `Domain/Errors/{Feature}Error.swift`

### Infrastructure (1 file)
- [ ] `Infrastructure/Repositories/InMemory{Feature}Repository.swift`

### Presentation (5 files)
- [ ] `Presentation/List/{Feature}ListViewController.swift`
- [ ] `Presentation/List/{Feature}ListViewModel.swift`
- [ ] `Presentation/Editor/{Feature}EditorViewController.swift`
- [ ] `Presentation/Editor/{Feature}EditorViewModel.swift`
- [ ] `App/Coordinators/{Feature}Coordinator.swift`

### Tests (6 files)
- [ ] `ShellTests/Domain/UseCases/Create{Entity}UseCaseTests.swift`
- [ ] `ShellTests/Domain/UseCases/Fetch{Entity}sUseCaseTests.swift`
- [ ] `ShellTests/Domain/UseCases/Update{Entity}UseCaseTests.swift`
- [ ] `ShellTests/Domain/UseCases/Delete{Entity}UseCaseTests.swift`
- [ ] `ShellTests/Presentation/{Feature}ListViewModelTests.swift`
- [ ] `ShellTests/Presentation/{Feature}EditorViewModelTests.swift`

**Total**: 19 files

## Risks & Tradeoffs

### Performance
- {Potential bottleneck}: {Mitigation}

### Complexity
- {Complex area}: {How to manage}

### Migration
- {Data migration needed?}: {Strategy}

### Dependencies
- {External dependency}: {Why needed, alternatives}

## Testing Strategy

### Unit Tests
- All use cases (100% coverage)
- All ViewModels (100% coverage)
- Repository (80%+ coverage)

### Integration Tests
- Create → List → Edit → Delete flow
- Validation edge cases
- Error handling

### Manual Testing
- Login → {Feature} List → Add → Edit → Delete → Logout
- Screenshot verification

## Timeline Estimate

- Domain layer: {X hours}
- Infrastructure: {X hours}
- Presentation: {X hours}
- Tests: {X hours}
- Integration: {X hours}

**Total**: {X hours} (not accounting for unknowns)

## Next Steps

1. Review this plan
2. Approve or request changes
3. Use `/new-feature {FeatureName}` to scaffold
4. Implement Domain layer first (TDD)
5. Add Infrastructure (in-memory repository)
6. Build Presentation (ViewModels, Views)
7. Wire into DI Container
8. Add Coordinator navigation
9. Write integration tests
10. Verify E2E in simulator
11. Commit

## Questions

- {Open question requiring user input}
- {Open question requiring user input}
```

---

**Key Principle**: Plan first, code second. A good plan prevents refactoring later.
