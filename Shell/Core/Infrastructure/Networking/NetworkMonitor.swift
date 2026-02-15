//
//  NetworkMonitor.swift
//  Shell
//
//  Created by Shell on 2026-02-12.
//

import Foundation
import Network

/// Monitors network connectivity status
/// Uses NWPathMonitor for real-time network status updates
actor NetworkMonitor {
    // MARK: - Properties

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.shell.networkmonitor")

    private(set) var isConnected: Bool = false
    private var continuations: [UUID: AsyncStream<Bool>.Continuation] = [:]

    // MARK: - Initialization

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task {
                await self?.updateConnectionStatus(path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Public Methods

    /// Stream of connectivity changes
    func connectivityStream() -> AsyncStream<Bool> {
        AsyncStream { continuation in
            let id = UUID()
            continuations[id] = continuation

            // Send current status immediately
            continuation.yield(isConnected)

            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.removeContinuation(id)
                }
            }
        }
    }

    /// Wait for network to become available
    func waitForConnection() async {
        guard !isConnected else { return }

        for await connected in connectivityStream() {
            if connected {
                return
            }
        }
    }

    // MARK: - Private Methods

    private func updateConnectionStatus(_ connected: Bool) {
        isConnected = connected

        // Notify all listeners
        for continuation in continuations.values {
            continuation.yield(connected)
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }
}
