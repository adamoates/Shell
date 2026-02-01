//
//  ValidateCredentialsUseCaseTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

final class ValidateCredentialsUseCaseTests: XCTestCase {

    private var sut: ValidateCredentialsUseCase!

    override func setUp() {
        super.setUp()
        sut = DefaultValidateCredentialsUseCase()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Success Cases

    func testExecute_withValidCredentials_returnsSuccess() {
        // Given
        let credentials = Credentials(username: "testuser", password: "password123")

        // When
        let result = sut.execute(credentials: credentials)

        // Then
        switch result {
        case .success:
            XCTAssertTrue(true, "Valid credentials should succeed")
        case .failure:
            XCTFail("Valid credentials should not fail")
        }
    }

    func testExecute_withMinimumValidUsername_returnsSuccess() {
        // Given - username exactly at minimum length (3 characters)
        let credentials = Credentials(username: "abc", password: "password123")

        // When
        let result = sut.execute(credentials: credentials)

        // Then
        switch result {
        case .success:
            XCTAssertTrue(true, "Username at minimum length should succeed")
        case .failure:
            XCTFail("Username at minimum length should not fail")
        }
    }

    func testExecute_withMinimumValidPassword_returnsSuccess() {
        // Given - password exactly at minimum length (6 characters)
        let credentials = Credentials(username: "testuser", password: "pass12")

        // When
        let result = sut.execute(credentials: credentials)

        // Then
        switch result {
        case .success:
            XCTAssertTrue(true, "Password at minimum length should succeed")
        case .failure:
            XCTFail("Password at minimum length should not fail")
        }
    }

    // MARK: - Username Validation Failures

    func testExecute_withEmptyUsername_returnsMissingUsernameError() {
        // Given
        let credentials = Credentials(username: "", password: "password123")

        // When
        let result = sut.execute(credentials: credentials)

        // Then
        switch result {
        case .success:
            XCTFail("Empty username should fail")
        case .failure(let error):
            XCTAssertEqual(error, .missingUsername)
            XCTAssertEqual(error.userMessage, "Please enter a username")
        }
    }

    func testExecute_withUsernameTooShort_returnsUsernameTooShortError() {
        // Given - username below minimum length (2 characters when minimum is 3)
        let credentials = Credentials(username: "ab", password: "password123")

        // When
        let result = sut.execute(credentials: credentials)

        // Then
        switch result {
        case .success:
            XCTFail("Short username should fail")
        case .failure(let error):
            XCTAssertEqual(error, .usernameTooShort(minimumLength: 3))
            XCTAssertEqual(error.userMessage, "Username must be at least 3 characters")
        }
    }

    // MARK: - Password Validation Failures

    func testExecute_withEmptyPassword_returnsMissingPasswordError() {
        // Given
        let credentials = Credentials(username: "testuser", password: "")

        // When
        let result = sut.execute(credentials: credentials)

        // Then
        switch result {
        case .success:
            XCTFail("Empty password should fail")
        case .failure(let error):
            XCTAssertEqual(error, .missingPassword)
            XCTAssertEqual(error.userMessage, "Please enter a password")
        }
    }

    func testExecute_withPasswordTooShort_returnsPasswordTooShortError() {
        // Given - password below minimum length (5 characters when minimum is 6)
        let credentials = Credentials(username: "testuser", password: "pass1")

        // When
        let result = sut.execute(credentials: credentials)

        // Then
        switch result {
        case .success:
            XCTFail("Short password should fail")
        case .failure(let error):
            XCTAssertEqual(error, .passwordTooShort(minimumLength: 6))
            XCTAssertEqual(error.userMessage, "Password must be at least 6 characters")
        }
    }

    // MARK: - Priority Tests (Username checked before Password)

    func testExecute_withBothEmpty_returnsMissingUsernameError() {
        // Given - both username and password empty
        let credentials = Credentials(username: "", password: "")

        // When
        let result = sut.execute(credentials: credentials)

        // Then - Username validation should happen first
        switch result {
        case .success:
            XCTFail("Empty credentials should fail")
        case .failure(let error):
            XCTAssertEqual(error, .missingUsername)
        }
    }

    func testExecute_withShortUsernameAndShortPassword_returnsUsernameTooShortError() {
        // Given - both username and password too short
        let credentials = Credentials(username: "ab", password: "pass1")

        // When
        let result = sut.execute(credentials: credentials)

        // Then - Username validation should happen first
        switch result {
        case .success:
            XCTFail("Short credentials should fail")
        case .failure(let error):
            XCTAssertEqual(error, .usernameTooShort(minimumLength: 3))
        }
    }
}
