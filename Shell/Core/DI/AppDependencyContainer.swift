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
    /// Uses KeychainSessionRepository for secure, persistent storage
    private lazy var sharedSessionRepository: SessionRepository = KeychainSessionRepository()

    /// Shared user profile repository (singleton pattern)
    /// Profile data must be shared across the app
    /// Uses feature flag to switch between in-memory, remote, and Core Data implementations
    private lazy var sharedUserProfileRepository: UserProfileRepository = {
        if RepositoryConfig.useCoreDataUserProfileRepository {
            // Use Core Data repository for local persistence
            return CoreDataUserProfileRepository(
                stack: makeCoreDataStack(),
                logger: makeLogger()
            )
        } else if RepositoryConfig.useRemoteRepository {
            // Use remote repository with HTTP client
            let httpClient = URLSessionHTTPClient()
            return RemoteUserProfileRepository(
                httpClient: httpClient,
                baseURL: APIConfig.current.baseURL,
                authToken: APIConfig.current.authToken,
                logger: makeLogger()
            )
        } else {
            // Use in-memory repository for offline development
            return InMemoryUserProfileRepository()
        }
    }()

    /// Shared items repository (singleton pattern)
    /// Items data must be shared across the app
    /// Uses feature flag to switch between in-memory, HTTP, and Core Data implementations
    private lazy var sharedItemsRepository: ItemsRepository = {
        if RepositoryConfig.useCoreDataItemsRepository {
            // Use Core Data repository for local persistence
            return CoreDataItemsRepository(stack: makeCoreDataStack())
        } else if RepositoryConfig.useHTTPItemsRepository {
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

    /// Shared network monitor (singleton pattern)
    /// Network connectivity state must be shared across the app
    private lazy var sharedNetworkMonitor = NetworkMonitor()

    /// Shared dog repository (singleton pattern)
    /// Dog data must be shared across the app
    /// Currently uses in-memory storage (can be upgraded to Core Data/HTTP later)
    private lazy var sharedDogRepository: DogRepository = InMemoryDogRepository()

    /// Shared Core Data stack (singleton pattern)
    /// Core Data stack must be shared across the app for consistent persistence
    private lazy var sharedCoreDataStack: CoreDataStack = {
        // Create Core Data stack asynchronously with synchronous bridge
        // This blocks during initialization, which is acceptable for DI container setup
        var stack: CoreDataStack?
        let semaphore = DispatchSemaphore(value: 0)

        Task {
            do {
                stack = try await CoreDataStack(
                    modelName: "Shell",
                    inMemory: false,
                    logger: makeLogger()
                )
            } catch {
                // Fallback to in-memory stack if persistent store fails
                let logger = makeLogger()
                Task { @MainActor in
                    logger.error("Failed to load Core Data persistent store, using in-memory fallback: \(error.localizedDescription)")
                }
                do {
                    stack = try await CoreDataStack(
                        modelName: "Shell",
                        inMemory: true,
                        logger: logger
                    )
                } catch {
                    preconditionFailure("Failed to initialize Core Data stack (even in-memory fallback failed): \(error)")
                }
            }
            semaphore.signal()
        }

        semaphore.wait()
        guard let finalStack = stack else {
            preconditionFailure("Core Data stack was not initialized")
        }
        return finalStack
    }()

    // MARK: - Auth Infrastructure

    /// Shared auth HTTP client (singleton pattern)
    /// Auth client must be shared for consistent auth state
    private lazy var sharedAuthHTTPClient: AuthHTTPClient = {
        // Auth endpoints are at root level (/auth/*), not under /v1
        // Remove /v1 suffix from base URL for auth client
        let baseURL = APIConfig.current.baseURL
        let authBaseURL = baseURL.deletingLastPathComponent()

        return URLSessionAuthHTTPClient(
            session: .shared,
            baseURL: authBaseURL
        )
    }()

    /// Shared auth request interceptor (singleton pattern)
    /// Interceptor must be shared to coordinate token refresh across concurrent requests
    private lazy var sharedAuthInterceptor: AuthRequestInterceptor = {
        AuthRequestInterceptor(
            sessionRepository: makeSessionRepository(),
            authHTTPClient: makeAuthHTTPClient()
        )
    }()

    /// Shared authenticated HTTP client (singleton pattern)
    /// HTTP client must be shared for consistent auth state and request interception
    private lazy var sharedAuthenticatedHTTPClient: AuthenticatedHTTPClient = {
        AuthenticatedHTTPClient(
            session: .shared,
            interceptor: makeAuthInterceptor()
        )
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
            dependencyContainer: self,
            logger: makeLogger()
        )
    }

    /// Create an auth coordinator
    /// - Parameter navigationController: The navigation controller to use
    /// - Returns: Configured auth coordinator
    func makeAuthCoordinator(navigationController: UINavigationController) -> AuthCoordinator {
        AuthCoordinator(
            navigationController: navigationController,
            validateCredentials: makeValidateCredentialsUseCase(),
            login: makeLoginUseCase(),
            register: makeRegisterUseCase(),
            logger: makeLogger()
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
            deleteItem: makeDeleteItemUseCase(),
            networkMonitor: makeNetworkMonitor(),
            logger: makeLogger()
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

    /// Create a dog coordinator
    /// - Parameter navigationController: The navigation controller to use
    /// - Returns: Configured dog coordinator
    func makeDogCoordinator(navigationController: UINavigationController) -> DogCoordinator {
        DogCoordinator(
            navigationController: navigationController,
            dependencyContainer: self
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
            routeResolver: makeRouteResolver(),
            logger: makeLogger()
        )
    }

    /// Create an auth guard for route access control
    /// - Returns: Configured auth guard
    func makeAuthGuard() -> RouteAccessControl {
        AuthGuard(
            sessionRepository: makeSessionRepository(),
            logger: makeLogger()
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
        let logger = makeLogger()

        return [
            UniversalLinkHandler(routeResolver: resolver, router: router, logger: logger),
            CustomURLSchemeHandler(routeResolver: resolver, router: router, logger: logger)
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

    /// Create a Login use case
    /// - Returns: New instance of LoginUseCase
    func makeLoginUseCase() -> LoginUseCase {
        DefaultLoginUseCase(
            authHTTPClient: makeAuthHTTPClient(),
            sessionRepository: makeSessionRepository()
        )
    }

    /// Create a Logout use case
    /// - Returns: New instance of LogoutUseCase
    func makeLogoutUseCase() -> LogoutUseCase {
        DefaultLogoutUseCase(
            authHTTPClient: makeAuthHTTPClient(),
            sessionRepository: makeSessionRepository()
        )
    }

    /// Create a RefreshSession use case
    /// - Returns: New instance of RefreshSessionUseCase
    func makeRefreshSessionUseCase() -> RefreshSessionUseCase {
        DefaultRefreshSessionUseCase(
            authHTTPClient: makeAuthHTTPClient(),
            sessionRepository: makeSessionRepository()
        )
    }

    /// Create a Register use case
    /// - Returns: New instance of RegisterUseCase
    func makeRegisterUseCase() -> RegisterUseCase {
        DefaultRegisterUseCase(
            authHTTPClient: makeAuthHTTPClient()
        )
    }

    /// Create a ForgotPassword use case
    /// - Returns: New instance of ForgotPasswordUseCase
    func makeForgotPasswordUseCase() -> ForgotPasswordUseCase {
        DefaultForgotPasswordUseCase(
            authHTTPClient: makeAuthHTTPClient()
        )
    }

    /// Create a ResetPassword use case
    /// - Returns: New instance of ResetPasswordUseCase
    func makeResetPasswordUseCase() -> ResetPasswordUseCase {
        DefaultResetPasswordUseCase(
            authHTTPClient: makeAuthHTTPClient()
        )
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

    // MARK: - Dog Use Cases

    func makeFetchDogsUseCase() -> FetchDogsUseCase {
        DefaultFetchDogsUseCase(repository: makeDogRepository())
    }

    func makeCreateDogUseCase() -> CreateDogUseCase {
        DefaultCreateDogUseCase(repository: makeDogRepository())
    }

    func makeUpdateDogUseCase() -> UpdateDogUseCase {
        DefaultUpdateDogUseCase(repository: makeDogRepository())
    }

    func makeDeleteDogUseCase() -> DeleteDogUseCase {
        DefaultDeleteDogUseCase(repository: makeDogRepository())
    }

    // MARK: - Dog ViewModels

    @MainActor
    func makeDogListViewModel() -> DogListViewModel {
        DogListViewModel(
            fetchDogsUseCase: makeFetchDogsUseCase(),
            deleteDogUseCase: makeDeleteDogUseCase()
        )
    }

    @MainActor
    func makeDogEditorViewModel(dog: Dog? = nil) -> DogEditorViewModel {
        DogEditorViewModel(
            dog: dog,
            createDogUseCase: makeCreateDogUseCase(),
            updateDogUseCase: makeUpdateDogUseCase()
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

    /// Create a dog repository
    /// - Returns: Shared dog repository instance
    func makeDogRepository() -> DogRepository {
        sharedDogRepository
    }

    /// Create a network monitor
    /// - Returns: Shared network monitor instance
    func makeNetworkMonitor() -> NetworkMonitor {
        sharedNetworkMonitor
    }

    /// Create Core Data stack
    /// - Returns: Shared Core Data stack instance
    func makeCoreDataStack() -> CoreDataStack {
        sharedCoreDataStack
    }

    /// Create auth HTTP client
    /// - Returns: Shared auth HTTP client instance
    func makeAuthHTTPClient() -> AuthHTTPClient {
        sharedAuthHTTPClient
    }

    /// Create auth request interceptor
    /// - Returns: Shared auth request interceptor instance
    func makeAuthInterceptor() -> AuthRequestInterceptor {
        sharedAuthInterceptor
    }

    /// Create authenticated HTTP client
    /// - Returns: Shared authenticated HTTP client instance
    func makeAuthenticatedHTTPClient() -> AuthenticatedHTTPClient {
        sharedAuthenticatedHTTPClient
    }
}
