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
        let title = "Test Item"
        let subtitle = "Test Subtitle"
        let description = "Test Description"

        // Act
        let result = try await sut.execute(
            title: title,
            subtitle: subtitle,
            description: description
        )

        // Assert
        XCTAssertEqual(result.title, title)
        XCTAssertEqual(result.subtitle, subtitle)
        XCTAssertEqual(result.description, description)
        XCTAssertFalse(result.id.isEmpty)

        let repositoryCalled = await mockRepository.createCalled
        XCTAssertTrue(repositoryCalled, "Should call repository.create()")
    }

    func testExecute_withValidData_callsRepository() async throws {
        // Arrange
        let title = "Test"
        let subtitle = "Subtitle"
        let description = "Description"

        // Act
        _ = try await sut.execute(
            title: title,
            subtitle: subtitle,
            description: description
        )

        // Assert
        let createdItem = await mockRepository.createdItem
        XCTAssertNotNil(createdItem)
        XCTAssertEqual(createdItem?.title, title)
        XCTAssertEqual(createdItem?.subtitle, subtitle)
        XCTAssertEqual(createdItem?.description, description)
    }

    // MARK: - Tests: Validation Failures

    func testExecute_withEmptyTitle_throwsValidationError() async {
        // Arrange
        let title = ""
        let subtitle = "Subtitle"
        let description = "Description"

        // Act & Assert
        do {
            _ = try await sut.execute(
                title: title,
                subtitle: subtitle,
                description: description
            )
            XCTFail("Should throw validation error")
        } catch ItemError.validationFailed(let message) {
            XCTAssertEqual(message, "Title cannot be empty")
        } catch {
            XCTFail("Should throw ItemError.validationFailed")
        }
    }

    func testExecute_withEmptySubtitle_throwsValidationError() async {
        // Arrange
        let title = "Title"
        let subtitle = ""
        let description = "Description"

        // Act & Assert
        do {
            _ = try await sut.execute(
                title: title,
                subtitle: subtitle,
                description: description
            )
            XCTFail("Should throw validation error")
        } catch ItemError.validationFailed(let message) {
            XCTAssertEqual(message, "Subtitle cannot be empty")
        } catch {
            XCTFail("Should throw ItemError.validationFailed")
        }
    }

    func testExecute_withEmptyDescription_throwsValidationError() async {
        // Arrange
        let title = "Title"
        let subtitle = "Subtitle"
        let description = ""

        // Act & Assert
        do {
            _ = try await sut.execute(
                title: title,
                subtitle: subtitle,
                description: description
            )
            XCTFail("Should throw validation error")
        } catch ItemError.validationFailed(let message) {
            XCTAssertEqual(message, "Description cannot be empty")
        } catch {
            XCTFail("Should throw ItemError.validationFailed")
        }
    }

    // MARK: - Tests: Repository Failures

    func testExecute_whenRepositoryFails_propagatesError() async {
        // Arrange
        await mockRepository.setShouldThrowError(true)

        // Act & Assert
        do {
            _ = try await sut.execute(
                title: "Title",
                subtitle: "Subtitle",
                description: "Description"
            )
            XCTFail("Should propagate repository error")
        } catch ItemError.createFailed {
            // Success: error propagated
        } catch {
            XCTFail("Should throw ItemError.createFailed")
        }
    }
}
