//
//  URLSessionAuthHTTPClient.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import Foundation

/// URLSession-based implementation of AuthHTTPClient
/// Thread-safe actor for concurrent auth requests
actor URLSessionAuthHTTPClient: AuthHTTPClient {
    private let session: URLSession
    private let baseURL: URL

    /// Initialize with URLSession and base API URL
    /// - Parameters:
    ///   - session: URLSession instance (injectable for testing)
    ///   - baseURL: Base URL for auth endpoints (e.g., http://localhost:3000)
    init(session: URLSession = .shared, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let endpoint = baseURL.appendingPathComponent("/auth/login")
        let requestBody = LoginRequest(email: email, password: password)

        return try await performRequest(
            url: endpoint,
            method: "POST",
            body: requestBody,
            responseType: AuthResponse.self
        )
    }

    func refresh(refreshToken: String) async throws -> AuthResponse {
        let endpoint = baseURL.appendingPathComponent("/auth/refresh")
        let requestBody = RefreshRequest(refreshToken: refreshToken)

        return try await performRequest(
            url: endpoint,
            method: "POST",
            body: requestBody,
            responseType: AuthResponse.self
        )
    }

    func logout(accessToken: String, refreshToken: String) async throws {
        let endpoint = baseURL.appendingPathComponent("/auth/logout")
        let requestBody = LogoutRequest(refreshToken: refreshToken)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let encoder = JSONEncoder()
        // Backend expects camelCase JSON, no snake_case conversion needed
        request.httpBody = try encoder.encode(requestBody)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw mapHTTPError(statusCode: httpResponse.statusCode)
        }
    }

    func register(email: String, password: String, confirmPassword: String) async throws -> RegisterResponse {
        let endpoint = baseURL.appendingPathComponent("/auth/register")
        let requestBody = RegisterRequest(email: email, password: password, confirmPassword: confirmPassword)

        return try await performRequest(
            url: endpoint,
            method: "POST",
            body: requestBody,
            responseType: RegisterResponse.self
        )
    }

    func forgotPassword(email: String) async throws {
        let endpoint = baseURL.appendingPathComponent("/auth/forgot-password")
        let requestBody = ForgotPasswordRequest(email: email)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw mapHTTPError(statusCode: httpResponse.statusCode)
        }
    }

    func resetPassword(token: String, newPassword: String) async throws {
        let endpoint = baseURL.appendingPathComponent("/auth/reset-password")
        let requestBody = ResetPasswordRequest(token: token, newPassword: newPassword)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)

        let (_, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw mapHTTPError(statusCode: httpResponse.statusCode)
        }
    }

    // MARK: - Private Helpers

    /// Perform JSON request with encoding/decoding
    private func performRequest<RequestBody: Encodable, Response: Decodable>(
        url: URL,
        method: String,
        body: RequestBody,
        responseType: Response.Type
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let encoder = JSONEncoder()
        // Backend expects camelCase JSON, no snake_case conversion needed
        request.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw mapHTTPError(statusCode: httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        // Backend sends camelCase JSON, no snake_case conversion needed
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw AuthError.invalidResponse
        }
    }

    /// Map HTTP status codes to AuthError cases
    /// Note: For more specific error handling, parse the response body's "error" field
    private func mapHTTPError(statusCode: Int) -> AuthError {
        switch statusCode {
        case 401:
            return .invalidCredentials
        case 409:
            // Conflict - email already exists
            return .emailAlreadyExists
        case 400...499:
            return .invalidResponse
        case 500...599:
            return .networkError
        default:
            return .unknown("HTTP \(statusCode)")
        }
    }
}
