//
//  DeepLinkHandlerTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

// MARK: - Test Doubles

private struct NoOpLogger: Logger {
    func debug(_ message: String, category: String?, context: [String : String]?) {}
    func info(_ message: String, category: String?, context: [String : String]?) {}
    func warning(_ message: String, category: String?, context: [String : String]?) {}
    func error(_ message: String, category: String?, context: [String : String]?) {}
    func fault(_ message: String, category: String?, context: [String : String]?) {}
}

private final class RouterSpy: Router {
    private(set) var navigatedRoutes: [Route] = []
    private(set) var canNavigateChecks: [Route] = []
    var canNavigateResult = true

    func navigate(to route: Route) {
        navigatedRoutes.append(route)
    }

    func navigate(to url: URL) {
        // Not used in these tests
    }

    func canNavigate(to route: Route) async -> Bool {
        canNavigateChecks.append(route)
        return canNavigateResult
    }
}

/// Tests for UniversalLinkHandler and CustomURLSchemeHandler
/// Verifies deep link handling and routing
final class DeepLinkHandlerTests: XCTestCase {
    private var resolver: DefaultRouteResolver!
    private var router: RouterSpy!
    private var universalHandler: UniversalLinkHandler!
    private var customHandler: CustomURLSchemeHandler!

    override func setUp() {
        super.setUp()
        resolver = DefaultRouteResolver()
        router = RouterSpy()
        universalHandler = UniversalLinkHandler(routeResolver: resolver, router: router, logger: NoOpLogger())
        customHandler = CustomURLSchemeHandler(routeResolver: resolver, router: router, logger: NoOpLogger())
    }

    override func tearDown() {
        customHandler = nil
        universalHandler = nil
        resolver = nil
        router = nil
        super.tearDown()
    }

    // MARK: - UniversalLinkHandler Tests

    func testUniversalLinkHandler_canHandle_validDomain_returnsTrue() {
        let url = URL(string: "https://shell.app/login")!

        XCTAssertTrue(universalHandler.canHandle(url: url))
    }

    func testUniversalLinkHandler_canHandle_wwwSubdomain_returnsTrue() {
        let url = URL(string: "https://www.shell.app/login")!

        XCTAssertTrue(universalHandler.canHandle(url: url))
    }

    func testUniversalLinkHandler_canHandle_differentDomain_returnsFalse() {
        let url = URL(string: "https://example.com/login")!

        XCTAssertFalse(universalHandler.canHandle(url: url))
    }

    func testUniversalLinkHandler_canHandle_customScheme_returnsFalse() {
        let url = URL(string: "shell://login")!

        XCTAssertFalse(universalHandler.canHandle(url: url))
    }

    func testUniversalLinkHandler_handle_validURL_navigatesToRoute() {
        let url = URL(string: "https://shell.app/profile/user123")!
        let handled = universalHandler.handle(url: url)

        XCTAssertTrue(handled)
        XCTAssertEqual(router.navigatedRoutes.count, 1)
        XCTAssertEqual(router.navigatedRoutes.first, .profile(userID: "user123"))
    }

    func testUniversalLinkHandler_handle_invalidDomain_returnsFalse() {
        let url = URL(string: "https://example.com/profile/user123")!
        let handled = universalHandler.handle(url: url)

        XCTAssertFalse(handled)
        XCTAssertEqual(router.navigatedRoutes.count, 0)
    }

    // MARK: - CustomURLSchemeHandler Tests

    func testCustomURLSchemeHandler_canHandle_validScheme_returnsTrue() {
        let url = URL(string: "shell://login")!

        XCTAssertTrue(customHandler.canHandle(url: url))
    }

    func testCustomURLSchemeHandler_canHandle_httpsScheme_returnsFalse() {
        let url = URL(string: "https://shell.app/login")!

        XCTAssertFalse(customHandler.canHandle(url: url))
    }

    func testCustomURLSchemeHandler_handle_validURL_navigatesToRoute() {
        let url = URL(string: "shell://settings/privacy")!
        let handled = customHandler.handle(url: url)

        XCTAssertTrue(handled)
        XCTAssertEqual(router.navigatedRoutes.count, 1)
        XCTAssertEqual(router.navigatedRoutes.first, .settings(section: .privacy))
    }

    func testCustomURLSchemeHandler_handle_invalidScheme_returnsFalse() {
        let url = URL(string: "https://shell.app/settings/privacy")!
        let handled = customHandler.handle(url: url)

        XCTAssertFalse(handled)
        XCTAssertEqual(router.navigatedRoutes.count, 0)
    }

    // MARK: - Integration Tests

    func testDeepLinkHandlers_bothHandlers_correctPriority() {
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
