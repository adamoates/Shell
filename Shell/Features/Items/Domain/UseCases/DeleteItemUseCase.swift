//
//  DeleteItemUseCase.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation

/// Use case for deleting an item
///
/// Responsibilities:
/// - Validate item exists
/// - Delegate deletion to ItemsRepository
/// - Return success or error
protocol DeleteItemUseCase {
    func execute(id: String) async throws
}

final class DefaultDeleteItemUseCase: DeleteItemUseCase {

    // MARK: - Properties

    private let repository: ItemsRepository

    // MARK: - Initialization

    init(repository: ItemsRepository) {
        self.repository = repository
    }

    // MARK: - DeleteItemUseCase

    func execute(id: String) async throws {
        // Validate item exists before attempting delete
        let items = try await repository.fetchAll()
        guard items.contains(where: { $0.id == id }) else {
            throw ItemError.notFound
        }

        // Delete via repository
        try await repository.delete(id: id)
    }
}
