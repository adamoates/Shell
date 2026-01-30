//
//  Credentials.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

/// Domain entity representing user credentials for authentication
struct Credentials: Equatable {
    let username: String
    let password: String

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}
