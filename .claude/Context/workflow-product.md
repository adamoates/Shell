# Product Development Workflow

**How to build real-world products using Shell architecture**

Shell provides the architecture and patterns.
This workflow ensures consistent, fast, and safe feature delivery.

---

## Guiding Principles

1. **Build vertical slices only** - Complete features, not layers
2. **Every feature must be user-visible** - No invisible architecture work
3. **Test-first domain logic** - Write tests before implementation
4. **No architecture work without a feature** - Architecture serves features
5. **No partial merges** - Ship complete, working features
6. **Small and complete features** - 2-5 days max per feature

---

## What is a Vertical Slice?

Every feature includes ALL layers:

```
Domain Layer
├── Entity (e.g., Dog, Booking, Note)
├── Use Cases (e.g., CreateDogUseCase)
└── Repository Protocol (e.g., DogsRepository)

Infrastructure Layer
├── InMemory Repository (for testing/MVP)
└── HTTP Repository (for production, later)

Presentation Layer
├── ViewModel (e.g., DogEditorViewModel)
├── ViewController/View (e.g., DogEditorViewController)
└── Coordinator (e.g., DogsCoordinator)

Tests
├── Domain Tests (use cases)
├── Infrastructure Tests (repositories)
└── Presentation Tests (ViewModels)
```

**No half-finished layers. No "I'll add the UI later."**

---

## Feature Development Loop

### 1. Create Feature Branch
```bash
git checkout -b feature/dog-care-routines
```

**Branch naming:**
- `feature/dog-care-routines`
- `feature/booking-request`
- `feature/payment-integration`

### 2. Write Failing Domain Tests

**Start here. Always.**

```swift
func testCreateDogWithValidData() async throws {
    // Arrange
    let repository = InMemoryDogsRepository()
    let useCase = DefaultCreateDogUseCase(repository: repository)

    // Act
    let dog = try await useCase.execute(
        name: "Max",
        breed: "Golden Retriever",
        age: 3
    )

    // Assert
    XCTAssertEqual(dog.name, "Max")
    XCTAssertEqual(dog.breed, "Golden Retriever")
}
```

### 3. Implement Domain Logic

Make the tests pass.

```swift
// Domain/Entities/Dog.swift
struct Dog: Sendable, Identifiable, Codable {
    let id: UUID
    let name: String
    let breed: String
    let age: Int
}

// Domain/UseCases/CreateDogUseCase.swift
protocol CreateDogUseCase {
    func execute(name: String, breed: String, age: Int) async throws -> Dog
}

final class DefaultCreateDogUseCase: CreateDogUseCase {
    private let repository: DogsRepository

    init(repository: DogsRepository) {
        self.repository = repository
    }

    func execute(name: String, breed: String, age: Int) async throws -> Dog {
        // Validation
        guard !name.isEmpty else {
            throw DogError.validationFailed("Name cannot be empty")
        }

        // Business logic
        let dog = Dog(
            id: UUID(),
            name: name,
            breed: breed,
            age: age
        )

        return try await repository.create(dog)
    }
}
```

### 4. Build In-Memory Infrastructure

Start with in-memory for fast iteration.

```swift
actor InMemoryDogsRepository: DogsRepository {
    private var dogs: [UUID: Dog] = [:]

    func create(_ dog: Dog) async throws -> Dog {
        dogs[dog.id] = dog
        return dog
    }

    func fetchAll() async throws -> [Dog] {
        Array(dogs.values)
    }
}
```

### 5. Build ViewModel

```swift
@MainActor
final class DogEditorViewModel: ObservableObject {
    @Published var name = ""
    @Published var breed = ""
    @Published var age = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let createDogUseCase: CreateDogUseCase

    init(createDogUseCase: CreateDogUseCase) {
        self.createDogUseCase = createDogUseCase
    }

    func save() async {
        isLoading = true
        errorMessage = nil

        do {
            let ageInt = Int(age) ?? 0
            _ = try await createDogUseCase.execute(
                name: name,
                breed: breed,
                age: ageInt
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
```

### 6. Build UI and Navigation

```swift
final class DogEditorViewController: UIViewController {
    private let viewModel: DogEditorViewModel

    // Build UI, wire up actions, etc.
}
```

### 7. Add Integration Tests

Test the full flow.

```swift
func testDogCreationFlow() async throws {
    let repository = InMemoryDogsRepository()
    let useCase = DefaultCreateDogUseCase(repository: repository)
    let viewModel = DogEditorViewModel(createDogUseCase: useCase)

    viewModel.name = "Max"
    viewModel.breed = "Golden Retriever"
    viewModel.age = "3"

    await viewModel.save()

    XCTAssertNil(viewModel.errorMessage)
    XCTAssertFalse(viewModel.isLoading)
}
```

### 8. Open Pull Request

Ensure:
- ✅ All tests pass
- ✅ Feature is complete
- ✅ No compiler warnings
- ✅ No TODOs or commented code

### 9. Merge into Main

After review, merge and delete branch.

