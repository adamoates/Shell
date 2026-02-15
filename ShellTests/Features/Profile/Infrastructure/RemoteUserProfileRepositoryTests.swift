//
//  RemoteUserProfileRepositoryTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for RemoteUserProfileRepository
/// Verifies HTTP API integration with mock responses
final class RemoteUserProfileRepositoryTests: XCTestCase {
    private var sut: RemoteUserProfileRepository!
    private var mockHTTPClient: MockHTTPClient!
    private let baseURL = URL(string: "https://api.shell.app/v1")!

    // MARK: - Test Doubles

    private struct NoOpLogger: Logger {
        func debug(_ message: String, category: String?, context: [String: String]?) {}
        func info(_ message: String, category: String?, context: [String: String]?) {}
        func warning(_ message: String, category: String?, context: [String: String]?) {}
        func error(_ message: String, category: String?, context: [String: String]?) {}
        func fault(_ message: String, category: String?, context: [String: String]?) {}
    }

    override func setUp() {
        super.setUp()
        mockHTTPClient = MockHTTPClient()
        sut = RemoteUserProfileRepository(
            httpClient: mockHTTPClient,
            baseURL: baseURL,
            authToken: "test-token",
            logger: NoOpLogger()
        )
    }

    override func tearDown() {
        sut = nil
        mockHTTPClient = nil
        super.tearDown()
    }

    // MARK: - Fetch Profile Tests

    func testFetchProfile_success_returnsProfile() async {
        // Arrange
        let jsonResponse = """
        {
            "userID": "user123",
            "screenName": "trader123",
            "birthday": "1990-05-15",
            "avatarURL": "https://cdn.shell.app/avatar.jpg",
            "createdAt": "2026-01-30T12:00:00Z",
            "updatedAt": "2026-01-30T12:00:00Z"
        }
        """.data(using: .utf8)!

        mockHTTPClient.stubSuccess(urlPattern: "/users/user123/profile", json: jsonResponse)

        // Act
        let profile = await sut.fetchProfile(userID: "user123")

        // Assert
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.userID, "user123")
        XCTAssertEqual(profile?.screenName, "trader123")
        XCTAssertEqual(profile?.avatarURL?.absoluteString, "https://cdn.shell.app/avatar.jpg")

        // Verify HTTP request
        XCTAssertEqual(mockHTTPClient.getRequestCount(), 1)
        let request = mockHTTPClient.getLastRequest()
        XCTAssertEqual(request?.method, .get)
        XCTAssertTrue(request?.url.absoluteString.contains("/users/user123/profile") ?? false)
        XCTAssertEqual(request?.headers["Authorization"], "Bearer test-token")
    }

    func testFetchProfile_notFound_returnsNil() async {
        // Arrange
        mockHTTPClient.stub404(urlPattern: "/users/user123/profile")

        // Act
        let profile = await sut.fetchProfile(userID: "user123")

        // Assert
        XCTAssertNil(profile)
    }

    func testFetchProfile_networkError_returnsNil() async {
        // Arrange
        mockHTTPClient.stubError(
            urlPattern: "/users/user123/profile",
            error: .networkError(NSError(domain: "test", code: -1))
        )

        // Act
        let profile = await sut.fetchProfile(userID: "user123")

        // Assert
        XCTAssertNil(profile)
    }

    // MARK: - Save Profile Tests

    func testSaveProfile_success_sendsCorrectRequest() async {
        // Arrange
        let calendar = Calendar.current
        let birthday = calendar.date(from: DateComponents(year: 1990, month: 5, day: 15))!

        let profile = UserProfile(
            userID: "user123",
            screenName: "trader123",
            birthday: birthday,
            avatarURL: URL(string: "https://cdn.shell.app/avatar.jpg"),
            createdAt: Date(),
            updatedAt: Date()
        )

        let jsonResponse = """
        {
            "userID": "user123",
            "screenName": "trader123",
            "birthday": "1990-05-15",
            "avatarURL": "https://cdn.shell.app/avatar.jpg",
            "createdAt": "2026-01-30T12:00:00Z",
            "updatedAt": "2026-01-30T12:00:00Z"
        }
        """.data(using: .utf8)!

        mockHTTPClient.stubSuccess(urlPattern: "/users/user123/profile", statusCode: 200, json: jsonResponse)

        // Act
        await sut.saveProfile(profile)

        // Assert
        XCTAssertEqual(mockHTTPClient.getRequestCount(), 1)
        let request = mockHTTPClient.getLastRequest()
        XCTAssertEqual(request?.method, .put)
        XCTAssertTrue(request?.url.absoluteString.contains("/users/user123/profile") ?? false)
        XCTAssertEqual(request?.headers["Authorization"], "Bearer test-token")
        XCTAssertEqual(request?.headers["Content-Type"], "application/json")
        XCTAssertNotNil(request?.body)

        // Verify request body
        if let body = request?.body,
           let requestBody = try? JSONDecoder().decode(ProfileAPI.CreateProfileRequest.self, from: body) {
            XCTAssertEqual(requestBody.screenName, "trader123")
            XCTAssertEqual(requestBody.birthday, "1990-05-15")
            XCTAssertEqual(requestBody.avatarURL, "https://cdn.shell.app/avatar.jpg")
        } else {
            XCTFail("Failed to decode request body")
        }
    }

    // MARK: - Delete Profile Tests

    func testDeleteProfile_success_sendsCorrectRequest() async {
        // Arrange
        let emptyResponse = Data()
        mockHTTPClient.stubSuccess(urlPattern: "/users/user123/profile", statusCode: 204, json: emptyResponse)

        // Act
        await sut.deleteProfile(userID: "user123")

        // Assert
        XCTAssertEqual(mockHTTPClient.getRequestCount(), 1)
        let request = mockHTTPClient.getLastRequest()
        XCTAssertEqual(request?.method, .delete)
        XCTAssertTrue(request?.url.absoluteString.contains("/users/user123/profile") ?? false)
    }

    // MARK: - Identity Status Tests

    func testHasCompletedIdentitySetup_true_returnsTrue() async {
        // Arrange
        let jsonResponse = """
        {
            "hasCompletedIdentitySetup": true
        }
        """.data(using: .utf8)!

        mockHTTPClient.stubSuccess(urlPattern: "/users/user123/identity-status", json: jsonResponse)

        // Act
        let hasCompleted = await sut.hasCompletedIdentitySetup(userID: "user123")

        // Assert
        XCTAssertTrue(hasCompleted)
    }

    func testHasCompletedIdentitySetup_false_returnsFalse() async {
        // Arrange
        let jsonResponse = """
        {
            "hasCompletedIdentitySetup": false
        }
        """.data(using: .utf8)!

        mockHTTPClient.stubSuccess(urlPattern: "/users/user123/identity-status", json: jsonResponse)

        // Act
        let hasCompleted = await sut.hasCompletedIdentitySetup(userID: "user123")

        // Assert
        XCTAssertFalse(hasCompleted)
    }

    func testHasCompletedIdentitySetup_networkError_returnsFalse() async {
        // Arrange
        mockHTTPClient.stubError(
            urlPattern: "/users/user123/identity-status",
            error: .networkError(NSError(domain: "test", code: -1))
        )

        // Act
        let hasCompleted = await sut.hasCompletedIdentitySetup(userID: "user123")

        // Assert
        XCTAssertFalse(hasCompleted)
    }
}
