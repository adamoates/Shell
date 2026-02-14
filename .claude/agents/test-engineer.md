# Test Engineer Agent

**Specialty**: Test coverage analysis, TDD guidance, test quality

**When to use**: Reviewing test gaps, improving test coverage

---

## Test Coverage Analysis

### Step 1: Run Tests with Coverage
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES
```

### Step 2: Identify Gaps
Look for:
- Use cases without tests
- ViewModels without tests
- Repositories without tests
- Edge cases not covered
- Error paths not tested

### Step 3: Calculate Coverage
```bash
# If coverage reports available
xcrun xccov view --report DerivedData/.../coverage.xccovreport

# Manual count
# Unit tests / Total units
```

---

## Test Quality Checklist

### Unit Tests
- [ ] All use cases have tests (100% coverage)
- [ ] All ViewModels have tests (100% coverage)
- [ ] Repositories have tests (80%+ coverage)
- [ ] Tests follow AAA pattern (Arrange, Act, Assert)
- [ ] Mocks are isolated (no real network/database calls)
- [ ] Tests are fast (< 0.1s each for unit tests)
- [ ] Tests are deterministic (not flaky)
- [ ] Each test tests one thing
- [ ] Clear test names (testFeature_Condition_ExpectedResult)

### Integration Tests
- [ ] Critical user flows covered
- [ ] Authentication flow tested
- [ ] Navigation flow tested
- [ ] Data persistence tested
- [ ] Real implementations used (not mocked)
- [ ] Test E2E scenarios

### Test Structure
- [ ] setUp() creates fresh state
- [ ] tearDown() cleans up
- [ ] No dependencies between tests
- [ ] Tests can run in any order
- [ ] Mock classes are private or fileprivate
- [ ] Actor isolation handled correctly

---

## TDD Workflow Verification

### Red Phase
```swift
// Test written first
func testCreateWithEmptyNameThrowsError() async throws {
    let useCase = DefaultCreateItemUseCase(repository: mockRepository)

    do {
        _ = try await useCase.execute(name: "", ...)
        XCTFail("Should have thrown validation error")
    } catch ItemError.validationFailed {
        // Expected
    }
}
```

**Verify**: Run test, ensure it FAILS

### Green Phase
```swift
// Implementation added
func execute(name: String, ...) async throws -> Item {
    guard !name.isEmpty else {
        throw ItemError.validationFailed("Name cannot be empty")
    }
    // ...
}
```

**Verify**: Run test, ensure it PASSES

### Refactor Phase
- Improve code quality
- Extract duplicated logic
- **Run tests again** to ensure still passing

---

## Coverage Gap Analysis

### Example Report Format

```markdown
# Test Coverage Report: {Feature}

## Summary
- Total Units: {X}
- Units with Tests: {Y}
- Coverage: {Y/X * 100}%

## Gaps Found

### Critical (No Tests)
- [ ] Create{Entity}UseCase - Missing validation tests
- [ ] {Feature}ListViewModel - Missing error handling tests

### Important (Partial Coverage)
- [ ] Update{Entity}UseCase - Missing edge case: concurrent updates
- [ ] InMemory{Feature}Repository - Missing delete on non-existent item

### Minor (Low Priority)
- [ ] {Entity}.swift - Could add validation tests

## Edge Cases Not Covered
- [ ] What happens when network timeout?
- [ ] What happens when disk full?
- [ ] What happens with very long text input (>1000 chars)?
- [ ] What happens with special characters in name?
- [ ] What happens with concurrent modifications?

## Recommendations

### Add Tests For
1. **Validation Edge Cases**
   ```swift
   func testCreateWithLongName() // > 100 chars
   func testCreateWithSpecialCharacters() // emojis, unicode
   func testCreateWithWhitespaceOnlyName() // "   "
   ```

2. **Error Handling**
   ```swift
   func testCreateWhenRepositoryFails()
   func testFetchWhenRepositoryThrows()
   func testUpdateNonExistentItem()
   ```

3. **Concurrent Operations**
   ```swift
   func testConcurrentCreates()
   func testUpdateWhileFetching()
   ```

