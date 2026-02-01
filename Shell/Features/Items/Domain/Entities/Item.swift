//
//  Item.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Domain entity representing an item in the list
struct Item: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let date: Date

    init(id: String, title: String, subtitle: String, description: String, date: Date) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.date = date
    }
}
