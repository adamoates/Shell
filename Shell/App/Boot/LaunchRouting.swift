//
//  LaunchRouting.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Protocol for routing based on launch state
///
/// This is the seam between Boot (orchestration) and Coordinators (navigation).
/// Coordinators implement this to start the appropriate flow.
protocol LaunchRouting {
    /// Route to the specified launch state
    /// - Parameter state: The launch state to route to
    func route(to state: LaunchState)
}
