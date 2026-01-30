//
//  ValidateCredentialsUseCase.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Use case for validating user credentials
///
/// Responsibilities:
/// - Validate username format and length
/// - Validate password format and length
/// - Encapsulate validation rules in one place
protocol ValidateCredentialsUseCase {
    /// Validate the provided credentials
    /// - Parameter credentials: The credentials to validate
    /// - Returns: Result with Void on success or AuthError on failure
    func execute(credentials: Credentials) -> Result<Void, AuthError>
}

/// Default implementation of ValidateCredentialsUseCase
final class DefaultValidateCredentialsUseCase: ValidateCredentialsUseCase {
    // MARK: - Constants

    private let minimumUsernameLength = 3
    private let minimumPasswordLength = 6

    // MARK: - ValidateCredentialsUseCase

    func execute(credentials: Credentials) -> Result<Void, AuthError> {
        // Validate username
        if credentials.username.isEmpty {
            return .failure(.missingUsername)
        }

        if credentials.username.count < minimumUsernameLength {
            return .failure(.usernameTooShort(minimumLength: minimumUsernameLength))
        }

        // Validate password
        if credentials.password.isEmpty {
            return .failure(.missingPassword)
        }

        if credentials.password.count < minimumPasswordLength {
            return .failure(.passwordTooShort(minimumLength: minimumPasswordLength))
        }

        // All validations passed
        return .success(())
    }
}
