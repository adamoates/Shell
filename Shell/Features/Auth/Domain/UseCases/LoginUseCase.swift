//
//  LoginUseCase.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import Foundation

/// Use case for authenticating user with backend and persisting session
protocol LoginUseCase: Sendable {
    /// Login with email and password
    /// - Parameters:
    ///   - email: User email address
    ///   - password: User password
    /// - Returns: UserSession with access and refresh tokens
    /// - Throws: AuthError on failure
    func execute(email: String, password: String) async throws -> UserSession
}

/// Default implementation of LoginUseCase
final class DefaultLoginUseCase: LoginUseCase {
    private let authHTTPClient: AuthHTTPClient
    private let sessionRepository: SessionRepository

    init(authHTTPClient: AuthHTTPClient, sessionRepository: SessionRepository) {
        self.authHTTPClient = authHTTPClient
        self.sessionRepository = sessionRepository
    }

    func execute(email: String, password: String) async throws -> UserSession {
        // Call backend login endpoint
        let response = try await authHTTPClient.login(email: email, password: password)

        // Convert response to session
        let session = response.session

        // Save session to Keychain
        try await sessionRepository.saveSession(session)

        return session
    }
}
