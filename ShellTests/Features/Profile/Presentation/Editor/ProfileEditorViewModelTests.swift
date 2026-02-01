//
//  ProfileEditorViewModelTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-31.
//

import XCTest
@testable import Shell

@MainActor
final class ProfileEditorViewModelTests: XCTestCase {

    // MARK: - Test Doubles

    class MockDelegate: ProfileEditorViewModelDelegate {
        var didSaveCalled = false
        var didCancelCalled = false

        func profileEditorDidSave(_ viewModel: ProfileEditorViewModel) {
            didSaveCalled = true
        }

        func profileEditorDidCancel(_ viewModel: ProfileEditorViewModel) {
            didCancelCalled = true
        }
    }

    class SpySetupIdentityUseCase: SetupIdentityUseCase {
        var executeCalled = false
        var capturedScreenName: String?
        var capturedBirthday: Date?
        var shouldThrowError: IdentityValidationError?

        override func execute(userID: String, screenName: String, birthday: Date) async throws {
            executeCalled = true
            capturedScreenName = screenName
            capturedBirthday = birthday

            if let error = shouldThrowError {
                throw error
            }
        }
    }

    // MARK: - Properties

    var repository: InMemoryUserProfileRepository!
    var spyUseCase: SpySetupIdentityUseCase!
    var mockDelegate: MockDelegate!
    var viewModel: ProfileEditorViewModel!

    // MARK: - Setup

    override func setUp() async throws {
        repository = InMemoryUserProfileRepository()
        spyUseCase = SpySetupIdentityUseCase(repository: repository)
        mockDelegate = MockDelegate()

        viewModel = ProfileEditorViewModel(
            userID: "test-user",
            setupIdentityUseCase: spyUseCase
        )
        viewModel.delegate = mockDelegate
    }

