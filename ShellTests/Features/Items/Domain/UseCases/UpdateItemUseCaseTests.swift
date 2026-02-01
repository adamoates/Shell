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
            title: "Original Title",
            subtitle: "Original Subtitle",
            description: "Original Description",
            date: Date().addingTimeInterval(-86400) // 1 day ago
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
        let newTitle = "Updated Title"
        let newSubtitle = "Updated Subtitle"
        let newDescription = "Updated Description"

        // Act
        let result = try await sut.execute(
            id: testItemID,
            title: newTitle,
            subtitle: newSubtitle,
            description: newDescription
        )

        // Assert
        XCTAssertEqual(result.id, testItemID)
        XCTAssertEqual(result.title, newTitle)
        XCTAssertEqual(result.subtitle, newSubtitle)
        XCTAssertEqual(result.description, newDescription)

        let repositoryCalled = await mockRepository.updateCalled
        XCTAssertTrue(repositoryCalled, "Should call repository.update()")
    }

    func testExecute_preservesOriginalDate() async throws {
        // Arrange
        let originalDate = await mockRepository.existingItems.first?.date

        // Act
        let result = try await sut.execute(
            id: testItemID,
            title: "New Title",
            subtitle: "New Subtitle",
            description: "New Description"
        )

        // Assert
        XCTAssertEqual(result.date, originalDate, "Should preserve original creation date")
    }

    // MARK: - Tests: Validation Failures

    func testExecute_withEmptyTitle_throwsValidationError() async {
        // Act & Assert
        do {
            _ = try await sut.execute(
                id: testItemID,
                title: "",
                subtitle: "Subtitle",
                description: "Description"
            )
            XCTFail("Should throw validation error")
        } catch ItemError.validationFailed(let message) {
            XCTAssertEqual(message, "Title cannot be empty")
        } catch {
            XCTFail("Should throw ItemError.validationFailed")
        }
    }

    func testExecute_withEmptySubtitle_throwsValidationError() async {
        // Act & Assert
        do {
            _ = try await sut.execute(
                id: testItemID,
                title: "Title",
                subtitle: "",
                description: "Description"
            )
            XCTFail("Should throw validation error")
        } catch ItemError.validationFailed(let message) {
            XCTAssertEqual(message, "Subtitle cannot be empty")
        } catch {
            XCTFail("Should throw ItemError.validationFailed")
        }
    }

    func testExecute_withEmptyDescription_throwsValidationError() async {
        // Act & Assert
        do {
            _ = try await sut.execute(
                id: testItemID,
                title: "Title",
                subtitle: "Subtitle",
                description: ""
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
                title: "Title",
                subtitle: "Subtitle",
                description: "Description"
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
                title: "Title",
                subtitle: "Subtitle",
                description: "Description"
            )
            XCTFail("Should propagate repository error")
        } catch ItemError.updateFailed {
            // Success: error propagated
        } catch {
            XCTFail("Should throw ItemError.updateFailed")
        }
    }
}
