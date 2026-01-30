//
//  RouteResolver.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Protocol for resolving URLs to routes
/// Maps deep link URLs to type-safe Route enum cases
protocol RouteResolver {
    /// Resolve a URL to a Route
    /// Returns nil if URL cannot be parsed
    func resolve(url: URL) -> Route?
}
