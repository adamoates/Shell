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

    init(
        httpClient: HTTPClient,
        baseURL: URL,
        authToken: String? = nil
    ) {
        self.httpClient = httpClient
        self.baseURL = baseURL
        self.authToken = authToken
    }

    // MARK: - UserProfileRepository

    func fetchProfile(userID: String) async -> UserProfile? {
        // Build URL: GET /users/{userID}/profile
        guard let url = URL(string: "/users/\(userID)/profile", relativeTo: baseURL) else {
            print("⚠️ RemoteUserProfileRepository: Invalid URL for user \(userID)")
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
            print("ℹ️ RemoteUserProfileRepository: Profile not found for user \(userID)")
            return nil

        } catch {
            print("⚠️ RemoteUserProfileRepository: Failed to fetch profile: \(error)")
            return nil
        }
    }

    func saveProfile(_ profile: UserProfile) async {
        // Build URL: PUT /users/{userID}/profile
        guard let url = URL(string: "/users/\(profile.userID)/profile", relativeTo: baseURL) else {
            print("⚠️ RemoteUserProfileRepository: Invalid URL for user \(profile.userID)")
            return
        }

        // Build request body
        let requestBody = ProfileAPI.toRequest(profile: profile)

        guard let bodyData = try? JSONEncoder().encode(requestBody) else {
            print("⚠️ RemoteUserProfileRepository: Failed to encode request body")
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
            print("✅ RemoteUserProfileRepository: Profile saved for user \(profile.userID)")

        } catch {
            print("⚠️ RemoteUserProfileRepository: Failed to save profile: \(error)")
        }
    }

    func deleteProfile(userID: String) async {
        // Build URL: DELETE /users/{userID}/profile
        guard let url = URL(string: "/users/\(userID)/profile", relativeTo: baseURL) else {
            print("⚠️ RemoteUserProfileRepository: Invalid URL for user \(userID)")
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
            print("✅ RemoteUserProfileRepository: Profile deleted for user \(userID)")

        } catch {
            print("⚠️ RemoteUserProfileRepository: Failed to delete profile: \(error)")
        }
    }

    func hasCompletedIdentitySetup(userID: String) async -> Bool {
        // Build URL: GET /users/{userID}/identity-status
        guard let url = URL(string: "/users/\(userID)/identity-status", relativeTo: baseURL) else {
            print("⚠️ RemoteUserProfileRepository: Invalid URL for user \(userID)")
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
            print("⚠️ RemoteUserProfileRepository: Failed to fetch identity status: \(error)")
            return false
        }
    }
}
