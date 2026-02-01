//
//  ItemEditorViewModelTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-31.
//

import XCTest
import Combine
@testable import Shell

/// Tests for ItemEditorViewModel
///
/// Covers both create and edit modes
@MainActor
final class ItemEditorViewModelTests: XCTestCase {

    // MARK: - Test Doubles

    private final class MockCreateItemUseCase: CreateItemUseCase {
        var executeCallCount = 0
        var capturedName: String?
        var capturedDescription: String?
        var capturedIsCompleted: Bool?
        var resultToReturn: Result<Item, Error>?

        func execute(name: String, description: String, isCompleted: Bool) async throws -> Item {
            executeCallCount += 1
            capturedName = name
            capturedDescription = description
            capturedIsCompleted = isCompleted

            switch resultToReturn {
            case .success(let item):
                return item
            case .failure(let error):
                throw error
            case .none:
                let now = Date()
                return Item(id: "new-id", name: name, description: description, isCompleted: isCompleted, createdAt: now, updatedAt: now)
            }
        }
    }

    private final class MockUpdateItemUseCase: UpdateItemUseCase {
        var executeCallCount = 0
        var capturedID: String?
        var capturedName: String?
        var capturedDescription: String?
        var capturedIsCompleted: Bool?
        var resultToReturn: Result<Item, Error>?

        func execute(id: String, name: String, description: String, isCompleted: Bool) async throws -> Item {
            executeCallCount += 1
            capturedID = id
            capturedName = name
            capturedDescription = description
            capturedIsCompleted = isCompleted

            switch resultToReturn {
            case .success(let item):
                return item
            case .failure(let error):
                throw error
            case .none:
                let now = Date()
                return Item(id: id, name: name, description: description, isCompleted: isCompleted, createdAt: now, updatedAt: now)
            }
        }
    }

    private final class MockDelegate: ItemEditorViewModelDelegate {
        var didSaveCallCount = 0
        var savedItem: Item?
        var didCancelCallCount = 0

        func itemEditorViewModel(_ viewModel: ItemEditorViewModel, didSaveItem item: Item) {
            didSaveCallCount += 1
            savedItem = item
        }

        func itemEditorViewModelDidCancel(_ viewModel: ItemEditorViewModel) {
            didCancelCallCount += 1
        }
    }

    // MARK: - Properties

