//
//  UniversalLinkHandler.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Handles universal links (https://shell.app/...)
/// Maps URLs to routes and navigates via router
final class UniversalLinkHandler: DeepLinkHandler {
    private let routeResolver: RouteResolver
    private let router: Router

    init(routeResolver: RouteResolver, router: Router) {
        self.routeResolver = routeResolver
        self.router = router
    }

    func canHandle(url: URL) -> Bool {
        // Check if URL matches app's associated domain
        guard let host = url.host else { return false }

        // Accept both shell.app and www.shell.app
        return host == "shell.app" || host == "www.shell.app"
    }

    func handle(url: URL) -> Bool {
        guard canHandle(url: url) else { return false }

        guard let route = routeResolver.resolve(url: url) else {
            print("⚠️ UniversalLinkHandler: Could not resolve URL to route: \(url)")
            return false
        }

        print("🔗 UniversalLinkHandler: Navigating to \(route.description)")
        router.navigate(to: route)
        return true
    }
}
