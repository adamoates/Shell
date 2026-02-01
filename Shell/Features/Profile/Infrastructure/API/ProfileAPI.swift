//
//  ProfileAPI.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// API models for Profile endpoints
enum ProfileAPI {
    // MARK: - Request Models

    struct CreateProfileRequest: Codable {
        let screenName: String
        let birthday: String  // ISO 8601 date format: "YYYY-MM-DD"
        let avatarURL: String?
    }

    // MARK: - Response Models

    struct ProfileResponse: Codable {
        let userID: String
        let screenName: String
        let birthday: String  // ISO 8601 date format
        let avatarURL: String?
        let createdAt: String  // ISO 8601 datetime
        let updatedAt: String  // ISO 8601 datetime
    }

    struct IdentityStatusResponse: Codable {
        let hasCompletedIdentitySetup: Bool
    }

    struct ErrorResponse: Codable {
        let error: String
        let message: String
        let field: String?
    }

    // MARK: - Mappers

    /// Convert ProfileResponse to domain UserProfile
    static func toDomain(_ response: ProfileResponse) -> UserProfile? {
        // Parse ISO 8601 dates
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]

        let datetimeFormatter = ISO8601DateFormatter()

        guard let birthday = dateFormatter.date(from: response.birthday),
              let createdAt = datetimeFormatter.date(from: response.createdAt),
              let updatedAt = datetimeFormatter.date(from: response.updatedAt) else {
            return nil
        }

        let avatarURL: URL?
        if let urlString = response.avatarURL {
            avatarURL = URL(string: urlString)
        } else {
            avatarURL = nil
        }

        return UserProfile(
            userID: response.userID,
            screenName: response.screenName,
            birthday: birthday,
            avatarURL: avatarURL,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Convert domain IdentityData to API request
    static func toRequest(userID: String, identityData: IdentityData, avatarURL: URL?) -> CreateProfileRequest {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]

        return CreateProfileRequest(
            screenName: identityData.screenName,
            birthday: dateFormatter.string(from: identityData.birthday),
            avatarURL: avatarURL?.absoluteString
        )
    }

    /// Convert domain UserProfile to API request
    static func toRequest(profile: UserProfile) -> CreateProfileRequest {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]

        return CreateProfileRequest(
            screenName: profile.screenName,
            birthday: dateFormatter.string(from: profile.birthday),
            avatarURL: profile.avatarURL?.absoluteString
        )
    }
}
