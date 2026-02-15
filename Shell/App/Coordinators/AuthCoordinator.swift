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
    func loginViewController(_ controller: LoginViewController, didRequestPasswordResetFor email: String)
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

    func loginViewController(_ controller: LoginViewController, didRequestPasswordResetFor email: String) {
        logger.info("Password reset requested", category: "coordinator", context: ["email": email])

        Task { @MainActor in
            do {
                // Call backend to send password reset email
                guard let url = URL(string: "http://localhost:3000/auth/forgot-password") else {
                    logger.error("Invalid forgot password URL", category: "coordinator")
                    return
                }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let body = ["email": email]
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (_, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    // Show success message
                    let alert = UIAlertController(
                        title: "Email Sent",
                        message: "If an account exists with that email, a password reset link has been sent.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    navigationController.present(alert, animated: true)
                } else {
                    throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to send email"])
                }
            } catch {
                // Show error message
                let alert = UIAlertController(
                    title: "Error",
                    message: "Failed to send password reset email. Please try again.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                navigationController.present(alert, animated: true)
            }
        }
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
