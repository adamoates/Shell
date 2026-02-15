//
//  EmptyStateView.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import UIKit

/// Reusable empty state view for displaying when no content is available
/// Shows a centered message with optional image
final class EmptyStateView: UIView {
    // MARK: - Properties

    /// Message to display in the empty state
    var message: String = "No items available" {
        didSet {
            messageLabel.text = message
            messageLabel.accessibilityLabel = message
        }
    }

    /// Accessibility hint for the empty state
    var accessibilityHintText: String? {
        didSet {
            messageLabel.accessibilityHint = accessibilityHintText
        }
    }

    // MARK: - UI Components

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.text = message
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        backgroundColor = .systemBackground
        isHidden = true
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(messageLabel)

        NSLayoutConstraint.activate([
            messageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40)
        ])
    }
}
