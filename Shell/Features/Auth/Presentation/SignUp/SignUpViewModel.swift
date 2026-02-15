//
//  SignUpViewModel.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import Foundation
import Combine

/// Protocol for SignUpViewModel to communicate events to the view
protocol SignUpViewModelDelegate: AnyObject {
    /// Called when registration succeeds
    func signUpViewModelDidSucceed(_ viewModel: SignUpViewModel, userID: String)
}

/// ViewModel for sign up screen
///
/// Responsibilities:
/// - Hold email, password, and confirmPassword state
/// - Validate input fields
/// - Communicate registration errors and success to the view
@MainActor
final class SignUpViewModel: ObservableObject {
    // MARK: - Properties

    /// Email input
    @Published var email: String = ""

    /// Password input
    @Published var password: String = ""

    /// Confirm password input
    @Published var confirmPassword: String = ""

    /// Current error message (nil if no error)
    @Published var errorMessage: String?

    /// Whether registration is in progress
    @Published var isLoading: Bool = false

    weak var delegate: SignUpViewModelDelegate?

    private let registerUseCase: RegisterUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(registerUseCase: RegisterUseCase) {
        self.registerUseCase = registerUseCase
    }

    // MARK: - Actions

    /// Attempt to register with current inputs
    func register() {
        Task { [weak self] in
            await self?.performRegistration()
        }
    }

    /// Perform registration and notify delegate on success
    private func performRegistration() async {
        // Clear previous error
        errorMessage = nil
        isLoading = true

        do {
            let userID = try await registerUseCase.execute(
                email: email,
                password: password,
                confirmPassword: confirmPassword
            )

            // Registration successful
            delegate?.signUpViewModelDidSucceed(self, userID: userID)
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Registration failed. Please try again."
        }

        isLoading = false
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
