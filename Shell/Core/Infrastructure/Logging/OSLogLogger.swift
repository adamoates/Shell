//
//  OSLogLogger.swift
//  Shell
//
//  Created by Shell on 2026-02-02.
//

import Foundation
import os

/// OSLog-based implementation of Logger protocol
/// Integrates with Apple's unified logging system for system-wide log collection
final class OSLogLogger: Logger {
    private let subsystem: String
    private let defaultCategory: String

    /// Initialize OSLogLogger
    /// - Parameters:
    ///   - subsystem: The subsystem identifier (typically bundle identifier)
    ///   - defaultCategory: Default category when none is specified
    init(subsystem: String, defaultCategory: String = "general") {
        self.subsystem = subsystem
        self.defaultCategory = defaultCategory
    }

    // MARK: - Logger Protocol Implementation

    func debug(_ message: String, category: String?, context: [String: String]?) {
        log(message, level: .debug, category: category, context: context)
    }

    func info(_ message: String, category: String?, context: [String: String]?) {
        log(message, level: .info, category: category, context: context)
    }

    func warning(_ message: String, category: String?, context: [String: String]?) {
        log(message, level: .default, category: category, context: context)
    }

    func error(_ message: String, category: String?, context: [String: String]?) {
        log(message, level: .error, category: category, context: context)
    }

    func fault(_ message: String, category: String?, context: [String: String]?) {
        log(message, level: .fault, category: category, context: context)
    }

    // MARK: - Private Helpers

    private func log(
        _ message: String,
        level: OSLogType,
        category: String?,
        context: [String: String]?
    ) {
        let categoryName = category ?? defaultCategory
        let logger = os.Logger(subsystem: subsystem, category: categoryName)

        // Format message with context if provided
        let formattedMessage: String
        if let context = context, !context.isEmpty {
            let contextString = context
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            formattedMessage = "\(message) [\(contextString)]"
        } else {
            formattedMessage = message
        }

        // Log at appropriate level
        logger.log(level: level, "\(formattedMessage)")
    }
}
