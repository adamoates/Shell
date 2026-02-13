//
//  AvatarViewController.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit
import Combine

/// Third step of identity setup: Choose avatar (optional)
final class AvatarViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // MARK: - Properties

    private let viewModel: IdentitySetupViewModel
    private var cancellables = Set<AnyCancellable>()

    var onNext: (() -> Void)?
    var onSkip: (() -> Void)?
    var onBack: (() -> Void)?

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose Your Avatar"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Add a profile picture (optional)"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 75
        imageView.backgroundColor = .systemGray5
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemGray3
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var choosePhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Choose Photo", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(choosePhotoTapped), for: .touchUpInside)
        return button
    }()

    private lazy var skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Skip for Now", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Next", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        button.isHidden = true  // Only show after photo is selected
        return button
    }()

    // MARK: - Init

    init(viewModel: IdentitySetupViewModel) {
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
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Avatar"

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(avatarImageView)
        view.addSubview(choosePhotoButton)
        view.addSubview(skipButton)
        view.addSubview(nextButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            avatarImageView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            avatarImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 150),
            avatarImageView.heightAnchor.constraint(equalToConstant: 150),

            choosePhotoButton.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 24),
            choosePhotoButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            nextButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            nextButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            nextButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            nextButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    // MARK: - Actions

    @objc private func choosePhotoTapped() {
        // Check photo library authorization
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showPhotoLibraryUnavailableAlert()
            return
        }

        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        // Get the selected image (prefer edited version if available)
        guard let selectedImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage) else {
            return
        }

        // Update UI with selected image
        avatarImageView.image = selectedImage
        nextButton.isHidden = false
        skipButton.isHidden = true

        // Generate a placeholder avatar URL using UI Avatars service
        // In production, this would upload the image and get a real URL
        let screenName = viewModel.screenName
        let encodedName = screenName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "User"
        viewModel.avatarURL = URL(string: "https://ui-avatars.com/api/?name=\(encodedName)&size=200&background=random")
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    // MARK: - Helpers

    private func showPhotoLibraryUnavailableAlert() {
        let alert = UIAlertController(
            title: "Photo Library Unavailable",
            message: "Unable to access photo library on this device.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func skipButtonTapped() {
        viewModel.avatarURL = nil
        onSkip?()
    }

    @objc private func nextButtonTapped() {
        // Avatar URL would be set after photo upload
        // For now, we'll proceed without it
        onNext?()
    }
}
