//
//  OSLogLoggerTests.swift
//  ShellTests
//
//  Created by Shell on 2026-02-02.
//

import XCTest
@testable import Shell

/// Tests for OSLogLogger
/// Verifies Logger protocol conformance and API surface
/// Note: OSLog doesn't expose logs for inspection, so we verify invocations don't crash
final class OSLogLoggerTests: XCTestCase {
    private var sut: OSLogLogger!

    override func setUp() {
        super.setUp()
        sut = OSLogLogger(subsystem: "com.test.shell", defaultCategory: "test")
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Protocol Conformance

    func testConformsToLoggerProtocol() {
        // Verify OSLogLogger conforms to Logger protocol
        XCTAssertNotNil(sut as Logger)
    }

    func testInitialization_withSubsystemAndCategory_succeeds() {
        let logger = OSLogLogger(subsystem: "com.example.app", defaultCategory: "network")
        XCTAssertNotNil(logger)
    }

    // MARK: - Log Level Methods

    func testDebugLogging_withMessage_doesNotCrash() {
        // OSLog doesn't expose logs for inspection
        // We verify the method can be called without crashing
        sut.debug("Debug message", category: nil, context: nil)
        sut.debug("Debug with category", category: "test-category", context: nil)
        sut.debug("Debug with context", category: nil, context: ["key": "value"])
    }

    func testInfoLogging_withMessage_doesNotCrash() {
        sut.info("Info message", category: nil, context: nil)
        sut.info("Info with category", category: "network", context: nil)
        sut.info("Info with context", category: nil, context: ["userId": "123"])
    }

    func testWarningLogging_withMessage_doesNotCrash() {
        sut.warning("Warning message", category: nil, context: nil)
        sut.warning("Warning with category", category: "auth", context: nil)
        sut.warning("Warning with context", category: nil, context: ["attempt": "3"])
    }

    func testErrorLogging_withMessage_doesNotCrash() {
        sut.error("Error message", category: nil, context: nil)
        sut.error("Error with category", category: "database", context: nil)
        sut.error("Error with context", category: nil, context: ["code": "500"])
    }

    func testFaultLogging_withMessage_doesNotCrash() {
        sut.fault("Fault message", category: nil, context: nil)
        sut.fault("Fault with category", category: "system", context: nil)
        sut.fault("Fault with context", category: nil, context: ["critical": "true"])
    }

    // MARK: - Convenience Extensions

    func testDebugConvenience_withoutCategoryOrContext_doesNotCrash() {
        sut.debug("Simple debug message")
    }

    func testDebugConvenience_withCategoryOnly_doesNotCrash() {
        sut.debug("Debug with category", category: "ui")
    }

    func testInfoConvenience_withoutCategoryOrContext_doesNotCrash() {
        sut.info("Simple info message")
    }

    func testWarningConvenience_withoutCategoryOrContext_doesNotCrash() {
        sut.warning("Simple warning message")
    }

    func testErrorConvenience_withoutCategoryOrContext_doesNotCrash() {
        sut.error("Simple error message")
    }

    func testFaultConvenience_withoutCategoryOrContext_doesNotCrash() {
        sut.fault("Simple fault message")
    }

    // MARK: - Context Formatting

    func testLogging_withMultipleContextValues_doesNotCrash() {
        let context = [
            "userId": "12345",
            "action": "login",
            "timestamp": "2026-02-02T12:00:00Z"
        ]
        sut.info("User action", category: "analytics", context: context)
    }

    func testLogging_withEmptyContext_doesNotCrash() {
        sut.info("Message with empty context", category: "test", context: [:])
    }
}
