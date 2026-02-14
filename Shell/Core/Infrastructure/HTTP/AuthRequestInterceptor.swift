//
//  AuthRequestInterceptor.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import Foundation

/// Protocol for request interception and retry logic
/// Enables automatic token refresh on 401 responses
protocol RequestInterceptor: Sendable {
    /// Adapt a request before execution (e.g., add Authorization header)
    /// - Parameter request: The original request
    /// - Returns: The adapted request with headers
    /// - Throws: If adaptation fails
    func adapt(_ request: URLRequest) async throws -> URLRequest

    /// Determine if a request should be retried after failure
    /// - Parameters:
    ///   - request: The original request
    ///   - response: The HTTP response
    ///   - data: Response data
    /// - Returns: True if the request should be retried
    /// - Throws: If retry logic fails or refresh is not possible
    func retry(_ request: URLRequest, for response: HTTPURLResponse, with data: Data) async throws -> Bool
}

/// Actor-isolated request interceptor for automatic token refresh
/// Prevents concurrent refresh attempts using Task deduplication
///
/// Thread Safety:
/// - Actor isolation prevents data races on isRefreshing and refreshTask
/// - Multiple concurrent 401 responses will wait for the same refresh task
/// - Only one refresh request is made even if dozens of requests fail simultaneously
actor AuthRequestInterceptor: RequestInterceptor {
    private let sessionRepository: SessionRepository
    private let authHTTPClient: AuthHTTPClient

    // State tracking for refresh deduplication
    private var isRefreshing = false
    private var refreshTask: Task<UserSession, Error>?

    /// Initialize with dependencies
    /// - Parameters:
    ///   - sessionRepository: Repository for session storage (Keychain)
    ///   - authHTTPClient: HTTP client for auth endpoints
    init(sessionRepository: SessionRepository, authHTTPClient: AuthHTTPClient) {
        self.sessionRepository = sessionRepository
        self.authHTTPClient = authHTTPClient
    }

    // MARK: - RequestInterceptor

    func adapt(_ request: URLRequest) async throws -> URLRequest {
        // Get current session from Keychain
        guard let session = try await sessionRepository.getCurrentSession() else {
            // No session exists, pass through request unchanged
            return request
        }

        // Add Authorization header with Bearer token
        var mutableRequest = request
        mutableRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        return mutableRequest
    }

    func retry(_ request: URLRequest, for response: HTTPURLResponse, with data: Data) async throws -> Bool {
        // Only retry on 401 Unauthorized
        guard response.statusCode == 401 else {
            return false
        }

        // If already refreshing, wait for existing refresh task
        if isRefreshing, let task = refreshTask {
            // Wait for the existing refresh to complete
            _ = try await task.value
            return true // Retry with new token
        }

        // Start new refresh process
        isRefreshing = true

        // Create refresh task (stored for deduplication)
        refreshTask = Task {
            do {
                // Get current session
                guard let session = try await sessionRepository.getCurrentSession() else {
                    throw AuthError.noRefreshToken
                }

                // Call refresh endpoint with refresh token
                let authResponse = try await authHTTPClient.refresh(refreshToken: session.refreshToken)

                // Save new session to Keychain
                let newSession = authResponse.session
                try await sessionRepository.saveSession(newSession)

                return newSession

            } catch {
                // Refresh failed - clear session and force re-login
                try? await sessionRepository.clearSession()
                throw AuthError.refreshFailed
            }
        }

        // Wait for refresh to complete
        do {
            _ = try await refreshTask?.value
            // Reset state
            isRefreshing = false
            refreshTask = nil
            return true // Retry original request with new token
        } catch {
            // Reset state
            isRefreshing = false
            refreshTask = nil
            throw error
        }
    }
}
