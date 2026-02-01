# Quick Start: Adding a New Feature

This guide walks you through adding a new feature to Shell, following Clean Architecture principles and established patterns.

## Table of Contents

1. [Overview](#overview)
2. [Step-by-Step Checklist](#step-by-step-checklist)
3. [Concrete Example: Notes Feature](#concrete-example-notes-feature)
4. [Testing Your Feature](#testing-your-feature)
5. [Common Patterns](#common-patterns)

---

## Overview

Adding a feature to Shell follows this flow:

```
1. Domain Models (Entities) →
2. Repository Protocol (Contract) →
3. Use Cases (Business Logic) →
4. Repository Implementation (Infrastructure) →
5. ViewModel (Presentation Logic) →
6. View (UIKit or SwiftUI) →
7. Coordinator (Navigation) →
8. Dependency Injection →
9. Tests
```

**Key Principle**: Work from **inside out** (Domain → Infrastructure → Presentation)

---

## Step-by-Step Checklist

### ✅ Step 1: Create Domain Models

**Location**: `Features/{FeatureName}/Domain/Entities/`

Create your entity (business object).

```swift
// Features/Notes/Domain/Entities/Note.swift
import Foundation

struct Note: Identifiable, Sendable {
    let id: UUID
    var title: String
    var content: String
    var createdAt: Date
    var updatedAt: Date
}
```

**Requirements**:
- Conform to `Identifiable` (for SwiftUI lists)
- Conform to `Sendable` (for Swift 6 concurrency)
- Use immutable `let` for identity fields
- Use mutable `var` for editable fields

---

### ✅ Step 2: Define Repository Protocol

**Location**: `Features/{FeatureName}/Domain/Contracts/`

Define the data access contract.

```swift
// Features/Notes/Domain/Contracts/NotesRepositoryProtocol.swift
import Foundation

protocol NotesRepositoryProtocol: Actor {
    func fetchAll() async throws -> [Note]
    func fetch(id: UUID) async throws -> Note?
    func create(_ note: Note) async throws
    func update(_ note: Note) async throws
    func delete(id: UUID) async throws
}
```

**Requirements**:
- Inherit from `Actor` (for thread-safe async operations)
- Return domain entities, not DTOs
- Use `async throws` for operations that can fail

---

### ✅ Step 3: Create Domain Errors

**Location**: `Features/{FeatureName}/Domain/Errors/`

Define validation and business rule errors.

```swift
// Features/Notes/Domain/Errors/NoteValidationError.swift
import Foundation

enum NoteValidationError: Error, LocalizedError {
    case titleEmpty
    case titleTooLong
    case contentTooLong

    var errorDescription: String? {
        switch self {
        case .titleEmpty:
            return "Title cannot be empty"
        case .titleTooLong:
            return "Title must be 100 characters or less"
        case .contentTooLong:
            return "Content must be 10,000 characters or less"
        }
    }
}

enum NoteRepositoryError: Error, LocalizedError {
    case notFound
    case duplicateID

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Note not found"
        case .duplicateID:
            return "Note with this ID already exists"
        }
    }
}
```

---

### ✅ Step 4: Create Use Cases

**Location**: `Features/{FeatureName}/Domain/UseCases/`

Implement business logic operations.

```swift
// Features/Notes/Domain/UseCases/CreateNoteUseCase.swift
import Foundation

actor CreateNoteUseCase {
    private let repository: NotesRepositoryProtocol

    init(repository: NotesRepositoryProtocol) {
        self.repository = repository
    }

    func execute(title: String, content: String) async throws -> Note {
        // Validate business rules
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else {
            throw NoteValidationError.titleEmpty
        }

        guard trimmedTitle.count <= 100 else {
            throw NoteValidationError.titleTooLong
        }

        guard content.count <= 10_000 else {
            throw NoteValidationError.contentTooLong
        }

        // Create entity
        let note = Note(
            id: UUID(),
            title: trimmedTitle,
            content: content,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Persist
        try await repository.create(note)

        return note
    }
}
```

**Repeat for other operations**:
- `FetchNotesUseCase.swift` - Fetch all notes
- `UpdateNoteUseCase.swift` - Update existing note
- `DeleteNoteUseCase.swift` - Delete note

---

### ✅ Step 5: Implement Repository

**Location**: `Features/{FeatureName}/Infrastructure/Repositories/`

Create the concrete repository implementation.

```swift
// Features/Notes/Infrastructure/Repositories/InMemoryNotesRepository.swift
import Foundation

actor InMemoryNotesRepository: NotesRepositoryProtocol {
    private var notes: [Note] = []

    func fetchAll() async throws -> [Note] {
        return notes.sorted { $0.createdAt > $1.createdAt }
    }

    func fetch(id: UUID) async throws -> Note? {
        return notes.first { $0.id == id }
    }

    func create(_ note: Note) async throws {
        guard !notes.contains(where: { $0.id == note.id }) else {
            throw NoteRepositoryError.duplicateID
        }
        notes.append(note)
    }

    func update(_ note: Note) async throws {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else {
            throw NoteRepositoryError.notFound
        }
        notes[index] = note
    }

    func delete(id: UUID) async throws {
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            throw NoteRepositoryError.notFound
        }
        notes.remove(at: index)
    }
}
```

**Future**: Add `HTTPNotesRepository` for API integration.

---

### ✅ Step 6: Create ViewModel

**Location**: `Features/{FeatureName}/Presentation/{ScreenName}/`

Create presentation logic and state management.

```swift
// Features/Notes/Presentation/List/NotesListViewModel.swift
import Foundation
import Combine

@MainActor
final class NotesListViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var notes: [Note] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies
    private let fetchNotesUseCase: FetchNotesUseCase
    private let deleteNoteUseCase: DeleteNoteUseCase

    weak var coordinator: NotesListViewModelCoordinator?

    // MARK: - Initialization
    init(
        fetchNotesUseCase: FetchNotesUseCase,
        deleteNoteUseCase: DeleteNoteUseCase
    ) {
        self.fetchNotesUseCase = fetchNotesUseCase
        self.deleteNoteUseCase = deleteNoteUseCase
    }

    // MARK: - Actions
    func loadNotes() async {
        isLoading = true
        errorMessage = nil

        do {
            notes = try await fetchNotesUseCase.execute()
        } catch {
            errorMessage = "Failed to load notes"
        }

        isLoading = false
    }

    func deleteNote(id: UUID) async {
        do {
            try await deleteNoteUseCase.execute(id: id)
            notes.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete note"
        }
    }

    func addNoteTapped() {
        coordinator?.showNoteEditor(note: nil)
    }

    func noteTapped(_ note: Note) {
        coordinator?.showNoteDetail(note: note)
    }
}

// MARK: - Coordinator Protocol
protocol NotesListViewModelCoordinator: AnyObject {
    func showNoteEditor(note: Note?)
    func showNoteDetail(note: Note)
}
```

---

### ✅ Step 7: Create View (UIKit or SwiftUI)

**Option A: UIKit ViewController**

**Location**: `Features/{FeatureName}/Presentation/{ScreenName}/`

```swift
// Features/Notes/Presentation/List/NotesListViewController.swift
import UIKit
import Combine

final class NotesListViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: NotesListViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "NoteCell")
        return table
    }()

    // MARK: - Initialization
    init(viewModel: NotesListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()

        Task {
            await viewModel.loadNotes()
        }
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Notes"
        view.backgroundColor = .systemBackground

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
    }

    private func bindViewModel() {
        viewModel.$notes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
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

    // MARK: - Actions
    @objc private func addTapped() {
        viewModel.addNoteTapped()
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension NotesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.notes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath)
        let note = viewModel.notes[indexPath.row]
        cell.textLabel?.text = note.title
        return cell
    }
}

// MARK: - UITableViewDelegate
extension NotesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let note = viewModel.notes[indexPath.row]
        viewModel.noteTapped(note)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let note = viewModel.notes[indexPath.row]
            Task {
                await viewModel.deleteNote(id: note.id)
            }
        }
    }
}
```

**Option B: SwiftUI View**

```swift
// Features/Notes/Presentation/List/NotesListView.swift
import SwiftUI

struct NotesListView: View {
    @ObservedObject var viewModel: NotesListViewModel

    var body: some View {
        List {
            ForEach(viewModel.notes) { note in
                Button {
                    viewModel.noteTapped(note)
                } label: {
                    VStack(alignment: .leading) {
                        Text(note.title)
                            .font(.headline)
                        Text(note.content)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let note = viewModel.notes[index]
                    Task {
                        await viewModel.deleteNote(id: note.id)
                    }
                }
            }
        }
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.addNoteTapped()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadNotes()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                // Error handling
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}
```

---

### ✅ Step 8: Create Coordinator

**Location**: `App/Coordinators/`

```swift
// App/Coordinators/NotesCoordinator.swift
import UIKit

final class NotesCoordinator: Coordinator {
    let navigationController: UINavigationController
    private let dependencies: AppDependencies

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        showNotesList()
    }

    func showNotesList() {
        let viewModel = NotesListViewModel(
            fetchNotesUseCase: dependencies.fetchNotesUseCase,
            deleteNoteUseCase: dependencies.deleteNotesUseCase
        )
        viewModel.coordinator = self

        let viewController = NotesListViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showNoteEditor(note: Note?) {
        let viewModel = NoteEditorViewModel(
            note: note,
            createNoteUseCase: dependencies.createNoteUseCase,
            updateNoteUseCase: dependencies.updateNoteUseCase
        )

        let viewController = NoteEditorViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func showNoteDetail(note: Note) {
        let viewModel = NoteDetailViewModel(note: note)
        let viewController = NoteDetailViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}

// MARK: - NotesListViewModelCoordinator
extension NotesCoordinator: NotesListViewModelCoordinator {}
```

---

### ✅ Step 9: Update Dependency Injection

**Location**: `Core/DI/AppDependencyContainer.swift`

Add your new dependencies to the container.

```swift
@MainActor
final class AppDependencyContainer {
    // MARK: - Repositories
    let notesRepository: InMemoryNotesRepository

    // MARK: - Use Cases
    let fetchNotesUseCase: FetchNotesUseCase
    let createNoteUseCase: CreateNoteUseCase
    let updateNoteUseCase: UpdateNoteUseCase
    let deleteNotesUseCase: DeleteNoteUseCase

    init() {
        // Create repository
        notesRepository = InMemoryNotesRepository()

        // Create use cases
        fetchNotesUseCase = FetchNotesUseCase(repository: notesRepository)
        createNoteUseCase = CreateNoteUseCase(repository: notesRepository)
        updateNoteUseCase = UpdateNoteUseCase(repository: notesRepository)
        deleteNotesUseCase = DeleteNoteUseCase(repository: notesRepository)
    }
}
```

---

### ✅ Step 10: Write Tests

**Location**: `ShellTests/Features/{FeatureName}/`

#### Use Case Tests

```swift
// ShellTests/Features/Notes/Domain/UseCases/CreateNoteUseCaseTests.swift
import XCTest
@testable import Shell

final class CreateNoteUseCaseTests: XCTestCase {
    var repository: InMemoryNotesRepository!
    var useCase: CreateNoteUseCase!

    override func setUp() async throws {
        repository = InMemoryNotesRepository()
        useCase = CreateNoteUseCase(repository: repository)
    }

    func testCreateNoteSuccess() async throws {
        // When
        let note = try await useCase.execute(title: "Meeting Notes", content: "Discussed project timeline")

        // Then
        XCTAssertEqual(note.title, "Meeting Notes")
        XCTAssertEqual(note.content, "Discussed project timeline")

        let allNotes = try await repository.fetchAll()
        XCTAssertEqual(allNotes.count, 1)
    }

    func testCreateNoteWithEmptyTitleThrowsError() async throws {
        // When/Then
        do {
            _ = try await useCase.execute(title: "", content: "Some content")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? NoteValidationError, .titleEmpty)
        }
    }

    func testCreateNoteTrimsTitleWhitespace() async throws {
        // When
        let note = try await useCase.execute(title: "  Spaced  ", content: "Content")

        // Then
        XCTAssertEqual(note.title, "Spaced")
    }
}
```

#### Repository Tests

```swift
// ShellTests/Features/Notes/Infrastructure/Repositories/InMemoryNotesRepositoryTests.swift
import XCTest
@testable import Shell

final class InMemoryNotesRepositoryTests: XCTestCase {
    func testFetchAllReturnsEmptyArrayInitially() async throws {
        let repository = InMemoryNotesRepository()
        let notes = try await repository.fetchAll()
        XCTAssertTrue(notes.isEmpty)
    }

    func testCreateAndFetchNote() async throws {
        let repository = InMemoryNotesRepository()
        let note = Note(id: UUID(), title: "Test", content: "Content", createdAt: Date(), updatedAt: Date())

        try await repository.create(note)
        let notes = try await repository.fetchAll()

        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes.first?.title, "Test")
    }

    func testDeleteNote() async throws {
        let repository = InMemoryNotesRepository()
        let note = Note(id: UUID(), title: "Test", content: "Content", createdAt: Date(), updatedAt: Date())

        try await repository.create(note)
        try await repository.delete(id: note.id)

        let notes = try await repository.fetchAll()
        XCTAssertTrue(notes.isEmpty)
    }
}
```

#### ViewModel Tests

```swift
// ShellTests/Features/Notes/Presentation/List/NotesListViewModelTests.swift
import XCTest
@testable import Shell

@MainActor
final class NotesListViewModelTests: XCTestCase {
    func testLoadNotesSuccess() async {
        // Given
        let repository = InMemoryNotesRepository()
        let note = Note(id: UUID(), title: "Test", content: "Content", createdAt: Date(), updatedAt: Date())
        try! await repository.create(note)

        let fetchUseCase = FetchNotesUseCase(repository: repository)
        let deleteUseCase = DeleteNoteUseCase(repository: repository)
        let viewModel = NotesListViewModel(fetchNotesUseCase: fetchUseCase, deleteNoteUseCase: deleteUseCase)

        // When
        await viewModel.loadNotes()

        // Then
        XCTAssertEqual(viewModel.notes.count, 1)
        XCTAssertEqual(viewModel.notes.first?.title, "Test")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteNoteSuccess() async {
        // Given
        let repository = InMemoryNotesRepository()
        let note = Note(id: UUID(), title: "Test", content: "Content", createdAt: Date(), updatedAt: Date())
        try! await repository.create(note)

        let fetchUseCase = FetchNotesUseCase(repository: repository)
        let deleteUseCase = DeleteNoteUseCase(repository: repository)
        let viewModel = NotesListViewModel(fetchNotesUseCase: fetchUseCase, deleteNoteUseCase: deleteUseCase)

        await viewModel.loadNotes()
        XCTAssertEqual(viewModel.notes.count, 1)

        // When
        await viewModel.deleteNote(id: note.id)

        // Then
        XCTAssertEqual(viewModel.notes.count, 0)
        XCTAssertNil(viewModel.errorMessage)
    }
}
```

---

## Concrete Example: Notes Feature

Here's the complete file structure for a hypothetical **Notes** feature:

```
Features/Notes/
├── Domain/
│   ├── Contracts/
│   │   └── NotesRepositoryProtocol.swift
│   ├── Entities/
│   │   └── Note.swift
│   ├── Errors/
│   │   ├── NoteValidationError.swift
│   │   └── NoteRepositoryError.swift
│   └── UseCases/
│       ├── FetchNotesUseCase.swift
│       ├── CreateNoteUseCase.swift
│       ├── UpdateNoteUseCase.swift
│       └── DeleteNoteUseCase.swift
├── Infrastructure/
│   └── Repositories/
│       └── InMemoryNotesRepository.swift
└── Presentation/
    ├── List/
    │   ├── NotesListViewController.swift (or NotesListView.swift for SwiftUI)
    │   └── NotesListViewModel.swift
    ├── Detail/
    │   ├── NoteDetailViewController.swift
    │   └── NoteDetailViewModel.swift
    └── Editor/
        ├── NoteEditorViewController.swift
        └── NoteEditorViewModel.swift

App/Coordinators/
└── NotesCoordinator.swift

ShellTests/Features/Notes/
├── Domain/
│   ├── Entities/
│   │   └── NoteTests.swift
│   └── UseCases/
│       ├── CreateNoteUseCaseTests.swift
│       ├── FetchNotesUseCaseTests.swift
│       └── DeleteNoteUseCaseTests.swift
├── Infrastructure/
│   └── Repositories/
│       └── InMemoryNotesRepositoryTests.swift
└── Presentation/
    ├── List/
    │   └── NotesListViewModelTests.swift
    └── Editor/
        └── NoteEditorViewModelTests.swift
```

---

## Testing Your Feature

### Run All Tests

```bash
xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Run Specific Test Suite

```bash
xcodebuild test -scheme Shell -only-testing:ShellTests/NotesListViewModelTests
```

### In Xcode

1. Press `⌘U` to run all tests
2. Click the diamond icon next to a test to run individual tests
3. View test results in the Test Navigator (⌘6)

---

## Common Patterns

### Pattern 1: Validation in Use Cases

```swift
actor CreateNoteUseCase {
    func execute(title: String, content: String) async throws -> Note {
        // Validate BEFORE creating entity
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NoteValidationError.titleEmpty
        }

        // Create entity AFTER validation passes
        let note = Note(...)
        try await repository.create(note)
        return note
    }
}
```

### Pattern 2: Error Handling in ViewModel

```swift
@MainActor
final class NotesListViewModel: ObservableObject {
    @Published private(set) var errorMessage: String?

    func loadNotes() async {
        errorMessage = nil // Clear previous errors

        do {
            notes = try await fetchNotesUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

### Pattern 3: Coordinator Navigation

```swift
// ViewModel requests navigation via protocol
protocol NotesListViewModelCoordinator: AnyObject {
    func showNoteEditor(note: Note?)
}

@MainActor
final class NotesListViewModel: ObservableObject {
    weak var coordinator: NotesListViewModelCoordinator?

    func addNoteTapped() {
        coordinator?.showNoteEditor(note: nil)
    }
}

// Coordinator implements protocol
extension NotesCoordinator: NotesListViewModelCoordinator {
    func showNoteEditor(note: Note?) {
        let viewModel = NoteEditorViewModel(...)
        let viewController = NoteEditorViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
```

### Pattern 4: Combine Bindings

```swift
// ViewModel publishes state
@Published private(set) var notes: [Note] = []

// ViewController observes state
viewModel.$notes
    .receive(on: DispatchQueue.main)
    .sink { [weak self] notes in
        self?.updateUI(with: notes)
    }
    .store(in: &cancellables)
```

---

## Summary

To add a new feature:

1. ✅ Create domain models (`Entities/`)
2. ✅ Define repository protocol (`Contracts/`)
3. ✅ Create domain errors (`Errors/`)
4. ✅ Implement use cases (`UseCases/`)
5. ✅ Implement repository (`Infrastructure/Repositories/`)
6. ✅ Create ViewModel (`Presentation/{ScreenName}/`)
7. ✅ Create View (UIKit or SwiftUI)
8. ✅ Create Coordinator (`App/Coordinators/`)
9. ✅ Update dependency injection (`AppDependencyContainer`)
10. ✅ Write tests (Domain, Infrastructure, Presentation)

**Key Principles**:
- Work **inside out** (Domain → Infrastructure → Presentation)
- Domain has **no dependencies** on frameworks
- ViewModels depend on **Use Cases**, not repositories
- Coordinators handle **all navigation**
- Tests mirror **production structure**

For architecture details, see [ARCHITECTURE.md](../ARCHITECTURE.md).

---

**Shell v1.0.0** - Production-ready iOS starter kit.
