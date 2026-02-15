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
    private let logger: Logger

    /// Route to restore after successful authentication
    private var pendingRoute: Route?

    // MARK: - Initialization

    init(
        window: UIWindow,
        navigationController: UINavigationController,
        dependencyContainer: AppDependencyContainer,
        logger: Logger
    ) {
        self.window = window
        self.navigationController = navigationController
        self.dependencyContainer = dependencyContainer
        self.logger = logger

        // Observe Universal Link notifications
        setupUniversalLinkObserver()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        logger.debug("Saving intended route", category: "coordinator", context: ["route": route.description])
        pendingRoute = route
    }

    /// Get and clear the pending route
    /// - Returns: The saved route, if any
    func restorePendingRoute() -> Route? {
        guard let route = pendingRoute else {
            return nil
        }

        logger.debug("Restoring pending route", category: "coordinator", context: ["route": route.description])
        pendingRoute = nil
        return route
    }

    /// Clear the pending route without restoring it
    func clearPendingRoute() {
        if pendingRoute != nil {
            logger.debug("Clearing pending route", category: "coordinator")
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

    /// Show reset password screen with token
    /// - Parameter token: The password reset token
    func showResetPassword(token: String) {
        Task { @MainActor in
            // Create ResetPasswordViewController with token
            let resetPasswordUseCase = dependencyContainer.makeResetPasswordUseCase()
            let viewModel = ResetPasswordViewModel(
                token: token,
                resetPasswordUseCase: resetPasswordUseCase
            )
            let viewController = ResetPasswordViewController(viewModel: viewModel)
            viewController.delegate = self

            // Present modally on top of current navigation stack
            if let topViewController = navigationController.topViewController {
                topViewController.present(viewController, animated: true)
            } else {
                navigationController.present(viewController, animated: true)
            }
        }
    }

    /// Show identity setup flow
    /// - Parameter startStep: Optional starting step
    func showIdentitySetup(startStep: IdentityStep? = nil) {
        Task { @MainActor in
            // Get actual userID from current session
            guard let userID = await getCurrentUserID() else {
                logger.error("Cannot show identity setup: No active session", category: "coordinator")
                showGuestFlow()
                return
            }

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
            logger.warning("No URL in Universal Link notification", category: "coordinator")
            return
        }

        logger.info("Processing Universal Link", category: "coordinator", context: ["url": url.absoluteString])

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
    /// Get the current user ID from the active session
    /// - Returns: User ID if session exists and is valid, nil otherwise
    func getCurrentUserID() async -> String? {
        let sessionRepository = dependencyContainer.makeSessionRepository()

        do {
            guard let session = try await sessionRepository.getCurrentSession(),
                  session.isValid else {
                return nil
            }
            return session.userId
        } catch {
            logger.error("Failed to get current session", category: "coordinator", context: ["error": "\(error)"])
            return nil
        }
    }

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

        // Create and start DogCoordinator via DI container
        let dogCoordinator = dependencyContainer.makeDogCoordinator(navigationController: navigationController)
        dogCoordinator.delegate = self
        addChild(dogCoordinator)
        dogCoordinator.start()
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
        logger.info("Login completed", category: "coordinator", context: ["username": username])

        // Check for pending route to restore
        if let pendingRoute = restorePendingRoute() {
            logger.info("Navigating to restored route", category: "coordinator", context: ["route": pendingRoute.description])
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
        logger.info("Logout requested", category: "coordinator")
        // Clear any pending route on logout
        clearPendingRoute()
        // Route to unauthenticated state
        route(to: .unauthenticated)
    }

    func itemsCoordinatorDidRequestIdentitySetup(_ coordinator: ItemsCoordinator) {
        logger.info("Identity setup requested", category: "coordinator")
        // Navigate to identity setup flow
        showIdentitySetup()
    }

    func itemsCoordinatorDidRequestProfile(_ coordinator: ItemsCoordinator) {
        logger.info("Profile view requested", category: "coordinator")

        Task { @MainActor in
            // Get actual userID from current session
            guard let userID = await getCurrentUserID() else {
                logger.error("Cannot show profile: No active session", category: "coordinator")
                return
            }

            showProfile(userID: userID)
        }
    }
}

// MARK: - DogCoordinatorDelegate

extension AppCoordinator: DogCoordinatorDelegate {
    func dogCoordinatorDidRequestLogout(_ coordinator: DogCoordinator) {
        logger.info("Logout requested from Dog feature", category: "coordinator")

        Task {
            // Clear the session
            let sessionRepository = dependencyContainer.makeSessionRepository()
            do {
                try await sessionRepository.clearSession()
                logger.info("Session cleared successfully", category: "coordinator")
            } catch {
                logger.error("Failed to clear session", category: "coordinator", context: ["error": "\(error)"])
            }

            // Navigate to unauthenticated state
            await MainActor.run {
                clearPendingRoute()
                route(to: .unauthenticated)
            }
        }
    }
}

// MARK: - IdentitySetupCoordinatorDelegate

extension AppCoordinator: IdentitySetupCoordinatorDelegate {
    func identitySetupCoordinatorDidComplete(_ coordinator: IdentitySetupCoordinator, profile: UserProfile) {
        logger.info("Identity setup completed", category: "coordinator", context: ["userID": profile.userID])

        // Check for pending route to restore
        if let pendingRoute = restorePendingRoute() {
            logger.info("Navigating to restored route", category: "coordinator", context: ["route": pendingRoute.description])
            // Create router to navigate to the pending route
            let router = dependencyContainer.makeAppRouter(coordinator: self)
            router.navigate(to: pendingRoute)
        } else {
            // No pending route, go to default authenticated state
            route(to: .authenticated)
        }
    }

    func identitySetupCoordinatorDidCancel(_ coordinator: IdentitySetupCoordinator) {
        logger.warning("Identity setup cancelled", category: "coordinator")
        // User cancelled identity setup, return to login
        clearPendingRoute()
        route(to: .unauthenticated)
    }
}

// MARK: - ResetPasswordViewControllerDelegate

extension AppCoordinator: ResetPasswordViewControllerDelegate {
    func resetPasswordViewControllerDidSucceed(_ controller: ResetPasswordViewController) {
        logger.info("Password reset successful", category: "coordinator")

        Task { @MainActor in
            // Dismiss the reset password screen
            controller.dismiss(animated: true) { [weak self] in
                // Show success message and return to login
                let alert = UIAlertController(
                    title: "Password Reset",
                    message: "Your password has been reset successfully. Please log in with your new password.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    // Navigate to login
                    self?.route(to: .unauthenticated)
                })

                self?.navigationController.present(alert, animated: true)
            }
        }
    }

    func resetPasswordViewControllerDidCancel(_ controller: ResetPasswordViewController) {
        logger.info("Password reset cancelled", category: "coordinator")

        Task { @MainActor in
            // Dismiss the reset password screen
            controller.dismiss(animated: true)
        }
    }
}
