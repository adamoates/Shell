//
//  ProfileError.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Errors that can occur in Profile feature
enum ProfileError: Error {
    case network
    case server(message: String)
    case notFound
    case unknown

    /// User-friendly error message
    var localizedDescription: String {
        switch self {
        case .network:
            return "Check your connection and try again."
        case .server(let message):
            return message
        case .notFound:
            return "Profile not found."
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    /// Whether this error can be retried
    var canRetry: Bool {
        switch self {
        case .network, .server, .unknown:
            return true
        case .notFound:
            return false
        }
    }
}

/// Errors that can occur in Identity Setup feature
enum IdentitySetupError: Error {
    case validation(IdentityValidationError)
    case network
    case server(message: String)
    case unknown

    /// User-friendly error message
    var localizedDescription: String {
        switch self {
        case .validation(let validationError):
            return validationError.localizedDescription
        case .network:
            return "Check your connection and try again."
        case .server(let message):
            return message
        case .unknown:
            return "Something went wrong. Please try again."
        }
    }

    /// Whether this error can be retried
    var canRetry: Bool {
        switch self {
        case .validation:
            return false  // Validation errors need user correction
        case .network, .server, .unknown:
            return true
        }
    }
}
