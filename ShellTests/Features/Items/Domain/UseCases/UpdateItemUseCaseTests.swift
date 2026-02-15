//
//  UpdateItemUseCaseTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-31.
//

import XCTest
@testable import Shell

/// Tests for UpdateItemUseCase
final class UpdateItemUseCaseTests: XCTestCase {
    // MARK: - Test Doubles

    private actor MockItemsRepository: ItemsRepository {
        var updateCalled = false
        var updatedItem: Item?
        var existingItems: [Item] = []
        var shouldThrowError = false

        func addExistingItem(_ item: Item) {
            existingItems.append(item)
        }

        func setShouldThrowError(_ value: Bool) {
            shouldThrowError = value
        }

        func fetchAll() async throws -> [Item] {
            return existingItems
        }

        func create(_ item: Item) async throws -> Item {
            return item
        }

        func update(_ item: Item) async throws -> Item {
            updateCalled = true
            updatedItem = item

            if shouldThrowError {
                throw ItemError.updateFailed
            }

            return item
        }

        func delete(id: String) async throws {
            // No-op
        }
    }

    // MARK: - Properties

    private var sut: DefaultUpdateItemUseCase!
    private var mockRepository: MockItemsRepository!
    private let testItemID = "test-id-123"

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockItemsRepository()

        // Add existing item to repository
        let existingItem = Item(
            id: testItemID,
            name: "Original Name",
            description: "Original Description",
            isCompleted: false,
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            updatedAt: Date().addingTimeInterval(-86400)
        )
        await mockRepository.addExistingItem(existingItem)

        sut = DefaultUpdateItemUseCase(repository: mockRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - Tests: Success Cases

    func testExecute_withValidData_updatesItem() async throws {
        // Arrange
        let newName = "Updated Name"
        let newDescription = "Updated Description"
        let newIsCompleted = true

        // Act
        let result = try await sut.execute(
            id: testItemID,
            name: newName,
            description: newDescription,
            isCompleted: newIsCompleted
        )

        // Assert
        XCTAssertEqual(result.id, testItemID)
        XCTAssertEqual(result.name, newName)
        XCTAssertEqual(result.description, newDescription)
        XCTAssertEqual(result.isCompleted, newIsCompleted)
        XCTAssertNotNil(result.createdAt)
        XCTAssertNotNil(result.updatedAt)

        let repositoryCalled = await mockRepository.updateCalled
        XCTAssertTrue(repositoryCalled, "Should call repository.update()")
    }

    func testExecute_preservesOriginalCreatedAt() async throws {
        // Arrange
        let originalCreatedAt = await mockRepository.existingItems.first?.createdAt

        // Act
        let result = try await sut.execute(
            id: testItemID,
            name: "New Name",
            description: "New Description",
            isCompleted: true
        )

        // Assert
        XCTAssertEqual(result.createdAt, originalCreatedAt, "Should preserve original creation date")
        XCTAssertNotEqual(result.updatedAt, result.createdAt, "Should update updatedAt timestamp")
    }

    // MARK: - Tests: Validation Failures

    func testExecute_withEmptyName_throwsValidationError() async {
        // Act & Assert
        do {
            _ = try await sut.execute(
                id: testItemID,
                name: "",
                description: "Description",
                isCompleted: false
            )
            XCTFail("Should throw validation error")
        } catch ItemError.validationFailed(let message) {
            XCTAssertEqual(message, "Name cannot be empty")
        } catch {
            XCTFail("Should throw ItemError.validationFailed")
        }
    }

    func testExecute_withEmptyDescription_throwsValidationError() async {
        // Act & Assert
        do {
            _ = try await sut.execute(
                id: testItemID,
                name: "Name",
                description: "",
                isCompleted: false
            )
            XCTFail("Should throw validation error")
        } catch ItemError.validationFailed(let message) {
            XCTAssertEqual(message, "Description cannot be empty")
        } catch {
            XCTFail("Should throw ItemError.validationFailed")
        }
    }

    // MARK: - Tests: Item Not Found

    func testExecute_withNonExistentID_throwsNotFoundError() async {
        // Arrange
        let nonExistentID = "non-existent-id"

        // Act & Assert
        do {
            _ = try await sut.execute(
                id: nonExistentID,
                name: "Name",
                description: "Description",
                isCompleted: false
            )
            XCTFail("Should throw not found error")
        } catch ItemError.notFound {
            // Success: error thrown
        } catch {
            XCTFail("Should throw ItemError.notFound")
        }
    }

    // MARK: - Tests: Repository Failures

    func testExecute_whenRepositoryFails_propagatesError() async {
        // Arrange
        await mockRepository.setShouldThrowError(true)

        // Act & Assert
        do {
            _ = try await sut.execute(
                id: testItemID,
                name: "Name",
                description: "Description",
                isCompleted: false
            )
            XCTFail("Should propagate repository error")
        } catch ItemError.updateFailed {
            // Success: error propagated
        } catch {
            XCTFail("Should throw ItemError.updateFailed")
        }
    }
}
