//
//  ProfileViewController.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit
import Combine

/// Profile screen view controller
/// Displays user profile information
final class ProfileViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 50
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var screenNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var birthdayLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()

    private lazy var errorBanner: ErrorBannerView = {
        let banner = ErrorBannerView()
        banner.onRetry = { [weak self] in
            self?.retryLoadProfile()
        }
        return banner
    }()

    // MARK: - Init

    init(viewModel: ProfileViewModel) {
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
        setupBindings()
        loadProfile()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Profile"
        view.backgroundColor = .systemBackground

        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        view.addSubview(loadingIndicator)
        view.addSubview(errorBanner)

        // Add profile components to stack
        stackView.addArrangedSubview(avatarImageView)
        stackView.addArrangedSubview(screenNameLabel)
        stackView.addArrangedSubview(birthdayLabel)

        // Layout constraints
        NSLayoutConstraint.activate([
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // StackView
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            // Avatar
            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100),

            // Loading indicator
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            // Error banner
            errorBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            errorBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Accessibility
        avatarImageView.accessibilityLabel = "Profile picture"
        screenNameLabel.accessibilityTraits = .header
    }

    private func setupBindings() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateUI(for: state)
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    private func loadProfile() {
        Task {
            await viewModel.loadProfile()
        }
    }

    private func retryLoadProfile() {
        Task {
            await viewModel.retryLoadProfile()
        }
    }

    private func loadAvatarImage(from url: URL) {
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)

                // Validate HTTP response
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    await showPlaceholderAvatar()
                    return
                }

                // Create image from data
                guard let image = UIImage(data: data) else {
                    await showPlaceholderAvatar()
                    return
                }

                // Update UI on main actor
                await MainActor.run {
                    self.avatarImageView.image = image
                }
            } catch {
                await showPlaceholderAvatar()
            }
        }
    }

    @MainActor
    private func showPlaceholderAvatar() {
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .systemGray3
    }

    private func updateUI(for state: ProfileState) {
        switch state {
        case .idle:
            loadingIndicator.stopAnimating()
            stackView.isHidden = true
            errorBanner.hide()

        case .loading:
            loadingIndicator.startAnimating()
            stackView.isHidden = true
            errorBanner.hide()

        case .loaded(let profile):
            loadingIndicator.stopAnimating()
            stackView.isHidden = false
            errorBanner.hide()

            screenNameLabel.text = profile.screenName

            let formatter = DateFormatter()
            formatter.dateStyle = .long
            birthdayLabel.text = "Birthday: \(formatter.string(from: profile.birthday))"

            // Load avatar if available
            if let avatarURL = profile.avatarURL {
                loadAvatarImage(from: avatarURL)
            } else {
                // Show placeholder when no avatar URL
                avatarImageView.image = UIImage(systemName: "person.circle.fill")
                avatarImageView.tintColor = .systemGray3
            }

        case .error(let error):
            loadingIndicator.stopAnimating()
            stackView.isHidden = true
            errorBanner.show(message: error.localizedDescription, canRetry: error.canRetry)
        }
    }
}
