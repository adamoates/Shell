//
//  HTTPClient.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// HTTP method types
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// HTTP request representation
public struct HTTPRequest {
    public let url: URL
    public let method: HTTPMethod
    public let headers: [String: String]
    public let body: Data?

    public init(
        url: URL,
        method: HTTPMethod,
        headers: [String: String] = [:],
        body: Data? = nil
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}

/// HTTP response representation
public struct HTTPResponse {
    public let statusCode: Int
    public let data: Data
    public let headers: [String: String]

    public init(statusCode: Int, data: Data, headers: [String: String]) {
        self.statusCode = statusCode
        self.data = data
        self.headers = headers
    }
}

/// HTTP client errors
public enum HTTPClientError: Error, Equatable {
    case networkError(Error)
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingError(Error)

    public static func == (lhs: HTTPClientError, rhs: HTTPClientError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse):
            return true
        case (.httpError(let lhsCode, _), .httpError(let rhsCode, _)):
            return lhsCode == rhsCode
        case (.networkError, .networkError):
            return true
        case (.decodingError, .decodingError):
            return true
        default:
            return false
        }
    }
}

/// Protocol for HTTP client abstraction
/// Allows for easy testing with mock implementations
public protocol HTTPClient {
    /// Perform an HTTP request
    /// - Parameter request: The HTTP request to perform
    /// - Returns: HTTP response
    /// - Throws: HTTPClientError on failure
    func perform(_ request: HTTPRequest) async throws -> HTTPResponse
}