    private var sut: ItemEditorViewModel!
    private var mockCreateUseCase: MockCreateItemUseCase!
    private var mockUpdateUseCase: MockUpdateItemUseCase!
    private var mockDelegate: MockDelegate!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()
        mockCreateUseCase = MockCreateItemUseCase()
        mockUpdateUseCase = MockUpdateItemUseCase()
        mockDelegate = MockDelegate()
        cancellables = []
    }

    override func tearDown() async throws {
        sut = nil
        mockCreateUseCase = nil
        mockUpdateUseCase = nil
        mockDelegate = nil
        cancellables = nil
        try await super.tearDown()
    }

    // MARK: - Tests: Initialization (Create Mode)

    func testInit_createMode_hasEmptyFields() {
        // Act
        sut = ItemEditorViewModel(
            createItem: mockCreateUseCase,
            updateItem: mockUpdateUseCase,
            itemToEdit: nil
        )

        // Assert
        XCTAssertTrue(sut.name.isEmpty)
        XCTAssertTrue(sut.itemDescription.isEmpty)
        XCTAssertFalse(sut.isCompleted)
        XCTAssertFalse(sut.isEditMode)
        XCTAssertEqual(sut.saveButtonTitle, "Create Item")
    }

    // MARK: - Tests: Initialization (Edit Mode)

    func testInit_editMode_prePopulatesFields() {
        // Arrange
        let now = Date()
        let existingItem = Item(
            id: "123",
            name: "Existing Name",
            description: "Existing Description",
            isCompleted: true,
            createdAt: now,
            updatedAt: now
        )

        // Act
        sut = ItemEditorViewModel(
            createItem: mockCreateUseCase,
            updateItem: mockUpdateUseCase,
            itemToEdit: existingItem
        )

        // Assert
        XCTAssertEqual(sut.name, "Existing Name")
        XCTAssertEqual(sut.itemDescription, "Existing Description")
        XCTAssertEqual(sut.isCompleted, true)
        XCTAssertTrue(sut.isEditMode)
        XCTAssertEqual(sut.saveButtonTitle, "Save Changes")
    }

    // MARK: - Tests: Save (Create Mode)

    func testSave_createMode_withValidData_callsCreateUseCase() async {
        // Arrange
        sut = ItemEditorViewModel(
            createItem: mockCreateUseCase,
            updateItem: mockUpdateUseCase,
            itemToEdit: nil
        )
        sut.delegate = mockDelegate
        sut.name = "New Item"
        sut.itemDescription = "New Description"
        sut.isCompleted = false

        // Act
        sut.save()
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for async

        // Assert
        XCTAssertEqual(mockCreateUseCase.executeCallCount, 1)
        XCTAssertEqual(mockCreateUseCase.capturedName, "New Item")
        XCTAssertEqual(mockCreateUseCase.capturedDescription, "New Description")
        XCTAssertEqual(mockCreateUseCase.capturedIsCompleted, false)
        XCTAssertEqual(mockUpdateUseCase.executeCallCount, 0, "Should not call update in create mode")
    }

    func testSave_createMode_onSuccess_notifiesDelegate() async {
        // Arrange
        let now = Date()
        let createdItem = Item(id: "new-id", name: "New Item", description: "Description", isCompleted: false, createdAt: now, updatedAt: now)
        mockCreateUseCase.resultToReturn = .success(createdItem)

        sut = ItemEditorViewModel(
            createItem: mockCreateUseCase,
            updateItem: mockUpdateUseCase,
            itemToEdit: nil
        )
        sut.delegate = mockDelegate
        sut.name = "New Item"
        sut.itemDescription = "Description"
        sut.isCompleted = false

        // Act
        sut.save()
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for async

        // Assert
        XCTAssertEqual(mockDelegate.didSaveCallCount, 1)
        XCTAssertEqual(mockDelegate.savedItem?.id, "new-id")
        XCTAssertFalse(sut.isSaving)
    }

    // MARK: - Tests: Save (Edit Mode)

    func testSave_editMode_withValidData_callsUpdateUseCase() async {
        // Arrange
        let now = Date()
        let existingItem = Item(id: "123", name: "Old Name", description: "Old Description", isCompleted: false, createdAt: now, updatedAt: now)
        sut = ItemEditorViewModel(
            createItem: mockCreateUseCase,
            updateItem: mockUpdateUseCase,
            itemToEdit: existingItem
        )
        sut.delegate = mockDelegate
        sut.name = "Updated Name"
        sut.itemDescription = "Updated Description"
        sut.isCompleted = true

        // Act
        sut.save()
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for async

        // Assert
        XCTAssertEqual(mockUpdateUseCase.executeCallCount, 1)
        XCTAssertEqual(mockUpdateUseCase.capturedID, "123")
        XCTAssertEqual(mockUpdateUseCase.capturedName, "Updated Name")
        XCTAssertEqual(mockUpdateUseCase.capturedDescription, "Updated Description")
        XCTAssertEqual(mockUpdateUseCase.capturedIsCompleted, true)
        XCTAssertEqual(mockCreateUseCase.executeCallCount, 0, "Should not call create in edit mode")
    }

    // MARK: - Tests: Validation

    func testSave_withEmptyName_setsErrorMessage() async {
        // Arrange
        sut = ItemEditorViewModel(
            createItem: mockCreateUseCase,
            updateItem: mockUpdateUseCase,
            itemToEdit: nil
        )
        sut.name = ""
        sut.itemDescription = "Description"

        // Act
        sut.save()
        try? await Task.sleep(nanoseconds: 50_000_000) // Wait for validation

        // Assert
        XCTAssertEqual(sut.errorMessage, "Name cannot be empty")
        XCTAssertEqual(mockCreateUseCase.executeCallCount, 0, "Should not call use case when validation fails")
    }

    func testSave_withEmptyDescription_setsErrorMessage() async {
        // Arrange
        sut = ItemEditorViewModel(
            createItem: mockCreateUseCase,
            updateItem: mockUpdateUseCase,
            itemToEdit: nil
        )
        sut.name = "Name"
        sut.itemDescription = ""

        // Act
        sut.save()
        try? await Task.sleep(nanoseconds: 50_000_000)

        // Assert
        XCTAssertEqual(sut.errorMessage, "Description cannot be empty")
        XCTAssertEqual(mockCreateUseCase.executeCallCount, 0)
    }

    // MARK: - Tests: Error Handling

    func testSave_whenUseCaseFails_setsErrorMessage() async {
        // Arrange
        mockCreateUseCase.resultToReturn = .failure(ItemError.createFailed)
        sut = ItemEditorViewModel(
            createItem: mockCreateUseCase,
            updateItem: mockUpdateUseCase,
            itemToEdit: nil
        )
        sut.delegate = mockDelegate
        sut.name = "Name"
        sut.itemDescription = "Description"

        // Act
        sut.save()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertEqual(sut.errorMessage, "Failed to create item")
        XCTAssertEqual(mockDelegate.didSaveCallCount, 0, "Should not notify delegate on error")
        XCTAssertFalse(sut.isSaving)
    }

    // MARK: - Tests: Loading State

    func testSave_setsLoadingState() async {
        // Arrange
        sut = ItemEditorViewModel(
            createItem: mockCreateUseCase,
            updateItem: mockUpdateUseCase,
            itemToEdit: nil
        )
        sut.name = "Name"
        sut.itemDescription = "Description"

        var loadingStates: [Bool] = []
        sut.$isSaving
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)

        // Act
        sut.save()
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Assert
        XCTAssertTrue(loadingStates.contains(true), "Should set isSaving to true during save")
        XCTAssertFalse(sut.isSaving, "Should reset isSaving after save completes")
    }

    // MARK: - Tests: Cancel

    func testCancel_notifiesDelegate() {
        // Arrange
        sut = ItemEditorViewModel(
            createItem: mockCreateUseCase,
            updateItem: mockUpdateUseCase,
            itemToEdit: nil
        )
        sut.delegate = mockDelegate

        // Act
        sut.cancel()

        // Assert
        XCTAssertEqual(mockDelegate.didCancelCallCount, 1)
    }
}
