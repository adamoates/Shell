//
//  OfflineBannerView.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import UIKit

/// Banner view that shows when device is offline
/// Provides clear feedback to users about network status
final class OfflineBannerView: UIView {

    // MARK: - UI Components

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemOrange
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "wifi.slash"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.text = "No Internet Connection"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
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
        isHidden = true
        translatesAutoresizingMaskIntoConstraints = false

        addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(messageLabel)

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 44),

            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),

            messageLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            messageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            messageLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])

        // Accessibility
        isAccessibilityElement = true
        accessibilityLabel = "Offline banner"
        accessibilityTraits = .staticText
    }

    // MARK: - Public Methods

    func show(animated: Bool = true) {
        guard isHidden else { return }

        isHidden = false
        accessibilityValue = "No Internet Connection"

        if animated {
            alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.alpha = 1
            }
        }

        UIAccessibility.post(notification: .announcement, argument: "No Internet Connection")
    }

    func hide(animated: Bool = true) {
        guard !isHidden else { return }

        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.isHidden = true
                self.alpha = 1
            })
        } else {
            isHidden = true
        }
    }
}
