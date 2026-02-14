# New Feature Skill

Scaffold a new feature following Shell's vertical slice architecture (Clean Architecture + MVVM + Repository + Coordinator patterns).

## When to use

When you want to add a new feature (e.g., Notes, Watchlist, Alerts) with consistent folder structure, boilerplate types, and tests following Shell's established patterns.

## Steps

### 1. Gather Requirements

Ask the user for:
- **Feature name** (e.g., "Notes", "Watchlist", "Alerts")
  - Must be PascalCase singular (e.g., "Note" not "Notes")
- **UI implementation** (UIKit, SwiftUI, or both)
- **Primary screens** (e.g., "List", "Detail", "Editor")

### 2. Create Feature Folder Structure

Create folders under `Shell/Features/<FeatureName>/`:

```
Features/<FeatureName>/
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   ├── Contracts/
│   └── Errors/
├── Infrastructure/
│   └── Repositories/
└── Presentation/
    ├── List/          (if needed)
    ├── Detail/        (if needed)
    └── Editor/        (if needed)
```

### 3. Create Test Folder Structure

Create matching test folders under `ShellTests/Features/<FeatureName>/`:

```
ShellTests/Features/<FeatureName>/
├── Domain/
│   ├── Entities/
│   └── UseCases/
├── Infrastructure/
│   └── Repositories/
└── Presentation/
    ├── List/
    ├── Detail/
    └── Editor/
```

### 4. Generate Domain Layer Files

#### Entity (`Domain/Entities/<FeatureName>.swift`)

```swift
//
//  <FeatureName>.swift
//  Shell
//

import Foundation

/// Domain entity for <feature description>
struct <FeatureName>: Identifiable, Sendable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    let createdAt: Date
    let updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
```

#### Repository Protocol (`Domain/Contracts/<FeatureName>RepositoryProtocol.swift`)

```swift
//
//  <FeatureName>RepositoryProtocol.swift
//  Shell
//

import Foundation

/// Repository protocol for <FeatureName> data access
/// Infrastructure layer provides concrete implementations
protocol <FeatureName>RepositoryProtocol: Actor {
    /// Fetch all <featureName>s
    func fetchAll() async throws -> [<FeatureName>]

    /// Fetch a single <featureName> by ID
    func fetch(id: UUID) async throws -> <FeatureName>?

    /// Create a new <featureName>
    func create(_ <featureName>: <FeatureName>) async throws

    /// Update an existing <featureName>
    func update(_ <featureName>: <FeatureName>) async throws

    /// Delete a <featureName> by ID
    func delete(id: UUID) async throws
}
```

#### Domain Errors (`Domain/Errors/<FeatureName>ValidationError.swift`)

```swift
//
//  <FeatureName>ValidationError.swift
//  Shell
//

import Foundation

enum <FeatureName>ValidationError: Error, LocalizedError {
    case nameEmpty
    case nameTooLong
    case descriptionTooLong

    var errorDescription: String? {
        switch self {
        case .nameEmpty:
            return "Name cannot be empty"
        case .nameTooLong:
            return "Name must be 100 characters or less"
        case .descriptionTooLong:
            return "Description must be 1000 characters or less"
        }
    }
}

enum <FeatureName>RepositoryError: Error, LocalizedError {
    case notFound
    case duplicateID

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "<FeatureName> not found"
        case .duplicateID:
            return "<FeatureName> with this ID already exists"
        }
    }
}
```

#### Use Cases (`Domain/UseCases/Fetch<FeatureName>sUseCase.swift`, `Create<FeatureName>UseCase.swift`, etc.)

```swift
//
//  Fetch<FeatureName>sUseCase.swift
//  Shell
//

import Foundation

actor Fetch<FeatureName>sUseCase {
    private let repository: <FeatureName>RepositoryProtocol

    init(repository: <FeatureName>RepositoryProtocol) {
        self.repository = repository
    }

    func execute() async throws -> [<FeatureName>] {
        try await repository.fetchAll()
    }
}
```

