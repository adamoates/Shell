//
//  ForgotPasswordUseCase.swift
//  Shell
//
//  Created by Shell on 2026-02-15.
//

import Foundation

/// Use case for requesting a password reset email
protocol ForgotPasswordUseCase: Sendable {
    /// Request password reset email for the given email address
    /// - Parameter email: User's email address
    /// - Throws: AuthError on failure
    func execute(email: String) async throws
}

/// Default implementation of ForgotPasswordUseCase
final class DefaultForgotPasswordUseCase: ForgotPasswordUseCase {
    private let authHTTPClient: AuthHTTPClient

    init(authHTTPClient: AuthHTTPClient) {
        self.authHTTPClient = authHTTPClient
    }

    func execute(email: String) async throws {
        // Client-side validation
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }

        // Call backend forgot password endpoint
        do {
            try await authHTTPClient.forgotPassword(email: email)
        } catch let authError as AuthError {
            throw authError
        } catch {
            throw AuthError.unknown("Failed to send password reset email")
        }
    }
}
