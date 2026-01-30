//
//  Route.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Type-safe representation of all app routes
/// Ensures compile-time safety for navigation
indirect enum Route: Equatable {
    // MARK: - Unauthenticated Routes

    /// Login screen
    case login

    /// Signup screen
    case signup

    /// Forgot password flow
    case forgotPassword

    // MARK: - Authenticated Routes

    /// Home screen (authenticated)
    case home

    /// User profile screen
    case profile(userID: String)

    /// Settings screen with optional section
    case settings(section: SettingsSection?)

    /// Identity setup flow (demonstrates form engine)
    case identitySetup(step: IdentityStep?)

    // MARK: - Error/Fallback Routes

    /// Route not found
    case notFound(path: String)

    /// Unauthorized access (redirect to login)
    case unauthorized(requestedRoute: Route)

    // MARK: - Route Properties

    /// Whether this route requires authentication
    var requiresAuth: Bool {
        switch self {
        case .login, .signup, .forgotPassword:
            return false
        case .home, .profile, .settings, .identitySetup:
            return true
        case .notFound, .unauthorized:
            return false
        }
    }

    /// Human-readable description for debugging
    var description: String {
        switch self {
        case .login:
            return "Login"
        case .signup:
            return "Signup"
        case .forgotPassword:
            return "Forgot Password"
        case .home:
            return "Home"
        case .profile(let userID):
            return "Profile (userID: \(userID))"
        case .settings(let section):
            return "Settings (section: \(section?.rawValue ?? "main"))"
        case .identitySetup(let step):
            return "Identity Setup (step: \(step?.rawValue ?? "start"))"
        case .notFound(let path):
            return "Not Found (path: \(path))"
        case .unauthorized(let requestedRoute):
            return "Unauthorized (requested: \(requestedRoute.description))"
        }
    }
}

// MARK: - Settings Section

/// Settings screen sections
enum SettingsSection: String, Codable, Equatable {
    case account
    case privacy
    case notifications
    case about
}

// MARK: - Identity Step

/// Identity setup flow steps
enum IdentityStep: String, Codable, Equatable {
    case screenName
    case birthday
    case avatar
    case review
}
