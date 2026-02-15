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
    private var loginUseCase: MockLoginUseCase!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        validateCredentials = MockValidateCredentialsUseCase()
        loginUseCase = MockLoginUseCase()
        sut = LoginViewModel(
            validateCredentials: validateCredentials,
            login: loginUseCase
        )
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        validateCredentials = nil
        loginUseCase = nil
        super.tearDown()
    }

    private func awaitLoginFlow() async {
        await Task.yield()
        await Task.yield()
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

    func testLogin_withValidCredentials_callsDelegate() async {
        // Given
        let delegate = MockLoginViewModelDelegate()
        sut.delegate = delegate
        sut.username = "testuser"
        sut.password = "password123"
        validateCredentials.resultToReturn = .success(())
        loginUseCase.sessionToReturn = UserSession(
            userId: "testuser",
            accessToken: "access123",
            refreshToken: "refresh123",
            expiresAt: Date().addingTimeInterval(900)
        )
        let expectation = expectation(description: "Delegate called")
        delegate.onSuccess = {
            expectation.fulfill()
        }

        // When
        sut.login()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(delegate.didCallSuccess)
        XCTAssertEqual(delegate.successUsername, "testuser")
        XCTAssertNil(sut.errorMessage)
    }

    func testLogin_withValidCredentials_clearsErrorMessage() async {
        // Given
        sut.username = "testuser"
        sut.password = "password123"
        sut.errorMessage = "Previous error"
        validateCredentials.resultToReturn = .success(())
        loginUseCase.sessionToReturn = UserSession(
            userId: "testuser",
            accessToken: "access123",
            refreshToken: "refresh123",
            expiresAt: Date().addingTimeInterval(900)
        )

        // When
        sut.login()
        await awaitLoginFlow()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    func testLogin_withValidCredentials_callsLoginUseCase() async {
        // Given
        sut.username = "testuser@example.com"
        sut.password = "password123"
        validateCredentials.resultToReturn = .success(())
        loginUseCase.sessionToReturn = UserSession(
            userId: "testuser",
            accessToken: "access123",
            refreshToken: "refresh123",
            expiresAt: Date().addingTimeInterval(900)
        )

        // When
        sut.login()
        await awaitLoginFlow()

        // Then
        XCTAssertEqual(loginUseCase.executeCallCount, 1)
        XCTAssertEqual(loginUseCase.lastEmail, "testuser@example.com")
        XCTAssertEqual(loginUseCase.lastPassword, "password123")
    }

    // MARK: - Login Failure Tests

    func testLogin_withMissingUsername_setsErrorMessage() async {
        // Given
        sut.username = ""
        sut.password = "password123"
        validateCredentials.resultToReturn = .failure(.missingUsername)

        // When
        sut.login()
        await awaitLoginFlow()

        // Then
        XCTAssertEqual(sut.errorMessage, "Please enter a username")
    }

    func testLogin_withShortUsername_setsErrorMessage() async {
        // Given
        sut.username = "ab"
        sut.password = "password123"
        validateCredentials.resultToReturn = .failure(.usernameTooShort(minimumLength: 3))

        // When
        sut.login()
        await awaitLoginFlow()

        // Then
        XCTAssertEqual(sut.errorMessage, "Username must be at least 3 characters")
    }

    func testLogin_withMissingPassword_setsErrorMessage() async {
        // Given
        sut.username = "testuser"
        sut.password = ""
        validateCredentials.resultToReturn = .failure(.missingPassword)

        // When
        sut.login()
        await awaitLoginFlow()

        // Then
        XCTAssertEqual(sut.errorMessage, "Please enter a password")
    }

    func testLogin_withShortPassword_setsErrorMessage() async {
        // Given
        sut.username = "testuser"
        sut.password = "pass1"
        validateCredentials.resultToReturn = .failure(.passwordTooShort(minimumLength: 6))

        // When
        sut.login()
        await awaitLoginFlow()

        // Then
        XCTAssertEqual(sut.errorMessage, "Password must be at least 6 characters")
    }

    func testLogin_withValidationError_doesNotCallDelegate() async {
        // Given
        let delegate = MockLoginViewModelDelegate()
        sut.delegate = delegate
        sut.username = ""
        sut.password = "password123"
        validateCredentials.resultToReturn = .failure(.missingUsername)

        // When
        sut.login()
        await awaitLoginFlow()

        // Then
        XCTAssertFalse(delegate.didCallSuccess)
    }

    func testLogin_whenLoginUseCaseFails_setsErrorAndDoesNotCallDelegate() async {
        // Given
        let delegate = MockLoginViewModelDelegate()
        sut.delegate = delegate
        sut.username = "testuser"
        sut.password = "password123"
        validateCredentials.resultToReturn = .success(())
        loginUseCase.errorToThrow = AuthError.invalidCredentials

        // When
        sut.login()
        await awaitLoginFlow()

        // Then
        XCTAssertEqual(loginUseCase.executeCallCount, 1)
        XCTAssertEqual(sut.errorMessage, "Invalid username or password")
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

    func testErrorMessagePublisher_publishesChanges() async {
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
        await awaitLoginFlow()

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
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

// MARK: - Mock LoginUseCase

private final class MockLoginUseCase: LoginUseCase {
    var executeCallCount = 0
    var lastEmail: String?
    var lastPassword: String?
    var sessionToReturn: UserSession?
    var errorToThrow: Error?

    func execute(email: String, password: String) async throws -> UserSession {
        executeCallCount += 1
        lastEmail = email
        lastPassword = password

        if let error = errorToThrow {
            throw error
        }

        guard let session = sessionToReturn else {
            throw AuthError.invalidCredentials
        }

        return session
    }
}

private enum SessionError: Error {
    case failed
}

private final class MockSessionRepository: SessionRepository {
    private(set) var saveSessionCallCount = 0
    private(set) var savedSession: UserSession?
    var saveError: Error?

    func getCurrentSession() async throws -> UserSession? {
        savedSession
    }

    func saveSession(_ session: UserSession) async throws {
        saveSessionCallCount += 1
        if let saveError {
            throw saveError
        }
        savedSession = session
    }

    func clearSession() async throws {
        savedSession = nil
    }
}

// MARK: - Mock LoginViewModelDelegate

private class MockLoginViewModelDelegate: LoginViewModelDelegate {
    var didCallSuccess = false
    var successUsername: String?
    var onSuccess: (() -> Void)?

    func loginViewModelDidSucceed(_ viewModel: LoginViewModel, username: String) {
        didCallSuccess = true
        successUsername = username
        onSuccess?()
    }
}
