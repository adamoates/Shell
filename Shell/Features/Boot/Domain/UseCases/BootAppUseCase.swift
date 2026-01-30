//
//  BootAppUseCase.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Protocol for the BootApp use case
///
/// Responsibilities:
/// - Load application configuration
/// - Restore user session if available
/// - Determine initial navigation route
protocol BootAppUseCase: AnyObject {
    /// Execute the boot sequence
    /// - Returns: Boot result containing configuration and initial route
    /// - Throws: If critical configuration cannot be loaded
    func execute() async throws -> BootResult
}

// MARK: - Default Implementation

/// Default implementation of BootAppUseCase
final class DefaultBootAppUseCase: BootAppUseCase {
    // MARK: - Properties

    private let configLoader: ConfigLoader
    private let sessionRepository: SessionRepository

    // MARK: - Initialization

    init(
        configLoader: ConfigLoader,
        sessionRepository: SessionRepository
    ) {
        self.configLoader = configLoader
        self.sessionRepository = sessionRepository
    }

    // MARK: - BootAppUseCase

    func execute() async throws -> BootResult {
        // 1. Load configuration (critical - throws if fails)
        let config = try await configLoader.loadConfig()

        // 2. Try to restore session (non-critical - falls back to guest)
        let session = try? await sessionRepository.getCurrentSession()

        // 3. Validate session if present
        let validSession = session?.isValid == true ? session : nil

        // 4. Determine initial route
        let initialRoute: BootResult.InitialRoute = validSession != nil ? .authenticated : .guest

        return BootResult(
            initialRoute: initialRoute,
            config: config,
            session: validSession
        )
    }
}