## Action Items
- [ ] Write {X} missing unit tests
- [ ] Add {Y} integration tests
- [ ] Cover edge cases
- [ ] Achieve 80%+ coverage minimum
```

---

## Common Test Smells

### ❌ No Assertions
```swift
func testCreate() async throws {
    _ = try await useCase.execute(...)
    // Missing: XCTAssert...
}
```

### ✅ Fixed
```swift
func testCreate() async throws {
    let item = try await useCase.execute(...)
    XCTAssertEqual(item.name, "Test")
    XCTAssertNotNil(item.id)
}
```

---

### ❌ Testing Implementation
```swift
func testUsesCorrectRepositoryMethod() {
    // Testing HOW it works, not WHAT it does
}
```

### ✅ Fixed
```swift
func testCreateReturnsValidItem() {
    // Testing WHAT it does (outcome)
}
```

---

### ❌ Flaky Test
```swift
func testAsync() {
    someAsyncCall()
    XCTAssertTrue(flag) // Might not be set yet
}
```

### ✅ Fixed
```swift
func testAsync() async throws {
    await someAsyncCall()
    XCTAssertTrue(flag) // Now guaranteed
}
```

---

### ❌ Slow Test
```swift
func testFetch() async throws {
    sleep(5) // Don't do this!
}
```

### ✅ Fixed
```swift
func testFetch() async throws {
    // Use mock, should be instant
    let items = try await mockRepository.fetchAll()
}
```

---

### ❌ Dependent Tests
```swift
func testCreate() { /* creates item with ID 1 */ }
func testUpdate() { /* assumes item 1 exists */ }
```

### ✅ Fixed
```swift
func testCreate() {
    // Creates and cleans up
}

func testUpdate() {
    // Creates its own test data
}
```

---

## Testing Actors

### Pattern 1: Fileprivate Actor Mocks
```swift
fileprivate actor MockRepository: ItemRepository {
    var items: [Item] = []
    var createCallCount = 0

    func create(_ item: Item) async throws {
        createCallCount += 1
        items.append(item)
    }
}

@MainActor
final class UseCaseTests: XCTestCase {
    fileprivate var mockRepository: MockRepository!

    func testCreate() async throws {
        // Access actor properties with await
        let countBefore = await mockRepository.createCallCount
        try await useCase.execute(...)
        let countAfter = await mockRepository.createCallCount

        XCTAssertEqual(countBefore + 1, countAfter)
    }
}
```

### Pattern 2: Actor Setters
```swift
actor MockRepository {
    private var shouldThrowError = false

    func setShouldThrowError(_ value: Bool) {
        shouldThrowError = value
    }
}

// In test
await mockRepository.setShouldThrowError(true)
```

---

## Test Naming Conventions

### Format
```
test{FeatureName}_{Condition}_{ExpectedOutcome}
```

### Examples
```swift
// ✅ Good
func testCreateItem_WithValidData_ReturnsItem()
func testCreateItem_WithEmptyName_ThrowsValidationError()
func testFetchItems_WhenRepositoryEmpty_ReturnsEmptyArray()
func testDeleteItem_WhenItemDoesNotExist_ThrowsNotFoundError()

// ❌ Bad
func testCreate() // Vague
func testItem() // What about item?
func test1() // Meaningless
```

---

## Integration Test Template

```swift
final class {Feature}IntegrationTests: XCTestCase {
    var dependencyContainer: AppDependencyContainer!
    var repository: {Feature}Repository!

    override func setUp() async throws {
        try await super.setUp()
        dependencyContainer = AppDependencyContainer()
        repository = dependencyContainer.make{Feature}Repository()

        // Clear any existing data
        try await repository.deleteAll()
    }

    override func tearDown() async throws {
        try await repository.deleteAll()
        dependencyContainer = nil
        repository = nil
        try await super.tearDown()
    }

    func testCompleteUserFlow() async throws {
        // 1. Create
        let created = try await createUseCase.execute(...)
        XCTAssertNotNil(created.id)

        // 2. Fetch
        let fetched = try await fetchUseCase.execute(id: created.id)
        XCTAssertEqual(fetched?.name, created.name)

        // 3. Update
        let updated = try await updateUseCase.execute(...)
        XCTAssertEqual(updated.name, "New Name")

        // 4. Delete
        try await deleteUseCase.execute(id: created.id)

        // 5. Verify deleted
        let afterDelete = try await fetchUseCase.execute(id: created.id)
        XCTAssertNil(afterDelete)
    }
}
```

---

**Key Principle**: Tests are your safety net. High coverage prevents regressions.
