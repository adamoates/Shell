# Epic 2: Items CRUD - Implementation Guide

## Status: Test-First Foundation Ready ✅

All domain logic, use cases, ViewModels, and comprehensive tests have been created following TDD principles.

---

## What's Been Created

### 1. Domain Layer ✅

**Use Cases:**
- `CreateItemUseCase.swift` - Create new items with validation
- `UpdateItemUseCase.swift` - Update existing items
- `DeleteItemUseCase.swift` - Delete items by ID
- `ItemError` enum - Domain-specific errors

**Contracts:**
- `ItemsRepository.swift` - Repository protocol for items persistence

**Entities:**
- `Item.swift` - Updated to use String ID (UUID) instead of Int

### 2. Infrastructure Layer ✅

**Repository Implementation:**
- `InMemoryItemsRepository.swift` - Actor-based thread-safe in-memory storage
  - Implements full CRUD operations
  - Simulates network delays (realistic async behavior)
  - Pre-populated with 5 sample items

### 3. Presentation Layer ✅

**ViewModel:**
- `ItemEditorViewModel.swift` - Handles both create and edit modes
  - `@Published` properties for reactive UI binding
  - Form validation with user-friendly error messages
  - Loading state management
  - Delegate pattern for coordinator communication

### 4. Tests ✅ (Ready to Run)

**Use Case Tests:**
- `CreateItemUseCaseTests.swift` - 8 comprehensive test cases
- `UpdateItemUseCaseTests.swift` - 9 comprehensive test cases

**ViewModel Tests:**
- `ItemEditorViewModelTests.swift` - 14 comprehensive test cases
  - Create mode tests
  - Edit mode tests
  - Validation tests
  - Error handling tests
  - Loading state tests
  - Delegate communication tests

**Total New Tests: 31 test cases**

---

## What Still Needs Implementation

### 1. Update FetchItemsUseCase to Use Repository Pattern

**Current:** Hardcoded sample data
**Needed:** Use ItemsRepository

```swift
// File: Shell/Features/Items/Domain/UseCases/FetchItemsUseCase.swift

protocol FetchItemsUseCase {
    func execute() async throws -> [Item]
}

final class DefaultFetchItemsUseCase: FetchItemsUseCase {
    private let repository: ItemsRepository

    init(repository: ItemsRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Item] {
        return try await repository.fetchAll()
    }
}
```

### 2. Create ItemEditorViewController (Programmatic UI)

**File:** `Shell/Features/Items/Presentation/ItemEditor/ItemEditorViewController.swift`

**Requirements:**
- Programmatic UIKit (no storyboards)
- Three text fields: Title, Subtitle, Description
- Save and Cancel buttons in navigation bar
- Error label (hidden by default)
- Activity indicator during save
- Binds to `ItemEditorViewModel` via Combine

**Pattern to follow:** `LoginViewController.swift` or `ProfileViewController.swift`

**Key components:**
```swift
class ItemEditorViewController: UIViewController {
    private let viewModel: ItemEditorViewModel
    private var cancellables = Set<AnyCancellable>()

    // UI Components
    private lazy var titleTextField: UITextField = { ... }()
    private lazy var subtitleTextField: UITextField = { ... }()
    private lazy var descriptionTextView: UITextView = { ... }()
    private lazy var errorLabel: UILabel = { ... }()
    private lazy var activityIndicator: UIActivityIndicatorView = { ... }()

    init(viewModel: ItemEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    // setupBindings() - Subscribe to ViewModel @Published properties
    // setupUI() - Create programmatic layout
    // setupActions() - Wire up Save/Cancel buttons
}
```

### 3. Update ItemsCoordinator

**File:** `Shell/App/Coordinators/ItemsCoordinator.swift`

**Add methods:**
```swift
@MainActor
private func showCreateItem() {
    let viewModel = ItemEditorViewModel(
        createItem: createItemUseCase,
        updateItem: updateItemUseCase,
        itemToEdit: nil
    )
    viewModel.delegate = self

    let editorVC = ItemEditorViewController(viewModel: viewModel)
    let navController = UINavigationController(rootViewController: editorVC)
    navigationController.present(navController, animated: true)
}

@MainActor
private func showEditItem(_ item: Item) {
    let viewModel = ItemEditorViewModel(
        createItem: createItemUseCase,
        updateItem: updateItemUseCase,
        itemToEdit: item
    )
    viewModel.delegate = self

    let editorVC = ItemEditorViewController(viewModel: viewModel)
    let navController = UINavigationController(rootViewController: editorVC)
    navigationController.present(navController, animated: true)
}
```

**Implement delegate:**
```swift
extension ItemsCoordinator: ItemEditorViewModelDelegate {
    func itemEditorViewModel(_ viewModel: ItemEditorViewModel, didSaveItem item: Item) {
        // Dismiss editor
        navigationController.dismiss(animated: true)

        // Refresh list
        // ListViewController should reload items
    }

    func itemEditorViewModelDidCancel(_ viewModel: ItemEditorViewModel) {
        navigationController.dismiss(animated: true)
    }
}
```

### 4. Update ListViewController

**File:** `Shell/ListViewController.swift`

**Add navigation bar button:**
```swift
private func setupUI() {
    // ... existing code ...

    // Add "+" button for creating items
    navigationItem.rightBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .add,
        target: self,
        action: #selector(addItemTapped)
    )
}

@objc private func addItemTapped() {
    delegate?.listViewControllerDidRequestCreateItem(self)
}
```

