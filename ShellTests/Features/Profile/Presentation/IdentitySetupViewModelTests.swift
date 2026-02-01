//
//  IdentitySetupViewModelTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for IdentitySetupViewModel
/// Verifies validation, loading states, error handling, and retry logic
@MainActor
final class IdentitySetupViewModelTests: XCTestCase {
    private var sut: IdentitySetupViewModel!
    private var mockCompleteIdentitySetup: CompleteIdentitySetupUseCaseFake!
    private let testUserID = "test-user-123"

    override func setUp() {
        super.setUp()
        mockCompleteIdentitySetup = CompleteIdentitySetupUseCaseFake()
        sut = IdentitySetupViewModel(
            userID: testUserID,
            completeIdentitySetup: mockCompleteIdentitySetup
        )
    }

    override func tearDown() {
        sut = nil
        mockCompleteIdentitySetup = nil
        super.tearDown()
    }

    // MARK: - Validation Tests

    func testValidateScreenName_valid_returnsTrue() {
        // Arrange
        sut.screenName = "valid_user"

        // Act
        let isValid = sut.validateScreenName()

        // Assert
        XCTAssertTrue(isValid)
        XCTAssertNil(sut.validationError)
    }

    func testValidateScreenName_tooShort_returnsFalse() {
        // Arrange
        sut.screenName = "a"

        // Act
        let isValid = sut.validateScreenName()

        // Assert
        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationError)
    }

    func testValidateBirthday_valid_returnsTrue() {
        // Arrange
        let calendar = Calendar.current
        sut.birthday = calendar.date(byAdding: .year, value: -20, to: Date())!

        // Act
        let isValid = sut.validateBirthday()

        // Assert
        XCTAssertTrue(isValid)
        XCTAssertNil(sut.validationError)
    }

    func testValidateBirthday_tooYoung_returnsFalse() {
        // Arrange
        let calendar = Calendar.current
        sut.birthday = calendar.date(byAdding: .year, value: -10, to: Date())!

        // Act
        let isValid = sut.validateBirthday()

        // Assert
        XCTAssertFalse(isValid)
        XCTAssertNotNil(sut.validationError)
    }

    // MARK: - Loading State Tests

    func testCompleteSetup_setsLoadingState() async {
        // Arrange
        sut.screenName = "valid_user"
        let calendar = Calendar.current
        sut.birthday = calendar.date(byAdding: .year, value: -20, to: Date())!
        mockCompleteIdentitySetup.delay = 0.1

        // Act
        let completeTask = Task {
            await sut.completeSetup()
        }

        // Give time for loading state to be set
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        // Assert - should be completing
        XCTAssertTrue(sut.isCompleting)

        // Wait for completion
        _ = await completeTask.value
    }

    func testCompleteSetup_success_clearsLoadingAndError() async {
        // Arrange
        sut.screenName = "valid_user"
        let calendar = Calendar.current
        sut.birthday = calendar.date(byAdding: .year, value: -20, to: Date())!

        // Act
        let profile = await sut.completeSetup()

        // Assert
        XCTAssertNotNil(profile)
        XCTAssertFalse(sut.isCompleting)
        XCTAssertNil(sut.completionError)
        XCTAssertFalse(sut.canRetry)
    }

    // MARK: - Error State Tests

    func testCompleteSetup_validationError_setsError() async {
        // Arrange
        sut.screenName = "a"  // Too short
        let calendar = Calendar.current
        sut.birthday = calendar.date(byAdding: .year, value: -20, to: Date())!

        // Act
        let profile = await sut.completeSetup()

        // Assert
        XCTAssertNil(profile)
        XCTAssertFalse(sut.isCompleting)
        XCTAssertNotNil(sut.completionError)
        XCTAssertFalse(sut.canRetry)  // Validation errors are not retryable
    }

    // MARK: - Retry Logic Tests

    func testRetryCompleteSetup_callsUseCaseAgain() async {
        // Arrange
        sut.screenName = "valid_user"
        let calendar = Calendar.current
        sut.birthday = calendar.date(byAdding: .year, value: -20, to: Date())!

        // First completion
        await sut.completeSetup()
        XCTAssertEqual(mockCompleteIdentitySetup.executeCallCount, 1)

        // Act - retry (even though first succeeded, test the retry path)
        let profile = await sut.retryCompleteSetup()

        // Assert
        XCTAssertNotNil(profile)
        XCTAssertEqual(mockCompleteIdentitySetup.executeCallCount, 2)
    }
}

// MARK: - Test Doubles

private class CompleteIdentitySetupUseCaseFake: CompleteIdentitySetupUseCase {
    var executeCallCount = 0
    var delay: TimeInterval = 0
    var profileToReturn: UserProfile?

    func execute(userID: String, identityData: IdentityData, avatarURL: URL?) async -> UserProfile {
        executeCallCount += 1

        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        // Return the provided profile or create a new one
        return profileToReturn ?? UserProfile.create(
            userID: userID,
            identityData: identityData,
            avatarURL: avatarURL
        )
    }
}
