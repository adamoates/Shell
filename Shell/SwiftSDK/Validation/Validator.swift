//
//  Validator.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation

/// Protocol-oriented validation framework demonstrating:
/// - Protocol-oriented design with associated types
/// - Functional composition (combining validators)
/// - Generic constraints
/// - Type-safe error handling
protocol Validator {
    /// The type being validated
    associatedtype Value

    /// The error type returned on validation failure
    associatedtype ValidationError: Error

    /// Validate a value
    /// - Parameter value: The value to validate
    /// - Returns: Result containing validated value or error
    func validate(_ value: Value) -> Result<Value, ValidationError>
}

// MARK: - Type Erasure for Composition

/// Type-erased validation error
/// Wraps any validator's specific error type for composition
enum AnyValidationError: Error, Equatable {
    case wrapped(String, underlyingError: String)

    init(wrapping error: Error) {
        let typeName = String(describing: type(of: error))
        let description = (error as? LocalizedError)?.errorDescription
            ?? error.localizedDescription
        self = .wrapped(typeName, underlyingError: description)
    }

    var localizedDescription: String {
        if case .wrapped(_, let description) = self {
            return description
        }
        return "Validation failed"
    }

    static func == (lhs: AnyValidationError, rhs: AnyValidationError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}

/// Type-erased validator wrapper
/// Allows composition of validators with different error types
struct AnyValidator<Value>: Validator {
    typealias ValidationError = AnyValidationError

    private let _validate: (Value) -> Result<Value, AnyValidationError>

    init<V: Validator>(_ validator: V) where V.Value == Value {
        self._validate = { value in
            validator.validate(value)
                .mapError { AnyValidationError(wrapping: $0) }
        }
    }

    init(_ validate: @escaping (Value) -> Result<Value, AnyValidationError>) {
        self._validate = validate
    }

    func validate(_ value: Value) -> Result<Value, AnyValidationError> {
        _validate(value)
    }
}

// MARK: - Validator Composition

extension Validator {
    /// Combine this validator with another validator
    /// Creates a new validator that runs both validations in sequence
    /// - Parameter other: The validator to combine with
    /// - Returns: A composed validator
    func and<V: Validator>(_ other: V) -> ComposedValidator<Self, V>
    where V.Value == Value, V.ValidationError == ValidationError {
        ComposedValidator(first: self, second: other)
    }

    /// Combine with another validator (different error types)
    /// Uses type erasure to enable composition of heterogeneous validators
    /// - Parameter other: The validator to combine with
    /// - Returns: A type-erased composed validator
    func and<V: Validator>(_ other: V) -> AnyValidator<Value>
    where V.Value == Value {
        let first = AnyValidator(self)
        let second = AnyValidator(other)
        return AnyValidator { value in
            switch first.validate(value) {
            case .success(let validated):
                return second.validate(validated)
            case .failure(let error):
                return .failure(error)
            }
        }
    }

    /// Convert any validator to type-erased form
    /// - Returns: A type-erased validator
    func eraseToAnyValidator() -> AnyValidator<Value> {
        AnyValidator(self)
    }
}

/// Composed validator that runs two validators in sequence
/// Demonstrates:
/// - Generic type composition
/// - Where clauses for type constraints
/// - Short-circuit evaluation (fails on first error)
struct ComposedValidator<First: Validator, Second: Validator>: Validator
where First.Value == Second.Value, First.ValidationError == Second.ValidationError {
    typealias Value = First.Value
    typealias ValidationError = First.ValidationError

    private let first: First
    private let second: Second

    init(first: First, second: Second) {
        self.first = first
        self.second = second
    }

    func validate(_ value: Value) -> Result<Value, ValidationError> {
        // Short-circuit: if first fails, don't run second
        switch first.validate(value) {
        case .success(let validated):
            return second.validate(validated)
        case .failure(let error):
            return .failure(error)
        }
    }
}

// MARK: - Common Validators

/// Generic string length validator
/// Demonstrates:
/// - Generic enums
/// - Associated values
/// - Reusable validation logic
struct StringLengthValidator: Validator {
    enum Error: Swift.Error, Equatable {
        case tooShort(minimum: Int)
        case tooLong(maximum: Int)
        case empty
    }

