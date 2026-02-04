//
//  FormValidatorTests.swift
//  ShellTests
//
//  Created by Shell on 2026-02-01.
//

import XCTest
@testable import Shell

@MainActor
final class FormValidatorTests: XCTestCase {

    func testFormValidWhenAllFieldsValid() {
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

    func testFormInvalidWhenAnyFieldInvalid() {
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

    func testValidateAllValidatesAllFields() {
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
        XCTAssertFalse(field1.isValid)
        XCTAssertFalse(field2.isValid)
    }

    func testTouchAllTouchesAllFields() {
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

        formValidator.touchAll()

        XCTAssertTrue(field1.isTouched)
        XCTAssertTrue(field2.isTouched)
    }

    func testHasInteractionWhenAnyFieldTouched() {
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

    func testIsDirtyWhenAnyFieldDirty() {
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

        field1.value = "modified"

        XCTAssertTrue(formValidator.isDirty)
    }

    func testFormValidityUpdatesWhenFieldValueChanges() {
        let formValidator = FormValidator()

        let field1 = FieldValidator(
            initialValue: "hello",
            validator: StringLengthValidator(minimum: 2, maximum: 10)
        )

        formValidator.register(field1)

        XCTAssertTrue(formValidator.isFormValid)

        // Make field invalid
        field1.value = "x"

        XCTAssertFalse(formValidator.isFormValid)

        // Make field valid again
        field1.value = "hello"

        XCTAssertTrue(formValidator.isFormValid)
    }

    func testValidateAllReturnsTrueWhenAllFieldsValid() {
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
    }
}
