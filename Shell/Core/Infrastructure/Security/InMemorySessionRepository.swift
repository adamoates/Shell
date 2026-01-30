//
//  InMemorySessionRepository.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// In-memory implementation of SessionRepository
/// This is a simple implementation for demonstration
/// In production, use KeychainSessionRepository for secure storage
final class InMemorySessionRepository: SessionRepository {
    // MARK: - Properties

    private var currentSession: UserSession?
    private let queue = DispatchQueue(label: "com.shell.session-repository")

    // MARK: - SessionRepository

    func getCurrentSession() async throws -> UserSession? {
        queue.sync {
            currentSession
        }
    }

    func saveSession(_ session: UserSession) async throws {
        queue.sync {
            currentSession = session
        }
    }

    func clearSession() async throws {
        queue.sync {
            currentSession = nil
        }
    }
}
