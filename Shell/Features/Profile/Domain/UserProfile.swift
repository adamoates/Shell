//
//  UserProfile.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Domain model representing a user's profile
/// Immutable value type for thread safety
struct UserProfile: Equatable, Codable, Sendable {
    let userID: String
    let screenName: String
    let birthday: Date
    let avatarURL: URL?
    let createdAt: Date
    let updatedAt: Date

    /// Whether the user has completed identity setup
    var hasCompletedIdentitySetup: Bool {
        !screenName.isEmpty
    }
}

// MARK: - Factory Methods

extension UserProfile {
    /// Create a new profile with identity data
    static func create(
        userID: String,
        identityData: IdentityData,
        avatarURL: URL? = nil
    ) -> UserProfile {
        let now = Date()
        return UserProfile(
            userID: userID,
            screenName: identityData.screenName,
            birthday: identityData.birthday,
            avatarURL: avatarURL,
            createdAt: now,
            updatedAt: now
        )
    }

    /// Update profile with new identity data
    func update(with identityData: IdentityData, avatarURL: URL? = nil) -> UserProfile {
        UserProfile(
            userID: userID,
            screenName: identityData.screenName,
            birthday: identityData.birthday,
            avatarURL: avatarURL ?? self.avatarURL,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
