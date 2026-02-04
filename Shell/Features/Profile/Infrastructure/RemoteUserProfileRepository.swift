//
//  RemoteUserProfileRepository.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Remote implementation of UserProfileRepository
/// Communicates with backend API for profile persistence
final class RemoteUserProfileRepository: UserProfileRepository {
    private let httpClient: HTTPClient
    private let baseURL: URL
    private let authToken: String?
    private let logger: Logger

    init(
        httpClient: HTTPClient,
        baseURL: URL,
        authToken: String? = nil,
        logger: Logger
    ) {
        self.httpClient = httpClient
        self.baseURL = baseURL
        self.authToken = authToken
        self.logger = logger
    }

    // MARK: - UserProfileRepository

    func fetchProfile(userID: String) async -> UserProfile? {
        // Build URL: GET /users/{userID}/profile
        guard let url = URL(string: "/users/\(userID)/profile", relativeTo: baseURL) else {
            logger.error("Invalid URL for fetch profile", category: "repository", context: ["userID": userID])
            return nil
        }

        // Build request
        var headers = ["Content-Type": "application/json"]
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        let request = HTTPRequest(
            url: url,
            method: .get,
            headers: headers
        )

        do {
            // Perform HTTP request
            let response = try await httpClient.perform(request)

            // Decode response
            let decoder = JSONDecoder()
            let profileResponse = try decoder.decode(ProfileAPI.ProfileResponse.self, from: response.data)

            // Map to domain model
            return ProfileAPI.toDomain(profileResponse)

        } catch HTTPClientError.httpError(statusCode: 404, _) {
            // Profile not found - this is expected for new users
            logger.info("Profile not found", category: "repository", context: ["userID": userID])
            return nil

        } catch {
            logger.warning("Failed to fetch profile", category: "repository", context: ["userID": userID, "error": "\(error)"])
            return nil
        }
    }

    func saveProfile(_ profile: UserProfile) async {
        // Build URL: PUT /users/{userID}/profile
        guard let url = URL(string: "/users/\(profile.userID)/profile", relativeTo: baseURL) else {
            logger.error("Invalid URL for save profile", category: "repository", context: ["userID": profile.userID])
            return
        }

        // Build request body
        let requestBody = ProfileAPI.toRequest(profile: profile)

        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            logger.error("Failed to encode profile request body", category: "repository", context: ["userID": profile.userID])
            return
        }

        // Build request
        var headers = ["Content-Type": "application/json"]
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        let request = HTTPRequest(
            url: url,
            method: .put,
            headers: headers,
            body: bodyData
        )

        do {
            // Perform HTTP request
            _ = try await httpClient.perform(request)
            logger.info("Profile saved", category: "repository", context: ["userID": profile.userID])

        } catch {
            logger.warning("Failed to save profile", category: "repository", context: ["userID": profile.userID, "error": "\(error)"])
        }
    }

    func deleteProfile(userID: String) async {
        // Build URL: DELETE /users/{userID}/profile
        guard let url = URL(string: "/users/\(userID)/profile", relativeTo: baseURL) else {
            logger.error("Invalid URL for delete profile", category: "repository", context: ["userID": userID])
            return
        }

        // Build request
        var headers = ["Content-Type": "application/json"]
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        let request = HTTPRequest(
            url: url,
            method: .delete,
            headers: headers
        )

        do {
            // Perform HTTP request
            _ = try await httpClient.perform(request)
            logger.info("Profile deleted", category: "repository", context: ["userID": userID])

        } catch {
            logger.warning("Failed to delete profile", category: "repository", context: ["userID": userID, "error": "\(error)"])
        }
    }

    func hasCompletedIdentitySetup(userID: String) async -> Bool {
        // Build URL: GET /users/{userID}/identity-status
        guard let url = URL(string: "/users/\(userID)/identity-status", relativeTo: baseURL) else {
            logger.error("Invalid URL for identity status", category: "repository", context: ["userID": userID])
            return false
        }

        // Build request
        var headers = ["Content-Type": "application/json"]
        if let token = authToken {
            headers["Authorization"] = "Bearer \(token)"
        }

        let request = HTTPRequest(
            url: url,
            method: .get,
            headers: headers
        )

        do {
            // Perform HTTP request
            let response = try await httpClient.perform(request)

            // Decode response
            let decoder = JSONDecoder()
            let statusResponse = try decoder.decode(ProfileAPI.IdentityStatusResponse.self, from: response.data)

            return statusResponse.hasCompletedIdentitySetup

        } catch {
            logger.warning("Failed to fetch identity status", category: "repository", context: ["userID": userID, "error": "\(error)"])
            return false
        }
    }
}
