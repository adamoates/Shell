# Validation Framework

## Overview

The Shell validation framework provides composable, type-safe validators for input validation across the application.

### Core Components

- **Validator Protocol**: Generic protocol for implementing validation logic
- **Type-Erased Composition**: Chain validators with different error types using `AnyValidator`
- **Built-in Validators**: Common validators for strings, numbers, dates, and character sets

## Quick Start

### Basic Validation

```swift
let validator = StringLengthValidator(minimum: 3, maximum: 20)
let result = validator.validate("hello")

switch result {
case .success(let value):
    print("Valid: \(value)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Composing Validators

Combine multiple validators to create complex validation rules:

```swift
let usernameValidator = StringLengthValidator(minimum: 3, maximum: 20)
    .and(CharacterSetValidator(allowedCharacters: .alphanumerics))

let result = usernameValidator.validate("user123")
// Returns: .success("user123")

let invalidResult = usernameValidator.validate("ab")
// Returns: .failure(AnyValidationError)
```

### Type-Erased Composition

The `.and()` method automatically handles validators with different error types:

```swift
// These validators have different error types:
// - StringLengthValidator.Error
// - CharacterSetValidator.Error
// - RegexValidator.Error

let complexValidator = StringLengthValidator(minimum: 3, maximum: 20)
    .and(CharacterSetValidator(allowedCharacters: .alphanumerics))
    .and(RegexValidator(pattern: "^[a-z]+$", options: []))

// Returns AnyValidator<String> which can compose any validator
```

## Available Validators

### StringLengthValidator

Validates string length with optional trimming:

```swift
let validator = StringLengthValidator(minimum: 2, maximum: 100)
validator.validate("hello") // .success("hello")
validator.validate("x")      // .failure(.tooShort(minimum: 2))
```

### RegexValidator

Pattern matching with NSRegularExpression:

```swift
let emailValidator = RegexValidator(
    pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$",
    options: .caseInsensitive
)
emailValidator.validate("user@example.com") // .success
```

### CharacterSetValidator

Restrict input to allowed character sets:

```swift
let alphanumericValidator = CharacterSetValidator(
    allowedCharacters: .alphanumerics
)
alphanumericValidator.validate("abc123")  // .success
alphanumericValidator.validate("abc_123") // .failure(.containsInvalidCharacters)
```

### RangeValidator<T>

Generic range validation for Comparable types:

```swift
let ageValidator = RangeValidator(minimum: 18, maximum: 120)
ageValidator.validate(25)  // .success(25)
ageValidator.validate(15)  // .failure(.lessThanMinimum)
```

### DateAgeValidator

Age-based date validation (e.g., COPPA compliance):

```swift
let validator = DateAgeValidator(minimumAge: 13, maximumAge: 120)
let birthdate = Calendar.current.date(byAdding: .year, value: -20, to: Date())!
validator.validate(birthdate) // .success
```

## Creating Custom Validators

Implement the `Validator` protocol:

```swift
struct EmailDomainValidator: Validator {
    enum Error: Swift.Error {
        case invalidDomain
    }

    private let allowedDomains: Set<String>

    init(allowedDomains: Set<String>) {
        self.allowedDomains = allowedDomains
    }

    func validate(_ value: String) -> Result<String, Error> {
        guard let domain = value.split(separator: "@").last,
              allowedDomains.contains(String(domain)) else {
            return .failure(.invalidDomain)
        }
        return .success(value)
    }
}

// Use in composition
let validator = RegexValidator(pattern: emailPattern)
    .and(EmailDomainValidator(allowedDomains: ["company.com"]))
```

## Testing

All validators are fully testable:

```swift
func testUsernameValidation() {
    let validator = StringLengthValidator(minimum: 3, maximum: 20)
        .and(CharacterSetValidator(allowedCharacters: .alphanumerics))

    XCTAssertNoThrow(try validator.validate("user123").get())
    XCTAssertThrowsError(try validator.validate("ab").get())
}
```

## Architecture

### Protocol-Oriented Design

```swift
protocol Validator {
    associatedtype Value
    associatedtype ValidationError: Error

    func validate(_ value: Value) -> Result<Value, ValidationError>
}
```

### Type Erasure

`AnyValidator` wraps any validator, erasing its specific error type:

```swift
struct AnyValidator<Value>: Validator {
    typealias ValidationError = AnyValidationError

    init<V: Validator>(_ validator: V) where V.Value == Value
    func validate(_ value: Value) -> Result<Value, AnyValidationError>
}
```

### Composition

Validators can be chained using `.and()`:

```swift
extension Validator {
    // Same error types
    func and<V: Validator>(_ other: V) -> ComposedValidator<Self, V>
    where V.Value == Value, V.ValidationError == ValidationError

    // Different error types (type-erased)
    func and<V: Validator>(_ other: V) -> AnyValidator<Value>
    where V.Value == Value
}
```

## Best Practices

1. **Compose validators** instead of writing complex validation logic
2. **Use type-erased composition** when combining validators with different errors
3. **Provide descriptive error messages** in custom validators
4. **Test validators in isolation** before composing them
5. **Prefer immutable validators** - create new instances instead of mutating

## Examples

### User Registration Form

```swift
let usernameValidator = StringLengthValidator(minimum: 3, maximum: 20)
    .and(CharacterSetValidator(allowedCharacters: .alphanumerics))

let passwordValidator = StringLengthValidator(minimum: 8, maximum: 128)
    .and(RegexValidator(pattern: ".*[A-Z].*")) // At least one uppercase
    .and(RegexValidator(pattern: ".*[0-9].*")) // At least one number

let emailValidator = RegexValidator(
    pattern: "^[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}$",
    options: .caseInsensitive
)

// Validate each field
let usernameResult = usernameValidator.validate(username)
let passwordResult = passwordValidator.validate(password)
let emailResult = emailValidator.validate(email)
```

### Data Entry with Age Restrictions

```swift
let birthdateValidator = DateAgeValidator(minimumAge: 18, maximumAge: 120)
let phoneValidator = RegexValidator(pattern: "^\\d{10}$")
let zipValidator = RegexValidator(pattern: "^\\d{5}(-\\d{4})?$")

// Validate form data
let birthdateResult = birthdateValidator.validate(birthdate)
let phoneResult = phoneValidator.validate(phone)
let zipResult = zipValidator.validate(zipCode)
```

## See Also

- `Validator.swift` - Core protocol definitions
- `ValidatorTests.swift` - Comprehensive test suite with examples
- CLAUDE.md - Project architecture and guidelines
