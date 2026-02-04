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
    private let logger: Logger

    init(routeResolver: RouteResolver, router: Router, logger: Logger) {
        self.routeResolver = routeResolver
        self.router = router
        self.logger = logger
    }

    func canHandle(url: URL) -> Bool {
        // Check for custom scheme (shell://)
        return url.scheme == "shell"
    }

    func handle(url: URL) -> Bool {
        guard canHandle(url: url) else { return false }

        guard let route = routeResolver.resolve(url: url) else {
            logger.warning("Could not resolve custom URL to route", category: "deeplink", context: ["url": url.absoluteString])
            return false
        }

        logger.info("Navigating to route from custom URL", category: "deeplink", context: ["route": route.description, "url": url.absoluteString])
        router.navigate(to: route)
        return true
    }
}
