//
//  ItemDTO.swift
//  Shell
//
//  Created by Shell on 2026-02-01.
//

import Foundation

/// Data Transfer Object for Item API responses
/// Maps between backend JSON and domain Item entity
struct ItemDTO: Codable, Sendable {
    let id: String
    let name: String
    let description: String
    let isCompleted: Bool
    let createdAt: Date
    let updatedAt: Date

    /// Convert DTO to domain Item entity
    func toDomain() -> Item {
        Item(
            id: id,
            name: name,
            description: description,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Convert domain Item entity to DTO
    static func fromDomain(_ item: Item) -> ItemDTO {
        ItemDTO(
            id: item.id,
            name: item.name,
            description: item.description,
            isCompleted: item.isCompleted,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt
        )
    }
}

/// Request DTO for creating/updating items
struct ItemRequestDTO: Codable, Sendable {
    let name: String
    let description: String
    let isCompleted: Bool

    init(name: String, description: String, isCompleted: Bool) {
        self.name = name
        self.description = description
        self.isCompleted = isCompleted
    }

    /// Create request DTO from domain Item
    static func fromDomain(_ item: Item) -> ItemRequestDTO {
        ItemRequestDTO(
            name: item.name,
            description: item.description,
            isCompleted: item.isCompleted
        )
    }
}
