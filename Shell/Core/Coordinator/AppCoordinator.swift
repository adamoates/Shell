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
/// - Own and delegate to child coordinators for features
final class AppCoordinator: Coordinator {
    // MARK: - Properties

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    private let window: UIWindow
    private let dependencyContainer: AppDependencyContainer

    /// Route to restore after successful authentication
    private var pendingRoute: Route?

    // MARK: - Initialization

    init(
        window: UIWindow,
        navigationController: UINavigationController,
        dependencyContainer: AppDependencyContainer
    ) {
        self.window = window
        self.navigationController = navigationController
        self.dependencyContainer = dependencyContainer

        // Observe Universal Link notifications
        setupUniversalLinkObserver()
    }

    // MARK: - Coordinator

    func start() {
        // AppCoordinator is started via LaunchRouting.route(to:)
        // Called by AppBootstrapper after boot completes
    }

    func finish() {
        // App coordinator doesn't finish
    }

    // MARK: - Pending Route Management

    /// Save a route to restore after authentication
    /// - Parameter route: The route that was denied due to lack of authentication
    func saveIntendedRoute(_ route: Route) {
        print("💾 AppCoordinator: Saving intended route: \(route.description)")
        pendingRoute = route
    }

    /// Get and clear the pending route
    /// - Returns: The saved route, if any
    func restorePendingRoute() -> Route? {
        guard let route = pendingRoute else {
            return nil
        }

        print("📍 AppCoordinator: Restoring pending route: \(route.description)")
        pendingRoute = nil
        return route
    }

    /// Clear the pending route without restoring it
    func clearPendingRoute() {
        if pendingRoute != nil {
            print("🗑️  AppCoordinator: Clearing pending route")
            pendingRoute = nil
        }
    }

    // MARK: - Profile Navigation

    /// Show profile for a user
    /// - Parameter userID: The user's ID
    func showProfile(userID: String) {
        Task { @MainActor in
            let profileCoordinator = dependencyContainer.makeProfileCoordinator(
                navigationController: navigationController,
                userID: userID
            )
            addChild(profileCoordinator)
            profileCoordinator.start()
        }
    }

    /// Show identity setup flow
    /// - Parameter startStep: Optional starting step
    func showIdentitySetup(startStep: IdentityStep? = nil) {
        Task { @MainActor in
            // TODO: Get actual userID from session
            let userID = "current_user"  // Placeholder

            let identityCoordinator = dependencyContainer.makeIdentitySetupCoordinator(
                navigationController: navigationController,
                userID: userID,
                startStep: startStep
            )
            identityCoordinator.delegate = self
            addChild(identityCoordinator)
            identityCoordinator.start()
        }
    }

    // MARK: - Universal Links

    /// Setup observer for Universal Link notifications
    private func setupUniversalLinkObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUniversalLinkNotification(_:)),
            name: .handleUniversalLink,
            object: nil
        )
    }

    /// Handle Universal Link notification from SceneDelegate
    /// - Parameter notification: Notification containing the URL in userInfo
    @objc private func handleUniversalLinkNotification(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else {
            print("⚠️ AppCoordinator: No URL in Universal Link notification")
            return
        }

        print("🔗 AppCoordinator: Processing Universal Link: \(url)")

        // Create router to handle the URL
        let router = dependencyContainer.makeAppRouter(coordinator: self)
        router.navigate(to: url)
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
        // Remove any existing child coordinators
        removeAllChildCoordinators()

        // Create and start AuthCoordinator via DI container
        let authCoordinator = dependencyContainer.makeAuthCoordinator(navigationController: navigationController)
        authCoordinator.delegate = self
        addChild(authCoordinator)
        authCoordinator.start()
    }

    @MainActor
    func showAuthenticatedFlow() {
        // Remove any existing child coordinators
        removeAllChildCoordinators()

        // Create and start ItemsCoordinator via DI container
        let itemsCoordinator = dependencyContainer.makeItemsCoordinator(navigationController: navigationController)
        itemsCoordinator.delegate = self
        addChild(itemsCoordinator)
        itemsCoordinator.start()
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

    // MARK: - Child Coordinator Management

    func addChild(_ coordinator: Coordinator) {
        guard !childCoordinators.contains(where: { $0 === coordinator }) else { return }
        childCoordinators.append(coordinator)
        coordinator.parentCoordinator = self
    }

    func removeChild(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }

    func removeAllChildCoordinators() {
        childCoordinators.forEach { $0.finish() }
        childCoordinators.removeAll()
    }
}

// MARK: - AuthCoordinatorDelegate

extension AppCoordinator: AuthCoordinatorDelegate {
    func authCoordinatorDidCompleteLogin(_ coordinator: AuthCoordinator, username: String) {
        print("✅ AppCoordinator: Login completed for user: \(username)")

        // Check for pending route to restore
        if let pendingRoute = restorePendingRoute() {
            print("📍 AppCoordinator: Navigating to restored route: \(pendingRoute.description)")
            // Create router to navigate to the pending route
            let router = dependencyContainer.makeAppRouter(coordinator: self)
            router.navigate(to: pendingRoute)
        } else {
            // No pending route, go to default authenticated state
            route(to: .authenticated)
        }
    }
}

// MARK: - ItemsCoordinatorDelegate

extension AppCoordinator: ItemsCoordinatorDelegate {
    func itemsCoordinatorDidRequestLogout(_ coordinator: ItemsCoordinator) {
        print("✅ AppCoordinator: Logout requested")
        // Clear any pending route on logout
        clearPendingRoute()
        // Route to unauthenticated state
        route(to: .unauthenticated)
    }

    func itemsCoordinatorDidRequestIdentitySetup(_ coordinator: ItemsCoordinator) {
        print("✅ AppCoordinator: Identity setup requested")
        // Navigate to identity setup flow
        showIdentitySetup()
    }

    func itemsCoordinatorDidRequestProfile(_ coordinator: ItemsCoordinator) {
        print("✅ AppCoordinator: Profile view requested")
        // TODO: Get actual userID from session
        // For now, use a test userID
        showProfile(userID: "current_user")
    }
}

// MARK: - IdentitySetupCoordinatorDelegate

extension AppCoordinator: IdentitySetupCoordinatorDelegate {
    func identitySetupCoordinatorDidComplete(_ coordinator: IdentitySetupCoordinator, profile: UserProfile) {
        print("✅ AppCoordinator: Identity setup completed for user: \(profile.userID)")

        // Check for pending route to restore
        if let pendingRoute = restorePendingRoute() {
            print("📍 AppCoordinator: Navigating to restored route: \(pendingRoute.description)")
            // Create router to navigate to the pending route
            let router = dependencyContainer.makeAppRouter(coordinator: self)
            router.navigate(to: pendingRoute)
        } else {
            // No pending route, go to default authenticated state
            route(to: .authenticated)
        }
    }

    func identitySetupCoordinatorDidCancel(_ coordinator: IdentitySetupCoordinator) {
        print("⚠️ AppCoordinator: Identity setup cancelled")
        // User cancelled identity setup, return to login
        clearPendingRoute()
        route(to: .unauthenticated)
    }
}
