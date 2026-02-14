//
//  HTTPError.swift
//  Shell
//
//  Created by Shell on 2026-02-14.
//

import Foundation

/// HTTP errors for network operations
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
