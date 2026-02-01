//
//  ViewState.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Generic view state for async operations
/// Represents the lifecycle of loading data: idle → loading → loaded/error
enum ViewState<Content> {
    case idle
    case loading
    case loaded(Content)
    case error(message: String, canRetry: Bool = true)

    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .error(let message, _) = self {
            return message
        }
        return nil
    }

    var canRetry: Bool {
        if case .error(_, let retry) = self {
            return retry
        }
        return false
    }

    var content: Content? {
        if case .loaded(let content) = self {
            return content
        }
        return nil
    }
}
