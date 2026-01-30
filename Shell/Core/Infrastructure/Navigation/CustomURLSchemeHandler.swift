//
//  CustomURLSchemeHandler.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Handles custom URL schemes (shell://...)
/// Maps URLs to routes and navigates via router
final class CustomURLSchemeHandler: DeepLinkHandler {
    private let routeResolver: RouteResolver
    private let router: Router

    init(routeResolver: RouteResolver, router: Router) {
        self.routeResolver = routeResolver
        self.router = router
    }

    func canHandle(url: URL) -> Bool {
        // Check for custom scheme (shell://)
        return url.scheme == "shell"
    }

    func handle(url: URL) -> Bool {
        guard canHandle(url: url) else { return false }

        guard let route = routeResolver.resolve(url: url) else {
            print("⚠️ CustomURLSchemeHandler: Could not resolve URL to route: \(url)")
            return false
        }

        print("🔗 CustomURLSchemeHandler: Navigating to \(route.description)")
        router.navigate(to: route)
        return true
    }
}
