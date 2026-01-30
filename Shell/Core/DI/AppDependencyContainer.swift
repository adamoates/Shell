//
//  AppDependencyContainer.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit

/// Composition Root for dependency injection
///
/// This is the ONLY place where concrete types are instantiated and wired together.
/// All other code depends on protocols, not concrete types.
///
/// Benefits:
/// - Single source of truth for object graph
/// - Easy to swap implementations (testing, feature flags)
/// - Clear visibility of dependencies
/// - No singletons (except this container if needed)
final class AppDependencyContainer {
    // MARK: - Shared Dependencies

    /// Shared session repository (singleton pattern)
    /// Session state must be shared across the app
    private lazy var sharedSessionRepository: SessionRepository = InMemorySessionRepository()

    // MARK: - Boot Factory

    /// Create the app bootstrapper
    /// - Parameter router: The launch router (typically AppCoordinator)
    /// - Returns: Configured bootstrapper
    func makeAppBootstrapper(router: LaunchRouting) -> AppBootstrapper {
        AppBootstrapper(
            restoreSession: makeRestoreSessionUseCase(),
            router: router
        )
    }

    // MARK: - Coordinator Factory

    /// Create the root app coordinator
    /// - Parameter window: The main window
    /// - Returns: Configured app coordinator
    func makeAppCoordinator(window: UIWindow) -> AppCoordinator {
        let navigationController = UINavigationController()

        return AppCoordinator(
            window: window,
            navigationController: navigationController,
            dependencyContainer: self
        )
    }

    /// Create an auth coordinator
    /// - Parameter navigationController: The navigation controller to use
    /// - Returns: Configured auth coordinator
    func makeAuthCoordinator(navigationController: UINavigationController) -> AuthCoordinator {
        AuthCoordinator(
            navigationController: navigationController,
            validateCredentials: makeValidateCredentialsUseCase()
        )
    }

    /// Create an items coordinator
    /// - Parameter navigationController: The navigation controller to use
    /// - Returns: Configured items coordinator
    func makeItemsCoordinator(navigationController: UINavigationController) -> ItemsCoordinator {
        ItemsCoordinator(navigationController: navigationController)
    }

    // MARK: - Navigation Factory

    /// Create the app router
    /// - Parameter coordinator: The app coordinator
    /// - Returns: Configured app router
    func makeAppRouter(coordinator: AppCoordinator) -> Router {
        AppRouter(
            coordinator: coordinator,
            accessControl: makeAuthGuard()
        )
    }

    /// Create an auth guard for route access control
    /// - Returns: Configured auth guard
    func makeAuthGuard() -> RouteAccessControl {
        AuthGuard(
            sessionRepository: makeSessionRepository()
        )
    }

    /// Create a route resolver
    /// - Returns: Configured route resolver
    func makeRouteResolver() -> RouteResolver {
        DefaultRouteResolver()
    }

    /// Create deep link handlers
    /// - Parameter router: The app router
    /// - Returns: Array of configured deep link handlers
    func makeDeepLinkHandlers(router: Router) -> [DeepLinkHandler] {
        let resolver = makeRouteResolver()

        return [
            UniversalLinkHandler(routeResolver: resolver, router: router),
            CustomURLSchemeHandler(routeResolver: resolver, router: router)
        ]
    }

    // MARK: - Use Case Factory

    /// Create a RestoreSession use case
    /// - Returns: New instance of RestoreSessionUseCase
    func makeRestoreSessionUseCase() -> RestoreSessionUseCase {
        DefaultRestoreSessionUseCase(
            sessionRepository: makeSessionRepository()
        )
    }

    /// Create a ValidateCredentials use case
    /// - Returns: New instance of ValidateCredentialsUseCase
    func makeValidateCredentialsUseCase() -> ValidateCredentialsUseCase {
        DefaultValidateCredentialsUseCase()
    }

    // MARK: - Infrastructure Factory

    /// Create a config loader
    /// - Returns: New instance of ConfigLoader
    func makeConfigLoader() -> ConfigLoader {
        DefaultConfigLoader()
    }

    /// Create a session repository
    /// - Returns: Shared session repository instance
    func makeSessionRepository() -> SessionRepository {
        sharedSessionRepository
    }
}