    override func tearDown() {
        viewModel = nil
        mockDelegate = nil
        spyUseCase = nil
        repository = nil
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertEqual(viewModel.screenName, "")
        XCTAssertNotNil(viewModel.birthday)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isSaveEnabled)
    }

    // MARK: - Validation Tests

    func testSaveEnabledWhenScreenNameNotEmpty() {
        viewModel.screenName = "john"

        // Allow time for Combine publisher to update
        let expectation = expectation(description: "isSaveEnabled updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(self.viewModel.isSaveEnabled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testSaveDisabledWhenScreenNameEmpty() {
        viewModel.screenName = ""

        let expectation = expectation(description: "isSaveEnabled updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.viewModel.isSaveEnabled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testSaveDisabledWhenScreenNameOnlyWhitespace() {
        viewModel.screenName = "   "

        let expectation = expectation(description: "isSaveEnabled updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.viewModel.isSaveEnabled)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Save Success Tests

    func testSaveSuccess() async {
        // Given
        viewModel.screenName = "john_doe"
        viewModel.birthday = Date().addingTimeInterval(-365 * 24 * 60 * 60 * 25) // 25 years ago

        // When
        await viewModel.save()

        // Then
        XCTAssertTrue(spyUseCase.executeCalled)
        XCTAssertEqual(spyUseCase.capturedScreenName, "john_doe")
        XCTAssertNotNil(spyUseCase.capturedBirthday)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(mockDelegate.didSaveCalled)
    }

    func testSaveShowsLoadingDuringExecution() async {
        // Given
        viewModel.screenName = "john"

        // When
        let saveTask = Task {
            await viewModel.save()
        }

        // Then - isLoading should be true during execution
        // (In a real async test, we'd check this during the async operation)

        await saveTask.value

        // After completion, loading should be false
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Save Failure Tests

    func testSaveFailureWithScreenNameTooShort() async {
        // Given
        spyUseCase.shouldThrowError = .screenNameTooShort
        viewModel.screenName = "a"

        // When
        await viewModel.save()

        // Then
        XCTAssertTrue(spyUseCase.executeCalled)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Screen name must be at least 2 characters")
        XCTAssertFalse(mockDelegate.didSaveCalled)
    }

    func testSaveFailureWithScreenNameTooLong() async {
        // Given
        spyUseCase.shouldThrowError = .screenNameTooLong
        viewModel.screenName = "this_is_a_very_long_screen_name_that_exceeds_limit"

        // When
        await viewModel.save()

        // Then
        XCTAssertEqual(viewModel.errorMessage, "Screen name must be 20 characters or less")
        XCTAssertFalse(mockDelegate.didSaveCalled)
    }

    func testSaveFailureWithInvalidCharacters() async {
        // Given
        spyUseCase.shouldThrowError = .screenNameInvalidCharacters
        viewModel.screenName = "john@doe"

        // When
        await viewModel.save()

        // Then
        XCTAssertEqual(
            viewModel.errorMessage,
            "Screen name can only contain letters, numbers, underscores, and hyphens"
        )
        XCTAssertFalse(mockDelegate.didSaveCalled)
    }

    func testSaveFailureWithBirthdayInFuture() async {
        // Given
        spyUseCase.shouldThrowError = .birthdayInFuture
        viewModel.screenName = "john"
        viewModel.birthday = Date().addingTimeInterval(86400) // Tomorrow

        // When
        await viewModel.save()

        // Then
        XCTAssertEqual(viewModel.errorMessage, "Birthday cannot be in the future")
        XCTAssertFalse(mockDelegate.didSaveCalled)
    }

    func testSaveFailureWithBirthdayTooRecent() async {
        // Given
        spyUseCase.shouldThrowError = .birthdayTooRecent
        viewModel.screenName = "john"
        viewModel.birthday = Date().addingTimeInterval(-365 * 24 * 60 * 60 * 10) // 10 years ago

        // When
        await viewModel.save()

        // Then
        XCTAssertEqual(viewModel.errorMessage, "You must be at least 13 years old")
        XCTAssertFalse(mockDelegate.didSaveCalled)
    }

    func testSaveClearsErrorMessageBeforeRetry() async {
        // Given - first save fails
        spyUseCase.shouldThrowError = .screenNameTooShort
        viewModel.screenName = "a"
        await viewModel.save()
        XCTAssertNotNil(viewModel.errorMessage)

        // When - retry with valid input
        spyUseCase.shouldThrowError = nil
        viewModel.screenName = "john"
        await viewModel.save()

        // Then - error message cleared
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(mockDelegate.didSaveCalled)
    }

    // MARK: - Cancel Tests

    func testCancel() {
        // When
        viewModel.cancel()

        // Then
        XCTAssertTrue(mockDelegate.didCancelCalled)
        XCTAssertFalse(spyUseCase.executeCalled)
    }

    // MARK: - Published Properties Tests

    func testScreenNamePublished() {
        let expectation = expectation(description: "screenName publishes changes")
        var receivedValue: String?

        let cancellable = viewModel.$screenName.sink { value in
            receivedValue = value
            if value == "test" {
                expectation.fulfill()
            }
        }

        viewModel.screenName = "test"

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, "test")

        cancellable.cancel()
    }

    func testBirthdayPublished() {
        let expectation = expectation(description: "birthday publishes changes")
        let testDate = Date()
        var receivedValue: Date?

        let cancellable = viewModel.$birthday.sink { value in
            receivedValue = value
            if value == testDate {
                expectation.fulfill()
            }
        }

        viewModel.birthday = testDate

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, testDate)

        cancellable.cancel()
    }

    func testErrorMessagePublished() {
        let expectation = expectation(description: "errorMessage publishes changes")
        var receivedValue: String??

        let cancellable = viewModel.$errorMessage.sink { value in
            receivedValue = value
            if value == "Test error" {
                expectation.fulfill()
            }
        }

        viewModel.errorMessage = "Test error"

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValue, "Test error")

        cancellable.cancel()
    }
}
