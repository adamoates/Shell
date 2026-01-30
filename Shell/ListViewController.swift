//
//  ListViewController.swift
//  Shell
//
//  Created for Storyboard UI/UX Test
//

import UIKit

struct Item {
    let id: Int
    let title: String
    let subtitle: String
    let description: String
    let date: Date
}

class ListViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateView: UIView!
    @IBOutlet weak var emptyStateLabel: UILabel!

    // MARK: - Properties

    weak var delegate: ListViewControllerDelegate?
    var username: String?
    private var items: [Item] = []
    private var refreshControl: UIRefreshControl!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupAccessibility()
        loadItems()
    }

    // MARK: - Setup

    private func setupUI() {
        if let username = username {
            title = "Hello, \(username)"
        } else {
            title = "Items"
        }

        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        // Add logout button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80

        // Setup refresh control
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl

        // Register cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ItemCell")
    }

    private func setupAccessibility() {
        emptyStateLabel.accessibilityLabel = "No items available"
        emptyStateLabel.accessibilityHint = "Pull down to refresh and load new items"

        navigationItem.rightBarButtonItem?.accessibilityLabel = "Logout"
        navigationItem.rightBarButtonItem?.accessibilityHint = "Double tap to log out and return to login screen"
    }

    private func loadItems() {
        // Simulate initial empty state
        items = []
        updateEmptyState()
    }

    @objc private func refreshData() {
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.loadSampleData()
            self?.refreshControl.endRefreshing()
        }
    }

    private func loadSampleData() {
        items = [
            Item(
                id: 1,
                title: "Welcome to Shell",
                subtitle: "Getting Started",
                description: "This is a demonstration of proper Storyboard layout with Auto Layout constraints that adapt to all device sizes and Dynamic Type settings.",
                date: Date()
            ),
            Item(
                id: 2,
                title: "Adaptive Layouts",
                subtitle: "Size Classes",
                description: "These constraints work perfectly across all devices from iPhone SE to iPad Pro, in both portrait and landscape orientations.",
                date: Date().addingTimeInterval(-3600)
            ),
            Item(
                id: 3,
                title: "Dynamic Type",
                subtitle: "Accessibility",
                description: "All text scales properly with Dynamic Type. Try changing text size in Settings > Accessibility > Display & Text Size.",
                date: Date().addingTimeInterval(-7200)
            ),
            Item(
                id: 4,
                title: "Stack Views",
                subtitle: "Layout Technique",
                description: "Using stack views with proper content hugging and compression resistance priorities ensures clean, maintainable layouts.",
                date: Date().addingTimeInterval(-86400)
            ),
            Item(
                id: 5,
                title: "Pull to Refresh",
                subtitle: "iOS Pattern",
                description: "This list demonstrates pull-to-refresh, a common iOS UI pattern for updating content.",
                date: Date().addingTimeInterval(-172800)
            )
        ]

        tableView.reloadData()
        updateEmptyState()

        // Announce to VoiceOver
        UIAccessibility.post(
            notification: .announcement,
            argument: "\(items.count) items loaded"
        )
    }

    private func updateEmptyState() {
        let isEmpty = items.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }

    @objc private func logoutTapped() {
        delegate?.listViewControllerDidRequestLogout(self)
    }
}

// MARK: - UITableViewDataSource

extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let item = items[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = item.title
        content.secondaryText = item.subtitle
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        content.textProperties.adjustsFontForContentSizeCategory = true
        content.secondaryTextProperties.adjustsFontForContentSizeCategory = true

        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator

        // Accessibility
        cell.accessibilityLabel = "\(item.title), \(item.subtitle)"
        cell.accessibilityHint = "Double tap to view details"

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        delegate?.listViewController(self, didSelectItem: item)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.items.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self?.updateEmptyState()
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")

        let shareAction = UIContextualAction(style: .normal, title: "Share") { [weak self] _, _, completion in
            guard let item = self?.items[indexPath.row] else {
                completion(false)
                return
            }

            let activityVC = UIActivityViewController(
                activityItems: [item.title, item.description],
                applicationActivities: nil
            )
            self?.present(activityVC, animated: true)
            completion(true)
        }
        shareAction.image = UIImage(systemName: "square.and.arrow.up")
        shareAction.backgroundColor = .systemBlue

        return UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
    }
}
