# Navigation System

## Overview

Type-safe navigation system with deep link support, auth guards, and coordinator integration.

## Architecture

### Core/Navigation/ (Domain Layer)

Type-safe routing abstractions:

```swift
// Route.swift - Type-safe route enum
indirect enum Route: Equatable {
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

    var requiresAuth: Bool { /* ... */ }
    var description: String { /* ... */ }
}

// RouteParameters.swift - Parameter validation
protocol RouteParameters {
    static func validate(_ params: [String: String]) -> Result<Self, RouteError>
}

struct ProfileParameters: RouteParameters {
    let userID: String
    // Validates: minimum length, alphanumeric only
}

// DefaultRouteResolver.swift - URL → Route mapping
final class DefaultRouteResolver: RouteResolver {
    func resolve(url: URL) -> Route? {
        // Handles both HTTPS and custom schemes
        // https://shell.app/profile/user123 → .profile(userID: "user123")
        // shell://profile/user123 → .profile(userID: "user123")
    }
}

// AuthGuard.swift - Access control
final class AuthGuard: RouteAccessControl {
    func canAccess(route: Route) async -> AccessDecision {
        // Checks session validity
        // Returns .allowed or .denied(reason: .unauthenticated)
    }
}
```

### Core/Contracts/Navigation/ (Protocol Boundaries)

```swift
// Router.swift
protocol Router: AnyObject {
    func navigate(to route: Route)
    func canNavigate(to route: Route) async -> Bool
}

// RouteResolver.swift
protocol RouteResolver {
    func resolve(url: URL) -> Route?
}

// RouteAccessControl.swift
protocol RouteAccessControl {
    func canAccess(route: Route) async -> AccessDecision
}

enum AccessDecision: Equatable {
    case allowed
    case denied(reason: DenialReason)
}

enum DenialReason: Equatable {
    case unauthenticated
    case locked
    case insufficientPermissions
    case requiresAdditionalInfo
}

// DeepLinkHandler.swift
protocol DeepLinkHandler {
    func canHandle(url: URL) -> Bool
    func handle(url: URL) -> Bool
}
```

### Core/Infrastructure/Navigation/ (Platform Implementations)

```swift
// UniversalLinkHandler.swift
final class UniversalLinkHandler: DeepLinkHandler {
    // Handles: https://shell.app/... links
    // Checks host matches shell.app or www.shell.app
    // Routes via RouteResolver → Router
}

// CustomURLSchemeHandler.swift
final class CustomURLSchemeHandler: DeepLinkHandler {
    // Handles: shell://... links
    // Checks scheme == "shell"
    // Routes via RouteResolver → Router
}
```

### App/Navigation/ (Application Layer)

```swift
// AppRouter.swift
final class AppRouter: Router {
    private let coordinator: AppCoordinator
    private let accessControl: RouteAccessControl

    func navigate(to route: Route) {
        // 1. Check access control (AuthGuard)
        // 2. If allowed: route to coordinator
        // 3. If denied: handle based on denial reason
    }

    @MainActor
    private func routeToCoordinator(_ route: Route) {
        switch route {
        case .login, .signup: coordinator.route(to: .unauthenticated)
        case .home: coordinator.route(to: .authenticated)
        case .profile(let userID): /* Future: show profile */
        // ...
        }
    }

    @MainActor
    private func handleDenial(route: Route, reason: DenialReason) {
        switch reason {
        case .unauthenticated: coordinator.route(to: .unauthenticated)
        case .locked: coordinator.route(to: .locked)
        // ...
        }
    }
}
```

## Data Flow

### Deep Link → Route → Coordinator

```
1. User taps link: https://shell.app/profile/user123
   ↓
2. SceneDelegate receives URL
   ↓
3. Deep link handlers process URL
   UniversalLinkHandler.canHandle(url) → true
   ↓
4. Route resolution
   DefaultRouteResolver.resolve(url) → .profile(userID: "user123")
   ↓
5. Access control
   AuthGuard.canAccess(.profile(userID: "user123")) → .allowed
   ↓
6. Router navigates
   AppRouter.navigate(to: .profile(userID: "user123"))
   ↓
7. Coordinator shows screen
   AppCoordinator.showProfile(userID: "user123")
```

