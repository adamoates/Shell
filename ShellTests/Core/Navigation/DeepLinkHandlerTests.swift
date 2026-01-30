//
//  DeepLinkHandlerTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for UniversalLinkHandler and CustomURLSchemeHandler
/// Verifies deep link handling and routing
final class DeepLinkHandlerTests: XCTestCase {

    // MARK: - Test Doubles

    private final class RouterSpy: Router {
        private(set) var navigatedRoutes: [Route] = []
        private(set) var canNavigateChecks: [Route] = []
        var canNavigateResult = true

        func navigate(to route: Route) {
            navigatedRoutes.append(route)
        }

        func canNavigate(to route: Route) async -> Bool {
            canNavigateChecks.append(route)
            return canNavigateResult
        }
    }

    // MARK: - UniversalLinkHandler Tests

    func testUniversalLinkHandler_canHandle_validDomain_returnsTrue() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()
        let sut = UniversalLinkHandler(routeResolver: resolver, router: router)

        let url = URL(string: "https://shell.app/login")!

        XCTAssertTrue(sut.canHandle(url: url))
    }

    func testUniversalLinkHandler_canHandle_wwwSubdomain_returnsTrue() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()
        let sut = UniversalLinkHandler(routeResolver: resolver, router: router)

        let url = URL(string: "https://www.shell.app/login")!

        XCTAssertTrue(sut.canHandle(url: url))
    }

    func testUniversalLinkHandler_canHandle_differentDomain_returnsFalse() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()
        let sut = UniversalLinkHandler(routeResolver: resolver, router: router)

        let url = URL(string: "https://example.com/login")!

        XCTAssertFalse(sut.canHandle(url: url))
    }

    func testUniversalLinkHandler_canHandle_customScheme_returnsFalse() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()
        let sut = UniversalLinkHandler(routeResolver: resolver, router: router)

        let url = URL(string: "shell://login")!

        XCTAssertFalse(sut.canHandle(url: url))
    }

    func testUniversalLinkHandler_handle_validURL_navigatesToRoute() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()
        let sut = UniversalLinkHandler(routeResolver: resolver, router: router)

        let url = URL(string: "https://shell.app/profile/user123")!
        let handled = sut.handle(url: url)

        XCTAssertTrue(handled)
        XCTAssertEqual(router.navigatedRoutes.count, 1)
        XCTAssertEqual(router.navigatedRoutes.first, .profile(userID: "user123"))
    }

    func testUniversalLinkHandler_handle_invalidDomain_returnsFalse() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()
        let sut = UniversalLinkHandler(routeResolver: resolver, router: router)

        let url = URL(string: "https://example.com/profile/user123")!
        let handled = sut.handle(url: url)

        XCTAssertFalse(handled)
        XCTAssertEqual(router.navigatedRoutes.count, 0)
    }

    // MARK: - CustomURLSchemeHandler Tests

    func testCustomURLSchemeHandler_canHandle_validScheme_returnsTrue() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()
        let sut = CustomURLSchemeHandler(routeResolver: resolver, router: router)

        let url = URL(string: "shell://login")!

        XCTAssertTrue(sut.canHandle(url: url))
    }

    func testCustomURLSchemeHandler_canHandle_httpsScheme_returnsFalse() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()
        let sut = CustomURLSchemeHandler(routeResolver: resolver, router: router)

        let url = URL(string: "https://shell.app/login")!

        XCTAssertFalse(sut.canHandle(url: url))
    }

    func testCustomURLSchemeHandler_handle_validURL_navigatesToRoute() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()
        let sut = CustomURLSchemeHandler(routeResolver: resolver, router: router)

        let url = URL(string: "shell://settings/privacy")!
        let handled = sut.handle(url: url)

        XCTAssertTrue(handled)
        XCTAssertEqual(router.navigatedRoutes.count, 1)
        XCTAssertEqual(router.navigatedRoutes.first, .settings(section: .privacy))
    }

    func testCustomURLSchemeHandler_handle_invalidScheme_returnsFalse() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()
        let sut = CustomURLSchemeHandler(routeResolver: resolver, router: router)

        let url = URL(string: "https://shell.app/settings/privacy")!
        let handled = sut.handle(url: url)

        XCTAssertFalse(handled)
        XCTAssertEqual(router.navigatedRoutes.count, 0)
    }

    // MARK: - Integration Tests

    func testDeepLinkHandlers_bothHandlers_correctPriority() {
        let resolver = DefaultRouteResolver()
        let router = RouterSpy()

        let universalHandler = UniversalLinkHandler(routeResolver: resolver, router: router)
        let customHandler = CustomURLSchemeHandler(routeResolver: resolver, router: router)

        let handlers: [DeepLinkHandler] = [universalHandler, customHandler]

        // Test universal link
        let universalURL = URL(string: "https://shell.app/login")!
        var handled = false
        for handler in handlers {
            if handler.handle(url: universalURL) {
                handled = true
                break
            }
        }
        XCTAssertTrue(handled)
        XCTAssertEqual(router.navigatedRoutes.last, .login)

        // Test custom scheme
        let customURL = URL(string: "shell://signup")!
        handled = false
        for handler in handlers {
            if handler.handle(url: customURL) {
                handled = true
                break
            }
        }
        XCTAssertTrue(handled)
        XCTAssertEqual(router.navigatedRoutes.last, .signup)
    }
}
