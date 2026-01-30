//
//  LoginViewModel.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation
import Combine

/// Protocol for LoginViewModel to communicate events to the view
protocol LoginViewModelDelegate: AnyObject {
    /// Called when login succeeds
    func loginViewModelDidSucceed(_ viewModel: LoginViewModel, username: String)
}

/// ViewModel for login screen
///
/// Responsibilities:
/// - Hold username and password state
/// - Validate credentials using ValidateCredentialsUseCase
/// - Communicate validation errors and success to the view
final class LoginViewModel {
    // MARK: - Properties

    /// Username input
    @Published var username: String = ""

    /// Password input
    @Published var password: String = ""

    /// Current error message (nil if no error)
    @Published var errorMessage: String?

    /// Whether login is in progress
    @Published var isLoading: Bool = false

    weak var delegate: LoginViewModelDelegate?

    private let validateCredentials: ValidateCredentialsUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(validateCredentials: ValidateCredentialsUseCase) {
        self.validateCredentials = validateCredentials
    }

    // MARK: - Actions

    /// Attempt to log in with current credentials
    func login() {
        // Clear previous error
        errorMessage = nil

        // Create credentials
        let credentials = Credentials(
            username: username,
            password: password
        )

        // Validate credentials
        let result = validateCredentials.execute(credentials: credentials)

        switch result {
        case .success:
            // Validation succeeded - notify delegate
            delegate?.loginViewModelDidSucceed(self, username: username)

        case .failure(let error):
            // Validation failed - show error message
            errorMessage = error.userMessage
        }
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
