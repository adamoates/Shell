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

    /// Shared logger (singleton pattern)
    /// Logger must be shared across the app for consistent subsystem/category organization
    private lazy var sharedLogger: Logger = OSLogLogger(
        subsystem: "com.adamcodertrader.Shell",
        defaultCategory: "general"
    )

    /// Shared session repository (singleton pattern)
    /// Session state must be shared across the app
    private lazy var sharedSessionRepository: SessionRepository = InMemorySessionRepository()

    /// Shared user profile repository (singleton pattern)
    /// Profile data must be shared across the app
    /// Uses feature flag to switch between in-memory and remote implementation
    private lazy var sharedUserProfileRepository: UserProfileRepository = {
        if RepositoryConfig.useRemoteRepository {
            // Use remote repository with HTTP client
            let httpClient = URLSessionHTTPClient()
            return RemoteUserProfileRepository(
                httpClient: httpClient,
                baseURL: APIConfig.current.baseURL,
                authToken: APIConfig.current.authToken
            )
        } else {
            // Use in-memory repository for offline development
            return InMemoryUserProfileRepository()
        }
    }()

    /// Shared items repository (singleton pattern)
    /// Items data must be shared across the app
    /// Uses feature flag to switch between in-memory and HTTP implementation
    private lazy var sharedItemsRepository: ItemsRepository = {
        if RepositoryConfig.useHTTPItemsRepository {
            // Use HTTP repository with backend API
            let httpClient = URLSessionItemsHTTPClient(
                session: .shared,
                baseURL: APIConfig.current.baseURL
            )
            return HTTPItemsRepository(httpClient: httpClient)
        } else {
            // Use in-memory repository for offline development
            return InMemoryItemsRepository()
        }
    }()

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
        ItemsCoordinator(
            navigationController: navigationController,
            fetchItems: makeFetchItemsUseCase(),
            createItem: makeCreateItemUseCase(),
            updateItem: makeUpdateItemUseCase(),
            deleteItem: makeDeleteItemUseCase()
        )
    }

    /// Create a profile coordinator
    /// - Parameters:
    ///   - navigationController: The navigation controller to use
    ///   - userID: The user's ID
    /// - Returns: Configured profile coordinator
    func makeProfileCoordinator(navigationController: UINavigationController, userID: String) -> ProfileCoordinator {
        ProfileCoordinator(
            navigationController: navigationController,
            userID: userID,
            fetchProfile: makeFetchProfileUseCase(),
            setupIdentity: makeCompleteIdentitySetupUseCase()
        )
    }

    /// Create an identity setup coordinator
    /// - Parameters:
    ///   - navigationController: The navigation controller to use
    ///   - userID: The user's ID
    ///   - startStep: Optional starting step
    /// - Returns: Configured identity setup coordinator
    func makeIdentitySetupCoordinator(
        navigationController: UINavigationController,
        userID: String,
        startStep: IdentityStep? = nil
    ) -> IdentitySetupCoordinator {
        IdentitySetupCoordinator(
            navigationController: navigationController,
            userID: userID,
            completeIdentitySetup: makeCompleteIdentitySetupUseCase(),
            startStep: startStep
        )
    }

    // MARK: - Navigation Factory

    /// Create the app router
    /// - Parameter coordinator: The app coordinator
    /// - Returns: Configured app router
    func makeAppRouter(coordinator: AppCoordinator) -> Router {
        AppRouter(
            coordinator: coordinator,
            accessControl: makeAuthGuard(),
            routeResolver: makeRouteResolver()
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

    /// Create a FetchItems use case
    /// - Returns: New instance of FetchItemsUseCase
    func makeFetchItemsUseCase() -> FetchItemsUseCase {
        DefaultFetchItemsUseCase(repository: makeItemsRepository())
    }

    /// Create a CreateItem use case
    /// - Returns: New instance of CreateItemUseCase
    func makeCreateItemUseCase() -> CreateItemUseCase {
        DefaultCreateItemUseCase(repository: makeItemsRepository())
    }

    /// Create an UpdateItem use case
    /// - Returns: New instance of UpdateItemUseCase
    func makeUpdateItemUseCase() -> UpdateItemUseCase {
        DefaultUpdateItemUseCase(repository: makeItemsRepository())
    }

    /// Create a DeleteItem use case
    /// - Returns: New instance of DeleteItemUseCase
    func makeDeleteItemUseCase() -> DeleteItemUseCase {
        DefaultDeleteItemUseCase(repository: makeItemsRepository())
    }

    /// Create a FetchProfile use case
    /// - Returns: New instance of FetchProfileUseCase
    func makeFetchProfileUseCase() -> FetchProfileUseCase {
        DefaultFetchProfileUseCase(
            repository: makeUserProfileRepository()
        )
    }

    /// Create a CompleteIdentitySetup use case
    /// - Returns: New instance of CompleteIdentitySetupUseCase
    func makeCompleteIdentitySetupUseCase() -> CompleteIdentitySetupUseCase {
        DefaultCompleteIdentitySetupUseCase(
            repository: makeUserProfileRepository()
        )
    }

    // MARK: - Infrastructure Factory

    /// Create a logger
    /// - Returns: Shared logger instance
    func makeLogger() -> Logger {
        sharedLogger
    }

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

    /// Create a user profile repository
    /// - Returns: Shared user profile repository instance
    func makeUserProfileRepository() -> UserProfileRepository {
        sharedUserProfileRepository
    }

    /// Create an items repository
    /// - Returns: Shared items repository instance
    func makeItemsRepository() -> ItemsRepository {
        sharedItemsRepository
    }
}
