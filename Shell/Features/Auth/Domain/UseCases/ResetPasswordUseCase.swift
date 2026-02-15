//
//  ResetPasswordUseCase.swift
//  Shell
//
//  Created by Shell on 2026-02-15.
//

import Foundation

/// Use case for resetting user password with a reset token
protocol ResetPasswordUseCase: Sendable {
    /// Reset password using a reset token
    /// - Parameters:
    ///   - token: Password reset token from email deep link
    ///   - newPassword: New password to set
    /// - Throws: AuthError on failure
    func execute(token: String, newPassword: String) async throws
}

/// Default implementation of ResetPasswordUseCase
final class DefaultResetPasswordUseCase: ResetPasswordUseCase {
    private let authHTTPClient: AuthHTTPClient

    init(authHTTPClient: AuthHTTPClient) {
        self.authHTTPClient = authHTTPClient
    }

    func execute(token: String, newPassword: String) async throws {
        // Client-side validation
        guard !token.isEmpty else {
            throw AuthError.unknown("Reset token is missing")
        }

        guard newPassword.count >= 8 else {
            throw AuthError.passwordTooShort(minimumLength: 8)
        }

        // Call backend reset password endpoint
        do {
            try await authHTTPClient.resetPassword(token: token, newPassword: newPassword)
        } catch let authError as AuthError {
            throw authError
        } catch {
            throw AuthError.unknown("Password reset failed")
        }
    }
}
