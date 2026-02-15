//
//  ResetPasswordViewModel.swift
//  Shell
//
//  Created by Shell on 2026-02-15.
//

import Foundation
import Combine

/// Protocol for ResetPasswordViewModel to communicate events to the view
protocol ResetPasswordViewModelDelegate: AnyObject {
    /// Called when password reset succeeds
    func resetPasswordViewModelDidSucceed(_ viewModel: ResetPasswordViewModel)
}

/// ViewModel for reset password screen
///
/// Responsibilities:
/// - Hold new password and confirm password state
/// - Store reset token from deep link
/// - Validate password inputs
/// - Call reset password use case
/// - Communicate errors and success to the view
@MainActor
final class ResetPasswordViewModel: ObservableObject {
    // MARK: - Properties

    /// New password input
    @Published var newPassword: String = ""

    /// Confirm password input
    @Published var confirmPassword: String = ""

    /// Current error message (nil if no error)
    @Published var errorMessage: String?

    /// Whether reset is in progress
    @Published var isLoading: Bool = false

    weak var delegate: ResetPasswordViewModelDelegate?

    private let token: String
    private let resetPasswordUseCase: ResetPasswordUseCase
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(token: String, resetPasswordUseCase: ResetPasswordUseCase) {
        self.token = token
        self.resetPasswordUseCase = resetPasswordUseCase
    }

    // MARK: - Actions

    /// Attempt to reset password with current inputs
    func resetPassword() {
        Task { [weak self] in
            await self?.performReset()
        }
    }

    /// Perform password reset and notify delegate on success
    private func performReset() async {
        // Clear previous error
        errorMessage = nil
        isLoading = true

        // Client-side validation
        guard !newPassword.isEmpty else {
            errorMessage = "Please enter a new password"
            isLoading = false
            return
        }

        guard newPassword.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            isLoading = false
            return
        }

        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match"
            isLoading = false
            return
        }

        do {
            try await resetPasswordUseCase.execute(token: token, newPassword: newPassword)

            // Reset successful
            delegate?.resetPasswordViewModelDidSucceed(self)
        } catch let authError as AuthError {
            errorMessage = authError.userMessage
        } catch {
            errorMessage = "Password reset failed. Please try again."
        }

        isLoading = false
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
