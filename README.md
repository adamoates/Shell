# Shell - iOS Starter Kit

A production-ready iOS application foundation built with Clean Architecture, MVVM, Coordinator pattern, and Swift 6 strict concurrency.

## What is Shell?

Shell is a **fully-tested, architecture-compliant iOS starter kit** demonstrating modern Swift development patterns. It's designed to be a **reusable foundation** for building scalable iOS applications with proper separation of concerns, comprehensive testing, and hybrid UIKit/SwiftUI support.

## Features

### Architecture
- ✅ **Clean Architecture** - Domain, Presentation, and Infrastructure layers with clear boundaries
- ✅ **MVVM Pattern** - ViewModels for presentation logic, Views for UI only
- ✅ **Coordinator Pattern** - Type-safe navigation with no segues
- ✅ **Repository Pattern** - Protocol-based data abstraction
- ✅ **Dependency Injection** - Composition root with AppDependencyContainer

### Technology Stack
- ✅ **Swift 6 Strict Concurrency** - Zero warnings, Sendable conformance
- ✅ **Actor-Based Repositories** - Thread-safe data access
- ✅ **Async/Await** - Modern concurrency throughout
- ✅ **Combine** - Reactive UI updates via @Published properties
- ✅ **Programmatic UI** - UIKit views built in code (no storyboards)
- ✅ **SwiftUI Integration** - Hybrid UIKit/SwiftUI via UIHostingController

### Implemented Features

#### Items CRUD (Epic 2)
- Full Create, Read, Update, Delete operations
- In-memory repository with actor-based thread safety
- ItemEditorViewController demonstrating programmatic UI
- Comprehensive validation and error handling
- 31 tests covering all CRUD operations

#### Profile Management
- User profile with identity validation
- Screen name validation (2-20 chars, alphanumeric + _ -)
- Birthday validation (COPPA compliant, 13+ age requirement)
- SwiftUI Profile Editor (demonstrates hybrid integration)
- Actor-based profile repository
- 99+ tests for domain validation

#### SwiftSDK Module (Test 02)
- **Generic Storage Framework** - Thread-safe key-value storage and caching
- **Validation Framework** - Composable validators with functional composition
- **Observer Pattern** - Memory-safe observers with weak references
- 60+ tests demonstrating Swift language mastery

### Testing
- ✅ **195+ Tests** - All passing, comprehensive coverage
- ✅ **Unit Tests** - Domain logic, use cases, ViewModels
- ✅ **Repository Tests** - Thread-safety, actor isolation
- ✅ **ViewModel Tests** - State management, Combine publishers
- ✅ **Validation Tests** - Edge cases, error conditions

## Quick Start

