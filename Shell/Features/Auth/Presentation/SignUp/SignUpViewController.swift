//
//  SignUpViewController.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import UIKit
import Combine

class SignUpViewController: UIViewController {
    // MARK: - Properties

    weak var delegate: SignUpViewControllerDelegate?
    private let viewModel: SignUpViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Create Account"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var emailTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Email"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.keyboardType = .emailAddress
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
        field.returnKeyType = .next
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var confirmPasswordTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Confirm Password"
        field.borderStyle = .roundedRect
        field.isSecureTextEntry = true
        field.returnKeyType = .go
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var registerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Up", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(registerButtonTapped), for: .touchUpInside)
        return button
    }()

    private let registerActivityIndicator: UIActivityIndicatorView = {
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

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Already have an account? Log In", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()

    private lazy var passwordRequirementsLabel: UILabel = {
        let label = UILabel()
        label.text = "Password must be at least 8 characters with 1 uppercase, 1 number, and 1 special character"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            emailTextField,
            passwordTextField,
            confirmPasswordTextField,
            passwordRequirementsLabel,
            registerButton,
            errorBannerView,
            cancelButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initialization

    init(viewModel: SignUpViewModel) {
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
        title = "Sign Up"
        view.backgroundColor = .systemBackground

        // Add stack view to view
        view.addSubview(contentStackView)
        registerButton.addSubview(registerActivityIndicator)

        errorBannerView.onRetry = { [weak self] in
            self?.registerButtonTapped()
        }

        // Layout constraints
        NSLayoutConstraint.activate([
            contentStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Button height
            registerButton.heightAnchor.constraint(equalToConstant: 50),

            // Text field heights
            emailTextField.heightAnchor.constraint(equalToConstant: 44),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 44),

            registerActivityIndicator.centerXAnchor.constraint(equalTo: registerButton.centerXAnchor),
            registerActivityIndicator.centerYAnchor.constraint(equalTo: registerButton.centerYAnchor)
        ])

        contentStackView.setCustomSpacing(8, after: passwordRequirementsLabel)
        contentStackView.setCustomSpacing(12, after: registerButton)
        contentStackView.setCustomSpacing(8, after: errorBannerView)
    }

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header
        titleLabel.accessibilityLabel = "Create Account"

        emailTextField.accessibilityLabel = "Email"
        emailTextField.accessibilityHint = "Enter your email address"

        passwordTextField.accessibilityLabel = "Password"
        passwordTextField.accessibilityHint = "Enter your password"

        confirmPasswordTextField.accessibilityLabel = "Confirm Password"
        confirmPasswordTextField.accessibilityHint = "Re-enter your password"

        registerButton.accessibilityLabel = "Sign Up"
        registerButton.accessibilityHint = "Double tap to create account"

        errorBannerView.accessibilityLabel = "Error message"

        cancelButton.accessibilityLabel = "Cancel"
        cancelButton.accessibilityHint = "Return to login screen"
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

    @objc private func registerButtonTapped() {
        // Sync text fields to view model
        viewModel.email = emailTextField.text ?? ""
        viewModel.password = passwordTextField.text ?? ""
        viewModel.confirmPassword = confirmPasswordTextField.text ?? ""

        // Let view model handle validation and registration
        viewModel.register()
    }

    @objc private func cancelTapped() {
        delegate?.signUpViewControllerDidCancel(self)
    }

    private func showError(_ message: String) {
        errorBannerView.show(message: message, canRetry: true)

        // Announce to VoiceOver
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            registerButton.setTitle("", for: .normal)
            registerActivityIndicator.startAnimating()
        } else {
            registerButton.setTitle("Sign Up", for: .normal)
            registerActivityIndicator.stopAnimating()
        }

        registerButton.isEnabled = !isLoading
        emailTextField.isEnabled = !isLoading
        passwordTextField.isEnabled = !isLoading
        confirmPasswordTextField.isEnabled = !isLoading
        cancelButton.isEnabled = !isLoading

        registerButton.accessibilityValue = isLoading ? "Loading" : nil
    }
}

// MARK: - SignUpViewModelDelegate

extension SignUpViewController: SignUpViewModelDelegate {
    func signUpViewModelDidSucceed(_ viewModel: SignUpViewModel, userID: String) {
        // Notify coordinator of successful registration
        delegate?.signUpViewController(self, didRegisterWithUserID: userID)
    }
}

// MARK: - UITextFieldDelegate

extension SignUpViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            passwordTextField.becomeFirstResponder()
        } else if textField == passwordTextField {
            confirmPasswordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordTextField {
            textField.resignFirstResponder()
            registerButtonTapped()
        }
        return true
    }
}

// MARK: - Delegate Protocol

/// Protocol for SignUpViewController to communicate with coordinator
protocol SignUpViewControllerDelegate: AnyObject {
    func signUpViewController(_ controller: SignUpViewController, didRegisterWithUserID userID: String)
    func signUpViewControllerDidCancel(_ controller: SignUpViewController)
}
