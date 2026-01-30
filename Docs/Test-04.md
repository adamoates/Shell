# Test 04: Navigation & Deep Linking

## Purpose

Build a **type-safe routing system** with deep link support that integrates with the Coordinator pattern.

## Goals

1. **Type-Safe Routes**: Enum-based routing with compile-time safety
2. **Deep Link Handling**: Universal links + custom URL schemes
3. **Auth Guards**: Protect routes based on session state
4. **Parameter Validation**: Type-safe route parameters
5. **Coordinator Integration**: Routes map to coordinator flows

## Why This Matters

### Traditional Approach (String-Based)
```swift
// ❌ Stringly-typed, error-prone
func navigate(to urlString: String) {
    if urlString == "/profile/123" {
        // Parse manually, hope it's valid
        showProfile(id: "123")
    }
}
```

### Type-Safe Approach
```swift
// ✅ Compile-time safety, explicit parameters
enum Route {
    case profile(userID: String)
    case settings(section: SettingsSection)
}

func navigate(to route: Route) {
    switch route {
    case .profile(let userID):
        showProfile(id: userID)
    case .settings(let section):
        showSettings(section: section)
    }
}
```

---

## Architecture

### Core/Navigation/ (Domain)
```
Core/Navigation/
├── Route.swift                  // Type-safe route enum
├── RouteParameters.swift        // Parameter validation
├── AuthGuard.swift              // Route access control
└── RouteResolver.swift          // URL → Route mapping
```

### Core/Contracts/Navigation/
```
Core/Contracts/Navigation/
├── Router.swift                 // Protocol for navigation
├── DeepLinkHandler.swift        // Protocol for deep links
└── RouteAccessControl.swift     // Protocol for auth checks
```

### Core/Infrastructure/Navigation/
```
Core/Infrastructure/Navigation/
├── UniversalLinkHandler.swift   // Universal links implementation
└── CustomURLSchemeHandler.swift // Custom URL scheme implementation
```

### App/Navigation/
```
App/Navigation/
├── AppRouter.swift              // Main router (coordinates with AppCoordinator)
└── RouteConfiguration.swift     // Define all app routes
```

---

## 1) Type-Safe Route System

### Route Definition
```swift
// Core/Navigation/Route.swift
enum Route: Equatable {
    // Auth flows
    case login
    case signup
    case forgotPassword

    // Authenticated flows
    case home
    case profile(userID: String)
    case settings(section: SettingsSection?)

    // Identity flow (demonstrates form engine)
    case identitySetup(step: IdentityStep?)

    // Error/fallback
    case notFound(path: String)
    case unauthorized(requestedRoute: Route)
}

enum SettingsSection: String, Codable {
    case account
    case privacy
    case notifications
    case about
}

enum IdentityStep: String, Codable {
    case screenName
    case birthday
    case avatar
    case review
}
```

### Route Parameters Protocol
```swift
// Core/Navigation/RouteParameters.swift
protocol RouteParameters {
    static func validate(_ params: [String: String]) -> Result<Self, RouteError>
}

enum RouteError: Error {
    case missingParameter(String)
    case invalidParameter(String, reason: String)
    case invalidURL
}

// Example: Profile route parameters
struct ProfileParameters: RouteParameters {
    let userID: String

    static func validate(_ params: [String: String]) -> Result<ProfileParameters, RouteError> {
        guard let userID = params["userID"], !userID.isEmpty else {
            return .failure(.missingParameter("userID"))
        }

        // Validate userID format (e.g., UUID)
        guard userID.count >= 3 else {
            return .failure(.invalidParameter("userID", reason: "Too short"))
        }

        return .success(ProfileParameters(userID: userID))
    }
}
```

---

## 2) Deep Link Handling

### URL → Route Mapping
```swift
// Core/Navigation/RouteResolver.swift
protocol RouteResolver {
    func resolve(url: URL) -> Route?
}

final class DefaultRouteResolver: RouteResolver {
    func resolve(url: URL) -> Route? {
        // Parse path components
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        guard let firstComponent = pathComponents.first else {
            return .home
        }

        switch firstComponent {
        case "login":
            return .login

        case "signup":
            return .signup

        case "profile":
            guard pathComponents.count > 1 else {
                return .notFound(path: url.path)
            }
            let userID = pathComponents[1]
            return .profile(userID: userID)

        case "settings":
            let section = pathComponents.count > 1
                ? SettingsSection(rawValue: pathComponents[1])
                : nil
            return .settings(section: section)

        case "identity":
            let step = pathComponents.count > 1
                ? IdentityStep(rawValue: pathComponents[1])
                : nil
            return .identitySetup(step: step)

        default:
            return .notFound(path: url.path)
        }
    }
}
```

