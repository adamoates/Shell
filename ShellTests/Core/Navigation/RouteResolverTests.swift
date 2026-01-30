//
//  RouteResolverTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for DefaultRouteResolver
/// Verifies URL → Route mapping
final class RouteResolverTests: XCTestCase {
    private var sut: DefaultRouteResolver!

    override func setUp() {
        super.setUp()
        sut = DefaultRouteResolver()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Root URL

    func testResolve_rootURL_resolvesToHome() {
        let url = URL(string: "https://shell.app/")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .home)
    }

    // MARK: - Auth Routes

    func testResolve_login_parsesCorrectly() {
        let url = URL(string: "https://shell.app/login")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .login)
    }

    func testResolve_signup_parsesCorrectly() {
        let url = URL(string: "https://shell.app/signup")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .signup)
    }

    func testResolve_forgotPassword_parsesCorrectly() {
        let url = URL(string: "https://shell.app/forgot-password")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .forgotPassword)
    }

    // MARK: - Profile Routes

    func testResolve_profileWithValidUserID_parsesCorrectly() {
        let url = URL(string: "https://shell.app/profile/user123")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .profile(userID: "user123"))
    }

    func testResolve_profileWithoutUserID_resolvesToNotFound() {
        let url = URL(string: "https://shell.app/profile")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .notFound(path: "/profile"))
    }

    func testResolve_profileWithInvalidUserID_resolvesToNotFound() {
        // UserID must be at least 3 characters (per ProfileParameters validation)
        let url = URL(string: "https://shell.app/profile/ab")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .notFound(path: "/profile/ab"))
    }

    // MARK: - Settings Routes

    func testResolve_settingsWithoutSection_parsesCorrectly() {
        let url = URL(string: "https://shell.app/settings")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .settings(section: nil))
    }

    func testResolve_settingsWithValidSection_parsesCorrectly() {
        let url = URL(string: "https://shell.app/settings/privacy")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .settings(section: .privacy))
    }

    func testResolve_settingsWithInvalidSection_parsesAsNil() {
        let url = URL(string: "https://shell.app/settings/invalid")!

        let route = sut.resolve(url: url)

        // Invalid sections default to nil (main settings)
        XCTAssertEqual(route, .settings(section: nil))
    }

    // MARK: - Identity Routes

    func testResolve_identityWithoutStep_parsesCorrectly() {
        let url = URL(string: "https://shell.app/identity")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .identitySetup(step: nil))
    }

    func testResolve_identityWithValidStep_parsesCorrectly() {
        let url = URL(string: "https://shell.app/identity/screenName")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .identitySetup(step: .screenName))
    }

    func testResolve_identityWithInvalidStep_parsesAsNil() {
        let url = URL(string: "https://shell.app/identity/invalid")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .identitySetup(step: nil))
    }

    // MARK: - Unknown Routes

    func testResolve_unknownPath_resolvesToNotFound() {
        let url = URL(string: "https://shell.app/unknown")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .notFound(path: "/unknown"))
    }

    // MARK: - Custom URL Scheme

    func testResolve_customScheme_parsesCorrectly() {
        let url = URL(string: "shell://profile/user123")!

        let route = sut.resolve(url: url)

        XCTAssertEqual(route, .profile(userID: "user123"))
    }
}
