//
//  RouteParametersTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for RouteParameters implementations
/// Verifies parameter validation logic
final class RouteParametersTests: XCTestCase {

    // MARK: - ProfileParameters Tests

    func testProfileParameters_validUserID_succeeds() {
        let params = ["userID": "user123"]

        let result = ProfileParameters.validate(params)

        switch result {
        case .success(let validatedParams):
            XCTAssertEqual(validatedParams.userID, "user123")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testProfileParameters_missingUserID_fails() {
        let params: [String: String] = [:]

        let result = ProfileParameters.validate(params)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .missingParameter("userID"))
        }
    }

    func testProfileParameters_emptyUserID_fails() {
        let params = ["userID": ""]

        let result = ProfileParameters.validate(params)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .missingParameter("userID"))
        }
    }

    func testProfileParameters_tooShortUserID_fails() {
        let params = ["userID": "ab"] // Less than 3 characters

        let result = ProfileParameters.validate(params)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .invalidParameter("userID", reason: "Must be at least 3 characters"))
        }
    }

    func testProfileParameters_alphanumericUserID_succeeds() {
        let params = ["userID": "user123"]

        let result = ProfileParameters.validate(params)

        switch result {
        case .success(let validatedParams):
            XCTAssertEqual(validatedParams.userID, "user123")
        case .failure:
            XCTFail("Expected success")
        }
    }

    func testProfileParameters_specialCharactersInUserID_fails() {
        let params = ["userID": "user@123"]

        let result = ProfileParameters.validate(params)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .invalidParameter("userID", reason: "Must contain only letters and numbers"))
        }
    }

    func testProfileParameters_spaceInUserID_fails() {
        let params = ["userID": "user 123"]

        let result = ProfileParameters.validate(params)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .invalidParameter("userID", reason: "Must contain only letters and numbers"))
        }
    }

    func testProfileParameters_emojiInUserID_fails() {
        let params = ["userID": "user😀123"]

        let result = ProfileParameters.validate(params)

        switch result {
        case .success:
            XCTFail("Expected failure")
        case .failure(let error):
            XCTAssertEqual(error, .invalidParameter("userID", reason: "Must contain only letters and numbers"))
        }
    }

    // MARK: - RouteError Tests

    func testRouteError_localizedDescription_correctFormat() {
        let missingError = RouteError.missingParameter("userID")
        XCTAssertEqual(missingError.localizedDescription, "Missing required parameter: userID")

        let invalidError = RouteError.invalidParameter("userID", reason: "Too short")
        XCTAssertEqual(invalidError.localizedDescription, "Invalid parameter 'userID': Too short")

        let urlError = RouteError.invalidURL
        XCTAssertEqual(urlError.localizedDescription, "Invalid URL format")
    }
}
