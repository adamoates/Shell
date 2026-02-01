//
//  FetchItemsUseCase.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Use case for fetching items
///
/// This encapsulates the business logic for loading items.
/// Uses repository to fetch from persistence layer.
protocol FetchItemsUseCase {
    func execute() async throws -> [Item]
}

final class DefaultFetchItemsUseCase: FetchItemsUseCase {
    private let repository: ItemsRepository

    init(repository: ItemsRepository) {
        self.repository = repository
    }

    func execute() async throws -> [Item] {
        return try await repository.fetchAll()
    }
}
