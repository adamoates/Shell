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
    @Published var birthday: Date = Date()
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var isSaveEnabled: Bool = false

    // MARK: - Dependencies

    private let setupIdentityUseCase: SetupIdentityUseCase
    private let userID: String

    // MARK: - Delegate

    weak var delegate: ProfileEditorViewModelDelegate?

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        userID: String,
        setupIdentityUseCase: SetupIdentityUseCase
    ) {
        self.userID = userID
        self.setupIdentityUseCase = setupIdentityUseCase

        setupValidation()
    }

    // MARK: - Setup

    private func setupValidation() {
        // Combine screenName and birthday publishers to enable/disable save
        Publishers.CombineLatest($screenName, $birthday)
            .map { screenName, birthday in
                // Enable save if basic validation passes
                !screenName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .assign(to: &$isSaveEnabled)
    }

    // MARK: - Actions

    func save() async {
        errorMessage = nil
        isLoading = true

        do {
            try await setupIdentityUseCase.execute(
                userID: userID,
                screenName: screenName,
                birthday: birthday
            )

            isLoading = false
            delegate?.profileEditorDidSave(self)

        } catch let error as IdentityValidationError {
            isLoading = false
            errorMessage = error.localizedDescription

        } catch {
            isLoading = false
            errorMessage = "An unexpected error occurred"
        }
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
