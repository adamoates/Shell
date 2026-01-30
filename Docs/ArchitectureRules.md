# Architecture Rules

## Non-Negotiable Rules

These rules prevent architectural drift and ensure staff-level quality.

### 1. Boot Lives Under App/Boot

**Rule:** Application orchestration lives in `App/Boot/`, NOT in `Features/`.

**Why:** Boot is not a feature. It's application lifecycle orchestration.

**Test:** "Can we remove this and still have an app?"
- If NO → App/Boot (or Core)
- If YES → Features/

**Allowed in Boot:**
- Thin orchestration (call use cases, map results, route)
- LaunchState enum
- LaunchRouting protocol

**NOT allowed in Boot:**
- Business logic
- Network calls
- Persistence access
- Deep Clean Architecture layers

### 2. Coordinators Route, Use Cases Decide

**Rule:** Use cases return typed states. Coordinators translate states to navigation.

**Example:**
```swift
// ✅ Good: Use case returns domain state
enum SessionStatus {
    case authenticated
    case unauthenticated
    case locked
}

// ✅ Good: Coordinator maps to navigation
func route(to state: LaunchState) {
    switch state {
    case .authenticated:
        showMainFlow()
    case .unauthenticated:
        showAuthFlow()
    }
}

// ❌ Bad: Use case returns navigation
enum BootResult {
    case showHomeScreen
    case showLoginScreen  // UI concern in domain!
}
```

### 3. No "initialRoute" in Domain

**Rule:** Domain types must be UI-agnostic. Routes are UI concerns.

**Good:**
- `SessionStatus` (domain concept)
- `LaunchState` (app orchestration)

**Bad:**
- `BootResult.initialRoute` (leaks routing into domain)

### 4. Features Are User-Facing and Removable

**Rule:** Features live in `Features/` and must be:
- User-facing (has UI)
- Independently evolvable
- Routable
- Removable without breaking boot

**Examples:**
- ✅ Features: Auth, Profile, Search, Settings
- ❌ NOT Features: Boot, DI, Coordinators, HTTPClient

### 5. Protocols Define Needs, Infrastructure Implements

**Rule:** Protocols that define "what the app needs" live in:
- `Core/Contracts/` (or `Core/Domain/`)
- `Features/{Feature}/Domain/Protocols/`

**Implementations** live in:
- `Core/Infrastructure/`
- `Features/{Feature}/Data/`

**Why:** Domain owns abstractions. Infrastructure adapts to them.

**Example:**
```swift
// Core/Contracts/Security/SessionRepository.swift
protocol SessionRepository {
    func getCurrentSession() async -> UserSession?
}

// Core/Infrastructure/Security/KeychainSessionRepository.swift
final class KeychainSessionRepository: SessionRepository {
    // Implementation using Keychain APIs
}
```

### 6. Composition Root Wires Everything

**Rule:** Concrete types are instantiated ONLY in the composition root (`Core/DI/AppDependencyContainer`).

**Everywhere else:** Depend on protocols, receive via constructor injection.

**No:**
- Singletons (except Apple APIs)
- Service locators
- Static factories
- Instantiating concretes inside use cases/coordinators

### 7. LaunchState is UI-Agnostic

**Rule:** LaunchState describes app state, not screens.

**Good:**
- `.authenticated`
- `.unauthenticated`
- `.locked`
- `.maintenance`

**Bad:**
- `.showLoginScreen`
- `.navigateToHome`
- `.presentOnboarding`

### 8. Bootstrapper Mapping is Dead Simple

**Rule:** AppBootstrapper only maps use case results to LaunchState.

**If you need complex logic:**
- Push it into a use case
- Push it into a policy object
- Do NOT add it to bootstrapper

**Example:**
```swift
// ✅ Good: Simple mapping
private static func map(status: SessionStatus) -> LaunchState {
    switch status {
    case .authenticated: return .authenticated
    case .unauthenticated: return .unauthenticated
    case .locked: return .locked
    }
}

// ❌ Bad: Complex business logic in Boot
func start() {
    let session = await restoreSession.execute()
    let config = await loadConfig.execute()

    // This is business logic! Push to a use case!
    if session.isPremium && config.featureFlags.contains("newUI") {
        router.route(to: .authenticatedWithNewUI)
    } else {
        router.route(to: .authenticated)
    }
}
```

## Folder Structure Rules

```
Shell/
  App/
    Boot/              # Thin orchestration only
    Coordinators/      # Navigation control
    DI/                # Composition root

  Core/
    Contracts/         # Protocols defining needs
    Infrastructure/    # Platform implementations

  Features/
    {Feature}/
      Domain/          # Business logic, entities, protocols
      Data/            # Repository implementations
      Presentation/    # ViewModels, Views, Coordinators
```

## Review Checklist

Before merging any branch, verify:

- [ ] Boot has no business logic
- [ ] Use cases return domain types, not routes
- [ ] Coordinators own navigation decisions
- [ ] Protocols are in Contracts/Domain, not Infrastructure
- [ ] Composition root is the only place creating concretes
- [ ] LaunchState is UI-agnostic
- [ ] Features are removable without breaking boot

## When in Doubt

Ask these questions:

1. **"Can we delete this and still boot?"**
   - No → App/Boot or Core
   - Yes → Features

2. **"Is this a business rule or navigation?"**
   - Business → Use case
   - Navigation → Coordinator

3. **"Does this define a need or provide implementation?"**
   - Need → Protocol in Contracts/Domain
   - Implementation → Core/Infrastructure or Feature/Data

4. **"Is this orchestration or logic?"**
   - Orchestration → Boot (thin)
   - Logic → Use case

## Staff-Level Signal

These rules exist to demonstrate architectural maturity. Every violation sends a signal:

✅ **Good signal:** "This engineer understands where concerns belong"
❌ **Bad signal:** "This engineer mixes layers and will create maintenance nightmares"

**Boot placement is one of the loudest signals.** Getting it right shows you understand the difference between orchestration and features.
