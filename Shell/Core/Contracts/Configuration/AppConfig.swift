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
            guard let url = URL(string: "https://api-dev.shell.com") else {
                preconditionFailure("Invalid development API URL")
            }
            return url
        case .staging:
            guard let url = URL(string: "https://api-staging.shell.com") else {
                preconditionFailure("Invalid staging API URL")
            }
            return url
        case .production:
            guard let url = URL(string: "https://api.shell.com") else {
                preconditionFailure("Invalid production API URL")
            }
            return url
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
