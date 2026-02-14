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
/// - Keychain for secure storage (actor-based for thread safety)
/// - UserDefaults for non-sensitive data
/// - In-memory storage for testing
///
/// Note: This protocol is designed to be implemented by actors for Swift 6 concurrency safety
protocol SessionRepository: Sendable {
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
