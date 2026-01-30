//
//  DefaultConfigLoader.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Default implementation of ConfigLoader
/// Loads configuration from Info.plist and build settings
final class DefaultConfigLoader: ConfigLoader {
    // MARK: - ConfigLoader

    func loadConfig() async throws -> AppConfig {
        // Load environment from Info.plist or use default
        let environment = loadEnvironment()

        return AppConfig(environment: environment)
    }

    // MARK: - Private

    private func loadEnvironment() -> AppConfig.Environment {
        // In a real app, this would read from Info.plist or build settings
        // For now, we'll use a simple check
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}
