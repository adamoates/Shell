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

    init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    func canAccess(route: Route) async -> AccessDecision {
        // Unauthenticated routes are always allowed
        guard route.requiresAuth else {
            return .allowed
        }

        // Check session
        guard let session = try? await sessionRepository.getCurrentSession() else {
            return .denied(reason: .unauthenticated)
        }

        // Check session validity
        guard session.isValid else {
            // Clear expired session
            try? await sessionRepository.clearSession()
            return .denied(reason: .unauthenticated)
        }

        // Future: Check additional permissions, account status, etc.
        // if session.isLocked {
        //     return .denied(reason: .locked)
        // }

        return .allowed
    }
}
