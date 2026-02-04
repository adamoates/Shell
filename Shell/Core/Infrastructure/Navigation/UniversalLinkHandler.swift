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
    private let logger: Logger

    init(routeResolver: RouteResolver, router: Router, logger: Logger) {
        self.routeResolver = routeResolver
        self.router = router
        self.logger = logger
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
            logger.warning("Could not resolve universal link to route", category: "deeplink", context: ["url": url.absoluteString])
            return false
        }

        logger.info("Navigating to route from universal link", category: "deeplink", context: ["route": route.description, "url": url.absoluteString])
        router.navigate(to: route)
        return true
    }
}
