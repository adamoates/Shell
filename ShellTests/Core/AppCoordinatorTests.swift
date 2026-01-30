//
//  AppCoordinatorTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for AppCoordinator
/// Following TDD: These tests are written FIRST
final class AppCoordinatorTests: XCTestCase {

    // MARK: - Test Doubles

    private class MockBootAppUseCase: BootAppUseCase {
        var stubbedResult: BootResult?
        var stubbedError: Error?

        func execute() async throws -> BootResult {
            if let error = stubbedError {
                throw error
            }
            return stubbedResult ?? BootResult(
                initialRoute: .guest,
                config: AppConfig(environment: .development),
                session: nil
            )
        }
    }

    private class SpyWindow: UIWindow {
        var rootViewControllerSetCount = 0
        var lastRootViewController: UIViewController?

        override var rootViewController: UIViewController? {
            get { super.rootViewController }
            set {
                rootViewControllerSetCount += 1
                lastRootViewController = newValue
                super.rootViewController = newValue
            }
        }
    }

    // MARK: - Properties

    private var sut: AppCoordinator!
    private var mockBootUseCase: MockBootAppUseCase!
    private var window: SpyWindow!
    private var navigationController: UINavigationController!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        mockBootUseCase = MockBootAppUseCase()
        window = SpyWindow()
        navigationController = UINavigationController()
        sut = AppCoordinator(
            window: window,
            navigationController: navigationController,
            bootUseCase: mockBootUseCase
        )
    }

    override func tearDown() {
        sut = nil
        mockBootUseCase = nil
        window = nil
        navigationController = nil
        super.tearDown()
    }

    // MARK: - Tests: Initialization

    func testCoordinatorHasNavigationController() {
        // Assert
        XCTAssertEqual(sut.navigationController, navigationController)
    }

    func testCoordinatorInitiallyHasNoChildren() {
        // Assert
        XCTAssertTrue(sut.childCoordinators.isEmpty)
    }

    // MARK: - Tests: Boot Flow

    func testStartBootsAppAndSetsWindowRoot() async {
        // Arrange
        mockBootUseCase.stubbedResult = BootResult(
            initialRoute: .guest,
            config: AppConfig(environment: .development),
            session: nil
        )

        // Act
        await sut.start()

        // Assert
        XCTAssertEqual(window.rootViewControllerSetCount, 1)
        XCTAssertEqual(window.rootViewController, navigationController)
    }

    func testStartWithGuestRouteShowsGuestFlow() async {
        // Arrange
        mockBootUseCase.stubbedResult = BootResult(
            initialRoute: .guest,
            config: AppConfig(environment: .development),
            session: nil
        )

        // Act
        await sut.start()

        // Assert
        XCTAssertFalse(navigationController.viewControllers.isEmpty)
    }

    func testStartWithAuthenticatedRouteShowsAuthenticatedFlow() async {
        // Arrange
        let session = UserSession(
            userId: "user123",
            accessToken: "token",
            expiresAt: Date().addingTimeInterval(3600)
        )
        mockBootUseCase.stubbedResult = BootResult(
            initialRoute: .authenticated,
            config: AppConfig(environment: .production),
            session: session
        )

        // Act
        await sut.start()

        // Assert
        XCTAssertFalse(navigationController.viewControllers.isEmpty)
    }

    func testStartWithBootErrorShowsErrorState() async {
        // Arrange
        enum TestError: Error {
            case bootFailed
        }
        mockBootUseCase.stubbedError = TestError.bootFailed

        // Act
        await sut.start()

        // Assert: Should still set window root even on error
        XCTAssertEqual(window.rootViewControllerSetCount, 1)
        XCTAssertFalse(navigationController.viewControllers.isEmpty)
    }
}