### Requirements
- Xcode 15.0+
- iOS 16.0+ deployment target
- macOS 13.0+ (for development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Shell
   ```

2. **Open in Xcode**
   ```bash
   open Shell.xcodeproj
   ```

3. **Build the project** (⌘B)
   ```bash
   xcodebuild build -scheme Shell
   ```

4. **Run tests** (⌘U)
   ```bash
   xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
   ```

5. **Run the app** (⌘R)
   - Select a simulator from the scheme picker
   - Press Run or ⌘R

### First Run

The app starts with:
1. **Boot sequence** - Checks for existing session
2. **Login screen** - Enter any username (3+ chars) and password (6+ chars)
3. **Items list** - View, create, edit, and delete items
4. **Profile** - View and edit user profile

## Project Structure

```
Shell/
├── App/
│   ├── Boot/                      # App launch orchestration
│   ├── Coordinators/              # Feature coordinators
│   └── Navigation/                # App-level routing
│
├── Core/
│   ├── Coordinator/               # Coordinator protocol
│   ├── Contracts/                 # Domain-owned protocols
│   │   ├── Configuration/
│   │   ├── Navigation/
│   │   ├── Networking/
│   │   └── Security/
│   ├── DI/                        # Dependency injection
│   ├── Infrastructure/            # Shared implementations
│   │   ├── Configuration/
│   │   ├── Navigation/
│   │   ├── Networking/
│   │   └── Security/
│   ├── Navigation/                # Type-safe routing
│   └── Presentation/              # Shared UI components
│
├── Features/
│   ├── Auth/                      # Authentication feature
│   │   ├── Domain/
│   │   │   ├── Entities/
│   │   │   ├── Errors/
│   │   │   └── UseCases/
│   │   └── Presentation/
│   │       └── Login/
│   │
│   ├── Items/                     # Items CRUD feature
│   │   ├── Domain/
│   │   │   ├── Contracts/         # Repository protocols
│   │   │   ├── Entities/
│   │   │   ├── Errors/
│   │   │   └── UseCases/
│   │   ├── Infrastructure/        # Repository implementations
│   │   └── Presentation/
│   │       ├── List/
│   │       ├── Detail/
│   │       └── ItemEditor/
│   │
│   └── Profile/                   # Profile feature
│       ├── Domain/
│       │   ├── Entities/
│       │   ├── Errors/
│       │   └── UseCases/
│       ├── Infrastructure/
│       └── Presentation/
│           └── Editor/            # SwiftUI Profile Editor
│
├── SwiftSDK/                      # Reusable SDK components
│   ├── Storage/                   # Generic storage framework
│   ├── Validation/                # Validation framework
│   └── Observation/               # Observer pattern
│
└── Shared/
    └── UI/                        # Reusable UI components

ShellTests/
├── Features/                      # Feature tests mirror structure
│   ├── Auth/
│   ├── Items/
│   └── Profile/
├── SwiftSDK/                      # SDK tests
│   ├── Storage/
│   ├── Validation/
│   └── Observation/
└── Core/
    └── Navigation/
```

## Architecture Overview

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

### Layer Separation

```
┌─────────────────────────────────────────┐
│           Presentation Layer            │
│  ViewControllers, ViewModels, SwiftUI   │
│        (depends on Domain only)         │
└─────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────┐
│             Domain Layer                │
│  Entities, Use Cases, Repository        │
│       Protocols (no dependencies)       │
└─────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────┐
│         Infrastructure Layer            │
│   Repository Implementations, API       │
│      (depends on Domain protocols)      │
└─────────────────────────────────────────┘
```

### Key Patterns

**MVVM**:
- ViewControllers are thin, only handle UI updates
- ViewModels contain presentation logic
- Use Cases contain business logic
- Clear separation of concerns

**Repository Pattern**:
- Domain defines repository protocols
- Infrastructure implements repositories
- Use Cases depend on protocol, not implementation
- Easy to swap implementations (in-memory → HTTP → Core Data)

**Coordinator Pattern**:
- Coordinators own navigation logic
- ViewControllers don't know about other ViewControllers
- Type-safe routes via enum
- No segues or storyboard-based navigation

**Hybrid UIKit/SwiftUI**:
- SwiftUI views wrapped in UIHostingController
- Coordinators push UIHostingController onto UIKit navigation stack
- Incremental SwiftUI adoption without full rewrite

## Adding a New Feature

See [Docs/QuickStart.md](Docs/QuickStart.md) for a step-by-step guide.

**Quick overview**:

1. **Create domain models** in `Features/YourFeature/Domain/Entities/`
2. **Define repository protocol** in `Features/YourFeature/Domain/Contracts/`
3. **Create use cases** in `Features/YourFeature/Domain/UseCases/`
4. **Implement repository** in `Features/YourFeature/Infrastructure/`
5. **Create ViewModel** in `Features/YourFeature/Presentation/`
6. **Create View** (UIKit or SwiftUI) in `Features/YourFeature/Presentation/`
7. **Create Coordinator** in `App/Coordinators/`
8. **Write tests** for domain, use cases, repository, ViewModel

## Testing

### Running All Tests

```bash
xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Running Specific Test Suites

```bash
# Items feature tests only
xcodebuild test -scheme Shell -only-testing:ShellTests/ItemsListViewModelTests

# Profile feature tests only
xcodebuild test -scheme Shell -only-testing:ShellTests/ProfileViewModelTests

# SwiftSDK tests only
xcodebuild test -scheme Shell -only-testing:ShellTests/InMemoryStorageTests
```

### Test Organization

Tests mirror the main app structure:

```
ShellTests/
├── Features/                    # Feature tests
│   ├── Auth/
│   │   ├── Domain/
│   │   │   └── UseCases/       # Use case tests
│   │   └── Presentation/       # ViewModel tests
│   ├── Items/
│   │   ├── Domain/
│   │   ├── Infrastructure/     # Repository tests
│   │   └── Presentation/
│   └── Profile/
│       ├── Domain/
│       ├── Infrastructure/
│       └── Presentation/
└── SwiftSDK/                    # SDK tests
    ├── Storage/
    ├── Validation/
    └── Observation/
```

## Key Demonstrations

Shell demonstrates the following patterns and technologies through its test branches:

### Test 01: Storyboard UI/UX
- Auto Layout, Dynamic Type, Safe Areas
- iOS UI patterns (pull-to-refresh, empty states, swipe actions)
- Full accessibility support

### Test 02: Swift Language Mastery
- Protocol-oriented design with associated types
- Generic programming with type constraints
- Swift concurrency (actors, async/await, Sendable)
- Memory-safe observer pattern with weak references
- Functional composition

### Test 03: Architecture Foundation
- Clean Architecture layer separation
- Boot orchestration (App/Boot/ vs Features/)
- Session restoration use case
- Repository protocol boundaries

### Test 04: Navigation
- Type-safe routing with enum Route
- Deep link support (universal links + custom URL schemes)
- AuthGuard for route access control
- RouteResolver for URL → Route mapping

### Test 05: SwiftUI Foundations
- SwiftUI view with declarative syntax
- ObservableObject ViewModel with @Published properties
- UIHostingController integration
- Hybrid UIKit/SwiftUI architecture

## Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed architecture guide
- [Docs/QuickStart.md](Docs/QuickStart.md) - Adding new features
- [Docs/Test-01.md](Docs/Test-01.md) - Storyboard UI/UX patterns
- [Docs/Test-02.md](Docs/Test-02.md) - Swift language patterns
- [Docs/Test-03.md](Docs/Test-03.md) - Architecture foundation
- [Docs/Test-04.md](Docs/Test-04.md) - Navigation system
- [Docs/Test-05.md](Docs/Test-05.md) - SwiftUI integration
- [Docs/UniversalLinks-Setup.md](Docs/UniversalLinks-Setup.md) - Deep linking setup

## Current Limitations

Shell is a **starter kit**, not a complete app. The following are intentionally not implemented (yet):

### Data Persistence
- Uses **in-memory repositories** (data lost on app restart)
- No Core Data, Realm, or SQLite integration
- No network API calls (mock data only)

**Why**: Allows focusing on architecture without backend dependencies. Repositories can be swapped for HTTP/Core Data implementations via dependency injection.

### Authentication
- Mock authentication (any username/password works)
- No real auth tokens, OAuth, or biometrics
- Sessions not persisted (logout on restart)

**Why**: Auth is highly app-specific. Foundation is in place to add real auth.

### Production Features
- No real API integration
- No image uploads or caching
- No offline sync
- No analytics or crash reporting
- No push notifications

**Why**: These are app-specific concerns. Shell provides the architecture to add them.

## Roadmap

### Planned for v2.0
- **Epic 3**: Real API integration (HTTPItemsRepository, HTTPUserProfileRepository)
- **Keychain** persistence for auth tokens
- **Error handling** improvements (retry logic, offline state)
- **Image caching** framework
- **Settings screen** with app preferences

### Under Consideration
- **Core Data** repository implementation example
- **Offline sync** strategy
- **SwiftUI-first** screens for remaining features
- **CI/CD** pipeline (GitHub Actions)
- **Fastlane** integration for deployment

## Contributing

This is a personal starter kit project, but suggestions and improvements are welcome.

If you find a bug or have a suggestion:
1. Check existing issues
2. Create a new issue with:
   - Clear description
   - Steps to reproduce (if bug)
   - Expected vs actual behavior

## License

MIT

## Acknowledgments

Built with:
- Swift 6
- UIKit + SwiftUI
- Combine
- XCTest

Architecture inspired by:
- Clean Architecture (Robert C. Martin)
- MVVM pattern
- Coordinator pattern (Soroush Khanlou)

---

**Shell v1.0.0** - A production-ready iOS starter kit.

For questions or feedback, create an issue on GitHub.
