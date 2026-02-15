//
//  RestoreSessionUseCaseTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for RestoreSessionUseCase
/// Following TDD with test doubles
final class RestoreSessionUseCaseTests: XCTestCase {
    // MARK: - Test Doubles

    /// Fake SessionRepository - returns stubbed data
    private final class SessionRepositoryFake: SessionRepository {
        var stubbedSession: UserSession?
        var stubbedError: Error?
        private(set) var getCurrentSessionCallCount = 0
        private(set) var clearSessionCallCount = 0

        func getCurrentSession() async throws -> UserSession? {
            getCurrentSessionCallCount += 1
            if let error = stubbedError {
                throw error
            }
            return stubbedSession
        }

        func saveSession(_ session: UserSession) async throws {
            stubbedSession = session
        }

        func clearSession() async throws {
            clearSessionCallCount += 1
            stubbedSession = nil
        }
    }

    // MARK: - Tests: No Session

    func testExecute_whenNoSession_returnsUnauthenticated() async {
        // Arrange
        let repository = SessionRepositoryFake()
        repository.stubbedSession = nil

        let sut = DefaultRestoreSessionUseCase(sessionRepository: repository)

        // Act
        let result = await sut.execute()

        // Assert
        XCTAssertEqual(result, .unauthenticated)
        XCTAssertEqual(repository.getCurrentSessionCallCount, 1)
    }

    // MARK: - Tests: Valid Session

    func testExecute_whenSessionValid_returnsAuthenticated() async {
        // Arrange
        let validSession = UserSession(
            userId: "user123",
            accessToken: "valid_token",
            refreshToken: "valid_refresh_token",
            expiresAt: Date().addingTimeInterval(3600) // Expires in 1 hour
        )

        let repository = SessionRepositoryFake()
        repository.stubbedSession = validSession

        let sut = DefaultRestoreSessionUseCase(sessionRepository: repository)

        // Act
        let result = await sut.execute()

        // Assert
        XCTAssertEqual(result, .authenticated)
        XCTAssertEqual(repository.getCurrentSessionCallCount, 1)
        XCTAssertEqual(repository.clearSessionCallCount, 0, "Should not clear valid session")
    }

    // MARK: - Tests: Expired Session

    func testExecute_whenSessionExpired_returnsUnauthenticatedAndClearsSession() async {
        // Arrange
        let expiredSession = UserSession(
            userId: "user123",
            accessToken: "expired_token",
            refreshToken: "expired_refresh_token",
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )

        let repository = SessionRepositoryFake()
        repository.stubbedSession = expiredSession

        let sut = DefaultRestoreSessionUseCase(sessionRepository: repository)

        // Act
        let result = await sut.execute()

        // Assert
        XCTAssertEqual(result, .unauthenticated)
        XCTAssertEqual(repository.getCurrentSessionCallCount, 1)
        XCTAssertEqual(repository.clearSessionCallCount, 1, "Should clear expired session")
    }

    // MARK: - Tests: Repository Error

    func testExecute_whenRepositoryThrows_returnsUnauthenticated() async {
        // Arrange
        enum TestError: Error {
            case repositoryFailed
        }

        let repository = SessionRepositoryFake()
        repository.stubbedError = TestError.repositoryFailed

        let sut = DefaultRestoreSessionUseCase(sessionRepository: repository)

        // Act
        let result = await sut.execute()

        // Assert
        XCTAssertEqual(result, .unauthenticated, "Should fall back to unauthenticated on error")
        XCTAssertEqual(repository.getCurrentSessionCallCount, 1)
    }

    // MARK: - Tests: Session Validation

    func testExecute_whenSessionExpiresInOneSecond_returnsAuthenticated() async {
        // Arrange
        let almostExpiredSession = UserSession(
            userId: "user123",
            accessToken: "token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(1) // Expires in 1 second
        )

        let repository = SessionRepositoryFake()
        repository.stubbedSession = almostExpiredSession

        let sut = DefaultRestoreSessionUseCase(sessionRepository: repository)

        // Act
        let result = await sut.execute()

        // Assert
        XCTAssertEqual(result, .authenticated, "Session is still valid if not yet expired")
    }

    func testExecute_whenSessionExpiredOneSecondAgo_returnsUnauthenticated() async {
        // Arrange
        let justExpiredSession = UserSession(
            userId: "user123",
            accessToken: "token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(-1) // Expired 1 second ago
        )

        let repository = SessionRepositoryFake()
        repository.stubbedSession = justExpiredSession

        let sut = DefaultRestoreSessionUseCase(sessionRepository: repository)

        // Act
        let result = await sut.execute()

        // Assert
        XCTAssertEqual(result, .unauthenticated, "Session is invalid if expired")
        XCTAssertEqual(repository.clearSessionCallCount, 1, "Should clear expired session")
    }
}
