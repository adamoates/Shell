# Project Structure (STRICT)

## Overview

The Shell iOS app follows **Clean Architecture** with clear layer separation and feature-based organization.

## High-Level Structure

```
Shell/
├── App/                       # Application entry point & composition
├── Features/                  # Feature modules (vertical slices)
├── Shared/                    # Shared infrastructure & utilities
├── Resources/                 # Assets, localization, plists
ShellTests/                    # Unit & integration tests
ShellUITests/                  # UI tests
Docs/                          # Documentation
.claude/                       # Claude Code configuration
```

## Detailed Structure

### App/ Directory

Application-level concerns: entry point, composition root, coordinators.

```
App/
├── AppDelegate.swift          # App lifecycle
├── SceneDelegate.swift        # Scene lifecycle
├── CompositionRoot/
│   ├── AppDependencies.swift  # DI container (wiring)
│   ├── AppCoordinator.swift   # Root coordinator
│   └── ViewControllerFactory.swift
└── Configuration/
    ├── Environment.swift       # Environment config (dev/staging/prod)
    └── FeatureFlags.swift     # Feature toggle system
```

### Features/ Directory

Feature modules with full vertical slices (Domain → Data → UI).

```
Features/
├── Auth/
│   ├── Domain/
│   │   ├── Entities/
│   │   │   ├── User.swift
│   │   │   └── Credentials.swift
│   │   ├── UseCases/
│   │   │   ├── LoginUseCase.swift
│   │   │   ├── LogoutUseCase.swift
│   │   │   └── ValidateCredentialsUseCase.swift
│   │   ├── Repositories/
│   │   │   └── AuthRepository.swift (protocol)
│   │   └── Errors/
│   │       └── AuthError.swift
│   ├── Data/
│   │   ├── Repositories/
│   │   │   └── DefaultAuthRepository.swift
│   │   ├── DataSources/
│   │   │   ├── RemoteAuthDataSource.swift
│   │   │   └── LocalAuthDataSource.swift
│   │   ├── DTOs/
│   │   │   ├── LoginRequestDTO.swift
│   │   │   └── LoginResponseDTO.swift
│   │   └── Mappers/
│   │       └── UserMapper.swift
│   └── Presentation/
│       ├── Login/
│       │   ├── LoginViewController.swift
│       │   ├── LoginViewModel.swift
│       │   └── LoginCoordinator.swift
│       └── Models/
│           └── UserUIModel.swift
│
├── Notes/
│   ├── Domain/
│   │   ├── Entities/
│   │   │   └── Note.swift
│   │   ├── UseCases/
│   │   │   ├── FetchNotesUseCase.swift
│   │   │   ├── CreateNoteUseCase.swift
│   │   │   ├── UpdateNoteUseCase.swift
│   │   │   └── DeleteNoteUseCase.swift
│   │   ├── Repositories/
│   │   │   └── NoteRepository.swift (protocol)
│   │   └── Errors/
│   │       └── NoteError.swift
│   ├── Data/
│   │   ├── Repositories/
│   │   │   └── DefaultNoteRepository.swift
│   │   ├── DataSources/
│   │   │   ├── RemoteNoteDataSource.swift
│   │   │   └── LocalNoteDataSource.swift (Core Data)
│   │   ├── DTOs/
│   │   │   └── NoteDTO.swift
│   │   └── Mappers/
│   │       └── NoteMapper.swift
│   └── Presentation/
│       ├── List/
│       │   ├── NotesListViewController.swift
│       │   ├── NotesListViewModel.swift
│       │   ├── NoteCell.swift
│       │   └── NotesCoordinator.swift
│       ├── Detail/
│       │   ├── NoteDetailViewController.swift
│       │   └── NoteDetailViewModel.swift
│       ├── Editor/
│       │   ├── NoteEditorView.swift (SwiftUI)
│       │   └── NoteEditorViewModel.swift
│       └── Models/
│           └── NoteUIModel.swift
│
└── Settings/
    ├── Domain/
    ├── Data/
    └── Presentation/
```

