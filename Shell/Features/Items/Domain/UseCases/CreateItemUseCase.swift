//
//  CreateItemUseCase.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation

/// Use case for creating a new item
///
/// Responsibilities:
/// - Validate item data
/// - Delegate persistence to ItemsRepository
/// - Return created item or error
protocol CreateItemUseCase {
    func execute(title: String, subtitle: String, description: String) async throws -> Item
}

final class DefaultCreateItemUseCase: CreateItemUseCase {

    // MARK: - Properties

    private let repository: ItemsRepository

    // MARK: - Initialization

    init(repository: ItemsRepository) {
        self.repository = repository
    }

    // MARK: - CreateItemUseCase

    func execute(title: String, subtitle: String, description: String) async throws -> Item {
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

        // Create item
        let newItem = Item(
            id: UUID().uuidString,
            title: title,
            subtitle: subtitle,
            description: description,
            date: Date()
        )

        // Persist via repository
        return try await repository.create(newItem)
    }
}

/// Errors that can occur during item operations
public enum ItemError: LocalizedError {
    case validationFailed(String)
    case notFound
    case createFailed
    case updateFailed
    case deleteFailed

    public var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return message
        case .notFound:
            return "Item not found"
        case .createFailed:
            return "Failed to create item"
        case .updateFailed:
            return "Failed to update item"
        case .deleteFailed:
            return "Failed to delete item"
        }
    }
}
