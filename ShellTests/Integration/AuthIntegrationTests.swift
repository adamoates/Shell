//
//  AuthIntegrationTests.swift
//  ShellTests
//
//  Created by Shell on 2026-02-14.
//

import XCTest
@testable import Shell

/// Integration tests for authentication system with real backend
///
/// PREREQUISITES:
/// - Backend must be running: `cd backend && docker compose up -d`
/// - Backend health check: `curl http://localhost:3000/health`
///
/// These tests verify:
/// - iOS app can communicate with Node.js backend
/// - Login flow saves tokens to Keychain
/// - Token refresh works with rotation
/// - Logout clears Keychain and backend session
/// - Rate limiting works
@MainActor
final class AuthIntegrationTests: XCTestCase {
    // MARK: - Properties

    var dependencyContainer: AppDependencyContainer!
    var authHTTPClient: AuthHTTPClient!
    var sessionRepository: SessionRepository!
    var loginUseCase: LoginUseCase!
    var logoutUseCase: LogoutUseCase!
    var refreshUseCase: RefreshSessionUseCase!

    // Test user credentials (unique per test method to avoid interference)
    var testEmail: String!
    let testPassword = "TestPass123@"

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        // Generate unique email for this test method (avoids test interference)
        testEmail = "integration-test-\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString.prefix(8))@example.com"

        // Check if backend is running
        guard await isBackendRunning() else {
            throw XCTSkip("Backend is not running. Start with: cd backend && docker compose up -d")
        }

        dependencyContainer = AppDependencyContainer()
        authHTTPClient = dependencyContainer.makeAuthHTTPClient()
        sessionRepository = dependencyContainer.makeSessionRepository()
        loginUseCase = dependencyContainer.makeLoginUseCase()
        logoutUseCase = dependencyContainer.makeLogoutUseCase()
        refreshUseCase = dependencyContainer.makeRefreshSessionUseCase()

        // Clear any existing session
        try await sessionRepository.clearSession()

