//
//  Coordinator.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit

/// Protocol defining the Coordinator pattern for navigation
///
/// Coordinators are responsible for:
/// - Managing navigation flow
/// - Creating and presenting view controllers
/// - Managing child coordinators
/// - Handling deep links and routing
///
/// This protocol ensures:
/// - UI is decoupled from navigation logic
/// - Navigation can be tested independently
/// - Child coordinator lifecycle is managed properly
protocol Coordinator: AnyObject {
    /// The navigation controller managed by this coordinator
    var navigationController: UINavigationController { get }

    /// Child coordinators owned by this coordinator
    var childCoordinators: [Coordinator] { get set }

    /// Parent coordinator (weak reference to avoid retain cycles)
    var parentCoordinator: Coordinator? { get set }

    /// Start the coordinator's flow
    func start()

    /// Finish the coordinator's flow and notify parent
    func finish()
}

// MARK: - Default Implementation

extension Coordinator {
    /// Add a child coordinator
    /// - Parameter child: The child coordinator to add
    func addChild(_ child: Coordinator) {
        // Prevent duplicates
        guard !childCoordinators.contains(where: { $0 === child }) else {
            return
        }

        childCoordinators.append(child)
        child.parentCoordinator = self
    }

    /// Remove a child coordinator
    /// - Parameter child: The child coordinator to remove
    func removeChild(_ child: Coordinator) {
        childCoordinators.removeAll(where: { $0 === child })
        child.parentCoordinator = nil
    }

    /// Remove all child coordinators
    func removeAllChildren() {
        childCoordinators.forEach { $0.parentCoordinator = nil }
        childCoordinators.removeAll()
    }

    /// Called when a child coordinator has finished
    /// - Parameter child: The child coordinator that finished
    func childDidFinish(_ child: Coordinator) {
        removeChild(child)
    }
}
