//
//  Item.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Domain entity representing an item in the list
/// Schema aligned with backend API (Epic 3)
struct Item: Equatable, Identifiable, Sendable {
    let id: String
    let name: String
    let description: String
    let isCompleted: Bool
    let createdAt: Date
    let updatedAt: Date

    init(
        id: String,
        name: String,
        description: String,
        isCompleted: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