---

## Definition of Done

A feature is **complete** only if:

### Functional
- ✅ UI works for happy path
- ✅ UI works for error cases
- ✅ Loading states handled
- ✅ Navigation works
- ✅ Error messages are clear

### Business Logic
- ✅ Domain rules enforced
- ✅ Validation works
- ✅ Edge cases handled

### Code Quality
- ✅ Tests written and passing
- ✅ No compiler warnings
- ✅ No force unwraps (!)
- ✅ No TODOs
- ✅ No commented code

### Architecture
- ✅ Clean Architecture respected
- ✅ Dependencies injected properly
- ✅ ViewModels are @MainActor
- ✅ Entities are Sendable

**If ANY of these are incomplete, the feature is NOT done.**

---

## Anti-Patterns to Avoid

### ❌ Don't: Build layers separately
```
Week 1: Build all domain entities
Week 2: Build all repositories
Week 3: Build all UI
```

**Why it fails:**
- No user value until week 3
- Integration issues discovered late
- Hard to validate assumptions

### ✅ Do: Build features vertically
```
Week 1: Dog profile feature (complete)
Week 2: Booking feature (complete)
Week 3: Payment feature (complete)
```

**Why it works:**
- User value every week
- Integration issues caught early
- Assumptions validated quickly

---

### ❌ Don't: Architecture without features
```
"Let's build a generic caching system"
"Let's abstract the network layer"
"Let's create a reusable component library"
```

**Why it fails:**
- Premature abstraction
- Over-engineering
- Doesn't solve real problems

### ✅ Do: Architecture driven by features
```
"Dogs feature needs caching → Add caching"
"API calls are repetitive → Extract HTTP client"
"3 screens use similar layouts → Extract component"
```

**Why it works:**
- Solves real, validated problems
- Right level of abstraction
- Avoids over-engineering

---

### ❌ Don't: Partial merges
```
"Merge domain layer, UI coming later"
"Merge UI, tests coming later"
"Merge feature, error handling coming later"
```

**Why it fails:**
- Broken main branch
- Incomplete features pile up
- Technical debt accumulates

### ✅ Do: Complete merges only
```
"Merge complete dog profile feature"
"Merge complete booking flow"
```

**Why it works:**
- Main always works
- No partial features
- Forces completion

---

## Example: Building a Booking Feature

### Week 1: Day 1 (Domain)
- Create `Booking` entity
- Create `CreateBookingUseCase`
- Write domain tests
- Implement use case
- All domain tests pass ✅

### Week 1: Day 2 (Infrastructure)
- Create `BookingsRepository` protocol
- Implement `InMemoryBookingsRepository`
- Write repository tests
- All tests pass ✅

### Week 1: Day 3-4 (Presentation)
- Create `BookingEditorViewModel`
- Write ViewModel tests
- Create `BookingEditorViewController`
- Wire up navigation
- All tests pass ✅

### Week 1: Day 5 (Polish)
- Error handling
- Loading states
- Integration tests
- Manual testing
- Create PR
- Merge ✅

**Result: Shippable booking feature in 1 week.**

---

## Scaling to Multiple Features

### Week 1: Dog Profiles
Complete vertical slice

### Week 2: Care Routines
Complete vertical slice

### Week 3: Booking Requests
Complete vertical slice

### Week 4: Payment Flow
Complete vertical slice

**Each week delivers user value.**

---

## When to Add HTTP Integration

Start with in-memory repositories for speed.

Add HTTP when:
1. Feature is validated with users
2. You need real data persistence
3. You have a backend API ready

**Process:**
1. Create `HTTPDogsRepository`
2. Implement using `URLSession`
3. Add DTOs for API mapping
4. Test with `URLProtocol` mocks
5. Add feature flag to switch between in-memory/HTTP
6. Gradually roll out

---

## Testing Strategy

### Domain Tests (100% coverage required)
- Use cases
- Business rules
- Validations

### Infrastructure Tests (80%+ coverage)
- Repositories
- HTTP clients
- API mapping

### Presentation Tests (100% coverage)
- ViewModels
- State transitions
- Error handling

### UI Tests (selective)
- Critical user flows only
- Login, booking, payment
- Don't test every screen

---

## Commit Strategy

### Good commits
```
feat: Add dog profile creation

- Created Dog entity with validation
- Implemented CreateDogUseCase
- Added InMemoryDogsRepository
- Built DogEditorViewModel and UI
- Tests: 12 passing

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
```

### Bad commits
```
"WIP"
"Fixed stuff"
"More changes"
"Removed debugs"
```

**Squash WIP commits before merging.**

---

## Key Takeaways

1. **Vertical slices** = Complete features, not layers
2. **User value first** = Ship working features weekly
3. **Test-first domain** = Confidence in business logic
4. **In-memory first** = Fast iteration before HTTP
5. **Complete before merge** = No partial features
6. **Architecture follows features** = Don't over-engineer

---

**Last Updated:** 2026-02-14
**Applies to:** Any product built on Shell
