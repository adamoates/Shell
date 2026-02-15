//
//  ItemEntity+CoreDataProperties.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import CoreData
import Foundation

extension ItemEntity {
    @nonobjc nonisolated public class func fetchRequest() -> NSFetchRequest<ItemEntity> {
        return NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var itemDescription: String
    @NSManaged public var isCompleted: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
}

extension ItemEntity: Identifiable {}
