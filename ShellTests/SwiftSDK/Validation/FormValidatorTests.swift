//
//  FormValidatorTests.swift
//  ShellTests
//
//  Created by Shell on 2026-02-01.
//

import XCTest
@testable import Shell

final class FormValidatorTests: XCTestCase {
    @MainActor
    func testFormValidWhenAllFieldsValid() async throws {
        let formValidator = FormValidator()

        let field1 = FieldValidator(
            initialValue: "hello",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )
        let field2 = FieldValidator(
            initialValue: "world",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )

        formValidator.register(field1)
        formValidator.register(field2)

        XCTAssertTrue(formValidator.isFormValid)
    }

    @MainActor
    func testFormInvalidWhenAnyFieldInvalid() async throws {
        let formValidator = FormValidator()

        let field1 = FieldValidator(
            initialValue: "hello",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )
        let field2 = FieldValidator(
            initialValue: "x", // Too short
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )

        formValidator.register(field1)
        formValidator.register(field2)

        XCTAssertFalse(formValidator.isFormValid)
    }

    @MainActor
    func testValidateAllValidatesAllFields() async throws {
        let formValidator = FormValidator()

        let field1 = FieldValidator(
            initialValue: "x",
            validator: StringLengthValidator(minimum: 2, maximum: 10),
            validateOnChange: false
        )
        let field2 = FieldValidator(
            initialValue: "y",
            validator: StringLengthValidator(minimum: 2, maximum: 10),
            validateOnChange: false
        )

        formValidator.register(field1)
        formValidator.register(field2)

        let result = formValidator.validateAll()

        XCTAssertFalse(result)
        XCTAssertFalse(formValidator.isFormValid)
        XCTAssertFalse(field1.isValid)
        XCTAssertFalse(field2.isValid)
    }

    @MainActor
    func testValidateAllReturnsTrueWhenAllFieldsValid() async throws {
        let formValidator = FormValidator()

        let field1 = FieldValidator(
            initialValue: "hello",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )
        let field2 = FieldValidator(
            initialValue: "world",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )

        formValidator.register(field1)
        formValidator.register(field2)

        let result = formValidator.validateAll()

        XCTAssertTrue(result)
        XCTAssertTrue(formValidator.isFormValid)
    }

    @MainActor
    func testHasInteractionWhenAnyFieldTouched() async throws {
        let formValidator = FormValidator()

        let field1 = FieldValidator(
            initialValue: "hello",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )
        let field2 = FieldValidator(
            initialValue: "world",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )

        formValidator.register(field1)
        formValidator.register(field2)

        XCTAssertFalse(formValidator.hasInteraction)

        field1.touch()

        XCTAssertTrue(formValidator.hasInteraction)
    }

    @MainActor
    func testIsDirtyWhenAnyFieldDirty() async throws {
        let formValidator = FormValidator()

        let field1 = FieldValidator(
            initialValue: "hello",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )
        let field2 = FieldValidator(
            initialValue: "world",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )

        formValidator.register(field1)
        formValidator.register(field2)

        XCTAssertFalse(formValidator.isDirty)

        field1.value = "hi"

        XCTAssertTrue(formValidator.isDirty)
    }

    @MainActor
    func testTouchAllTouchesAllFields() async throws {
        let formValidator = FormValidator()

        let field1 = FieldValidator(
            initialValue: "hello",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )
        let field2 = FieldValidator(
            initialValue: "world",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )

        formValidator.register(field1)
        formValidator.register(field2)

        XCTAssertFalse(field1.isTouched)
        XCTAssertFalse(field2.isTouched)

        formValidator.touchAll()

        XCTAssertTrue(field1.isTouched)
        XCTAssertTrue(field2.isTouched)
        XCTAssertTrue(formValidator.hasInteraction)
    }

    @MainActor
    func testFormValidityUpdatesWhenFieldValueChanges() async throws {
        let formValidator = FormValidator()

        let field1 = FieldValidator(
            initialValue: "hello",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )
        let field2 = FieldValidator(
            initialValue: "world",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )

        formValidator.register(field1)
        formValidator.register(field2)

        XCTAssertTrue(formValidator.isFormValid)

        // Change field1 to invalid value
        field1.value = "x" // Too short

        XCTAssertFalse(formValidator.isFormValid)

        // Change field1 back to valid value
        field1.value = "hello"

        XCTAssertTrue(formValidator.isFormValid)
    }
}
