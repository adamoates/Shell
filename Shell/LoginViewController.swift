//
//  LoginViewController.swift
//  Shell
//
//  Created for Storyboard UI/UX Test
//

import UIKit

class LoginViewController: UIViewController {

    // MARK: - Properties

    weak var delegate: LoginViewControllerDelegate?

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

    // MARK: - Actions

    @IBAction func loginButtonTapped(_ sender: UIButton) {
        errorLabel.isHidden = true

        guard let username = usernameTextField.text, !username.isEmpty else {
            showError("Please enter a username")
            return
        }

        guard let password = passwordTextField.text, !password.isEmpty else {
            showError("Please enter a password")
            return
        }

        // Simple validation for demo
        if username.count < 3 {
            showError("Username must be at least 3 characters")
            return
        }

        if password.count < 6 {
            showError("Password must be at least 6 characters")
            return
        }

        // Success - notify coordinator
        if let username = usernameTextField.text {
            delegate?.loginViewController(self, didLoginWithUsername: username)
        }
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
