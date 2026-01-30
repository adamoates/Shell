//
//  AppRouter.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Main router for the app
/// Coordinates between routes, auth guards, and AppCoordinator
final class AppRouter: Router {
    private let coordinator: AppCoordinator
    private let accessControl: RouteAccessControl

    init(coordinator: AppCoordinator, accessControl: RouteAccessControl) {
        self.coordinator = coordinator
        self.accessControl = accessControl
    }

    func canNavigate(to route: Route) async -> Bool {
        let decision = await accessControl.canAccess(route: route)

        switch decision {
        case .allowed:
            return true
        case .denied:
            return false
        }
    }

    func navigate(to route: Route) {
        Task { @MainActor in
            // Check access control
            let decision = await accessControl.canAccess(route: route)

            switch decision {
            case .allowed:
                routeToCoordinator(route)

            case .denied(let reason):
                handleDenial(route: route, reason: reason)
            }
        }
    }

    // MARK: - Private

    @MainActor
    private func routeToCoordinator(_ route: Route) {
        print("🧭 AppRouter: Routing to \(route.description)")

        switch route {
        case .login, .signup, .forgotPassword:
            // All guest flows route to guest coordinator
            coordinator.route(to: .unauthenticated)

        case .home:
            // Authenticated home
            coordinator.route(to: .authenticated)

        case .profile(let userID):
            // Future: Specific profile coordinator
            print("  → Profile: \(userID)")
            // For now, just route to authenticated
            coordinator.route(to: .authenticated)

        case .settings(let section):
            // Future: Settings coordinator
            print("  → Settings section: \(section?.rawValue ?? "main")")
            // For now, just route to authenticated
            coordinator.route(to: .authenticated)

        case .identitySetup(let step):
            // Future: Identity flow coordinator
            print("  → Identity setup step: \(step?.rawValue ?? "start")")
            // For now, just route to authenticated
            coordinator.route(to: .authenticated)

        case .notFound(let path):
            print("⚠️ AppRouter: Route not found: \(path)")
            // Fall back to appropriate flow based on auth state
            coordinator.route(to: .authenticated)

        case .unauthorized:
            // Redirect to login (handled below)
            break
        }
    }

    @MainActor
    private func handleDenial(route: Route, reason: DenialReason) {
        print("🚫 AppRouter: Access denied for \(route.description)")
        print("   Reason: \(reason)")

        switch reason {
        case .unauthenticated:
            // Redirect to login
            // Future: Save intended destination for post-login redirect
            coordinator.route(to: .unauthenticated)

        case .locked:
            // Show locked screen
            coordinator.route(to: .locked)

        case .insufficientPermissions:
            // Future: Show error message
            print("   → Insufficient permissions")
            coordinator.route(to: .authenticated)

        case .requiresAdditionalInfo:
            // Redirect to identity setup
            // Future: Show identity setup flow
            print("   → Requires additional info")
            coordinator.route(to: .authenticated)
        }
    }
}
