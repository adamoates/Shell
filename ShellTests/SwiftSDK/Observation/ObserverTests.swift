//
//  ObserverTests.swift
//  ShellTests
//
//  Created by Shell on 2026-01-31.
//

import XCTest
@testable import Shell

final class ObserverTests: XCTestCase {

    // MARK: - Basic Observer Tests

    func testAddObserverAndNotify() async {
        let observable = Observable<String>()
        var receivedEvents: [String] = []

        let observer = ClosureObserver<String> { event in
            receivedEvents.append(event)
        }

        let token = await observable.addObserver(observer)

        await observable.notifyObservers("Event 1")
        await observable.notifyObservers("Event 2")

        // Give async tasks time to complete
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(receivedEvents, ["Event 1", "Event 2"])

        token.cancel()
    }

    func testMultipleObservers() async {
        let observable = Observable<Int>()
        var observer1Events: [Int] = []
        var observer2Events: [Int] = []

        let observer1 = ClosureObserver<Int> { event in
            observer1Events.append(event)
        }

        let observer2 = ClosureObserver<Int> { event in
            observer2Events.append(event)
        }

        let token1 = await observable.addObserver(observer1)
        let token2 = await observable.addObserver(observer2)

        await observable.notifyObservers(42)

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(observer1Events, [42])
        XCTAssertEqual(observer2Events, [42])

        token1.cancel()
        token2.cancel()
    }

    func testRemoveObserver() async {
        let observable = Observable<String>()
        var receivedEvents: [String] = []

        let observer = ClosureObserver<String> { event in
            receivedEvents.append(event)
        }

        let token = await observable.addObserver(observer)

        await observable.notifyObservers("Event 1")

        // Remove observer
        token.cancel()

        await observable.notifyObservers("Event 2")

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Should only have received first event
        XCTAssertEqual(receivedEvents, ["Event 1"])
    }

    // MARK: - Memory Safety Tests

    func testWeakReferenceCleanup() async {
        let observable = Observable<String>()

        // Scope for observer to be deallocated
        do {
            var receivedEvents: [String] = []
            let observer = ClosureObserver<String> { event in
                receivedEvents.append(event)
            }

            _ = await observable.addObserver(observer)

            let countBefore = await observable.observerCount()
            XCTAssertEqual(countBefore, 1)

            // Observer goes out of scope here
        }

        // Give time for deallocation
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Trigger cleanup by notifying
        await observable.notifyObservers("test")

        let countAfter = await observable.observerCount()

        // Observer should have been cleaned up
        XCTAssertEqual(countAfter, 0, "Deallocated observer should be removed")
    }

    func testAutomaticCleanupOnNotify() async {
        let observable = Observable<Int>()

        // Add observer that will be deallocated
        do {
            let observer = ClosureObserver<Int> { _ in }
            _ = await observable.addObserver(observer)
        }

        // Add observer that will remain
        var remainingEvents: [Int] = []
        let remainingObserver = ClosureObserver<Int> { event in
            remainingEvents.append(event)
        }
        let token = await observable.addObserver(remainingObserver)

        // Notify - should clean up deallocated observer
        await observable.notifyObservers(1)

        try? await Task.sleep(nanoseconds: 100_000_000)

        let count = await observable.observerCount()

        // Only remaining observer should be counted
        XCTAssertEqual(count, 1)
        XCTAssertEqual(remainingEvents, [1])

        token.cancel()
    }

    func testTokenDeinit() async {
        let observable = Observable<String>()
        var receivedEvents: [String] = []

        let observer = ClosureObserver<String> { event in
            receivedEvents.append(event)
        }

        // Scope for token to be deallocated
        do {
            let token = await observable.addObserver(observer)
            await observable.notifyObservers("Event 1")

            try? await Task.sleep(nanoseconds: 100_000_000)

            // Token is still alive, should receive event
            XCTAssertEqual(receivedEvents, ["Event 1"])

            // Token will be deallocated when scope ends
        }

        // Give time for deinit
        try? await Task.sleep(nanoseconds: 100_000_000)

        await observable.notifyObservers("Event 2")

        try? await Task.sleep(nanoseconds: 100_000_000)

        // Should not receive Event 2 because token was deallocated
        // Note: The observer is still alive but removed via token deinit
        XCTAssertEqual(receivedEvents, ["Event 1"])
    }

