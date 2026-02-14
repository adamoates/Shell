//
//  RefreshSessionUseCase.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import Foundation

/// Use case for refreshing access token using refresh token
protocol RefreshSessionUseCase: Sendable {
    /// Refresh the current session
    /// - Returns: New UserSession with rotated tokens
    /// - Throws: AuthError on failure
    func execute() async throws -> UserSession
}

/// Default implementation of RefreshSessionUseCase
final class DefaultRefreshSessionUseCase: RefreshSessionUseCase {
    private let authHTTPClient: AuthHTTPClient
    private let sessionRepository: SessionRepository

    init(authHTTPClient: AuthHTTPClient, sessionRepository: SessionRepository) {
        self.authHTTPClient = authHTTPClient
        self.sessionRepository = sessionRepository
    }

    func execute() async throws -> UserSession {
        // Get current session from Keychain
        guard let currentSession = try await sessionRepository.getCurrentSession() else {
            throw AuthError.noRefreshToken
        }

        do {
            // Call backend refresh endpoint with refresh token
            let response = try await authHTTPClient.refresh(refreshToken: currentSession.refreshToken)

            // Convert response to new session (tokens are rotated)
            let newSession = response.session

            // Save new session to Keychain (replaces old session)
            try await sessionRepository.saveSession(newSession)

            return newSession
        } catch {
            // Security: Clear session on refresh failure (token might be compromised)
            // This protects against token reuse attacks
            try? await sessionRepository.clearSession()
            throw error
        }
    }
}
