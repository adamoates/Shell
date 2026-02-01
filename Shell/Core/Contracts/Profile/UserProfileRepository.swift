//
//  UserProfileRepository.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Repository protocol for user profile persistence
/// Abstracts storage implementation (in-memory, UserDefaults, Core Data, etc.)
protocol UserProfileRepository {
    /// Fetch a user profile by ID
    /// - Parameter userID: The user's ID
    /// - Returns: The user profile if found, nil otherwise
    func fetchProfile(userID: String) async -> UserProfile?

    /// Save or update a user profile
    /// - Parameter profile: The profile to save
    func saveProfile(_ profile: UserProfile) async

    /// Delete a user profile
    /// - Parameter userID: The user's ID
    func deleteProfile(userID: String) async

    /// Check if a user has completed identity setup
    /// - Parameter userID: The user's ID
    /// - Returns: True if profile exists and has completed identity setup
    func hasCompletedIdentitySetup(userID: String) async -> Bool
}