**Add long-press for edit:**
```swift
func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let item = viewModel.items[indexPath.row]

    // Option 1: Tap to view details (existing)
    delegate?.listViewController(self, didSelectItem: item)

    // Option 2: Add edit button in detail view
    // Or: Add edit action in swipe actions (already has delete/share)
}
```

### 5. Update ListViewControllerDelegate Protocol

**File:** `Shell/App/Coordinators/ItemsCoordinator.swift`

**Add to protocol:**
```swift
protocol ListViewControllerDelegate: AnyObject {
    func listViewControllerDidRequestLogout(_ controller: ListViewController)
    func listViewController(_ controller: ListViewController, didSelectItem item: Item)
    func listViewControllerDidRequestIdentitySetup(_ controller: ListViewController)
    func listViewControllerDidRequestProfile(_ controller: ListViewController)

    // NEW:
    func listViewControllerDidRequestCreateItem(_ controller: ListViewController)
    func listViewController(_ controller: ListViewController, didRequestEditItem item: Item)
}
```

### 6. Update AppDependencyContainer

**File:** `Shell/App/DI/AppDependencyContainer.swift`

**Add use case factories:**
```swift
func makeCreateItemUseCase() -> CreateItemUseCase {
    return DefaultCreateItemUseCase(repository: makeItemsRepository())
}

func makeUpdateItemUseCase() -> UpdateItemUseCase {
    return DefaultUpdateItemUseCase(repository: makeItemsRepository())
}

func makeDeleteItemUseCase() -> DeleteItemUseCase {
    return DefaultDeleteItemUseCase(repository: makeItemsRepository())
}

func makeItemsRepository() -> ItemsRepository {
    return InMemoryItemsRepository()
}
```

### 7. Update ListViewModel

**File:** `Shell/Features/Items/Presentation/List/ListViewModel.swift`

**Add delete method (if not already present):**
```swift
func deleteItem(at index: Int) {
    guard index < items.count else { return }
    let itemToDelete = items[index]

    Task {
        do {
            try await deleteItemUseCase.execute(id: itemToDelete.id)
            // Remove from local array
            await MainActor.run {
                items.remove(at: index)
            }
        } catch {
            // Handle error
        }
    }
}
```

---

## Implementation Order (Recommended)

1. **Update FetchItemsUseCase** (5 min)
   - Use repository instead of hardcoded data
   - Update tests if needed

2. **Update AppDependencyContainer** (10 min)
   - Add use case factories
   - Wire up repository

3. **Create ItemEditorViewController** (2-3 hours)
   - Programmatic UI layout
   - Combine bindings
   - Follow existing patterns

4. **Update ItemsCoordinator** (30 min)
   - Add create/edit methods
   - Implement delegate

5. **Update ListViewController** (30 min)
   - Add "+" button
   - Add delegate method calls

6. **Update ListViewControllerDelegate** (5 min)
   - Add protocol methods

7. **Test Everything** (1 hour)
   - Run all 31 new tests (should pass)
   - Manual QA: Create, Edit, Delete flows
   - Test error states
   - Test validation

---

## Testing Checklist

Once implementation is complete:

### Unit Tests (Automated)
- [ ] All 31 new tests pass
- [ ] Existing 150+ tests still pass
- [ ] No test regressions

### Manual QA
- [ ] Create new item → appears in list
- [ ] Edit existing item → changes reflected
- [ ] Delete item → removed from list
- [ ] Validation errors show correctly
- [ ] Loading states display
- [ ] Cancel dismisses editor
- [ ] Save success dismisses editor and refreshes list

---

## Files Modified Summary

**Created (9 files):**
1. `CreateItemUseCase.swift`
2. `UpdateItemUseCase.swift`
3. `DeleteItemUseCase.swift`
4. `ItemsRepository.swift`
5. `InMemoryItemsRepository.swift`
6. `ItemEditorViewModel.swift`
7. `CreateItemUseCaseTests.swift`
8. `UpdateItemUseCaseTests.swift`
9. `ItemEditorViewModelTests.swift`

**To Be Modified (7 files):**
1. `FetchItemsUseCase.swift` - Use repository
2. `Item.swift` - ✅ Already updated (String ID)
3. `ItemEditorViewController.swift` - Create new
4. `ItemsCoordinator.swift` - Add create/edit methods
5. `ListViewController.swift` - Add "+" button
6. `ListViewModel.swift` - Ensure delete method exists
7. `AppDependencyContainer.swift` - Add use case factories

---

## Estimated Time Remaining

- **ViewController creation:** 2-3 hours
- **Coordinator/DI wiring:** 1 hour
- **Testing & QA:** 1 hour
- **Bug fixes/polish:** 1 hour

**Total: 5-6 hours** (within original 12-16 hour estimate)

---

## Next Steps

**After user confirms ShellTests are running:**

1. Verify all 31 new tests pass
2. Start implementing ItemEditorViewController
3. Wire up coordinator and DI
4. Manual QA
5. Mark Epic 2 complete ✅

**Questions for user:**
- Do you want me to implement ItemEditorViewController now?
- Or do you prefer to implement it yourself using the guide?
- Any design preferences for the editor UI?
