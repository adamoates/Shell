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
    private let logger: Logger

    init(
        coordinator: AppCoordinator,
        accessControl: RouteAccessControl,
        routeResolver: RouteResolver,
        logger: Logger
    ) {
        self.coordinator = coordinator
        self.accessControl = accessControl
        self.routeResolver = routeResolver
        self.logger = logger
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
        logger.info("Resolving URL", category: "navigation", context: ["url": url.absoluteString])

        // Resolve URL to Route
        guard let route = routeResolver.resolve(url: url) else {
            logger.warning("Could not resolve URL to route", category: "navigation", context: ["url": url.absoluteString])
            return
        }

        logger.info("Resolved URL to route", category: "navigation", context: ["route": route.description])

        // Navigate to the resolved route
        navigate(to: route)
    }

    // MARK: - Private

    @MainActor
    private func routeToCoordinator(_ route: Route) {
        logger.info("Routing to coordinator", category: "navigation", context: ["route": route.description])

        switch route {
        case .login, .signup, .forgotPassword:
            // All guest flows route to guest coordinator
            coordinator.route(to: .unauthenticated)

        case .home:
            // Authenticated home
            coordinator.route(to: .authenticated)

        case .profile(let userID):
            // Show profile for user
            logger.debug("Routing to profile", category: "navigation", context: ["userID": userID])
            coordinator.showProfile(userID: userID)

        case .settings(let section):
            // Future: Settings coordinator
            logger.debug("Routing to settings", category: "navigation", context: ["section": section?.rawValue ?? "main"])
            // For now, just route to authenticated
            coordinator.route(to: .authenticated)

        case .identitySetup(let step):
            // Show identity setup flow
            logger.debug("Routing to identity setup", category: "navigation", context: ["step": step?.rawValue ?? "start"])
            coordinator.showIdentitySetup(startStep: step)

        case .notFound(let path):
            logger.warning("Route not found", category: "navigation", context: ["path": path])
            // Fall back to appropriate flow based on auth state
            coordinator.route(to: .authenticated)

        case .unauthorized:
            // Redirect to login (handled below)
            break
        }
    }

    @MainActor
    private func handleDenial(route: Route, reason: DenialReason) {
        logger.warning(
            "Access denied",
            category: "navigation",
            context: ["route": route.description, "reason": "\(reason)"]
        )

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
            logger.debug("Insufficient permissions, redirecting", category: "navigation")
            coordinator.route(to: .authenticated)

        case .requiresAdditionalInfo:
            // Redirect to identity setup
            // Future: Show identity setup flow
            logger.debug("Requires additional info, redirecting", category: "navigation")
            coordinator.route(to: .authenticated)
        }
    }
}
