//
//  ItemsHTTPClient.swift
//  Shell
//
//  Created by Shell on 2026-02-01.
//

import Foundation

/// HTTP client abstraction for Items network requests
/// Allows mocking for tests using URLProtocol
protocol ItemsHTTPClient: Sendable {
    func request<T: Decodable>(
        _ endpoint: HTTPEndpoint,
        responseType: T.Type
    ) async throws -> T

    func request(_ endpoint: HTTPEndpoint) async throws
}

/// HTTP endpoint configuration
struct HTTPEndpoint: Sendable {
    enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
    }

    let path: String
    let method: Method
    let body: Data?
    let headers: [String: String]

    init(
        path: String,
        method: Method,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.method = method
        self.body = body
        self.headers = headers
    }
}

/// URLSession-based HTTP client implementation for Items
actor URLSessionItemsHTTPClient: ItemsHTTPClient {
    private let session: URLSession
    private let baseURL: URL

    init(session: URLSession = .shared, baseURL: URL) {
        self.session = session
        self.baseURL = baseURL
    }

    func request<T: Decodable>(
        _ endpoint: HTTPEndpoint,
        responseType: T.Type
    ) async throws -> T {
        let urlRequest = try buildURLRequest(for: endpoint)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPError.httpError(statusCode: httpResponse.statusCode, data: data)
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw HTTPError.decodingError(underlying: error)
        }
    }

    func request(_ endpoint: HTTPEndpoint) async throws {
        let urlRequest = try buildURLRequest(for: endpoint)

        let (_, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw HTTPError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw HTTPError.httpError(statusCode: httpResponse.statusCode, data: nil)
        }
    }

    private func buildURLRequest(for endpoint: HTTPEndpoint) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint.path)

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body

        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Apply custom headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

/// HTTP errors
enum HTTPError: Error, Equatable {
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(underlying: Error)
    case networkError(underlying: Error)

    static func == (lhs: HTTPError, rhs: HTTPError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse):
            return true
        case (.httpError(let lhsCode, _), .httpError(let rhsCode, _)):
            return lhsCode == rhsCode
        case (.decodingError, .decodingError):
            return true
        case (.networkError, .networkError):
            return true
        default:
            return false
        }
    }
}
