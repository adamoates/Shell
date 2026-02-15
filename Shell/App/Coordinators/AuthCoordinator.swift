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
    func loginViewControllerDidRequestSignUp(_ controller: LoginViewController)
    func loginViewControllerDidRequestForgotPassword(_ controller: LoginViewController)
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
    private let registerUseCase: RegisterUseCase
    private let logger: Logger

    // MARK: - Initialization

    init(
        navigationController: UINavigationController,
        validateCredentials: ValidateCredentialsUseCase,
        login: LoginUseCase,
        register: RegisterUseCase,
        logger: Logger
    ) {
        self.navigationController = navigationController
        self.validateCredentials = validateCredentials
        self.loginUseCase = login
        self.registerUseCase = register
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

    @MainActor
    private func showSignUp() {
        // Create and inject ViewModel
        let viewModel = SignUpViewModel(registerUseCase: registerUseCase)
        let signUpVC = SignUpViewController(viewModel: viewModel)
        signUpVC.delegate = self

        navigationController.pushViewController(signUpVC, animated: true)
    }

    @MainActor
    private func showForgotPassword() {
        // TODO: Implement forgot password flow when backend endpoint is ready
        let alert = UIAlertController(
            title: "Forgot Password",
            message: "Password reset is not yet available. Please contact support.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        navigationController.present(alert, animated: true)
    }
}

// MARK: - LoginViewControllerDelegate

extension AuthCoordinator: LoginViewControllerDelegate {
    func loginViewController(_ controller: LoginViewController, didLoginWithUsername username: String) {
        logger.info("Login completed", category: "coordinator", context: ["username": username])
        delegate?.authCoordinatorDidCompleteLogin(self, username: username)
    }

    func loginViewControllerDidRequestSignUp(_ controller: LoginViewController) {
        logger.info("Sign up requested", category: "coordinator")
        showSignUp()
    }

    func loginViewControllerDidRequestForgotPassword(_ controller: LoginViewController) {
        logger.info("Forgot password requested", category: "coordinator")
        showForgotPassword()
    }
}

// MARK: - SignUpViewControllerDelegate

extension AuthCoordinator: SignUpViewControllerDelegate {
    func signUpViewController(_ controller: SignUpViewController, didRegisterWithUserID userID: String) {
        logger.info("Registration completed", category: "coordinator", context: ["userID": userID])

        // Show success alert and return to login
        let alert = UIAlertController(
            title: "Account Created",
            message: "Your account has been created successfully. Please log in.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController.popViewController(animated: true)
        })
        navigationController.present(alert, animated: true)
    }

    func signUpViewControllerDidCancel(_ controller: SignUpViewController) {
        logger.info("Sign up cancelled", category: "coordinator")
        navigationController.popViewController(animated: true)
    }
}
