//
//  Credentials.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Domain entity representing user credentials for authentication
///
/// SECURITY NOTE:
/// - Passwords are stored as String in memory (unavoidable with Swift/UIKit TextField API)
/// - NEVER log, print, or persist passwords to disk
/// - NEVER store Credentials in @Published properties or long-lived state
/// - Create Credentials immediately before validation/authentication
/// - Let ARC deallocate immediately after use
/// - All network transmission MUST use HTTPS (enforced by ATS in Info.plist)
///
/// Usage:
/// ```swift
/// // ✅ CORRECT: Create, validate, discard
/// let credentials = Credentials(username: username, password: password)
/// try await authenticate(credentials: credentials)
/// // credentials deallocated here
///
/// // ❌ WRONG: Storing credentials
/// @Published var credentials: Credentials? // Don't do this!
/// ```
struct Credentials: Equatable {
    let username: String

    /// Password is stored temporarily in memory for authentication
    /// WARNING: Never log, persist, or store in long-lived state
    let password: String
}
