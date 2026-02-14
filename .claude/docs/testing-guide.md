# Testing Guide & Verification Protocol

**Purpose**: Prevent false positives, ensure tests actually pass

---

## Test Pyramid

1. **Domain Tests** (100% coverage required)
   - Use cases
   - Business logic
   - Validation rules

2. **Infrastructure Tests** (80%+ coverage)
   - Repositories
   - HTTP clients
   - Database operations

3. **Presentation Tests** (100% coverage)
   - ViewModels
   - State management
   - User interactions

4. **Integration Tests** (Critical paths)
   - Auth flow
   - Navigation
   - E2E user journeys

5. **UI Tests** (Selective)
   - Smoke tests only
   - Critical user flows

---

## Test Structure (AAA Pattern)

```swift
func testCreateItemSuccess() async throws {
    // Arrange (Given)
    let repository = InMemoryItemsRepository()
    let useCase = DefaultCreateItemUseCase(repository: repository)

    // Act (When)
    let item = try await useCase.execute(
        name: "Test Item",
        description: "Test Description",
        isCompleted: false
    )

    // Assert (Then)
    XCTAssertEqual(item.name, "Test Item")
    XCTAssertFalse(item.isCompleted)
}
```

---

## Verification Protocol (CRITICAL)

### The Golden Rule

**NEVER** claim tests pass without proving it.

❌ **DON'T**:
- Say "tests pass" or "all tests passing"
- Assume tests ran successfully
- Simulate or hallucinate test results

✅ **DO**:
- Run `xcodebuild test` and show `** TEST SUCCEEDED **` output
- Verify exit code is 0: `echo $?`
- Count actual passing tests: `grep -c "passed" output.txt`
- Save logs: `tee /tmp/shell_last_test.log`

---

## Red-Green-Refactor Workflow

### Step 1: RED (Write Failing Test)
```swift
func testValidateEmptyNameThrowsError() async throws {
    let useCase = DefaultCreateItemUseCase(repository: repository)

    do {
        _ = try await useCase.execute(name: "", description: "Test", isCompleted: false)
        XCTFail("Should have thrown validation error")
    } catch ItemError.validationFailed {
        // Expected
    }
}
```

### Step 2: VERIFY Failure
```bash
xcodebuild test -only-testing:ShellTests/CreateItemUseCaseTests/testValidateEmptyNameThrowsError
# Output: ** TEST FAILED ** (Expected)
```

### Step 3: GREEN (Make It Pass)
```swift
func execute(name: String, ...) async throws -> Item {
    guard !name.isEmpty else {
        throw ItemError.validationFailed("Name cannot be empty")
    }
    // ... rest of implementation
}
```

### Step 4: VERIFY Success
```bash
xcodebuild test -only-testing:ShellTests/CreateItemUseCaseTests/testValidateEmptyNameThrowsError
# Output: ** TEST SUCCEEDED ** (Required)
```

### Step 5: REFACTOR
- Improve code quality
- Extract duplicated logic
- **Run tests again** to verify nothing broke

---

## Test Execution Commands

### All Tests
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:ShellUITests \
  2>&1 | tee /tmp/shell_last_test.log

# Save timestamp for pre-commit hook
date +%s > /tmp/shell_last_test_time
```

### Specific Feature
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/DogListViewModelTests
```

### Specific Test Method
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/CreateDogUseCaseTests/testCreateDogSuccess
```

---

## Verification Checklist

After running tests, verify ALL of these:

- [ ] Exit code is 0: `echo $?`
- [ ] Output contains: `** TEST SUCCEEDED **`
- [ ] No `** TEST FAILED **` messages
- [ ] Test count matches expected: `grep -c "passed" /tmp/shell_last_test.log`
- [ ] All expected tests executed (none skipped)
- [ ] Timestamp saved: `date +%s > /tmp/shell_last_test_time`

**Only then** can you claim tests passed.

---

## Integration vs Unit Tests

### Unit Tests
- Mock dependencies
- Fast execution
- Test in isolation
- **Limitation**: Can pass while app is broken

### Integration Tests
- Real implementations
- Slower execution
- Test wiring/integration
- **Strength**: Catches real bugs

**Example**:
```swift
// Unit test (mocked)
func testLoginCreatesSession() async throws {
    let mockRepo = MockSessionRepository()
    let viewModel = LoginViewModel(repository: mockRepo)
    // ... test passes, but real app might be broken
}

// Integration test (real)
func testLoginFlowEndToEnd() async throws {
    let realRepo = KeychainSessionRepository() // Real implementation
    let viewModel = LoginViewModel(repository: realRepo)
    // ... tests actual Keychain, catches wiring issues
}
```

**Rule**: Need BOTH for confidence.

---

## Testing Actors

```swift
// Test setup
fileprivate actor MockRepository: ItemRepository {
    var createCallCount = 0
    private var shouldThrowError = false

    func setShouldThrowError(_ value: Bool) {
        shouldThrowError = value
    }

    func create(_ item: Item) async throws {
        createCallCount += 1
        if shouldThrowError {
            throw RepositoryError.createFailed
        }
    }
}

// In test
@MainActor
final class UseCaseTests: XCTestCase {
    fileprivate var mockRepository: MockRepository!

    override func setUp() async throws {
        mockRepository = MockRepository()
    }

    func testCreate() async throws {
        // Access actor properties with await
        let countBefore = await mockRepository.createCallCount
        XCTAssertEqual(countBefore, 0)

        // Execute
        try await useCase.execute(...)

        // Verify
        let countAfter = await mockRepository.createCallCount
        XCTAssertEqual(countAfter, 1)
    }
}
```

---

## Pre-Commit Hook

Location: `.git/hooks/pre-commit`

**Blocks commits** unless:
1. Tests ran in last 5 minutes
2. Test log contains `** TEST SUCCEEDED **`
3. Exit code was 0

**Override**: `git commit --no-verify` (use sparingly)

---

## Common Test Smells

❌ **No Assertions**: Test that doesn't assert anything
❌ **Testing Implementation**: Test how it works, not what it does
❌ **Flaky Tests**: Sometimes pass, sometimes fail
❌ **Slow Tests**: Unit tests should be <0.1s each
❌ **Dependent Tests**: Test B requires Test A to run first

---

**Key Principle**: Tests are documentation. They prove the code works. False positives erode trust.
