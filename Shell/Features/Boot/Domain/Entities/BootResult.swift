//
//  BootResult.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Result of the boot process
struct BootResult: Equatable {
    /// The initial route to navigate to
    let initialRoute: InitialRoute

    /// Application configuration
    let config: AppConfig

    /// User session (if authenticated)
    let session: UserSession?
}

// MARK: - InitialRoute

extension BootResult {
    enum InitialRoute: Equatable {
        case authenticated
        case guest
    }
}
