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

    /// Access token has expired
    case tokenExpired

    /// No refresh token available in session
    case noRefreshToken

    /// Failed to refresh the session
    case refreshFailed

    /// Keychain storage error
    case keychainError(OSStatus)

    /// Invalid server response
    case invalidResponse

    /// Unknown error
    case unknown(String)

    /// Registration errors
    case emailAlreadyExists
    case invalidEmail
    case weakPassword
    case passwordMismatch
    case registrationFailed
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
        case .tokenExpired:
            return "Your session has expired"
        case .noRefreshToken:
            return "No refresh token available"
        case .refreshFailed:
            return "Failed to refresh session"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .invalidResponse:
            return "Invalid server response"
        case .unknown(let message):
            return message
        case .emailAlreadyExists:
            return "This email is already registered"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters with 1 uppercase, 1 number, and 1 special character"
        case .passwordMismatch:
            return "Passwords do not match"
        case .registrationFailed:
            return "Registration failed. Please try again."
        }
    }
}
