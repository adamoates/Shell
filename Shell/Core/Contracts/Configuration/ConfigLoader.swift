//
//  ConfigLoader.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Protocol for loading application configuration
///
/// Implementations might load from:
/// - Info.plist
/// - Remote config service
/// - Environment variables
/// - Build configuration
protocol ConfigLoader: AnyObject {
    /// Load application configuration
    /// - Returns: The loaded configuration
    /// - Throws: If configuration cannot be loaded
    func loadConfig() async throws -> AppConfig
}
