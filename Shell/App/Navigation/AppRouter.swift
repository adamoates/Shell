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
    private let routeResolver: RouteResolver

    init(coordinator: AppCoordinator, accessControl: RouteAccessControl, routeResolver: RouteResolver) {
        self.coordinator = coordinator
        self.accessControl = accessControl
        self.routeResolver = routeResolver
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

    func navigate(to url: URL) {
        print("🔗 AppRouter: Resolving URL: \(url)")

        // Resolve URL to Route
        guard let route = routeResolver.resolve(url: url) else {
            print("⚠️ AppRouter: Could not resolve URL to route")
            return
        }

        print("✅ AppRouter: Resolved to route: \(route.description)")

        // Navigate to the resolved route
        navigate(to: route)
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
            // Show profile for user
            print("  → Profile: \(userID)")
            coordinator.showProfile(userID: userID)

        case .settings(let section):
            // Future: Settings coordinator
            print("  → Settings section: \(section?.rawValue ?? "main")")
            // For now, just route to authenticated
            coordinator.route(to: .authenticated)

        case .identitySetup(let step):
            // Show identity setup flow
            print("  → Identity setup step: \(step?.rawValue ?? "start")")
            coordinator.showIdentitySetup(startStep: step)

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
            // Save the intended route for post-login redirect
            coordinator.saveIntendedRoute(route)
            // Redirect to login
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
