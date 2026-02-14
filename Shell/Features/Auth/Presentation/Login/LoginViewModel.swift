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
@MainActor
final class LoginViewModel: ObservableObject {
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
    private let sessionRepository: SessionRepository
    private var cancellables = Set<AnyCancellable>()
    private let sessionDuration: TimeInterval = 60 * 60 * 24 // 24 hours

    // MARK: - Rate Limiting Properties

    private var failedAttempts: Int = 0
    private var lastAttemptTime: Date?
    private var lockoutUntil: Date?

    // MARK: - Initialization

    init(
        validateCredentials: ValidateCredentialsUseCase,
        sessionRepository: SessionRepository
    ) {
        self.validateCredentials = validateCredentials
        self.sessionRepository = sessionRepository
    }

    // MARK: - Actions

    /// Attempt to log in with current credentials
    func login() {
        Task { [weak self] in
            await self?.performLogin()
        }
    }

    /// Perform login and persist session if credentials are valid
    private func performLogin() async {
        // Check if account is locked out
        if let lockout = lockoutUntil, Date() < lockout {
            let remainingSeconds = Int(lockout.timeIntervalSinceNow)
            errorMessage = "Too many failed attempts. Please wait \(remainingSeconds) seconds."
            return
        }

        // Check rate limiting (prevent rapid fire attempts)
        if let lastAttempt = lastAttemptTime, Date().timeIntervalSince(lastAttempt) < 1.0 {
            errorMessage = "Please wait before trying again."
            return
        }

        // Clear previous error
        errorMessage = nil
        isLoading = true

        // Update attempt time
        lastAttemptTime = Date()

        // Create credentials
        let credentials = Credentials(
            username: username,
            password: password
        )

        // Validate credentials
        let result = validateCredentials.execute(credentials: credentials)

        switch result {
        case .success:
            // Persist authenticated session before reporting login success.
            let session = UserSession(
                userId: username,
                accessToken: UUID().uuidString,
                expiresAt: Date().addingTimeInterval(sessionDuration)
            )

            do {
                try await sessionRepository.saveSession(session)
                failedAttempts = 0
                lockoutUntil = nil
                delegate?.loginViewModelDidSucceed(self, username: username)
            } catch {
                errorMessage = "Failed to persist your session. Please try again."
            }

        case .failure(let error):
            // Validation failed - increment counter and apply exponential backoff
            failedAttempts += 1

            // Apply lockout after 5 failed attempts
            if failedAttempts >= 5 {
                let lockoutDuration: TimeInterval = 30 // 30 seconds lockout
                lockoutUntil = Date().addingTimeInterval(lockoutDuration)
                errorMessage = "Too many failed attempts. Account locked for 30 seconds."
            } else if failedAttempts >= 3 {
                // After 3 failures, show warning
                errorMessage = "\(error.userMessage). \(6 - failedAttempts) attempts remaining."
            } else {
                // Show normal error message
                errorMessage = error.userMessage
            }
        }

        isLoading = false
    }

    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}
