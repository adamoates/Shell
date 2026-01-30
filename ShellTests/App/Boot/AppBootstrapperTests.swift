//
//  AppBootstrapperTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for AppBootstrapper
/// Following TDD with clean test doubles (Fakes and Spies)
final class AppBootstrapperTests: XCTestCase {

    // MARK: - Test Doubles

    /// Fake RestoreSessionUseCase - returns stubbed status
    private final class RestoreSessionUseCaseFake: RestoreSessionUseCase {
        private let status: SessionStatus
        private(set) var executeCallCount = 0

        init(status: SessionStatus) {
            self.status = status
        }

        func execute() async -> SessionStatus {
            executeCallCount += 1
            return status
        }
    }

    /// Spy LaunchRouter - records routed states
    private final class LaunchRouterSpy: LaunchRouting {
        private(set) var routedStates: [LaunchState] = []
        var onRoute: (() -> Void)?

        func route(to state: LaunchState) {
            routedStates.append(state)
            onRoute?()
        }
    }

    // MARK: - Tests: Authenticated Flow

    func testStart_whenSessionAuthenticated_routesToAuthenticated() async {
        // Arrange
        let restoreSession = RestoreSessionUseCaseFake(status: .authenticated)

        let router = LaunchRouterSpy()
        let routed = expectation(description: "Wait for routing")
        router.onRoute = { routed.fulfill() }

        let sut = AppBootstrapper(restoreSession: restoreSession, router: router)

        // Act
        sut.start()
        await fulfillment(of: [routed], timeout: 1.0)

        // Assert
        XCTAssertEqual(restoreSession.executeCallCount, 1)
        XCTAssertEqual(router.routedStates, [.authenticated])
    }

    // MARK: - Tests: Unauthenticated Flow

    func testStart_whenSessionUnauthenticated_routesToUnauthenticated() async {
        // Arrange
        let restoreSession = RestoreSessionUseCaseFake(status: .unauthenticated)

        let router = LaunchRouterSpy()
        let routed = expectation(description: "Wait for routing")
        router.onRoute = { routed.fulfill() }

        let sut = AppBootstrapper(restoreSession: restoreSession, router: router)

        // Act
        sut.start()
        await fulfillment(of: [routed], timeout: 1.0)

        // Assert
        XCTAssertEqual(restoreSession.executeCallCount, 1)
        XCTAssertEqual(router.routedStates, [.unauthenticated])
    }

    // MARK: - Tests: Locked Flow

    func testStart_whenSessionLocked_routesToLocked() async {
        // Arrange
        let restoreSession = RestoreSessionUseCaseFake(status: .locked)

        let router = LaunchRouterSpy()
        let routed = expectation(description: "Wait for routing")
        router.onRoute = { routed.fulfill() }

        let sut = AppBootstrapper(restoreSession: restoreSession, router: router)

        // Act
        sut.start()
        await fulfillment(of: [routed], timeout: 1.0)

        // Assert
        XCTAssertEqual(restoreSession.executeCallCount, 1)
        XCTAssertEqual(router.routedStates, [.locked])
    }

    // MARK: - Tests: Use Case Invocation

    func testStart_invokesRestoreSessionExactlyOnce() async {
        // Arrange
        let restoreSession = RestoreSessionUseCaseFake(status: .authenticated)

        let router = LaunchRouterSpy()
        let routed = expectation(description: "Wait for routing")
        router.onRoute = { routed.fulfill() }

        let sut = AppBootstrapper(restoreSession: restoreSession, router: router)

        // Act
        sut.start()
        await fulfillment(of: [routed], timeout: 1.0)

        // Assert
        XCTAssertEqual(restoreSession.executeCallCount, 1, "Should call restore session exactly once")
    }

    func testStart_routesExactlyOnce() async {
        // Arrange
        let restoreSession = RestoreSessionUseCaseFake(status: .unauthenticated)

        let router = LaunchRouterSpy()
        let routed = expectation(description: "Wait for routing")
        router.onRoute = { routed.fulfill() }

        let sut = AppBootstrapper(restoreSession: restoreSession, router: router)

        // Act
        sut.start()
        await fulfillment(of: [routed], timeout: 1.0)

        // Assert
        XCTAssertEqual(router.routedStates.count, 1, "Should route exactly once")
    }
}
