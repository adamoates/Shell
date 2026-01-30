//
//  AppCoordinator.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit

/// Root coordinator for the entire application
///
/// Responsibilities:
/// - Boot the application
/// - Determine initial route (guest vs authenticated)
/// - Manage global navigation state
/// - Handle deep links
final class AppCoordinator: Coordinator {
    // MARK: - Properties

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?

    private let window: UIWindow
    private let bootUseCase: BootAppUseCase

    // MARK: - Initialization

    init(
        window: UIWindow,
        navigationController: UINavigationController,
        bootUseCase: BootAppUseCase
    ) {
        self.window = window
        self.navigationController = navigationController
        self.bootUseCase = bootUseCase
    }

    // MARK: - Coordinator

    func start() {
        Task { @MainActor in
            await boot()
        }
    }

    func finish() {
        // App coordinator doesn't finish
    }

    // MARK: - Private

    @MainActor
    private func boot() async {
        do {
            let result = try await bootUseCase.execute()
            showInitialFlow(for: result)
        } catch {
            showErrorState(error)
        }
    }

    @MainActor
    private func showInitialFlow(for result: BootResult) {
        switch result.initialRoute {
        case .authenticated:
            showAuthenticatedFlow()
        case .guest:
            showGuestFlow()
        }

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    @MainActor
    private func showGuestFlow() {
        // For now, show a simple placeholder view controller
        let viewController = createPlaceholderViewController(title: "Welcome")
        navigationController.setViewControllers([viewController], animated: false)
    }

    @MainActor
    private func showAuthenticatedFlow() {
        // For now, show a simple placeholder view controller
        let viewController = createPlaceholderViewController(title: "Home")
        navigationController.setViewControllers([viewController], animated: false)
    }

    @MainActor
    private func showErrorState(_ error: Error) {
        let viewController = createPlaceholderViewController(
            title: "Error",
            message: "Failed to boot: \(error.localizedDescription)"
        )
        navigationController.setViewControllers([viewController], animated: false)

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    @MainActor
    private func createPlaceholderViewController(
        title: String,
        message: String? = nil
    ) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .systemBackground
        viewController.title = title

        let label = UILabel()
        label.text = message ?? title
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false

        viewController.view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: viewController.view.centerYAnchor),
            label.leadingAnchor.constraint(
                equalTo: viewController.view.leadingAnchor,
                constant: 20
            ),
            label.trailingAnchor.constraint(
                equalTo: viewController.view.trailingAnchor,
                constant: -20
            )
        ])

        return viewController
    }
}
