//
//  CoreDataItemsRepository.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import CoreData
import Foundation

/// Core Data implementation of ItemsRepository
///
/// Provides local persistence for items using Core Data. All operations use
/// background contexts to avoid blocking the UI thread.
actor CoreDataItemsRepository: ItemsRepository {
    // MARK: - Properties

    private let stack: CoreDataStack

    // MARK: - Initialization

    init(stack: CoreDataStack) {
        self.stack = stack
    }

    // MARK: - ItemsRepository Protocol

    func fetchAll() async throws -> [Item] {
        try await stack.performBackgroundTask { context in
            let request = ItemEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            do {
                let entities = try context.fetch(request)
                return entities.map { $0.toDomain() }
            } catch {
                throw ItemError.createFailed
            }
        }
    }

    func create(_ item: Item) async throws -> Item {
        try await stack.performBackgroundTask { context in
            // Create new entity from domain model
            let entity = ItemEntity.fromDomain(item, in: context)

            do {
                try context.save()
                return entity.toDomain()
            } catch {
                throw ItemError.createFailed
            }
        }
    }

    func update(_ item: Item) async throws -> Item {
        try await stack.performBackgroundTask { context in
            // Fetch existing entity
            let request = ItemEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", item.id)

            do {
                guard let entity = try context.fetch(request).first else {
                    throw ItemError.notFound
                }

                // Update entity from domain model
                entity.updateFromDomain(item)

                try context.save()
                return entity.toDomain()
            } catch let error as ItemError {
                throw error
            } catch {
                throw ItemError.updateFailed
            }
        }
    }

    func delete(id: String) async throws {
        try await stack.performBackgroundTask { context in
            // Fetch entity to delete
            let request = ItemEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)

            do {
                guard let entity = try context.fetch(request).first else {
                    throw ItemError.notFound
                }

                context.delete(entity)
                try context.save()
            } catch let error as ItemError {
                throw error
            } catch {
                throw ItemError.deleteFailed
            }
        }
    }
}
