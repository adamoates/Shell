//
//  SessionRepository.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Protocol for managing user session persistence
///
/// Implementations might use:
/// - Keychain for secure storage
/// - UserDefaults for non-sensitive data
/// - In-memory storage for testing
protocol SessionRepository: AnyObject {
    /// Get the current user session
    /// - Returns: The current session if one exists and is valid, nil otherwise
    /// - Throws: If session data is corrupted or cannot be accessed
    func getCurrentSession() async throws -> UserSession?

    /// Save a user session
    /// - Parameter session: The session to save
    /// - Throws: If session cannot be saved
    func saveSession(_ session: UserSession) async throws

    /// Clear the current session
    /// - Throws: If session cannot be cleared
    func clearSession() async throws
}
