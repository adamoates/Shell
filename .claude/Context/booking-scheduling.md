# Booking and Scheduling System

**Domain-specific guide for building scheduling and booking features**

This is a reference for products that need scheduling (dog care, appointments, classes, etc.)

---

## Overview

Scheduling systems seem simple but are deceptively complex.

Common mistakes:
- Over-engineering too early
- Ignoring time zones
- No conflict detection
- Poor cancellation handling
- Complex availability systems

This guide helps avoid these pitfalls.

---

## MVP Philosophy

### Start Simple

**v1 should be:**
```
Request → Accept → Confirm → Complete
```

**Not:**
- ❌ Complex availability calendars
- ❌ Optimization algorithms
- ❌ AI matching
- ❌ Dynamic pricing
- ❌ Recurring bookings (yet)

**Why:**
- Validates core loop
- Fast to build
- Easy to test
- Learns user behavior

---

## Domain Model (MVP)

### Booking Entity

```swift
struct Booking: Sendable, Identifiable, Codable {
    let id: UUID
    let ownerId: UUID          // Who's requesting
    let providerId: UUID       // Who's providing service
    let serviceType: ServiceType
    let startTime: Date
    let endTime: Date
    let status: BookingStatus
    let dogs: [UUID]           // What's being cared for (domain-specific)
    let notes: String?
    let createdAt: Date
    let updatedAt: Date
}

enum BookingStatus: String, Codable {
    case pending      // Requested, waiting for acceptance
    case confirmed    // Accepted by provider
    case inProgress   // Service is happening
    case completed    // Service finished
    case cancelled    // Cancelled by either party
}

enum ServiceType: String, Codable {
    case daycare
    case boarding
    case walking
    case sitting
}
```

### Key Design Decisions

**Snapshot, not reference:**
- Store `ownerId`, not `Owner` object
- Store `dogs: [UUID]`, not `[Dog]`
- **Why:** Booking represents a point in time. Dog details can change.

**Status enum:**
- Clear state machine
- Easy to query
- Simple to reason about

**Time as Date:**
- Use `Date` for simplicity in MVP
- Timezone handling comes later

---

## Use Cases (MVP)

### 1. CreateBookingUseCase

```swift
protocol CreateBookingUseCase {
    func execute(
        providerId: UUID,
        serviceType: ServiceType,
        startTime: Date,
        endTime: Date,
        dogIds: [UUID],
        notes: String?
    ) async throws -> Booking
}

final class DefaultCreateBookingUseCase: CreateBookingUseCase {
    private let bookingsRepository: BookingsRepository
    private let dogsRepository: DogsRepository

    func execute(
        providerId: UUID,
        serviceType: ServiceType,
        startTime: Date,
        endTime: Date,
        dogIds: [UUID],
        notes: String?
    ) async throws -> Booking {
        // 1. Validation
        guard startTime < endTime else {
            throw BookingError.invalidTimeRange
        }

        guard !dogIds.isEmpty else {
            throw BookingError.noDogs
        }

        // 2. Verify dogs exist and belong to user
        let dogs = try await dogsRepository.fetch(ids: dogIds)
        guard dogs.count == dogIds.count else {
            throw BookingError.invalidDogs
        }

        // 3. Check for conflicts (v2 feature, skip in MVP)
        // let conflicts = try await bookingsRepository.findConflicts(...)

        // 4. Create booking
        let booking = Booking(
            id: UUID(),
            ownerId: currentUserId, // From auth context
            providerId: providerId,
            serviceType: serviceType,
            startTime: startTime,
            endTime: endTime,
            status: .pending,
            dogs: dogIds,
            notes: notes,
            createdAt: Date(),
            updatedAt: Date()
        )

        return try await bookingsRepository.create(booking)
    }
}
```

### 2. AcceptBookingUseCase

```swift
protocol AcceptBookingUseCase {
    func execute(bookingId: UUID) async throws -> Booking
}

final class DefaultAcceptBookingUseCase: AcceptBookingUseCase {
    private let bookingsRepository: BookingsRepository

    func execute(bookingId: UUID) async throws -> Booking {
        // 1. Fetch booking
        var booking = try await bookingsRepository.fetch(id: bookingId)

        // 2. Validate status
        guard booking.status == .pending else {
            throw BookingError.invalidStatus
        }

        // 3. Verify current user is provider
        guard booking.providerId == currentUserId else {
            throw BookingError.unauthorized
        }

        // 4. Accept booking
        booking.status = .confirmed
        booking.updatedAt = Date()

        return try await bookingsRepository.update(booking)
    }
}
```

