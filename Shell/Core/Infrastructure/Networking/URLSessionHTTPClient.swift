//
//  URLSessionHTTPClient.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// URLSession-based implementation of HTTPClient
final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func perform(_ request: HTTPRequest) async throws -> HTTPResponse {
        // Create URLRequest
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body

        // Add headers
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // Perform request
        do {
            let (data, response) = try await session.data(for: urlRequest)

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPClientError.invalidResponse
            }

            // Extract headers
            var headers: [String: String] = [:]
            for (key, value) in httpResponse.allHeaderFields {
                if let keyString = key as? String, let valueString = value as? String {
                    headers[keyString] = valueString
                }
            }

            // Check for HTTP errors
            if !(200...299).contains(httpResponse.statusCode) {
                throw HTTPClientError.httpError(statusCode: httpResponse.statusCode, data: data)
            }

            return HTTPResponse(
                statusCode: httpResponse.statusCode,
                data: data,
                headers: headers
            )

        } catch let error as HTTPClientError {
            throw error
        } catch {
            throw HTTPClientError.networkError(error)
        }
    }
}
