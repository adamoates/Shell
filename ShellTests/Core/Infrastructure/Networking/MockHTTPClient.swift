//
//  MockHTTPClient.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import Foundation
@testable import Shell

/// Mock HTTP client for testing
/// Allows stubbing responses for specific URLs
final class MockHTTPClient: HTTPClient {
    private var responses: [String: Result<HTTPResponse, HTTPClientError>] = [:]
    private(set) var requests: [HTTPRequest] = []

    /// Stub a response for a specific URL pattern
    func stub(urlPattern: String, response: Result<HTTPResponse, HTTPClientError>) {
        responses[urlPattern] = response
    }

    /// Stub a success response with JSON data
    func stubSuccess(urlPattern: String, statusCode: Int = 200, json: Data) {
        let response = HTTPResponse(
            statusCode: statusCode,
            data: json,
            headers: ["Content-Type": "application/json"]
        )
        stub(urlPattern: urlPattern, response: .success(response))
    }

    /// Stub an error response
    func stubError(urlPattern: String, error: HTTPClientError) {
        stub(urlPattern: urlPattern, response: .failure(error))
    }

    /// Stub a 404 not found response
    func stub404(urlPattern: String) {
        let errorData = """
        {
            "error": "profile_not_found",
            "message": "No profile exists for this user"
        }
        """.data(using: .utf8)!

        stubError(urlPattern: urlPattern, error: .httpError(statusCode: 404, data: errorData))
    }

    func perform(_ request: HTTPRequest) async throws -> HTTPResponse {
        // Record request
        requests.append(request)

        // Find matching response
        let urlString = request.url.absoluteString

        for (pattern, response) in responses {
            if urlString.contains(pattern) {
                return try response.get()
            }
        }

        // No stub found - fail test
        fatalError("No stub found for URL: \(urlString)")
    }

    /// Get the number of requests made
    func getRequestCount() -> Int {
        requests.count
    }

    /// Get the last request made
    func getLastRequest() -> HTTPRequest? {
        requests.last
    }

    /// Clear all recorded requests
    func clearRequests() {
        requests.removeAll()
    }
}
