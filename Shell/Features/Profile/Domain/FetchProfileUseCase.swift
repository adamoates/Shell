//
//  FetchProfileUseCase.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Use case protocol for fetching a user profile
protocol FetchProfileUseCase {
    /// Fetch a user's profile
    /// - Parameter userID: The user's ID
    /// - Returns: The user profile if found, nil otherwise
    func execute(userID: String) async -> UserProfile?
}

/// Default implementation of FetchProfileUseCase
final class DefaultFetchProfileUseCase: FetchProfileUseCase {
    private let repository: UserProfileRepository

    init(repository: UserProfileRepository) {
        self.repository = repository
    }

    func execute(userID: String) async -> UserProfile? {
        await repository.fetchProfile(userID: userID)
    }
}
