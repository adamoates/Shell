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

**App**: Shell / Field Notes
**Flow**: Login (mock) → Notes List → Note Detail → Create/Edit
**Requirements**:
- Offline support
- Caching
- Secure auth token
- Full testability

This app must evolve incrementally across branches without architectural drift.

## UI Strategy (MANDATORY)

### UIKit-First Approach
- **Login**: Storyboard + Auto Layout
- **Notes List + Detail**: Programmatic UIKit
  - UICollectionView with diffable data source
  - Compositional layout
  - Custom cells and layouts

### SwiftUI Module
- One feature (e.g., Note Editor or Explore tab)
- Embedded via Coordinator / UIHostingController
- Proper data flow with Combine or async/await

### Rules
- Coordinator owns ALL navigation
- UI layers contain NO business logic
- ViewModels handle presentation logic only
- No fat ViewControllers

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

## Feature Requirements

### Authentication
- Mock login (local validation)
- Secure token storage (Keychain)
- Biometric authentication option
- Token refresh simulation
- Logout with proper cleanup

### Notes Management
- Create, read, update, delete notes
- Offline-first architecture
- Sync indicator
- Search and filter
- Categories/tags

### Data Persistence
- Core Data for local storage
- Repository pattern for data access
- Background context for writes
- Migration support

### Networking
- REST API simulation
- Retry logic with exponential backoff
- Request/response logging
- Error mapping
- Cancellation support

### Performance
- Smooth 60fps scrolling
- Efficient image loading (if applicable)
- Background task optimization
- Memory leak prevention
- Instruments profiling

### Security
- Keychain for sensitive data
- Biometric authentication
- Certificate pinning discussion
- No secrets in logs
- Data protection classes

### Accessibility
- VoiceOver support
- Dynamic Type
- Minimum touch targets (44x44)
- Color contrast compliance
- Semantic content

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
