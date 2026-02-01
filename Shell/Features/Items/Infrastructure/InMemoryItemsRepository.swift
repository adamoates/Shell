//
//  InMemoryItemsRepository.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation

/// In-memory implementation of ItemsRepository
///
/// Thread-safe actor-based storage for items.
/// Used for development and testing until backend is ready.
actor InMemoryItemsRepository: ItemsRepository {

    // MARK: - Properties

    private var items: [Item] = []
    private var isInitialized = false

    // MARK: - Initialization

    init() {
        // Initialize with sample data
        let now = Date()
        items = [
            Item(
                id: UUID().uuidString,
                name: "Review AAPL earnings",
                description: "Check quarterly results and analyst commentary",
                isCompleted: false,
                createdAt: now,
                updatedAt: now
            ),
            Item(
                id: UUID().uuidString,
                name: "Update portfolio spreadsheet",
                description: "Q1 2026 performance tracking",
                isCompleted: true,
                createdAt: now.addingTimeInterval(-3600),
                updatedAt: now.addingTimeInterval(-3600)
            ),
            Item(
                id: UUID().uuidString,
                name: "Buy QQQ calls",
                description: "0DTE scalp strategy",
                isCompleted: false,
                createdAt: now.addingTimeInterval(-7200),
                updatedAt: now.addingTimeInterval(-7200)
            )
        ]
        isInitialized = true
    }

    // MARK: - ItemsRepository

    func fetchAll() async throws -> [Item] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        return items
    }

    func create(_ item: Item) async throws -> Item {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        items.append(item)
        return item
    }

    func update(_ item: Item) async throws -> Item {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        guard let index = items.firstIndex(where: { $0.id == item.id }) else {
            throw ItemError.notFound
        }

        items[index] = item
        return item
    }

    func delete(id: String) async throws {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

        guard let index = items.firstIndex(where: { $0.id == id }) else {
            throw ItemError.notFound
        }

        items.remove(at: index)
    }
}