```swift
//
//  Create<FeatureName>UseCase.swift
//  Shell
//

import Foundation

actor Create<FeatureName>UseCase {
    private let repository: <FeatureName>RepositoryProtocol

    init(repository: <FeatureName>RepositoryProtocol) {
        self.repository = repository
    }

    func execute(name: String, description: String) async throws -> <FeatureName> {
        // Validate
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw <FeatureName>ValidationError.nameEmpty
        }

        guard trimmedName.count <= 100 else {
            throw <FeatureName>ValidationError.nameTooLong
        }

        // Create entity
        let <featureName> = <FeatureName>(
            name: trimmedName,
            description: description
        )

        // Persist
        try await repository.create(<featureName>)

        return <featureName>
    }
}
```

### 5. Generate Infrastructure Layer Files

#### Repository Implementation (`Infrastructure/Repositories/InMemory<FeatureName>Repository.swift`)

```swift
//
//  InMemory<FeatureName>Repository.swift
//  Shell
//

import Foundation

/// In-memory implementation of <FeatureName>RepositoryProtocol
/// Thread-safe actor-based storage
actor InMemory<FeatureName>Repository: <FeatureName>RepositoryProtocol {
    private var items: [<FeatureName>] = []

    func fetchAll() async throws -> [<FeatureName>] {
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func fetch(id: UUID) async throws -> <FeatureName>? {
        return items.first { $0.id == id }
    }

    func create(_ <featureName>: <FeatureName>) async throws {
        guard !items.contains(where: { $0.id == <featureName>.id }) else {
            throw <FeatureName>RepositoryError.duplicateID
        }
        items.append(<featureName>)
    }

    func update(_ <featureName>: <FeatureName>) async throws {
        guard let index = items.firstIndex(where: { $0.id == <featureName>.id }) else {
            throw <FeatureName>RepositoryError.notFound
        }
        items[index] = <featureName>
    }

    func delete(id: UUID) async throws {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw <FeatureName>RepositoryError.notFound
        }
        items.remove(at: index)
    }
}
```

### 6. Generate Presentation Layer Files (UIKit)

#### ViewModel (`Presentation/List/<FeatureName>ListViewModel.swift`)

```swift
//
//  <FeatureName>ListViewModel.swift
//  Shell
//

import Foundation
import Combine

@MainActor
final class <FeatureName>ListViewModel: ObservableObject {
    // MARK: - Published State
    @Published private(set) var items: [<FeatureName>] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies
    private let fetchUseCase: Fetch<FeatureName>sUseCase
    private let deleteUseCase: Delete<FeatureName>UseCase

    weak var coordinator: <FeatureName>ListViewModelCoordinator?

    // MARK: - Initialization
    init(
        fetchUseCase: Fetch<FeatureName>sUseCase,
        deleteUseCase: Delete<FeatureName>UseCase
    ) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
    }

    // MARK: - Actions
    func loadItems() async {
        isLoading = true
        errorMessage = nil

        do {
            items = try await fetchUseCase.execute()
        } catch {
            errorMessage = "Failed to load items"
        }

        isLoading = false
    }

    func deleteItem(id: UUID) async {
        do {
            try await deleteUseCase.execute(id: id)
            items.removeAll { $0.id == id }
        } catch {
            errorMessage = "Failed to delete item"
        }
    }

    func addTapped() {
        coordinator?.show<FeatureName>Editor(<featureName>: nil)
    }

    func itemTapped(_ <featureName>: <FeatureName>) {
        coordinator?.show<FeatureName>Detail(<featureName>: <featureName>)
    }
}

// MARK: - Coordinator Protocol
protocol <FeatureName>ListViewModelCoordinator: AnyObject {
    func show<FeatureName>Editor(<featureName>: <FeatureName>?)
    func show<FeatureName>Detail(<featureName>: <FeatureName>)
}
```

#### ViewController (`Presentation/List/<FeatureName>ListViewController.swift`)

