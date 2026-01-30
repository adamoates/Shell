//
//  RestoreSessionUseCase.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Protocol for restoring user session on app launch
///
/// This is domain logic (business rules), not orchestration.
/// Boot calls this use case and reacts to the result.
protocol RestoreSessionUseCase: AnyObject {
    /// Attempt to restore the user session
    /// - Returns: The session status after restoration attempt
    func execute() async -> SessionStatus
}

// MARK: - Default Implementation

/// Default implementation of RestoreSessionUseCase
final class DefaultRestoreSessionUseCase: RestoreSessionUseCase {
    // MARK: - Properties

    private let sessionRepository: SessionRepository

    // MARK: - Initialization

    init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    // MARK: - RestoreSessionUseCase

    func execute() async -> SessionStatus {
        // Try to get current session (non-critical, no throw)
        guard let session = try? await sessionRepository.getCurrentSession() else {
            return .unauthenticated
        }

        // Validate session expiry (business rule)
        guard session.isValid else {
            // Session expired, clear it
            try? await sessionRepository.clearSession()
            return .unauthenticated
        }

        // Session is valid
        return .authenticated
    }
}
