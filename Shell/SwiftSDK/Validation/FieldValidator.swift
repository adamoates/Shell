//
//  FieldValidator.swift
//  Shell
//
//  Created by Shell on 2026-02-01.
//

import Foundation

/// Validation state for a single form field
/// Provides:
/// - Real-time validation feedback
/// - Form state tracking (touched, dirty, valid)
/// - Error message display
@MainActor
final class FieldValidator<Value: Equatable> {
    // MARK: - Published State

    var value: Value {
        didSet {
            if value != oldValue {
                isDirty = true
                if validateOnChange {
                    validate()
                }
            }
        }
    }

    private(set) var errorMessage: String?
    private(set) var isTouched: Bool = false
    private(set) var isDirty: Bool = false
    private(set) var isValid: Bool = true

    // MARK: - Properties

    private let validator: AnyValidator<Value>
    private let validateOnChange: Bool
    private let errorMapper: ((AnyValidationError) -> String)?

    // MARK: - Initialization

    init<V: Validator>(
        initialValue: Value,
        validator: V,
        validateOnChange: Bool = true,
        errorMapper: ((AnyValidationError) -> String)? = nil
    ) where V.Value == Value {
        self.value = initialValue
        self.validator = validator.eraseToAnyValidator()
        self.validateOnChange = validateOnChange
        self.errorMapper = errorMapper
    }

    // MARK: - Actions

    func touch() {
        isTouched = true
        if !validateOnChange {
            validate()
        }
    }

    @discardableResult
    func validate() -> Bool {
        let result = validator.validate(value)

        switch result {
        case .success:
            errorMessage = nil
            isValid = true
            return true
        case .failure(let error):
            if let mapper = errorMapper {
                errorMessage = mapper(error)
            } else {
                errorMessage = error.localizedDescription
            }
            isValid = false
            return false
        }
    }

    func reset(to newValue: Value) {
        value = newValue
        errorMessage = nil
        isTouched = false
        isDirty = false
        isValid = true
    }

    var validatedValue: Value? {
        guard validate() else { return nil }
        return value
    }
}
