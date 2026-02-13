//
//  UIViewController+OfflineMonitoring.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import UIKit

/// Extension to add offline monitoring capabilities to any ViewController
extension UIViewController {

    /// Add offline monitoring banner to the view controller
    /// - Parameter networkMonitor: The network monitor to observe
    /// - Returns: The offline banner view for customization
    @discardableResult
    func addOfflineMonitoring(networkMonitor: NetworkMonitor) -> OfflineBannerView {
        let banner = OfflineBannerView()
        view.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        // Start monitoring network status
        Task {
            for await isConnected in await networkMonitor.connectivityStream() {
                await MainActor.run {
                    if isConnected {
                        banner.hide()
                    } else {
                        banner.show()
                    }
                }
            }
        }

        return banner
    }
}
