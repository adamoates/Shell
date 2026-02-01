//
//  ItemEditorViewModel.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation
import Combine

/// Delegate protocol for ItemEditorViewModel to communicate with coordinator
protocol ItemEditorViewModelDelegate: AnyObject {
    func itemEditorViewModel(_ viewModel: ItemEditorViewModel, didSaveItem item: Item)
    func itemEditorViewModelDidCancel(_ viewModel: ItemEditorViewModel)
}

/// ViewModel for creating or editing an item
///
/// Handles both create and edit modes:
/// - Create mode: itemToEdit is nil
/// - Edit mode: itemToEdit contains existing item
@MainActor
final class ItemEditorViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var title: String = ""
    @Published var subtitle: String = ""
    @Published var itemDescription: String = ""
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?

    // MARK: - Properties

    weak var delegate: ItemEditorViewModelDelegate?

    private let createItem: CreateItemUseCase
    private let updateItem: UpdateItemUseCase
    private let itemToEdit: Item?

    var isEditMode: Bool {
        itemToEdit != nil
    }

    var saveButtonTitle: String {
        isEditMode ? "Save Changes" : "Create Item"
    }

    // MARK: - Initialization

    init(
        createItem: CreateItemUseCase,
        updateItem: UpdateItemUseCase,
        itemToEdit: Item? = nil
    ) {
        self.createItem = createItem
        self.updateItem = updateItem
        self.itemToEdit = itemToEdit

        // Pre-populate fields if editing
        if let item = itemToEdit {
            self.title = item.title
            self.subtitle = item.subtitle
            self.itemDescription = item.description
        }
    }

    // MARK: - Actions

    func save() {
        Task {
            await performSave()
        }
    }

    func cancel() {
        delegate?.itemEditorViewModelDidCancel(self)
    }

    // MARK: - Private

    private func performSave() async {
        // Clear previous error
        errorMessage = nil

        // Validate fields
        guard validate() else {
            return
        }

        // Set loading state
        isSaving = true

        do {
            let savedItem: Item

            if let existingItem = itemToEdit {
                // Edit mode: update existing item
                savedItem = try await updateItem.execute(
                    id: existingItem.id,
                    title: title,
                    subtitle: subtitle,
                    description: itemDescription
                )
            } else {
                // Create mode: create new item
                savedItem = try await createItem.execute(
                    title: title,
                    subtitle: subtitle,
                    description: itemDescription
                )
            }

            // Success: notify delegate
            isSaving = false
            delegate?.itemEditorViewModel(self, didSaveItem: savedItem)

        } catch let error as ItemError {
            // Domain error: show user-friendly message
            isSaving = false
            errorMessage = error.localizedDescription

        } catch {
            // Unknown error
            isSaving = false
            errorMessage = "An unexpected error occurred. Please try again."
        }
    }

    private func validate() -> Bool {
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Title cannot be empty"
            return false
        }

        if subtitle.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Subtitle cannot be empty"
            return false
        }

        if itemDescription.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Description cannot be empty"
            return false
        }

        return true
    }
}
