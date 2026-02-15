//
//  ItemTableViewCell.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import UIKit

/// Table view cell for displaying an Item in a list
/// Uses modern UIListContentConfiguration for accessibility and dynamic type support
final class ItemTableViewCell: UITableViewCell {
    // MARK: - Properties

    static let reuseIdentifier = "ItemTableViewCell"

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupAccessibility()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    /// Configure cell with an item
    /// - Parameter item: The item to display
    func configure(with item: Item) {
        var content = defaultContentConfiguration()
        content.text = item.name
        content.secondaryText = item.description
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.secondaryTextProperties.font = .preferredFont(forTextStyle: .subheadline)
        content.textProperties.adjustsFontForContentSizeCategory = true
        content.secondaryTextProperties.adjustsFontForContentSizeCategory = true

        contentConfiguration = content

        // Show checkmark if completed
        accessoryType = item.isCompleted ? .checkmark : .disclosureIndicator

        // Accessibility
        let completionStatus = item.isCompleted ? "completed" : "not completed"
        accessibilityLabel = "\(item.name), \(completionStatus)"
        accessibilityHint = "Double tap to view details"
    }

    // MARK: - Setup

    private func setupAccessibility() {
        isAccessibilityElement = true
    }
}
