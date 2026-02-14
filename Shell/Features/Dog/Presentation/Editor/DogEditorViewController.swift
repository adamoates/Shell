import UIKit
import Combine

final class DogEditorViewController: UIViewController {
    // MARK: - Properties
    private let viewModel: DogEditorViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        stack.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()

    private lazy var nameTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Dog Name"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .words
        return field
    }()

    private lazy var breedTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Breed"
        field.borderStyle = .roundedRect
        field.autocapitalizationType = .words
        return field
    }()

    private lazy var ageTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Age (years)"
        field.borderStyle = .roundedRect
        field.keyboardType = .numberPad
        return field
    }()

    private lazy var medicalNotesLabel: UILabel = {
        let label = UILabel()
        label.text = "Medical Notes"
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()

    private lazy var medicalNotesTextView: UITextView = {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var behaviorNotesLabel: UILabel = {
        let label = UILabel()
        label.text = "Behavior Notes"
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()

    private lazy var behaviorNotesTextView: UITextView = {
        let textView = UITextView()
        textView.font = .preferredFont(forTextStyle: .body)
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    private lazy var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(viewModel.saveButtonTitle, for: .normal)
        button.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Initialization
    init(viewModel: DogEditorViewModel) {
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
        bindViewModel()
        setupKeyboardDismissal()
    }

    // MARK: - Setup
    private func setupUI() {
        title = viewModel.title
        view.backgroundColor = .systemBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(nameTextField)
        contentStack.addArrangedSubview(breedTextField)
        contentStack.addArrangedSubview(ageTextField)
        contentStack.addArrangedSubview(medicalNotesLabel)
        contentStack.addArrangedSubview(medicalNotesTextView)
        contentStack.addArrangedSubview(behaviorNotesLabel)
        contentStack.addArrangedSubview(behaviorNotesTextView)
        contentStack.addArrangedSubview(saveButton)
        contentStack.addArrangedSubview(activityIndicator)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            medicalNotesTextView.heightAnchor.constraint(equalToConstant: 100),
            behaviorNotesTextView.heightAnchor.constraint(equalToConstant: 100),
            saveButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func bindViewModel() {
        // Bind text fields to ViewModel
        nameTextField.text = viewModel.name
        nameTextField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)

        breedTextField.text = viewModel.breed
        breedTextField.addTarget(self, action: #selector(breedChanged), for: .editingChanged)

        ageTextField.text = viewModel.age
        ageTextField.addTarget(self, action: #selector(ageChanged), for: .editingChanged)

        medicalNotesTextView.text = viewModel.medicalNotes
        medicalNotesTextView.delegate = self

        behaviorNotesTextView.text = viewModel.behaviorNotes
        behaviorNotesTextView.delegate = self

        // Bind loading state
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.saveButton.isEnabled = !isLoading
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        // Bind error messages
        viewModel.$errorMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                if let error = errorMessage {
                    self?.showError(error)
                }
            }
            .store(in: &cancellables)
    }

    private func setupKeyboardDismissal() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    // MARK: - Actions
    @objc private func nameChanged() {
        viewModel.name = nameTextField.text ?? ""
    }

    @objc private func breedChanged() {
        viewModel.breed = breedTextField.text ?? ""
    }

    @objc private func ageChanged() {
        viewModel.age = ageTextField.text ?? ""
    }

    @objc private func saveButtonTapped() {
        Task {
            await viewModel.save()
        }
    }

    @objc private func cancelButtonTapped() {
        viewModel.cancel()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextViewDelegate
extension DogEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView == medicalNotesTextView {
            viewModel.medicalNotes = textView.text
        } else if textView == behaviorNotesTextView {
            viewModel.behaviorNotes = textView.text
        }
    }
}
