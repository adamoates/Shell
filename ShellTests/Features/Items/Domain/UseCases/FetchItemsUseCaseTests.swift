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
        XCTAssertFalse(firstItem.title.isEmpty, "Item should have title")
        XCTAssertFalse(firstItem.subtitle.isEmpty, "Item should have subtitle")
        XCTAssertFalse(firstItem.description.isEmpty, "Item should have description")
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
        XCTAssertEqual(firstItem.title, "Welcome to Shell")
        XCTAssertEqual(firstItem.subtitle, "Getting Started")
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

        return await [
            Item(
                id: "1",
                title: "Welcome to Shell",
                subtitle: "Getting Started",
                description: "This is a demonstration of proper Storyboard layout with Auto Layout constraints that adapt to all device sizes and Dynamic Type settings.",
                date: Date()
            ),
            Item(
                id: "2",
                title: "Adaptive Layouts",
                subtitle: "Size Classes",
                description: "These constraints work perfectly across all devices from iPhone SE to iPad Pro, in both portrait and landscape orientations.",
                date: Date().addingTimeInterval(-3600)
            ),
            Item(
                id: "3",
                title: "Dynamic Type",
                subtitle: "Accessibility",
                description: "All text scales properly with Dynamic Type. Try changing text size in Settings > Accessibility > Display & Text Size.",
                date: Date().addingTimeInterval(-7200)
            ),
            Item(
                id: "4",
                title: "Stack Views",
                subtitle: "Layout Technique",
                description: "Using stack views with proper content hugging and compression resistance priorities ensures clean, maintainable layouts.",
                date: Date().addingTimeInterval(-86400)
            ),
            Item(
                id: "5",
                title: "Pull to Refresh",
                subtitle: "iOS Pattern",
                description: "This list demonstrates pull-to-refresh, a common iOS UI pattern for updating content.",
                date: Date().addingTimeInterval(-172800)
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
