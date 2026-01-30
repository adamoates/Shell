//
//  RouteParameters.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Protocol for validating route parameters
protocol RouteParameters {
    /// Validate parameters from URL components
    /// Returns Result with validated parameters or error
    static func validate(_ params: [String: String]) -> Result<Self, RouteError>
}

/// Route-specific errors
enum RouteError: Error, Equatable {
    case missingParameter(String)
    case invalidParameter(String, reason: String)
    case invalidURL

    var localizedDescription: String {
        switch self {
        case .missingParameter(let param):
            return "Missing required parameter: \(param)"
        case .invalidParameter(let param, let reason):
            return "Invalid parameter '\(param)': \(reason)"
        case .invalidURL:
            return "Invalid URL format"
        }
    }
}

// MARK: - Example: Profile Parameters

/// Parameters for profile route
struct ProfileParameters: RouteParameters {
    let userID: String

    static func validate(_ params: [String: String]) -> Result<ProfileParameters, RouteError> {
        guard let userID = params["userID"], !userID.isEmpty else {
            return .failure(.missingParameter("userID"))
        }

        // Validate userID format (minimum length)
        guard userID.count >= 3 else {
            return .failure(.invalidParameter("userID", reason: "Must be at least 3 characters"))
        }

        // Validate no special characters (alphanumeric only)
        let allowedCharacters = CharacterSet.alphanumerics
        guard userID.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return .failure(.invalidParameter("userID", reason: "Must contain only letters and numbers"))
        }

        return .success(ProfileParameters(userID: userID))
    }
}
