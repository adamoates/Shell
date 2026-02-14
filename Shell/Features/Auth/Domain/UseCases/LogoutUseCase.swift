//
//  LogoutUseCase.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import Foundation

/// Use case for logging out user, invalidating session on backend, and clearing local session
protocol LogoutUseCase: Sendable {
    /// Logout current user
    /// - Throws: AuthError on failure
    func execute() async throws
}

/// Default implementation of LogoutUseCase
final class DefaultLogoutUseCase: LogoutUseCase {
    private let authHTTPClient: AuthHTTPClient
    private let sessionRepository: SessionRepository

    init(authHTTPClient: AuthHTTPClient, sessionRepository: SessionRepository) {
        self.authHTTPClient = authHTTPClient
        self.sessionRepository = sessionRepository
    }

    func execute() async throws {
        // Get current session from Keychain
        guard let session = try await sessionRepository.getCurrentSession() else {
            // No session to logout, just return
            return
        }

        do {
            // Call backend logout endpoint to invalidate session
            try await authHTTPClient.logout(
                accessToken: session.accessToken,
                refreshToken: session.refreshToken
            )
        } catch {
            // Even if backend logout fails, clear local session
            // This prevents user from being stuck if backend is unreachable
        }

        // Clear session from Keychain
        try await sessionRepository.clearSession()
    }
}
