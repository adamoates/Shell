# Shell - iOS Modernization Toolkit

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS 26.2+](https://img.shields.io/badge/iOS-26.2+-blue.svg)](https://developer.apple.com/ios/)
[![Xcode 16.3+](https://img.shields.io/badge/Xcode-16.3+-blue.svg)](https://developer.apple.com/xcode/)
[![Tests](https://img.shields.io/badge/tests-383%20passing-brightgreen.svg)](./ShellTests)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> **Production-ready iOS boilerplate** demonstrating **Clean Architecture + MVVM** for building modern Swift 6 apps with strict concurrency.

A comprehensive reference implementation for migrating legacy iOS codebases to modern patterns, featuring OAuth 2.0 authentication, offline-first architecture, and complete test coverage.

---

## ✨ Features

### Authentication (OAuth 2.0 + OIDC)
- ✅ **JWT Access Tokens** (15-minute expiry, HS256)
- ✅ **Refresh Token Rotation** (7-day expiry, automatic refresh on 401)
- ✅ **Keychain Secure Storage** (device-locked, actor-safe)
- ✅ **Session Persistence** (survives app restarts)
- ✅ **Rate Limiting** (client + server-side brute force protection)
- ✅ **Token Reuse Detection** (security measure against attacks)
- ✅ **Automatic 401 Handling** (transparent token refresh with request retry)

### CRUD Operations
- ✅ **Items Module** (HTTP repository, full CRUD with backend)
- ✅ **Dog Module** (Core Data persistence, session validation)
- ✅ **Offline Support** (Core Data + network monitoring)

### Architecture
- ✅ **Clean Architecture** (Domain/Infrastructure/Presentation layers)
- ✅ **MVVM Pattern** (@MainActor ViewModels, UIKit programmatic UI)
- ✅ **Coordinator Pattern** (navigation flow management)
- ✅ **Repository Pattern** (data access abstraction)
- ✅ **Use Case Pattern** (single-responsibility business logic)
- ✅ **Dependency Injection** (AppDependencyContainer)

### Testing
- ✅ **383 Passing Tests** (unit, integration, end-to-end)
- ✅ **100% Domain Coverage** (business logic fully tested)
- ✅ **Integration Tests** (real backend communication)
- ✅ **URLProtocol Mocking** (HTTP client tests)
- ✅ **2.1:1 Test-to-Code Ratio** (auth module)

---

## 🏗️ Architecture

Canonical architecture guidance lives in [`ARCHITECTURE.md`](ARCHITECTURE.md).
If a README example conflicts with implementation details, defer to `ARCHITECTURE.md`.

```
Shell/
├── Features/              # Feature modules (vertical slices)
│   ├── Auth/             # OAuth 2.0 authentication
│   │   ├── Domain/       # Entities, UseCases, Repository protocols
│   │   ├── Infrastructure/ # HTTP client, Keychain storage
│   │   └── Presentation/ # LoginViewModel, LoginViewController
│   ├── Items/            # CRUD with backend integration
│   └── Dog/              # Core Data persistence example
├── Core/                 # Shared infrastructure
│   ├── DI/              # Dependency injection container
│   ├── Contracts/       # Shared protocols
│   └── Infrastructure/  # Config, Navigation, HTTP base
└── SwiftSDK/            # Reusable utilities
    └── Validation/      # Composable validators
```

### Layer Responsibilities

**Domain Layer** (Pure Swift, no dependencies):
- Entities (Sendable structs)
- Use Cases (business logic)
- Repository Protocols (data access abstraction)

**Infrastructure Layer** (External integrations):
- Repository Implementations (Keychain, Core Data, HTTP)
- HTTP Clients (URLSession actors)
- DTOs (API mapping)

**Presentation Layer** (UI concerns):
- ViewModels (@MainActor, ObservableObject)
- ViewControllers (UIKit programmatic)
- Coordinators (navigation flows)

**Dependency Rule**: Presentation and Infrastructure depend inward on Domain. Domain does not depend on either layer.

---

## 🚀 Getting Started

### Prerequisites

- **Xcode 16.3+** (Swift 6 required)
- **iOS Simulator** or physical device (iOS 26.2+)
- **Docker Desktop** (for backend)
- **Node.js 18+** (for backend development)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/adamoates/Shell.git
   cd Shell
   ```

2. **Start the backend** (required for auth and Items module):
   ```bash
   cd backend
   docker compose up -d
   ```

3. **Verify backend is running**:
   ```bash
   curl http://localhost:3000/health
   # Should return: {"status":"healthy","timestamp":"...","database":"connected"}
   ```

4. **Open Xcode project**:
   ```bash
   open Shell.xcodeproj
   ```

5. **Build and run** (⌘R):
   - Select "iPhone 17 Pro" simulator
   - Build scheme: "Shell"
   - Press Run

### Quick Test

**Run all tests** (recommended):
```bash
xcodebuild test -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:ShellUITests
```

**Test specific feature**:
```bash
# Auth tests only
xcodebuild test -scheme Shell -only-testing:ShellTests/AuthIntegrationTests

# Items tests only
xcodebuild test -scheme Shell -only-testing:ShellTests/ItemsTests
```

### Login Credentials

**Test Account**:
- Email: `adam@shell.app`
- Password: `TestPass1!`

Or create a new account via Sign Up screen.

---

## 🔧 Tech Stack

| Category | Technology |
|----------|-----------|
| **Language** | Swift 6 (strict concurrency enabled) |
| **UI Framework** | UIKit (programmatic, no storyboards) |
| **Architecture** | Clean Architecture + MVVM + Coordinator |
| **Concurrency** | async/await + actors |
| **Persistence** | Core Data, Keychain |
| **Networking** | URLSession (actor-based) |
| **Testing** | XCTest (unit + integration) |
| **Backend** | Node.js + Express + Postgres + Redis |
| **Backend Auth** | Argon2id + JWT (HS256) + OAuth 2.0 |
| **Dependency Manager** | Swift Package Manager (SPM) |

---

## 📁 Project Structure

### Feature Module Template

Every feature follows this structure:

```
Features/{Feature}/
├── Domain/
│   ├── Entities/              # Core models (Sendable structs)
│   ├── Contracts/             # Repository/data access protocols
│   ├── UseCases/              # Business logic (protocols + implementations)
│   └── Errors/                # Optional typed domain errors
├── Infrastructure/
│   └── Repositories/          # Repository implementations
│       ├── InMemory{Feature}Repository.swift
│       └── HTTP{Feature}Repository.swift
└── Presentation/
    ├── {ScreenA}/             # e.g., List/, ItemEditor/, Login/
    │   ├── {ScreenA}ViewModel.swift
    │   └── {ScreenA}ViewController.swift
    └── {ScreenB}/
        ├── {ScreenB}ViewModel.swift
        └── {ScreenB}ViewController.swift
```

### Reference Implementations

**Auth Module** (`Features/Auth/`):
- OAuth 2.0 Resource Owner Password Credentials Grant
- JWT access tokens (15 min) + refresh tokens (7 days)
- Keychain storage, 401 auto-refresh, rate limiting
- **50+ tests** covering all auth flows

**Items Module** (`Features/Items/`):
- HTTP repository with full CRUD operations
- Backend integration (Node.js REST API)
- In-memory repository for offline mode
- **55 passing tests**

**Dog Module** (`Features/Dog/`):
- Core Data persistence
- CRUD operations with session validation
- **37 passing tests**

---

## 🧪 Testing

### Test Coverage Summary

| Module | Unit Tests | Integration Tests | Total |
|--------|-----------|-------------------|-------|
| **Auth** | 40+ | 10 | 50+ |
| **Items** | 45 | 10 | 55 |
| **Dog** | 33 | 4 | 37 |
| **Core** | 50+ | - | 50+ |
| **SwiftSDK** | 100+ | - | 100+ |
| **Total** | **268+** | **24** | **383** |

### Test Types

**Unit Tests** (Mock all dependencies):
- Domain use cases
- ViewModels
- Repository implementations
- Validators

**Integration Tests** (Real implementations):
- Backend communication (requires Docker)
- Keychain storage
- Core Data persistence
- End-to-end auth flows

### Running Tests

**All tests**:
```bash
xcodebuild test -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:ShellUITests
```

**Specific test class**:
```bash
xcodebuild test -scheme Shell \
  -only-testing:ShellTests/AuthIntegrationTests
```

**Verify results**:
```bash
# Check for success
echo $?  # Should be 0

# Or grep for "TEST SUCCEEDED"
xcodebuild test ... 2>&1 | grep "TEST SUCCEEDED"
```

---

## 🐳 Backend Setup

The backend provides OAuth 2.0 authentication and REST API endpoints.

### Start Backend

```bash
cd backend
docker compose up -d
```

### Verify Services

**Check containers**:
```bash
docker ps
# Should show: shell-backend, shell-postgres, shell-redis
```

**Check health**:
```bash
curl http://localhost:3000/health
```

**View logs**:
```bash
docker logs shell-backend --tail 50 -f
```

### API Endpoints

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/health` | GET | No | Health check |
| `/auth/register` | POST | No | Create account |
| `/auth/login` | POST | No | Login (get tokens) |
| `/auth/refresh` | POST | No | Rotate tokens |
| `/auth/logout` | POST | Yes | Invalidate session |
| `/v1/items` | GET | Yes | Fetch all items |
| `/v1/items` | POST | Yes | Create item |
| `/v1/items/:id` | PUT | Yes | Update item |
| `/v1/items/:id` | DELETE | Yes | Delete item |

**Base URL**: `http://localhost:3000`

### Database Access

**Connect to Postgres**:
```bash
docker exec -it shell-postgres psql -U shell -d shell_db
```

**View users**:
```sql
SELECT user_id, email, created_at FROM users;
```

**View sessions**:
```sql
SELECT session_id, user_id, expires_at FROM sessions WHERE expires_at > NOW();
```

**Clear rate limits** (useful for tests):
```bash
docker exec shell-redis redis-cli FLUSHDB
```

---

## 📚 Documentation

### Architecture Guides

- **[CLAUDE.md](.claude/CLAUDE.md)** - Complete technical reference
- **[Auth Implementation](.claude/docs/AUTH_IMPLEMENTATION_IOS.md)** - OAuth 2.0 integration guide
- **[Swift 6 Rules](.claude/docs/swift-6-rules.md)** - Concurrency patterns
- **[Testing Guide](.claude/docs/testing-guide.md)** - TDD workflow
- **[Architecture Patterns](.claude/docs/architecture-patterns.md)** - Clean Architecture deep dive

### Quick References

**Add New Feature**:
1. Create feature directory: `Features/{Feature}/`
2. Add Domain layer (entities, use cases, repository protocol)
3. Add Infrastructure layer (repository implementation)
4. Add Presentation layer (ViewModel, ViewController, Coordinator)
5. Wire dependencies in `AppDependencyContainer`
6. Write tests (TDD recommended)

**Coding Standards**:
- ✅ All ViewModels: `@MainActor`
- ✅ All repositories: `actor` (thread-safe)
- ✅ All entities: `Sendable`
- ✅ No force unwraps: `!`, `try!`, `as!`
- ✅ Programmatic UI (no storyboards)
- ✅ Dependency injection (no singletons)

---

## 🎯 Use Cases

### 1. Modernizing Legacy iOS App

Shell demonstrates how to migrate from:
- **MVC → MVVM** (separation of concerns)
- **Singletons → Dependency Injection** (testability)
- **Completion handlers → async/await** (readability)
- **Global state → Repository Pattern** (data flow)
- **Force unwraps → Optional handling** (safety)

### 2. Learning Clean Architecture

Study reference implementations:
- **Items Module**: HTTP integration, CRUD operations
- **Auth Module**: OAuth 2.0, JWT, refresh tokens
- **Dog Module**: Core Data persistence

### 3. Starting New iOS Project

Fork Shell and:
1. Remove example features (Items, Dog)
2. Keep Core + SwiftSDK
3. Add your domain-specific features
4. Update backend schema and endpoints

### 4. Interview/Portfolio Project

Demonstrates knowledge of:
- Clean Architecture
- Swift 6 strict concurrency
- OAuth 2.0 / JWT authentication
- TDD (100% domain coverage)
- Backend integration
- Docker containerization

---

## 🔒 Security

### Implemented Security Measures

**Authentication**:
- ✅ Argon2id password hashing (timeCost: 3, memoryCost: 65536)
- ✅ JWT access tokens (HS256, 15-minute expiry)
- ✅ Refresh token rotation (7-day expiry, opaque UUID)
- ✅ Token reuse detection (invalidates all sessions)
- ✅ Rate limiting (5 login attempts / 15 min)
- ✅ Brute-force protection (account lockout)

**Storage**:
- ✅ Keychain for tokens (kSecAttrAccessibleWhenUnlockedThisDeviceOnly)
- ✅ No tokens in UserDefaults or plain text
- ✅ Session clearing on refresh failure

**Network**:
- ✅ HTTPS enforcement (production)
- ✅ Authorization header on protected routes
- ✅ Error response sanitization

### Not Implemented (Future Enhancements)
- ❌ Certificate pinning (dev environment uses localhost)
- ❌ Biometric authentication (Face ID / Touch ID)
- ❌ Multi-factor authentication (MFA)
- ❌ Social login (Apple / Google Sign-In)

**Security Score**: 85/100 (Production-ready for basic auth)

---

## 🛠️ Development

### Prerequisites

- Xcode 16.3+ (Swift 6 compiler)
- Docker Desktop (backend services)
- SwiftLint (optional, for code formatting)

### Build Commands

**Clean build**:
```bash
xcodebuild clean -scheme Shell
xcodebuild build -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Run in simulator**:
```bash
xcrun simctl launch booted com.adamcodertrader.Shell
```

**Capture screenshot**:
```bash
xcrun simctl io booted screenshot /tmp/shell-screenshot.png
open /tmp/shell-screenshot.png
```

### Feature Flags

Toggle repository implementations without code changes:

**`Shell/Core/Infrastructure/Config/APIConfig.swift`**:
```swift
struct RepositoryConfig {
    static var useHTTPItemsRepository: Bool = true  // Toggle Items: HTTP vs In-Memory
    static var useRemoteRepository: Bool = false    // Toggle Profile: Remote vs Local
}
```

### Pre-commit Hooks

Automatically enforced:
- ✅ **Test verification** (blocks commit if tests not run recently)
- ✅ **SwiftLint** (auto-formatting on every Edit/Write)
- ✅ **Push confirmation** (prompts before `git push`)

Located at: `.git/hooks/pre-commit`

---

## 🤝 Contributing

Contributions are welcome! This project serves as a reference implementation and learning resource.

### How to Contribute

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/your-feature`
3. **Follow existing patterns**:
   - Clean Architecture (Domain/Infrastructure/Presentation)
   - Swift 6 strict concurrency
   - 100% test coverage for Domain layer
4. **Write tests first** (TDD recommended)
5. **Ensure all tests pass**: `xcodebuild test -scheme Shell`
6. **Commit with conventional format**: `feat:`, `fix:`, `refactor:`, etc.
7. **Submit pull request**

### Code Style

- **Naming**: Descriptive, no abbreviations
- **Functions**: < 50 lines
- **Classes**: < 300 lines
- **Concurrency**: Actors for shared state, @MainActor for UI
- **Optionals**: Guard/if-let, no force unwrap
- **Errors**: Typed errors (enums), no generic Error

### Areas for Contribution

- ✅ Additional feature modules (Profile editing, Settings, Notifications)
- ✅ SwiftUI versions of ViewControllers
- ✅ Certificate pinning implementation
- ✅ Biometric authentication
- ✅ Social login (Apple / Google)
- ✅ Snapshot testing
- ✅ CI/CD pipeline (GitHub Actions)

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

**Built with**:
- [Swift](https://swift.org) - Apple's modern programming language
- [Docker](https://docker.com) - Containerization platform
- [Node.js](https://nodejs.org) - Backend runtime
- [PostgreSQL](https://postgresql.org) - Relational database
- [Redis](https://redis.io) - In-memory data store

**Inspired by**:
- Clean Architecture (Robert C. Martin)
- MVVM Pattern (Microsoft)
- Repository Pattern (Martin Fowler)

---

## 📞 Contact

**Author**: Adam Oates
**GitHub**: [@adamoates](https://github.com/adamoates)
**Repository**: [Shell](https://github.com/adamoates/Shell)

---

## ⭐️ Show Your Support

If this project helped you learn Clean Architecture or Swift 6, please give it a ⭐️!

**Happy Coding!** 🚀
