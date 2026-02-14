//
//  AuthenticatedHTTPClient.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import Foundation

/// HTTP client wrapper that automatically handles authentication
/// Uses AuthRequestInterceptor for token refresh on 401 responses
///
/// Usage:
/// ```swift
/// let client = AuthenticatedHTTPClient(
///     session: .shared,
///     interceptor: authInterceptor
/// )
///
/// let request = URLRequest(url: protectedURL)
/// let (data, response) = try await client.execute(request)
/// ```
actor AuthenticatedHTTPClient {
    private let session: URLSession
    private let interceptor: AuthRequestInterceptor

    /// Initialize with URLSession and interceptor
    /// - Parameters:
    ///   - session: URLSession for network requests
    ///   - interceptor: Request interceptor for auth handling
    init(session: URLSession, interceptor: AuthRequestInterceptor) {
        self.session = session
        self.interceptor = interceptor
    }

    /// Execute a request with automatic token refresh
    /// - Parameter request: The URLRequest to execute
    /// - Returns: Response data and HTTP response
    /// - Throws: HTTPError or AuthError on failure
    func execute(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        // Adapt request (add Authorization header)
        var adaptedRequest = try await interceptor.adapt(request)

        // Execute request
        let (data, response) = try await session.data(for: adaptedRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }

        // Check for 401 Unauthorized
        if httpResponse.statusCode == 401 {
            // Ask interceptor if we should retry
            let shouldRetry = try await interceptor.retry(adaptedRequest, for: httpResponse, with: data)

            if shouldRetry {
                // Token was refreshed, retry with new token
                adaptedRequest = try await interceptor.adapt(request)
                let (retryData, retryResponse) = try await session.data(for: adaptedRequest)

                guard let retryHTTPResponse = retryResponse as? HTTPURLResponse else {
                    throw HTTPError.invalidResponse
                }

                return (retryData, retryHTTPResponse)
            }
        }

        return (data, httpResponse)
    }

    /// Execute a JSON request with Codable support
    /// - Parameters:
    ///   - request: The URLRequest to execute
    ///   - responseType: The expected Decodable response type
    /// - Returns: Decoded response object
    /// - Throws: HTTPError, AuthError, or DecodingError on failure
    func execute<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        let (data, httpResponse) = try await execute(request)

        // Check for HTTP errors
        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        // Decode response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw HTTPError.decodingError(underlying: error)
        }
    }
}
