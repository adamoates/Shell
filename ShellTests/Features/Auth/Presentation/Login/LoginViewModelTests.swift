//
//  LoginViewModelTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
import Combine
@testable import Shell

@MainActor
final class LoginViewModelTests: XCTestCase {

    private var sut: LoginViewModel!
    private var validateCredentials: MockValidateCredentialsUseCase!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        validateCredentials = MockValidateCredentialsUseCase()
        sut = LoginViewModel(validateCredentials: validateCredentials)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        validateCredentials = nil
        super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState_hasEmptyUsername() {
        XCTAssertEqual(sut.username, "")
    }

    func testInitialState_hasEmptyPassword() {
        XCTAssertEqual(sut.password, "")
    }

    func testInitialState_hasNoError() {
        XCTAssertNil(sut.errorMessage)
    }

    func testInitialState_isNotLoading() {
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Login Success Tests

    func testLogin_withValidCredentials_callsDelegate() {
        // Given
        let delegate = MockLoginViewModelDelegate()
        sut.delegate = delegate
        sut.username = "testuser"
        sut.password = "password123"
        validateCredentials.resultToReturn = .success(())

        // When
        sut.login()

        // Then
        XCTAssertTrue(delegate.didCallSuccess)
        XCTAssertEqual(delegate.successUsername, "testuser")
        XCTAssertNil(sut.errorMessage)
    }

    func testLogin_withValidCredentials_clearsErrorMessage() {
        // Given
        sut.username = "testuser"
        sut.password = "password123"
        sut.errorMessage = "Previous error"
        validateCredentials.resultToReturn = .success(())

        // When
        sut.login()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Login Failure Tests

    func testLogin_withMissingUsername_setsErrorMessage() {
        // Given
        sut.username = ""
        sut.password = "password123"
        validateCredentials.resultToReturn = .failure(.missingUsername)

        // When
        sut.login()

        // Then
        XCTAssertEqual(sut.errorMessage, "Please enter a username")
    }

    func testLogin_withShortUsername_setsErrorMessage() {
        // Given
        sut.username = "ab"
        sut.password = "password123"
        validateCredentials.resultToReturn = .failure(.usernameTooShort(minimumLength: 3))

        // When
        sut.login()

        // Then
        XCTAssertEqual(sut.errorMessage, "Username must be at least 3 characters")
    }

    func testLogin_withMissingPassword_setsErrorMessage() {
        // Given
        sut.username = "testuser"
        sut.password = ""
        validateCredentials.resultToReturn = .failure(.missingPassword)

        // When
        sut.login()

        // Then
        XCTAssertEqual(sut.errorMessage, "Please enter a password")
    }

    func testLogin_withShortPassword_setsErrorMessage() {
        // Given
        sut.username = "testuser"
        sut.password = "pass1"
        validateCredentials.resultToReturn = .failure(.passwordTooShort(minimumLength: 6))

        // When
        sut.login()

        // Then
        XCTAssertEqual(sut.errorMessage, "Password must be at least 6 characters")
    }

    func testLogin_withValidationError_doesNotCallDelegate() {
        // Given
        let delegate = MockLoginViewModelDelegate()
        sut.delegate = delegate
        sut.username = ""
        sut.password = "password123"
        validateCredentials.resultToReturn = .failure(.missingUsername)

        // When
        sut.login()

        // Then
        XCTAssertFalse(delegate.didCallSuccess)
    }

    // MARK: - Clear Error Tests

    func testClearError_removesErrorMessage() {
        // Given
        sut.errorMessage = "Some error"

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Combine Publisher Tests

    func testErrorMessagePublisher_publishesChanges() {
        // Given
        let expectation = expectation(description: "Error message published")
        var receivedMessage: String?

        sut.$errorMessage
            .dropFirst() // Skip initial nil value
            .compactMap { $0 } // Only capture non-nil values
            .sink { message in
                receivedMessage = message
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.username = ""
        sut.password = "password123"
        validateCredentials.resultToReturn = .failure(.missingUsername)
        sut.login()

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedMessage, "Please enter a username")
    }

    func testErrorMessagePublisher_publishesClear() {
        // Given
        sut.errorMessage = "Some error" // Set initial error
        let expectation = expectation(description: "Error cleared published")
        var receivedMessage: String?

        sut.$errorMessage
            .dropFirst() // Skip initial "Some error" value
            .sink { message in
                receivedMessage = message
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        sut.clearError()

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedMessage)
    }
}

// MARK: - Mock ValidateCredentialsUseCase

private class MockValidateCredentialsUseCase: ValidateCredentialsUseCase {
    var resultToReturn: Result<Void, AuthError> = .success(())
    var executeWasCalled = false
    var lastCredentials: Credentials?

    func execute(credentials: Credentials) -> Result<Void, AuthError> {
        executeWasCalled = true
        lastCredentials = credentials
        return resultToReturn
    }
}

// MARK: - Mock LoginViewModelDelegate

private class MockLoginViewModelDelegate: LoginViewModelDelegate {
    var didCallSuccess = false
    var successUsername: String?

    func loginViewModelDidSucceed(_ viewModel: LoginViewModel, username: String) {
        didCallSuccess = true
        successUsername = username
    }
}