### Shared/ Directory

Reusable infrastructure and utilities.

```
Shared/
├── Networking/
│   ├── HTTPClient.swift (protocol)
│   ├── URLSessionAdapter.swift
│   ├── Decorators/
│   │   ├── AuthenticatedHTTPClient.swift
│   │   ├── LoggingHTTPClient.swift
│   │   └── RetryHTTPClient.swift
│   ├── Models/
│   │   ├── HTTPRequest.swift
│   │   ├── HTTPResponse.swift
│   │   └── HTTPError.swift
│   └── Strategies/
│       ├── RetryStrategy.swift
│       └── ExponentialBackoffStrategy.swift
│
├── Persistence/
│   ├── CoreData/
│   │   ├── CoreDataStack.swift
│   │   ├── Shell.xcdatamodeld
│   │   ├── ManagedObjectModels/
│   │   │   ├── NoteManagedObject+CoreDataClass.swift
│   │   │   └── NoteManagedObject+CoreDataProperties.swift
│   │   └── Migrations/
│   │       └── ModelVersion1to2Migration.swift
│   └── UserDefaults/
│       └── UserDefaultsStorage.swift
│
├── Security/
│   ├── SecureStorage.swift (Facade)
│   ├── KeychainWrapper.swift
│   ├── BiometricAuthentication.swift
│   └── TokenManager.swift
│
├── Utilities/
│   ├── Extensions/
│   │   ├── String+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   └── UIView+Extensions.swift
│   ├── Helpers/
│   │   ├── IDGenerator.swift
│   │   ├── Clock.swift
│   │   └── Logger.swift
│   └── Protocols/
│       └── Coordinator.swift
│
└── TestsSupport/
    ├── Mocks/
    │   ├── MockNoteRepository.swift
    │   ├── MockHTTPClient.swift
    │   └── MockAuthRepository.swift
    ├── Stubs/
    │   ├── StubURLProtocol.swift
    │   └── StubNoteDataSource.swift
    ├── Fakes/
    │   ├── FakeNoteRepository.swift
    │   └── FakeCoreDataStack.swift
    ├── Builders/
    │   ├── Note+TestBuilder.swift
    │   └── User+TestBuilder.swift
    └── Utilities/
        ├── XCTestCase+Async.swift
        └── NSPersistentContainer+InMemory.swift
```

### Resources/ Directory

Assets, strings, storyboards, plists.

```
Resources/
├── Assets.xcassets/
│   ├── AppIcon.appiconset/
│   ├── Colors/
│   │   ├── primaryColor.colorset/
│   │   └── secondaryColor.colorset/
│   └── Icons/
│       └── note-icon.imageset/
├── Localization/
│   ├── en.lproj/
│   │   └── Localizable.strings
│   └── es.lproj/
│       └── Localizable.strings
├── Storyboards/
│   ├── LaunchScreen.storyboard
│   └── Login.storyboard
└── Plists/
    ├── Info.plist
    └── Shell.entitlements
```

### Tests Directory

Mirror the app structure for tests.

```
ShellTests/
├── Features/
│   ├── Auth/
│   │   ├── Domain/
│   │   │   ├── LoginUseCaseTests.swift
│   │   │   └── CredentialsTests.swift
│   │   ├── Data/
│   │   │   ├── DefaultAuthRepositoryTests.swift
│   │   │   └── RemoteAuthDataSourceTests.swift
│   │   └── Presentation/
│   │       └── LoginViewModelTests.swift
│   └── Notes/
│       ├── Domain/
│       │   ├── FetchNotesUseCaseTests.swift
│       │   └── NoteTests.swift
│       ├── Data/
│       │   ├── DefaultNoteRepositoryTests.swift
│       │   └── CoreDataNoteDataSourceTests.swift
│       └── Presentation/
│           ├── NotesListViewModelTests.swift
│           └── NoteDetailViewModelTests.swift
└── Shared/
    ├── Networking/
    │   ├── URLSessionAdapterTests.swift
    │   └── RetryHTTPClientTests.swift
    └── Security/
        └── SecureStorageTests.swift

ShellUITests/
├── LoginUITests.swift
├── NotesFlowUITests.swift
└── PageObjects/
    ├── LoginScreen.swift
    └── NotesListScreen.swift
```

