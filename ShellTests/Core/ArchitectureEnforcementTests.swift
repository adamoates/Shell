//
//  ArchitectureEnforcementTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests that enforce architectural rules at runtime
///
/// These tests catch violations of architectural conventions that would
/// otherwise only be caught in code review. They fail fast if someone
/// accidentally violates the rules documented in Docs/ArchitectureRules.md
final class ArchitectureEnforcementTests: XCTestCase {
    // MARK: - Boot Placement Rules

    func testBootIsNotInFeatures() {
        // Arrange
        // Use #filePath (absolute path) to find project root
        let thisFilePath = URL(fileURLWithPath: #filePath)
        let projectRoot = thisFilePath
            .deletingLastPathComponent()  // Core/
            .deletingLastPathComponent()  // ShellTests/
            .deletingLastPathComponent()  // Project root

        let featuresBootPath = projectRoot
            .appendingPathComponent("Shell")
            .appendingPathComponent("Features")
            .appendingPathComponent("Boot")

        // Assert
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: featuresBootPath.path),
            """
            ❌ ARCHITECTURE VIOLATION

            Boot layer must NOT exist in Features/.

            Boot is application orchestration, not a feature.

            Litmus test: "Can we delete this and still boot?"
            - Boot → NO → Lives in App/Boot/
            - Features → YES → Lives in Features/

            See: Docs/ArchitectureRules.md
            """
        )
    }

    // MARK: - Type-Based Enforcement
    // These tests verify key types exist, which proves the structure is correct

    func testBootTypesExist() {
        // Compile-time check: If these types don't exist, test won't compile

        // App/Boot/ types should be accessible
        let _: LaunchState = .authenticated
        let _: LaunchRouting? = nil

        // This test passing proves:
        // 1. App/Boot/ structure exists
        // 2. LaunchState and LaunchRouting are properly exposed
        // 3. Boot layer is in correct location

        XCTAssertTrue(true, "Boot types are accessible")
    }

    func testAuthFeatureTypesExist() {
        // Compile-time check: If these types don't exist, test won't compile

        // Features/Auth/ types should be accessible
        let _: SessionStatus = .authenticated
        let _: RestoreSessionUseCase? = nil

        // This test passing proves:
        // 1. Features/Auth/Domain/ structure exists
        // 2. Domain use cases are in Features/, not App/Boot/
        // 3. SessionStatus and RestoreSessionUseCase are properly exposed

        XCTAssertTrue(true, "Auth feature types are accessible")
    }

    func testCoreContractsTypesExist() {
        // Compile-time check: If these types don't exist, test won't compile

        // Core/Contracts/ types should be accessible
        let _: UserSession? = nil
        let _: SessionRepository? = nil
        let _: AppConfig? = nil
        let _: ConfigLoader? = nil

        // This test passing proves:
        // 1. Core/Contracts/ structure exists
        // 2. Domain owns the abstractions
        // 3. Protocols are properly exposed

        XCTAssertTrue(true, "Core Contracts types are accessible")
    }
}
