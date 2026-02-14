//
//  UserSession.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Represents an authenticated user session
/// Follows OAuth 2.0 token refresh pattern with access and refresh tokens
struct UserSession: Equatable, Codable, Sendable {
    let userId: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date

    /// Whether this session is still valid
    var isValid: Bool {
        Date() < expiresAt
    }
}
