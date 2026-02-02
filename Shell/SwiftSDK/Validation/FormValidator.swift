//
//  FormValidator.swift
//  Shell
//
//  Created by Shell on 2026-02-01.
//

import Foundation

/// Coordinates validation for multiple form fields
/// Provides:
/// - Form-level validation state
/// - Orchestration of multiple FieldValidators
/// - Submit button enable/disable logic
@MainActor
final class FormValidator {
    private(set) var isFormValid: Bool = false
    private(set) var hasInteraction: Bool = false
    private(set) var isDirty: Bool = false

    private var fieldValidators: [any FieldValidatorProtocol] = []

    func register<Value>(_ field: FieldValidator<Value>) {
        fieldValidators.append(field)
        updateFormState()
    }

    @discardableResult
    func validateAll() -> Bool {
        let results = fieldValidators.map { $0.validate() }
        updateFormState()
        return results.allSatisfy { $0 }
    }

    func touchAll() {
        fieldValidators.forEach { $0.touch() }
        updateFormState()
    }

    func updateFormState() {
        isFormValid = fieldValidators.allSatisfy { $0.isValid }
        hasInteraction = fieldValidators.contains { $0.isTouched }
        isDirty = fieldValidators.contains { $0.isDirty }
    }
}

@MainActor
protocol FieldValidatorProtocol: AnyObject {
    var isValid: Bool { get }
    var isTouched: Bool { get }
    var isDirty: Bool { get }

    func validate() -> Bool
    func touch()
}

extension FieldValidator: FieldValidatorProtocol {}
