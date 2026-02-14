//
//  AuthCoordinator.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit

/// Protocol for LoginViewController to communicate with coordinator
protocol LoginViewControllerDelegate: AnyObject {
    func loginViewController(_ controller: LoginViewController, didLoginWithUsername username: String)
}

/// Protocol for AuthCoordinator to communicate completion back to parent
protocol AuthCoordinatorDelegate: AnyObject {
    func authCoordinatorDidCompleteLogin(_ coordinator: AuthCoordinator, username: String)
}

/// Coordinator responsible for authentication flows
///
/// Manages:
/// - Login flow
/// - Signup flow (future)
/// - Forgot password flow (future)
final class AuthCoordinator: Coordinator {
    // MARK: - Properties

    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?
    weak var delegate: AuthCoordinatorDelegate?

    private let validateCredentials: ValidateCredentialsUseCase
    private let loginUseCase: LoginUseCase
    private let logger: Logger

    // MARK: - Initialization

    init(
        navigationController: UINavigationController,
        validateCredentials: ValidateCredentialsUseCase,
        login: LoginUseCase,
        logger: Logger
    ) {
        self.navigationController = navigationController
        self.validateCredentials = validateCredentials
        self.loginUseCase = login
        self.logger = logger
    }

    // MARK: - Coordinator

    func start() {
        showLogin()
    }

    func finish() {
        parentCoordinator?.childDidFinish(self)
    }

    // MARK: - Navigation

    @MainActor
    private func showLogin() {
        // Create and inject ViewModel
        let viewModel = LoginViewModel(
            validateCredentials: validateCredentials,
            login: loginUseCase
        )
        let loginVC = LoginViewController(viewModel: viewModel)
        loginVC.delegate = self

        navigationController.setViewControllers([loginVC], animated: false)
    }
}

// MARK: - LoginViewControllerDelegate

extension AuthCoordinator: LoginViewControllerDelegate {
    func loginViewController(_ controller: LoginViewController, didLoginWithUsername username: String) {
        logger.info("Login completed", category: "coordinator", context: ["username": username])
        delegate?.authCoordinatorDidCompleteLogin(self, username: username)
    }
}