### Documentation Directory

```
Docs/
├── Test-01.md                # Storyboard UI/UX test
├── Test-02.md                # Swift language test
├── Test-03.md                # Architecture test
├── ...
├── Architecture.md           # Architecture decisions
├── APISpec.md                # API documentation
└── SetupGuide.md             # Local setup instructions
```

### .claude/ Directory

Claude Code configuration and context.

```
.claude/
├── Agents/                    # Expert agent definitions
│   ├── storyboard-expert.md
│   ├── swift-expert.md
│   ├── ios-architecture-expert.md
│   ├── uikit-expert.md
│   ├── swiftui-expert.md
│   ├── testing-expert.md
│   ├── networking-expert.md
│   ├── core-data-expert.md
│   ├── performance-expert.md
│   ├── security-expert.md
│   └── debugging-expert.md
├── Context/                   # Project context
│   ├── requirements.md
│   ├── architecture.md
│   ├── code-quality.md
│   ├── tdd-requirements.md
│   ├── branch-strategy.md
│   └── project-structure.md
└── Skills/                    # Custom skills (optional)
```

## Layer Responsibilities

### Domain Layer (Features/*/Domain/)
**Contents**: Pure business logic, no dependencies
- Entities: Business models
- Use Cases: Application business rules
- Repository Protocols: Data access contracts
- Domain Errors: Business-specific errors

**Rules**:
- ✅ Pure Swift (Foundation only)
- ✅ No UIKit, SwiftUI, Core Data, URLSession
- ✅ Defines protocols for boundaries
- ❌ Never imports presentation or data layers

### Data Layer (Features/*/Data/)
**Contents**: Data access implementations
- Repository Implementations: Implement domain protocols
- Data Sources: Remote (API) and Local (Core Data)
- DTOs: Network/database models
- Mappers: Convert DTOs to Domain entities

**Rules**:
- ✅ Implements domain protocols
- ✅ Can import Core Data, URLSession
- ✅ Maps between DTOs and Domain models
- ❌ Never imports presentation layer
- ❌ Never exposes DTOs to domain

### Presentation Layer (Features/*/Presentation/)
**Contents**: UI and user interaction
- ViewControllers/Views: UI components
- ViewModels: Presentation logic
- Coordinators: Navigation logic
- UI Models: View-specific models (if different from domain)

**Rules**:
- ✅ Uses domain use cases
- ✅ Can import UIKit, SwiftUI
- ✅ Transforms domain models to UI models
- ❌ Never accesses repositories directly
- ❌ Never contains business logic

## File Naming Conventions

### Domain Layer
```
User.swift                     # Entity
LoginUseCase.swift             # Use case (protocol)
DefaultLoginUseCase.swift      # Use case implementation
AuthRepository.swift           # Repository protocol
AuthError.swift                # Domain errors
```

### Data Layer
```
DefaultAuthRepository.swift    # Repository implementation
RemoteAuthDataSource.swift     # Remote data source
LocalAuthDataSource.swift      # Local data source
LoginRequestDTO.swift          # Data transfer object
UserMapper.swift               # DTO ↔ Domain mapper
```

### Presentation Layer
```
LoginViewController.swift      # View controller
LoginViewModel.swift           # View model
LoginCoordinator.swift         # Coordinator
UserUIModel.swift              # UI model
LoginView.swift                # SwiftUI view
```