### Auth Guard Flow

```
Route requires auth?
  ↓ YES
Has valid session?
  ↓ YES
AccessDecision.allowed
  ↓
Navigate to route

Route requires auth?
  ↓ YES
Has valid session?
  ↓ NO
AccessDecision.denied(reason: .unauthenticated)
  ↓
Redirect to login
Save intended destination (future)
```

## Integration Points

### SceneDelegate

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    // Create coordinator, router, bootstrapper
    let coordinator = dependencyContainer.makeAppCoordinator(window: window)
    let router = dependencyContainer.makeAppRouter(coordinator: coordinator)
    let bootstrapper = dependencyContainer.makeAppBootstrapper(router: coordinator)

    // Create deep link handlers
    deepLinkHandlers = dependencyContainer.makeDeepLinkHandlers(router: router)

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
    for handler in deepLinkHandlers {
        if handler.handle(url: url) {
            return
        }
    }
}
```

### AppDependencyContainer

```swift
// Navigation factories
func makeAppRouter(coordinator: AppCoordinator) -> Router {
    AppRouter(coordinator: coordinator, accessControl: makeAuthGuard())
}

func makeAuthGuard() -> RouteAccessControl {
    AuthGuard(sessionRepository: makeSessionRepository())
}

func makeRouteResolver() -> RouteResolver {
    DefaultRouteResolver()
}

func makeDeepLinkHandlers(router: Router) -> [DeepLinkHandler] {
    let resolver = makeRouteResolver()
    return [
        UniversalLinkHandler(routeResolver: resolver, router: router),
        CustomURLSchemeHandler(routeResolver: resolver, router: router)
    ]
}
```

## URL Schemes

### Universal Links (HTTPS)

**Format**: `https://shell.app/{route}/{params}`

**Examples**:
- `https://shell.app/login` → Route.login
- `https://shell.app/profile/user123` → Route.profile(userID: "user123")
- `https://shell.app/settings/privacy` → Route.settings(section: .privacy)
- `https://www.shell.app/home` → Route.home (www subdomain supported)

**Setup** (future):
1. Add associated domains in entitlements
2. Configure apple-app-site-association file on server
3. Enable Associated Domains capability in Xcode

### Custom URL Schemes

**Format**: `shell://{route}/{params}`

**Examples**:
- `shell://login` → Route.login
- `shell://profile/user123` → Route.profile(userID: "user123")
- `shell://settings/notifications` → Route.settings(section: .notifications)

**Setup**:
- Already configured in Info.plist (CFBundleURLSchemes)

## Adding New Routes

### 1. Define Route Case

```swift
// Core/Navigation/Route.swift
enum Route: Equatable {
    // ...existing cases...

    // New route
    case productDetail(productID: String, variant: String?)

    var requiresAuth: Bool {
        switch self {
        // ...
        case .productDetail: return true  // Requires auth
        }
    }
}
```

### 2. Add Parameter Validation (if needed)

```swift
// Core/Navigation/RouteParameters.swift
struct ProductDetailParameters: RouteParameters {
    let productID: String
    let variant: String?

    static func validate(_ params: [String: String]) -> Result<Self, RouteError> {
        guard let productID = params["productID"], !productID.isEmpty else {
            return .failure(.missingParameter("productID"))
        }

        // Validate productID format (e.g., UUID, alphanumeric)
        guard productID.count >= 3 else {
            return .failure(.invalidParameter("productID", reason: "Too short"))
        }

        let variant = params["variant"]  // Optional

        return .success(ProductDetailParameters(productID: productID, variant: variant))
    }
}
```

### 3. Update Route Resolver

