//
//  InMemoryStorageTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-31.
//

import XCTest
@testable import Shell

final class InMemoryStorageTests: XCTestCase {

    // MARK: - Basic Storage Tests

    func testStoreAndRetrieve() async throws {
        let storage = InMemoryStorage<String, Int>()

        try await storage.store(42, forKey: "answer")
        let retrieved = await storage.retrieve(forKey: "answer")

        XCTAssertEqual(retrieved, 42)
    }

    func testRetrieveNonExistentKey() async {
        let storage = InMemoryStorage<String, Int>()

        let retrieved = await storage.retrieve(forKey: "missing")

        XCTAssertNil(retrieved)
    }

    func testOverwriteValue() async throws {
        let storage = InMemoryStorage<String, String>()

        try await storage.store("first", forKey: "key")
        try await storage.store("second", forKey: "key")

        let retrieved = await storage.retrieve(forKey: "key")

        XCTAssertEqual(retrieved, "second")
    }

    func testRemove() async throws {
        let storage = InMemoryStorage<String, Int>()

        try await storage.store(100, forKey: "temp")
        try await storage.remove(forKey: "temp")

        let retrieved = await storage.retrieve(forKey: "temp")

        XCTAssertNil(retrieved)
    }

    func testRemoveAll() async throws {
        let storage = InMemoryStorage<String, Int>()

        try await storage.store(1, forKey: "one")
        try await storage.store(2, forKey: "two")
        try await storage.store(3, forKey: "three")

        try await storage.removeAll()

        let one = await storage.retrieve(forKey: "one")
        let two = await storage.retrieve(forKey: "two")
        let three = await storage.retrieve(forKey: "three")

        XCTAssertNil(one)
        XCTAssertNil(two)
        XCTAssertNil(three)
    }

    func testContains() async throws {
        let storage = InMemoryStorage<String, Int>()

        try await storage.store(5, forKey: "exists")

        let exists = await storage.contains(key: "exists")
        let missing = await storage.contains(key: "missing")

        XCTAssertTrue(exists)
        XCTAssertFalse(missing)
    }

    func testAllKeys() async throws {
        let storage = InMemoryStorage<String, Int>()

        try await storage.store(1, forKey: "a")
        try await storage.store(2, forKey: "b")
        try await storage.store(3, forKey: "c")

        let keys = await storage.allKeys()

        XCTAssertEqual(Set(keys), Set(["a", "b", "c"]))
    }

    // MARK: - Generic Type Tests

    func testStorageWithCustomTypes() async throws {
        struct User: Sendable, Equatable {
            let id: String
            let name: String
        }

        let storage = InMemoryStorage<String, User>()
        let user = User(id: "123", name: "Alice")

        try await storage.store(user, forKey: "user123")
        let retrieved = await storage.retrieve(forKey: "user123")

        XCTAssertEqual(retrieved, user)
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAccess() async throws {
        let storage = InMemoryStorage<Int, String>()

        // Store multiple values concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask {
                    try? await storage.store("value\(i)", forKey: i)
                }
            }
        }

        // Verify all values stored
        let keys = await storage.allKeys()
        XCTAssertEqual(keys.count, 100)
    }
}

final class InMemoryCacheTests: XCTestCase {

    // MARK: - Basic Cache Tests

    func testCacheStoreAndRetrieve() async throws {
        let cache = InMemoryCache<String, String>(timeToLive: 10)

        try await cache.store("cached", forKey: "key")
        let retrieved = await cache.retrieve(forKey: "key")

        XCTAssertEqual(retrieved, "cached")
    }

    func testCacheExpiration() async throws {
        let cache = InMemoryCache<String, String>(timeToLive: 0.1) // 100ms TTL

        try await cache.store("expires", forKey: "key")

        // Wait for expiration
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        let retrieved = await cache.retrieve(forKey: "key")

        XCTAssertNil(retrieved, "Cached value should have expired")
    }

    func testCacheCustomExpiration() async throws {
        let cache = InMemoryCache<String, String>(timeToLive: 10) // Default 10s

        try await cache.store("short", forKey: "key", expiresIn: 0.1) // Custom 100ms

        // Wait for custom expiration
        try await Task.sleep(nanoseconds: 200_000_000) // 200ms

        let retrieved = await cache.retrieve(forKey: "key")

        XCTAssertNil(retrieved, "Custom expiration should have occurred")
    }

    func testCacheContainsExpiredKey() async throws {
        let cache = InMemoryCache<String, Int>(timeToLive: 0.1)

        try await cache.store(42, forKey: "expires")

        // Before expiration
        let existsBefore = await cache.contains(key: "expires")
        XCTAssertTrue(existsBefore)

        // Wait for expiration
        try await Task.sleep(nanoseconds: 200_000_000)

        // After expiration
        let existsAfter = await cache.contains(key: "expires")
        XCTAssertFalse(existsAfter, "Expired key should not exist")
    }

    func testCacheAllKeysExcludesExpired() async throws {
        let cache = InMemoryCache<String, Int>(timeToLive: 0.1)

        try await cache.store(1, forKey: "expires")
        try await cache.store(2, forKey: "lasts", expiresIn: 10) // Won't expire

        // Wait for first to expire
        try await Task.sleep(nanoseconds: 200_000_000)

        let keys = await cache.allKeys()

        XCTAssertEqual(keys, ["lasts"], "Only non-expired keys should be returned")
    }

    func testCleanupExpired() async throws {
        let cache = InMemoryCache<String, Int>(timeToLive: 0.1)

        try await cache.store(1, forKey: "a")
        try await cache.store(2, forKey: "b")
        try await cache.store(3, forKey: "c", expiresIn: 10) // Won't expire

        // Wait for expiration
        try await Task.sleep(nanoseconds: 200_000_000)

        await cache.cleanupExpired()

        let keys = await cache.allKeys()

        XCTAssertEqual(keys, ["c"], "Cleanup should remove expired entries")
    }

    // MARK: - Performance Tests

    func testCachePerformance() async throws {
        let cache = InMemoryCache<Int, String>(timeToLive: 60)

        measure {
            Task {
                for i in 0..<1000 {
                    try? await cache.store("value\(i)", forKey: i)
                }
            }
        }
    }
}