### Deep Link Handler Protocol
```swift
// Core/Contracts/Navigation/DeepLinkHandler.swift
protocol DeepLinkHandler {
    func canHandle(url: URL) -> Bool
    func handle(url: URL) -> Bool
}

// Core/Infrastructure/Navigation/UniversalLinkHandler.swift
final class UniversalLinkHandler: DeepLinkHandler {
    private let routeResolver: RouteResolver
    private let router: Router

    init(routeResolver: RouteResolver, router: Router) {
        self.routeResolver = routeResolver
        self.router = router
    }

    func canHandle(url: URL) -> Bool {
        // Check if URL matches app's associated domain
        guard let host = url.host else { return false }
        return host == "shell.app" || host == "www.shell.app"
    }

    func handle(url: URL) -> Bool {
        guard canHandle(url) else { return false }

        guard let route = routeResolver.resolve(url: url) else {
            return false
        }

        router.navigate(to: route)
        return true
    }
}

// Core/Infrastructure/Navigation/CustomURLSchemeHandler.swift
final class CustomURLSchemeHandler: DeepLinkHandler {
    private let routeResolver: RouteResolver
    private let router: Router

    init(routeResolver: RouteResolver, router: Router) {
        self.routeResolver = routeResolver
        self.router = router
    }

    func canHandle(url: URL) -> Bool {
        // Check for custom scheme (shell://)
        return url.scheme == "shell"
    }

    func handle(url: URL) -> Bool {
        guard canHandle(url) else { return false }

        guard let route = routeResolver.resolve(url: url) else {
            return false
        }

        router.navigate(to: route)
        return true
    }
}
```

---

## 3) Auth Guards

### Route Access Control
```swift
// Core/Contracts/Navigation/RouteAccessControl.swift
protocol RouteAccessControl {
    func canAccess(route: Route) async -> AccessDecision
}

enum AccessDecision {
    case allowed
    case denied(reason: DenialReason)
}

enum DenialReason {
    case unauthenticated
    case locked
    case insufficientPermissions
    case requiresAdditionalInfo
}

// Core/Navigation/AuthGuard.swift
final class AuthGuard: RouteAccessControl {
    private let sessionRepository: SessionRepository

    init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }

    func canAccess(route: Route) async -> AccessDecision {
        // Define which routes require authentication
        guard route.requiresAuth else {
            return .allowed
        }

        // Check session
        guard let session = try? await sessionRepository.getCurrentSession(),
              session.isValid else {
            return .denied(reason: .unauthenticated)
        }

        // Check if account is locked
        // (In real app: check session.accountStatus)

        return .allowed
    }
}

extension Route {
    var requiresAuth: Bool {
        switch self {
        case .login, .signup, .forgotPassword:
            return false
        case .home, .profile, .settings, .identitySetup:
            return true
        case .notFound, .unauthorized:
            return false
        }
    }
}
```

---

## 4) Router Implementation

### Router Protocol
```swift
// Core/Contracts/Navigation/Router.swift
protocol Router: AnyObject {
    func navigate(to route: Route)
    func canNavigate(to route: Route) async -> Bool
}

// App/Navigation/AppRouter.swift
final class AppRouter: Router {
    private let coordinator: AppCoordinator
    private let accessControl: RouteAccessControl

    init(coordinator: AppCoordinator, accessControl: RouteAccessControl) {
        self.coordinator = coordinator
        self.accessControl = accessControl
    }

    func canNavigate(to route: Route) async -> Bool {
        let decision = await accessControl.canAccess(route: route)

        switch decision {
        case .allowed:
            return true
        case .denied:
            return false
        }
    }

    func navigate(to route: Route) {
        Task { @MainActor in
            // Check access
            let decision = await accessControl.canAccess(route: route)

            switch decision {
            case .allowed:
                routeToCoordinator(route)

            case .denied(let reason):
                handleDenial(route: route, reason: reason)
            }
        }
    }

    @MainActor
    private func routeToCoordinator(_ route: Route) {
        switch route {
        case .login:
            coordinator.showGuestFlow()

        case .signup:
            coordinator.showGuestFlow()

        case .home:
            coordinator.showAuthenticatedFlow()

        case .profile(let userID):
            // Future: coordinator.showProfile(userID: userID)
            print("Navigate to profile: \(userID)")

        case .settings(let section):
            // Future: coordinator.showSettings(section: section)
            print("Navigate to settings: \(section?.rawValue ?? "main")")

        case .identitySetup(let step):
            // Future: coordinator.showIdentitySetup(step: step)
            print("Navigate to identity setup: \(step?.rawValue ?? "start")")

        case .notFound(let path):
            print("Route not found: \(path)")

        case .unauthorized(let requestedRoute):
            print("Unauthorized access to: \(requestedRoute)")
        }
    }

    @MainActor
    private func handleDenial(route: Route, reason: DenialReason) {
        switch reason {
        case .unauthenticated:
            // Redirect to login, save intended destination
            navigate(to: .unauthorized(requestedRoute: route))
            navigate(to: .login)

        case .locked:
            coordinator.showLockedFlow()

        case .insufficientPermissions:
            // Show error
            print("Insufficient permissions for route: \(route)")

        case .requiresAdditionalInfo:
            // Redirect to identity setup
            navigate(to: .identitySetup(step: nil))
        }
    }
}
```

---