```swift
// Core/Navigation/DefaultRouteResolver.swift
func resolve(url: URL) -> Route? {
    // ...
    switch firstComponent {
    // ...existing cases...

    case "product":
        guard pathComponents.count > 1 else {
            return .notFound(path: url.path)
        }

        let productID = pathComponents[1]
        let variant = pathComponents.count > 2 ? pathComponents[2] : nil
        let params = [
            "productID": productID,
            "variant": variant
        ].compactMapValues { $0 }

        switch ProductDetailParameters.validate(params) {
        case .success(let validated):
            return .productDetail(productID: validated.productID, variant: validated.variant)
        case .failure:
            return .notFound(path: url.path)
        }
    }
}
```

### 4. Update AppRouter

```swift
// App/Navigation/AppRouter.swift
@MainActor
private func routeToCoordinator(_ route: Route) {
    switch route {
    // ...existing cases...

    case .productDetail(let productID, let variant):
        // Future: coordinator.showProductDetail(productID: productID, variant: variant)
        print("Navigate to product: \(productID), variant: \(variant ?? "none")")
        coordinator.route(to: .authenticated)
    }
}
```

### 5. Write Tests

```swift
// ShellTests/Core/Navigation/RouteResolverTests.swift
func testResolve_productDetail_parsesCorrectly() {
    let url = URL(string: "https://shell.app/product/abc123/red")!

    let route = sut.resolve(url: url)

    XCTAssertEqual(route, .productDetail(productID: "abc123", variant: "red"))
}

func testResolve_productDetailWithoutVariant_parsesCorrectly() {
    let url = URL(string: "https://shell.app/product/abc123")!

    let route = sut.resolve(url: url)

    XCTAssertEqual(route, .productDetail(productID: "abc123", variant: nil))
}
```

## Testing Strategy

### Unit Tests

**RouteResolverTests** - URL → Route mapping
- Test valid URLs resolve to correct routes
- Test invalid URLs resolve to .notFound
- Test parameter validation
- Test both HTTPS and custom schemes

**AuthGuardTests** - Access control
- Test unauthenticated routes always allow
- Test authenticated routes check session
- Test expired sessions deny access
- Test repository errors deny access

**RouteParametersTests** - Parameter validation
- Test valid parameters succeed
- Test missing required parameters fail
- Test invalid parameter formats fail
- Test edge cases (length, characters, etc.)

**DeepLinkHandlerTests** - Deep link handling
- Test UniversalLinkHandler recognizes correct domains
- Test CustomURLSchemeHandler recognizes correct schemes
- Test handlers delegate to router
- Test handler priority (universal links before custom schemes)

### Integration Tests

**End-to-end deep linking**:
1. Construct URL
2. Pass through handler → resolver → router
3. Verify correct coordinator method called

## Common Patterns

### Post-Login Redirect

```swift
// Save intended destination when auth required
case .denied(.unauthenticated):
    saveIntendedDestination(route)
    coordinator.route(to: .unauthenticated)

// After login, restore destination
func loginDidComplete() {
    if let intended = retrieveIntendedDestination() {
        router.navigate(to: intended)
    } else {
        router.navigate(to: .home)
    }
}
```

### Query Parameters

```swift
// Parse query parameters from URL
let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
let params = queryItems?.reduce(into: [:]) { $0[$1.name] = $1.value }

// Example: https://shell.app/profile/user123?tab=posts
// → .profile(userID: "user123", tab: "posts")
```

### Conditional Routing

```swift
// Route based on feature flags, A/B tests, etc.
case .someFeature:
    if featureFlags.isEnabled(.newUI) {
        coordinator.showNewUI()
    } else {
        coordinator.showOldUI()
    }
```

## Benefits

✅ **Type Safety** - Impossible to navigate to invalid routes (compile-time errors)
✅ **Testability** - All routing logic unit testable with spies/fakes
✅ **Deep Links** - First-class universal link + custom scheme support
✅ **Security** - Auth guards enforce access control before navigation
✅ **Clarity** - Route definitions document entire app navigation
✅ **Maintainability** - All routes defined in one place
✅ **Flexibility** - Easy to add new routes, parameters, or guards

## Documentation

See `Docs/Test-04.md` for complete navigation system documentation including:
- Detailed architecture explanation
- Code examples for all components
- Testing strategy with example tests
- Success criteria