    private let minimum: Int
    private let maximum: Int

    init(minimum: Int = 0, maximum: Int = .max) {
        self.minimum = minimum
        self.maximum = maximum
    }

    func validate(_ value: String) -> Result<String, Error> {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return .failure(.empty)
        }

        guard trimmed.count >= minimum else {
            return .failure(.tooShort(minimum: minimum))
        }

        guard trimmed.count <= maximum else {
            return .failure(.tooLong(maximum: maximum))
        }

        return .success(trimmed)
    }
}

/// Generic regex pattern validator
/// Demonstrates:
/// - NSRegularExpression usage
/// - Pattern-based validation
/// - Unicode support
struct RegexValidator: Validator {
    enum Error: Swift.Error, Equatable {
        case invalidPattern
        case doesNotMatch
    }

    private let pattern: String
    private let options: NSRegularExpression.Options

    init(pattern: String, options: NSRegularExpression.Options = []) {
        self.pattern = pattern
        self.options = options
    }

    func validate(_ value: String) -> Result<String, Error> {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return .failure(.invalidPattern)
        }

        let range = NSRange(value.startIndex..., in: value)
        guard regex.firstMatch(in: value, range: range) != nil else {
            return .failure(.doesNotMatch)
        }

        return .success(value)
    }
}

/// Character set validator
/// Demonstrates:
/// - CharacterSet usage
/// - Unicode scalar validation
struct CharacterSetValidator: Validator {
    enum Error: Swift.Error, Equatable {
        case containsInvalidCharacters
    }

    private let allowedCharacters: CharacterSet

    init(allowedCharacters: CharacterSet) {
        self.allowedCharacters = allowedCharacters
    }

    func validate(_ value: String) -> Result<String, Error> {
        guard value.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return .failure(.containsInvalidCharacters)
        }

        return .success(value)
    }
}

/// Generic range validator for Comparable types
/// Demonstrates:
/// - Generic constraints (Comparable)
/// - Flexible type reuse
struct RangeValidator<T: Comparable>: Validator {
    enum Error: Swift.Error, Equatable {
        case lessThanMinimum
        case greaterThanMaximum
        case outsideRange
    }

    private let minimum: T?
    private let maximum: T?

    init(minimum: T? = nil, maximum: T? = nil) {
        self.minimum = minimum
        self.maximum = maximum
    }

    func validate(_ value: T) -> Result<T, Error> {
        if let min = minimum, value < min {
            return .failure(.lessThanMinimum)
        }

        if let max = maximum, value > max {
            return .failure(.greaterThanMaximum)
        }

        return .success(value)
    }
}

/// Date validator with age constraints
/// Demonstrates:
/// - Calendar API usage
/// - Date arithmetic
/// - Domain-specific validation
struct DateAgeValidator: Validator {
    enum Error: Swift.Error, Equatable {
        case inFuture
        case tooYoung(minimumAge: Int)
        case tooOld(maximumAge: Int)
    }

    private let minimumAge: Int?
    private let maximumAge: Int?

    init(minimumAge: Int? = nil, maximumAge: Int? = nil) {
        self.minimumAge = minimumAge
        self.maximumAge = maximumAge
    }

    func validate(_ value: Date) -> Result<Date, Error> {
        let now = Date()

        // Check if date is in the future
        guard value < now else {
            return .failure(.inFuture)
        }

        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: value, to: now)
        guard let age = ageComponents.year else {
            return .success(value)
        }

        // Check minimum age
        if let minAge = minimumAge, age < minAge {
            return .failure(.tooYoung(minimumAge: minAge))
        }

        // Check maximum age
        if let maxAge = maximumAge, age > maxAge {
            return .failure(.tooOld(maximumAge: maxAge))
        }

        return .success(value)
    }
}
