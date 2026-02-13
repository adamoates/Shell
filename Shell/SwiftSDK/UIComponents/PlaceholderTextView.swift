//
//  PlaceholderTextView.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import UIKit

/// UITextView with built-in placeholder text support
/// Automatically shows/hides placeholder text when editing
final class PlaceholderTextView: UITextView {

    // MARK: - Properties

    /// Placeholder text to display when the text view is empty
    var placeholder: String = "" {
        didSet {
            updatePlaceholder()
        }
    }

    /// Placeholder text color (defaults to system placeholder color)
    var placeholderColor: UIColor = .placeholderText {
        didSet {
            updatePlaceholder()
        }
    }

    /// Override text to handle placeholder visibility
    override var text: String! {
        didSet {
            updatePlaceholder()
        }
    }

    /// Actual user-entered text (empty string when showing placeholder)
    var actualText: String {
        return isShowingPlaceholder ? "" : text ?? ""
    }

    private var isShowingPlaceholder: Bool {
        return text == placeholder && textColor == placeholderColor
    }

    // MARK: - Initialization

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    // MARK: - Setup

    private func setupView() {
        delegate = self
        updatePlaceholder()
    }

    private func updatePlaceholder() {
        if text.isEmpty || isShowingPlaceholder {
            showPlaceholder()
        }
    }

    private func showPlaceholder() {
        text = placeholder
        textColor = placeholderColor
    }

    private func hidePlaceholder() {
        if isShowingPlaceholder {
            text = ""
            textColor = .label
        }
    }
}

// MARK: - UITextViewDelegate

extension PlaceholderTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        hidePlaceholder()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if text.isEmpty {
            showPlaceholder()
        }
    }
}
