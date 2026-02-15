//
//  RegisterUseCase.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import Foundation

/// Use case for registering a new user account
protocol RegisterUseCase: Sendable {
    /// Register a new user with email and password
    /// - Parameters:
    ///   - email: User email address
    ///   - password: User password
    ///   - confirmPassword: Password confirmation (must match password)
    /// - Returns: User ID of newly created account
    /// - Throws: AuthError on failure
    func execute(email: String, password: String, confirmPassword: String) async throws -> String
}

/// Default implementation of RegisterUseCase
final class DefaultRegisterUseCase: RegisterUseCase {
    private let authHTTPClient: AuthHTTPClient

    init(authHTTPClient: AuthHTTPClient) {
        self.authHTTPClient = authHTTPClient
    }

    func execute(email: String, password: String, confirmPassword: String) async throws -> String {
        // Client-side validation
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }

        guard password.count >= 8 else {
            throw AuthError.passwordTooShort(minimumLength: 8)
        }

        guard password == confirmPassword else {
            throw AuthError.passwordMismatch
        }

        // Call backend registration endpoint
        do {
            let response = try await authHTTPClient.register(
                email: email,
                password: password,
                confirmPassword: confirmPassword
            )
            return response.userID
        } catch let authError as AuthError {
            throw authError
        } catch {
            throw AuthError.registrationFailed
        }
    }
}