```swift
//
//  <FeatureName>ListViewController.swift
//  Shell
//

import UIKit
import Combine

final class <FeatureName>ListViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: <FeatureName>ListViewModel
    private var cancellables = Set<AnyCancellable>()

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "<FeatureName>Cell")
        return table
    }()

    // MARK: - Initialization
    init(viewModel: <FeatureName>ListViewModel) {
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
            await viewModel.loadItems()
        }
    }

    // MARK: - Setup
    private func setupUI() {
        title = "<FeatureName>s"
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
        viewModel.$items
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
        viewModel.addTapped()
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension <FeatureName>ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "<FeatureName>Cell", for: indexPath)
        let item = viewModel.items[indexPath.row]

        var config = cell.defaultContentConfiguration()
        config.text = item.name
        config.secondaryText = item.description
        cell.contentConfiguration = config

        return cell
    }
}

// MARK: - UITableViewDelegate
extension <FeatureName>ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = viewModel.items[indexPath.row]
        viewModel.itemTapped(item)
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let item = viewModel.items[indexPath.row]
            Task {
                await viewModel.deleteItem(id: item.id)
            }
        }
    }
}
```

### 7. Generate Presentation Layer Files (SwiftUI)

#### SwiftUI View (`Presentation/List/<FeatureName>ListView.swift`)

```swift
//
//  <FeatureName>ListView.swift
//  Shell
//

import SwiftUI

struct <FeatureName>ListView: View {
    @ObservedObject var viewModel: <FeatureName>ListViewModel

    var body: some View {
        List {
            ForEach(viewModel.items) { item in
                Button {
                    viewModel.itemTapped(item)
                } label: {
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                        Text(item.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let item = viewModel.items[index]
                    Task {
                        await viewModel.deleteItem(id: item.id)
                    }
                }
            }
        }
        .navigationTitle("<FeatureName>s")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.addTapped()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await viewModel.loadItems()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}
```

### 8. Generate Test Files

#### Use Case Tests (`ShellTests/Features/<FeatureName>/Domain/UseCases/Create<FeatureName>UseCaseTests.swift`)

```swift
//
//  Create<FeatureName>UseCaseTests.swift
//  ShellTests
//

import XCTest
@testable import Shell

final class Create<FeatureName>UseCaseTests: XCTestCase {
    var repository: InMemory<FeatureName>Repository!
    var useCase: Create<FeatureName>UseCase!

    override func setUp() async throws {
        repository = InMemory<FeatureName>Repository()
        useCase = Create<FeatureName>UseCase(repository: repository)
    }

    override func tearDown() {
        useCase = nil
        repository = nil
    }

    func testExecute_withValidData_creates<FeatureName>() async throws {
        // When
        let <featureName> = try await useCase.execute(name: "Test", description: "Description")

        // Then
        XCTAssertEqual(<featureName>.name, "Test")
        XCTAssertEqual(<featureName>.description, "Description")

        let all = try await repository.fetchAll()
        XCTAssertEqual(all.count, 1)
    }

    func testExecute_withEmptyName_throwsError() async {
        // When/Then
        do {
            _ = try await useCase.execute(name: "", description: "Description")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? <FeatureName>ValidationError, .nameEmpty)
        }
    }
}
```

#### Repository Tests (`ShellTests/Features/<FeatureName>/Infrastructure/Repositories/InMemory<FeatureName>RepositoryTests.swift`)

```swift
//
//  InMemory<FeatureName>RepositoryTests.swift
//  ShellTests
//

import XCTest
@testable import Shell

final class InMemory<FeatureName>RepositoryTests: XCTestCase {
    func testFetchAll_returnsEmptyArrayInitially() async throws {
        let repository = InMemory<FeatureName>Repository()
        let items = try await repository.fetchAll()
        XCTAssertTrue(items.isEmpty)
    }

    func testCreate_addsItemToRepository() async throws {
        let repository = InMemory<FeatureName>Repository()
        let item = <FeatureName>(name: "Test", description: "Description")

        try await repository.create(item)
        let all = try await repository.fetchAll()

        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "Test")
    }

    func testDelete_removesItemFromRepository() async throws {
        let repository = InMemory<FeatureName>Repository()
        let item = <FeatureName>(name: "Test", description: "Description")

        try await repository.create(item)
        try await repository.delete(id: item.id)

        let all = try await repository.fetchAll()
        XCTAssertTrue(all.isEmpty)
    }
}
```

