//
//  CoreDataStack.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import CoreData
import Foundation

/// Thread-safe Core Data stack wrapper with async/await support
///
/// Provides actor-isolated access to NSPersistentContainer with proper
/// concurrency management for Swift 6 strict concurrency compliance.
actor CoreDataStack {
    // MARK: - Properties

    private let container: NSPersistentContainer
    private let logger: Logger

    /// Main thread view context for UI operations
    /// nonisolated allows cross-actor access since viewContext is MainActor-isolated
    nonisolated var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    // MARK: - Initialization

    /// Initialize Core Data stack with persistent store
    ///
    /// - Parameters:
    ///   - modelName: Name of the .xcdatamodeld file (without extension)
    ///   - inMemory: If true, uses in-memory store for testing; if false, uses SQLite
    ///   - logger: Logger for diagnostics and error reporting
    /// - Throws: CoreDataError.storeLoadFailed if persistent store cannot be loaded
    init(modelName: String, inMemory: Bool = false, logger: Logger) async throws {
        self.logger = logger
        self.container = NSPersistentContainer(name: modelName)

        if inMemory {
            // Use in-memory store for testing (no disk persistence)
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            logger.debug("Core Data stack initialized with in-memory store", category: "persistence")
        } else {
            logger.debug("Core Data stack initialized with persistent store", category: "persistence")
        }

        // Configure merge policy (last write wins)
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        // Load persistent stores asynchronously
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            container.loadPersistentStores { description, error in
                if let error = error {
                    Task { @MainActor in
                        self.logger.error(
                            "Failed to load Core Data persistent store: \(error.localizedDescription)",
                            category: "persistence"
                        )
                    }
                    continuation.resume(throwing: CoreDataError.storeLoadFailed(underlying: error))
                } else {
                    Task { @MainActor in
                        self.logger.info(
                            "Core Data persistent store loaded successfully",
                            category: "persistence",
                            context: ["storeURL": description.url?.absoluteString ?? "unknown"]
                        )
                    }
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Context Management

    /// Create a new background context for async operations
    ///
    /// Background contexts are isolated from the view context and should be used
    /// for all repository operations to avoid blocking the UI.
    ///
    /// - Returns: New background managed object context
    nonisolated func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    /// Perform an async task on a background context
    ///
    /// This is the preferred method for repository operations. It creates a background
    /// context, performs the operation, and automatically handles errors.
    ///
    /// - Parameter block: Async closure to execute on background context
    /// - Returns: Result of the operation
    /// - Throws: Rethrows any error from the block
    func performBackgroundTask<T>(
        _ block: @escaping @Sendable (NSManagedObjectContext) async throws -> T
    ) async throws -> T {
        let context = newBackgroundContext()

        do {
            let result = try await block(context)
            return result
        } catch {
            Task { @MainActor in
                self.logger.error(
                    "Background task failed: \(error.localizedDescription)",
                    category: "persistence"
                )
            }
            throw error
        }
    }

    /// Save a managed object context
    ///
    /// - Parameter context: Context to save
    /// - Throws: CoreDataError.saveFailed if save operation fails
    func save(context: NSManagedObjectContext) async throws {
        guard context.hasChanges else {
            Task { @MainActor in
                logger.debug("No changes to save", category: "persistence")
            }
            return
        }

        do {
            try context.save()
            Task { @MainActor in
                logger.debug("Context saved successfully", category: "persistence")
            }
        } catch {
            Task { @MainActor in
                logger.error("Failed to save context: \(error.localizedDescription)", category: "persistence")
            }
            throw CoreDataError.saveFailed(underlying: error)
        }
    }
}
