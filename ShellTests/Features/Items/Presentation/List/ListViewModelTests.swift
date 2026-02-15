//
//  ListViewModelTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
import Combine
@testable import Shell

@MainActor
final class ListViewModelTests: XCTestCase {
    private var sut: ListViewModel!
    private var fetchItems: MockFetchItemsUseCase!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        fetchItems = MockFetchItemsUseCase()
        sut = ListViewModel(fetchItems: fetchItems)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        fetchItems = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_hasEmptyItems() {
        XCTAssertTrue(sut.items.isEmpty)
    }

    func testInitialState_isNotLoading() {
        XCTAssertFalse(sut.isLoading)
    }

    func testInitialState_hasNoError() {
        XCTAssertNil(sut.errorMessage)
    }

    func testInitialState_isEmptyIsTrue() {
        XCTAssertTrue(sut.isEmpty)
    }

    // MARK: - Load Items Tests

    func testLoadItems_clearsItems() async {
        // Given - Add some items first
        let sampleItems = createSampleItems(count: 3)
        fetchItems.itemsToReturn = sampleItems
        await sut.refreshItems()

        // Verify items were loaded
        XCTAssertEqual(sut.items.count, 3)

        // When
        sut.loadItems()

        // Then
        XCTAssertTrue(sut.items.isEmpty)
    }

    func testLoadItems_clearsError() {
        // Given
        sut.errorMessage = "Previous error"

        // When
        sut.loadItems()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Refresh Items Success Tests

    func testRefreshItems_withSuccess_setsItems() async {
        // Given
        let sampleItems = createSampleItems(count: 5)
        fetchItems.itemsToReturn = sampleItems

        // When
        await sut.refreshItems()

        // Then
        XCTAssertEqual(sut.items.count, 5)
        XCTAssertEqual(sut.items, sampleItems)
    }

    func testRefreshItems_withSuccess_clearsError() async {
        // Given
        sut.errorMessage = "Previous error"
        let sampleItems = createSampleItems(count: 3)
        fetchItems.itemsToReturn = sampleItems

        // When
        await sut.refreshItems()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    func testRefreshItems_withSuccess_setsLoadingToFalse() async {
        // Given
        let sampleItems = createSampleItems(count: 3)
        fetchItems.itemsToReturn = sampleItems

        // When
        await sut.refreshItems()

        // Then
        XCTAssertFalse(sut.isLoading)
    }

    func testRefreshItems_withSuccess_setsIsEmptyToFalse() async {
        // Given
        let sampleItems = createSampleItems(count: 3)
        fetchItems.itemsToReturn = sampleItems

        // When
        await sut.refreshItems()

        // Then
        XCTAssertFalse(sut.isEmpty)
    }

    // MARK: - Refresh Items Failure Tests

    func testRefreshItems_withFailure_setsErrorMessage() async {
        // Given
        let error = NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network failed"])
        fetchItems.errorToReturn = error

        // When
        await sut.refreshItems()

        // Then
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Failed to load items") ?? false)
    }

    func testRefreshItems_withFailure_itemsRemainEmpty() async {
        // Given
        let error = NSError(domain: "TestError", code: 1)
        fetchItems.errorToReturn = error

        // When
        await sut.refreshItems()

        // Then
        XCTAssertTrue(sut.items.isEmpty)
    }

    func testRefreshItems_withFailure_setsLoadingToFalse() async {
        // Given
        let error = NSError(domain: "TestError", code: 1)
        fetchItems.errorToReturn = error

        // When
        await sut.refreshItems()

        // Then
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Delete Item Tests

    func testDeleteItem_removesItemAtIndex() async {
        // Given
        let sampleItems = createSampleItems(count: 5)
        fetchItems.itemsToReturn = sampleItems
        await sut.refreshItems()

        // When
        sut.deleteItem(at: 2)

        // Then
        XCTAssertEqual(sut.items.count, 4)
        XCTAssertFalse(sut.items.contains { $0.id == "3" })
    }

    func testDeleteItem_withInvalidIndex_doesNotCrash() async {
        // Given
        let sampleItems = createSampleItems(count: 3)
        fetchItems.itemsToReturn = sampleItems
        await sut.refreshItems()

        // When
        sut.deleteItem(at: 10) // Invalid index

        // Then
        XCTAssertEqual(sut.items.count, 3) // No change
    }

    func testDeleteItem_withLastItem_setsIsEmptyToTrue() async {
        // Given
        let sampleItems = createSampleItems(count: 1)
        fetchItems.itemsToReturn = sampleItems
        await sut.refreshItems()

        // When
        sut.deleteItem(at: 0)

        // Then
        XCTAssertTrue(sut.isEmpty)
    }

    // MARK: - Item At Index Tests

    func testItemAtIndex_returnsCorrectItem() async {
        // Given
        let sampleItems = createSampleItems(count: 5)
        fetchItems.itemsToReturn = sampleItems
        await sut.refreshItems()

        // When
        let item = sut.item(at: 2)

        // Then
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.id, "3")
    }

    func testItemAtIndex_withInvalidIndex_returnsNil() async {
        // Given
        let sampleItems = createSampleItems(count: 3)
        fetchItems.itemsToReturn = sampleItems
        await sut.refreshItems()

        // When
        let item = sut.item(at: 10)

        // Then
        XCTAssertNil(item)
    }

    // MARK: - Combine Publisher Tests

    func testIsEmptyPublisher_reflectsItemsChanges() async {
        // Given
        let hasItemsExpectation = expectation(description: "Has items (not empty)")
        let isEmptyExpectation = expectation(description: "Is empty")
        var receivedValues: [Bool] = []
        var hasSeenFalse = false

        sut.$isEmpty
            .dropFirst() // Skip initial true value
            .sink { isEmpty in
                receivedValues.append(isEmpty)
                if !isEmpty && !hasSeenFalse {
                    hasSeenFalse = true
                    hasItemsExpectation.fulfill()
                } else if isEmpty && hasSeenFalse {
                    isEmptyExpectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        let sampleItems = createSampleItems(count: 3)
        fetchItems.itemsToReturn = sampleItems
        await sut.refreshItems()

        await fulfillment(of: [hasItemsExpectation], timeout: 1.0)

        // Delete all items - isEmpty will change from false to true
        sut.deleteItem(at: 0)
        sut.deleteItem(at: 0)
        sut.deleteItem(at: 0)

        // Then
        await fulfillment(of: [isEmptyExpectation], timeout: 1.0)
        XCTAssertTrue(receivedValues.contains(false), "Should have received false (has items)")
        XCTAssertTrue(receivedValues.last == true, "Last value should be true (is empty)")
    }

    // MARK: - Helper Methods

    private func createSampleItems(count: Int) -> [Item] {
        let now = Date()
        return (1...count).map { index in
            Item(
                id: "\(index)",
                name: "Item \(index)",
                description: "Description \(index)",
                isCompleted: false,
                createdAt: now,
                updatedAt: now
            )
        }
    }
}

// MARK: - Mock FetchItemsUseCase

private class MockFetchItemsUseCase: FetchItemsUseCase {
    var itemsToReturn: [Item] = []
    var errorToReturn: Error?
    var executeWasCalled = false

    func execute() async throws -> [Item] {
        executeWasCalled = true

        // Simulate minimal delay
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        if let error = errorToReturn {
            throw error
        }

        return itemsToReturn
    }
}
