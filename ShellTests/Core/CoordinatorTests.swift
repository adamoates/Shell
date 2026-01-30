//
//  CoordinatorTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for Coordinator protocol and base implementation
/// Following TDD: These tests are written FIRST, before implementation
final class CoordinatorTests: XCTestCase {

    // MARK: - Test Doubles

    private class MockChildCoordinator: Coordinator {
        var navigationController: UINavigationController
        var childCoordinators: [Coordinator] = []
        var parentCoordinator: Coordinator?

        var startCalled = false
        var finishCalled = false

        init(navigationController: UINavigationController = UINavigationController()) {
            self.navigationController = navigationController
        }

        func start() {
            startCalled = true
        }

        func finish() {
            finishCalled = true
            parentCoordinator?.childDidFinish(self)
        }
    }

    // MARK: - Properties

    private var sut: MockChildCoordinator!
    private var navigationController: UINavigationController!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        navigationController = UINavigationController()
        sut = MockChildCoordinator(navigationController: navigationController)
    }

    override func tearDown() {
        sut = nil
        navigationController = nil
        super.tearDown()
    }

    // MARK: - Tests: Coordinator Protocol

    func testCoordinatorHasNavigationController() {
        // Assert
        XCTAssertNotNil(sut.navigationController)
        XCTAssertEqual(sut.navigationController, navigationController)
    }

    func testCoordinatorHasChildCoordinatorsArray() {
        // Assert
        XCTAssertNotNil(sut.childCoordinators)
        XCTAssertTrue(sut.childCoordinators.isEmpty)
    }

    func testCoordinatorCanHaveParent() {
        // Arrange
        let parent = MockChildCoordinator()

        // Act
        sut.parentCoordinator = parent

        // Assert
        XCTAssertNotNil(sut.parentCoordinator)
    }

    func testStartMethodIsCalled() {
        // Act
        sut.start()

        // Assert
        XCTAssertTrue(sut.startCalled)
    }

    func testFinishMethodIsCalled() {
        // Act
        sut.finish()

        // Assert
        XCTAssertTrue(sut.finishCalled)
    }

    // MARK: - Tests: Child Coordinator Management

    func testAddChildCoordinator() {
        // Arrange
        let child = MockChildCoordinator()

        // Act
        sut.addChild(child)

        // Assert
        XCTAssertEqual(sut.childCoordinators.count, 1)
        XCTAssertTrue(sut.childCoordinators.contains(where: { $0 === child }))
        XCTAssertTrue(child.parentCoordinator === sut)
    }

    func testRemoveChildCoordinator() {
        // Arrange
        let child = MockChildCoordinator()
        sut.addChild(child)

        // Act
        sut.removeChild(child)

        // Assert
        XCTAssertEqual(sut.childCoordinators.count, 0)
        XCTAssertNil(child.parentCoordinator)
    }

    func testChildDidFinishRemovesChild() {
        // Arrange
        let child = MockChildCoordinator()
        sut.addChild(child)

        // Act
        child.finish()

        // Assert
        XCTAssertEqual(sut.childCoordinators.count, 0)
    }

    func testAddingSameChildTwiceDoesNotDuplicate() {
        // Arrange
        let child = MockChildCoordinator()

        // Act
        sut.addChild(child)
        sut.addChild(child)

        // Assert
        XCTAssertEqual(sut.childCoordinators.count, 1)
    }

    func testRemoveAllChildCoordinators() {
        // Arrange
        let child1 = MockChildCoordinator()
        let child2 = MockChildCoordinator()
        sut.addChild(child1)
        sut.addChild(child2)

        // Act
        sut.removeAllChildren()

        // Assert
        XCTAssertEqual(sut.childCoordinators.count, 0)
        XCTAssertNil(child1.parentCoordinator)
        XCTAssertNil(child2.parentCoordinator)
    }
}
