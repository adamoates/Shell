//
//  ListViewController.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//  Migrated from Storyboard to pure code
//

import UIKit
import Combine

class ListViewController: UIViewController {
    // MARK: - Properties

    weak var delegate: ListViewControllerDelegate?
    private let username: String?
    private let viewModel: ListViewModel
    private var cancellables = Set<AnyCancellable>()
    private lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return control
    }()
    private var networkMonitor: NetworkMonitor?

    // MARK: - UI Components

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 80
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(ItemTableViewCell.self, forCellReuseIdentifier: ItemTableViewCell.reuseIdentifier)
        return table
    }()

    private lazy var emptyStateView: EmptyStateView = {
        let view = EmptyStateView()
        view.message = "No items available"
        view.accessibilityHintText = "Pull down to refresh and load new items"
        return view
    }()

    // MARK: - Initialization

    init(viewModel: ListViewModel, username: String?) {
        self.viewModel = viewModel
        self.username = username
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        setupAccessibility()
        setupBindings()
        setupOfflineMonitoring()
        viewModel.loadItems()
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
        view.backgroundColor = .systemBackground

        // Add table view to view
        view.addSubview(tableView)

        // Add empty state view to view
        view.addSubview(emptyStateView)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Table view fills the view
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Empty state view fills the view
            emptyStateView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyStateView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Add toolbar with buttons
        let identityButton = UIBarButtonItem(
            title: "Setup Identity",
            style: .plain,
            target: self,
            action: #selector(setupIdentityTapped)
        )

        let profileButton = UIBarButtonItem(
            title: "View Profile",
            style: .plain,
            target: self,
            action: #selector(viewProfileTapped)
        )

        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        toolbarItems = [identityButton, spacer, profileButton]
        navigationController?.setToolbarHidden(false, animated: false)

        // Add logout button (left)
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )

        // Add create item button (right)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addItemTapped)
        )
    }

    private func setupTableView() {
        // Setup refresh control (initialized lazily)
        tableView.refreshControl = refreshControl
    }

    private func setupAccessibility() {
        navigationItem.leftBarButtonItem?.accessibilityLabel = "Logout"
        navigationItem.leftBarButtonItem?.accessibilityHint = "Double tap to log out and return to login screen"

        navigationItem.rightBarButtonItem?.accessibilityLabel = "Add item"
        navigationItem.rightBarButtonItem?.accessibilityHint = "Double tap to create a new item"
    }

    private func setupBindings() {
        // Bind items from ViewModel
        viewModel.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.tableView.reloadData()

                // Announce to VoiceOver
                if !items.isEmpty {
                    UIAccessibility.post(
                        notification: .announcement,
                        argument: "\(items.count) items loaded"
                    )
                }
            }
            .store(in: &cancellables)

        // Bind empty state from ViewModel
        viewModel.$isEmpty
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEmpty in
                self?.emptyStateView.isHidden = !isEmpty
                self?.tableView.isHidden = isEmpty
            }
            .store(in: &cancellables)

        // Bind loading state from ViewModel
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
    }

    private func setupOfflineMonitoring() {
        if let monitor = networkMonitor {
            addOfflineMonitoring(networkMonitor: monitor)
        }
    }

    // MARK: - Public Methods (for dependency injection)

    func setNetworkMonitor(_ monitor: NetworkMonitor) {
        self.networkMonitor = monitor
    }

    @objc private func refreshData() {
        Task {
            await viewModel.refreshItems()
        }
    }

    @objc private func logoutTapped() {
        delegate?.listViewControllerDidRequestLogout(self)
    }

    @objc private func setupIdentityTapped() {
        delegate?.listViewControllerDidRequestIdentitySetup(self)
    }

    @objc private func viewProfileTapped() {
        delegate?.listViewControllerDidRequestProfile(self)
    }

    @objc private func addItemTapped() {
        delegate?.listViewControllerDidRequestCreateItem(self)
    }

    // MARK: - Public Methods

    /// Refresh the list of items (called by coordinator after creating/editing an item)
    func refreshList() async {
        await viewModel.refreshItems()
    }
}

// MARK: - UITableViewDataSource

extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ItemTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? ItemTableViewCell else {
            return UITableViewCell()
        }

        let item = viewModel.items[indexPath.row]
        cell.configure(with: item)

        return cell
    }
}

// MARK: - UITableViewDelegate

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = viewModel.items[indexPath.row]
        delegate?.listViewController(self, didSelectItem: item)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.viewModel.deleteItem(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")

        let shareAction = UIContextualAction(style: .normal, title: "Share") { [weak self] _, _, completion in
            guard let item = self?.viewModel.item(at: indexPath.row) else {
                completion(false)
                return
            }

            let activityVC = UIActivityViewController(
                activityItems: [item.name, item.description],
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
