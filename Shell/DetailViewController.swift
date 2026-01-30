//
//  DetailViewController.swift
//  Shell
//
//  Created for Storyboard UI/UX Test
//

import UIKit

class DetailViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dividerView: UIView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!

    // MARK: - Properties

    var item: Item?

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

        // Configure button
        actionButton.layer.cornerRadius = 8

        // Configure divider
        dividerView.backgroundColor = .separator
    }

    private func setupAccessibility() {
        titleLabel.accessibilityTraits = .header

        actionButton.accessibilityLabel = "Mark as complete"
        actionButton.accessibilityHint = "Double tap to mark this item as complete"
    }

    private func configureWithItem() {
        guard let item = item else { return }

        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        descriptionLabel.text = item.description

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: item.date)

        // Update accessibility
        titleLabel.accessibilityLabel = item.title
        subtitleLabel.accessibilityLabel = item.subtitle
        dateLabel.accessibilityLabel = "Date: \(formatter.string(from: item.date))"
        descriptionLabel.accessibilityLabel = item.description
    }

    // MARK: - Actions

    @IBAction func actionButtonTapped(_ sender: UIButton) {
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
