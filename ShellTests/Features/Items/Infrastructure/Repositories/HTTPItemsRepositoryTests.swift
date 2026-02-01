//
//  HTTPItemsRepositoryTests.swift
//  ShellTests
//
//  Created by Shell on 2026-02-01.
//

import XCTest
@testable import Shell

@MainActor
final class HTTPItemsRepositoryTests: XCTestCase {

    var repository: HTTPItemsRepository!
    var mockURLSession: URLSession!

    override func setUp() async throws {
        // Configure URLSession with mock protocol
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockURLSession = URLSession(configuration: configuration)

        let httpClient = URLSessionItemsHTTPClient(
            session: mockURLSession,
            baseURL: URL(string: "http://localhost:3000")!
        )
        repository = HTTPItemsRepository(httpClient: httpClient)

        // Reset mock
        MockURLProtocol.reset()
    }

    override func tearDown() {
        repository = nil
        mockURLSession = nil
        MockURLProtocol.reset()
    }

    // MARK: - fetchAll Tests

    func testFetchAllSuccess() async throws {
        // Given
        let jsonResponse = """
        [
            {
                "id": "test-id-1",
                "name": "Buy QQQ calls",
                "description": "0DTE scalp",
                "is_completed": false,
                "created_at": "2026-02-01T07:17:39.150Z",
                "updated_at": "2026-02-01T07:17:39.150Z"
            },
            {
                "id": "test-id-2",
                "name": "Review AAPL earnings",
                "description": "Check quarterly results",
                "is_completed": true,
                "created_at": "2026-02-01T07:18:00.000Z",
                "updated_at": "2026-02-01T07:18:00.000Z"
            }
        ]
        """.data(using: .utf8)!

        MockURLProtocol.mockResponse = (jsonResponse, HTTPURLResponse(
            url: URL(string: "http://localhost:3000/v1/items")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!, nil)

        // When
        let items = try await repository.fetchAll()

        // Then
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].id, "test-id-1")
        XCTAssertEqual(items[0].name, "Buy QQQ calls")
        XCTAssertEqual(items[0].description, "0DTE scalp")
        XCTAssertEqual(items[0].isCompleted, false)
        XCTAssertEqual(items[1].id, "test-id-2")
        XCTAssertEqual(items[1].isCompleted, true)
    }

    func testFetchAllEmptyArray() async throws {
        // Given
        let jsonResponse = "[]".data(using: .utf8)!

        MockURLProtocol.mockResponse = (jsonResponse, HTTPURLResponse(
            url: URL(string: "http://localhost:3000/v1/items")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!, nil)

        // When
        let items = try await repository.fetchAll()

        // Then
        XCTAssertEqual(items.count, 0)
    }

    func testFetchAllServerError() async throws {
        // Given
        MockURLProtocol.mockResponse = (Data(), HTTPURLResponse(
            url: URL(string: "http://localhost:3000/v1/items")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!, nil)

        // When/Then
        do {
            _ = try await repository.fetchAll()
            XCTFail("Should throw error")
        } catch let error as ItemError {
            XCTAssertEqual(error, .createFailed)
        }
    }

    // MARK: - create Tests

    func testCreateSuccess() async throws {
        // Given
        let newItem = Item(
            id: UUID().uuidString,
            name: "New Item",
            description: "Test description",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let jsonResponse = """
        {
            "id": "generated-id",
            "name": "New Item",
            "description": "Test description",
            "is_completed": false,
            "created_at": "2026-02-01T07:20:00.000Z",
            "updated_at": "2026-02-01T07:20:00.000Z"
        }
        """.data(using: .utf8)!

        MockURLProtocol.mockResponse = (jsonResponse, HTTPURLResponse(
            url: URL(string: "http://localhost:3000/v1/items")!,
            statusCode: 201,
            httpVersion: nil,
            headerFields: nil
        )!, nil)

        // When
        let createdItem = try await repository.create(newItem)

        // Then
        XCTAssertEqual(createdItem.id, "generated-id")
        XCTAssertEqual(createdItem.name, "New Item")
        XCTAssertEqual(createdItem.description, "Test description")
        XCTAssertEqual(createdItem.isCompleted, false)
    }

    func testCreateValidationError() async throws {
        // Given
        let newItem = Item(
            id: UUID().uuidString,
            name: "",
            description: "Test",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        MockURLProtocol.mockResponse = (Data(), HTTPURLResponse(
            url: URL(string: "http://localhost:3000/v1/items")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )!, nil)

        // When/Then
        do {
            _ = try await repository.create(newItem)
            XCTFail("Should throw error")
        } catch let error as ItemError {
            XCTAssertEqual(error, .validationFailed("Invalid request"))
        }
    }

    // MARK: - update Tests

    func testUpdateSuccess() async throws {
        // Given
        let updatedItem = Item(
            id: "existing-id",
            name: "Updated Item",
            description: "Updated description",
            isCompleted: true,
            createdAt: Date(),
            updatedAt: Date()
        )

        let jsonResponse = """
        {
            "id": "existing-id",
            "name": "Updated Item",
            "description": "Updated description",
            "is_completed": true,
            "created_at": "2026-02-01T07:00:00.000Z",
            "updated_at": "2026-02-01T07:25:00.000Z"
        }
        """.data(using: .utf8)!

        MockURLProtocol.mockResponse = (jsonResponse, HTTPURLResponse(
            url: URL(string: "http://localhost:3000/v1/items/existing-id")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!, nil)

        // When
        let result = try await repository.update(updatedItem)

        // Then
        XCTAssertEqual(result.id, "existing-id")
        XCTAssertEqual(result.name, "Updated Item")
        XCTAssertEqual(result.isCompleted, true)
    }

    func testUpdateNotFound() async throws {
        // Given
        let item = Item(
            id: "nonexistent-id",
            name: "Test",
            description: "Test",
            isCompleted: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        MockURLProtocol.mockResponse = (Data(), HTTPURLResponse(
            url: URL(string: "http://localhost:3000/v1/items/nonexistent-id")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!, nil)

        // When/Then
        do {
            _ = try await repository.update(item)
            XCTFail("Should throw error")
        } catch let error as ItemError {
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: - delete Tests

    func testDeleteSuccess() async throws {
        // Given
        MockURLProtocol.mockResponse = (Data(), HTTPURLResponse(
            url: URL(string: "http://localhost:3000/v1/items/test-id")!,
            statusCode: 204,
            httpVersion: nil,
            headerFields: nil
        )!, nil)

        // When/Then
        try await repository.delete(id: "test-id")
        // Success - no error thrown
    }

    func testDeleteNotFound() async throws {
        // Given
        MockURLProtocol.mockResponse = (Data(), HTTPURLResponse(
            url: URL(string: "http://localhost:3000/v1/items/nonexistent")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )!, nil)

        // When/Then
        do {
            try await repository.delete(id: "nonexistent")
            XCTFail("Should throw error")
        } catch let error as ItemError {
            XCTAssertEqual(error, .notFound)
        }
    }
}

// MARK: - MockURLProtocol

class MockURLProtocol: URLProtocol {
    static var mockResponse: (Data, HTTPURLResponse, Error?)?

    static func reset() {
        mockResponse = nil
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let (data, response, error) = Self.mockResponse else {
            fatalError("Mock response not set")
        }

        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
        }

        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
        // No-op
    }
}
