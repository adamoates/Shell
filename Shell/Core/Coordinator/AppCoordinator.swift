//
//  AppCoordinator.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit

/// Root coordinator for the entire application
///
/// Responsibilities:
/// - Route based on launch state (implements LaunchRouting)
/// - Manage global navigation state
/// - Handle deep links
/// - Own child coordinators for features
final class AppCoordinator: Coordinator {
    // MARK: - Properties

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    private let window: UIWindow

    // MARK: - Initialization

    init(
        window: UIWindow,
        navigationController: UINavigationController
    ) {
        self.window = window
        self.navigationController = navigationController
    }

    // MARK: - Coordinator

    func start() {
        // AppCoordinator is started via LaunchRouting.route(to:)
        // Called by AppBootstrapper after boot completes
    }

    func finish() {
        // App coordinator doesn't finish
    }
}

// MARK: - LaunchRouting

extension AppCoordinator: LaunchRouting {
    func route(to state: LaunchState) {
        Task { @MainActor in
            switch state {
            case .authenticated:
                showAuthenticatedFlow()
            case .unauthenticated:
                showGuestFlow()
            case .locked:
                showLockedFlow()
            case .maintenance:
                showMaintenanceFlow()
            case .failure(let message):
                showErrorState(message: message)
            }

            window.rootViewController = navigationController
            window.makeKeyAndVisible()
        }
    }
}

// MARK: - Private Navigation

private extension AppCoordinator {
    @MainActor
    func showGuestFlow() {
        let viewController = createPlaceholderViewController(
            title: "Welcome",
            message: "Guest mode - not authenticated"
        )
        navigationController.setViewControllers([viewController], animated: false)
    }

    @MainActor
    func showAuthenticatedFlow() {
        let viewController = createPlaceholderViewController(
            title: "Home",
            message: "Authenticated - session valid"
        )
        navigationController.setViewControllers([viewController], animated: false)
    }

    @MainActor
    func showLockedFlow() {
        let viewController = createPlaceholderViewController(
            title: "Locked",
            message: "Session locked - biometric unlock required"
        )
        navigationController.setViewControllers([viewController], animated: false)
    }

    @MainActor
    func showMaintenanceFlow() {
        let viewController = createPlaceholderViewController(
            title: "Maintenance",
            message: "App is currently under maintenance"
        )
        navigationController.setViewControllers([viewController], animated: false)
    }

    @MainActor
    func showErrorState(message: String) {
        let viewController = createPlaceholderViewController(
            title: "Error",
            message: "Boot failed: \(message)"
        )
        navigationController.setViewControllers([viewController], animated: false)
    }

    @MainActor
    func createPlaceholderViewController(
        title: String,
        message: String? = nil
    ) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        viewController.title = title

        let label = UILabel()
        label.text = message ?? title
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        viewController.view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            label.leadingAnchor.constraint(
                equalTo: viewController.view.leadingAnchor,
                constant: 20
            ),
            label.trailingAnchor.constraint(
                equalTo: viewController.view.trailingAnchor,
                constant: -20
            )
        ])

        return viewController
    }
}
