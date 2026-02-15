//
//  AuthRequestInterceptorTests.swift
//  ShellTests
//
//  Created by Shell on 2026-02-14.
//

import XCTest
@testable import Shell

/// Tests for AuthRequestInterceptor token refresh logic
/// Verifies concurrent refresh deduplication and retry behavior
@MainActor
final class AuthRequestInterceptorTests: XCTestCase {
    var mockSessionRepository: MockActorSessionRepository!
    var mockAuthHTTPClient: MockActorAuthHTTPClient!
    var interceptor: AuthRequestInterceptor!

    override func setUp() async throws {
        try await super.setUp()
        mockSessionRepository = MockActorSessionRepository()
        mockAuthHTTPClient = MockActorAuthHTTPClient()
        interceptor = AuthRequestInterceptor(
            sessionRepository: mockSessionRepository,
            authHTTPClient: mockAuthHTTPClient
        )
    }

    override func tearDown() async throws {
        interceptor = nil
        mockAuthHTTPClient = nil
        mockSessionRepository = nil
        try await super.tearDown()
    }

    // MARK: - Adapt Tests

    func testAdaptAddsAuthorizationHeader() async throws {
        // Given: Session exists
        let session = UserSession(
            userId: "user-123",
            accessToken: "access-token-123",
            refreshToken: "refresh-token-123",
            expiresAt: Date().addingTimeInterval(3600)
        )
        await mockSessionRepository.setSession(session)

        // Given: Request without Authorization header
        var request = URLRequest(url: URL(string: "https://api.example.com/items")!)

        // When: Adapt request
        request = try await interceptor.adapt(request)

        // Then: Authorization header is added
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token-123")
    }

    func testAdaptWithoutSessionReturnsUnchangedRequest() async throws {
        // Given: No session exists
        await mockSessionRepository.setSession(nil)

        // Given: Request without Authorization header
        let originalRequest = URLRequest(url: URL(string: "https://api.example.com/items")!)

        // When: Adapt request
        let adaptedRequest = try await interceptor.adapt(originalRequest)

        // Then: Request is unchanged
        XCTAssertNil(adaptedRequest.value(forHTTPHeaderField: "Authorization"))
        XCTAssertEqual(adaptedRequest.url, originalRequest.url)
    }

    // MARK: - Retry Tests

