---
name: coordinator-review
description: Review coordinator implementation for proper navigation encapsulation, child lifecycle management, delegate patterns, and dependency wiring. Use when writing or reviewing coordinator code.
allowed-tools: Read, Grep, Glob
argument-hint: [coordinator-file-path]
---

# Coordinator Review

Review coordinator(s) for compliance with Shell's Coordinator pattern. Read `.claude/Context/design-patterns.md` for the full pattern reference.

If `$ARGUMENTS` is provided, review that specific file. Otherwise scan all coordinators in `Shell/App/Coordinators/` and `Shell/Core/Coordinator/`.

## Required Checks

### 1. Protocol Conformance

Every coordinator must:
- Conform to `Coordinator` protocol
- Have `var navigationController: UINavigationController`
- Have `var childCoordinators: [Coordinator]`
- Have `weak var parentCoordinator: Coordinator?` (MUST be weak)
- Implement `start()` and `finish()`

VIOLATION if `parentCoordinator` is not `weak` (retain cycle risk).

### 2. Child Coordinator Lifecycle

When a coordinator creates a child:
- MUST call `addChild(_:)` before `child.start()`
- Child's `finish()` MUST call `parentCoordinator?.childDidFinish(self)`
- Parent MUST implement `childDidFinish(_:)` to call `removeChild(_:)`

VIOLATION if any child coordinator is started without `addChild`.
VIOLATION if `finish()` doesn't notify parent.

### 3. Navigation Encapsulation

- VIOLATION if any ViewController creates or presents another ViewController directly
- VIOLATION if any ViewController imports or references another ViewController type
- All navigation must go through coordinator methods
- ViewControllers communicate navigation intent via delegate pattern to coordinator

### 4. Delegate Pattern

Each coordinator should define a delegate protocol for parent communication:
- Delegate must be `weak`
- Delegate protocol must be `AnyObject`-constrained
- VIOLATION if coordinator communicates to parent via closures stored as strong references

### 5. Dependency Wiring

- All dependencies injected via `init()`
- Coordinator creates ViewModels using injected dependencies
- VIOLATION if coordinator accesses `AppDependencyContainer` directly (should receive via init)

### 6. ViewController Construction

Coordinators must construct ViewControllers with programmatic init:
- VIOLATION if using storyboard string identifiers without type safety
- WARNING if coordinator both constructs and extensively configures VC properties

## Output Format

```
## Coordinator Review: AuthCoordinator.swift

### Protocol Conformance
- [PASS] Conforms to Coordinator
- [PASS] Has navigationController
- [PASS] parentCoordinator is weak

### Child Lifecycle
- [PASS] addChild called before start
- [PASS] finish notifies parent

### Navigation Encapsulation
- [PASS] No VC-to-VC navigation

### Delegate Pattern
- [PASS] Delegate is weak and AnyObject

### Issues Found: 0
```
