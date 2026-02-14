# Navigation & Auth Refactor Spec

## Purpose
This spec captures the current navigation/auth state, confirmed implementation gaps, and the highest-value refactor targets.
Use this as the source of truth for phased execution and code review.

## Current Navigation State

- Navigation is coordinator-driven with a typed route layer:
  - `Shell/Core/Navigation/Route.swift`
  - `Shell/Core/Navigation/DefaultRouteResolver.swift`
  - `Shell/Core/Navigation/AuthGuard.swift`
  - `Shell/App/Navigation/AppRouter.swift`
- App startup is separated cleanly:
  - Boot decides launch state via `AppBootstrapper`
  - Coordinator decides UI flow via `LaunchRouting`
  - Files:
    - `Shell/App/Boot/AppBootstrapper.swift`
    - `Shell/Core/Coordinator/AppCoordinator.swift`
- Deep links are handled for both universal links and custom URL schemes:
  - `https://shell.app/...`
  - `shell://...`
  - Files:
    - `Shell/Core/Infrastructure/Navigation/UniversalLinkHandler.swift`
    - `Shell/Core/Infrastructure/Navigation/CustomURLSchemeHandler.swift`
    - `Shell/SceneDelegate.swift`
- Pending-route restore exists for post-login redirect:
  - `Shell/Core/Coordinator/AppCoordinator.swift`
  - `ShellTests/App/Coordinators/PostLoginRedirectTests.swift`
- Current authenticated root flow enters via `DogCoordinator`:
  - `Shell/Core/Coordinator/AppCoordinator.swift`
  - `Shell/App/Coordinators/DogCoordinator.swift`
- `ItemsCoordinator` and profile flows still exist but are no longer the default authenticated entry path.

## Confirmed Gaps

1. Login does not persist authenticated session
- `LoginViewModel` validates format and reports success, but does not save a real session via `SessionRepository`.
- Files:
  - `Shell/Features/Auth/Presentation/Login/LoginViewModel.swift`
  - `Shell/Features/Auth/Domain/UseCases/ValidateCredentialsUseCase.swift`

2. Unsafe `.notFound` fallback behavior
- `AppRouter` currently routes `.notFound` to authenticated flow.
- File:
  - `Shell/App/Navigation/AppRouter.swift`

3. Potential duplicate stack entries in authenticated flow
- `DogCoordinator.start()` calls `pushViewController` for its list screen.
- Re-routing to authenticated state can stack duplicate root list screens.
- File:
  - `Shell/App/Coordinators/DogCoordinator.swift`

4. Deep-link path complexity
- Deep-link handling uses both direct handler dispatch and notification-based universal-link bridging.
- Files:
  - `Shell/SceneDelegate.swift`
  - `Shell/AppDelegate.swift`

5. Missing end-to-end navigation integration tests
- Resolver/guard/handler unit tests exist.
- Integrated `AppRouter + AppCoordinator` route outcome tests are missing.

## Most Valuable Improvements

1. Auth persistence
- Ensure login writes a valid `UserSession` to `SessionRepository` (Keychain-backed).
- Use `KeychainSessionRepository` as production storage.
- File:
  - `Shell/Core/Infrastructure/Security/KeychainSessionRepository.swift`

2. Routing correctness
- Change `.notFound` behavior to safe fallback (guest/error route), not authenticated root.
- Ensure denial paths route to explicit UX when needed.

3. Authenticated root idempotency
- Prevent duplicate list/root stack entries by resetting root stack where appropriate (`setViewControllers`) instead of repeated pushes.

4. Deep-link simplification
- Prefer a single deep-link pipeline where practical; avoid duplicate routing entry mechanisms.

5. Integration verification
- Add integration tests for `AppRouter + AppCoordinator` to assert:
  - denied routes save/restore pending route
  - post-login pending route navigation works
  - `.notFound` fallback correctness
  - authenticated re-entry does not duplicate root stack

## Refactor Constraints

- Apply changes in phases; do not batch everything in one commit.
- Preserve coordinator ownership of navigation decisions.
- Maintain typed-route API and auth guard boundary.
- Add tests with each phase to prevent regressions.
- Prefer minimal, behavior-preserving edits around app boot and scene lifecycle.

## Phase Targets

### Phase 1: Auth
- Wire login success to session persistence.
- Verify relaunch/deep-link auth checks can observe persisted session.
- Add tests for login-to-session persistence behavior.

### Phase 2: Routing
- Fix `.notFound` fallback behavior in router.
- Fix duplicate stack risk in authenticated root flow.
- Add/adjust tests for routing outcomes.

### Phase 3: Verification
- Add integration-focused tests for `AppRouter + AppCoordinator` flow behavior.
- Verify pending-route restore and stack idempotency end-to-end.

## Prompt Template (for Claude Plan Mode)

Subject: Navigation & Auth Refactor

I need to refactor our app's navigation and authentication persistence. I have documented the current state, gaps, and desired improvements in @docs/navigation-refactor-spec.md.

Please read that spec and analyze the current implementation in these files to confirm the state matches my description:
@Shell/App/Navigation/AppRouter.swift
@Shell/Core/Coordinator/AppCoordinator.swift
@Shell/Core/Navigation/Route.swift
@Shell/Features/Auth/Presentation/Login/LoginViewModel.swift
@Shell/SceneDelegate.swift

Goal: Create a phased implementation plan to execute the "Most Valuable Improvements" listed in the spec.

Requirements for the Plan:
1. Phase 1 (Auth): Focus on `KeychainSessionRepository.swift` (create if missing) and hooking it into `LoginViewModel`.
2. Phase 2 (Routing): Fix the `.notFound` fallback and `DogCoordinator` stack duplication issues.
3. Phase 3 (Verification): Outline the integration tests needed for `AppRouter + AppCoordinator` to verify these flows.

Do not write implementation code yet. Output the plan and ask me for approval.
