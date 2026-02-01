//
//  DetailViewController.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//  Migrated from Storyboard to pure code
//

import UIKit

class DetailViewController: UIViewController {

    // MARK: - Properties

    private let item: Item

    // MARK: - UI Components

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .tertiaryLabel
        label.textAlignment = .left
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Mark as Complete", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var contentStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            statusLabel,
            dateLabel,
            dividerView,
            descriptionLabel,
            actionButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Initialization

    init(item: Item) {
        self.item = item
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
        configureWithItem()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Details"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground

        // Add scroll view to view
        view.addSubview(scrollView)

        // Add stack view to scroll view
        scrollView.addSubview(contentStackView)

        // Layout constraints
        NSLayoutConstraint.activate([
            // Scroll view fills the view
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Content stack view inside scroll view
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            // Divider height
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            // Button height
            actionButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header

        actionButton.accessibilityLabel = "Mark as complete"
        actionButton.accessibilityHint = "Double tap to mark this item as complete"
    }

    private func configureWithItem() {
        titleLabel.text = item.name
        statusLabel.text = item.isCompleted ? "✓ Completed" : "◯ Not Completed"
        statusLabel.textColor = item.isCompleted ? .systemGreen : .systemOrange
        descriptionLabel.text = item.description

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = "Created: \(formatter.string(from: item.createdAt))"

        // Update button based on completion status
        if item.isCompleted {
            actionButton.setTitle("Mark as Incomplete", for: .normal)
            actionButton.backgroundColor = .systemOrange
        } else {
            actionButton.setTitle("Mark as Complete", for: .normal)
            actionButton.backgroundColor = .systemGreen
        }

        // Update accessibility
        titleLabel.accessibilityLabel = item.name
        statusLabel.accessibilityLabel = item.isCompleted ? "Completed" : "Not completed"
        dateLabel.accessibilityLabel = "Created: \(formatter.string(from: item.createdAt))"
        descriptionLabel.accessibilityLabel = item.description
    }

    // MARK: - Actions

    @objc private func actionButtonTapped() {
        let alert = UIAlertController(
            title: "Success",
            message: "Item marked as complete!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)

        // Announce to VoiceOver
        UIAccessibility.post(notification: .announcement, argument: "Item marked as complete")
    }
}
