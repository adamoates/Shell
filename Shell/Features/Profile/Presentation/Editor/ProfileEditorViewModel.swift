//
//  ProfileEditorViewModel.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation
import Combine

/// ViewModel for SwiftUI Profile Editor
/// Demonstrates:
/// - ObservableObject for SwiftUI binding
/// - @Published properties for reactive UI
/// - Integration with existing domain validation (IdentityData)
/// - Async/await use case calls
@MainActor
final class ProfileEditorViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var screenName: String = ""
    @Published var birthday = Date()
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isSaveEnabled: Bool = false

    // MARK: - Dependencies

    private let setupIdentityUseCase: CompleteIdentitySetupUseCase
    private let userID: String

    // MARK: - Delegate

    weak var delegate: ProfileEditorViewModelDelegate?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        userID: String,
        setupIdentityUseCase: CompleteIdentitySetupUseCase
    ) {
        self.userID = userID
        self.setupIdentityUseCase = setupIdentityUseCase

        setupValidation()
    }

    // MARK: - Setup

    private func setupValidation() {
        // Combine screenName and birthday publishers to enable/disable save
        Publishers.CombineLatest($screenName, $birthday)
            .map { screenName, _ in
                // Enable save if basic validation passes
                !screenName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .assign(to: &$isSaveEnabled)
    }

    // MARK: - Actions

    func save() async {
        errorMessage = nil
        isLoading = true

        // Validate and create identity data
        let result = IdentityData.create(
            screenName: screenName,
            birthday: birthday
        )

        guard case .success(let identityData) = result else {
            // Validation failed
            if case .failure(let error) = result {
                isLoading = false
                errorMessage = error.localizedDescription
                return
            }
            isLoading = false
            errorMessage = "Invalid input"
            return
        }

        // Execute use case
        _ = await setupIdentityUseCase.execute(
            userID: userID,
            identityData: identityData,
            avatarURL: nil
        )

        isLoading = false
        delegate?.profileEditorDidSave(self)
    }

    func cancel() {
        delegate?.profileEditorDidCancel(self)
    }
}

// MARK: - Delegate Protocol

protocol ProfileEditorViewModelDelegate: AnyObject {
    func profileEditorDidSave(_ viewModel: ProfileEditorViewModel)
    func profileEditorDidCancel(_ viewModel: ProfileEditorViewModel)
}
