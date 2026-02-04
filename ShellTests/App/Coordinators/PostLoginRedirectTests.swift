//
//  PostLoginRedirectTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

final class PostLoginRedirectTests: XCTestCase {

    private var sut: AppCoordinator!
    private var window: UIWindow!
    private var navigationController: UINavigationController!
    private var dependencyContainer: AppDependencyContainer!

    // MARK: - Test Doubles

    private struct NoOpLogger: Logger {
        func debug(_ message: String, category: String?, context: [String : String]?) {}
        func info(_ message: String, category: String?, context: [String : String]?) {}
        func warning(_ message: String, category: String?, context: [String : String]?) {}
        func error(_ message: String, category: String?, context: [String : String]?) {}
        func fault(_ message: String, category: String?, context: [String : String]?) {}
    }

    override func setUp() {
        super.setUp()
        window = UIWindow()
        navigationController = UINavigationController()
        dependencyContainer = AppDependencyContainer()
        sut = AppCoordinator(
            window: window,
            navigationController: navigationController,
            dependencyContainer: dependencyContainer,
            logger: NoOpLogger()
        )
    }

    override func tearDown() {
        sut = nil
        navigationController = nil
        window = nil
        dependencyContainer = nil
        super.tearDown()
    }

    // MARK: - Save Intended Route Tests

    func testSaveIntendedRoute_storesRoute() {
        // Given
        let route = Route.profile(userID: "user123")

        // When
        sut.saveIntendedRoute(route)

        // Then
        let restored = sut.restorePendingRoute()
        XCTAssertEqual(restored, route)
    }

    func testSaveIntendedRoute_replacesExistingRoute() {
        // Given
        let firstRoute = Route.profile(userID: "user123")
        let secondRoute = Route.settings(section: .account)

        // When
        sut.saveIntendedRoute(firstRoute)
        sut.saveIntendedRoute(secondRoute)

        // Then
        let restored = sut.restorePendingRoute()
        XCTAssertEqual(restored, secondRoute)
        XCTAssertNotEqual(restored, firstRoute)
    }

    // MARK: - Restore Pending Route Tests

    func testRestorePendingRoute_returnsNilWhenNothingSaved() {
        // When
        let restored = sut.restorePendingRoute()

        // Then
        XCTAssertNil(restored)
    }

    func testRestorePendingRoute_returnsSavedRoute() {
        // Given
        let route = Route.profile(userID: "user123")
        sut.saveIntendedRoute(route)

        // When
        let restored = sut.restorePendingRoute()

        // Then
        XCTAssertEqual(restored, route)
    }

    func testRestorePendingRoute_clearsRouteAfterReturning() {
        // Given
        let route = Route.profile(userID: "user123")
        sut.saveIntendedRoute(route)

        // When
        let firstRestore = sut.restorePendingRoute()
        let secondRestore = sut.restorePendingRoute()

        // Then
        XCTAssertEqual(firstRestore, route)
        XCTAssertNil(secondRestore, "Route should be cleared after first restore")
    }

    // MARK: - Clear Pending Route Tests

    func testClearPendingRoute_removesStoredRoute() {
        // Given
        let route = Route.profile(userID: "user123")
        sut.saveIntendedRoute(route)

        // When
        sut.clearPendingRoute()

        // Then
        let restored = sut.restorePendingRoute()
        XCTAssertNil(restored)
    }

    func testClearPendingRoute_whenNoRouteStored_doesNothing() {
        // When - Should not crash
        sut.clearPendingRoute()

        // Then
        let restored = sut.restorePendingRoute()
        XCTAssertNil(restored)
    }

    // MARK: - Integration Tests

    func testPostLoginFlow_restoresIntendedRoute() {
        // Given
        let intendedRoute = Route.profile(userID: "user123")
        sut.saveIntendedRoute(intendedRoute)

        // When - Simulate login completion
        let restored = sut.restorePendingRoute()

        // Then
        XCTAssertEqual(restored, intendedRoute)
    }

    func testLogoutFlow_clearsPendingRoute() {
        // Given
        let route = Route.profile(userID: "user123")
        sut.saveIntendedRoute(route)

        // When - Simulate logout
        sut.clearPendingRoute()

        // Then
        let restored = sut.restorePendingRoute()
        XCTAssertNil(restored, "Pending route should be cleared on logout")
    }

    func testMultipleLoginAttempts_onlyRestoresOnce() {
        // Given
        let route = Route.settings(section: .privacy)
        sut.saveIntendedRoute(route)

        // When - First login attempt restores route
        let firstRestore = sut.restorePendingRoute()

        // Second login attempt should not restore (already cleared)
        let secondRestore = sut.restorePendingRoute()

        // Then
        XCTAssertEqual(firstRestore, route)
        XCTAssertNil(secondRestore, "Route should only restore once")
    }

    func testSaveRoute_withDifferentRouteTypes() {
        // Test that different route types can be saved and restored

        let testRoutes: [Route] = [
            .home,
            .profile(userID: "test123"),
            .settings(section: .account),
            .settings(section: nil),
            .identitySetup(step: .screenName),
            .identitySetup(step: nil)
        ]

        for route in testRoutes {
            // Given
            sut.clearPendingRoute() // Clear previous

            // When
            sut.saveIntendedRoute(route)
            let restored = sut.restorePendingRoute()

            // Then
            XCTAssertEqual(restored, route, "Route type \(route) should be saved and restored correctly")
        }
    }
}
