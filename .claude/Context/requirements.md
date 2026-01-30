# Shell iOS App - Master Requirements

## Global Objective

Build a single coherent iOS app that proves mastery of:
- UIKit (Storyboard + Programmatic)
- SwiftUI (modern, production-ready usage)
- MVVM + Coordinator architecture
- Clean Architecture boundaries
- Design patterns applied intentionally
- Test-driven development
- Networking, persistence, performance, security, debugging
- Code quality suitable for long-term maintenance

**This is not a demo app and not a tutorial.**
Assume this code will be reviewed by staff+ engineers.

## App Concept (FIXED)

**The Shell is NOT a Notes app. It's an Ultimate Starter Kit.**

**Purpose**: Feature-agnostic infrastructure that demonstrates senior-level iOS patterns through platform concerns, not business logic.

**What this means**:
- We build infrastructure use cases: BootApp, HandleDeepLink, RefreshToken, SecureStore
- NOT business use cases: CreateNote, FetchTasks
- The Shell IS the product — a foundation you can drop any feature into later

**Core Infrastructure**:
1. App lifecycle & boot (BootApp, RestoreSession, HandleAppStateTransitions)
2. Coordinator routing (including deep link handling)
3. Generic APIClient with decorators (auth, retry, logging)
4. SecureStore (Keychain) + BiometricGate
5. Cache with TTL + CoreDataStack facade
6. Debug diagnostics screen + repro tools
7. Comprehensive test harness (unit, integration, UI)

**Requirements**:
- Production-ready patterns
- Every boundary is protocol-driven
- Composition root wires everything
- Complete test coverage
- Zero technical debt

This starter kit must be feature-agnostic and evolve incrementally across branches without architectural drift.

**See [starter-kit-use-cases.md](starter-kit-use-cases.md) for complete use case catalog.**

## UI Strategy (MANDATORY)

### Demonstrate Both UI Frameworks

**UIKit** (Storyboard + Programmatic):
- Storyboard example: Simple auth/onboarding screen
- Programmatic example: Diagnostics screen, state-driven UI
- Modern patterns: Diffable data sources, compositional layouts

**SwiftUI**:
- One infrastructure feature (e.g., Debug Diagnostics or Settings)
- Embedded via Coordinator / UIHostingController
- Proper state management with ObservableObject
- Combine or async/await data flow

### Architecture Rules
- **Coordinator owns ALL navigation** (UIKit and SwiftUI)
- UI layers contain **NO business logic**
- ViewModels handle **presentation logic only**
- No fat ViewControllers
- Every screen demonstrates MVVM pattern

## Core Principles

### 1. Architecture First
Every feature must follow Clean Architecture:
- Domain layer depends on nothing
- UI depends on Domain only
- Data implements Domain protocols
- Proper dependency injection throughout

### 2. Test-Driven Development
Tests written FIRST (except purely visual layout):
- Unit tests for use cases, ViewModels, repositories
- Integration tests with proper test doubles
- UI tests for critical flows
- No flaky tests, no sleeps

### 3. Code Quality
- Zero build warnings
- No commented-out code
- Small functions, single responsibility
- Explicit naming over brevity
- Typed errors mapped at boundaries

### 4. Intentional Patterns
Use design patterns to:
- Reduce coupling
- Increase testability
- Improve maintainability
- Not to show off

### 5. Production Readiness
This codebase should:
- Be handed to a team
- Scale to new features
- Survive refactors
- Pass staff-level code review

## Infrastructure Requirements

### A) App Lifecycle & Boot
- BootApp: Load config, construct DI graph, choose initial route
- RestoreSession: Check auth token, restore user session
- HandleAppStateTransitions: Foreground/background handling
- Edge cases: Invalid config, expired tokens, keychain locked

### B) Navigation & Routing
- Coordinator pattern for all navigation
- Deep link / universal link handling
- Typed Route enum with parameter validation
- Global UI presentation (errors, loading, modals)
- Edge cases: Unknown routes, rapid navigation, auth-required routes

### C) Application State
- Single source of truth for app state (authenticated/guest/locked)
- Observable state changes (Combine or async/await)
- State-driven UI rendering
- Edge cases: Background thread updates, state thrashing

