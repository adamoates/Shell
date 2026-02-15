import XCTest
import Combine
@testable import Shell

@MainActor
final class DogEditorViewModelTests: XCTestCase {
    var sut: DogEditorViewModel!
    fileprivate var mockCreateUseCase: MockCreateDogUseCase!
    fileprivate var mockUpdateUseCase: MockUpdateDogUseCase!
    fileprivate var mockCoordinator: MockDogEditorCoordinator!

    override func setUp() {
        super.setUp()
        mockCreateUseCase = MockCreateDogUseCase()
        mockUpdateUseCase = MockUpdateDogUseCase()
        mockCoordinator = MockDogEditorCoordinator()
    }

    override func tearDown() {
        sut = nil
        mockCreateUseCase = nil
        mockUpdateUseCase = nil
        mockCoordinator = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitWithNoDogShowsCreateMode() {
        // Arrange & Act
        sut = DogEditorViewModel(
            dog: nil,
            createDogUseCase: mockCreateUseCase,
            updateDogUseCase: mockUpdateUseCase
        )

        // Assert
        XCTAssertFalse(sut.isEditMode)
        XCTAssertEqual(sut.title, "Add Dog")
        XCTAssertEqual(sut.saveButtonTitle, "Create")
        XCTAssertTrue(sut.name.isEmpty)
        XCTAssertTrue(sut.breed.isEmpty)
        XCTAssertTrue(sut.age.isEmpty)
    }

    func testInitWithDogShowsEditMode() {
        // Arrange
        let dog = Dog(
            name: "Max",
            breed: "Golden Retriever",
            age: 3,
            medicalNotes: "Allergies",
            behaviorNotes: "Friendly"
        )

        // Act
        sut = DogEditorViewModel(
            dog: dog,
            createDogUseCase: mockCreateUseCase,
            updateDogUseCase: mockUpdateUseCase
        )

        // Assert
        XCTAssertTrue(sut.isEditMode)
        XCTAssertEqual(sut.title, "Edit Dog")
        XCTAssertEqual(sut.saveButtonTitle, "Update")
        XCTAssertEqual(sut.name, "Max")
        XCTAssertEqual(sut.breed, "Golden Retriever")
        XCTAssertEqual(sut.age, "3")
        XCTAssertEqual(sut.medicalNotes, "Allergies")
        XCTAssertEqual(sut.behaviorNotes, "Friendly")
    }

    // MARK: - Create Tests

    func testSaveCreatesNewDogSuccessfully() async {
        // Arrange
        sut = DogEditorViewModel(
            dog: nil,
            createDogUseCase: mockCreateUseCase,
            updateDogUseCase: mockUpdateUseCase,
            coordinator: mockCoordinator
        )

        sut.name = "Buddy"
        sut.breed = "Labrador"
        sut.age = "2"
        sut.medicalNotes = "None"
        sut.behaviorNotes = "Energetic"

        // Act
        await sut.save()

        // Assert
        let executeCallCount = await mockCreateUseCase.executeCallCount
        let lastNamePassed = await mockCreateUseCase.lastNamePassed
        let lastBreedPassed = await mockCreateUseCase.lastBreedPassed
        let lastAgePassed = await mockCreateUseCase.lastAgePassed

        XCTAssertEqual(executeCallCount, 1)
        XCTAssertEqual(lastNamePassed, "Buddy")
        XCTAssertEqual(lastBreedPassed, "Labrador")
        XCTAssertEqual(lastAgePassed, 2)
        XCTAssertEqual(mockCoordinator.didSaveDogCallCount, 1)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testSaveHandlesCreateError() async {
        // Arrange
        sut = DogEditorViewModel(
            dog: nil,
            createDogUseCase: mockCreateUseCase,
            updateDogUseCase: mockUpdateUseCase,
            coordinator: mockCoordinator
        )

        await mockCreateUseCase.setShouldThrowError(true)
        sut.name = "Charlie"
        sut.breed = "Beagle"
        sut.age = "4"

        // Act
        await sut.save()

        // Assert
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(mockCoordinator.didSaveDogCallCount, 0)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Update Tests

    func testSaveUpdatesExistingDogSuccessfully() async {
        // Arrange
        let existingDog = Dog(
            name: "Rocky",
            breed: "Bulldog",
            age: 5
        )

        sut = DogEditorViewModel(
            dog: existingDog,
            createDogUseCase: mockCreateUseCase,
            updateDogUseCase: mockUpdateUseCase,
            coordinator: mockCoordinator
        )

        sut.name = "Rocky Jr."
        sut.age = "6"

        // Act
        await sut.save()

        // Assert
        let executeCallCount = await mockUpdateUseCase.executeCallCount
        let lastDogPassed = await mockUpdateUseCase.lastDogPassed

        XCTAssertEqual(executeCallCount, 1)
        XCTAssertEqual(lastDogPassed?.name, "Rocky Jr.")
        XCTAssertEqual(lastDogPassed?.age, 6)
        XCTAssertEqual(mockCoordinator.didSaveDogCallCount, 1)
        XCTAssertNil(sut.errorMessage)
    }

    func testSaveHandlesUpdateError() async {
        // Arrange
        let existingDog = Dog(name: "Duke", breed: "Doberman", age: 7)

        sut = DogEditorViewModel(
            dog: existingDog,
            createDogUseCase: mockCreateUseCase,
            updateDogUseCase: mockUpdateUseCase,
            coordinator: mockCoordinator
        )

        await mockUpdateUseCase.setShouldThrowError(true)
        sut.name = "Duke Updated"

        // Act
        await sut.save()

        // Assert
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertEqual(mockCoordinator.didSaveDogCallCount, 0)
    }

    // MARK: - Cancel Tests

    func testCancelCallsCoordinator() {
        // Arrange
        sut = DogEditorViewModel(
            dog: nil,
            createDogUseCase: mockCreateUseCase,
            updateDogUseCase: mockUpdateUseCase,
            coordinator: mockCoordinator
        )

        // Act
        sut.cancel()

        // Assert
        XCTAssertEqual(mockCoordinator.didCancelEditingCallCount, 1)
    }

    // MARK: - Loading State Tests

    func testSaveUpdatesLoadingState() async {
        // Arrange
        sut = DogEditorViewModel(
            dog: nil,
            createDogUseCase: mockCreateUseCase,
            updateDogUseCase: mockUpdateUseCase
        )

        sut.name = "Test"
        sut.breed = "Test"
        sut.age = "1"

        // Act
        let expectation = XCTestExpectation(description: "Loading state updated")
        var loadingStates: [Bool] = []

        let cancellable = sut.$isLoading.sink { isLoading in
            loadingStates.append(isLoading)
            if loadingStates.count == 3 { // Initial false, true during save, false after
                expectation.fulfill()
            }
        }

        await sut.save()

        // Assert
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates, [false, true, false])

        cancellable.cancel()
    }
}

// MARK: - Mock Create Use Case
private actor MockCreateDogUseCase: CreateDogUseCase {
    var executeCallCount = 0
    private var shouldThrowError = false
    var lastNamePassed: String?
    var lastBreedPassed: String?
    var lastAgePassed: Int?

    func setShouldThrowError(_ value: Bool) {
        shouldThrowError = value
    }

    func execute(
        name: String,
        breed: String,
        age: Int,
        medicalNotes: String,
        behaviorNotes: String
    ) async throws -> Dog {
        executeCallCount += 1
        lastNamePassed = name
        lastBreedPassed = breed
        lastAgePassed = age

        if shouldThrowError {
            throw DogError.createFailed
        }

        return Dog(
            name: name,
            breed: breed,
            age: age,
            medicalNotes: medicalNotes,
            behaviorNotes: behaviorNotes
        )
    }
}

// MARK: - Mock Update Use Case
private actor MockUpdateDogUseCase: UpdateDogUseCase {
    var executeCallCount = 0
    private var shouldThrowError = false
    var lastDogPassed: Dog?

    func setShouldThrowError(_ value: Bool) {
        shouldThrowError = value
    }

    func execute(_ dog: Dog) async throws -> Dog {
        executeCallCount += 1
        lastDogPassed = dog

        if shouldThrowError {
            throw DogError.updateFailed
        }

        return dog
    }
}

// MARK: - Mock Coordinator
private final class MockDogEditorCoordinator: DogEditorCoordinatorDelegate {
    var didSaveDogCallCount = 0
    var didCancelEditingCallCount = 0

    func didSaveDog() {
        didSaveDogCallCount += 1
    }

    func didCancelEditing() {
        didCancelEditingCallCount += 1
    }
}
