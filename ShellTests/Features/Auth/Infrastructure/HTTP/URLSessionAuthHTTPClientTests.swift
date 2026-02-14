//
//  URLSessionAuthHTTPClientTests.swift
//  ShellTests
//
//  Created by Shell on 2026-02-14.
//

import XCTest
@testable import Shell

/// Tests for URLSessionAuthHTTPClient
/// Verifies login, refresh, and logout endpoint integration
@MainActor
final class URLSessionAuthHTTPClientTests: XCTestCase {
    var client: URLSessionAuthHTTPClient!
    var mockURLSession: URLSession!
    var baseURL: URL!

    override func setUp() async throws {
        try await super.setUp()

        // Setup mock URL session
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration)

        baseURL = URL(string: "http://localhost:3000")!
        client = URLSessionAuthHTTPClient(session: mockURLSession, baseURL: baseURL)
    }

    override func tearDown() async throws {
        MockURLProtocol.reset()
        client = nil
        mockURLSession = nil
        try await super.tearDown()
    }

    // MARK: - Login Tests

    func testLoginSuccess() async throws {
        // Given: Successful login response
        let responseJSON = """
        {
            "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
            "refreshToken": "refresh-token-uuid",
            "expiresIn": 900,
            "tokenType": "Bearer",
            "userID": "user-123"
        }
        """
        let data = responseJSON.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: baseURL.appendingPathComponent("/auth/login"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        MockURLProtocol.mockResponse = (data, response, nil)

        // When: Login
        let authResponse = try await client.login(email: "user@example.com", password: "password123")

        // Then: Returns auth response
        XCTAssertEqual(authResponse.accessToken, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9")
        XCTAssertEqual(authResponse.refreshToken, "refresh-token-uuid")
        XCTAssertEqual(authResponse.expiresIn, 900)
        XCTAssertEqual(authResponse.tokenType, "Bearer")
        XCTAssertEqual(authResponse.userID, "user-123")
    }

    func testLoginInvalidCredentialsThrowsError() async throws {
        // Given: 401 Unauthorized response
        let data = Data()
        let response = HTTPURLResponse(
            url: baseURL.appendingPathComponent("/auth/login"),
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!

        MockURLProtocol.mockResponse = (data, response, nil)

        // When: Login with invalid credentials
        do {
            _ = try await client.login(email: "user@example.com", password: "wrong")
            XCTFail("Should have thrown AuthError.invalidCredentials")
        } catch let error as AuthError {
            // Then: Throws invalidCredentials
            XCTAssertEqual(error, .invalidCredentials)
        }
    }

    // MARK: - Refresh Tests

    func testRefreshSuccess() async throws {
        // Given: Successful refresh response
        let responseJSON = """
        {
            "accessToken": "new-access-token",
            "refreshToken": "new-refresh-token",
            "expiresIn": 900,
            "tokenType": "Bearer",
            "userID": "user-123"
        }
        """
        let data = responseJSON.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: baseURL.appendingPathComponent("/auth/refresh"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!

        MockURLProtocol.mockResponse = (data, response, nil)

        // When: Refresh token
        let authResponse = try await client.refresh(refreshToken: "old-refresh-token")

        // Then: Returns new tokens
        XCTAssertEqual(authResponse.accessToken, "new-access-token")
        XCTAssertEqual(authResponse.refreshToken, "new-refresh-token")
        XCTAssertEqual(authResponse.expiresIn, 900)
    }

    func testRefreshInvalidTokenThrowsError() async throws {
        // Given: 401 Unauthorized response
        let data = Data()
        let response = HTTPURLResponse(
            url: baseURL.appendingPathComponent("/auth/refresh"),
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!

        MockURLProtocol.mockResponse = (data, response, nil)

        // When: Refresh with invalid token
        do {
            _ = try await client.refresh(refreshToken: "invalid-token")
            XCTFail("Should have thrown AuthError.invalidCredentials")
        } catch let error as AuthError {
            // Then: Throws invalidCredentials
            XCTAssertEqual(error, .invalidCredentials)
        }
    }

    // MARK: - Logout Tests

    func testLogoutSuccess() async throws {
        // Given: Successful logout response
        let data = Data()
        let response = HTTPURLResponse(
            url: baseURL.appendingPathComponent("/auth/logout"),
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        MockURLProtocol.mockResponse = (data, response, nil)

        // When: Logout
        try await client.logout(accessToken: "access-token", refreshToken: "refresh-token")

        // Then: No error thrown
        // Success indicated by not throwing
    }

    func testLogoutUnauthorizedThrowsError() async throws {
        // Given: 401 Unauthorized response
        let data = Data()
        let response = HTTPURLResponse(
            url: baseURL.appendingPathComponent("/auth/logout"),
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!

        MockURLProtocol.mockResponse = (data, response, nil)

        // When: Logout with invalid token
        do {
            try await client.logout(accessToken: "invalid", refreshToken: "invalid")
            XCTFail("Should have thrown AuthError.invalidCredentials")
        } catch let error as AuthError {
            // Then: Throws invalidCredentials
            XCTAssertEqual(error, .invalidCredentials)
        }
    }

    // MARK: - AuthResponse to UserSession Conversion

    func testAuthResponseConvertsToSession() {
        // Given: AuthResponse
        let authResponse = AuthResponse(
            accessToken: "access-token",
            refreshToken: "refresh-token",
            expiresIn: 900,
            tokenType: "Bearer",
            userID: "user-123"
        )

        // When: Convert to session
        let session = authResponse.session

        // Then: Session is created correctly
        XCTAssertEqual(session.userId, "user-123")
        XCTAssertEqual(session.accessToken, "access-token")
        XCTAssertEqual(session.refreshToken, "refresh-token")
        XCTAssertTrue(session.isValid)

        // Check expiration is approximately 900 seconds from now
        let expectedExpiry = Date().addingTimeInterval(900)
        let timeDifference = abs(session.expiresAt.timeIntervalSince(expectedExpiry))
        XCTAssertLessThan(timeDifference, 1.0, "Expiry time should be within 1 second")
    }
}
