//
//  ProfileViewModelTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for ProfileViewModel
/// Verifies loading states, error handling, and retry logic
@MainActor
final class ProfileViewModelTests: XCTestCase {
    private var sut: ProfileViewModel!
    private var mockFetchProfile: FetchProfileUseCaseFake!
    private let testUserID = "test-user-123"

    override func setUp() {
        super.setUp()
        mockFetchProfile = FetchProfileUseCaseFake()
        sut = ProfileViewModel(
            userID: testUserID,
            fetchProfile: mockFetchProfile
        )
    }

    override func tearDown() {
        sut = nil
        mockFetchProfile = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_isIdle() {
        // Assert
        if case .idle = sut.state {
            // Success
        } else {
            XCTFail("Expected idle state, got \(sut.state)")
        }
    }

    // MARK: - Loading State Tests

    func testLoadProfile_setsLoadingState() async {
        // Arrange
        mockFetchProfile.shouldReturnProfile = true
        mockFetchProfile.delay = 0.1  // Add delay to catch loading state

        // Act
        let loadTask = Task {
            await sut.loadProfile()
        }

        // Give time for loading state to be set
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        // Assert - should be in loading state
        XCTAssertTrue(sut.state.isLoading)

        // Wait for completion
        await loadTask.value
    }

    func testLoadProfile_success_setsLoadedState() async {
        // Arrange
        let expectedProfile = UserProfile(
            userID: testUserID,
            screenName: "TestUser",
            birthday: Date(),
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockFetchProfile.profileToReturn = expectedProfile
        mockFetchProfile.shouldReturnProfile = true

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertFalse(sut.state.isLoading)
        XCTAssertNil(sut.state.errorMessage)
        XCTAssertEqual(sut.state.profile, expectedProfile)
    }

    // MARK: - Error State Tests

    func testLoadProfile_notFound_setsErrorState() async {
        // Arrange
        mockFetchProfile.shouldReturnProfile = false

        // Act
        await sut.loadProfile()

        // Assert
        XCTAssertFalse(sut.state.isLoading)
        XCTAssertNotNil(sut.state.errorMessage)
        XCTAssertEqual(sut.state.errorMessage, ProfileError.notFound.localizedDescription)
        XCTAssertFalse(sut.state.canRetry)  // Not found is not retryable
    }

    // MARK: - Retry Logic Tests

    func testRetryLoadProfile_callsUseCaseAgain() async {
        // Arrange
        mockFetchProfile.shouldReturnProfile = false
        await sut.loadProfile()

        // Verify initial error state
        XCTAssertNotNil(sut.state.errorMessage)

        // Change mock to succeed
        mockFetchProfile.shouldReturnProfile = true
        let expectedProfile = UserProfile(
            userID: testUserID,
            screenName: "TestUser",
            birthday: Date(),
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockFetchProfile.profileToReturn = expectedProfile

        // Act
        await sut.retryLoadProfile()

        // Assert
        XCTAssertNil(sut.state.errorMessage)
        XCTAssertEqual(sut.state.profile, expectedProfile)
        XCTAssertEqual(mockFetchProfile.executeCallCount, 2)
    }

    func testRetryLoadProfile_afterNetworkError_succeeds() async {
        // Arrange - initial failure
        mockFetchProfile.shouldReturnProfile = false
        await sut.loadProfile()

        // Verify error state
        XCTAssertNotNil(sut.state.errorMessage)

        // Arrange - retry succeeds
        let profile = UserProfile(
            userID: testUserID,
            screenName: "RetryUser",
            birthday: Date(),
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        mockFetchProfile.profileToReturn = profile
        mockFetchProfile.shouldReturnProfile = true

        // Act
        await sut.retryLoadProfile()

        // Assert
        XCTAssertEqual(sut.state.profile?.screenName, "RetryUser")
        XCTAssertNil(sut.state.errorMessage)
    }
}

// MARK: - Test Doubles

private class FetchProfileUseCaseFake: FetchProfileUseCase {
    var executeCallCount = 0
    var shouldReturnProfile = true
    var profileToReturn: UserProfile?
    var delay: TimeInterval = 0

    func execute(userID: String) async -> UserProfile? {
        executeCallCount += 1

        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        return shouldReturnProfile ? profileToReturn : nil
    }
}
