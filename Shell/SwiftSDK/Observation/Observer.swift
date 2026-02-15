//
//  Observer.swift
//  Shell
//
//  Created by Shell on 2026-01-31.
//

import Foundation

/// Protocol-oriented observer pattern demonstrating:
/// - Weak references to avoid retain cycles
/// - Generic event types
/// - Thread-safe observation
/// - Automatic cleanup of deallocated observers
protocol Observer: AnyObject {
    /// The type of events this observer handles
    associatedtype Event

    /// Called when an event occurs
    /// - Parameter event: The event that occurred
    func handleEvent(_ event: Event)
}

/// Observable subject that manages observers
/// Demonstrates:
/// - Weak reference management to prevent retain cycles
/// - Generic constraints
/// - Thread-safe operations with actor
/// - Automatic cleanup of deallocated observers
actor Observable<Event> {
    // MARK: - Nested Types

    /// Weak wrapper to avoid retain cycles
    /// This is crucial for memory safety - observers are held weakly
    private struct WeakObserver {
        weak var observer: AnyObject?
        let notify: (Event) async -> Void

        var isAlive: Bool {
            observer != nil
        }
    }

    // MARK: - Properties

    private var observers: [UUID: WeakObserver] = [:]

    // MARK: - Initialization

    init() {}

    // MARK: - Observer Management

    /// Add an observer
    /// - Parameter observer: The observer to add
    /// - Returns: Token to remove observer later
    func addObserver<O: Observer>(_ observer: O) -> ObservationToken where O.Event == Event {
        let id = UUID()

        // Capture observer weakly to avoid retain cycle
        let weakObserver = WeakObserver(
            observer: observer
        )            { [weak observer] event in
                await observer?.handleEvent(event)
            }

        observers[id] = weakObserver

        return ObservationToken { [weak self] in
            Task {
                await self?.removeObserver(id: id)
            }
        }
    }

    /// Remove an observer
    /// - Parameter id: The observer ID to remove
    private func removeObserver(id: UUID) {
        observers.removeValue(forKey: id)
    }

    /// Notify all observers of an event
    /// Automatically cleans up deallocated observers
    /// - Parameter event: The event to send to observers
    func notifyObservers(_ event: Event) async {
        // Clean up deallocated observers
        observers = observers.filter { _, weakObserver in
            weakObserver.isAlive
        }

        // Notify remaining observers
        await withTaskGroup(of: Void.self) { group in
            for weakObserver in observers.values {
                group.addTask {
                    await weakObserver.notify(event)
                }
            }
        }
    }

    /// Get count of active observers (for testing)
    func observerCount() -> Int {
        // Clean up first
        observers = observers.filter { _, weakObserver in
            weakObserver.isAlive
        }
        return observers.count
    }
}

/// Token for removing observations
/// Demonstrates:
/// - RAII pattern (automatic cleanup)
/// - Closure capture for cleanup
/// - Sendable for concurrency
final class ObservationToken: Sendable {
    private let cancellationClosure: @Sendable () -> Void

    nonisolated init(cancellationClosure: @escaping @Sendable () -> Void) {
        self.cancellationClosure = cancellationClosure
    }

    /// Cancel the observation
    func cancel() {
        cancellationClosure()
    }

    deinit {
        cancellationClosure()
    }
}

// MARK: - Convenience Observers

/// Closure-based observer for simple use cases
/// Demonstrates:
/// - Closure-based API design
/// - Generic event handling
/// - Reference type for observer protocol
final class ClosureObserver<Event>: Observer {
    private let closure: (Event) -> Void

    init(closure: @escaping (Event) -> Void) {
        self.closure = closure
    }

    func handleEvent(_ event: Event) {
        closure(event)
    }
}

// MARK: - Example: Event Bus

/// Centralized event bus using the observer pattern
/// Demonstrates:
/// - Practical application of observer pattern
/// - Type-safe events
/// - Memory-safe observer management
actor EventBus {
    // MARK: - Nested Types

    enum AppEvent {
        case userLoggedIn(userId: String)
        case userLoggedOut
        case dataUpdated(type: String)
        case errorOccurred(Error)
    }

    // MARK: - Properties

    private let observable = Observable<AppEvent>()

    // MARK: - Shared Instance

    static let shared = EventBus()

    private init() {}

    // MARK: - Public API

    /// Subscribe to app events
    /// - Parameter observer: The observer to add
    /// - Returns: Token to cancel subscription
    func subscribe<O: Observer>(_ observer: O) async -> ObservationToken where O.Event == AppEvent {
        await observable.addObserver(observer)
    }

    /// Publish an event to all subscribers
    /// - Parameter event: The event to publish
    func publish(_ event: AppEvent) async {
        await observable.notifyObservers(event)
    }

    /// Get active subscriber count (for testing)
    func subscriberCount() async -> Int {
        await observable.observerCount()
    }
}
