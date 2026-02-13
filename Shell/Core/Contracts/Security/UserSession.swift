//
//  UserSession.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Represents an authenticated user session
struct UserSession: Equatable, Codable, Sendable {
    let userId: String
    let accessToken: String
    let expiresAt: Date

    /// Whether this session is still valid
    var isValid: Bool {
        Date() < expiresAt
    }
}