#### ViewModel Tests (`ShellTests/Features/<FeatureName>/Presentation/List/<FeatureName>ListViewModelTests.swift`)

```swift
//
//  <FeatureName>ListViewModelTests.swift
//  ShellTests
//

import XCTest
@testable import Shell

@MainActor
final class <FeatureName>ListViewModelTests: XCTestCase {
    var repository: InMemory<FeatureName>Repository!
    var fetchUseCase: Fetch<FeatureName>sUseCase!
    var deleteUseCase: Delete<FeatureName>UseCase!
    var viewModel: <FeatureName>ListViewModel!

    override func setUp() async throws {
        repository = InMemory<FeatureName>Repository()
        fetchUseCase = Fetch<FeatureName>sUseCase(repository: repository)
        deleteUseCase = Delete<FeatureName>UseCase(repository: repository)
        viewModel = <FeatureName>ListViewModel(
            fetchUseCase: fetchUseCase,
            deleteUseCase: deleteUseCase
        )
    }

    override func tearDown() {
        viewModel = nil
        deleteUseCase = nil
        fetchUseCase = nil
        repository = nil
    }

    func testLoadItems_success() async {
        // Given
        let item = <FeatureName>(name: "Test", description: "Description")
        try! await repository.create(item)

        // When
        await viewModel.loadItems()

        // Then
        XCTAssertEqual(viewModel.items.count, 1)
        XCTAssertEqual(viewModel.items.first?.name, "Test")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
}
```

### 9. Generate Coordinator

Create `App/Coordinators/<FeatureName>Coordinator.swift`:

```swift
//
//  <FeatureName>Coordinator.swift
//  Shell
//

import UIKit

final class <FeatureName>Coordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    private let dependencies: AppDependencies

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        show<FeatureName>List()
    }

    func show<FeatureName>List() {
        let viewModel = <FeatureName>ListViewModel(
            fetchUseCase: dependencies.fetch<FeatureName>sUseCase,
            deleteUseCase: dependencies.delete<FeatureName>UseCase
        )
        viewModel.coordinator = self

        let viewController = <FeatureName>ListViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }

    func show<FeatureName>Editor(<featureName>: <FeatureName>?) {
        // TODO: Implement editor screen
    }

    func show<FeatureName>Detail(<featureName>: <FeatureName>) {
        // TODO: Implement detail screen
    }
}

// MARK: - <FeatureName>ListViewModelCoordinator
extension <FeatureName>Coordinator: <FeatureName>ListViewModelCoordinator {}
```

### 10. Print Integration Checklist

After scaffolding, print:

```
✅ Feature scaffolded: <FeatureName>

📋 Next steps to complete integration:

1. Wire dependencies in AppDependencyContainer:
   - Add <featureName>Repository property
   - Add fetch<FeatureName>sUseCase, create<FeatureName>UseCase, etc.
   - Add make<FeatureName>Coordinator() factory method

2. Add navigation entry point:
   - Update AppCoordinator or MainTabBarCoordinator
   - Add route case to Route enum (if using type-safe routing)

3. Fill in domain logic:
   - Complete validation in use cases
   - Add business rules specific to <FeatureName>
   - Implement editor and detail ViewModels

4. Write comprehensive tests:
   - Domain validation edge cases
   - Repository thread-safety tests
   - ViewModel state management tests

5. (Optional) Add HTTP repository:
   - Create HTTP<FeatureName>Repository.swift
   - Add backend API endpoints
   - Update AppDependencyContainer toggle

📁 Generated files:
   - Domain: <count> files
   - Infrastructure: <count> files
   - Presentation: <count> files
   - Tests: <count> files
   - Coordinator: 1 file

Run tests: xcodebuild test -scheme Shell -only-testing:ShellTests/<FeatureName>Tests
```

## Notes

- All files follow Shell's Swift 6 strict concurrency (actors, Sendable, @MainActor)
- Repository pattern with protocol in Domain, implementation in Infrastructure
- MVVM with ObservableObject + @Published properties
- Coordinator pattern for navigation
- Vertical slice architecture (feature contains all layers)
- Test structure mirrors main app structure
