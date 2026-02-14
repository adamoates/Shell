import XCTest
@testable import Shell

/// Integration tests for authentication and navigation flow
final class AuthenticationFlowTests: XCTestCase {
    var dependencyContainer: AppDependencyContainer!
    var sessionRepository: SessionRepository!

    override func setUp() async throws {
        try await super.setUp()
        dependencyContainer = AppDependencyContainer()
        sessionRepository = dependencyContainer.makeSessionRepository()

        // Clear any existing session
        try await sessionRepository.clearSession()
    }

    override func tearDown() async throws {
        try await sessionRepository.clearSession()
        dependencyContainer = nil
        sessionRepository = nil
        try await super.tearDown()
    }

    // MARK: - Session Management Tests

    @MainActor
    func testLoginCreatesValidSession() async throws {
        // Arrange
        let validateCredentials = dependencyContainer.makeValidateCredentialsUseCase()
        let mockAuthHTTPClient = MockAuthHTTPClient()
        let loginUseCase = DefaultLoginUseCase(
            authHTTPClient: mockAuthHTTPClient,
            sessionRepository: sessionRepository
        )
        let loginViewModel = LoginViewModel(
            validateCredentials: validateCredentials,
            login: loginUseCase
        )

        loginViewModel.username = "test@example.com"
        loginViewModel.password = "Test123!"

        // Act
        loginViewModel.login()

        // Wait for async login
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second

        // Assert
        let session = try await sessionRepository.getCurrentSession()
        XCTAssertNotNil(session, "Session should exist after login")
        XCTAssertEqual(session?.userId, "test@example.com")
        XCTAssertTrue(session?.isValid ?? false, "Session should be valid")
    }

    func testLogoutClearsSession() async throws {
        // Arrange - Create a session
        let session = UserSession(
            userId: "test@example.com",
            accessToken: "test-token",
            refreshToken: "test-refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        try await sessionRepository.saveSession(session)

        // Verify session exists
        let savedSession = try await sessionRepository.getCurrentSession()
        XCTAssertNotNil(savedSession)

        // Act - Clear session (logout)
        try await sessionRepository.clearSession()

        // Assert
        let clearedSession = try await sessionRepository.getCurrentSession()
        XCTAssertNil(clearedSession, "Session should be nil after logout")
    }

    func testDogCoordinatorRequiresValidSession() async throws {
        // Arrange - No session exists
        let navController = UINavigationController()
        let dogCoordinator = dependencyContainer.makeDogCoordinator(
            navigationController: navController
        )

        var logoutRequested = false
        let mockDelegate = MockDogCoordinatorDelegate { _ in
            logoutRequested = true
        }
        dogCoordinator.delegate = mockDelegate

        // Act - Try to start without session
        dogCoordinator.start()

        // Wait for async validation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        // Assert
        await MainActor.run {
            XCTAssertTrue(logoutRequested, "Should request logout when no valid session")
        }
    }

    @MainActor
    func testDogCoordinatorAllowsAccessWithValidSession() async throws {
        // Arrange - Create valid session
        let session = UserSession(
            userId: "test@example.com",
            accessToken: "test-token",
            refreshToken: "test-refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        try await sessionRepository.saveSession(session)

        // Create a window and navigation controller for proper UIKit lifecycle
        let window = UIWindow(frame: UIScreen.main.bounds)
        let navController = UINavigationController()
        window.rootViewController = navController
        window.makeKeyAndVisible()

        let dogCoordinator = dependencyContainer.makeDogCoordinator(
            navigationController: navController
        )

        var logoutRequested = false
        let mockDelegate = MockDogCoordinatorDelegate { _ in
            logoutRequested = true
        }
        dogCoordinator.delegate = mockDelegate

        // Act - Try to start with valid session
        dogCoordinator.start()

        // Wait for async validation and view controller push
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second to allow animation

        // Assert
        XCTAssertFalse(logoutRequested, "Should not request logout with valid session")
        XCTAssertGreaterThanOrEqual(navController.viewControllers.count, 1, "Should show Dog list")

        // Cleanup
        window.isHidden = true
    }
}

// MARK: - Mock Delegate

private class MockDogCoordinatorDelegate: DogCoordinatorDelegate {
    private let onLogout: (DogCoordinator) -> Void

    init(onLogout: @escaping (DogCoordinator) -> Void) {
        self.onLogout = onLogout
    }

    func dogCoordinatorDidRequestLogout(_ coordinator: DogCoordinator) {
        onLogout(coordinator)
    }
}

// MARK: - Mock AuthHTTPClient

private actor MockAuthHTTPClient: AuthHTTPClient {
    func login(email: String, password: String) async throws -> AuthResponse {
        AuthResponse(
            accessToken: "mock-access-token",
            refreshToken: "mock-refresh-token",
            expiresIn: 900,
            tokenType: "Bearer",
            userID: email
        )
    }

    func refresh(refreshToken: String) async throws -> AuthResponse {
        AuthResponse(
            accessToken: "new-mock-access-token",
            refreshToken: "new-mock-refresh-token",
            expiresIn: 900,
            tokenType: "Bearer",
            userID: "mock-user"
        )
    }

    func logout(accessToken: String, refreshToken: String) async throws {
        // Mock logout - do nothing
    }
}
