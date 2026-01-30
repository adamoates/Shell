//
//  AuthError.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Domain errors for authentication
enum AuthError: Error, Equatable {
    /// Username is missing or empty
    case missingUsername

    /// Password is missing or empty
    case missingPassword

    /// Username is too short (minimum length not met)
    case usernameTooShort(minimumLength: Int)

    /// Password is too short (minimum length not met)
    case passwordTooShort(minimumLength: Int)

    /// Invalid credentials (wrong username/password combination)
    case invalidCredentials

    /// Network error occurred
    case networkError

    /// Unknown error
    case unknown(String)
}

// MARK: - User-Facing Messages

extension AuthError {
    /// User-friendly error message for display in UI
    var userMessage: String {
        switch self {
        case .missingUsername:
            return "Please enter a username"
        case .missingPassword:
            return "Please enter a password"
        case .usernameTooShort(let minimumLength):
            return "Username must be at least \(minimumLength) characters"
        case .passwordTooShort(let minimumLength):
            return "Password must be at least \(minimumLength) characters"
        case .invalidCredentials:
            return "Invalid username or password"
        case .networkError:
            return "Network connection failed. Please try again."
        case .unknown(let message):
            return message
        }
    }
}
