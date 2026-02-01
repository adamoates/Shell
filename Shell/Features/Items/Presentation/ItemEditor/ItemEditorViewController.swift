//
//  ItemEditorViewController.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import UIKit
import Combine

/// View controller for creating or editing an item
/// Displays form with title, subtitle, and description fields
final class ItemEditorViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: ItemEditorViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            titleTextField,
            subtitleTextField,
            descriptionTextView,
            errorLabel
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var titleTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Title"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .words
        field.returnKeyType = .next
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var subtitleTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Subtitle"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .words
        field.returnKeyType = .next
        field.delegate = self
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    private lazy var descriptionTextView: UITextView = {
        let textView = UITextView()
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

            // Text field heights
            titleTextField.heightAnchor.constraint(equalToConstant: 44),
            subtitleTextField.heightAnchor.constraint(equalToConstant: 44),

            // Description text view height
            descriptionTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 120)
        ])

        // Add placeholder text for description if in create mode
        if !viewModel.isEditMode {
            descriptionTextView.text = "Description"
            descriptionTextView.textColor = .placeholderText
            descriptionTextView.delegate = self
        }
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
        titleTextField.accessibilityLabel = "Title"
        titleTextField.accessibilityHint = "Enter the item title"

        subtitleTextField.accessibilityLabel = "Subtitle"
        subtitleTextField.accessibilityHint = "Enter the item subtitle"

        descriptionTextView.accessibilityLabel = "Description"
        descriptionTextView.accessibilityHint = "Enter the item description"

        errorLabel.accessibilityLabel = "Error message"
    }

    private func setupBindings() {
        // Bind title
        viewModel.$title
            .receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                if self?.titleTextField.text != title {
                    self?.titleTextField.text = title
                }
            }
            .store(in: &cancellables)

        // Bind subtitle
        viewModel.$subtitle
            .receive(on: DispatchQueue.main)
            .sink { [weak self] subtitle in
                if self?.subtitleTextField.text != subtitle {
                    self?.subtitleTextField.text = subtitle
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        viewModel.cancel()
    }

    @objc private func saveTapped() {
        // Sync text fields to view model
        viewModel.title = titleTextField.text ?? ""
        viewModel.subtitle = subtitleTextField.text ?? ""

        // Handle placeholder text for description
        if descriptionTextView.textColor == .placeholderText {
            viewModel.itemDescription = ""
        } else {
            viewModel.itemDescription = descriptionTextView.text ?? ""
        }

        // Dismiss keyboard
        view.endEditing(true)

        // Let view model handle validation and save
        viewModel.save()
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.scrollIndicatorInsets = .zero
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
            titleTextField.isEnabled = false
            subtitleTextField.isEnabled = false
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
            titleTextField.isEnabled = true
            subtitleTextField.isEnabled = true
            descriptionTextView.isEditable = true
        }
    }

    // MARK: - Deinitialization

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITextFieldDelegate

extension ItemEditorViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == titleTextField {
            subtitleTextField.becomeFirstResponder()
        } else if textField == subtitleTextField {
            descriptionTextView.becomeFirstResponder()
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        // Sync changes to view model
        if textField == titleTextField {
            viewModel.title = textField.text ?? ""
        } else if textField == subtitleTextField {
            viewModel.subtitle = textField.text ?? ""
        }
    }
}

// MARK: - UITextViewDelegate

extension ItemEditorViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Remove placeholder text when user starts editing
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        // Restore placeholder if empty
        if textView.text.isEmpty {
            textView.text = "Description"
            textView.textColor = .placeholderText
        }

        // Sync changes to view model
        viewModel.itemDescription = textView.textColor == .placeholderText ? "" : textView.text ?? ""
    }
}
