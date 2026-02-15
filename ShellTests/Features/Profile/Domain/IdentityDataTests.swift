//
//  IdentityDataTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for IdentityData domain model and validation
final class IdentityDataTests: XCTestCase {
    // MARK: - Screen Name Validation Tests

    func testValidateScreenName_validName_succeeds() {
        let result = IdentityData.validateScreenName("valid_user123")

        XCTAssertTrue(result.isSuccess)
        if case .success(let screenName) = result {
            XCTAssertEqual(screenName, "valid_user123")
        }
    }

    func testValidateScreenName_tooShort_fails() {
        let result = IdentityData.validateScreenName("a")

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, .screenNameTooShort)
        }
    }

    func testValidateScreenName_tooLong_fails() {
        let result = IdentityData.validateScreenName("this_is_a_very_long_screen_name_that_exceeds_limit")

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, .screenNameTooLong)
        }
    }

    func testValidateScreenName_invalidCharacters_fails() {
        let result = IdentityData.validateScreenName("invalid@user!")

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, .screenNameInvalidCharacters)
        }
    }

    func testValidateScreenName_trimsWhitespace() {
        let result = IdentityData.validateScreenName("  user123  ")

        XCTAssertTrue(result.isSuccess)
        if case .success(let screenName) = result {
            XCTAssertEqual(screenName, "user123")
        }
    }

    func testValidateScreenName_allowsUnderscore() {
        let result = IdentityData.validateScreenName("user_name")

        XCTAssertTrue(result.isSuccess)
    }

    func testValidateScreenName_allowsHyphen() {
        let result = IdentityData.validateScreenName("user-name")

        XCTAssertTrue(result.isSuccess)
    }

    // MARK: - Birthday Validation Tests

    func testValidateBirthday_validDate_succeeds() {
        let calendar = Calendar.current
        let birthday = calendar.date(byAdding: .year, value: -20, to: Date())!

        let result = IdentityData.validateBirthday(birthday)

        XCTAssertTrue(result.isSuccess)
    }

    func testValidateBirthday_futureDate_fails() {
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .day, value: 1, to: Date())!

        let result = IdentityData.validateBirthday(futureDate)

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, .birthdayInFuture)
        }
    }

    func testValidateBirthday_tooRecent_fails() {
        let calendar = Calendar.current
        let recentDate = calendar.date(byAdding: .year, value: -10, to: Date())!

        let result = IdentityData.validateBirthday(recentDate)

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, .birthdayTooRecent)
        }
    }

    func testValidateBirthday_tooOld_fails() {
        let calendar = Calendar.current
        let veryOldDate = calendar.date(byAdding: .year, value: -130, to: Date())!

        let result = IdentityData.validateBirthday(veryOldDate)

        XCTAssertTrue(result.isFailure)
        if case .failure(let error) = result {
            XCTAssertEqual(error, .birthdayTooOld)
        }
    }

    func testValidateBirthday_exactlyThirteen_succeeds() {
        let calendar = Calendar.current
        let thirteenYearsAgo = calendar.date(byAdding: .year, value: -13, to: Date())!

        let result = IdentityData.validateBirthday(thirteenYearsAgo)

        XCTAssertTrue(result.isSuccess)
    }

    // MARK: - IdentityData Creation Tests

    func testCreate_validData_succeeds() {
        let calendar = Calendar.current
        let birthday = calendar.date(byAdding: .year, value: -20, to: Date())!

        let result = IdentityData.create(screenName: "testuser", birthday: birthday)

        XCTAssertTrue(result.isSuccess)
        if case .success(let identityData) = result {
            XCTAssertEqual(identityData.screenName, "testuser")
            XCTAssertEqual(identityData.birthday, birthday)
        }
    }

    func testCreate_invalidScreenName_fails() {
        let calendar = Calendar.current
        let birthday = calendar.date(byAdding: .year, value: -20, to: Date())!

        let result = IdentityData.create(screenName: "a", birthday: birthday)

        XCTAssertTrue(result.isFailure)
    }

    func testCreate_invalidBirthday_fails() {
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .day, value: 1, to: Date())!

        let result = IdentityData.create(screenName: "testuser", birthday: futureDate)

        XCTAssertTrue(result.isFailure)
    }
}

// MARK: - Result Helper Extensions

private extension Result {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var isFailure: Bool {
        if case .failure = self {
            return true
        }
        return false
    }
}
