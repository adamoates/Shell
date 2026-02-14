//
//  KeychainSessionRepositoryTests.swift
//  ShellTests
//
//  Created by Shell on 2026-02-14.
//

import XCTest
@testable import Shell

@MainActor
final class KeychainSessionRepositoryTests: XCTestCase {

    var repository: KeychainSessionRepository!

    override func setUp() async throws {
        repository = KeychainSessionRepository()

        // Clear any existing session before each test
        try await repository.clearSession()
    }

    override func tearDown() async throws {
        // Clean up after each test
        try await repository.clearSession()
        repository = nil
    }

    // MARK: - Save and Retrieve Tests

    func testSaveAndRetrieveSession() async throws {
        // Given
        let expiresAt = Date().addingTimeInterval(900) // 15 minutes from now
        let session = UserSession(
            userId: "test-user-id",
            accessToken: "test-access-token",
            refreshToken: "test-refresh-token",
            expiresAt: expiresAt
        )

        // When
        try await repository.saveSession(session)
        let retrievedSession = try await repository.getCurrentSession()

        // Then
        XCTAssertNotNil(retrievedSession)
        XCTAssertEqual(retrievedSession?.userId, "test-user-id")
        XCTAssertEqual(retrievedSession?.accessToken, "test-access-token")
        XCTAssertEqual(retrievedSession?.refreshToken, "test-refresh-token")

        // Compare dates with tolerance (ISO8601 formatting might lose milliseconds)
        if let retrieved = retrievedSession {
            XCTAssertEqual(
                retrieved.expiresAt.timeIntervalSince1970,
                expiresAt.timeIntervalSince1970,
                accuracy: 1.0,
                "Expiry dates should match within 1 second"
            )
        }
    }

    func testRetrieveNonExistentSessionReturnsNil() async throws {
        // Given - no session saved

        // When
        let session = try await repository.getCurrentSession()

        // Then
        XCTAssertNil(session, "Should return nil when no session exists")
    }

    func testOverwriteExistingSession() async throws {
        // Given - first session
        let firstSession = UserSession(
            userId: "user-1",
            accessToken: "token-1",
            refreshToken: "refresh-1",
            expiresAt: Date().addingTimeInterval(900)
        )
        try await repository.saveSession(firstSession)

        // When - save second session
        let secondSession = UserSession(
            userId: "user-2",
            accessToken: "token-2",
            refreshToken: "refresh-2",
            expiresAt: Date().addingTimeInterval(1800)
        )
        try await repository.saveSession(secondSession)

        // Then - second session should be retrieved
        let retrieved = try await repository.getCurrentSession()
        XCTAssertEqual(retrieved?.userId, "user-2")
        XCTAssertEqual(retrieved?.accessToken, "token-2")
        XCTAssertEqual(retrieved?.refreshToken, "refresh-2")
    }

    // MARK: - Clear Session Tests

    func testClearSession() async throws {
        // Given - session exists
        let session = UserSession(
            userId: "test-user",
            accessToken: "test-token",
            refreshToken: "test-refresh",
            expiresAt: Date().addingTimeInterval(900)
        )
        try await repository.saveSession(session)

        // Verify session was saved
        let savedSession = try await repository.getCurrentSession()
        XCTAssertNotNil(savedSession)

        // When - clear session
        try await repository.clearSession()

        // Then - session should be nil
        let clearedSession = try await repository.getCurrentSession()
        XCTAssertNil(clearedSession, "Session should be nil after clearing")
    }

    func testClearNonExistentSessionDoesNotThrow() async throws {
        // Given - no session exists

        // When/Then - clearing should not throw
        try await repository.clearSession()
    }

    // MARK: - Edge Cases

    func testSaveSessionWithSpecialCharacters() async throws {
        // Given - tokens with special characters
        let session = UserSession(
            userId: "user@example.com",
            accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U",
            refreshToken: "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            expiresAt: Date().addingTimeInterval(900)
        )

        // When
        try await repository.saveSession(session)
        let retrieved = try await repository.getCurrentSession()

        // Then
        XCTAssertEqual(retrieved?.userId, session.userId)
        XCTAssertEqual(retrieved?.accessToken, session.accessToken)
        XCTAssertEqual(retrieved?.refreshToken, session.refreshToken)
    }

    func testSaveSessionWithExpiredDate() async throws {
        // Given - session with expired date
        let expiredDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let session = UserSession(
            userId: "test-user",
            accessToken: "test-token",
            refreshToken: "test-refresh",
            expiresAt: expiredDate
        )

        // When
        try await repository.saveSession(session)
        let retrieved = try await repository.getCurrentSession()

        // Then - repository should save and retrieve even expired sessions
        // Expiry validation is the responsibility of the domain layer
        XCTAssertNotNil(retrieved)
        XCTAssertFalse(retrieved?.isValid ?? true, "Retrieved session should be invalid")
    }

    func testSaveSessionWithFutureDate() async throws {
        // Given - session expiring in 7 days
        let futureDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let session = UserSession(
            userId: "test-user",
            accessToken: "test-token",
            refreshToken: "test-refresh",
            expiresAt: futureDate
        )

        // When
        try await repository.saveSession(session)
        let retrieved = try await repository.getCurrentSession()

        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertTrue(retrieved?.isValid ?? false, "Retrieved session should be valid")
    }

    // MARK: - Concurrency Tests

    func testConcurrentSaveAndRetrieve() async throws {
        // Given - multiple sessions to save concurrently
        let sessions = (1...5).map { index in
            UserSession(
                userId: "user-\(index)",
                accessToken: "token-\(index)",
                refreshToken: "refresh-\(index)",
                expiresAt: Date().addingTimeInterval(Double(index * 900))
            )
        }

        // When - save sessions concurrently (last one wins due to actor isolation)
        await withTaskGroup(of: Void.self) { group in
            for session in sessions {
                group.addTask {
                    try? await self.repository.saveSession(session)
                }
            }
        }

        // Then - one session should be saved (actor ensures serialization)
        let retrieved = try await repository.getCurrentSession()
        XCTAssertNotNil(retrieved)
    }

    // MARK: - Session Validation Tests

    func testRetrievedSessionIsValid() async throws {
        // Given - session expiring in future
        let session = UserSession(
            userId: "test-user",
            accessToken: "test-token",
            refreshToken: "test-refresh",
            expiresAt: Date().addingTimeInterval(900)
        )

        // When
        try await repository.saveSession(session)
        let retrieved = try await repository.getCurrentSession()

        // Then
        XCTAssertTrue(retrieved?.isValid ?? false, "Session should be valid")
    }

    func testRetrievedSessionIsInvalid() async throws {
        // Given - expired session
        let session = UserSession(
            userId: "test-user",
            accessToken: "test-token",
            refreshToken: "test-refresh",
            expiresAt: Date().addingTimeInterval(-100) // Expired 100 seconds ago
        )

        // When
        try await repository.saveSession(session)
        let retrieved = try await repository.getCurrentSession()

        // Then
        XCTAssertFalse(retrieved?.isValid ?? true, "Session should be invalid")
    }
}