### Tests
```
LoginUseCaseTests.swift        # Tests for LoginUseCase
DefaultAuthRepositoryTests.swift
LoginViewModelTests.swift
LoginUITests.swift
```

## Import Rules

### Allowed Imports Per Layer

#### Domain
```swift
import Foundation  // ✅ Basic types only
import Combine     // ✅ If using publishers
```

#### Data
```swift
import Foundation
import CoreData    // ✅ For local storage
```

#### Presentation
```swift
import Foundation
import UIKit       // ✅ For UIKit views
import SwiftUI     // ✅ For SwiftUI views
import Combine     // ✅ For reactive binding
```

### Forbidden Cross-Layer Imports

```swift
// ❌ Domain importing Data
import CoreData  // NO

// ❌ Domain importing Presentation
import UIKit     // NO

// ❌ Data importing Presentation
import UIKit     // NO
```

## Dependency Flow

```
┌─────────────────┐
│  Presentation   │ ─┐
│    (UI Layer)   │  │
└─────────────────┘  │
                     │ depends on
┌─────────────────┐  │
│     Domain      │ ◄┘
│  (Core Logic)   │
└─────────────────┘
         ▲
         │ implements
         │
┌─────────────────┐
│      Data       │
│ (Infrastructure)│
└─────────────────┘
```

All arrows point **inward** to Domain.

## Creating a New Feature

### 1. Domain First (TDD)
```
Features/MyFeature/Domain/
├── Entities/
│   └── MyEntity.swift
├── UseCases/
│   └── MyUseCase.swift
└── Repositories/
    └── MyRepository.swift (protocol)
```

### 2. Tests
```
ShellTests/Features/MyFeature/Domain/
├── MyEntityTests.swift
└── MyUseCaseTests.swift
```

### 3. Data Layer
```
Features/MyFeature/Data/
├── Repositories/
│   └── DefaultMyRepository.swift
└── DataSources/
    └── RemoteMyDataSource.swift
```

### 4. Tests
```
ShellTests/Features/MyFeature/Data/
└── DefaultMyRepositoryTests.swift
```

### 5. Presentation Layer
```
Features/MyFeature/Presentation/
├── MyViewController.swift
├── MyViewModel.swift
└── MyCoordinator.swift
```

### 6. Tests
```
ShellTests/Features/MyFeature/Presentation/
└── MyViewModelTests.swift
```

### 7. Wire in Composition Root
```swift
// App/CompositionRoot/AppDependencies.swift
lazy var myRepository: MyRepository = {
    DefaultMyRepository(/*...*/)
}()

lazy var myUseCase: MyUseCase = {
    DefaultMyUseCase(repository: myRepository)
}()
```

## File Size Guidelines

- **Maximum 500 lines** per file
- **Ideal 100-300 lines**
- If larger, extract:
  - Protocols to separate files
  - Extensions to separate files
  - Helper types to separate files

## Xcode Groups = File System Folders

**Always keep Xcode groups in sync with filesystem folders.**

- Xcode group "Features/Auth/Domain" = `Features/Auth/Domain/` folder
- Don't create flat structures in Xcode with nested folders in filesystem

## Summary

### Structure Principles
1. ✅ Feature-based organization (vertical slices)
2. ✅ Clean Architecture (Domain → Data ← UI)
3. ✅ Mirror test structure to app structure
4. ✅ Shared infrastructure in Shared/
5. ✅ Composition root wires everything

### Directory Rules
- ✅ Domain: Pure Swift, no dependencies
- ✅ Data: Implements domain protocols
- ✅ Presentation: Uses domain use cases
- ✅ No circular dependencies
- ✅ Dependency arrows point inward

### File Naming
- ✅ Clear, descriptive names
- ✅ Consistent suffixes (UseCase, Repository, ViewModel, etc.)
- ✅ Tests mirror production file names with "Tests" suffix

**This structure is mandatory. All features follow this pattern.**
