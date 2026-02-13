//
//  APIConfig.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// API configuration
struct APIConfig {
    let baseURL: URL
    let authToken: String?

    /// Production configuration
    static let production = APIConfig(
        baseURL: URL(string: "https://api.shell.app/v1")!,
        authToken: nil  // Token will be set after login
    )

    /// Staging configuration
    static let staging = APIConfig(
        baseURL: URL(string: "https://api.staging.shell.app/v1")!,
        authToken: nil
    )

    /// Local development configuration
    static let local = APIConfig(
        baseURL: URL(string: "http://localhost:3000/v1")!,
        authToken: nil
    )

    /// Current active configuration
    /// Change this to switch between environments
    static var current: APIConfig {
        #if DEBUG
        return .local  // Use local backend for development
        #else
        return .production  // Use production for release builds
        #endif
    }
}

/// Feature flags for repository implementations
struct RepositoryConfig {
    /// Use remote repository (true) or in-memory repository (false)
    /// Set to false during development to work offline
    static var useRemoteRepository: Bool {
        #if DEBUG
        return false  // Use in-memory for now during development
        #else
        return true  // Use remote in production
        #endif
    }

    /// Use HTTP Items repository (true) or in-memory repository (false)
    /// Set to true to connect to backend API
    static var useHTTPItemsRepository: Bool {
        #if DEBUG
        return true  // Use HTTP for items during development
        #else
        return true  // Use HTTP in production
        #endif
    }

    /// Use Core Data Items repository (true) or current implementation (false)
    /// Set to true for local offline persistence
    static var useCoreDataItemsRepository: Bool {
        #if DEBUG
        return false  // Disabled by default, toggle for testing
        #else
        return false  // Disabled in production until fully tested
        #endif
    }

    /// Use Core Data UserProfile repository (true) or current implementation (false)
    /// Set to true for local offline persistence
    static var useCoreDataUserProfileRepository: Bool {
        #if DEBUG
        return false  // Disabled by default, toggle for testing
        #else
        return false  // Disabled in production until fully tested
        #endif
    }
}
