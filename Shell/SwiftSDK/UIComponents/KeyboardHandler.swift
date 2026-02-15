//
//  KeyboardHandler.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import UIKit

/// Utility class to handle keyboard show/hide events and adjust scroll view insets
/// Automatically manages content insets when keyboard appears/disappears
final class KeyboardHandler {
    // MARK: - Properties

    private weak var scrollView: UIScrollView?
    private var observers: [NSObjectProtocol] = []

    // MARK: - Initialization

    /// Initialize with a scroll view to adjust when keyboard appears
    /// - Parameter scrollView: The scroll view to manage
    init(scrollView: UIScrollView) {
        self.scrollView = scrollView
        setupObservers()
    }

    deinit {
        removeObservers()
    }

    // MARK: - Setup

    private func setupObservers() {
        let willShowObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.keyboardWillShow(notification)
        }

        let willHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.keyboardWillHide(notification)
        }

        observers = [willShowObserver, willHideObserver]
    }

    private func removeObservers() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }

    // MARK: - Keyboard Handling

    private func keyboardWillShow(_ notification: Notification) {
        guard let scrollView = scrollView,
              let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }

        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    private func keyboardWillHide(_ notification: Notification) {
        scrollView?.contentInset = .zero
        scrollView?.scrollIndicatorInsets = .zero
    }
}
