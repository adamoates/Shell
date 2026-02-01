//
//  ListViewModel.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation
import Combine

/// Presentation logic for the list screen
///
/// Responsibilities:
/// - Hold presentation state (items, loading, errors)
/// - Delegate to FetchItemsUseCase for data loading
/// - Handle user actions (refresh, delete)
final class ListViewModel {
    // MARK: - Published Properties

    @Published var items: [Item] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isEmpty: Bool = true

    // MARK: - Dependencies

    private let fetchItems: FetchItemsUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(fetchItems: FetchItemsUseCase) {
        self.fetchItems = fetchItems

        // Update isEmpty whenever items change
        $items
            .map { $0.isEmpty }
            .assign(to: &$isEmpty)
    }

    // MARK: - Actions

    /// Load items initially (called on viewDidLoad)
    func loadItems() {
        // Start with empty state
        items = []
        errorMessage = nil
    }

    /// Refresh items (called on pull-to-refresh)
    @MainActor
    func refreshItems() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedItems = try await fetchItems.execute()
            items = fetchedItems
            errorMessage = nil
        } catch {
            errorMessage = "Failed to load items: \(error.localizedDescription)"
        }

        isLoading = false
    }

    /// Delete an item at the given index
    func deleteItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
    }

    /// Get item at index for sharing
    func item(at index: Int) -> Item? {
        guard items.indices.contains(index) else { return nil }
        return items[index]
    }
}
