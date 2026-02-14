# Architecture Patterns

**Clean Architecture + MVVM + Coordinator**

---

## Layer Dependency Rule

```
Domain (Pure Swift)
  ↑
Infrastructure (External Systems)
  ↑
Presentation (UI Layer)
```

**Rule**: Dependencies point inward. Presentation → Infrastructure → Domain.
**Never**: Presentation imports Infrastructure directly (use protocols).

---

## Navigation (Coordinator Pattern)

### Coordinator Protocol
```swift
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    var childCoordinators: [Coordinator] { get set }
    weak var parentCoordinator: Coordinator? { get set }

    func start()
    func finish()
    func childDidFinish(_ child: Coordinator)
}
```

### Example: DogCoordinator
```swift
final class DogCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?
    weak var delegate: DogCoordinatorDelegate?

    private let dependencyContainer: AppDependencyContainer

    func start() {
        Task {
            // Validate session before showing feature
            guard await hasValidSession() else {
                delegate?.dogCoordinatorDidRequestLogout(self)
                return
            }

            await MainActor.run {
                showDogList()
            }
        }
    }

    private func showDogList() {
        let viewModel = dependencyContainer.makeDogListViewModel()
        viewModel.coordinator = self

        let viewController = DogListViewController(viewModel: viewModel)
        navigationController.pushViewController(viewController, animated: true)
    }
}
```

**Benefits**:
- ViewControllers don't know about navigation
- Testable navigation logic
- Coordinator owns flow, ViewController owns UI

---

## Presentation (MVVM Pattern)

### ViewModel
```swift
@MainActor
final class DogListViewModel: ObservableObject {
    // Published state
    @Published var dogs: [Dog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Dependencies
    private let fetchDogsUseCase: FetchDogsUseCase
    private let deleteDogUseCase: DeleteDogUseCase
    weak var coordinator: DogListCoordinatorDelegate?

    // Initialization (constructor injection)
    init(
        fetchDogsUseCase: FetchDogsUseCase,
        deleteDogUseCase: DeleteDogUseCase
    ) {
        self.fetchDogsUseCase = fetchDogsUseCase
        self.deleteDogUseCase = deleteDogUseCase
    }

    // Actions (async)
    func loadDogs() async {
        isLoading = true
        errorMessage = nil

        do {
            dogs = try await fetchDogsUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // Coordinator delegation
    func addDogTapped() {
        coordinator?.didRequestAddDog()
    }
}
```

### ViewController
```swift
final class DogListViewController: UIViewController {
    private let viewModel: DogListViewModel
    private var cancellables = Set<AnyCancellable>()

    // Constructor injection
    init(viewModel: DogListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        loadDogs()
    }

    private func bindViewModel() {
        viewModel.$dogs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                isLoading ? self?.activityIndicator.startAnimating()
                          : self?.activityIndicator.stopAnimating()
            }
            .store(in: &cancellables)
    }
}
```

**Benefits**:
- Testable business logic (ViewModel)
- UI separate from logic
- Reactive updates (Combine)

---

## Business Logic (Use Cases)

### Protocol + Default Implementation
```swift
// Protocol (in Domain/UseCases/)
protocol CreateDogUseCase {
    func execute(
        name: String,
        breed: String,
        age: Int,
        medicalNotes: String,
        behaviorNotes: String
    ) async throws -> Dog
}

// Implementation
final class DefaultCreateDogUseCase: CreateDogUseCase {
    private let repository: DogRepository

    init(repository: DogRepository) {
        self.repository = repository
    }

    func execute(...) async throws -> Dog {
        // Validation
        guard !name.isEmpty else {
            throw DogError.validationFailed("Name cannot be empty")
        }
        guard !breed.isEmpty else {
            throw DogError.validationFailed("Breed cannot be empty")
        }
        guard age >= 0 && age <= 30 else {
            throw DogError.validationFailed("Age must be between 0 and 30")
        }

        // Create entity
        let dog = Dog(
            id: UUID(),
            name: name,
            breed: breed,
            age: age,
            medicalNotes: medicalNotes,
            behaviorNotes: behaviorNotes
        )

        // Persist
        try await repository.create(dog)

        return dog
    }
}
```

