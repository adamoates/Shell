//
//  SessionStatus.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Represents the status of a user session
///
/// This is a domain concept, UI-agnostic.
/// Coordinators translate SessionStatus → LaunchState → navigation.
enum SessionStatus: Equatable {
    /// User is authenticated with a valid session
    case authenticated

    /// User is not authenticated (no session or expired)
    case unauthenticated

    /// User session exists but is locked (requires biometric unlock)
    case locked
}
