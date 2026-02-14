//
//  AuthGuardTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for AuthGuard
/// Verifies route access control based on session state
final class AuthGuardTests: XCTestCase {
    private var sut: AuthGuard!
    private var mockRepository: SessionRepositoryFake!

    // MARK: - Test Doubles

    private struct NoOpLogger: Logger {
        func debug(_ message: String, category: String?, context: [String : String]?) {}
        func info(_ message: String, category: String?, context: [String : String]?) {}
        func warning(_ message: String, category: String?, context: [String : String]?) {}
        func error(_ message: String, category: String?, context: [String : String]?) {}
        func fault(_ message: String, category: String?, context: [String : String]?) {}
    }

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

    override func setUp() {
        super.setUp()
        mockRepository = SessionRepositoryFake()
        sut = AuthGuard(sessionRepository: mockRepository, logger: NoOpLogger())
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Unauthenticated Routes

    func testCanAccess_loginRoute_alwaysAllows() async {
        // No session needed for login
        mockRepository.stubbedSession = nil

        let decision = await sut.canAccess(route: .login)

        XCTAssertEqual(decision, .allowed)
        XCTAssertEqual(mockRepository.getCurrentSessionCallCount, 0, "Should not check session for unauthenticated routes")
    }

    func testCanAccess_signupRoute_alwaysAllows() async {
        mockRepository.stubbedSession = nil

        let decision = await sut.canAccess(route: .signup)

        XCTAssertEqual(decision, .allowed)
    }

    func testCanAccess_forgotPasswordRoute_alwaysAllows() async {
        mockRepository.stubbedSession = nil

        let decision = await sut.canAccess(route: .forgotPassword)

        XCTAssertEqual(decision, .allowed)
    }

    // MARK: - Authenticated Routes With Valid Session

    func testCanAccess_homeWithValidSession_allows() async {
        let validSession = UserSession(
            userId: "user123",
            accessToken: "token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(3600) // Expires in 1 hour
        )
        mockRepository.stubbedSession = validSession

        let decision = await sut.canAccess(route: .home)

        XCTAssertEqual(decision, .allowed)
        XCTAssertEqual(mockRepository.getCurrentSessionCallCount, 1)
    }

    func testCanAccess_profileWithValidSession_allows() async {
        let validSession = UserSession(
            userId: "user123",
            accessToken: "token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        mockRepository.stubbedSession = validSession

        let decision = await sut.canAccess(route: .profile(userID: "user456"))

        XCTAssertEqual(decision, .allowed)
    }

    func testCanAccess_settingsWithValidSession_allows() async {
        let validSession = UserSession(
            userId: "user123",
            accessToken: "token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        mockRepository.stubbedSession = validSession

        let decision = await sut.canAccess(route: .settings(section: .privacy))

        XCTAssertEqual(decision, .allowed)
    }

    // MARK: - Authenticated Routes Without Session

    func testCanAccess_homeWithoutSession_deniesWithUnauthenticated() async {
        mockRepository.stubbedSession = nil

        let decision = await sut.canAccess(route: .home)

        if case .denied(let reason) = decision {
            XCTAssertEqual(reason, .unauthenticated)
        } else {
            XCTFail("Expected denied with unauthenticated reason")
        }
    }

    func testCanAccess_profileWithoutSession_deniesWithUnauthenticated() async {
        mockRepository.stubbedSession = nil

        let decision = await sut.canAccess(route: .profile(userID: "user123"))

        if case .denied(let reason) = decision {
            XCTAssertEqual(reason, .unauthenticated)
        } else {
            XCTFail("Expected denied with unauthenticated reason")
        }
    }

    // MARK: - Authenticated Routes With Expired Session

    func testCanAccess_homeWithExpiredSession_deniesAndClearsSession() async {
        let expiredSession = UserSession(
            userId: "user123",
            accessToken: "token",
            refreshToken: "refresh-token",
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )
        mockRepository.stubbedSession = expiredSession

        let decision = await sut.canAccess(route: .home)

        if case .denied(let reason) = decision {
            XCTAssertEqual(reason, .unauthenticated)
            XCTAssertEqual(mockRepository.clearSessionCallCount, 1, "Should clear expired session")
        } else {
            XCTFail("Expected denied with unauthenticated reason")
        }
    }

    // MARK: - Repository Error

    func testCanAccess_repositoryThrows_deniesWithUnauthenticated() async {
        enum TestError: Error {
            case repositoryFailed
        }
        mockRepository.stubbedError = TestError.repositoryFailed

        let decision = await sut.canAccess(route: .home)

        if case .denied(let reason) = decision {
            XCTAssertEqual(reason, .unauthenticated)
        } else {
            XCTFail("Expected denied with unauthenticated reason")
        }
    }
}