**Benefits**:
- Single Responsibility (one use case = one action)
- Testable (mock repository)
- Reusable across features

---

## Data Access (Repository Pattern)

### Protocol (in Domain/Contracts/)
```swift
protocol DogRepository: Actor {
    func fetchAll() async throws -> [Dog]
    func fetch(id: UUID) async throws -> Dog?
    func create(_ dog: Dog) async throws
    func update(_ dog: Dog) async throws
    func delete(id: UUID) async throws
}
```

### Implementation (in Infrastructure/Repositories/)
```swift
actor InMemoryDogRepository: DogRepository {
    private var dogs: [UUID: Dog] = [:]

    func fetchAll() async throws -> [Dog] {
        Array(dogs.values).sorted { $0.name < $1.name }
    }

    func fetch(id: UUID) async throws -> Dog? {
        dogs[id]
    }

    func create(_ dog: Dog) async throws {
        dogs[dog.id] = dog
    }

    func update(_ dog: Dog) async throws {
        guard dogs[dog.id] != nil else {
            throw DogError.notFound
        }
        dogs[dog.id] = dog
    }

    func delete(id: UUID) async throws {
        guard dogs.removeValue(forKey: id) != nil else {
            throw DogError.notFound
        }
    }
}
```

**Benefits**:
- Swap implementations (InMemory ↔ HTTP ↔ CoreData)
- Testable (use InMemory in tests)
- Thread-safe (actor isolation)

---

## Dependency Injection

### AppDependencyContainer
```swift
final class AppDependencyContainer {
    // Shared instances
    private lazy var sharedDogRepository: DogRepository = InMemoryDogRepository()

    // Repository factories
    func makeDogRepository() -> DogRepository {
        sharedDogRepository
    }

    // Use case factories
    func makeCreateDogUseCase() -> CreateDogUseCase {
        DefaultCreateDogUseCase(repository: makeDogRepository())
    }

    func makeFetchDogsUseCase() -> FetchDogsUseCase {
        DefaultFetchDogsUseCase(repository: makeDogRepository())
    }

    // ViewModel factories
    func makeDogListViewModel() -> DogListViewModel {
        DogListViewModel(
            fetchDogsUseCase: makeFetchDogsUseCase(),
            deleteDogUseCase: makeDeleteDogUseCase()
        )
    }

    // Coordinator factories
    func makeDogCoordinator(
        navigationController: UINavigationController
    ) -> DogCoordinator {
        DogCoordinator(
            navigationController: navigationController,
            dependencyContainer: self
        )
    }
}
```

**Benefits**:
- Single place to configure dependencies
- Easy to swap implementations (feature flags)
- Testable (inject mocks)

---

## Feature Structure (Vertical Slice)

```
Features/Dog/
├── Domain/
│   ├── Entities/
│   │   └── Dog.swift
│   ├── UseCases/
│   │   ├── CreateDogUseCase.swift
│   │   ├── FetchDogsUseCase.swift
│   │   ├── UpdateDogUseCase.swift
│   │   └── DeleteDogUseCase.swift
│   └── Errors/
│       └── DogError.swift
├── Infrastructure/
│   └── Repositories/
│       └── InMemoryDogRepository.swift
└── Presentation/
    ├── List/
    │   ├── DogListViewController.swift
    │   └── DogListViewModel.swift
    └── Editor/
        ├── DogEditorViewController.swift
        └── DogEditorViewModel.swift
```

**Complete vertical slice**: Everything needed for Dog feature in one place.

---

**Key Principle**: Separation of concerns. Each layer has a clear responsibility. Dependencies point inward.
