//
//  ErrorBannerView.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import UIKit

/// Reusable error banner view that displays at the top of a view controller
/// Shows an error message with optional retry button
final class ErrorBannerView: UIView {
    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemRed
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retry", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Properties

    var onRetry: (() -> Void)?

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        isHidden = true

        addSubview(containerView)
        containerView.addSubview(messageLabel)
        containerView.addSubview(retryButton)

        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            messageLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: retryButton.leadingAnchor, constant: -8),
            messageLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),

            retryButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            retryButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            retryButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 60)
        ])
    }

    // MARK: - Actions

    @objc private func retryTapped() {
        onRetry?()
    }

    // MARK: - Public Methods

    /// Show the error banner with a message
    /// - Parameters:
    ///   - message: The error message to display
    ///   - canRetry: Whether to show the retry button
    func show(message: String, canRetry: Bool = true) {
        messageLabel.text = message
        retryButton.isHidden = !canRetry
        isHidden = false

        // Animate in
        alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }

    /// Hide the error banner
    func hide() {
        UIView.animate(withDuration: 0.3) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
        }
    }
}
