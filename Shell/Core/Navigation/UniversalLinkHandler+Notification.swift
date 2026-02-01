//
//  UniversalLinkHandler+Notification.swift
//  Shell
//
//  Created by Shell on 2026-01-30.
//

import Foundation

extension Notification.Name {
    /// Posted when a Universal Link is received
    /// UserInfo contains "url" key with the URL value
    static let handleUniversalLink = Notification.Name("handleUniversalLink")
}