    // MARK: - Custom Observer Tests

    func testCustomObserver() async {
        class TestObserver: Observer {
            var events: [String] = []

            func handleEvent(_ event: String) {
                events.append(event)
            }
        }

        let observable = Observable<String>()
        let observer = TestObserver()

        let token = await observable.addObserver(observer)

        await observable.notifyObservers("Test 1")
        await observable.notifyObservers("Test 2")

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(observer.events, ["Test 1", "Test 2"])

        token.cancel()
    }

    // MARK: - EventBus Tests

    func testEventBusPublishSubscribe() async {
        let eventBus = EventBus.shared
        var receivedEvents: [EventBus.AppEvent] = []

        let observer = ClosureObserver<EventBus.AppEvent> { event in
            receivedEvents.append(event)
        }

        let token = await eventBus.subscribe(observer)

        await eventBus.publish(.userLoggedIn(userId: "123"))
        await eventBus.publish(.dataUpdated(type: "items"))

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(receivedEvents.count, 2)

        // Verify event types
        if case .userLoggedIn(let userId) = receivedEvents[0] {
            XCTAssertEqual(userId, "123")
        } else {
            XCTFail("Expected userLoggedIn event")
        }

        if case .dataUpdated(let type) = receivedEvents[1] {
            XCTAssertEqual(type, "items")
        } else {
            XCTFail("Expected dataUpdated event")
        }

        token.cancel()
    }

    func testEventBusMultipleSubscribers() async {
        let eventBus = EventBus.shared
        var subscriber1Events: [EventBus.AppEvent] = []
        var subscriber2Events: [EventBus.AppEvent] = []

        let subscriber1 = ClosureObserver<EventBus.AppEvent> { event in
            subscriber1Events.append(event)
        }

        let subscriber2 = ClosureObserver<EventBus.AppEvent> { event in
            subscriber2Events.append(event)
        }

        let token1 = await eventBus.subscribe(subscriber1)
        let token2 = await eventBus.subscribe(subscriber2)

        await eventBus.publish(.userLoggedOut)

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(subscriber1Events.count, 1)
        XCTAssertEqual(subscriber2Events.count, 1)

        token1.cancel()
        token2.cancel()
    }

    // MARK: - Concurrent Notification Tests

    func testConcurrentNotifications() async {
        let observable = Observable<Int>()
        var receivedEvents: [Int] = []
        let lock = NSLock()

        let observer = ClosureObserver<Int> { event in
            lock.lock()
            receivedEvents.append(event)
            lock.unlock()
        }

        let token = await observable.addObserver(observer)

        // Send multiple notifications concurrently
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await observable.notifyObservers(i)
                }
            }
        }

        try? await Task.sleep(nanoseconds: 200_000_000)

        // All events should be received
        XCTAssertEqual(receivedEvents.count, 10)

        token.cancel()
    }
}

// MARK: - AppEvent Equatable (for testing)

extension EventBus.AppEvent: Equatable {
    static func == (lhs: EventBus.AppEvent, rhs: EventBus.AppEvent) -> Bool {
        switch (lhs, rhs) {
        case (.userLoggedIn(let lhsId), .userLoggedIn(let rhsId)):
            return lhsId == rhsId
        case (.userLoggedOut, .userLoggedOut):
            return true
        case (.dataUpdated(let lhsType), .dataUpdated(let rhsType)):
            return lhsType == rhsType
        case (.errorOccurred, .errorOccurred):
            return true
        default:
            return false
        }
    }
}