### 3. CancelBookingUseCase

```swift
protocol CancelBookingUseCase {
    func execute(bookingId: UUID, reason: String?) async throws
}

final class DefaultCancelBookingUseCase: CancelBookingUseCase {
    private let bookingsRepository: BookingsRepository

    func execute(bookingId: UUID, reason: String?) async throws {
        // 1. Fetch booking
        var booking = try await bookingsRepository.fetch(id: bookingId)

        // 2. Validate can cancel
        guard booking.status == .pending || booking.status == .confirmed else {
            throw BookingError.cannotCancel
        }

        // 3. Verify user can cancel (owner or provider)
        guard booking.ownerId == currentUserId || booking.providerId == currentUserId else {
            throw BookingError.unauthorized
        }

        // 4. Cancel
        booking.status = .cancelled
        booking.updatedAt = Date()

        try await bookingsRepository.update(booking)

        // 5. Notify other party (v2 feature)
        // await notificationService.send(...)
    }
}
```

---

## Common Pitfalls and Solutions

### Pitfall 1: Time Zones

**Problem:**
```swift
let startTime = Date() // What timezone?
```

**MVP Solution:**
- Store all times in UTC
- Convert to local time in UI only

**v2 Solution:**
```swift
struct Booking {
    let startTime: Date        // UTC
    let timeZone: TimeZone     // Where service happens
}
```

---

### Pitfall 2: Conflict Detection

**Problem:**
Provider double-booked for same time.

**MVP Solution:**
- Manual conflict check by provider
- Show warning in UI

**v2 Solution:**
```swift
protocol BookingsRepository {
    func findConflicts(
        providerId: UUID,
        startTime: Date,
        endTime: Date
    ) async throws -> [Booking]
}

// Reject if conflicts exist
let conflicts = try await repository.findConflicts(...)
guard conflicts.isEmpty else {
    throw BookingError.conflictingBooking
}
```

---

### Pitfall 3: Cancellation Policy

**Problem:**
No rules for cancellations.

**MVP Solution:**
- Allow cancellation anytime
- No refunds (if no payments yet)

**v2 Solution:**
```swift
struct CancellationPolicy {
    let hoursBeforeService: Int
    let refundPercentage: Int
}

func validateCancellation(booking: Booking, policy: CancellationPolicy) throws {
    let hoursUntilStart = booking.startTime.timeIntervalSince(Date()) / 3600

    guard hoursUntilStart >= Double(policy.hoursBeforeService) else {
        throw BookingError.cancellationTooLate(
            refundPercentage: policy.refundPercentage
        )
    }
}
```

---

### Pitfall 4: Recurring Bookings

**Problem:**
User wants same booking every week.

**MVP Solution:**
- Manual re-booking
- Don't implement recurring yet

**v2 Solution:**
```swift
struct RecurringBooking {
    let id: UUID
    let templateBooking: Booking
    let frequency: RecurrenceFrequency
    let endDate: Date?
    let generatedBookings: [UUID]  // Track generated instances
}

enum RecurrenceFrequency {
    case daily
    case weekly
    case biweekly
    case monthly
}

protocol CreateRecurringBookingUseCase {
    func execute(template: Booking, frequency: RecurrenceFrequency) async throws
}
```

---

### Pitfall 5: Status Transitions

**Problem:**
Booking goes from `pending` to `completed` directly.

**Solution:**
State machine validation.

```swift
extension BookingStatus {
    func canTransition(to newStatus: BookingStatus) -> Bool {
        switch (self, newStatus) {
        case (.pending, .confirmed):    return true
        case (.pending, .cancelled):    return true
        case (.confirmed, .inProgress): return true
        case (.confirmed, .cancelled):  return true
        case (.inProgress, .completed): return true
        case (.inProgress, .cancelled): return true
        default:                        return false
        }
    }
}

// In use case
guard booking.status.canTransition(to: .confirmed) else {
    throw BookingError.invalidStatusTransition
}
```

---

## Repository Design

### MVP: In-Memory

