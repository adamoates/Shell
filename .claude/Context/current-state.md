# Current Application State

**Last Updated**: 2026-02-04

## Overview

The Shell iOS starter kit is a **production-ready foundation** implementing Clean Architecture + MVVM + Coordinator pattern with type-safe navigation, programmatic UI, Repository pattern, comprehensive logging infrastructure, and comprehensive testing infrastructure (301 tests passing, zero warnings, Swift 6 strict concurrency compliant).

## Architecture Status

### ✅ Completed Components

#### 1. Boot System (App/Boot/)
- **AppBootstrapper** - Orchestrates app launch sequence
- **LaunchState** - Type-safe boot states (authenticated, unauthenticated, locked, maintenance, failure)
- **LaunchRouting** - Protocol for routing based on boot result
- **Session Restoration** - Async session check via RestoreSessionUseCase

**Status**: Production ready, fully tested

#### 2. Navigation System (Core/Navigation/ + Core/Infrastructure/Navigation/)
- **Type-Safe Routes** - `indirect enum Route` with parameter validation
- **AuthGuard** - Session-based route access control
- **Deep Link Support** - Universal links (https://shell.app/...) + custom schemes (shell://...)
- **Route Resolution** - URL → Route mapping with scheme-aware parsing
- **AppRouter** - Main router coordinating AuthGuard + AppCoordinator

**Status**: Production ready, comprehensive tests (39 tests across 4 test files)

#### 3. Coordinator Hierarchy (Core/Coordinator/ + App/Coordinators/)

**AppCoordinator** (Root)
- Manages app-level state transitions
- Owns child coordinator lifecycle
- Delegates to feature coordinators
- Receives DI container for dependency creation

**AuthCoordinator** (Child)
- Manages authentication flows (login, signup, forgot password)
- Creates and injects LoginViewModel
- Delegates completion to AppCoordinator via AuthCoordinatorDelegate

**ItemsCoordinator** (Child)
- Manages content flows (list, detail)
- Handles list → detail navigation
- Delegates logout to AppCoordinator via ItemsCoordinatorDelegate

**Status**: Production ready, clean separation of concerns

#### 4. Dependency Injection (Core/DI/)
- **AppDependencyContainer** - Composition root for all dependencies
- **Factory Methods**:
  - Coordinators (App, Auth, Items)
  - Use Cases (RestoreSession, ValidateCredentials)
  - Repositories (SessionRepository)
  - Navigation (Router, AuthGuard, RouteResolver, DeepLinkHandlers)
- **Shared Dependencies**: SessionRepository (singleton pattern for shared state)

**Status**: Production ready, all dependencies properly injected

#### 5. Auth Feature (Features/Auth/)

**Domain Layer**:
- `Credentials` - Domain entity (username, password)
- `AuthError` - Domain errors with user-facing messages
- `ValidateCredentialsUseCase` - Validation business logic (protocol + implementation)
- `RestoreSessionUseCase` - Session restoration logic
- `SessionStatus` - Session state enum

**Presentation Layer**:
- `LoginViewModel` - Presentation logic with Combine @Published properties
  - Properties: username, password, errorMessage, isLoading
  - Delegates to ValidateCredentialsUseCase
  - Communicates success via LoginViewModelDelegate
- `LoginViewController` - Thin view layer with Combine bindings
  - Removed all validation logic (now in use case)
  - Binds to ViewModel via Combine
  - Pure UI updates only

**Status**: LoginViewModel complete, demonstrates MVVM pattern for replication

#### 6. Items Feature (Features/Items/) - **EPIC 2 COMPLETE**

**Domain Layer**:
- `Item` - Domain entity (id, title, subtitle, description, date) - `Sendable` for Swift 6 concurrency
- `ItemsRepository` (protocol) - Repository abstraction for item persistence
- **Full CRUD Use Cases** (protocol + implementation):
  - `GetItemsUseCase` - Fetch all items via repository
  - `CreateItemUseCase` - Create new item with validation
  - `UpdateItemUseCase` - Update existing item
  - `DeleteItemUseCase` - Delete item by ID
- `ItemsError` - Domain errors (notFound, validationFailed, unknown)

**Infrastructure Layer** (NEW):
- `InMemoryItemsRepository` - Actor-based repository implementation
  - Thread-safe item storage using Swift actor
  - In-memory persistence for development/testing
  - Conforms to ItemsRepository protocol

**Presentation Layer**:
- `ItemsListViewModel` - List screen presentation logic
  - Properties: items, isLoading, errorMessage, isEmpty
  - Delegates to GetItemsUseCase and DeleteItemUseCase
  - Handles item selection and deletion
- `ItemEditorViewModel` - Create/Edit screen presentation logic (NEW)
  - Properties: title, subtitle, description, errorMessage, isLoading
  - Delegates to CreateItemUseCase or UpdateItemUseCase
  - Validation logic for required fields
- `ItemsListViewController` - Programmatic list UI (UITableView)
- `ItemEditorViewController` - **Programmatic form UI** (UIScrollView + UIStackView)
  - Demonstrates programmatic Auto Layout patterns
  - Dynamic keyboard handling
  - Form validation and error display

**Status**: Epic 2 complete - Full CRUD with Repository pattern, 31 new tests, programmatic UI established

#### 7. Profile Feature (Features/Profile/)

**Domain Layer**:
- `UserProfile` - Domain entity (screenName, birthday, avatarURL?) - `Sendable` for Swift 6 concurrency
- `IdentityData` - Identity setup data (screenName, birthday) - `Sendable` for Swift 6 concurrency
  - Static validation methods (validateScreenName, validateBirthday)
  - COPPA compliance (13+ age validation)
  - Character validation (alphanumeric, underscore, hyphen only)
- `IdentityValidationError` - Domain validation errors with user-facing messages
- `UserProfileRepository` (protocol) - Repository abstraction for profile persistence
- **Profile Use Cases**:
  - `GetUserProfileUseCase` - Fetch user profile by ID
  - `UpdateUserProfileUseCase` - Update user profile
  - `SetupIdentityUseCase` - Complete identity setup with validation

**Infrastructure Layer**:
- `InMemoryUserProfileRepository` - Actor-based repository implementation
  - Thread-safe profile storage using Swift actor
  - Swift 6 concurrency compliance (inlined computed properties to avoid false positive warnings)
  - In-memory persistence for development/testing

**Presentation Layer**:
- `ProfileViewModel` - Profile screen presentation logic
  - States: idle, loading, loaded(UserProfile), error(ProfileError)
  - Delegates to GetUserProfileUseCase
  - Retry logic for error recovery
- `ProfileViewController` - Programmatic profile UI
  - UIScrollView + UIStackView layout
  - Avatar, screen name, birthday display
  - ErrorBannerView for error handling
  - Combine bindings to ViewModel state

**Status**: Profile domain complete with Repository pattern, identity validation, programmatic UI

#### 8. Application Lifecycle Logging (Core/Logging/) - **EPIC 4 COMPLETE**

**Logging Infrastructure** (NEW):
- `Logger` (protocol) - Logging abstraction with severity levels
- `LogLevel` - Severity levels (debug, info, warning, error, critical)
- `LogCategory` - Semantic categories (app, navigation, auth, network, data, ui, security)
- `OSLogger` - Production logger using OSLog/Unified Logging System
- `ConsoleLogger` - Development logger with formatted console output

**Lifecycle Observers** (NEW):
- `AppLifecycleLogger` - Logs UIApplicationDelegate lifecycle events
  - Launch, foreground/background transitions, termination
  - Memory warnings, significant time changes
  - Protected data availability changes
- `SceneLifecycleLogger` - Logs UISceneDelegate lifecycle events
  - Scene connection/disconnection
  - Foreground/background/active/resigned states
  - Deep link handling (Universal Links, Custom URL schemes)

**Integration**:
- AppDelegate and SceneDelegate instrumented with observers
- Structured logging with categories and severity levels
- Production-ready with OSLog backend
- Development-friendly with ConsoleLogger

**Status**: Epic 4 complete - Comprehensive logging infrastructure, 86 tests, zero warnings

#### 9. Form Validation Framework (SwiftSDK/Validation/) - **TECHNICAL DEBT RESOLVED**

**Validation Infrastructure** (NEW):
- `Validator` (protocol) - Generic validation abstraction
- `AnyValidator` - Type-erased validator wrapper
- `StringLengthValidator` - String length validation with trim support
- `CharacterSetValidator` - Character set validation
- `ComposedValidator` - Validator composition with `.and()` operator

**Field-Level Validation**:
- `FieldValidator<Value>` - Tracks validation state for single field
  - Properties: `value`, `errorMessage`, `isValid`, `isTouched`, `isDirty`
  - Validates on change or on demand
  - Reactive observation via `onChange` callback
  - Initial validation for non-empty values

**Form-Level Validation**:
- `FormValidator` - Orchestrates multiple field validators
  - Properties: `isFormValid`, `hasInteraction`, `isDirty`
  - Registers field validators with reactive observation
  - Aggregates field state for form-level decisions
  - Submit button enable/disable logic

**Status**: Technical debt resolved - 20 validation tests passing, reactive observation working

#### 10. UI Layer (Programmatic UIKit)

**ViewControllers** (Programmatic-First Architecture):
- `LoginViewController` - Login screen (root level, needs migration to Features/Auth/Presentation/)
- `ListViewController` - Items list (root level, needs migration to Features/Items/Presentation/)
- `DetailViewController` - Item detail (root level, needs migration to Features/Items/Presentation/)
- `ItemsListViewController` - Items list (Features/Items/Presentation/List/)
- `ItemEditorViewController` - **Programmatic form UI** (Features/Items/Presentation/Editor/)
  - Demonstrates programmatic Auto Layout with UIScrollView + UIStackView
  - Keyboard handling, form validation, error display
  - Pattern for all future programmatic UI
- `ProfileViewController` - Profile display (Features/Profile/Presentation/)

**Programmatic UI Patterns Established**:
- UIScrollView for scrollable content
- UIStackView for vertical layouts
- NSLayoutConstraint.activate([...]) for Auto Layout
- translatesAutoresizingMaskIntoConstraints = false on all views
- Combine bindings for ViewModel → View updates
- ErrorBannerView for consistent error display
- Dynamic keyboard handling (NotificationCenter + constraint adjustments)

**Storyboard Status**:
- Main.storyboard still exists for legacy ViewControllers (LoginViewController, ListViewController, DetailViewController)
- **ZERO segues** - all navigation via coordinators
- **Future**: Migrate remaining storyboard VCs to programmatic UI

**Status**: Programmatic UI pattern established, legacy storyboard VCs pending migration

#### 11. Infrastructure Organization (Core/Infrastructure/ + Features/*/Infrastructure/)

**Core Infrastructure** (Core/Infrastructure/ + Core/Contracts/):

**Logging** (NEW):
- `Logger` (protocol) - Core/Contracts/Logging/
- `OSLogger` (implementation) - Core/Infrastructure/Logging/
- `ConsoleLogger` (implementation) - Core/Infrastructure/Logging/
- `LogLevel` (enum) - Core/Contracts/Logging/
- `LogCategory` (enum) - Core/Contracts/Logging/

**Lifecycle Observers** (NEW):
- `AppLifecycleLogger` - Core/Infrastructure/Logging/
- `SceneLifecycleLogger` - Core/Infrastructure/Logging/

**Session Management**:
- `SessionRepository` (protocol) - Core/Contracts/Security/
- `InMemorySessionRepository` (implementation) - Core/Infrastructure/Security/
- `UserSession` (entity) - Core/Contracts/Security/

**Configuration**:
- `ConfigLoader` (protocol) - Core/Contracts/Configuration/
- `DefaultConfigLoader` (implementation) - Core/Infrastructure/Configuration/
- `AppConfig` (entity) - Core/Contracts/Configuration/

**Navigation Handlers**:
- `UniversalLinkHandler` - Handles https://shell.app/... links
- `CustomURLSchemeHandler` - Handles shell://... links
- Both delegate to AppRouter for route resolution and navigation

**Feature-Specific Infrastructure** (NEW - Repository Pattern):

**Items Infrastructure** (Features/Items/Infrastructure/):
- `InMemoryItemsRepository` - Actor-based implementation of ItemsRepository
  - Thread-safe with Swift actor concurrency
  - In-memory storage for development/testing
  - Returns `Sendable` Item entities

**Profile Infrastructure** (Features/Profile/Infrastructure/):
- `InMemoryUserProfileRepository` - Actor-based implementation of UserProfileRepository
  - Thread-safe with Swift actor concurrency
  - Swift 6 strict concurrency compliant (inlined computed properties)
  - Returns `Sendable` UserProfile entities

**Infrastructure Organization Rules**:
- **Shared infrastructure** → Core/Infrastructure/ (session, config, navigation)
- **Feature-specific infrastructure** → Features/*/Infrastructure/ (repositories, data sources)
- All infrastructure implements protocols defined in Domain or Core/Contracts
- Actor-based for thread-safety where needed

**Status**: Repository pattern established with actor-based implementations, Swift 6 compliant

## File Structure (Actual - Updated 2026-01-31)

```
Shell/
├── App/
│   ├── Boot/
│   │   ├── AppBootstrapper.swift ✅
│   │   ├── LaunchState.swift ✅
│   │   └── LaunchRouting.swift ✅
│   ├── Coordinators/
│   │   ├── AuthCoordinator.swift ✅
│   │   └── ItemsCoordinator.swift ✅
│   └── Navigation/
│       └── AppRouter.swift ✅
│
├── Core/
│   ├── Coordinator/
│   │   ├── Coordinator.swift ✅
│   │   └── AppCoordinator.swift ✅
│   ├── Contracts/
│   │   ├── Logging/
│   │   │   ├── Logger.swift ✅
│   │   │   ├── LogLevel.swift ✅
│   │   │   └── LogCategory.swift ✅
│   │   ├── Configuration/
│   │   │   ├── AppConfig.swift ✅
│   │   │   └── ConfigLoader.swift ✅
│   │   ├── Navigation/
│   │   │   ├── DeepLinkHandler.swift ✅
│   │   │   ├── Router.swift ✅
│   │   │   ├── RouteAccessControl.swift ✅
│   │   │   └── RouteResolver.swift ✅
│   │   ├── Networking/
│   │   │   └── HTTPClient.swift ✅
│   │   └── Security/
│   │       ├── SessionRepository.swift ✅
│   │       └── UserSession.swift ✅
│   ├── DI/
│   │   └── AppDependencyContainer.swift ✅
│   ├── Infrastructure/
│   │   ├── Configuration/
│   │   │   └── DefaultConfigLoader.swift ✅
│   │   ├── Logging/
│   │   │   ├── OSLogger.swift ✅
│   │   │   ├── ConsoleLogger.swift ✅
│   │   │   ├── AppLifecycleLogger.swift ✅
│   │   │   └── SceneLifecycleLogger.swift ✅
│   │   ├── Navigation/
│   │   │   ├── CustomURLSchemeHandler.swift ✅
│   │   │   ├── UniversalLinkHandler.swift ✅
│   │   │   └── UniversalLinkHandler+Notification.swift ✅
│   │   └── Security/
│   │       └── InMemorySessionRepository.swift ✅
│   └── Navigation/
│       ├── AuthGuard.swift ✅
│       ├── DefaultRouteResolver.swift ✅
│       ├── Route.swift ✅
│       └── RouteParameters.swift ✅
│
├── Features/
│   ├── Auth/
│   │   ├── Domain/
│   │   │   ├── Entities/
│   │   │   │   └── Credentials.swift ✅
│   │   │   ├── Errors/
│   │   │   │   └── AuthError.swift ✅
│   │   │   ├── SessionStatus.swift ✅
│   │   │   └── UseCases/
│   │   │       ├── RestoreSessionUseCase.swift ✅
│   │   │       └── ValidateCredentialsUseCase.swift ✅
│   │   └── Presentation/
│   │       └── Login/
│   │           └── LoginViewModel.swift ✅
│   │
│   ├── Items/
│   │   ├── Domain/
│   │   │   ├── Entities/
│   │   │   │   └── Item.swift ✅ (Sendable)
│   │   │   ├── Errors/
│   │   │   │   └── ItemsError.swift ✅
│   │   │   ├── ItemsRepository.swift ✅ (protocol)
│   │   │   └── UseCases/
│   │   │       ├── GetItemsUseCase.swift ✅
│   │   │       ├── CreateItemUseCase.swift ✅
│   │   │       ├── UpdateItemUseCase.swift ✅
│   │   │       └── DeleteItemUseCase.swift ✅
│   │   ├── Infrastructure/
│   │   │   └── InMemoryItemsRepository.swift ✅ (actor-based)
│   │   └── Presentation/
│   │       ├── List/
│   │       │   ├── ItemsListViewController.swift ✅
│   │       │   └── ItemsListViewModel.swift ✅
│   │       └── Editor/
│   │           ├── ItemEditorViewController.swift ✅ (programmatic UI)
│   │           └── ItemEditorViewModel.swift ✅
│   │
│   └── Profile/
│       ├── Domain/
│       │   ├── Entities/
│       │   │   └── UserProfile.swift ✅ (Sendable)
│       │   ├── Errors/
│       │   │   └── ProfileError.swift ✅
│       │   ├── IdentityData.swift ✅ (Sendable, validation)
│       │   ├── UserProfileRepository.swift ✅ (protocol)
│       │   └── UseCases/
│       │       ├── GetUserProfileUseCase.swift ✅
│       │       ├── UpdateUserProfileUseCase.swift ✅
│       │       └── SetupIdentityUseCase.swift ✅
│       ├── Infrastructure/
│       │   └── InMemoryUserProfileRepository.swift ✅ (actor-based)
│       └── Presentation/
│           ├── ProfileViewController.swift ✅ (programmatic UI)
│           └── ProfileViewModel.swift ✅
│
├── SwiftSDK/
│   └── Validation/
│       ├── Validator.swift ✅
│       ├── AnyValidator.swift ✅
│       ├── StringLengthValidator.swift ✅
│       ├── CharacterSetValidator.swift ✅
│       ├── ComposedValidator.swift ✅
│       ├── FieldValidator.swift ✅
│       └── FormValidator.swift ✅
│
├── Shared/
│   └── UI/
│       └── ErrorBannerView.swift ✅
│
├── LoginViewController.swift ⚠️  (root level - needs migration to Features/Auth/Presentation/)
├── ListViewController.swift ⚠️  (root level - needs migration to Features/Items/Presentation/)
├── DetailViewController.swift ⚠️  (root level - needs migration to Features/Items/Presentation/)
│
├── AppDelegate.swift ✅ (Universal Links handler)
├── SceneDelegate.swift ✅ (Universal Links integration)
└── Base.lproj/
    ├── Main.storyboard ⚠️  (legacy - supports root level VCs)
    └── LaunchScreen.storyboard ✅

ShellTests/
├── SwiftSDK/
│   └── Validation/
│       ├── StringLengthValidatorTests.swift ✅
│       ├── CharacterSetValidatorTests.swift ✅
│       ├── ComposedValidatorTests.swift ✅
│       ├── FieldValidatorTests.swift ✅
│       └── FormValidatorTests.swift ✅
├── Core/
│   └── Logging/
│       ├── OSLoggerTests.swift ✅
│       ├── ConsoleLoggerTests.swift ✅
│       ├── AppLifecycleLoggerTests.swift ✅
│       └── SceneLifecycleLoggerTests.swift ✅
├── Features/
│   ├── Auth/
│   │   ├── Domain/
│   │   │   └── UseCases/
│   │   │       ├── ValidateCredentialsUseCaseTests.swift ✅
│   │   │       └── RestoreSessionUseCaseTests.swift ✅
│   │   └── Presentation/
│   │       └── LoginViewModelTests.swift ✅
│   ├── Items/
│   │   ├── Domain/
│   │   │   └── UseCases/
│   │   │       ├── GetItemsUseCaseTests.swift ✅
│   │   │       ├── CreateItemUseCaseTests.swift ✅
│   │   │       ├── UpdateItemUseCaseTests.swift ✅
│   │   │       └── DeleteItemUseCaseTests.swift ✅
│   │   ├── Infrastructure/
│   │   │   └── InMemoryItemsRepositoryTests.swift ✅
│   │   └── Presentation/
│   │       ├── ItemsListViewModelTests.swift ✅
│   │       └── ItemEditorViewModelTests.swift ✅
│   └── Profile/
│       ├── Domain/
│       │   ├── IdentityDataTests.swift ✅
│       │   └── UseCases/
│       │       ├── GetUserProfileUseCaseTests.swift ✅
│       │       ├── UpdateUserProfileUseCaseTests.swift ✅
│       │       └── SetupIdentityUseCaseTests.swift ✅
│       ├── Infrastructure/
│       │   └── InMemoryUserProfileRepositoryTests.swift ✅
│       └── Presentation/
│           └── ProfileViewModelTests.swift ✅
├── Core/
│   └── Navigation/
│       ├── RouteResolverTests.swift ✅
│       ├── AuthGuardTests.swift ✅
│       ├── RouteParametersTests.swift ✅
│       └── DeepLinkHandlerTests.swift ✅
└── App/
    └── Boot/
        └── AppBootstrapperTests.swift ✅

Docs/
├── apple-app-site-association.json ✅ (AASA file template)
└── UniversalLinks-Setup.md ✅ (Comprehensive setup guide)

.claude/
├── Agents/ (11 files)
└── Context/ (13 files including this one)
```

## Current Navigation Flow

```
App Launch
  ↓
AppBootstrapper.start()
  ├─ RestoreSessionUseCase.execute()
  └─ router.route(to: LaunchState)
      ↓
AppCoordinator.route(to:)
  ├─ .unauthenticated → AuthCoordinator.start()
  │   └─ LoginViewController + LoginViewModel
  │       ↓ (user logs in)
  │   loginViewModelDidSucceed()
  │       ↓
  │   authCoordinatorDidCompleteLogin()
  │       ↓
  └─ .authenticated → ItemsCoordinator.start()
      └─ ListViewController
          ↓ (user taps item)
      listViewController(_:didSelectItem:)
          ↓
      ItemsCoordinator.showDetail(for:)
          └─ DetailViewController
```

## Deep Link Flow

### Universal Links Flow (https://shell.app/...)

```
User taps link: https://shell.app/profile/user123
  ↓
iOS checks AASA file → Launches app
  ↓
SceneDelegate.scene(_:continue:) receives NSUserActivity
  ↓
AppDelegate.handleUniversalLink() extracts URL
  ↓
Posts Notification.Name.handleUniversalLink with URL
  ↓
AppCoordinator.handleUniversalLinkNotification() receives notification
  ↓
Creates AppRouter via DI container
  ↓
AppRouter.navigate(to: URL)
  ├─ DefaultRouteResolver.resolve(url:) → Route.profile(userID: "user123")
  └─ AppRouter.navigate(to: Route)
      ↓
      AuthGuard.canAccess(route:)
      ├─ .allowed → AppCoordinator routes to screen
      └─ .denied(.unauthenticated) → AppCoordinator saves route + shows login
```

### Custom URL Scheme Flow (shell://...)

```
User taps link: shell://profile/user123
  ↓
SceneDelegate.scene(_:openURLContexts:)
  ↓
SceneDelegate.handleDeepLink()
  ↓
CustomURLSchemeHandler.handle(url:)
  ↓
DefaultRouteResolver.resolve(url:) → Route.profile(userID: "user123")
  ↓
AppRouter.navigate(to:)
  ↓
AuthGuard.canAccess(route:)
  ├─ .allowed → AppCoordinator routes to screen
  └─ .denied(.unauthenticated) → AppCoordinator routes to login
```

## Testing Infrastructure - 301 Tests Passing ✅

### Unit Tests (ShellTests/) - 301 Tests

**Epic 1: Navigation & Boot** (39 tests):
- `RouteResolverTests` - URL → Route mapping
- `AuthGuardTests` - Session-based access control
- `RouteParametersTests` - Parameter validation
- `DeepLinkHandlerTests` - Deep link integration
- `AppBootstrapperTests` - Boot sequence logic

**Epic 1: Auth Feature** (~26 tests):
- `ValidateCredentialsUseCaseTests` - Credential validation rules
  - Success cases (valid credentials, minimum lengths)
  - Username failures (empty, too short)
  - Password failures (empty, too short)
  - Validation priority tests
- `RestoreSessionUseCaseTests` - Session restoration logic
- `LoginViewModelTests` - Presentation logic
  - Initial state verification
  - Success scenarios with delegate calls
  - Failure scenarios with error messages
  - Combine publisher behavior

**Epic 2: Items CRUD Feature** (31 tests - NEW):
- `GetItemsUseCaseTests` - Data fetching via repository
- `CreateItemUseCaseTests` - Item creation with validation
- `UpdateItemUseCaseTests` - Item updates
- `DeleteItemUseCaseTests` - Item deletion
- `InMemoryItemsRepositoryTests` - Actor-based repository testing
  - Thread-safety verification
  - CRUD operations
  - Error handling
- `ItemsListViewModelTests` - List presentation logic
- `ItemEditorViewModelTests` - Editor presentation logic
  - Create mode validation
  - Edit mode validation
  - Error handling

**Epic 4: Logging Infrastructure** (86 tests - NEW):
- `OSLoggerTests` - Production logger verification
  - Log level filtering
  - Category-based logging
  - Message formatting
- `ConsoleLoggerTests` - Development logger verification
  - Console output formatting
  - Color coding (if supported)
  - Message structure
- `AppLifecycleLoggerTests` - Application lifecycle logging
  - Launch, foreground/background events
  - Memory warnings
  - Termination logging
- `SceneLifecycleLoggerTests` - Scene lifecycle logging
  - Scene state transitions
  - Deep link logging
  - Multi-window support

**Validation Framework** (20 tests - NEW):
- `StringLengthValidatorTests` - String validation (6 tests)
- `CharacterSetValidatorTests` - Character set validation (6 tests)
- `ComposedValidatorTests` - Validator composition (5 tests)
- `FieldValidatorTests` - Field-level validation (12 tests)
  - Initial state, validation modes
  - Error messaging, state tracking
  - Touch and dirty state management
- `FormValidatorTests` - Form-level orchestration (8 tests)
  - Form validity aggregation
  - Reactive observation
  - Field interaction tracking

**Profile Feature** (~99 tests):
- `IdentityDataTests` - Identity validation logic
  - Screen name validation (length, characters, edge cases)
  - Birthday validation (age limits, COPPA compliance, future dates)
  - Combined validation flows
- `GetUserProfileUseCaseTests` - Profile fetching
- `UpdateUserProfileUseCaseTests` - Profile updates
- `SetupIdentityUseCaseTests` - Identity setup flow
- `InMemoryUserProfileRepositoryTests` - Actor-based repository testing
  - Thread-safety verification
  - Profile CRUD operations
  - Identity setup completion tracking
- `ProfileViewModelTests` - Profile presentation logic
  - State management (idle, loading, loaded, error)
  - Retry logic
  - Error recovery

**Testing Patterns Established**:
- Protocol-based mocking for repositories and use cases
- Spy pattern for testing use case interactions
- Combine publisher testing with expectations
- Async/await testing patterns
- Actor isolation testing for repositories
- Domain validation testing (IdentityData as exemplar)
- ViewModel state machine testing
- Use cases fully unit testable (no UIKit dependencies)
- ViewModels testable without views
- Repository testing with thread-safety verification

### UI Tests (ShellUITests/)
- Launch performance tests
- Basic UI flow tests

**Status**: 301/301 tests passing, zero warnings, Swift 6 strict concurrency compliant

## What's Working Now (Updated 2026-01-31)

### Core Architecture
✅ App boots and checks session
✅ Shows login screen when unauthenticated
✅ Login validates credentials via use case
✅ Deep links resolve to type-safe routes
✅ Auth guard enforces session requirements
✅ All navigation coordinator-driven (zero segues in new code)
✅ Post-login redirects working (denied routes restored after authentication)
✅ Universal Links code implemented (ready for AASA hosting and Xcode configuration)

### Epic 2: Items CRUD (COMPLETE)
✅ Full CRUD operations via Repository pattern
✅ Create, Read, Update, Delete items with validation
✅ Actor-based InMemoryItemsRepository (thread-safe)
✅ ItemEditorViewController demonstrates programmatic UI pattern
✅ Programmatic Auto Layout with UIScrollView + UIStackView
✅ Dynamic keyboard handling
✅ Form validation and error display
✅ 31 new tests for Epic 2 (all passing)

### Profile Feature (COMPLETE)
✅ User profile display with ProfileViewController
✅ Identity validation (screen name, birthday, COPPA compliance)
✅ Actor-based InMemoryUserProfileRepository (thread-safe)
✅ Profile ViewModel with state management (idle, loading, loaded, error)
✅ Error recovery with retry logic
✅ Comprehensive validation testing (99+ tests)

### Swift 6 Compliance
✅ **Zero warnings** (excluding system AppIntents warning)
✅ Swift 6 strict concurrency mode enabled
✅ Domain models marked `Sendable` (UserProfile, Item, IdentityData)
✅ Actor-based repositories for thread-safety
✅ No main actor isolation warnings

### Testing
✅ **301/301 tests passing** (195 original + 86 logging + 20 validation)
✅ Repository pattern tested with actor isolation
✅ Domain validation tested (IdentityData exemplar)
✅ ViewModel state machines tested
✅ Use case business logic tested
✅ Async/await patterns tested

## Completed Work

### Epic 1: Foundation (COMPLETE)
- ✅ Clean Architecture + MVVM + Coordinator pattern
- ✅ Type-safe navigation with Route enum
- ✅ Auth guard and deep link support
- ✅ LoginViewModel + ValidateCredentialsUseCase
- ✅ Post-login redirects (denied routes restored after auth)
- ✅ Universal Links infrastructure (code ready, needs manual Xcode/Apple config)
- ✅ 39 navigation tests + ~26 auth tests

### Epic 2: Items CRUD (COMPLETE)
- ✅ Repository pattern with ItemsRepository protocol
- ✅ Actor-based InMemoryItemsRepository
- ✅ Full CRUD use cases (Get, Create, Update, Delete)
- ✅ ItemsListViewModel + ItemEditorViewModel
- ✅ Programmatic UI pattern (ItemEditorViewController)
- ✅ 31 Epic 2 tests (repository + use cases + ViewModels)

### Profile Feature (COMPLETE)
- ✅ UserProfile and IdentityData domain models (Sendable)
- ✅ Identity validation (screen name, birthday, COPPA compliance)
- ✅ Actor-based InMemoryUserProfileRepository
- ✅ Profile use cases (Get, Update, SetupIdentity)
- ✅ ProfileViewModel with state management
- ✅ ProfileViewController (programmatic UI)
- ✅ ~99 profile tests (validation + repository + use cases + ViewModel)

### Epic 4: Application Lifecycle Logging (COMPLETE - 2026-02-03)
- ✅ Logger protocol abstraction with severity levels and categories
- ✅ OSLogger (production) using Unified Logging System
- ✅ ConsoleLogger (development) with formatted output
- ✅ AppLifecycleLogger tracking UIApplicationDelegate events
- ✅ SceneLifecycleLogger tracking UISceneDelegate events
- ✅ Deep link logging (Universal Links + Custom URL schemes)
- ✅ 86 logging tests (all passing)
- ✅ Integrated into AppDelegate and SceneDelegate

### Validation Framework (COMPLETE - 2026-02-04)
- ✅ Generic Validator protocol with type erasure
- ✅ Concrete validators (StringLengthValidator, CharacterSetValidator)
- ✅ Validator composition with `.and()` operator
- ✅ FieldValidator for single field state tracking
- ✅ FormValidator for multi-field orchestration
- ✅ Reactive observation pattern with onChange callbacks
- ✅ Initial validation for non-empty values
- ✅ 20 validation tests (all passing)
- ✅ Fixed Swift concurrency crashes (@MainActor async test methods)

### Swift 6 Compliance (COMPLETE)
- ✅ Zero code warnings
- ✅ Sendable conformance for domain models
- ✅ Actor-based repositories for thread-safety
- ✅ Strict concurrency mode enabled

## Pending Work (Roadmap)

### 1. Programmatic UI Migration (Partially Complete)
- ✅ ItemEditorViewController (programmatic pattern established)
- ✅ ProfileViewController (programmatic)
- ⚠️  LoginViewController (still on storyboard - needs migration to Features/Auth/Presentation/)
- ⚠️  ListViewController (still on storyboard - needs migration to Features/Items/Presentation/)
- ⚠️  DetailViewController (still on storyboard - needs migration to Features/Items/Presentation/)
- ⚠️  Remove Main.storyboard after migration complete

### 2. Universal Links Configuration (Manual Steps)
- ⚠️  Enable Associated Domains capability in Apple Developer Portal
- ⚠️  Add applinks:shell.app to Xcode entitlements
- ⚠️  Host AASA file at https://shell.app/.well-known/apple-app-site-association
- ⚠️  Replace TEAMID placeholder with actual Apple Team ID
- ⚠️  Regenerate provisioning profiles after enabling capability

### 3. Form UI Integration
- 📋 Integrate validation framework into login form
- 📋 Integrate validation framework into item editor form
- 📋 Integrate validation framework into profile editor form
- 📋 Real-time error display with validation state
- 📋 Submit button enable/disable based on form validity

### 4. Additional Features (Future Epics)
- 📋 Real API integration (replace in-memory repositories)
- 📋 Keychain session persistence (KeychainSessionRepository)
- 📋 Settings screen + SettingsCoordinator
- 📋 Identity setup flow UI (multi-step coordinator)
- 📋 Profile editing UI
- 📋 Image upload for avatars
- 📋 Network error handling patterns

## Key Patterns Demonstrated

### 1. MVVM with Clean Architecture + Repository Pattern
```swift
View (ItemEditorViewController - programmatic UI)
  ↓ binds to
ViewModel (ItemEditorViewModel)
  ↓ uses
Use Case (CreateItemUseCase)
  ↓ uses
Repository Protocol (ItemsRepository)
  ↓ implemented by
Repository Implementation (InMemoryItemsRepository - actor)
  ↓ stores
Domain Entity (Item - Sendable)
```

### 2. Repository Pattern (Epic 2)
```swift
// Domain layer defines protocol
protocol ItemsRepository {
    func getAll() async throws -> [Item]
    func create(_ item: Item) async throws
    func update(_ item: Item) async throws
    func delete(id: String) async throws
}

// Infrastructure layer implements with actor for thread-safety
actor InMemoryItemsRepository: ItemsRepository {
    private var items: [String: Item] = [:]

    func getAll() async throws -> [Item] {
        Array(items.values).sorted { $0.date > $1.date }
    }
}

// Use cases depend on protocol (not implementation)
struct CreateItemUseCase {
    private let repository: ItemsRepository

    func execute(item: Item) async throws {
        try await repository.create(item)
    }
}
```

### 3. Swift 6 Sendable Pattern
```swift
// Domain models crossing actor boundaries must be Sendable
struct Item: Equatable, Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let description: String
    let date: Date
}

struct UserProfile: Equatable, Codable, Sendable {
    let screenName: String
    let birthday: Date
    let avatarURL: URL?
}
```

### 4. Programmatic UI Pattern (ItemEditorViewController)
```swift
// UIScrollView + UIStackView for forms
private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
}()

private lazy var stackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
}()

// Layout constraints
NSLayoutConstraint.activate([
    scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
    scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
    scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

    stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
    stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
    stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
    stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
])
```

### 5. Domain Validation Pattern (IdentityData)
```swift
struct IdentityData: Equatable, Codable, Sendable {
    let screenName: String
    let birthday: Date

    // Validation as static methods
    static func validateScreenName(_ screenName: String) -> Result<String, IdentityValidationError> {
        let trimmed = screenName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return .failure(.screenNameTooShort) }
        guard trimmed.count <= 20 else { return .failure(.screenNameTooLong) }
        // ... more validation
        return .success(trimmed)
    }

    // Factory method with combined validation
    static func create(screenName: String, birthday: Date) -> Result<IdentityData, IdentityValidationError> {
        // Validate all fields before creating
    }
}
```

### 6. Coordinator Pattern
- Parent coordinators own child coordinator lifecycle
- Children delegate completion events to parents
- Coordinators create and inject ViewModels
- No ViewController knows about other ViewControllers

### 7. Dependency Injection
- Composition root (AppDependencyContainer) creates all objects
- Dependencies flow inward (Presentation → Domain ← Infrastructure)
- Protocols define boundaries (ItemsRepository, UserProfileRepository)
- Easy to swap implementations (testing, feature flags)

### 8. Type-Safe Navigation
- Routes are compile-time safe (enum)
- Parameters validated before navigation
- Auth guards enforce access rules
- Deep links map to same Route enum

## Critical Rules (Updated 2026-01-31)

### Never Do This
❌ ViewControllers creating other ViewControllers
❌ Segues in storyboards (new VCs must be programmatic)
❌ Business logic in ViewControllers
❌ Domain layer importing UIKit
❌ Data layer exposing DTOs to domain
❌ Direct repository access from ViewControllers (use Use Cases)
❌ Singletons (except AppDependencyContainer and shared session state)
❌ String-based navigation
❌ Force unwrapping optionals in production code
❌ Non-Sendable domain models crossing actor boundaries
❌ Accessing computed properties from actors (inline instead)
❌ Storyboards for new ViewControllers (use programmatic UI)

### Always Do This
✅ Coordinators handle ALL navigation
✅ ViewModels hold presentation logic
✅ Use Cases encapsulate business operations
✅ Repository pattern for data access (protocol in Domain, implementation in Infrastructure)
✅ Actor-based repositories for thread-safety
✅ Sendable conformance for domain models (Item, UserProfile, IdentityData)
✅ Dependency injection for all dependencies
✅ Protocol boundaries between layers (Domain/Presentation/Infrastructure)
✅ Type-safe routes (enum Route)
✅ Auth guards before route access
✅ Unit tests for business logic (use cases, repositories, ViewModels)
✅ Spy pattern for testing use case interactions
✅ Programmatic UI for new ViewControllers (UIScrollView + UIStackView pattern)
✅ Domain validation with static methods (IdentityData pattern)
✅ Swift 6 strict concurrency compliance

## Next Immediate Steps

### High Priority
1. **Migrate Legacy ViewControllers to Programmatic UI**
   - Move LoginViewController from root to Features/Auth/Presentation/Login/
   - Move ListViewController from root to Features/Items/Presentation/List/
   - Move DetailViewController from root to Features/Items/Presentation/Detail/
   - Convert all three from storyboard to programmatic UI (follow ItemEditorViewController pattern)
   - Remove Main.storyboard after migration complete

### Medium Priority
2. **Complete Universal Links Configuration** (Manual Steps)
   - Enable Associated Domains in Apple Developer Portal
   - Configure Xcode entitlements with applinks:shell.app
   - Host AASA file on production domain
   - Update TEAMID placeholder with actual Team ID
   - Test with simulator and real device

### Future Epics
3. **Real API Integration**
   - Replace InMemoryItemsRepository with HTTPItemsRepository
   - Replace InMemoryUserProfileRepository with HTTPUserProfileRepository
   - Implement proper error handling for network failures
   - Add retry logic and offline support

4. **Additional Features**
   - Settings screen + SettingsCoordinator
   - Identity setup flow UI (multi-step coordinator)
   - Profile editing UI
   - Image upload for avatars

## Build Status (Updated 2026-02-04)

✅ **Builds**: Successfully compiles
✅ **Warnings**: **ZERO code warnings** (excluding system AppIntents warning)
✅ **Tests**: **301/301 tests passing** (navigation, auth, items, profile, logging, validation)
✅ **Swift 6**: Strict concurrency mode enabled, fully compliant
✅ **Runtime**: App launches and runs correctly
✅ **Architecture**: Clean Architecture + MVVM + Repository pattern established
✅ **Logging**: Comprehensive lifecycle logging with OSLog + ConsoleLogger
✅ **Validation**: Production-ready form validation framework
✅ **Programmatic UI**: Pattern established (ItemEditorViewController, ProfileViewController)
✅ **Thread Safety**: Actor-based repositories (InMemoryItemsRepository, InMemoryUserProfileRepository)
✅ **Deep Links**: Post-login redirects working

## Documentation

- Full navigation system docs: `Docs/Test-04.md`
- Storyboard UI docs: `Docs/Test-01.md`
- Universal Links setup guide: `Docs/UniversalLinks-Setup.md`
- AASA file template: `Docs/apple-app-site-association.json`
- Context files: `.claude/Context/`
- This file: Current state reference

---

## Patterns to Replicate

### For Features with Data Persistence (follow Epic 2 Items CRUD pattern):

1. **Domain Layer** (Features/[Feature]/Domain/):
   - Entities with `Sendable` conformance (Item.swift)
   - Domain errors (ItemsError.swift)
   - Repository protocol (ItemsRepository.swift)
   - Use case protocols + implementations (GetItemsUseCase, CreateItemUseCase, etc.)

2. **Infrastructure Layer** (Features/[Feature]/Infrastructure/):
   - Actor-based repository implementation (InMemoryItemsRepository.swift)
   - Conforms to Domain repository protocol
   - Thread-safe with Swift actor concurrency

3. **Presentation Layer** (Features/[Feature]/Presentation/):
   - ViewModels with @Published properties (ItemsListViewModel, ItemEditorViewModel)
   - Programmatic ViewControllers (ItemEditorViewController pattern)
   - UIScrollView + UIStackView for forms
   - Combine bindings for ViewModel → View updates

4. **Testing**:
   - Repository tests (thread-safety, CRUD operations)
   - Use case tests (business logic validation)
   - ViewModel tests (state management, Combine publishers)

### For Features with Domain Validation (follow IdentityData pattern):

1. **Domain Validation**:
   ```swift
   struct IdentityData: Equatable, Codable, Sendable {
       // Static validation methods
       static func validateScreenName(_ name: String) -> Result<String, Error>
       static func validateBirthday(_ date: Date) -> Result<Date, Error>

       // Factory method with combined validation
       static func create(...) -> Result<IdentityData, Error>
   }
   ```

2. **Comprehensive Validation Testing**:
   - Test all success cases
   - Test all failure cases (empty, too short, too long, invalid characters, etc.)
   - Test edge cases (minimum values, maximum values, boundary conditions)
   - Test error messages for user-facing clarity

### For Programmatic UI (follow ItemEditorViewController pattern):

```swift
// 1. Lazy var properties with closures
private lazy var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
}()

// 2. Layout in viewDidLoad
NSLayoutConstraint.activate([
    scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
    // ... more constraints
])

// 3. Combine bindings
viewModel.$state
    .receive(on: DispatchQueue.main)
    .sink { [weak self] state in
        self?.updateUI(for: state)
    }
    .store(in: &cancellables)
```

---

## Recent Work (Feb 2026)

### Epic 4: Application Lifecycle Logging (PRs 4-6)
**Completed**: 2026-02-03
- Comprehensive logging infrastructure with Logger protocol
- OSLogger (production) and ConsoleLogger (development)
- AppLifecycleLogger and SceneLifecycleLogger observers
- 86 tests covering all logging scenarios
- Integrated into app lifecycle (AppDelegate, SceneDelegate)

### Validation Framework (Technical Debt)
**Completed**: 2026-02-04
- Generic validation framework with composable validators
- FieldValidator and FormValidator for reactive form validation
- Fixed 20 crashing tests (Swift concurrency @MainActor issue)
- Resolved by using @MainActor async throws on test methods
- All 20 validation tests now passing

---

**Current Architecture Quality**: Production-ready with 301 tests, zero warnings, Swift 6 compliant, comprehensive logging
