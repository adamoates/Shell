//
//  UserProfileEntity+Mapping.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import CoreData
import Foundation

/// Mapping extension to convert between NSManagedObject and Domain Entity
///
/// This follows the same pattern as ProfileAPI.toDomain() for consistency with
/// the existing HTTP repository implementation.
extension UserProfileEntity {
    /// Convert NSManagedObject to Domain Entity
    ///
    /// - Returns: Domain UserProfile struct
    nonisolated func toDomain() -> UserProfile {
        UserProfile(
            userID: userID,
            screenName: screenName,
            birthday: birthday,
            avatarURL: avatarURL.flatMap { URL(string: $0) },  // String? -> URL?
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Create NSManagedObject from Domain Entity
    ///
    /// Used for create operations when inserting a new profile into Core Data.
    ///
    /// - Parameters:
    ///   - profile: Domain UserProfile to convert
    ///   - context: Managed object context to insert into
    /// - Returns: New UserProfileEntity managed object
    nonisolated static func fromDomain(_ profile: UserProfile, in context: NSManagedObjectContext) -> UserProfileEntity {
        let entity = UserProfileEntity(context: context)
        entity.userID = profile.userID
        entity.screenName = profile.screenName
        entity.birthday = profile.birthday
        entity.avatarURL = profile.avatarURL?.absoluteString
        entity.createdAt = profile.createdAt
        entity.updatedAt = profile.updatedAt
        return entity
    }

    /// Update existing NSManagedObject from Domain Entity
    ///
    /// Used for update operations to modify an existing profile in Core Data.
    ///
    /// - Parameter profile: Domain UserProfile with updated values
    nonisolated func updateFromDomain(_ profile: UserProfile) {
        // Update mutable fields only
        self.screenName = profile.screenName
        self.birthday = profile.birthday
        self.avatarURL = profile.avatarURL?.absoluteString
        self.updatedAt = profile.updatedAt
        // Note: userID and createdAt are immutable and not updated
    }
}
