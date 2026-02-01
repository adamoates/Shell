//
//  CompleteIdentitySetupUseCaseTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-30.
//

import XCTest
@testable import Shell

/// Tests for CompleteIdentitySetupUseCase
final class CompleteIdentitySetupUseCaseTests: XCTestCase {
    private var sut: DefaultCompleteIdentitySetupUseCase!
    private var repository: UserProfileRepositoryFake!

    override func setUp() {
        super.setUp()
        repository = UserProfileRepositoryFake()
        sut = DefaultCompleteIdentitySetupUseCase(repository: repository)
    }

    override func tearDown() {
        sut = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testExecute_newProfile_createsProfile() async {
        let calendar = Calendar.current
        let birthday = calendar.date(byAdding: .year, value: -20, to: Date())!
        let identityData = IdentityData(screenName: "testuser", birthday: birthday)

        let profile = await sut.execute(
            userID: "user123",
            identityData: identityData,
            avatarURL: nil
        )

        XCTAssertEqual(profile.userID, "user123")
        XCTAssertEqual(profile.screenName, "testuser")
        XCTAssertEqual(profile.birthday, birthday)
        XCTAssertNil(profile.avatarURL)
        XCTAssertTrue(profile.hasCompletedIdentitySetup)

        // Verify profile was saved
        let saveCount = await repository.getSaveProfileCallCount()
        let savedProfiles = await repository.getSavedProfiles()
        XCTAssertEqual(saveCount, 1)
        XCTAssertEqual(savedProfiles.count, 1)
        XCTAssertEqual(savedProfiles.first?.userID, "user123")
    }

    func testExecute_existingProfile_updatesProfile() async {
        let calendar = Calendar.current
        let oldBirthday = calendar.date(byAdding: .year, value: -25, to: Date())!
        let newBirthday = calendar.date(byAdding: .year, value: -20, to: Date())!

        // Create existing profile
        let existingProfile = UserProfile(
            userID: "user123",
            screenName: "oldname",
            birthday: oldBirthday,
            avatarURL: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        await repository.saveProfile(existingProfile)

        // Update with new identity data
        let newIdentityData = IdentityData(screenName: "newname", birthday: newBirthday)
        let updatedProfile = await sut.execute(
            userID: "user123",
            identityData: newIdentityData,
            avatarURL: nil
        )

        XCTAssertEqual(updatedProfile.userID, "user123")
        XCTAssertEqual(updatedProfile.screenName, "newname")
        XCTAssertEqual(updatedProfile.birthday, newBirthday)
        XCTAssertTrue(updatedProfile.hasCompletedIdentitySetup)

        // Verify profile was saved twice (initial + update)
        let saveCount = await repository.getSaveProfileCallCount()
        XCTAssertEqual(saveCount, 2)
    }

    func testExecute_withAvatarURL_savesAvatarURL() async {
        let calendar = Calendar.current
        let birthday = calendar.date(byAdding: .year, value: -20, to: Date())!
        let identityData = IdentityData(screenName: "testuser", birthday: birthday)
        let avatarURL = URL(string: "https://example.com/avatar.jpg")!

        let profile = await sut.execute(
            userID: "user123",
            identityData: identityData,
            avatarURL: avatarURL
        )

        XCTAssertEqual(profile.avatarURL, avatarURL)
    }
}

// MARK: - Test Doubles

private actor UserProfileRepositoryFake: UserProfileRepository {
    private(set) var profiles: [String: UserProfile] = [:]
    private(set) var saveProfileCallCount = 0
    private(set) var savedProfiles: [UserProfile] = []

    func fetchProfile(userID: String) async -> UserProfile? {
        profiles[userID]
    }

    func saveProfile(_ profile: UserProfile) async {
        saveProfileCallCount += 1
        savedProfiles.append(profile)
        profiles[profile.userID] = profile
    }

    func deleteProfile(userID: String) async {
        profiles.removeValue(forKey: userID)
    }

    func hasCompletedIdentitySetup(userID: String) async -> Bool {
        guard let profile = profiles[userID] else {
            return false
        }
        return profile.hasCompletedIdentitySetup
    }

    // Test helpers
    func getSaveProfileCallCount() async -> Int {
        saveProfileCallCount
    }

    func getSavedProfiles() async -> [UserProfile] {
        savedProfiles
    }
}
