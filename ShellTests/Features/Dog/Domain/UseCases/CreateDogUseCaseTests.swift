import XCTest
@testable import Shell

final class CreateDogUseCaseTests: XCTestCase {
    var sut: DefaultCreateDogUseCase!
    fileprivate var mockRepository: MockDogRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockDogRepository()
        sut = DefaultCreateDogUseCase(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Success Tests

    func testExecuteWithValidDataSucceeds() async throws {
        // Arrange
        let name = "Max"
        let breed = "Golden Retriever"
        let age = 3

        // Act
        let dog = try await sut.execute(
            name: name,
            breed: breed,
            age: age,
            medicalNotes: "Allergic to chicken",
            behaviorNotes: "Friendly with kids"
        )

        // Assert
        XCTAssertEqual(dog.name, name)
        XCTAssertEqual(dog.breed, breed)
        XCTAssertEqual(dog.age, age)
        XCTAssertEqual(dog.medicalNotes, "Allergic to chicken")
        XCTAssertEqual(dog.behaviorNotes, "Friendly with kids")
        let callCount = await mockRepository.createCallCount
        XCTAssertEqual(callCount, 1)
    }

    func testExecuteWithMinimalDataSucceeds() async throws {
        // Arrange
        let name = "Buddy"
        let breed = "Labrador"
        let age = 1

        // Act
        let dog = try await sut.execute(
            name: name,
            breed: breed,
            age: age
        )

        // Assert
        XCTAssertEqual(dog.name, name)
        XCTAssertEqual(dog.breed, breed)
        XCTAssertEqual(dog.age, age)
        XCTAssertTrue(dog.medicalNotes.isEmpty)
        XCTAssertTrue(dog.behaviorNotes.isEmpty)
    }

    // MARK: - Validation Tests

    func testExecuteWithEmptyNameThrows() async {
        // Arrange
        let name = ""
        let breed = "Poodle"
        let age = 2

        // Act & Assert
        do {
            _ = try await sut.execute(name: name, breed: breed, age: age)
            XCTFail("Expected validation error")
        } catch DogError.validationFailed(let reason) {
            XCTAssertEqual(reason, "Name cannot be empty")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteWithEmptyBreedThrows() async {
        // Arrange
        let name = "Charlie"
        let breed = ""
        let age = 4

        // Act & Assert
        do {
            _ = try await sut.execute(name: name, breed: breed, age: age)
            XCTFail("Expected validation error")
        } catch DogError.validationFailed(let reason) {
            XCTAssertEqual(reason, "Breed cannot be empty")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteWithNegativeAgeThrows() async {
        // Arrange
        let name = "Rocky"
        let breed = "Beagle"
        let age = -1

        // Act & Assert
        do {
            _ = try await sut.execute(name: name, breed: breed, age: age)
            XCTFail("Expected validation error")
        } catch DogError.validationFailed(let reason) {
            XCTAssertEqual(reason, "Age must be non-negative")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteWithUnrealisticAgeThrows() async {
        // Arrange
        let name = "Duke"
        let breed = "Bulldog"
        let age = 35

        // Act & Assert
        do {
            _ = try await sut.execute(name: name, breed: breed, age: age)
            XCTFail("Expected validation error")
        } catch DogError.validationFailed(let reason) {
            XCTAssertEqual(reason, "Age must be realistic (0-30 years)")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - Repository Error Tests

    func testExecuteWithRepositoryErrorThrows() async {
        // Arrange
        await mockRepository.setShouldThrowError(true)
        let name = "Bella"
        let breed = "Chihuahua"
        let age = 5

        // Act & Assert
        do {
            _ = try await sut.execute(name: name, breed: breed, age: age)
            XCTFail("Expected create error")
        } catch DogError.createFailed {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Mock Repository
fileprivate actor MockDogRepository: DogRepository {
    var createCallCount = 0
    private var shouldThrowError = false
    private var dogs: [UUID: Dog] = [:]

    func setShouldThrowError(_ value: Bool) {
        shouldThrowError = value
    }

    func fetchAll() async throws -> [Dog] {
        Array(dogs.values)
    }

    func fetch(id: UUID) async throws -> Dog? {
        dogs[id]
    }

    func create(_ dog: Dog) async throws -> Dog {
        createCallCount += 1

        if shouldThrowError {
            throw DogError.createFailed
        }

        dogs[dog.id] = dog
        return dog
    }

    func update(_ dog: Dog) async throws -> Dog {
        dogs[dog.id] = dog
        return dog
    }

    func delete(id: UUID) async throws {
        dogs.removeValue(forKey: id)
    }
}
