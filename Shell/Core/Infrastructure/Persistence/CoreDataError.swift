//
//  CoreDataError.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import Foundation

/// Errors that can occur during Core Data operations
enum CoreDataError: LocalizedError {
    case storeLoadFailed(underlying: Error)
    case saveFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case entityNotFound
    case invalidContext

    var errorDescription: String? {
        switch self {
        case .storeLoadFailed(let error):
            return "Failed to load persistent store: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save changes: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .entityNotFound:
            return "Entity not found in database"
        case .invalidContext:
            return "Invalid managed object context"
        }
    }
}
