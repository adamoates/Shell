//
//  ItemEditorViewController.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import UIKit
import Combine

/// View controller for creating or editing an item
/// Displays form with name, description, and completion status fields
final class ItemEditorViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: ItemEditorViewModel
    private var cancellables = Set<AnyCancellable>()
    private var keyboardHandler: KeyboardHandler?

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            nameTextField,
            descriptionTextView,
            completionContainer,
            errorLabel
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var nameTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Item Name"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .words
        field.returnKeyType = .next
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var completionContainer: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [completionLabel, completionSwitch])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var completionLabel: UILabel = {
        let label = UILabel()
        label.text = "Mark as Completed"
        label.font = .systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var completionSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.addTarget(self, action: #selector(completionSwitchChanged), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()

    private lazy var descriptionTextView: PlaceholderTextView = {
        let textView = PlaceholderTextView()
        textView.placeholder = "Description"
        textView.font = .systemFont(ofSize: 17)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
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

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Initialization

    init(viewModel: ItemEditorViewModel) {
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
        setupNavigationBar()
        setupAccessibility()
        setupBindings()
        setupKeyboardObservers()
    }

    // MARK: - Setup

    private func setupUI() {
        title = viewModel.isEditMode ? "Edit Item" : "New Item"
        view.backgroundColor = .systemBackground

        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // Layout constraints
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // ContentStackView
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            // Text field height
            nameTextField.heightAnchor.constraint(equalToConstant: 44),

            // Description text view height
            descriptionTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])
    }

    private func setupNavigationBar() {
        // Cancel button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )

        // Save button with activity indicator
        let saveButton = UIBarButtonItem(
            title: viewModel.saveButtonTitle,
            style: .prominent,
            target: self,
            action: #selector(saveTapped)
        )
        navigationItem.rightBarButtonItem = saveButton

        // Store reference for updating later
        navigationItem.rightBarButtonItem?.accessibilityLabel = "Save item"
    }

    private func setupAccessibility() {
        nameTextField.accessibilityLabel = "Item Name"
        nameTextField.accessibilityHint = "Enter the item name"

        completionSwitch.accessibilityLabel = "Mark as completed"
        completionSwitch.accessibilityHint = "Toggle to mark this item as completed or incomplete"

        descriptionTextView.accessibilityLabel = "Description"
        descriptionTextView.accessibilityHint = "Enter the item description"

        errorLabel.accessibilityLabel = "Error message"
    }

    private func setupBindings() {
        // Bind name
        viewModel.$name
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                if self?.nameTextField.text != name {
                    self?.nameTextField.text = name
                }
            }
            .store(in: &cancellables)

        // Bind completion status
        viewModel.$isCompleted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCompleted in
                if self?.completionSwitch.isOn != isCompleted {
                    self?.completionSwitch.isOn = isCompleted
                }
            }
            .store(in: &cancellables)

        // Bind description
        viewModel.$itemDescription
            .receive(on: DispatchQueue.main)
            .sink { [weak self] description in
                guard let self = self else { return }
                if self.descriptionTextView.text != description {
                    self.descriptionTextView.text = description
                    if !description.isEmpty {
                        self.descriptionTextView.textColor = .label
                    }
                }
            }
            .store(in: &cancellables)

        // Bind error message
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

        // Bind saving state
        viewModel.$isSaving
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSaving in
                self?.updateSavingState(isSaving)
            }
            .store(in: &cancellables)
    }

    private func setupKeyboardObservers() {
        keyboardHandler = KeyboardHandler(scrollView: scrollView)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        viewModel.cancel()
    }

    @objc private func completionSwitchChanged() {
        viewModel.isCompleted = completionSwitch.isOn
    }

    @objc private func saveTapped() {
        // Sync text fields to view model
        viewModel.name = nameTextField.text ?? ""
        viewModel.isCompleted = completionSwitch.isOn
        viewModel.itemDescription = descriptionTextView.actualText

        // Dismiss keyboard
        view.endEditing(true)

        // Let view model handle validation and save
        viewModel.save()
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

    private func updateSavingState(_ isSaving: Bool) {
        if isSaving {
            // Disable save button and show activity indicator
            let activityButton = UIBarButtonItem(customView: activityIndicator)
            navigationItem.rightBarButtonItem = activityButton
            activityIndicator.startAnimating()

            // Disable cancel button
            navigationItem.leftBarButtonItem?.isEnabled = false

            // Disable text fields
            nameTextField.isEnabled = false
            completionSwitch.isEnabled = false
            descriptionTextView.isEditable = false
        } else {
            // Re-enable save button
            let saveButton = UIBarButtonItem(
                title: viewModel.saveButtonTitle,
                style: .prominent,
                target: self,
                action: #selector(saveTapped)
            )
            navigationItem.rightBarButtonItem = saveButton

            // Re-enable cancel button
            navigationItem.leftBarButtonItem?.isEnabled = true

            // Re-enable text fields
            nameTextField.isEnabled = true
            completionSwitch.isEnabled = true
            descriptionTextView.isEditable = true
        }
    }
}

// MARK: - UITextFieldDelegate

extension ItemEditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameTextField {
            descriptionTextView.becomeFirstResponder()
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // Sync changes to view model
        if textField == nameTextField {
            viewModel.name = textField.text ?? ""
        }
    }
}
