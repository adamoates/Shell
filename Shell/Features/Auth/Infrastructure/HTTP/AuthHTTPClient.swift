//
//  AuthHTTPClient.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import Foundation

/// HTTP client abstraction for Authentication network requests
/// Follows the OAuth 2.0 token refresh pattern
protocol AuthHTTPClient: Sendable {
    /// Login with email and password
    /// - Parameters:
    ///   - email: User email address
    ///   - password: User password
    /// - Returns: Authentication response with tokens
    /// - Throws: AuthError on failure
    func login(email: String, password: String) async throws -> AuthResponse

    /// Refresh access token using refresh token
    /// - Parameter refreshToken: The refresh token from the current session
    /// - Returns: New authentication response with rotated tokens
    /// - Throws: AuthError on failure
    func refresh(refreshToken: String) async throws -> AuthResponse

    /// Logout and invalidate session
    /// - Parameters:
    ///   - accessToken: Current access token
    ///   - refreshToken: Current refresh token
    /// - Throws: AuthError on failure
    func logout(accessToken: String, refreshToken: String) async throws
}

/// Authentication response from the backend
struct AuthResponse: Sendable, Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int // Seconds until expiry
    let tokenType: String
    let userID: String // Backend uses capital D, not userId

    /// Convert response to UserSession entity
    var session: UserSession {
        UserSession(
            userId: userID, // Map userID to userId in domain entity
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(expiresIn))
        )
    }
}

// MARK: - DTOs (Data Transfer Objects)

/// Login request DTO
struct LoginRequest: Codable {
    let email: String
    let password: String
}

/// Refresh token request DTO
struct RefreshRequest: Codable {
    let refreshToken: String
}

/// Logout request DTO
struct LogoutRequest: Codable {
    let refreshToken: String
}
