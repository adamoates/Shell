//
//  LoginViewController.swift
//  Shell
//
//  Created for Storyboard UI/UX Test
//

import UIKit
import Combine

class LoginViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: LoginViewControllerDelegate?
    var viewModel: LoginViewModel!
    private var cancellables = Set<AnyCancellable>()

    // MARK: - IBOutlets

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var contentStackView: UIStackView!

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
        errorLabel.isHidden = true

        // Configure text fields
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.returnKeyType = .next
        usernameTextField.delegate = self

        passwordTextField.isSecureTextEntry = true
        passwordTextField.returnKeyType = .go
        passwordTextField.delegate = self

        // Configure button
        loginButton.layer.cornerRadius = 8
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

    @IBAction func loginButtonTapped(_ sender: UIButton) {
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
            loginButtonTapped(loginButton)
        }
        return true
    }
}
