//
//  CreateItemUseCaseTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-31.
//

import XCTest
@testable import Shell

/// Tests for CreateItemUseCase
///
/// Following TDD: These tests define the expected behavior
final class CreateItemUseCaseTests: XCTestCase {
    // MARK: - Test Doubles

    private actor MockItemsRepository: ItemsRepository {
        var createCalled = false
        var createdItem: Item?
        var shouldThrowError = false

        func setShouldThrowError(_ value: Bool) {
            shouldThrowError = value
        }

        func fetchAll() async throws -> [Item] {
            return []
        }

        func create(_ item: Item) async throws -> Item {
            createCalled = true
            createdItem = item

            if shouldThrowError {
                throw ItemError.createFailed
            }

            return item
        }

        func update(_ item: Item) async throws -> Item {
            return item
        }

        func delete(id: String) async throws {
            // No-op
        }
    }

    // MARK: - Properties

    private var sut: DefaultCreateItemUseCase!
    private var mockRepository: MockItemsRepository!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockItemsRepository()
        sut = DefaultCreateItemUseCase(repository: mockRepository)
    }

    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        try await super.tearDown()
    }

    // MARK: - Tests: Success Cases

    func testExecute_withValidData_createsItem() async throws {
        // Arrange
        let name = "Test Item"
        let description = "Test Description"
        let isCompleted = false

        // Act
        let result = try await sut.execute(
            name: name,
            description: description,
            isCompleted: isCompleted
        )

        // Assert
        XCTAssertEqual(result.name, name)
        XCTAssertEqual(result.description, description)
        XCTAssertEqual(result.isCompleted, isCompleted)
        XCTAssertFalse(result.id.isEmpty)
        XCTAssertNotNil(result.createdAt)
        XCTAssertNotNil(result.updatedAt)

        let repositoryCalled = await mockRepository.createCalled
        XCTAssertTrue(repositoryCalled, "Should call repository.create()")
    }

    func testExecute_withValidData_callsRepository() async throws {
        // Arrange
        let name = "Test"
        let description = "Description"
        let isCompleted = true

        // Act
        _ = try await sut.execute(
            name: name,
            description: description,
            isCompleted: isCompleted
        )

        // Assert
        let createdItem = await mockRepository.createdItem
        XCTAssertNotNil(createdItem)
        XCTAssertEqual(createdItem?.name, name)
        XCTAssertEqual(createdItem?.description, description)
        XCTAssertEqual(createdItem?.isCompleted, isCompleted)
    }

    func testExecute_withDefaultIsCompleted_createsPendingItem() async throws {
        // Arrange
        let name = "Test Item"
        let description = "Description"

        // Act
        let result = try await sut.execute(
            name: name,
            description: description,
            isCompleted: false
        )

        // Assert
        XCTAssertFalse(result.isCompleted, "Default isCompleted should be false")
    }

    // MARK: - Tests: Validation Failures

    func testExecute_withEmptyName_throwsValidationError() async {
        // Arrange
        let name = ""
        let description = "Description"

        // Act & Assert
        do {
            _ = try await sut.execute(
                name: name,
                description: description,
                isCompleted: false
            )
            XCTFail("Should throw validation error")
        } catch ItemError.validationFailed(let message) {
            XCTAssertEqual(message, "Name cannot be empty")
        } catch {
            XCTFail("Should throw ItemError.validationFailed, got \(error)")
        }
    }

    func testExecute_withEmptyDescription_throwsValidationError() async {
        // Arrange
        let name = "Name"
        let description = ""

        // Act & Assert
        do {
            _ = try await sut.execute(
                name: name,
                description: description,
                isCompleted: false
            )
            XCTFail("Should throw validation error")
        } catch ItemError.validationFailed(let message) {
            XCTAssertEqual(message, "Description cannot be empty")
        } catch {
            XCTFail("Should throw ItemError.validationFailed, got \(error)")
        }
    }

    // MARK: - Tests: Repository Failures

    func testExecute_whenRepositoryFails_propagatesError() async {
        // Arrange
        await mockRepository.setShouldThrowError(true)

        // Act & Assert
        do {
            _ = try await sut.execute(
                name: "Name",
                description: "Description",
                isCompleted: false
            )
            XCTFail("Should propagate repository error")
        } catch ItemError.createFailed {
            // Success: error propagated
        } catch {
            XCTFail("Should throw ItemError.createFailed, got \(error)")
        }
    }
}
