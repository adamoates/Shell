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

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemRed
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            usernameTextField,
            passwordTextField,
            errorLabel,
            loginButton
        ])
        stack.axis = .vertical
        stack.spacing = 20
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

        // Layout constraints
        NSLayoutConstraint.activate([
            contentStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Button height
            loginButton.heightAnchor.constraint(equalToConstant: 50),

            // Text field heights
            usernameTextField.heightAnchor.constraint(equalToConstant: 44),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
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

        errorLabel.accessibilityLabel = "Error message"
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
                    self?.errorLabel.isHidden = true
                }
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
        errorLabel.text = message
        errorLabel.isHidden = false

        // Announce to VoiceOver
        UIAccessibility.post(notification: .announcement, argument: message)

        // Animate error
        errorLabel.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.errorLabel.alpha = 1
        }
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
