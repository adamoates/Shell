//
//  BootAppUseCaseTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for BootApp use case
/// Following TDD: These tests are written FIRST
///
/// BootApp is responsible for:
/// - Loading app configuration
/// - Restoring user session if available
/// - Determining initial route (authenticated vs guest)
final class BootAppUseCaseTests: XCTestCase {

    // MARK: - Test Doubles

    private class MockConfigLoader: ConfigLoader {
        var stubbedConfig: AppConfig?
        var stubbedError: Error?

        func loadConfig() async throws -> AppConfig {
            if let error = stubbedError {
                throw error
            }
            return stubbedConfig ?? AppConfig(environment: .development)
        }
    }

    private class MockSessionRepository: SessionRepository {
        var stubbedSession: UserSession?
        var stubbedError: Error?

        func getCurrentSession() async throws -> UserSession? {
            if let error = stubbedError {
                throw error
            }
            return stubbedSession
        }

        func saveSession(_ session: UserSession) async throws {
            stubbedSession = session
        }

        func clearSession() async throws {
            stubbedSession = nil
        }
    }

    // MARK: - Properties

    private var sut: BootAppUseCase!
    private var mockConfigLoader: MockConfigLoader!
    private var mockSessionRepository: MockSessionRepository!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        mockConfigLoader = MockConfigLoader()
        mockSessionRepository = MockSessionRepository()
        sut = DefaultBootAppUseCase(
            configLoader: mockConfigLoader,
            sessionRepository: mockSessionRepository
        )
    }

    override func tearDown() {
        sut = nil
        mockConfigLoader = nil
        mockSessionRepository = nil
        super.tearDown()
    }

    // MARK: - Tests: Successful Boot

    func testExecuteWithNoSessionReturnsGuestRoute() async throws {
        // Arrange
        mockConfigLoader.stubbedConfig = AppConfig(environment: .development)
        mockSessionRepository.stubbedSession = nil

        // Act
        let result = try await sut.execute()

        // Assert
        XCTAssertEqual(result.initialRoute, .guest)
        XCTAssertEqual(result.config.environment, .development)
        XCTAssertNil(result.session)
    }

    func testExecuteWithValidSessionReturnsAuthenticatedRoute() async throws {
        // Arrange
        mockConfigLoader.stubbedConfig = AppConfig(environment: .production)
        let session = UserSession(
            userId: "user123",
            accessToken: "valid_token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        mockSessionRepository.stubbedSession = session

        // Act
        let result = try await sut.execute()

        // Assert
        XCTAssertEqual(result.initialRoute, .authenticated)
        XCTAssertEqual(result.config.environment, .production)
        XCTAssertNotNil(result.session)
        XCTAssertEqual(result.session?.userId, "user123")
    }

    func testExecuteWithExpiredSessionReturnsGuestRoute() async throws {
        // Arrange
        mockConfigLoader.stubbedConfig = AppConfig(environment: .development)
        let expiredSession = UserSession(
            userId: "user123",
            accessToken: "expired_token",
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )
        mockSessionRepository.stubbedSession = expiredSession

        // Act
        let result = try await sut.execute()

        // Assert
        XCTAssertEqual(result.initialRoute, .guest)
        XCTAssertNil(result.session)
    }

    // MARK: - Tests: Error Handling

    func testExecuteWithConfigLoadErrorThrows() async {
        // Arrange
        enum TestError: Error {
            case configLoadFailed
        }
        mockConfigLoader.stubbedError = TestError.configLoadFailed

        // Act & Assert
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func testExecuteWithSessionRepositoryErrorReturnsGuestRoute() async throws {
        // Arrange
        enum TestError: Error {
            case sessionLoadFailed
        }
        mockConfigLoader.stubbedConfig = AppConfig(environment: .development)
        mockSessionRepository.stubbedError = TestError.sessionLoadFailed

        // Act
        let result = try await sut.execute()

        // Assert: If session loading fails, fall back to guest mode
        XCTAssertEqual(result.initialRoute, .guest)
        XCTAssertNil(result.session)
    }

    // MARK: - Tests: Performance

    func testExecuteCompletesFast() async throws {
        // Arrange
        mockConfigLoader.stubbedConfig = AppConfig(environment: .development)
        mockSessionRepository.stubbedSession = nil

        // Act
        let start = Date()
        _ = try await sut.execute()
        let duration = Date().timeIntervalSince(start)

        // Assert: Boot should complete in < 100ms
        XCTAssertLessThan(duration, 0.1)
    }
}
