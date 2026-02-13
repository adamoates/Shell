//
//  ItemEntity+Mapping.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import CoreData
import Foundation

/// Mapping extension to convert between NSManagedObject and Domain Entity
///
/// This follows the same pattern as ItemDTO.toDomain() for consistency with
/// the existing HTTP repository implementation.
extension ItemEntity {
    /// Convert NSManagedObject to Domain Entity
    ///
    /// - Returns: Domain Item struct
    nonisolated func toDomain() -> Item {
        Item(
            id: id,
            name: name,
            description: itemDescription,  // Map itemDescription -> description
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Create NSManagedObject from Domain Entity
    ///
    /// Used for create operations when inserting a new item into Core Data.
    ///
    /// - Parameters:
    ///   - item: Domain Item to convert
    ///   - context: Managed object context to insert into
    /// - Returns: New ItemEntity managed object
    nonisolated static func fromDomain(_ item: Item, in context: NSManagedObjectContext) -> ItemEntity {
        let entity = ItemEntity(context: context)
        entity.id = item.id
        entity.name = item.name
        entity.itemDescription = item.description
        entity.isCompleted = item.isCompleted
        entity.createdAt = item.createdAt
        entity.updatedAt = item.updatedAt
        return entity
    }

    /// Update existing NSManagedObject from Domain Entity
    ///
    /// Used for update operations to modify an existing item in Core Data.
    ///
    /// - Parameter item: Domain Item with updated values
    nonisolated func updateFromDomain(_ item: Item) {
        // Update mutable fields only
        self.name = item.name
        self.itemDescription = item.description
        self.isCompleted = item.isCompleted
        self.updatedAt = item.updatedAt
        // Note: id and createdAt are immutable and not updated
    }
}
