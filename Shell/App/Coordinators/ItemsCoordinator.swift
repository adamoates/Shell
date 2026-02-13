//
//  ItemsCoordinator.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit

/// Protocol for ListViewController to communicate with coordinator
protocol ListViewControllerDelegate: AnyObject {
    func listViewControllerDidRequestLogout(_ controller: ListViewController)
    func listViewController(_ controller: ListViewController, didSelectItem item: Item)
    func listViewControllerDidRequestIdentitySetup(_ controller: ListViewController)
    func listViewControllerDidRequestProfile(_ controller: ListViewController)
    func listViewControllerDidRequestCreateItem(_ controller: ListViewController)
    func listViewController(_ controller: ListViewController, didRequestEditItem item: Item)
}

/// Protocol for ItemsCoordinator to communicate events back to parent
protocol ItemsCoordinatorDelegate: AnyObject {
    func itemsCoordinatorDidRequestLogout(_ coordinator: ItemsCoordinator)
    func itemsCoordinatorDidRequestIdentitySetup(_ coordinator: ItemsCoordinator)
    func itemsCoordinatorDidRequestProfile(_ coordinator: ItemsCoordinator)
}

/// Coordinator responsible for items/content flows
///
/// Manages:
/// - Items list screen
/// - Item detail screen
/// - Future: item editing, sharing, etc.
final class ItemsCoordinator: Coordinator {
    // MARK: - Properties

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?
    weak var delegate: ItemsCoordinatorDelegate?

    private let fetchItems: FetchItemsUseCase
    private let createItem: CreateItemUseCase
    private let updateItem: UpdateItemUseCase
    private let deleteItem: DeleteItemUseCase
    private let networkMonitor: NetworkMonitor
    private let logger: Logger

    // MARK: - Initialization

    init(
        navigationController: UINavigationController,
        fetchItems: FetchItemsUseCase,
        createItem: CreateItemUseCase,
        updateItem: UpdateItemUseCase,
        deleteItem: DeleteItemUseCase,
        networkMonitor: NetworkMonitor,
        logger: Logger
    ) {
        self.navigationController = navigationController
        self.fetchItems = fetchItems
        self.createItem = createItem
        self.updateItem = updateItem
        self.deleteItem = deleteItem
        self.networkMonitor = networkMonitor
        self.logger = logger
    }

    // MARK: - Coordinator

    func start() {
        showItemsList()
    }

    func finish() {
        parentCoordinator?.childDidFinish(self)
    }

    // MARK: - Navigation

    @MainActor
    private func showItemsList() {
        // Create and inject ViewModel
        let viewModel = ListViewModel(fetchItems: fetchItems)
        let listVC = ListViewController(viewModel: viewModel, username: nil)
        listVC.delegate = self
        listVC.setNetworkMonitor(networkMonitor)

        navigationController.setViewControllers([listVC], animated: false)
    }

    @MainActor
    private func showDetail(for item: Item) {
        let detailVC = DetailViewController(item: item)
        navigationController.pushViewController(detailVC, animated: true)
    }

    @MainActor
    private func showCreateItem() {
        let viewModel = ItemEditorViewModel(
            createItem: createItem,
            updateItem: updateItem,
            itemToEdit: nil
        )
        viewModel.delegate = self

        let editorVC = ItemEditorViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: editorVC)
        navigationController.present(navController, animated: true)
    }

    @MainActor
    private func showEditItem(_ item: Item) {
        let viewModel = ItemEditorViewModel(
            createItem: createItem,
            updateItem: updateItem,
            itemToEdit: item
        )
        viewModel.delegate = self

        let editorVC = ItemEditorViewController(viewModel: viewModel)
        let navController = UINavigationController(rootViewController: editorVC)
        navigationController.present(navController, animated: true)
    }
}

// MARK: - ListViewControllerDelegate

extension ItemsCoordinator: ListViewControllerDelegate {
    func listViewControllerDidRequestLogout(_ controller: ListViewController) {
        logger.info("Logout requested", category: "coordinator")
        delegate?.itemsCoordinatorDidRequestLogout(self)
    }

    func listViewController(_ controller: ListViewController, didSelectItem item: Item) {
        logger.info("Item selected", category: "coordinator", context: ["itemName": item.name])
        showDetail(for: item)
    }

    func listViewControllerDidRequestIdentitySetup(_ controller: ListViewController) {
        logger.info("Identity setup requested", category: "coordinator")
        delegate?.itemsCoordinatorDidRequestIdentitySetup(self)
    }

    func listViewControllerDidRequestProfile(_ controller: ListViewController) {
        logger.info("Profile view requested", category: "coordinator")
        delegate?.itemsCoordinatorDidRequestProfile(self)
    }

    func listViewControllerDidRequestCreateItem(_ controller: ListViewController) {
        logger.info("Create item requested", category: "coordinator")
        showCreateItem()
    }

    func listViewController(_ controller: ListViewController, didRequestEditItem item: Item) {
        logger.info("Edit item requested", category: "coordinator", context: ["itemName": item.name])
        showEditItem(item)
    }
}

// MARK: - ItemEditorViewModelDelegate

extension ItemsCoordinator: ItemEditorViewModelDelegate {
    func itemEditorViewModel(_ viewModel: ItemEditorViewModel, didSaveItem item: Item) {
        // Dismiss the editor
        navigationController.dismiss(animated: true)

        // Refresh the list to show the updated/new item
        if let listVC = navigationController.viewControllers.first as? ListViewController {
            Task {
                await listVC.refreshList()
            }
        }
    }

    func itemEditorViewModelDidCancel(_ viewModel: ItemEditorViewModel) {
        // Dismiss the editor
        navigationController.dismiss(animated: true)
    }
}
