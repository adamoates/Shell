//
//  RouteAccessControl.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Protocol for checking route access permissions
/// Implemented by AuthGuard
protocol RouteAccessControl {
    /// Check if the route can be accessed
    /// Returns decision with reason if denied
    func canAccess(route: Route) async -> AccessDecision
}

/// Result of access control check
enum AccessDecision: Equatable {
    case allowed
    case denied(reason: DenialReason)
}

/// Reasons why access might be denied
enum DenialReason: Equatable {
    case unauthenticated
    case locked
    case insufficientPermissions
    case requiresAdditionalInfo
}
