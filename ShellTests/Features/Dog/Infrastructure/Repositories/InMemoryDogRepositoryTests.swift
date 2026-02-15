import XCTest
@testable import Shell

final class InMemoryDogRepositoryTests: XCTestCase {
    var sut: InMemoryDogRepository!

    override func setUp() {
        super.setUp()
        sut = InMemoryDogRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Create Tests

    func testCreateDogSucceeds() async throws {
        // Arrange
        let dog = Dog(
            name: "Max",
            breed: "Golden Retriever",
            age: 3
        )

        // Act
        let createdDog = try await sut.create(dog)

        // Assert
        XCTAssertEqual(createdDog.id, dog.id)
        XCTAssertEqual(createdDog.name, dog.name)
        XCTAssertEqual(createdDog.breed, dog.breed)
        XCTAssertEqual(createdDog.age, dog.age)
    }

    // MARK: - Fetch Tests

    func testFetchAllReturnsAllDogs() async throws {
        // Arrange
        let dog1 = Dog(name: "Max", breed: "Golden Retriever", age: 3)
        let dog2 = Dog(name: "Buddy", breed: "Labrador", age: 5)

        _ = try await sut.create(dog1)
        _ = try await sut.create(dog2)

        // Act
        let dogs = try await sut.fetchAll()

        // Assert
        XCTAssertEqual(dogs.count, 2)
        XCTAssertTrue(dogs.contains { $0.id == dog1.id })
        XCTAssertTrue(dogs.contains { $0.id == dog2.id })
    }

    func testFetchAllReturnsEmptyArrayWhenNoDogs() async throws {
        // Act
        let dogs = try await sut.fetchAll()

        // Assert
        XCTAssertTrue(dogs.isEmpty)
    }

    func testFetchAllReturnsSortedByCreatedDate() async throws {
        // Arrange
        let dog1 = Dog(
            name: "First",
            breed: "Breed1",
            age: 1,
            createdAt: Date(timeIntervalSince1970: 100)
        )
        let dog2 = Dog(
            name: "Second",
            breed: "Breed2",
            age: 2,
            createdAt: Date(timeIntervalSince1970: 200)
        )

        _ = try await sut.create(dog2)
        _ = try await sut.create(dog1)

        // Act
        let dogs = try await sut.fetchAll()

        // Assert
        XCTAssertEqual(dogs.first?.name, "First")
        XCTAssertEqual(dogs.last?.name, "Second")
    }

    func testFetchByIdReturnsCorrectDog() async throws {
        // Arrange
        let dog = Dog(name: "Charlie", breed: "Beagle", age: 4)
        _ = try await sut.create(dog)

        // Act
        let fetchedDog = try await sut.fetch(id: dog.id)

        // Assert
        XCTAssertNotNil(fetchedDog)
        XCTAssertEqual(fetchedDog?.id, dog.id)
        XCTAssertEqual(fetchedDog?.name, dog.name)
    }

    func testFetchByIdReturnsNilForNonExistentDog() async throws {
        // Arrange
        let randomId = UUID()

        // Act
        let fetchedDog = try await sut.fetch(id: randomId)

        // Assert
        XCTAssertNil(fetchedDog)
    }

    // MARK: - Update Tests

    func testUpdateDogSucceeds() async throws {
        // Arrange
        let dog = Dog(name: "Rocky", breed: "Bulldog", age: 2)
        _ = try await sut.create(dog)

        var updatedDog = dog
        updatedDog = Dog(
            id: updatedDog.id,
            name: "Rocky Jr.",
            breed: "French Bulldog",
            age: 3,
            createdAt: updatedDog.createdAt
        )

        // Act
        let result = try await sut.update(updatedDog)

        // Assert
        XCTAssertEqual(result.name, "Rocky Jr.")
        XCTAssertEqual(result.breed, "French Bulldog")
        XCTAssertEqual(result.age, 3)

        let fetched = try await sut.fetch(id: dog.id)
        XCTAssertEqual(fetched?.name, "Rocky Jr.")
    }

    func testUpdateNonExistentDogThrows() async throws {
        // Arrange
        let dog = Dog(name: "Ghost", breed: "Phantom", age: 0)

        // Act & Assert
        do {
            _ = try await sut.update(dog)
            XCTFail("Expected not found error")
        } catch DogError.notFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUpdateDogUpdatesTimestamp() async throws {
        // Arrange
        let dog = Dog(name: "Bella", breed: "Poodle", age: 5)
        _ = try await sut.create(dog)

        // Act
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        var updatedDog = dog
        updatedDog = Dog(
            id: updatedDog.id,
            name: "Bella Updated",
            breed: updatedDog.breed,
            age: updatedDog.age,
            createdAt: updatedDog.createdAt
        )

        let result = try await sut.update(updatedDog)

        // Assert
        XCTAssertGreaterThan(result.updatedAt, dog.createdAt)
    }

    // MARK: - Delete Tests

    func testDeleteDogSucceeds() async throws {
        // Arrange
        let dog = Dog(name: "Duke", breed: "Doberman", age: 7)
        _ = try await sut.create(dog)

        // Act
        try await sut.delete(id: dog.id)

        // Assert
        let fetchedDog = try await sut.fetch(id: dog.id)
        XCTAssertNil(fetchedDog)
    }

    func testDeleteNonExistentDogThrows() async throws {
        // Arrange
        let randomId = UUID()

        // Act & Assert
        do {
            try await sut.delete(id: randomId)
            XCTFail("Expected not found error")
        } catch DogError.notFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testDeleteRemovesDogFromRepository() async throws {
        // Arrange
        let dog1 = Dog(name: "Milo", breed: "Terrier", age: 4)
        let dog2 = Dog(name: "Luna", breed: "Husky", age: 6)

        _ = try await sut.create(dog1)
        _ = try await sut.create(dog2)

        // Act
        try await sut.delete(id: dog1.id)

        // Assert
        let dogs = try await sut.fetchAll()
        XCTAssertEqual(dogs.count, 1)
        XCTAssertEqual(dogs.first?.id, dog2.id)
    }
}