### D) Networking Foundation
- Generic HTTPClient protocol
- URLSessionAdapter
- Decorators: Authentication, Retry, Logging
- Token refresh with single-flight pattern
- Typed error mapping
- Cancellation support
- Edge cases: 204 No Content, decoding errors, rate limiting, concurrent 401s

### E) Persistence Foundation
- Core Data stack facade
- Background context handling
- Merge policies and migrations
- Generic cache with TTL expiration
- Edge cases: Disk full, corrupted data, migration failures

### F) Security
- SecureStore (Keychain adapter)
- BiometricGate (Face ID / Touch ID)
- Token management (storage, refresh, expiry)
- No secrets in logs
- Edge cases: Keychain locked, biometric lockout, no enrollment

### G) Observability & Diagnostics
- Structured logging (no secrets)
- Debug diagnostics screen (app state, cache, network, flags)
- Repro tools (simulate offline, expired token, crashes, constraint warnings)
- Edge cases: Redact sensitive data, debug-only features

### H) Performance
- Measure critical paths (launch time, screen render, API response)
- Memory leak prevention (coordinator/ViewModel lifecycle)
- Smooth 60fps rendering
- Instruments profiling (Time Profiler, Allocations, Leaks)
- Edge cases: Retain cycles, main-thread blocking

### I) Accessibility (Built-in)
- VoiceOver support on all screens
- Dynamic Type scaling
- Minimum touch targets (44x44)
- Color contrast compliance
- Semantic content structure

## Acceptance Criteria

Every branch must meet ALL of these:

### Build Quality
- ✅ Compiles with zero warnings
- ✅ SwiftLint passes with strict config
- ✅ All tests pass
- ✅ No commented-out code

### Architecture Quality
- ✅ Clean Architecture boundaries respected
- ✅ Dependency injection used throughout
- ✅ No singletons (except Apple APIs)
- ✅ Composition root properly structured

### Test Quality
- ✅ >80% code coverage on domain/data layers
- ✅ ViewModels 100% unit tested
- ✅ Tests are deterministic and fast
- ✅ UI tests use accessibility identifiers

### Code Quality
- ✅ Functions under 50 lines
- ✅ Classes under 300 lines
- ✅ Cyclomatic complexity under 10
- ✅ No force unwraps in production code

### Documentation Quality
- ✅ README explains architecture
- ✅ Each branch has Docs/Test-NN.md
- ✅ Design decisions documented
- ✅ Tradeoffs explained

## Non-Goals

What this project is NOT:
- ❌ Not a tutorial for beginners
- ❌ Not showcasing every pattern
- ❌ Not optimizing for speed over quality
- ❌ Not cutting corners for "MVP"
- ❌ Not accepting technical debt

## Success Metrics

This project succeeds when:
1. Any senior engineer can understand the codebase in 30 minutes
2. Adding a new feature follows obvious patterns
3. Refactoring is safe (tests prove it)
4. Code review comments are about business logic, not structure
5. The app demonstrates production-ready practices

## Evolution Strategy

Build incrementally:
1. Architecture foundation (DI, Coordinator, protocols)
2. Authentication feature (end-to-end)
3. Notes list feature (with all layers)
4. Detail/edit feature (reusing patterns)
5. Performance optimization (measured)
6. Security hardening (KeyChain, biometrics)
7. Advanced features (search, sync, etc.)

Each addition must maintain the quality bar.

## Key Constraints

### MUST
- Follow Clean Architecture
- Write tests first
- Use dependency injection
- Document design decisions
- Zero warnings

### MUST NOT
- Create singletons
- Mix concerns (UI + business logic)
- Skip tests
- Add premature abstractions
- Ignore performance

### SHOULD
- Prefer composition over inheritance
- Use protocols for boundaries
- Keep functions small
- Make code self-documenting
- Measure before optimizing

### SHOULD NOT
- Over-engineer simple problems
- Add dependencies without justification
- Sacrifice readability for brevity
- Ignore edge cases
- Defer error handling

## Delivery Standard

Every branch delivers:
1. Working, tested code
2. Documentation explaining why
3. Proof of quality (build + test output)
4. Known limitations stated
5. Follow-up items identified

This is the standard. No exceptions.
