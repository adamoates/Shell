//
//  ValidatorTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-31.
//

import XCTest
@testable import Shell

final class StringLengthValidatorTests: XCTestCase {
    func testValidString() {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)

        let result = validator.validate("hello")

        XCTAssertEqual(try? result.get(), "hello")
    }

    func testEmptyString() {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)

        let result = validator.validate("")

        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? StringLengthValidator.Error, .empty)
        }
    }

    func testWhitespaceOnlyString() {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)

        let result = validator.validate("   ")

        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? StringLengthValidator.Error, .empty)
        }
    }

    func testStringTooShort() {
        let validator = StringLengthValidator(minimum: 5, maximum: 10)

        let result = validator.validate("hi")

        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? StringLengthValidator.Error, .tooShort(minimum: 5))
        }
    }

    func testStringTooLong() {
        let validator = StringLengthValidator(minimum: 2, maximum: 5)

        let result = validator.validate("toolong")

        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? StringLengthValidator.Error, .tooLong(maximum: 5))
        }
    }

    func testStringTrimming() {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)

        let result = validator.validate("  hello  ")

        // Should trim and validate
        XCTAssertEqual(try? result.get(), "hello")
    }
}

final class RegexValidatorTests: XCTestCase {
    func testEmailPattern() {
        let validator = RegexValidator(pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$", options: .caseInsensitive)

        let validResult = validator.validate("test@example.com")
        let invalidResult = validator.validate("not-an-email")

        XCTAssertEqual(try? validResult.get(), "test@example.com")
        XCTAssertThrowsError(try invalidResult.get())
    }

    func testNumericPattern() {
        let validator = RegexValidator(pattern: "^\\d+$")

        let validResult = validator.validate("12345")
        let invalidResult = validator.validate("123abc")

        XCTAssertEqual(try? validResult.get(), "12345")
        XCTAssertThrowsError(try invalidResult.get())
    }
}

final class CharacterSetValidatorTests: XCTestCase {
    func testAlphanumericOnly() {
        let validator = CharacterSetValidator(allowedCharacters: .alphanumerics)

        let validResult = validator.validate("abc123")
        let invalidResult = validator.validate("abc_123")

        XCTAssertEqual(try? validResult.get(), "abc123")
        XCTAssertThrowsError(try invalidResult.get())
    }

    func testAlphanumericWithUnderscore() {
        let allowedChars = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        let validator = CharacterSetValidator(allowedCharacters: allowedChars)

        let validResult = validator.validate("user_name-123")
        let invalidResult = validator.validate("user@name")

        XCTAssertEqual(try? validResult.get(), "user_name-123")
        XCTAssertThrowsError(try invalidResult.get())
    }
}

final class RangeValidatorTests: XCTestCase {
    func testIntegerRange() {
        let validator = RangeValidator(minimum: 0, maximum: 100)

        let validResult = validator.validate(50)
        let tooSmallResult = validator.validate(-1)
        let tooLargeResult = validator.validate(101)

        XCTAssertEqual(try? validResult.get(), 50)
        XCTAssertThrowsError(try tooSmallResult.get()) { error in
            XCTAssertEqual(error as? RangeValidator<Int>.Error, .lessThanMinimum)
        }
        XCTAssertThrowsError(try tooLargeResult.get()) { error in
            XCTAssertEqual(error as? RangeValidator<Int>.Error, .greaterThanMaximum)
        }
    }

    func testDoubleRange() {
        let validator = RangeValidator(minimum: 0.0, maximum: 1.0)

        let validResult = validator.validate(0.5)
        let tooSmallResult = validator.validate(-0.1)
        let tooLargeResult = validator.validate(1.1)

        XCTAssertEqual(try? validResult.get(), 0.5)
        XCTAssertThrowsError(try tooSmallResult.get())
        XCTAssertThrowsError(try tooLargeResult.get())
    }

    func testMinimumOnly() {
        let validator = RangeValidator<Int>(minimum: 10)

        let validResult = validator.validate(100)
        let invalidResult = validator.validate(5)

        XCTAssertEqual(try? validResult.get(), 100)
        XCTAssertThrowsError(try invalidResult.get())
    }

