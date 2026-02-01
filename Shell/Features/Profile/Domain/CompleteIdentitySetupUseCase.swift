//
//  CompleteIdentitySetupUseCase.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Use case protocol for completing identity setup
protocol CompleteIdentitySetupUseCase {
    /// Complete identity setup for a user
    /// Creates or updates user profile with identity data
    /// - Parameters:
    ///   - userID: The user's ID
    ///   - identityData: The collected identity data
    ///   - avatarURL: Optional avatar URL
    /// - Returns: The created or updated user profile
    func execute(
        userID: String,
        identityData: IdentityData,
        avatarURL: URL?
    ) async -> UserProfile
}

/// Default implementation of CompleteIdentitySetupUseCase
final class DefaultCompleteIdentitySetupUseCase: CompleteIdentitySetupUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute(
        userID: String,
        identityData: IdentityData,
        avatarURL: URL?
    ) async -> UserProfile {
        // Check if profile already exists
        if let existingProfile = await repository.fetchProfile(userID: userID) {
            // Update existing profile
            let updatedProfile = existingProfile.update(
                with: identityData,
                avatarURL: avatarURL
            )
            await repository.saveProfile(updatedProfile)
            return updatedProfile
        } else {
            // Create new profile
            let newProfile = UserProfile.create(
                userID: userID,
                identityData: identityData,
                avatarURL: avatarURL
            )
            await repository.saveProfile(newProfile)
            return newProfile
        }
    }
}
