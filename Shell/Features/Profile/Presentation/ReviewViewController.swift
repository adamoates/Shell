//
//  ReviewViewController.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit
import Combine

/// Fourth and final step of identity setup: Review and complete
final class ReviewViewController: UIViewController {
    // MARK: - Properties

    private let viewModel: IdentitySetupViewModel
    private var cancellables = Set<AnyCancellable>()

    var onComplete: ((UserProfile) -> Void)?
    var onBack: (() -> Void)?

    // MARK: - UI Components

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Review Your Profile"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Make sure everything looks good"
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var screenNameRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = "Screen Name"
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        valueLabel.text = viewModel.screenName
        valueLabel.font = .systemFont(ofSize: 17, weight: .regular)

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)

        return stack
    }()

    private lazy var birthdayRow: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4

        let titleLabel = UILabel()
        titleLabel.text = "Birthday"
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .secondaryLabel

        let valueLabel = UILabel()
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        valueLabel.text = formatter.string(from: viewModel.birthday)
        valueLabel.font = .systemFont(ofSize: 17, weight: .regular)

        stack.addArrangedSubview(titleLabel)
        stack.addArrangedSubview(valueLabel)

        return stack
    }()

    private lazy var completeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Complete Setup", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(completeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var errorBanner: ErrorBannerView = {
        let banner = ErrorBannerView()
        banner.onRetry = { [weak self] in
            self?.retryComplete()
        }
        return banner
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
        setupBindings()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Review"

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(stackView)
        view.addSubview(errorBanner)
        view.addSubview(completeButton)
        view.addSubview(loadingIndicator)

        stackView.addArrangedSubview(screenNameRow)
        stackView.addArrangedSubview(birthdayRow)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            stackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            errorBanner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            errorBanner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorBanner.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            completeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            completeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            completeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            completeButton.heightAnchor.constraint(equalToConstant: 50),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupBindings() {
        viewModel.$isCompleting
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCompleting in
                if isCompleting {
                    self?.loadingIndicator.startAnimating()
                    self?.completeButton.isEnabled = false
                } else {
                    self?.loadingIndicator.stopAnimating()
                    self?.completeButton.isEnabled = true
                }
            }
            .store(in: &cancellables)

        Publishers.CombineLatest(viewModel.$completionError, viewModel.$canRetry)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error, canRetry in
                if let error = error {
                    self?.errorBanner.show(message: error, canRetry: canRetry)
                } else {
                    self?.errorBanner.hide()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func completeButtonTapped() {
        Task {
            if let profile = await viewModel.completeSetup() {
                onComplete?(profile)
            }
        }
    }

    private func retryComplete() {
        Task {
            if let profile = await viewModel.retryCompleteSetup() {
                onComplete?(profile)
            }
        }
    }
}
