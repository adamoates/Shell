//
//  ItemsRepository.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation

/// Repository protocol for items persistence
///
/// Abstracts the data source (in-memory, local database, remote API).
/// Allows swapping implementations without changing domain logic.
protocol ItemsRepository {
    func fetchAll() async throws -> [Item]
    func create(_ item: Item) async throws -> Item
    func update(_ item: Item) async throws -> Item
    func delete(id: String) async throws
}