## 5) SceneDelegate Integration

```swift
// Shell/SceneDelegate.swift (updated)
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    // Create window
    let window = UIWindow(windowScene: windowScene)
    self.window = window

    // Create coordinator and bootstrapper
    let coordinator = dependencyContainer.makeAppCoordinator(window: window)
    let bootstrapper = dependencyContainer.makeAppBootstrapper(router: coordinator)

    appCoordinator = coordinator
    appBootstrapper = bootstrapper

    // Start boot sequence
    bootstrapper.start()

    // Handle deep links from initial launch
    if let urlContext = connectionOptions.urlContexts.first {
        handleDeepLink(urlContext.url)
    }
}

func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    // Handle deep links when app is already running
    guard let url = URLContexts.first?.url else { return }
    handleDeepLink(url)
}

private func handleDeepLink(_ url: URL) {
    let deepLinkHandlers = dependencyContainer.makeDeepLinkHandlers()

    for handler in deepLinkHandlers {
        if handler.handle(url: url) {
            return
        }
    }

    print("No handler could process URL: \(url)")
}
```

---

## 6) Testing Strategy

### Unit Tests: Route Resolver
```swift
func testRouteResolver_login_parsesCorrectly() {
    let resolver = DefaultRouteResolver()
    let url = URL(string: "https://shell.app/login")!

    let route = resolver.resolve(url: url)

    XCTAssertEqual(route, .login)
}

func testRouteResolver_profileWithID_parsesCorrectly() {
    let resolver = DefaultRouteResolver()
    let url = URL(string: "https://shell.app/profile/user123")!

    let route = resolver.resolve(url: url)

    XCTAssertEqual(route, .profile(userID: "user123"))
}

func testRouteResolver_settingsWithSection_parsesCorrectly() {
    let resolver = DefaultRouteResolver()
    let url = URL(string: "https://shell.app/settings/privacy")!

    let route = resolver.resolve(url: url)

    XCTAssertEqual(route, .settings(section: .privacy))
}
```

### Unit Tests: Auth Guard
```swift
func testAuthGuard_unauthenticatedRoute_allows() async {
    let mockRepo = SessionRepositoryFake()
    mockRepo.stubbedSession = nil

    let guard = AuthGuard(sessionRepository: mockRepo)
    let decision = await guard.canAccess(route: .login)

    XCTAssertEqual(decision, .allowed)
}

func testAuthGuard_authenticatedRouteWithValidSession_allows() async {
    let validSession = UserSession(
        userId: "user123",
        accessToken: "token",
        expiresAt: Date().addingTimeInterval(3600)
    )

    let mockRepo = SessionRepositoryFake()
    mockRepo.stubbedSession = validSession

    let guard = AuthGuard(sessionRepository: mockRepo)
    let decision = await guard.canAccess(route: .home)

    XCTAssertEqual(decision, .allowed)
}

func testAuthGuard_authenticatedRouteWithoutSession_denies() async {
    let mockRepo = SessionRepositoryFake()
    mockRepo.stubbedSession = nil

    let guard = AuthGuard(sessionRepository: mockRepo)
    let decision = await guard.canAccess(route: .home)

    if case .denied(let reason) = decision {
        XCTAssertEqual(reason, .unauthenticated)
    } else {
        XCTFail("Expected denied with unauthenticated reason")
    }
}
```

### Integration Tests: Deep Link Handler
```swift
func testUniversalLinkHandler_validURL_navigates() {
    let resolver = DefaultRouteResolver()
    let mockRouter = RouterSpy()
    let handler = UniversalLinkHandler(routeResolver: resolver, router: mockRouter)

    let url = URL(string: "https://shell.app/profile/user123")!
    let handled = handler.handle(url: url)

    XCTAssertTrue(handled)
    XCTAssertEqual(mockRouter.lastRoute, .profile(userID: "user123"))
}

func testCustomURLSchemeHandler_validScheme_navigates() {
    let resolver = DefaultRouteResolver()
    let mockRouter = RouterSpy()
    let handler = CustomURLSchemeHandler(routeResolver: resolver, router: mockRouter)

    let url = URL(string: "shell://settings/privacy")!
    let handled = handler.handle(url: url)

    XCTAssertTrue(handled)
    XCTAssertEqual(mockRouter.lastRoute, .settings(section: .privacy))
}
```

---

## Success Criteria

✅ Routes are type-safe (compile-time errors for invalid routes)
✅ Deep links map to routes correctly
✅ Auth guards protect routes based on session state
✅ Router integrates with AppCoordinator
✅ All navigation is testable with spies
✅ Universal links work (testable with URL stubs)
✅ Custom URL schemes work (shell://)

---

## Benefits

1. **Type Safety**: Impossible to navigate to invalid routes
2. **Testability**: All routing logic unit testable
3. **Clarity**: Route definitions document app navigation
4. **Deep Links**: First-class support for universal links
5. **Security**: Auth guards enforce access control
6. **Maintainability**: All routes defined in one place

This navigation layer is the **foundation** for all app flows and deep link handling.
