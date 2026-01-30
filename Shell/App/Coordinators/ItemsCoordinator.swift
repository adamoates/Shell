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
}

/// Protocol for ItemsCoordinator to communicate events back to parent
protocol ItemsCoordinatorDelegate: AnyObject {
    func itemsCoordinatorDidRequestLogout(_ coordinator: ItemsCoordinator)
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

    // MARK: - Initialization

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
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
        guard let listVC = loadListViewController() else {
            print("⚠️ ItemsCoordinator: Failed to load ListViewController")
            return
        }

        listVC.delegate = self
        navigationController.setViewControllers([listVC], animated: false)
    }

    @MainActor
    private func showDetail(for item: Item) {
        guard let detailVC = loadDetailViewController() else {
            print("⚠️ ItemsCoordinator: Failed to load DetailViewController")
            return
        }

        detailVC.item = item
        navigationController.pushViewController(detailVC, animated: true)
    }

    // MARK: - Storyboard Loading

    @MainActor
    private func loadListViewController() -> ListViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "ListViewController") as? ListViewController
    }

    @MainActor
    private func loadDetailViewController() -> DetailViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController
    }
}

// MARK: - ListViewControllerDelegate

extension ItemsCoordinator: ListViewControllerDelegate {
    func listViewControllerDidRequestLogout(_ controller: ListViewController) {
        print("✅ ItemsCoordinator: Logout requested")
        delegate?.itemsCoordinatorDidRequestLogout(self)
    }

    func listViewController(_ controller: ListViewController, didSelectItem item: Item) {
        print("✅ ItemsCoordinator: Item selected - \(item.title)")
        showDetail(for: item)
    }
}