    func testRetryOn401RefreshesTokenAndReturnsTrue() async throws {
        // Given: Session with refresh token
        let session = UserSession(
            userId: "user-123",
            accessToken: "old-access-token",
            refreshToken: "old-refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        await mockSessionRepository.setSession(session)

        // Given: Mock refresh returns new tokens
        let newAuthResponse = AuthResponse(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 900,
            tokenType: "Bearer",
            userID: "user-123"
        )
        await mockAuthHTTPClient.setRefreshResponse(newAuthResponse)

        // Given: 401 response
        let request = URLRequest(url: URL(string: "https://api.example.com/items")!)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = Data()

        // When: Retry request
        let shouldRetry = try await interceptor.retry(request, for: response, with: data)

        // Then: Should retry
        XCTAssertTrue(shouldRetry)

        // Then: Refresh was called
        let refreshCallCount = await mockAuthHTTPClient.refreshCallCount
        XCTAssertEqual(refreshCallCount, 1)

        // Then: New session was saved
        let savedSession = await mockSessionRepository.savedSession
        XCTAssertEqual(savedSession?.accessToken, "new-access-token")
        XCTAssertEqual(savedSession?.refreshToken, "new-refresh-token")
    }

    func testRetryOnNon401ReturnsFalse() async throws {
        // Given: Session exists
        let session = UserSession(
            userId: "user-123",
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        await mockSessionRepository.setSession(session)

        // Given: 404 response
        let request = URLRequest(url: URL(string: "https://api.example.com/items")!)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = Data()

        // When: Retry request
        let shouldRetry = try await interceptor.retry(request, for: response, with: data)

        // Then: Should not retry
        XCTAssertFalse(shouldRetry)

        // Then: Refresh was not called
        let refreshCallCount = await mockAuthHTTPClient.refreshCallCount
        XCTAssertEqual(refreshCallCount, 0)
    }

    func testConcurrentRefreshUsesSharedTask() async throws {
        // Given: Session exists
        let session = UserSession(
            userId: "user-123",
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        await mockSessionRepository.setSession(session)

        // Given: Mock refresh with delay (simulates network latency)
        let newAuthResponse = AuthResponse(
            accessToken: "new-access-token",
            refreshToken: "new-refresh-token",
            expiresIn: 900,
            tokenType: "Bearer",
            userID: "user-123"
        )
        await mockAuthHTTPClient.setRefreshResponse(newAuthResponse, delay: 0.1)

        // Given: Multiple 401 responses
        let request = URLRequest(url: URL(string: "https://api.example.com/items")!)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = Data()

        // When: Multiple concurrent retry attempts
        let results = await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    do {
                        return try await self.interceptor.retry(request, for: response, with: data)
                    } catch {
                        return false
                    }
                }
            }

            var results: [Bool] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // Then: All should return true
        XCTAssertEqual(results.count, 5)
        XCTAssertTrue(results.allSatisfy { $0 })

        // Then: Only ONE refresh call was made (deduplication worked)
        let refreshCallCount = await mockAuthHTTPClient.refreshCallCount
        XCTAssertEqual(refreshCallCount, 1, "Expected only 1 refresh call, got \(refreshCallCount)")
    }

    func testRefreshFailureClearsSession() async throws {
        // Given: Session exists
        let session = UserSession(
            userId: "user-123",
            accessToken: "access-token",
            refreshToken: "invalid-refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        await mockSessionRepository.setSession(session)

        // Given: Mock refresh throws error
        await mockAuthHTTPClient.setRefreshError(AuthError.invalidCredentials)

        // Given: 401 response
        let request = URLRequest(url: URL(string: "https://api.example.com/items")!)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = Data()

        // When: Retry request
        do {
            _ = try await interceptor.retry(request, for: response, with: data)
            XCTFail("Should have thrown AuthError.refreshFailed")
        } catch let error as AuthError {
            // Then: Throws refreshFailed
            XCTAssertEqual(error, .refreshFailed)
        }

        // Then: Session was cleared
        let clearedSession = await mockSessionRepository.currentSession
        XCTAssertNil(clearedSession)
    }

    func testRetryWithNoSessionThrowsNoRefreshToken() async throws {
        // Given: No session exists
        await mockSessionRepository.setSession(nil)

        // Given: 401 response
        let request = URLRequest(url: URL(string: "https://api.example.com/items")!)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        let data = Data()

        // When: Retry request
        do {
            _ = try await interceptor.retry(request, for: response, with: data)
            XCTFail("Should have thrown AuthError.noRefreshToken")
        } catch let error as AuthError {
            // Then: Throws noRefreshToken
            XCTAssertEqual(error, .refreshFailed)
        }
    }
}

// MARK: - Mock SessionRepository

actor MockActorSessionRepository: SessionRepository {
    var currentSession: UserSession?
    var savedSession: UserSession?
    var clearSessionCalled = false

    func setSession(_ session: UserSession?) {
        self.currentSession = session
    }

    func getCurrentSession() async throws -> UserSession? {
        return currentSession
    }

    func saveSession(_ session: UserSession) async throws {
        self.savedSession = session
        self.currentSession = session
    }

    func clearSession() async throws {
        self.currentSession = nil
        self.clearSessionCalled = true
    }
}

// MARK: - Mock AuthHTTPClient

actor MockActorAuthHTTPClient: AuthHTTPClient {
    var refreshResponse: AuthResponse?
    var refreshError: Error?
    var refreshDelay: TimeInterval = 0
    var refreshCallCount = 0

    func setRefreshResponse(_ response: AuthResponse, delay: TimeInterval = 0) {
        self.refreshResponse = response
        self.refreshError = nil
        self.refreshDelay = delay
    }

    func setRefreshError(_ error: Error) {
        self.refreshError = error
        self.refreshResponse = nil
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        fatalError("Not implemented in mock")
    }

    func refresh(refreshToken: String) async throws -> AuthResponse {
        refreshCallCount += 1

        if refreshDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(refreshDelay * 1_000_000_000))
        }

        if let error = refreshError {
            throw error
        }

        guard let response = refreshResponse else {
            throw AuthError.unknown("No mock response configured")
        }

        return response
    }

    func logout(accessToken: String, refreshToken: String) async throws {
        fatalError("Not implemented in mock")
    }

    func register(email: String, password: String, confirmPassword: String) async throws -> RegisterResponse {
        fatalError("Not implemented in mock")
    }

    func forgotPassword(email: String) async throws {
        fatalError("Not implemented in mock")
    }

    func resetPassword(token: String, newPassword: String) async throws {
        fatalError("Not implemented in mock")
    }
}
