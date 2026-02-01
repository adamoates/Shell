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
        items = [
            Item(
                id: UUID().uuidString,
                title: "Welcome to Shell",
                subtitle: "Getting Started",
                description: "This is a demonstration of proper programmatic UI with Auto Layout constraints that adapt to all device sizes and Dynamic Type settings.",
                date: Date()
            ),
            Item(
                id: UUID().uuidString,
                title: "Adaptive Layouts",
                subtitle: "Size Classes",
                description: "These constraints work perfectly across all devices from iPhone SE to iPad Pro, in both portrait and landscape orientations.",
                date: Date().addingTimeInterval(-3600)
            ),
            Item(
                id: UUID().uuidString,
                title: "Dynamic Type",
                subtitle: "Accessibility",
                description: "All text scales properly with Dynamic Type. Try changing text size in Settings > Accessibility > Display & Text Size.",
                date: Date().addingTimeInterval(-7200)
            ),
            Item(
                id: UUID().uuidString,
                title: "MVVM Pattern",
                subtitle: "Architecture",
                description: "ViewModels manage state and business logic, ViewControllers handle UI, keeping code clean and testable.",
                date: Date().addingTimeInterval(-86400)
            ),
            Item(
                id: UUID().uuidString,
                title: "Pull to Refresh",
                subtitle: "iOS Pattern",
                description: "This list demonstrates pull-to-refresh, a common iOS UI pattern for updating content.",
                date: Date().addingTimeInterval(-172800)
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