    func testMaximumOnly() {
        let validator = RangeValidator<Int>(maximum: 100)

        let validResult = validator.validate(50)
        let invalidResult = validator.validate(150)

        XCTAssertEqual(try? validResult.get(), 50)
        XCTAssertThrowsError(try invalidResult.get())
    }
}

final class DateAgeValidatorTests: XCTestCase {
    func testValidAge() {
        let validator = DateAgeValidator(minimumAge: 18, maximumAge: 120)

        // Create a date for someone who is 25 years old
        let calendar = Calendar.current
        let birthdate = calendar.date(byAdding: .year, value: -25, to: Date())!

        let result = validator.validate(birthdate)

        XCTAssertEqual(try? result.get(), birthdate)
    }

    func testFutureDate() {
        let validator = DateAgeValidator(minimumAge: 18)

        let futureDate = Date().addingTimeInterval(86400) // Tomorrow

        let result = validator.validate(futureDate)

        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? DateAgeValidator.Error, .inFuture)
        }
    }

    func testTooYoung() {
        let validator = DateAgeValidator(minimumAge: 18)

        // 10 years old
        let calendar = Calendar.current
        let birthdate = calendar.date(byAdding: .year, value: -10, to: Date())!

        let result = validator.validate(birthdate)

        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? DateAgeValidator.Error, .tooYoung(minimumAge: 18))
        }
    }

    func testTooOld() {
        let validator = DateAgeValidator(minimumAge: 13, maximumAge: 120)

        // 130 years old
        let calendar = Calendar.current
        let birthdate = calendar.date(byAdding: .year, value: -130, to: Date())!

        let result = validator.validate(birthdate)

        XCTAssertThrowsError(try result.get()) { error in
            XCTAssertEqual(error as? DateAgeValidator.Error, .tooOld(maximumAge: 120))
        }
    }
}

final class ComposedValidatorTests: XCTestCase {
    func testValidatorComposition() {
        // Create composed validator: length AND alphanumeric
        let lengthValidator = StringLengthValidator(minimum: 3, maximum: 20)
        let characterValidator = CharacterSetValidator(allowedCharacters: .alphanumerics)

        let composedValidator = lengthValidator.and(characterValidator)

        // Valid: passes both
        let validResult = composedValidator.validate("user123")
        XCTAssertEqual(try? validResult.get(), "user123")

        // Invalid: fails length check
        let tooShortResult = composedValidator.validate("ab")
        XCTAssertThrowsError(try tooShortResult.get()) { error in
            XCTAssertTrue(error is AnyValidationError)
        }

        // Invalid: fails character check
        let invalidCharsResult = composedValidator.validate("user_123")
        XCTAssertThrowsError(try invalidCharsResult.get()) { error in
            XCTAssertTrue(error is AnyValidationError)
        }
    }

    func testShortCircuitEvaluation() {
        // If first validator fails, second should not be called
        let lengthValidator = StringLengthValidator(minimum: 5, maximum: 20)
        let characterValidator = CharacterSetValidator(allowedCharacters: .alphanumerics)

        let composedValidator = lengthValidator.and(characterValidator)

        // This fails length first (too short), so character validation is skipped
        let result = composedValidator.validate("ab")

        XCTAssertThrowsError(try result.get()) { error in
            // Should be AnyValidationError (short-circuits on first failure)
            XCTAssertTrue(error is AnyValidationError)
        }
    }

    func testMultipleComposition() {
        // Chain multiple validators
        let lengthValidator = StringLengthValidator(minimum: 3, maximum: 20)
        let characterValidator = CharacterSetValidator(allowedCharacters: .alphanumerics)
        let regexValidator = RegexValidator(pattern: "^[a-z]+$", options: [])

        let composedValidator = lengthValidator
            .and(characterValidator)
            .and(regexValidator)

        // Valid
        let validResult = composedValidator.validate("hello")
        XCTAssertEqual(try? validResult.get(), "hello")

        // Invalid: has uppercase
        let invalidResult = composedValidator.validate("Hello")
        XCTAssertThrowsError(try invalidResult.get()) { error in
            XCTAssertTrue(error is AnyValidationError)
        }
    }
}
