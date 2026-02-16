//
//  FieldValidatorTests.swift
//  ShellTests
//
//  Created by Shell on 2026-02-01.
//

import XCTest
@testable import Shell

final class FieldValidatorTests: XCTestCase {
    @MainActor
    func testInitialState() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(initialValue: "", validator: validator)

        XCTAssertEqual(field.value, "")
        XCTAssertNil(field.errorMessage)
        XCTAssertFalse(field.isTouched)
        XCTAssertFalse(field.isDirty)
        XCTAssertTrue(field.isValid)
    }

    @MainActor
    func testValueChangeMarksFieldDirty() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(initialValue: "", validator: validator)

        field.value = "hello"

        XCTAssertTrue(field.isDirty)
    }

    @MainActor
    func testTouchMarksFieldTouched() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(initialValue: "", validator: validator)

        field.touch()

        XCTAssertTrue(field.isTouched)
    }

    @MainActor
    func testValidateOnChangeValidatesAutomatically() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(
            initialValue: "",
            validator: validator,
            validateOnChange: true
        )

        field.value = "h" // Too short

        XCTAssertFalse(field.isValid)
        XCTAssertNotNil(field.errorMessage)
    }

    @MainActor
    func testValidateOnChangeFalseRequiresManualValidation() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(
            initialValue: "",
            validator: validator,
            validateOnChange: false
        )

        field.value = "h" // Too short

        // Should still be valid until we call validate()
        XCTAssertTrue(field.isValid)
        XCTAssertNil(field.errorMessage)

        // Now validate manually
        let result = field.validate()

        XCTAssertFalse(result)
        XCTAssertFalse(field.isValid)
        XCTAssertNotNil(field.errorMessage)
    }

    @MainActor
    func testErrorMapperCustomizesErrorMessages() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(
            initialValue: "",
            validator: validator
        ) { _ in
                return "Custom error message"
        }

        field.value = "h" // Too short

        XCTAssertEqual(field.errorMessage, "Custom error message")
    }

    @MainActor
    func testResetClearsAllState() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(initialValue: "", validator: validator)

        field.value = "h"
        field.touch()

        field.reset(to: "hello")

        XCTAssertEqual(field.value, "hello")
        XCTAssertNil(field.errorMessage)
        XCTAssertFalse(field.isTouched)
        XCTAssertFalse(field.isDirty)
        XCTAssertTrue(field.isValid)
    }

    @MainActor
    func testValidatedValueReturnsNilWhenInvalid() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(initialValue: "h", validator: validator)

        XCTAssertNil(field.validatedValue)
    }

    @MainActor
    func testValidatedValueReturnsValueWhenValid() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(initialValue: "hello", validator: validator)

        XCTAssertEqual(field.validatedValue, "hello")
    }

    @MainActor
    func testComposedValidatorInField() async throws {
        let lengthValidator = StringLengthValidator(minimum: 3, maximum: 10)
        let characterValidator = CharacterSetValidator(allowedCharacters: .alphanumerics)
        let composedValidator = lengthValidator.and(characterValidator)

        let field = FieldValidator(initialValue: "", validator: composedValidator)

        field.value = "ab" // Too short
        XCTAssertFalse(field.isValid)

        field.value = "abc_123" // Invalid characters
        XCTAssertFalse(field.isValid)

        field.value = "abc123" // Valid
        XCTAssertTrue(field.isValid)
    }

    @MainActor
    func testValidFieldClearsErrorMessage() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(initialValue: "h", validator: validator)

        // Field starts invalid
        XCTAssertFalse(field.isValid)
        XCTAssertNotNil(field.errorMessage)

        // Make it valid
        field.value = "hello"

        // Error message should be cleared
        XCTAssertTrue(field.isValid)
        XCTAssertNil(field.errorMessage)
    }

    @MainActor
    func testTouchWithValidateOnChangeFalseTriggersValidation() async throws {
        let validator = StringLengthValidator(minimum: 2, maximum: 10)
        let field = FieldValidator(
            initialValue: "h",
            validator: validator,
            validateOnChange: false
        )

        // Should start as valid (no validation yet)
        XCTAssertTrue(field.isValid)
        XCTAssertNil(field.errorMessage)

        // Touch should trigger validation
        field.touch()

        XCTAssertTrue(field.isTouched)
        XCTAssertFalse(field.isValid)
        XCTAssertNotNil(field.errorMessage)
    }
}
