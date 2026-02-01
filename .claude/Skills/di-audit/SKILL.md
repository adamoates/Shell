---
name: di-audit
description: Audit AppDependencyContainer for complete dependency wiring, proper protocol usage, no circular dependencies, and correct factory methods. Use when adding new features or debugging dependency issues.
allowed-tools: Read, Grep, Glob
---

# Dependency Injection Audit

Audit the DI container and dependency graph for correctness. Read `.claude/Context/architecture.md` (Rule 5: Composition Root) for requirements.

## Primary File

`Shell/Core/DI/AppDependencyContainer.swift`

## Checks to Perform

### 1. Completeness

For each feature in `Shell/Features/`:
- VIOLATION if no repository property exists in the container
- VIOLATION if no use case factory methods exist
- VIOLATION if no coordinator factory method exists (`makeXCoordinator()`)
- Cross-reference: every protocol in `Core/Contracts/` should have a concrete wiring

### 2. Protocol Usage

All public/internal properties:
- MUST be typed as protocols, not concrete types
- VIOLATION: `let repo: InMemoryUserProfileRepository` (should be `UserProfileRepository`)
- Concrete types should only appear on the right side of assignments

### 3. No Circular Dependencies

Trace the dependency graph:
- A depends on B, B depends on A = CIRCULAR (VIOLATION)
- Repositories should not depend on use cases
- Use cases should not depend on ViewModels

Valid direction: `Coordinator -> ViewModel -> UseCase -> Repository -> DataSource`

### 4. Singleton Justification

For any `lazy var` or shared instance:
- Must be justified (session state, shared cache)
- VIOLATION if a ViewModel or Coordinator is a singleton
- ALLOWED: Repositories holding shared state, session management

### 5. Factory Method Pattern

Each factory method should:
- Return a protocol type (or Coordinator)
- Create dependencies using other factory methods
- Not leak implementation details

### 6. Initialization Order

- `lazy var` for expensive or optional dependencies
- Direct init for always-needed lightweight dependencies
- WARNING if all properties are eagerly initialized

## Output Format

```
## DI Container Audit

### Wiring Completeness
| Feature | Repository | Use Cases | Coordinator |
|---------|-----------|-----------|-------------|
| Auth | PASS | PASS (2) | PASS |
| Items | PASS | PASS (1) | PASS |
| Profile | PASS | PASS (2) | PASS |

### Protocol Usage: PASS/FAIL
### Circular Dependencies: PASS/FAIL
### Issues Found: N
```
