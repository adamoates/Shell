//
//  CoreDataUserProfileRepository.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import CoreData
import Foundation

/// Core Data implementation of UserProfileRepository
///
/// Provides local persistence for user profiles using Core Data. All operations use
/// background contexts to avoid blocking the UI thread.
///
/// Note: UserProfileRepository protocol uses optionals instead of throws,
/// so errors are logged but converted to nil returns.
actor CoreDataUserProfileRepository: UserProfileRepository {
    // MARK: - Properties

    private let stack: CoreDataStack
    private let logger: Logger

    // MARK: - Initialization

    init(stack: CoreDataStack, logger: Logger) {
        self.stack = stack
        self.logger = logger
    }

    // MARK: - UserProfileRepository Protocol

    func fetchProfile(userID: String) async -> UserProfile? {
        do {
            return try await stack.performBackgroundTask { context in
                let request = UserProfileEntity.fetchRequest()
                request.predicate = NSPredicate(format: "userID == %@", userID)

                guard let entity = try context.fetch(request).first else {
                    return nil
                }

                return entity.toDomain()
            }
        } catch {
            Task { @MainActor in
                logger.error("Failed to fetch profile: \(error.localizedDescription)", category: "persistence")
            }
            return nil
        }
    }

    func saveProfile(_ profile: UserProfile) async {
        do {
            try await stack.performBackgroundTask { context in
                let request = UserProfileEntity.fetchRequest()
                request.predicate = NSPredicate(format: "userID == %@", profile.userID)

                if let existingEntity = try context.fetch(request).first {
                    // Update existing profile
                    existingEntity.updateFromDomain(profile)
                } else {
                    // Create new profile
                    _ = UserProfileEntity.fromDomain(profile, in: context)
                }

                try context.save()
            }
        } catch {
            Task { @MainActor in
                logger.error("Failed to save profile: \(error.localizedDescription)", category: "persistence")
            }
        }
    }

    func deleteProfile(userID: String) async {
        do {
            try await stack.performBackgroundTask { context in
                let request = UserProfileEntity.fetchRequest()
                request.predicate = NSPredicate(format: "userID == %@", userID)

                if let entity = try context.fetch(request).first {
                    context.delete(entity)
                    try context.save()
                }
            }
        } catch {
            Task { @MainActor in
                logger.error("Failed to delete profile: \(error.localizedDescription)", category: "persistence")
            }
        }
    }

    func hasCompletedIdentitySetup(userID: String) async -> Bool {
        guard let profile = await fetchProfile(userID: userID) else {
            return false
        }
        return !profile.screenName.isEmpty
    }
}
