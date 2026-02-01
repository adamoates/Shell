//
//  StorageProtocol.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation

/// Protocol-oriented storage abstraction demonstrating:
/// - Associated types for flexibility
/// - Generic constraints
/// - Async/await for thread-safe operations
/// - Protocol composition
protocol Storage: Sendable {
    /// The type of keys used for storage
    associatedtype Key: Hashable & Sendable

    /// The type of values stored
    associatedtype Value: Sendable

    /// Store a value for a given key
    /// - Parameters:
    ///   - value: The value to store
    ///   - key: The key to associate with the value
    func store(_ value: Value, forKey key: Key) async throws

    /// Retrieve a value for a given key
    /// - Parameter key: The key to look up
    /// - Returns: The stored value, or nil if not found
    func retrieve(forKey key: Key) async -> Value?

    /// Remove a value for a given key
    /// - Parameter key: The key to remove
    func remove(forKey key: Key) async throws

    /// Remove all stored values
    func removeAll() async throws

    /// Check if a key exists
    /// - Parameter key: The key to check
    /// - Returns: True if the key exists
    func contains(key: Key) async -> Bool

    /// Get all stored keys
    /// - Returns: Array of all keys
    func allKeys() async -> [Key]
}

/// Specialized storage for items with expiration
protocol CacheStorage: Storage {
    /// Time-to-live for cached items
    var timeToLive: TimeInterval { get }

    /// Store a value with custom expiration
    /// - Parameters:
    ///   - value: The value to store
    ///   - key: The key to associate with the value
    ///   - expiresIn: Custom expiration time (overrides default TTL)
    func store(_ value: Value, forKey key: Key, expiresIn: TimeInterval) async throws
}
