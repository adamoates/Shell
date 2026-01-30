//
//  AppConfig.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Application configuration loaded during boot
struct AppConfig: Equatable {
    /// Application environment
    let environment: Environment

    /// API base URL (derived from environment)
    var apiBaseURL: URL {
        switch environment {
        case .development:
            return URL(string: "https://api-dev.shell.com")!
        case .staging:
            return URL(string: "https://api-staging.shell.com")!
        case .production:
            return URL(string: "https://api.shell.com")!
        }
    }

    /// Whether debug features are enabled
    var isDebugEnabled: Bool {
        environment != .production
    }
}

// MARK: - Environment

extension AppConfig {
    enum Environment: String, Equatable {
        case development
        case staging
        case production
    }
}
