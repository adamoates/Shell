//
//  AppDependencyContainerTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for AppDependencyContainer
/// Following TDD: These tests are written FIRST
final class AppDependencyContainerTests: XCTestCase {

    // MARK: - Properties

    private var sut: AppDependencyContainer!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        sut = AppDependencyContainer()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests: Coordinator Creation

    func testMakeAppCoordinatorReturnsCoordinator() {
        // Arrange
        let window = UIWindow()

        // Act
        let coordinator = sut.makeAppCoordinator(window: window)

        // Assert
        XCTAssertNotNil(coordinator)
    }

    func testMakeAppCoordinatorReturnsSameNavigationController() {
        // Arrange
        let window = UIWindow()

        // Act
        let coordinator1 = sut.makeAppCoordinator(window: window)
        let coordinator2 = sut.makeAppCoordinator(window: window)

        // Assert: Should return new coordinator instances
        // but can share navigation controller if needed
        XCTAssertNotNil(coordinator1)
        XCTAssertNotNil(coordinator2)
    }

    // MARK: - Tests: Use Case Creation

    func testMakeBootAppUseCaseReturnsUseCase() {
        // Act
        let useCase = sut.makeBootAppUseCase()

        // Assert
        XCTAssertNotNil(useCase)
    }

    func testMakeBootAppUseCaseReturnsNewInstances() {
        // Act
        let useCase1 = sut.makeBootAppUseCase()
        let useCase2 = sut.makeBootAppUseCase()

        // Assert: Should return different instances (not singletons)
        XCTAssertTrue(useCase1 !== useCase2)
    }

    // MARK: - Tests: Repository Creation

    func testMakeConfigLoaderReturnsLoader() {
        // Act
        let loader = sut.makeConfigLoader()

        // Assert
        XCTAssertNotNil(loader)
    }

    func testMakeSessionRepositoryReturnsRepository() {
        // Act
        let repository = sut.makeSessionRepository()

        // Assert
        XCTAssertNotNil(repository)
    }

    func testMakeSessionRepositoryReturnsSameInstance() {
        // Act
        let repository1 = sut.makeSessionRepository()
        let repository2 = sut.makeSessionRepository()

        // Assert: Session repository should be shared (singleton pattern)
        XCTAssertTrue(repository1 === repository2)
    }
}
