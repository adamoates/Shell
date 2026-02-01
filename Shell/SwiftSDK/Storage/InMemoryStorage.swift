//
//  InMemoryStorage.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation

/// Thread-safe in-memory storage using Swift actor concurrency
/// Demonstrates:
/// - Actor isolation for automatic thread safety
/// - Generic implementation with type constraints
/// - Sendable conformance for crossing actor boundaries
actor InMemoryStorage<Key: Hashable & Sendable, Value: Sendable>: Storage {
    // MARK: - Properties

    private var storage: [Key: Value] = [:]

    // MARK: - Initialization

    init() {}

    // MARK: - Storage Protocol

    func store(_ value: Value, forKey key: Key) async throws {
        storage[key] = value
    }

    func retrieve(forKey key: Key) async -> Value? {
        storage[key]
    }

    func remove(forKey key: Key) async throws {
        storage.removeValue(forKey: key)
    }

    func removeAll() async throws {
        storage.removeAll()
    }

    func contains(key: Key) async -> Bool {
        storage[key] != nil
    }

    func allKeys() async -> [Key] {
        Array(storage.keys)
    }
}

/// Thread-safe cache with expiration support
/// Demonstrates:
/// - Nested types (CacheEntry)
/// - Optional chaining
/// - Date-based expiration logic
actor InMemoryCache<Key: Hashable & Sendable, Value: Sendable>: CacheStorage {
    // MARK: - Nested Types

    private struct CacheEntry {
        let value: Value
        let expirationDate: Date

        var isExpired: Bool {
            Date() > expirationDate
        }
    }

    // MARK: - Properties

    private var cache: [Key: CacheEntry] = [:]
    let timeToLive: TimeInterval

    // MARK: - Initialization

    init(timeToLive: TimeInterval = 300) { // Default 5 minutes
        self.timeToLive = timeToLive
    }

    // MARK: - Storage Protocol

    func store(_ value: Value, forKey key: Key) async throws {
        try await store(value, forKey: key, expiresIn: timeToLive)
    }

    func retrieve(forKey key: Key) async -> Value? {
        // Clean up expired entry if found
        if let entry = cache[key] {
            if entry.isExpired {
                cache.removeValue(forKey: key)
                return nil
            }
            return entry.value
        }
        return nil
    }

    func remove(forKey key: Key) async throws {
        cache.removeValue(forKey: key)
    }

    func removeAll() async throws {
        cache.removeAll()
    }

    func contains(key: Key) async -> Bool {
        if let entry = cache[key] {
            if entry.isExpired {
                cache.removeValue(forKey: key)
                return false
            }
            return true
        }
        return false
    }

    func allKeys() async -> [Key] {
        // Return only non-expired keys
        let now = Date()
        return cache.compactMap { key, entry in
            entry.expirationDate > now ? key : nil
        }
    }

    // MARK: - CacheStorage Protocol

    func store(_ value: Value, forKey key: Key, expiresIn: TimeInterval) async throws {
        let entry = CacheEntry(
            value: value,
            expirationDate: Date().addingTimeInterval(expiresIn)
        )
        cache[key] = entry
    }

    // MARK: - Cleanup

    /// Remove all expired entries
    func cleanupExpired() async {
        let now = Date()
        cache = cache.filter { _, entry in
            entry.expirationDate > now
        }
    }
}