```swift
actor InMemoryBookingsRepository: BookingsRepository {
    private var bookings: [UUID: Booking] = [:]

    func create(_ booking: Booking) async throws -> Booking {
        bookings[booking.id] = booking
        return booking
    }

    func fetch(id: UUID) async throws -> Booking {
        guard let booking = bookings[id] else {
            throw BookingError.notFound
        }
        return booking
    }

    func fetchByOwner(ownerId: UUID) async throws -> [Booking] {
        bookings.values.filter { $0.ownerId == ownerId }
    }

    func fetchByProvider(providerId: UUID) async throws -> [Booking] {
        bookings.values.filter { $0.providerId == providerId }
    }

    func update(_ booking: Booking) async throws -> Booking {
        bookings[booking.id] = booking
        return booking
    }
}
```

### v2: HTTP

```swift
actor HTTPBookingsRepository: BookingsRepository {
    private let httpClient: BookingsHTTPClient

    func create(_ booking: Booking) async throws -> Booking {
        let dto = BookingDTO(from: booking)
        let response = try await httpClient.post("/bookings", body: dto)
        return response.toDomain()
    }

    func fetchConflicts(
        providerId: UUID,
        startTime: Date,
        endTime: Date
    ) async throws -> [Booking] {
        let params = [
            "provider_id": providerId.uuidString,
            "start_time": ISO8601DateFormatter().string(from: startTime),
            "end_time": ISO8601DateFormatter().string(from: endTime)
        ]

        let response = try await httpClient.get("/bookings/conflicts", params: params)
        return response.map { $0.toDomain() }
    }
}
```

---

## UI/UX Considerations

### Booking Flow

**Step 1: Select Service**
- Service type (daycare, boarding, etc.)
- Date picker
- Time range picker

**Step 2: Select Dogs**
- Multi-select list
- Show care requirements

**Step 3: Add Notes**
- Optional text field
- Care instructions

**Step 4: Review**
- Summary of booking
- Total cost (if payments implemented)

**Step 5: Confirm**
- Submit request
- Show pending status

### Status Display

```
Pending      → "Waiting for confirmation"
Confirmed    → "Confirmed! See you at 9am"
In Progress  → "Service in progress"
Completed    → "Completed on Feb 14"
Cancelled    → "Cancelled"
```

---

## Testing Strategy

### Domain Tests

```swift
func testCreateBookingWithValidData() async throws {
    let repository = InMemoryBookingsRepository()
    let useCase = DefaultCreateBookingUseCase(repository: repository)

    let booking = try await useCase.execute(
        providerId: UUID(),
        serviceType: .daycare,
        startTime: Date().addingTimeInterval(3600),
        endTime: Date().addingTimeInterval(7200),
        dogIds: [UUID()],
        notes: "Please use back door"
    )

    XCTAssertEqual(booking.status, .pending)
}

func testCreateBookingWithInvalidTimeRangeThrows() async throws {
    let useCase = DefaultCreateBookingUseCase(repository: repository)

    await XCTAssertThrowsError(
        try await useCase.execute(
            startTime: Date(),
            endTime: Date().addingTimeInterval(-3600) // End before start
        )
    )
}

func testStatusTransitionValidation() {
    let pending = BookingStatus.pending
    XCTAssertTrue(pending.canTransition(to: .confirmed))
    XCTAssertFalse(pending.canTransition(to: .completed))
}
```

---

## Evolution Path

### Phase 1: MVP (Week 1-2)
- Create booking
- Accept booking
- Cancel booking
- Basic status tracking

### Phase 2: Conflict Detection (Week 3)
- Check provider availability
- Block double bookings
- Show conflicts in UI

### Phase 3: Recurring Bookings (Week 4-5)
- Template bookings
- Generate instances
- Manage series

### Phase 4: Advanced Features (Month 2+)
- Availability calendars
- Smart matching
- Dynamic pricing
- Waitlists

**Ship Phase 1 first. Validate. Then iterate.**

---

## Key Takeaways

1. **Start simple** - Request/accept/confirm is enough for MVP
2. **Snapshot data** - Store IDs, not objects
3. **State machine** - Clear status transitions
4. **Time zones** - UTC in backend, local in UI
5. **Conflicts** - Manual in MVP, automated in v2
6. **Test edge cases** - Invalid times, status transitions, cancellations

---

**Last Updated:** 2026-02-14
**Use this guide:** When building scheduling/booking features
