//
//  DefaultRouteResolver.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Resolves URLs to type-safe Routes
/// Handles both universal links (https://shell.app/...) and custom schemes (shell://...)
final class DefaultRouteResolver: RouteResolver {
    func resolve(url: URL) -> Route? {
        // Parse path components (handle both HTTPS and custom schemes)
        let pathComponents: [String]
        if let scheme = url.scheme, scheme != "http", scheme != "https" {
            // Custom scheme (e.g., shell://profile/user123)
            // Host becomes first component, path components follow
            var components: [String] = []
            if let host = url.host {
                components.append(host)
            }
            // Drop leading slash to avoid empty string
            components.append(contentsOf: url.pathComponents.dropFirst())
            pathComponents = components
        } else {
            // HTTPS/HTTP (e.g., https://shell.app/profile/user123)
            // Drop leading slash and use path components
            pathComponents = Array(url.pathComponents.dropFirst())
        }

        guard let firstComponent = pathComponents.first else {
            // Root URL -> home
            return .home
        }

        switch firstComponent {
        case "login":
            return .login

        case "signup":
            return .signup

        case "forgot-password":
            return .forgotPassword

        case "reset-password":
            // Extract token from query parameters
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems,
                  let tokenItem = queryItems.first(where: { $0.name == "token" }),
                  let token = tokenItem.value, !token.isEmpty else {
                return .notFound(path: url.path)
            }
            return .resetPassword(token: token)

        case "home":
            return .home

        case "profile":
            // Profile requires userID parameter
            guard pathComponents.count > 1 else {
                return .notFound(path: url.path)
            }

            let userID = pathComponents[1]
            let params = ["userID": userID]

            // Validate parameters
            switch ProfileParameters.validate(params) {
            case .success(let validatedParams):
                return .profile(userID: validatedParams.userID)
            case .failure:
                return .notFound(path: url.path)
            }

        case "settings":
            // Settings with optional section
            let section: SettingsSection?
            if pathComponents.count > 1 {
                section = SettingsSection(rawValue: pathComponents[1])
            } else {
                section = nil
            }
            return .settings(section: section)

        case "identity":
            // Identity setup with optional step
            let step: IdentityStep?
            if pathComponents.count > 1 {
                step = IdentityStep(rawValue: pathComponents[1])
            } else {
                step = nil
            }
            return .identitySetup(step: step)

        default:
            return .notFound(path: url.path)
        }
    }
}
