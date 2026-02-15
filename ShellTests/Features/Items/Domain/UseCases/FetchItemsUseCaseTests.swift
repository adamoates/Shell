//
//  FetchItemsUseCaseTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

final class FetchItemsUseCaseTests: XCTestCase {
    private var sut: FetchItemsUseCase!
    private var repository: MockItemsRepository!

    override func setUp() {
        super.setUp()
        repository = MockItemsRepository()
        sut = DefaultFetchItemsUseCase(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Success Tests

    func testExecute_returnsSuccess() async throws {
        // When
        let items = try await sut.execute()

        // Then
        XCTAssertNotNil(items, "Execute should succeed")
    }

    func testExecute_returnsNonEmptyItems() async throws {
        // When
        let items = try await sut.execute()

        // Then
        XCTAssertFalse(items.isEmpty, "Should return at least one item")
    }

    func testExecute_returnsExpectedNumberOfItems() async throws {
        // When
        let items = try await sut.execute()

        // Then
        XCTAssertEqual(items.count, 5, "Should return 5 sample items")
    }

    func testExecute_returnsItemsWithCorrectStructure() async throws {
        // When
        let items = try await sut.execute()

        // Then
        guard let firstItem = items.first else {
            XCTFail("Should have at least one item")
            return
        }

        XCTAssertFalse(firstItem.id.isEmpty, "Item should have valid ID")
        XCTAssertFalse(firstItem.name.isEmpty, "Item should have name")
        XCTAssertFalse(firstItem.description.isEmpty, "Item should have description")
        XCTAssertNotNil(firstItem.createdAt, "Item should have createdAt date")
        XCTAssertNotNil(firstItem.updatedAt, "Item should have updatedAt date")
    }

    // TEMPORARY: Disabled due to testmanagerd crash
    // TODO: Re-enable after investigating crash
    func x_testExecute_returnsItemsWithUniqueIDs() async throws {
        // When
        let items = try await sut.execute()

        // Then
        let ids = items.map { $0.id }
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "All items should have unique IDs")
    }

    func testExecute_returnsExpectedFirstItem() async throws {
        // When
        let items = try await sut.execute()

        // Then
        guard let firstItem = items.first else {
            XCTFail("Should have at least one item")
            return
        }

        XCTAssertEqual(firstItem.id, "1")
        XCTAssertEqual(firstItem.name, "Welcome to Shell")
        XCTAssertEqual(firstItem.description, "This is a demonstration of proper Storyboard layout with Auto Layout constraints that adapt to all device sizes and Dynamic Type settings.")
    }

    // MARK: - Performance Tests

    func testExecute_completesWithinReasonableTime() async throws {
        // Given
        let startTime = Date()

        // When
        _ = try await sut.execute()

        // Then
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 2.0, "Execute should complete within 2 seconds")
    }

    func testExecute_simulatesNetworkDelay() async throws {
        // Given
        let startTime = Date()

        // When
        _ = try await sut.execute()

        // Then - Should take at least 0.1 seconds (simulated delay)
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(duration, 0.05, "Should simulate network delay of ~0.1 seconds")
    }
}

// MARK: - Mock Repository

private actor MockItemsRepository: ItemsRepository {
    func fetchAll() async throws -> [Item] {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        let now = Date()
        return await [
            Item(
                id: "1",
                name: "Welcome to Shell",
                description: "This is a demonstration of proper Storyboard layout with Auto Layout constraints that adapt to all device sizes and Dynamic Type settings.",
                isCompleted: false,
                createdAt: now,
                updatedAt: now
            ),
            Item(
                id: "2",
                name: "Adaptive Layouts",
                description: "These constraints work perfectly across all devices from iPhone SE to iPad Pro, in both portrait and landscape orientations.",
                isCompleted: true,
                createdAt: now.addingTimeInterval(-3600),
                updatedAt: now.addingTimeInterval(-3600)
            ),
            Item(
                id: "3",
                name: "Dynamic Type",
                description: "All text scales properly with Dynamic Type. Try changing text size in Settings > Accessibility > Display & Text Size.",
                isCompleted: false,
                createdAt: now.addingTimeInterval(-7200),
                updatedAt: now.addingTimeInterval(-7200)
            ),
            Item(
                id: "4",
                name: "Stack Views",
                description: "Using stack views with proper content hugging and compression resistance priorities ensures clean, maintainable layouts.",
                isCompleted: true,
                createdAt: now.addingTimeInterval(-86400),
                updatedAt: now.addingTimeInterval(-86400)
            ),
            Item(
                id: "5",
                name: "Pull to Refresh",
                description: "This list demonstrates pull-to-refresh, a common iOS UI pattern for updating content.",
                isCompleted: false,
                createdAt: now.addingTimeInterval(-172800),
                updatedAt: now.addingTimeInterval(-172800)
            )
        ]
    }

    func create(_ item: Item) async throws -> Item {
        fatalError("Not implemented in mock")
    }

    func update(_ item: Item) async throws -> Item {
        fatalError("Not implemented in mock")
    }

    func delete(id: String) async throws {
        fatalError("Not implemented in mock")
    }
}
