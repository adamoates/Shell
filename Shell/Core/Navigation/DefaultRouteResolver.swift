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
        // Parse path components
        let pathComponents = url.pathComponents.filter { $0 != "/" }

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
