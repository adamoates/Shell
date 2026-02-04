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
final class FieldValidator<Value: Equatable> {
    // MARK: - State

    var value: Value {
        didSet {
            if value != oldValue {
                isDirty = true
                if validateOnChange {
                    validate()
                }
                onChange?()
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

    // MARK: - Callback

    var onChange: (() -> Void)?

    // MARK: - Initialization

    init<V: Validator>(
        initialValue: Value,
        validator: V,
        validateOnChange: Bool = true,
        errorMapper: ((AnyValidationError) -> String)? = nil
    ) where V.Value == Value {
        let anyValidator = validator.eraseToAnyValidator()
        self.validator = anyValidator
        self.validateOnChange = validateOnChange
        self.errorMapper = errorMapper
        self.value = initialValue
        self.errorMessage = nil
        self.isTouched = false
        self.isDirty = false

        // Validate initially if validateOnChange is true AND value is non-empty string
        // (This handles the pattern where empty strings are treated as "not yet filled in")
        if validateOnChange, let stringValue = initialValue as? String, !stringValue.isEmpty {
            let result = anyValidator.validate(initialValue)
            switch result {
            case .success:
                self.isValid = true
            case .failure(let error):
                let message: String
                if let mapper = errorMapper {
                    message = mapper(error)
                } else {
                    message = error.localizedDescription
                }
                self.errorMessage = message
                self.isValid = false
            }
        } else {
            self.isValid = true
        }
    }

    // MARK: - Actions

    func touch() {
        isTouched = true
        if !validateOnChange {
            validate()
        }
        onChange?()
    }

    @discardableResult
    func validate() -> Bool {
        let result = validator.validate(value)

        switch result {
        case .success:
            errorMessage = nil
            isValid = true
            onChange?()
            return true
        case .failure(let error):
            if let mapper = errorMapper {
                errorMessage = mapper(error)
            } else {
                errorMessage = error.localizedDescription
            }
            isValid = false
            onChange?()
            return false
        }
    }

    func reset(to newValue: Value) {
        value = newValue
        errorMessage = nil
        isTouched = false
        isDirty = false
        isValid = true
        onChange?()
    }

    var validatedValue: Value? {
        guard validate() else { return nil }
        return value
    }
}
