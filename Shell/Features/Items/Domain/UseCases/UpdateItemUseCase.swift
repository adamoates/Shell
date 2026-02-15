//
//  UpdateItemUseCase.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation

/// Use case for updating an existing item
///
/// Responsibilities:
/// - Validate item data
/// - Ensure item exists
/// - Delegate persistence to ItemsRepository
/// - Return updated item or error
protocol UpdateItemUseCase {
    func execute(id: String, name: String, description: String, isCompleted: Bool) async throws -> Item
}

final class DefaultUpdateItemUseCase: UpdateItemUseCase {
    // MARK: - Properties

    private let repository: ItemsRepository

    // MARK: - Initialization

    init(repository: ItemsRepository) {
        self.repository = repository
    }

    // MARK: - UpdateItemUseCase

    func execute(id: String, name: String, description: String, isCompleted: Bool) async throws -> Item {
        // Validate inputs
        guard !name.isEmpty else {
            throw ItemError.validationFailed("Name cannot be empty")
        }

        guard !description.isEmpty else {
            throw ItemError.validationFailed("Description cannot be empty")
        }

        // Fetch existing item to preserve createdAt
        let items = try await repository.fetchAll()
        guard let existingItem = items.first(where: { $0.id == id }) else {
            throw ItemError.notFound
        }

        // Create updated item (preserve createdAt, update updatedAt)
        let updatedItem = Item(
            id: existingItem.id,
            name: name,
            description: description,
            isCompleted: isCompleted,
            createdAt: existingItem.createdAt, // Preserve original creation date
            updatedAt: Date() // Set to now
        )

        // Persist via repository
        return try await repository.update(updatedItem)
    }
}