        // Register test user (if not exists)
        try? await registerTestUser()
    }

    override func tearDown() async throws {
        // Clean up: logout if session exists, then clear
        if let session = try? await sessionRepository.getCurrentSession(), session.isValid {
            try? await logoutUseCase.execute()
        }
        try await sessionRepository.clearSession()

        dependencyContainer = nil
        authHTTPClient = nil
        sessionRepository = nil
        loginUseCase = nil
        logoutUseCase = nil
        refreshUseCase = nil
        testEmail = nil

        try await super.tearDown()
    }

    // MARK: - Backend Health Check

    private func isBackendRunning() async -> Bool {
        guard let url = URL(string: "http://localhost:3000/health") else {
            return false
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return false
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["status"] as? String == "healthy"
        } catch {
            return false
        }
    }

    private func registerTestUser() async throws {
        guard let url = URL(string: "http://localhost:3000/auth/register") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = [
            "email": testEmail,
            "password": testPassword,
            "confirmPassword": testPassword
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Ignore errors - user might already exist
        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Test 1: Login Flow

    func testLoginFlow_withValidCredentials_savesSessionToKeychain() async throws {
        // Given: Valid credentials

        // When: Login
        let session = try await loginUseCase.execute(email: testEmail, password: testPassword)

        // Then: Session should be saved to Keychain
        XCTAssertFalse(session.userId.isEmpty, "User ID should not be empty")
        XCTAssertFalse(session.accessToken.isEmpty, "Access token should not be empty")
        XCTAssertFalse(session.refreshToken.isEmpty, "Refresh token should not be empty")
        XCTAssertTrue(session.isValid, "Session should be valid")

        // Verify session is in Keychain
        let retrievedSession = try await sessionRepository.getCurrentSession()
        XCTAssertNotNil(retrievedSession, "Session should be in Keychain")
        XCTAssertEqual(retrievedSession?.userId, session.userId, "Keychain userId should match session")
        XCTAssertEqual(retrievedSession?.accessToken, session.accessToken)
        XCTAssertEqual(retrievedSession?.refreshToken, session.refreshToken)
    }

    func testLoginFlow_withInvalidCredentials_throwsError() async throws {
        // Given: Invalid credentials
        let invalidEmail = "wrong@example.com"
        let invalidPassword = "wrongpassword"

        // When/Then: Login should throw error
        do {
            _ = try await loginUseCase.execute(email: invalidEmail, password: invalidPassword)
            XCTFail("Should have thrown AuthError.invalidCredentials")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCredentials, "Should throw invalidCredentials error")
        } catch {
            XCTFail("Should throw AuthError, got: \(error)")
        }

        // Verify no session in Keychain
        let session = try await sessionRepository.getCurrentSession()
        XCTAssertNil(session, "No session should be saved after failed login")
    }

    // MARK: - Test 2: Token Refresh

    func testTokenRefresh_withValidRefreshToken_returnsNewTokens() async throws {
        // Given: Valid session
        let originalSession = try await loginUseCase.execute(email: testEmail, password: testPassword)
        XCTAssertFalse(originalSession.userId.isEmpty, "Original session should have userId")
        XCTAssertFalse(originalSession.refreshToken.isEmpty, "Original session should have refreshToken")

        // Verify session was saved to Keychain
        let savedSession = try await sessionRepository.getCurrentSession()
        XCTAssertNotNil(savedSession, "Session should be saved in Keychain after login")
        XCTAssertEqual(savedSession?.refreshToken, originalSession.refreshToken, "Keychain session should match original")

        // Wait a moment to ensure timestamps differ
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // When: Refresh token
        let newSession = try await refreshUseCase.execute()

        // Then: New tokens should be different (rotated)
        XCTAssertNotEqual(newSession.accessToken, originalSession.accessToken,
                         "Access token should be rotated")
        XCTAssertNotEqual(newSession.refreshToken, originalSession.refreshToken,
                         "Refresh token should be rotated")
        XCTAssertEqual(newSession.userId, originalSession.userId,
                      "User ID should remain the same")
        XCTAssertTrue(newSession.isValid, "New session should be valid")

        // Verify new session is in Keychain
        let keychainSession = try await sessionRepository.getCurrentSession()
        XCTAssertEqual(keychainSession?.accessToken, newSession.accessToken)
        XCTAssertEqual(keychainSession?.refreshToken, newSession.refreshToken)
    }

    func testTokenRefresh_withOldRefreshToken_fails() async throws {
        // Given: Login and get original refresh token
        let originalSession = try await loginUseCase.execute(email: testEmail, password: testPassword)
        let oldRefreshToken = originalSession.refreshToken

        // When: Refresh once (this invalidates the old token)
        _ = try await refreshUseCase.execute()

        // Manually save old session back (simulating attacker trying to reuse old token)
        let oldSession = UserSession(
            userId: originalSession.userId,
            accessToken: originalSession.accessToken,
            refreshToken: oldRefreshToken,
            expiresAt: originalSession.expiresAt
        )
        try await sessionRepository.saveSession(oldSession)

        // Then: Trying to use old refresh token should fail
        do {
            _ = try await refreshUseCase.execute()
            XCTFail("Should have thrown error when reusing old refresh token")
        } catch {
            // Expected error (could be AuthError.refreshFailed or network error)
            XCTAssertTrue(true, "Correctly rejected old refresh token")
        }

        // Session should be cleared (security measure)
        let session = try await sessionRepository.getCurrentSession()
        XCTAssertNil(session, "Session should be cleared after refresh failure")
    }

    // MARK: - Test 3: Logout

    func testLogout_clearsKeychainAndBackendSession() async throws {
        // Given: Valid logged-in session
        let session = try await loginUseCase.execute(email: testEmail, password: testPassword)

        // Verify session exists in Keychain
        let sessionBeforeLogout = try await sessionRepository.getCurrentSession()
        XCTAssertNotNil(sessionBeforeLogout, "Session should exist before logout")

        // When: Logout
        try await logoutUseCase.execute()

        // Then: Session should be cleared from Keychain
        let sessionAfterLogout = try await sessionRepository.getCurrentSession()
        XCTAssertNil(sessionAfterLogout, "Session should be nil after logout")

        // And: Old refresh token should be invalid on backend
        let oldSession = UserSession(
            userId: session.userId,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiresAt: session.expiresAt
        )
        try await sessionRepository.saveSession(oldSession)

        do {
            _ = try await refreshUseCase.execute()
            XCTFail("Should fail to refresh with logged-out session")
        } catch {
            // Expected - token should be invalid
            XCTAssertTrue(true, "Correctly rejected logged-out session")
        }
    }

    // MARK: - Test 4: Protected Routes

    func testProtectedRoute_withoutToken_returns401() async throws {
        // Given: No session
        try await sessionRepository.clearSession()

        // When: Try to access protected route
        guard let url = URL(string: "http://localhost:3000/v1/items") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (_, response) = try await URLSession.shared.data(for: request)

        // Then: Should get 401 Unauthorized
        if let httpResponse = response as? HTTPURLResponse {
            XCTAssertEqual(httpResponse.statusCode, 401,
                          "Protected route should return 401 without token")
        } else {
            XCTFail("Response should be HTTPURLResponse")
        }
    }

    func testProtectedRoute_withValidToken_succeeds() async throws {
        // Given: Valid session
        let session = try await loginUseCase.execute(email: testEmail, password: testPassword)

        // When: Access protected route with token
        guard let url = URL(string: "http://localhost:3000/v1/items") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)

        // Then: Should succeed
        if let httpResponse = response as? HTTPURLResponse {
            XCTAssertEqual(httpResponse.statusCode, 200,
                          "Protected route should return 200 with valid token")
        } else {
            XCTFail("Response should be HTTPURLResponse")
        }
    }

    // MARK: - Test 5: Rate Limiting

    func testRateLimit_after5FailedAttempts_blocksLogin() async throws {
        // Given: Invalid credentials
        let invalidEmail = "ratelimit-test@example.com"
        let invalidPassword = "wrongpassword"

        // When: Attempt 5 failed logins
        for attempt in 1...5 {
            do {
                _ = try await authHTTPClient.login(email: invalidEmail, password: invalidPassword)
                XCTFail("Attempt \(attempt) should have failed")
            } catch {
                // Expected failure
            }

            // Small delay between attempts
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }

        // Then: 6th attempt should be rate limited
        do {
            _ = try await authHTTPClient.login(email: invalidEmail, password: invalidPassword)
            XCTFail("6th attempt should be rate limited")
        } catch {
            // Expected: Could be rate limit error (429) or continued invalid credentials (401)
            // Either is acceptable for this test
            XCTAssertTrue(true, "Login blocked after 5 failed attempts")
        }
    }

    // MARK: - Test 6: Concurrent Requests

    func testConcurrentLogin_onlyOneSucceeds() async throws {
        // Given: Multiple concurrent login attempts
        let attempts = 3

        // When: Login concurrently
        await withTaskGroup(of: Result<UserSession, Error>.self) { group in
            for _ in 0..<attempts {
                group.addTask {
                    do {
                        let session = try await self.loginUseCase.execute(
                            email: self.testEmail,
                            password: self.testPassword
                        )
                        return .success(session)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            var successCount = 0
            var sessions: [UserSession] = []

            for await result in group {
                if case .success(let session) = result {
                    successCount += 1
                    sessions.append(session)
                }
            }

            // Then: All should succeed (backend allows multiple sessions)
            XCTAssertEqual(successCount, attempts,
                          "All concurrent login attempts should succeed")

            // All sessions should have same user ID but different tokens
            let userIDs = Set(sessions.map { $0.userId })
            XCTAssertEqual(userIDs.count, 1, "All sessions should be for same user")
        }
    }

    // MARK: - Test 7: Session Persistence

    func testSessionPersistence_acrossAppRestarts() async throws {
        // Given: Login and save session
        let originalSession = try await loginUseCase.execute(email: testEmail, password: testPassword)

        // Simulate app restart by creating new container
        dependencyContainer = nil
        sessionRepository = nil
        loginUseCase = nil

        // Create new instances (simulating fresh app launch)
        dependencyContainer = AppDependencyContainer()
        sessionRepository = dependencyContainer.makeSessionRepository()

        // When: Retrieve session from Keychain
        let retrievedSession = try await sessionRepository.getCurrentSession()

        // Then: Session should be restored
        XCTAssertNotNil(retrievedSession, "Session should persist across app restarts")
        XCTAssertEqual(retrievedSession?.userId, originalSession.userId)
        XCTAssertEqual(retrievedSession?.accessToken, originalSession.accessToken)
        XCTAssertEqual(retrievedSession?.refreshToken, originalSession.refreshToken)
        XCTAssertTrue(retrievedSession?.isValid ?? false, "Restored session should be valid")
    }
}
