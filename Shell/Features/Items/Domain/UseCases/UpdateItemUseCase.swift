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
    func execute(id: String, title: String, subtitle: String, description: String) async throws -> Item
}

final class DefaultUpdateItemUseCase: UpdateItemUseCase {

    // MARK: - Properties

    private let repository: ItemsRepository

    // MARK: - Initialization

    init(repository: ItemsRepository) {
        self.repository = repository
    }

    // MARK: - UpdateItemUseCase

    func execute(id: String, title: String, subtitle: String, description: String) async throws -> Item {
        // Validate inputs
        guard !title.isEmpty else {
            throw ItemError.validationFailed("Title cannot be empty")
        }

        guard !subtitle.isEmpty else {
            throw ItemError.validationFailed("Subtitle cannot be empty")
        }

        guard !description.isEmpty else {
            throw ItemError.validationFailed("Description cannot be empty")
        }

        // Fetch existing item to preserve other fields
        let items = try await repository.fetchAll()
        guard let existingItem = items.first(where: { $0.id == id }) else {
            throw ItemError.notFound
        }

        // Create updated item
        let updatedItem = Item(
            id: existingItem.id,
            title: title,
            subtitle: subtitle,
            description: description,
            date: existingItem.date // Preserve original date
        )

        // Persist via repository
        return try await repository.update(updatedItem)
    }
}
