//
//  Logger.swift
//  Shell
//
//  Created by Shell on 2026-02-02.
//

import Foundation

/// Log severity levels matching Apple's OSLog levels
public enum LogLevel: String, Sendable {
    case debug
    case info
    case warning
    case error
    case fault
}

/// Protocol for application-wide logging abstraction
///
/// Implementations might use:
/// - OSLog for system-integrated logging
/// - Console for development debugging
/// - Remote logging services for production monitoring
public protocol Logger: Sendable {
    /// Log a debug message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category for organizing logs (e.g., "network", "auth", "ui")
    ///   - context: Optional key-value pairs for structured logging
    func debug(_ message: String, category: String?, context: [String: String]?)

    /// Log an informational message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category for organizing logs
    ///   - context: Optional key-value pairs for structured logging
    func info(_ message: String, category: String?, context: [String: String]?)

    /// Log a warning message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category for organizing logs
    ///   - context: Optional key-value pairs for structured logging
    func warning(_ message: String, category: String?, context: [String: String]?)

    /// Log an error message
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category for organizing logs
    ///   - context: Optional key-value pairs for structured logging
    func error(_ message: String, category: String?, context: [String: String]?)

    /// Log a fault message (critical system failures)
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: Optional category for organizing logs
    ///   - context: Optional key-value pairs for structured logging
    func fault(_ message: String, category: String?, context: [String: String]?)
}

// MARK: - Convenience Extensions

extension Logger {
    /// Log a debug message without category or context
    public func debug(_ message: String) {
        debug(message, category: nil, context: nil)
    }

    /// Log a debug message with category
    public func debug(_ message: String, category: String) {
        debug(message, category: category, context: nil)
    }

    /// Log an info message without category or context
    public func info(_ message: String) {
        info(message, category: nil, context: nil)
    }

    /// Log an info message with category
    public func info(_ message: String, category: String) {
        info(message, category: category, context: nil)
    }

    /// Log a warning message without category or context
    public func warning(_ message: String) {
        warning(message, category: nil, context: nil)
    }

    /// Log a warning message with category
    public func warning(_ message: String, category: String) {
        warning(message, category: category, context: nil)
    }

    /// Log an error message without category or context
    public func error(_ message: String) {
        error(message, category: nil, context: nil)
    }

    /// Log an error message with category
    public func error(_ message: String, category: String) {
        error(message, category: category, context: nil)
    }

    /// Log a fault message without category or context
    public func fault(_ message: String) {
        fault(message, category: nil, context: nil)
    }

    /// Log a fault message with category
    public func fault(_ message: String, category: String) {
        fault(message, category: category, context: nil)
    }
}
