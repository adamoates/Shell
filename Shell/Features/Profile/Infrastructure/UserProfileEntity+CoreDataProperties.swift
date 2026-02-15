//
//  UserProfileEntity+CoreDataProperties.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import CoreData
import Foundation

extension UserProfileEntity {
    @nonobjc nonisolated public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        return NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }

    @NSManaged public var userID: String
    @NSManaged public var screenName: String
    @NSManaged public var birthday: Date
    @NSManaged public var avatarURL: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

extension UserProfileEntity: Identifiable {}
