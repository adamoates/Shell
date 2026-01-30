//
//  LaunchState.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Represents the app's launch state after boot orchestration
///
/// This is UI-agnostic - it describes app state, not screens.
/// Coordinators translate LaunchState → navigation flows.
enum LaunchState: Equatable {
    /// User is authenticated and session is valid
    case authenticated

    /// User is not authenticated (guest mode)
    case unauthenticated

    /// User session is locked (biometric gate required)
    case locked

    /// App is in maintenance mode
    case maintenance

    /// Boot failed with an error
    case failure(message: String)
}
