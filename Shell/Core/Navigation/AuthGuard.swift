//
//  AuthGuard.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Guards routes based on authentication state
/// Checks session validity before allowing access to protected routes
final class AuthGuard: RouteAccessControl {
    private let sessionRepository: SessionRepository
    private let logger: Logger

    init(sessionRepository: SessionRepository, logger: Logger) {
        self.sessionRepository = sessionRepository
        self.logger = logger
    }

    func canAccess(route: Route) async -> AccessDecision {
        // Unauthenticated routes are always allowed
        guard route.requiresAuth else {
            logger.debug("Route allowed (no auth required)", category: "navigation", context: ["route": route.description])
            return .allowed
        }

        // Check session
        guard let session = try? await sessionRepository.getCurrentSession() else {
            logger.info(
                "Route denied (no session)",
                category: "navigation",
                context: ["route": route.description, "reason": "unauthenticated"]
            )
            return .denied(reason: .unauthenticated)
        }

        // Check session validity
        guard session.isValid else {
            logger.info(
                "Route denied (session expired)",
                category: "navigation",
                context: ["route": route.description, "userID": session.userId]
            )
            // Clear expired session
            try? await sessionRepository.clearSession()
            return .denied(reason: .unauthenticated)
        }

        // Future: Check additional permissions, account status, etc.
        // if session.isLocked {
        //     return .denied(reason: .locked)
        // }

        logger.debug("Route allowed", category: "navigation", context: ["route": route.description, "userID": session.userId])
        return .allowed
    }
}
