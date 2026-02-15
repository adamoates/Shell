//
//  ResetPasswordViewController.swift
//  Shell
//
//  Created by Shell on 2026-02-15.
//

import UIKit
import Combine

class ResetPasswordViewController: UIViewController {
    // MARK: - Properties

    weak var delegate: ResetPasswordViewControllerDelegate?
    private let viewModel: ResetPasswordViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Reset Password"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter your new password below"
        label.font = .systemFont(ofSize: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var newPasswordTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "New Password"
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

    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset Password", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        return button
    }()

    private let resetActivityIndicator: UIActivityIndicatorView = {
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
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.setTitleColor(.systemBlue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            instructionLabel,
            newPasswordTextField,
            confirmPasswordTextField,
            passwordRequirementsLabel,
            resetButton,
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

    init(viewModel: ResetPasswordViewModel) {
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
        title = "Reset Password"
        view.backgroundColor = .systemBackground

        // Add stack view to view
        view.addSubview(contentStackView)
        resetButton.addSubview(resetActivityIndicator)

        errorBannerView.onRetry = { [weak self] in
            self?.resetButtonTapped()
        }

        // Layout constraints
        NSLayoutConstraint.activate([
            contentStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            contentStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            // Button height
            resetButton.heightAnchor.constraint(equalToConstant: 50),

            // Text field heights
            newPasswordTextField.heightAnchor.constraint(equalToConstant: 44),
            confirmPasswordTextField.heightAnchor.constraint(equalToConstant: 44),

            resetActivityIndicator.centerXAnchor.constraint(equalTo: resetButton.centerXAnchor),
            resetActivityIndicator.centerYAnchor.constraint(equalTo: resetButton.centerYAnchor)
        ])

        contentStackView.setCustomSpacing(8, after: instructionLabel)
        contentStackView.setCustomSpacing(8, after: passwordRequirementsLabel)
        contentStackView.setCustomSpacing(12, after: resetButton)
        contentStackView.setCustomSpacing(8, after: errorBannerView)
    }

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header
        titleLabel.accessibilityLabel = "Reset Password"

        newPasswordTextField.accessibilityLabel = "New Password"
        newPasswordTextField.accessibilityHint = "Enter your new password"

        confirmPasswordTextField.accessibilityLabel = "Confirm Password"
        confirmPasswordTextField.accessibilityHint = "Re-enter your new password"

        resetButton.accessibilityLabel = "Reset Password"
        resetButton.accessibilityHint = "Double tap to reset your password"

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

    @objc private func resetButtonTapped() {
        // Sync text fields to view model
        viewModel.newPassword = newPasswordTextField.text ?? ""
        viewModel.confirmPassword = confirmPasswordTextField.text ?? ""

        // Let view model handle validation and reset
        viewModel.resetPassword()
    }

    @objc private func cancelTapped() {
        delegate?.resetPasswordViewControllerDidCancel(self)
    }

    private func showError(_ message: String) {
        errorBannerView.show(message: message, canRetry: true)

        // Announce to VoiceOver
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            resetButton.setTitle("", for: .normal)
            resetActivityIndicator.startAnimating()
        } else {
            resetButton.setTitle("Reset Password", for: .normal)
            resetActivityIndicator.stopAnimating()
        }

        resetButton.isEnabled = !isLoading
        newPasswordTextField.isEnabled = !isLoading
        confirmPasswordTextField.isEnabled = !isLoading
        cancelButton.isEnabled = !isLoading

        resetButton.accessibilityValue = isLoading ? "Loading" : nil
    }
}

// MARK: - ResetPasswordViewModelDelegate

extension ResetPasswordViewController: ResetPasswordViewModelDelegate {
    func resetPasswordViewModelDidSucceed(_ viewModel: ResetPasswordViewModel) {
        // Notify coordinator of successful reset
        delegate?.resetPasswordViewControllerDidSucceed(self)
    }
}

// MARK: - UITextFieldDelegate

extension ResetPasswordViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == newPasswordTextField {
            confirmPasswordTextField.becomeFirstResponder()
        } else if textField == confirmPasswordTextField {
            textField.resignFirstResponder()
            resetButtonTapped()
        }
        return true
    }
}

// MARK: - Delegate Protocol

/// Protocol for ResetPasswordViewController to communicate with coordinator
protocol ResetPasswordViewControllerDelegate: AnyObject {
    func resetPasswordViewControllerDidSucceed(_ controller: ResetPasswordViewController)
    func resetPasswordViewControllerDidCancel(_ controller: ResetPasswordViewController)
}
