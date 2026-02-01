//
//  InMemoryUserProfileRepository.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// In-memory implementation of UserProfileRepository
/// Used for development and testing
/// Thread-safe using actor
actor InMemoryUserProfileRepository: UserProfileRepository {
    private var profiles: [String: UserProfile] = [:]

    func fetchProfile(userID: String) async -> UserProfile? {
        profiles[userID]
    }

    func saveProfile(_ profile: UserProfile) async {
        profiles[profile.userID] = profile
    }

    func deleteProfile(userID: String) async {
        profiles.removeValue(forKey: userID)
    }

    func hasCompletedIdentitySetup(userID: String) async -> Bool {
        guard let profile = profiles[userID] else {
            return false
        }
        // Inline the computed property to avoid Swift 6 concurrency warning
        return !profile.screenName.isEmpty
    }
}
