//
//  ProfileViewModel.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation
import Combine

/// ViewModel for the Profile screen
/// Follows MVVM pattern with Combine for reactive updates
@MainActor
final class ProfileViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var state: ProfileState = .idle

    // MARK: - Dependencies

    private let fetchProfile: FetchProfileUseCase
    private let userID: String

    // MARK: - Init

    init(
        userID: String,
        fetchProfile: FetchProfileUseCase
    ) {
        self.userID = userID
        self.fetchProfile = fetchProfile
    }

    // MARK: - Actions

    /// Load the user's profile
    func loadProfile() async {
        state = .loading

        // Fetch profile from use case
        guard let profile = await fetchProfile.execute(userID: userID) else {
            // Profile not found - this could be a new user
            state = .error(ProfileError.notFound)
            return
        }

        state = .loaded(profile)
    }

    /// Retry loading the profile after an error
    func retryLoadProfile() async {
        await loadProfile()
    }
}

// MARK: - Profile State

enum ProfileState: Equatable {
    case idle
    case loading
    case loaded(UserProfile)
    case error(ProfileError)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let error) = self {
            return error.localizedDescription
        }
        return nil
    }

    var canRetry: Bool {
        if case .error(let error) = self {
            return error.canRetry
        }
        return false
    }

    var profile: UserProfile? {
        if case .loaded(let profile) = self {
            return profile
        }
        return nil
    }

    static func == (lhs: ProfileState, rhs: ProfileState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.loaded(let lProfile), .loaded(let rProfile)):
            return lProfile == rProfile
        case (.error(let lError), .error(let rError)):
            return lError.localizedDescription == rError.localizedDescription
        default:
            return false
        }
    }
}
