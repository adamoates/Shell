//
//  LoginViewController.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//  Migrated from Storyboard to pure code
//

import UIKit
import Combine

class LoginViewController: UIViewController {
    // MARK: - Properties

    weak var delegate: LoginViewControllerDelegate?
    private let viewModel: LoginViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to Shell"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var usernameTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Username"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .next
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var passwordTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Password"
        field.borderStyle = .roundedRect
        field.isSecureTextEntry = true
        field.returnKeyType = .go
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        return button
    }()

    private let loginActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var errorBannerView: ErrorBannerView = {
        let view = ErrorBannerView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Forgot Password?", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)
        return button
    }()

    private lazy var signUpButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(signUpTapped), for: .touchUpInside)
        return button
    }()

    private lazy var biometricLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Use Face ID / Touch ID", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(biometricLoginTapped), for: .touchUpInside)
        return button
    }()

    private lazy var appleLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue with Apple", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(appleLoginTapped), for: .touchUpInside)
        return button
    }()

    private lazy var googleLoginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue with Google", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(googleLoginTapped), for: .touchUpInside)
        return button
    }()

    private lazy var socialLoginStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            appleLoginButton,
            googleLoginButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            usernameTextField,
            passwordTextField,
            loginButton,
            errorBannerView,
            forgotPasswordButton,
            signUpButton,
            biometricLoginButton,
            socialLoginStackView
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initialization

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAccessibility()
        setupBindings()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Welcome"
        view.backgroundColor = .systemBackground

        // Add stack view to view
        view.addSubview(contentStackView)
        loginButton.addSubview(loginActivityIndicator)

        errorBannerView.onRetry = { [weak self] in
            self?.loginButtonTapped()
        }

        // Layout constraints
        NSLayoutConstraint.activate([
            contentStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Button height
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            appleLoginButton.heightAnchor.constraint(equalToConstant: 44),
            googleLoginButton.heightAnchor.constraint(equalToConstant: 44),

            // Text field heights
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),

            loginActivityIndicator.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            loginActivityIndicator.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor)
        ])

        contentStackView.setCustomSpacing(12, after: loginButton)
        contentStackView.setCustomSpacing(8, after: errorBannerView)
    }

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header
        titleLabel.accessibilityLabel = "Welcome to Shell"

        usernameTextField.accessibilityLabel = "Username"
        usernameTextField.accessibilityHint = "Enter your username"

        passwordTextField.accessibilityLabel = "Password"
        passwordTextField.accessibilityHint = "Enter your password"

        loginButton.accessibilityLabel = "Login"
        loginButton.accessibilityHint = "Double tap to log in"

        errorBannerView.accessibilityLabel = "Error message"

        forgotPasswordButton.accessibilityLabel = "Forgot password"
        forgotPasswordButton.accessibilityHint = "Start password recovery"

        signUpButton.accessibilityLabel = "Sign up"
        signUpButton.accessibilityHint = "Create a new account"

        biometricLoginButton.accessibilityLabel = "Biometric login"
        biometricLoginButton.accessibilityHint = "Use Face ID or Touch ID to log in"

        appleLoginButton.accessibilityLabel = "Continue with Apple"
        appleLoginButton.accessibilityHint = "Log in with your Apple account"

        googleLoginButton.accessibilityLabel = "Continue with Google"
        googleLoginButton.accessibilityHint = "Log in with your Google account"
    }

    private func setupBindings() {
        // Set view model delegate
        viewModel.delegate = self

        // Bind error message from ViewModel
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let errorMessage = errorMessage {
                    self?.showError(errorMessage)
                } else {
                    self?.errorBannerView.hide()
                }
            }
            .store(in: &cancellables)

        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func loginButtonTapped() {
        // Sync text fields to view model
        viewModel.username = usernameTextField.text ?? ""
        viewModel.password = passwordTextField.text ?? ""

        // Let view model handle validation and login
        viewModel.login()
    }

    private func showError(_ message: String) {
        errorBannerView.show(message: message, canRetry: true)

        // Announce to VoiceOver
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            loginButton.setTitle("", for: .normal)
            loginActivityIndicator.startAnimating()
        } else {
            loginButton.setTitle("Login", for: .normal)
            loginActivityIndicator.stopAnimating()
        }

        loginButton.isEnabled = !isLoading
        usernameTextField.isEnabled = !isLoading
        passwordTextField.isEnabled = !isLoading
        forgotPasswordButton.isEnabled = !isLoading
        signUpButton.isEnabled = !isLoading
        biometricLoginButton.isEnabled = !isLoading
        socialLoginStackView.isUserInteractionEnabled = !isLoading

        loginButton.accessibilityValue = isLoading ? "Loading" : nil
    }
}

// MARK: - LoginViewModelDelegate

extension LoginViewController: LoginViewModelDelegate {
    func loginViewModelDidSucceed(_ viewModel: LoginViewModel, username: String) {
        // Notify coordinator of successful login
        delegate?.loginViewController(self, didLoginWithUsername: username)
    }
}

// MARK: - UITextFieldDelegate

extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            textField.resignFirstResponder()
            loginButtonTapped()
        }
        return true
    }
}

// MARK: - Placeholder Actions

extension LoginViewController {
    @objc private func forgotPasswordTapped() {
        // Show alert to enter email for password reset
        let alert = UIAlertController(
            title: "Reset Password",
            message: "Enter your email address to receive a password reset link.",
            preferredStyle: .alert
        )

        alert.addTextField { textField in
            textField.placeholder = "Email"
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Send Link", style: .default) { [weak self, weak alert] _ in
            guard let self = self,
                  let email = alert?.textFields?.first?.text, !email.isEmpty else {
                return
            }
            self.delegate?.loginViewController(self, didRequestPasswordResetFor: email)
        })

        present(alert, animated: true)
        UIAccessibility.post(notification: .announcement, argument: "Forgot password selected")
    }

    @objc private func signUpTapped() {
        delegate?.loginViewControllerDidRequestSignUp(self)
        UIAccessibility.post(notification: .announcement, argument: "Sign up selected")
    }

    @objc private func biometricLoginTapped() {
        UIAccessibility.post(notification: .announcement, argument: "Biometric login selected")
    }

    @objc private func appleLoginTapped() {
        UIAccessibility.post(notification: .announcement, argument: "Continue with Apple selected")
    }

    @objc private func googleLoginTapped() {
        UIAccessibility.post(notification: .announcement, argument: "Continue with Google selected")
    }
}
