//
//  Router.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Protocol for app-wide navigation
/// Implemented by AppRouter, which coordinates with AppCoordinator
protocol Router: AnyObject {
    /// Navigate to a route
    /// Checks auth guards and delegates to coordinator
    func navigate(to route: Route)

    /// Check if navigation to route is allowed
    /// Returns false if auth guard denies access
    func canNavigate(to route: Route) async -> Bool
}
