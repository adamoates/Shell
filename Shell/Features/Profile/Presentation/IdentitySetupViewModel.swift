//
//  IdentitySetupViewModel.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation
import Combine

/// ViewModel for the Identity Setup flow
/// Manages state across the multi-step identity setup process
@MainActor
final class IdentitySetupViewModel: ObservableObject {
    // MARK: - Published State

    @Published var screenName: String = ""
    @Published var birthday: Date = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @Published var avatarURL: URL?

    @Published private(set) var validationError: String?
    @Published private(set) var isCompleting: Bool = false
    @Published private(set) var completionError: String?
    @Published private(set) var canRetry: Bool = false

    // MARK: - Dependencies

    private let completeIdentitySetup: CompleteIdentitySetupUseCase
    private let userID: String

    // MARK: - Init

    init(
        userID: String,
        completeIdentitySetup: CompleteIdentitySetupUseCase
    ) {
        self.userID = userID
        self.completeIdentitySetup = completeIdentitySetup
    }

    // MARK: - Actions

    /// Validate screen name input
    func validateScreenName() -> Bool {
        validationError = nil

        switch IdentityData.validateScreenName(screenName) {
        case .success:
            return true
        case .failure(let error):
            validationError = error.localizedDescription
            return false
        }
    }

    /// Validate birthday input
    func validateBirthday() -> Bool {
        validationError = nil

        switch IdentityData.validateBirthday(birthday) {
        case .success:
            return true
        case .failure(let error):
            validationError = error.localizedDescription
            return false
        }
    }

    /// Complete the identity setup
    /// - Returns: The created user profile on success, nil on failure
    func completeSetup() async -> UserProfile? {
        isCompleting = true
        completionError = nil
        canRetry = false

        // Create identity data with validation
        guard case .success(let identityData) = IdentityData.create(
            screenName: screenName,
            birthday: birthday
        ) else {
            if case .failure(let error) = IdentityData.create(
                screenName: screenName,
                birthday: birthday
            ) {
                let setupError = IdentitySetupError.validation(error)
                completionError = setupError.localizedDescription
                canRetry = setupError.canRetry
            }
            isCompleting = false
            return nil
        }

        // Complete identity setup
        let profile = await completeIdentitySetup.execute(
            userID: userID,
            identityData: identityData,
            avatarURL: avatarURL
        )

        isCompleting = false
        return profile
    }

    /// Retry completing identity setup after an error
    func retryCompleteSetup() async -> UserProfile? {
        return await completeSetup()
    }
}
