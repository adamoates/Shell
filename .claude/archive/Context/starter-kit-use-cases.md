# Shell Starter Kit - Use Cases

## Overview

The Shell iOS app is **not a Notes app**. It's an **ultimate starter kit** that demonstrates senior-level iOS architecture through platform infrastructure, not business logic.

**What this means**: Instead of implementing "CreateNote" or "FetchTasks", we implement "BootApp", "HandleDeepLink", "RefreshToken", "SecureStore" — the foundation code that EVERY iOS app needs.

## Philosophy

**The Shell IS the product.**

It's feature-agnostic infrastructure that proves:
- Clean Architecture boundaries
- TDD-first development
- Production-ready patterns
- Staff-level code quality

You can drop any product (Notes, Tasks, Shopping, etc.) into this foundation later.

## Use Case Catalog

### A) App Lifecycle & Boot

**CRITICAL DISTINCTION:**
- **Boot Orchestration** (App/Boot/): Thin, calls use cases, maps results, routes
- **Domain Use Cases** (Features/*/Domain/UseCases/): Real business logic

#### 1. AppBootstrapper (ORCHESTRATION, not a use case)
**Location**: `App/Boot/AppBootstrapper.swift`
**Purpose**: Thin orchestrator that wires boot sequence
**Responsibility**: Call use cases, map results to LaunchState, ask coordinator to route

**NOT responsible for**: Business logic, network calls, persistence

**Input**:
- RestoreSessionUseCase (injected)
- LaunchRouting (coordinator)

**Output**:
- Calls `router.route(to: LaunchState)`

**Flow**:
```swift
1. Call restoreSessionUseCase.execute()
2. Map SessionStatus → LaunchState (trivial mapping only!)
3. Ask router.route(to: launchState)
```

**Rule**: AppBootstrapper must be < 60 lines. If it grows, you're doing business logic → extract to use case.

**Tests** (with Fakes/Spies):
```swift
func testStart_whenSessionAuthenticated_routesToAuthenticated()
func testStart_whenSessionUnauthenticated_routesToUnauthenticated()
func testStart_invokesRestoreSessionExactlyOnce()
```

**Fake/Spy Example**:
```swift
final class RestoreSessionUseCaseFake: RestoreSessionUseCase {
    private let status: SessionStatus
    func execute() async -> SessionStatus { return status }
}

final class LaunchRouterSpy: LaunchRouting {
    private(set) var routedStates: [LaunchState] = []
    func route(to state: LaunchState) { routedStates.append(state) }
}
```

---

#### 2. RestoreSessionUseCase (REAL USE CASE)
**Location**: `Features/Auth/Domain/UseCases/RestoreSessionUseCase.swift`
**Purpose**: Restore user session state on app launch
**Responsibility**: Check for valid auth token, validate expiry, return SessionStatus

**Input**:
- SessionRepository (protocol from Core/Contracts/Security/)

**Output**:
- SessionStatus: `.authenticated`, `.unauthenticated`, or `.locked`

**Flow**:
```swift
1. Get current session from repository
2. If no session → return .unauthenticated
3. If session exists, validate expiry (business rule)
4. If expired → clear session, return .unauthenticated
5. If valid → return .authenticated
```

**Edge Cases**:
- ❌ Token expired → Clear session, return .unauthenticated
- ❌ Repository throws → Catch, return .unauthenticated (safe fallback)
- ❌ Session corrupt → Clear and start fresh

**Tests** (with Fakes):
```swift
func testExecute_whenNoSession_returnsUnauthenticated()
func testExecute_whenSessionValid_returnsAuthenticated()
func testExecute_whenSessionExpired_returnsUnauthenticatedAndClearsSession()
func testExecute_whenRepositoryThrows_returnsUnauthenticated()
```

**Fake Example**:
```swift
final class SessionRepositoryFake: SessionRepository {
    var stubbedSession: UserSession?
    func getCurrentSession() async throws -> UserSession? {
        return stubbedSession
    }
}
```

---

#### 3. HandleAppStateTransitions
**Purpose**: Manage foreground/background transitions
**Responsibility**: Cancel work, persist state, prepare for suspension

**Input**:
- App state notification (willEnterForeground, didEnterBackground)
- Active tasks

**Output**:
- Cancelled tasks (if appropriate)
- Persisted state

**Flow**:
```swift
1. On background:
   - Cancel non-critical network requests
   - Persist unsaved state
   - Schedule background tasks (if needed)
2. On foreground:
   - Refresh stale data
   - Resume cancelled tasks
   - Check for expired session
```

**Edge Cases**:
- ❌ Background while network request in-flight → Cancel or complete
- ❌ Return from background after token expired → Force re-auth
- ❌ Background task expiration mid-sync → Rollback partial changes
- ❌ Killed while in background → State restoration on next launch

**Tests**:
```swift
func testHandleBackground_cancelsNonCriticalRequests()
func testHandleBackground_persistsUnsavedState()
func testHandleForeground_refreshesStaleData()
func testHandleForeground_whenTokenExpired_forcesReauth()
```

---

### B) Navigation & Composition (Coordinator)

#### 4. RouteToInitialFlow
**Purpose**: Determine and start the initial app flow
**Responsibility**: Choose AuthCoordinator vs MainCoordinator based on session state

**Input**:
- AppState (authenticated, guest, locked)
- Deep link (if present)

**Output**:
- Started Coordinator

**Flow**:
```swift
1. Evaluate app state
2. If authenticated → MainCoordinator
3. If guest/unauthenticated → AuthCoordinator
4. If locked → BiometricUnlockCoordinator
5. If deep link present → Queue for after auth
```

**Edge Cases**:
- ❌ Deep link arrives before DI ready → Queue it
- ❌ Deep link requires auth → Route to auth, then deep link
- ❌ Rapid double-navigation triggers → Guard with flag
- ❌ Unknown route → Ignore, start default flow

**Tests**:
```swift
func testRouteToInitialFlow_whenAuthenticated_startsMainCoordinator()
func testRouteToInitialFlow_whenGuest_startsAuthCoordinator()
func testRouteToInitialFlow_withDeepLink_queuesForAuth()
func testRouteToInitialFlow_rapidCalls_onlyStartsOnce()
```

---

#### 5. HandleDeepLink
**Purpose**: Parse and route deep links/universal links
**Responsibility**: Convert URL to typed Route, send to Coordinator

**Input**:
- URL (deep link / universal link)
- Current app state

**Output**:
- Route (typed enum)
- Navigation action

**Flow**:
```swift
1. Parse URL into components
2. Match to Route enum cases
3. Validate parameters
4. Check if route requires authentication
5. Send route to appropriate Coordinator
```

**Edge Cases**:
- ❌ Unknown route → Show "not supported" or ignore
- ❌ Malformed parameters → Show error or default
- ❌ Requires feature flag disabled → Ignore gracefully
- ❌ Requires auth, user not authenticated → Auth first, then route
- ❌ URL while modal presented → Dismiss modal, then route

**Tests**:
```swift
func testHandleDeepLink_validURL_parsesToRoute()
func testHandleDeepLink_invalidURL_showsError()
func testHandleDeepLink_requiresAuth_queuesUntilAuthenticated()
func testHandleDeepLink_unknownRoute_ignored()
```

---

#### 6. PresentGlobalUI
**Purpose**: Show app-level UI (errors, loading, modals)
**Responsibility**: Coordinate-level UI that transcends individual screens

**Input**:
- Global event (error, loading start/stop, force update)

**Output**:
- Presented UI (banner, overlay, modal)

**Flow**:
```swift
1. Receive global UI event
2. Determine presentation style (banner, modal, overlay)
3. Present on top of current navigation stack
4. Handle dismissal or user action
```

**Edge Cases**:
- ❌ Multiple errors in quick succession → Dedupe/throttle
- ❌ Present while already presenting → Queue or replace
- ❌ UIKit safety: can't present while presenting → Wait
- ❌ Error during transition → Wait for transition to complete

**Tests**:
```swift
func testPresentGlobalUI_showsBanner()
func testPresentGlobalUI_multipleErrors_dedupes()
func testPresentGlobalUI_whilePresenting_queues()
```

---

### C) Application State (MVVM-Friendly)

#### 7. ObserveAppState
**Purpose**: Single source of truth for app-level state
**Responsibility**: Publish app state changes reactively

**State Properties**:
```swift
enum AppState {
    case booting
    case authenticated(User)
    case guest
    case locked
    case maintenance
}

struct AppEnvironment {
    let isNetworkReachable: Bool  // optional
    let featureFlagsReady: Bool
    let maintenanceMode: Bool
}
```

**Flow**:
```swift
1. Centralized state store (ObservableObject or Combine Subject)
2. Mutations only through explicit actions
3. Publish changes to observers
4. ViewModels subscribe and react
```

**Edge Cases**:
- ❌ State update from background thread → Assert/crash in debug
- ❌ Reentrancy: multiple updates in one run loop → Coalesce
- ❌ Observers updating state while observing → Detect cycles

**Tests**:
```swift
func testObserveAppState_publishes Changes()
func testObserveAppState_backgroundThreadUpdate_assertsInDebug()
func testObserveAppState_multipleObservers_allNotified()
```

---

#### 8. RenderStateDrivenUI
**Purpose**: UI reacts to state changes deterministically
**Responsibility**: ViewModels/Views observe state and render accordingly

**Flow**:
```swift
1. ViewModel subscribes to AppState
2. Map state to UI state
3. View observes ViewModel
4. Render based on state (loading/error/content/empty)
```

**Edge Cases**:
- ❌ SwiftUI state resets on navigation → Use proper state ownership
- ❌ UIKit VC lifecycle causing duplicate loads → Guard with flags
- ❌ State thrashing (rapid changes) → Debounce if needed

**Tests**:
```swift
func testRenderStateDrivenUI_whenStateChanges_viewUpdates()
func testRenderStateDrivenUI_rapidChanges_deduplicates()
```

---

### D) Networking Foundation (Client + Decorators)

#### 9. PerformRequest
**Purpose**: Generic HTTP request/response handling
**Responsibility**: Execute request, decode response, map errors

**Input**:
- HTTPRequest (URL, method, headers, body)
- Expected response type

**Output**:
- Decoded response or typed error

**Flow**:
```swift
1. Validate request
2. Execute via URLSession
3. Decode response (Codable)
4. Map HTTP errors to domain errors
5. Support cancellation
```

**Edge Cases**:
- ❌ 204 No Content → Return success with no body
- ❌ Decoding error → Typed DecodingError with context
- ❌ Timeout / DNS / offline → NetworkError cases
- ❌ TLS failure → SecurityError
- ❌ 429 Rate Limited → Respect Retry-After header
- ❌ Cancellation during request → Clean cancellation, no state corruption

**Tests**:
```swift
func testPerformRequest_success_decodesResponse()
func testPerformRequest_decodingError_throwsTypedError()
func testPerformRequest_timeout_throwsTimeoutError()
func testPerformRequest_cancelled_throwsCancellationError()
func testPerformRequest_204NoContent_succeeds()
```

---

#### 10. AttachAuthentication
**Purpose**: Add auth headers to requests (Decorator pattern)
**Responsibility**: Transparently inject auth token

**Input**:
- Base HTTPRequest
- Token provider

**Output**:
- Authenticated HTTPRequest

**Flow**:
```swift
1. Decorate base HTTPClient
2. On request, get current token
3. Add Authorization header
4. Pass to decorated client
```

**Edge Cases**:
- ❌ Token missing → Throw AuthenticationRequiredError
- ❌ Token expires mid-flight → 401 response triggers refresh
- ❌ Refresh in progress → Wait for refresh, retry with new token

**Tests**:
```swift
func testAttachAuthentication_addsAuthHeader()
func testAttachAuthentication_tokenMissing_throwsError()
func testAttachAuthentication_tokenExpiresDuring Request_refreshes()
```

---

#### 11. RefreshToken
**Purpose**: Refresh expired auth token
**Responsibility**: Single-flight refresh, queue waiting requests

**Flow**:
```swift
1. Detect 401 Unauthorized
2. Check if refresh already in progress (single-flight)
3. If yes, wait for existing refresh
4. If no, start new refresh
5. On refresh success: update token, retry waiting requests
6. On refresh failure: force logout, fail waiting requests
```

**Edge Cases**:
- ❌ Refresh fails → Force logout, clear session
- ❌ Refresh loop protection → Max 1 refresh per request
- ❌ Concurrent 401s racing → Single-flight ensures only one refresh
- ❌ Request cancelled while waiting for refresh → Don't retry

**Tests**:
```swift
func testRefreshToken_singleFlight_onlyOneRefreshRequest()
func testRefreshToken_success_retriesWaitingRequests()
func testRefreshToken_failure_forcesLogout()
func testRefreshToken_multipl 401s_deduplicatesRefresh()
```

---

### E) Persistence Foundation (Core Data + Key-Value)

#### 12. PersistAppCache
**Purpose**: Generic app-level caching API
**Responsibility**: Store/retrieve codable values with TTL expiration

**Input**:
- Key (String)
- Value (Codable)
- TTL (TimeInterval)

**Output**:
- Cached value or nil (if expired/missing)

**Flow**:
```swift
1. Store: serialize value, save with timestamp + TTL
2. Retrieve: check timestamp, return if fresh, nil if stale
3. Purge: remove expired entries
```

**Edge Cases**:
- ❌ Corrupted cached payload → Return nil, log error
- ❌ Schema change (decoding fails) → Return nil, clear entry
- ❌ Stale TTL entries → Purge on read or background task
- ❌ Disk full → Handle gracefully, clear old entries

**Tests**:
```swift
func testPersistAppCache_storesAndRetrieves()
func testPersistAppCache_expiredTTL_returnsNil()
func testPersistAppCache_corruptedData_returnsNil()
func testPersistAppCache_purgesExpiredEntries()
```

---

#### 13. CoreDataStackFacade
**Purpose**: Simplified Core Data interface
**Responsibility**: Background context saving, merge policies, migrations

**Components**:
- View context (main thread)
- Background context (for writes)
- Persistent container
- Model version manager

**Flow**:
```swift
1. Initialize persistent container
2. Configure contexts (merge policy, etc.)
3. Provide background context for writes
4. Handle context merging
5. Migration on model version change
```

**Edge Cases**:
- ❌ Migration required → Perform automatic or manual
- ❌ Save fails (disk full) → Rollback, throw error
- ❌ Merge conflicts → Use merge policy (prefer remote/local)
- ❌ Thread confinement violations → Must be impossible (proper context usage)

**Tests**:
```swift
func testCoreDataStack_savesAndFetches()
func testCoreDataStack_backgroundContext_mergestoMain()
func testCoreDataStack_saveFailure_rollsBack()
func testCoreDataStack_migration_succeeds()
```

---

### F) Security Foundation (Keychain + Biometrics)

#### 14. SecureStore
**Purpose**: Keychain adapter/facade for secrets
**Responsibility**: Store/retrieve sensitive data securely

**Operations**:
```swift
func save(key: String, value: String) throws
func retrieve(key: String) throws -> String?
func delete(key: String) throws
```

**Flow**:
```swift
1. Convert value to Data
2. Configure keychain query (access control, synchronization)
3. Execute keychain operation
4. Handle errors, map to domain errors
```

**Edge Cases**:
- ❌ Keychain locked / inaccessible → Throw KeychainUnavailableError
- ❌ Item not found → Return nil, not error
- ❌ Access control flags wrong → Throw ConfigurationError
- ❌ Synchronization conflict → Choose merge strategy

**Tests**:
```swift
func testSecureStore_savesAndRetrieves()
func testSecureStore_itemNotFound_returnsNil()
func testSecureStore_keychainLocked_throwsError()
func testSecureStore_delete_removesItem()
```

---

#### 15. BiometricGate
**Purpose**: Optional biometric app unlock
**Responsibility**: Gate app access with Face ID / Touch ID

**Flow**:
```swift
1. Check if biometrics available/enrolled
2. Present biometric prompt
3. Handle success/failure/cancel
4. On success: unlock app
5. On failure: show fallback (passcode) or force logout
```

**Edge Cases**:
- ❌ No biometrics enrolled → Skip gate or show passcode
- ❌ Lockout (too many failures) → Show passcode fallback
- ❌ User cancel → Remain locked or exit app
- ❌ System cancel (interruption) → Retry or fallback
- ❌ Biometrics disabled in Settings → Skip gracefully

**Tests**:
```swift
func testBiometricGate_success_unlocksApp()
func testBiometricGate_failure_showsFallback()
func testBiometricGate_cancel_remainsLocked()
func testBiometricGate_notEnrolled_skips()
```

---

### G) Observability, Diagnostics, and Debug Tooling

#### 16. LogEvents
**Purpose**: Structured logging without secrets
**Responsibility**: Log events at appropriate levels, redact sensitive data

**Log Levels**:
```swift
enum LogLevel {
    case verbose  // debug only
    case debug
    case info
    case warning
    case error
}
```

**Flow**:
```swift
1. Log event with level and context
2. Redact sensitive fields (tokens, passwords, emails)
3. Output to console (debug) or analytics (release)
4. Different levels per build configuration
```

**Edge Cases**:
- ❌ Redact sensitive fields → Use regex/allowlist
- ❌ Prevent spamming logs from retries → Throttle repeats
- ❌ Log from background thread → Safe (os_log is thread-safe)

**Tests**:
```swift
func testLogEvents_redactsSensitiveData()
func testLogEvents_differentLevelsByBuild()
func testLogEvents_throttlesRepeats()
```

---

#### 17. CaptureDiagnosticsSnapshot (Debug-only UI)
**Purpose**: Debug screen showing app internal state
**Responsibility**: Display state, cache, network, feature flags

**Displays**:
- Current route
- App state (authenticated/guest/locked)
- Cache size and entries
- Last network request status (sanitized)
- Feature flags state
- Keychain item count (not contents)

**Edge Cases**:
- ❌ Must never expose secrets (tokens, passwords)
- ❌ Only available in debug builds
- ❌ Accessible via shake gesture or debug menu

**Tests**:
```swift
func testCaptureDiagnostics_showsAppState()
func testCaptureDiagnostics_sanitizesSecrets()
func testCaptureDiagnostics_onlyAvailableInDebug()
```

---

#### 18. ReproduceBugTools (Debug-only)
**Purpose**: Controlled bug reproduction for testing
**Responsibility**: Trigger known issues for verification

**Tools**:
```swift
- "Trigger constraint warning" → Create ambiguous layout
- "Trigger controlled crash" → Throw fatal error
- "Simulate offline" → Block network requests
- "Simulate token expiry" → Force 401 response
- "Simulate slow network" → Add latency
- "Clear all caches" → Wipe cache and restart
```

**Edge Cases**:
- ❌ Only available in debug builds
- ❌ Confirm before destructive actions
- ❌ Log all reproductions for tracking

**Tests**:
```swift
func testReproduceTools_simulateOffline_blocksRequests()
func testReproduceTools_onlyAvailableInDebug()
```

---

### H) Performance Hooks

#### 19. MeasureCriticalPaths
**Purpose**: Measure performance of critical operations
**Responsibility**: Track app launch, screen render, API response times

**Metrics**:
- App launch time (cold/warm)
- Time to interactive
- Screen render time
- API request duration

**Flow**:
```swift
1. Start timer at operation start
2. End timer at operation complete
3. Log/report metric
4. In debug: assert against thresholds
```

**Edge Cases**:
- ❌ Measurement overhead minimal in release → Conditional compilation
- ❌ No main-thread JSON decode in hot paths → Assert
- ❌ Track 95th percentile, not just average

**Tests**:
```swift
func testMeasureCriticalPaths_tracksLaunchTime()
func testMeasureCriticalPaths_detectsSlowOperations()
```

---

#### 20. PreventLeaks
**Purpose**: Ensure coordinators/ViewModels deallocate
**Responsibility**: Test lifecycle, detect retain cycles

**Strategy**:
```swift
1. Weak reference to object
2. Trigger deinit condition
3. Assert object deallocated
4. Use Instruments Leaks in CI
```

**Edge Cases**:
- ❌ Retain cycles in closures → Use [weak self]
- ❌ Long-lived tasks holding references → Cancel on deinit
- ❌ Coordinator not released → Check child coordinators

**Tests**:
```swift
func testPreventLeaks_viewModelDeallocates()
func testPreventLeaks_coordinatorDeallocates()
func testPreventLeaks_noRetainCyclesInClosures()
```

---

### I) Schema-Driven Forms (Killer Feature)

#### 21. RenderFormFromSchema
**Purpose**: Generate UI from form schema
**Responsibility**: Dynamic form rendering without hardcoded screens

**Input**:
- FormSchema (sections, fields, validation rules)
- FieldMapping (UI → Domain)

**Output**:
- Rendered form UI (UIKit or SwiftUI)
- Editable field states

**Flow**:
```swift
1. Parse FormSchema
2. Generate UI fields dynamically
3. Apply visibility rules (progressive disclosure)
4. Configure validation strategies
5. Set up field-to-field behavior
6. Render accessible, keyboard-friendly UI
```

**Edge Cases**:
- ❌ Complex visibility rules → Evaluate dependencies correctly
- ❌ Circular field dependencies → Detect and prevent
- ❌ Dynamic schema updates → Re-render affected fields only
- ❌ Accessibility with dynamic fields → Maintain VoiceOver order

**Tests**:
```swift
func testRenderFormFromSchema_generatesCorrectFieldCount()
func testRenderFormFromSchema_appliesVisibilityRules()
func testRenderFormFromSchema_configuresAccessibility()
func testRenderFormFromSchema_handlesInvalidSchema()
```

---

#### 22. ValidateFormFields
**Purpose**: Validate form fields using strategy pattern
**Responsibility**: Execute validation rules, provide user-friendly errors

**Input**:
- FieldID and value
- ValidationRules (required, email, minLength, etc.)
- ValidationMode (live, onBlur, onSubmit)

**Output**:
- ValidationResult (valid/invalid with error message)
- Field error state

**Flow**:
```swift
1. Determine when to validate (mode)
2. Apply validation rules to field value
3. Execute cross-field validation if needed
4. Map errors to user-friendly messages
5. Update field error state
6. Emit validation events
```

**Edge Cases**:
- ❌ Cross-field validation (password match) → Access other fields
- ❌ Async validation (username availability) → Handle loading state
- ❌ Validation during typing → Debounce to avoid noise
- ❌ Multiple validation errors → Show priority error first

**Tests**:
```swift
func testValidateFormFields_emailRule_rejectsInvalid()
func testValidateFormFields_passwordMatch_detectsMismatch()
func testValidateFormFields_required_rejectsEmpty()
func testValidateFormFields_asyncValidation_handlesLoading()
```

---

#### 23. MapFieldsToDomain
**Purpose**: Transform raw UI values to domain models
**Responsibility**: Apply transformations, normalize input, parse types

**Input**:
- Raw field values ([FieldID: String])
- FieldMapping definition

**Output**:
- Domain model or DTO
- MappingError if transformation fails

**Flow**:
```swift
1. Extract raw values from UI
2. Apply transformations (trim, lowercase, strip formatting)
3. Parse types (String → Date, String → Decimal)
4. Construct domain model
5. Validate domain constraints
6. Return typed model or throw error
```

**Edge Cases**:
- ❌ Missing required fields → Throw MappingError.missingField
- ❌ Parsing failures (invalid date) → Throw MappingError.invalidFormat
- ❌ Multiple transformations → Apply in correct order
- ❌ Sensitive field logging → Redact in error messages

**Tests**:
```swift
func testMapFieldsToDomain_normalizesEmail()
func testMapFieldsToDomain_stripsPhoneFormatting()
func testMapFieldsToDomain_parsesDateCorrectly()
func testMapFieldsToDomain_missingField_throwsError()
func testMapFieldsToDomain_redactsSensitiveData()
```

---

#### 24. SubmitFormData
**Purpose**: Submit validated and mapped form data
**Responsibility**: Execute submission use case, handle responses

**Input**:
- Mapped domain model
- Submission endpoint
- Auth context

**Output**:
- FormResponse (success, MFA required, additional info needed)
- Error if submission fails

**Flow**:
```swift
1. Validate all fields
2. Map to domain model
3. Execute SubmitFormUseCase
4. Handle response variants:
   - Success → Navigate to next screen
   - MFA Required → Show MFA screen
   - Additional Info → Show additional form
   - Error → Display error
```

**Edge Cases**:
- ❌ Network error during submission → Allow retry
- ❌ Submission in progress → Disable submit button
- ❌ Concurrent submissions → Single-flight pattern
- ❌ Response requires different flow → Route via Coordinator

**Tests**:
```swift
func testSubmitFormData_success_navigatesToNextScreen()
func testSubmitFormData_mfaRequired_showsMFAScreen()
func testSubmitFormData_networkError_allowsRetry()
func testSubmitFormData_concurrentSubmits_onlyOneInFlight()
```

---

#### 25. ApplyProgressiveDisclosure
**Purpose**: Show/hide fields based on user input
**Responsibility**: Evaluate visibility rules, update UI dynamically

**Input**:
- Visibility rules per field
- Current field values

**Output**:
- Updated set of visible fields
- Re-rendered UI

**Flow**:
```swift
1. User updates field (e.g., accountType = "Business")
2. Evaluate visibility rules for all fields
3. Determine which fields should be visible
4. Animate field appearance/disappearance
5. Update form state
6. Maintain accessibility focus order
```

**Edge Cases**:
- ❌ Dependent field has value when hidden → Clear value
- ❌ Multiple dependencies → Evaluate all rules
- ❌ Circular dependencies → Detect and prevent
- ❌ Accessibility focus when field disappears → Move to next visible

**Tests**:
```swift
func testProgressiveDisclosure_showsFieldWhenRuleMet()
func testProgressiveDisclosure_hidesFieldWhenRuleNotMet()
func testProgressiveDisclosure_clearsHiddenFieldValue()
func testProgressiveDisclosure_detectsCircularDependencies()
```

---

## Design Pattern Coverage

The Shell starter kit demonstrates ALL key patterns:

### Architectural
- ✅ **Coordinator**: AppCoordinator, AuthCoordinator, MainCoordinator
- ✅ **MVVM**: ViewModels for all screens, reactive data flow
- ✅ **Factory**: Screen/module builders (ViewControllerFactory)

### Domain Boundaries
- ✅ **Repository**: SessionRepository, ConfigRepository (not NotesRepository!)
- ✅ **Use Case**: BootApp, RestoreSession, HandleDeepLink, etc.

### Structural
- ✅ **Facade**: APIClient, CoreDataStack, SecureStore
- ✅ **Adapter**: KeychainAdapter, URLSessionAdapter, DTO mapping
- ✅ **Decorator**: AuthenticatedHTTPClient, RetryHTTPClient, LoggingHTTPClient

### Behavioral
- ✅ **Strategy**: RetryStrategy, CacheExpirationStrategy, BiometricPolicy
- ✅ **Observer**: Combine publishers for reactive state

### Creational
- ✅ **Dependency Injection**: Constructor injection throughout, composition root

---

## Ultimate Starter Kit Edge Cases

These separate "toy skeleton" from "real starter kit":

### Concurrency ✅
- Cancellation propagates: UI → VM → UseCase → Client
- Single-flight refresh token
- Logout cancels all in-flight work
- No state updates after logout

### UI State Correctness ✅
- Loading/error/empty states consistent and reusable
- Rapid taps / double navigations guarded
- Dynamic Type + rotation + accessibility baked in

### Reliability ✅
- Typed errors with user-presentable mapping
- Offline behavior produces stable UI states
- Graceful degradation when services unavailable

### Testability ✅
- Every boundary is protocol-driven
- Composition root is only place with concretes
- Integration tests don't hit network
- Test doubles provided for all protocols

---

## Minimal "Ultimate Starter Kit" Scope

The tightest scope that still screams "senior":

1. ✅ **Composition root + DI + factories**
   - AppDependencies
   - Factory protocols
   - Coordinator factories

2. ✅ **Coordinator routing (including deep link)**
   - AppCoordinator
   - Route enum
   - Deep link parser

3. ✅ **Generic APIClient + auth/retry decorators**
   - HTTPClient protocol
   - URLSessionAdapter
   - AuthenticatedHTTPClient
   - RetryHTTPClient
   - LoggingHTTPClient

4. ✅ **SecureStore + optional BiometricGate**
   - KeychainWrapper
   - SecureStorage facade
   - BiometricAuthentication

5. ✅ **Cache with TTL + CoreDataStack facade**
   - AppCache with expiration
   - CoreDataStack with in-memory tests
   - Background context handling

6. ✅ **Debug Diagnostics screen + repro tools**
   - DiagnosticsViewController
   - Reproduce bug tools
   - Debug-only features

7. ✅ **Real test harness**
   - Unit tests (use cases, strategies)
   - Integration tests (networking, persistence)
   - UI test (launch → initial route)

8. ✅ **Schema-Driven Form Engine** (Killer Feature)
   - FormSchema definitions
   - Dynamic field rendering (UIKit + SwiftUI)
   - FieldMapping (UI → Domain with transformations)
   - Validation strategies
   - Progressive disclosure (conditional fields)
   - Flow routing based on responses

---

## Implementation Order

### Phase 1: Foundation (test/03-architecture-foundation)
- Composition root
- DI container
- Coordinator protocols
- App state management

### Phase 2: Networking (test/08-networking)
- HTTPClient protocol
- URLSessionAdapter
- Decorators (Auth, Retry, Logging)
- RefreshToken single-flight

### Phase 3: Security (test/11-security)
- SecureStore / Keychain
- BiometricGate
- Token management

### Phase 4: Persistence (test/09-coredata)
- Core Data stack
- Cache with TTL
- Background contexts

### Phase 5: Observability (test/12-debugging)
- Structured logging
- Diagnostics screen
- Repro tools

### Phase 6: Performance (test/10-performance)
- Measure critical paths
- Leak detection
- Performance tests

### Phase 7: Schema-Driven Forms (test/13-form-engine)
- FormSchema data structures
- FormViewModel (MVVM)
- FormRenderer (UIKit + SwiftUI)
- Validation strategies
- FieldMapping implementations
- Progressive disclosure
- Form Sandbox UI

---

## Success Criteria

The Shell starter kit succeeds when:

1. ✅ Any iOS engineer can understand it in 30 minutes
2. ✅ Dropping in a new feature (Notes, Tasks, etc.) is trivial
3. ✅ All platform concerns are solved once
4. ✅ Every boundary is testable
5. ✅ Zero technical debt
6. ✅ Production-ready patterns throughout
7. ✅ Passes staff-level code review

**This is the foundation. Any product can build on it.**
