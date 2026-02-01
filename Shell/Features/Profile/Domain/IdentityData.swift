//
//  IdentityData.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Domain model for identity setup data
/// Collected across the multi-step identity setup flow
struct IdentityData: Equatable, Codable, Sendable {
    let screenName: String
    let birthday: Date

    /// Validate screen name
    /// - Returns: Validation result with error message if invalid
    static func validateScreenName(_ screenName: String) -> Result<String, IdentityValidationError> {
        let trimmed = screenName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check length
        guard trimmed.count >= 2 else {
            return .failure(.screenNameTooShort)
        }

        guard trimmed.count <= 20 else {
            return .failure(.screenNameTooLong)
        }

        // Check characters (alphanumeric, underscore, hyphen only)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        guard trimmed.unicodeScalars.allSatisfy({ allowedCharacters.contains($0) }) else {
            return .failure(.screenNameInvalidCharacters)
        }

        return .success(trimmed)
    }

    /// Validate birthday
    /// - Returns: Validation result with error message if invalid
    static func validateBirthday(_ birthday: Date) -> Result<Date, IdentityValidationError> {
        let calendar = Calendar.current
        let now = Date()

        // Check if birthday is in the future
        guard birthday < now else {
            return .failure(.birthdayInFuture)
        }

        // Check minimum age (13 years old for COPPA compliance)
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
        guard let age = ageComponents.year, age >= 13 else {
            return .failure(.birthdayTooRecent)
        }

        // Check maximum age (120 years - sanity check)
        guard age <= 120 else {
            return .failure(.birthdayTooOld)
        }

        return .success(birthday)
    }

    /// Create identity data with validation
    static func create(
        screenName: String,
        birthday: Date
    ) -> Result<IdentityData, IdentityValidationError> {
        // Validate screen name
        guard case .success(let validScreenName) = validateScreenName(screenName) else {
            if case .failure(let error) = validateScreenName(screenName) {
                return .failure(error)
            }
            return .failure(.screenNameInvalidCharacters)
        }

        // Validate birthday
        guard case .success(let validBirthday) = validateBirthday(birthday) else {
            if case .failure(let error) = validateBirthday(birthday) {
                return .failure(error)
            }
            return .failure(.birthdayInFuture)
        }

        return .success(IdentityData(
            screenName: validScreenName,
            birthday: validBirthday
        ))
    }
}

// MARK: - Validation Errors

enum IdentityValidationError: Error, Equatable {
    case screenNameTooShort
    case screenNameTooLong
    case screenNameInvalidCharacters
    case birthdayInFuture
    case birthdayTooRecent
    case birthdayTooOld

    var localizedDescription: String {
        switch self {
        case .screenNameTooShort:
            return "Screen name must be at least 2 characters"
        case .screenNameTooLong:
            return "Screen name must be 20 characters or less"
        case .screenNameInvalidCharacters:
            return "Screen name can only contain letters, numbers, underscores, and hyphens"
        case .birthdayInFuture:
            return "Birthday cannot be in the future"
        case .birthdayTooRecent:
            return "You must be at least 13 years old"
        case .birthdayTooOld:
            return "Please enter a valid birthday"
        }
    }
}
