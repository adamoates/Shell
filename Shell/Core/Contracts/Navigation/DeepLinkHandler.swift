//
//  DeepLinkHandler.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Protocol for handling deep links
/// Implemented by UniversalLinkHandler and CustomURLSchemeHandler
protocol DeepLinkHandler {
    /// Check if this handler can process the URL
    func canHandle(url: URL) -> Bool

    /// Handle the URL, return true if successful
    func handle(url: URL) -> Bool
}
