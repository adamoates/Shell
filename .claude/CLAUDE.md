# Shell - iOS Modernization Toolkit

**Tech Stack**: Swift 6, UIKit, Clean Architecture + MVVM + Coordinator
**Target**: iOS 26.2+ | Xcode 16.3 | Strict Concurrency Enabled

---

## Quick Start

**Build**:
```bash
xcodebuild build -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

**Test** (with verification):
```bash
xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skip-testing:ShellUITests 2>&1 | tee /tmp/shell_last_test.log && date +%s > /tmp/shell_last_test_time
```

**Launch**:
```bash
xcrun simctl launch booted com.adamcodertrader.Shell
xcrun simctl io booted screenshot /tmp/verify.png
```

---

## Architecture Map

```
Features/{Feature}/
├── Domain/        # Pure Swift, no UIKit (entities, use cases, protocols)
├── Presentation/  # UI layer (@MainActor ViewModels, ViewControllers)
└── Infrastructure/# External (repositories, HTTP, storage)

Core/
├── DI/            # AppDependencyContainer (dependency injection)
├── Contracts/     # Shared protocols (Repository, UseCase)
└── Infrastructure/# Config, Navigation, HTTP base

SwiftSDK/          # Reusable utilities (Validation, Observer, Storage)
```

**Layer Rule**: Domain → Infrastructure ← Presentation
**Never**: Presentation imports Infrastructure directly (use protocols)

---

## Verification Protocol

**After EVERY code change**:
1. Build → `xcodebuild build`
2. Test → `xcodebuild test`
3. Verify → Check `** TEST SUCCEEDED **` in output
4. Launch → Start in simulator
5. Screenshot → Capture UI state
6. Review → Verify visual correctness

**NEVER assume** tests pass. iOS compilation must be verified. Exit code 0 required.

**Pre-commit hook**: Blocks commits without recent test verification (`.git/hooks/pre-commit`)

---

## Critical Rules

**Swift 6 Concurrency**:
- All ViewModels: `@MainActor`
- All repositories: `actor` (thread-safe)
- All entities: `Sendable`
- No force unwraps: `!`, `try!`, `as!`

**Architecture**:
- Value types first (`struct` over `class`)
- Dependency injection via `AppDependencyContainer`
- No global state, no singletons
- Programmatic UI (no storyboards)

**Testing**:
- Unit tests: Mock dependencies
- Integration tests: Real implementations
- Red-Green-Refactor: Write failing test first
- Coverage: 100% for Domain, 80%+ for Infrastructure

---

## Progressive Disclosure

**When you need more detail**, read these guides:

- **Swift 6 Rules**: `@.claude/docs/swift-6-rules.md`
- **Testing Guide**: `@.claude/docs/testing-guide.md`
- **Architecture Patterns**: `@.claude/docs/architecture-patterns.md`
- **Commit Conventions**: `@.claude/docs/commit-conventions.md`
- **iOS Commands**: `@.claude/docs/ios-commands.md`
- **Daily Workflow**: `@.claude/docs/workflow.md`

**Use Skills for common tasks**:
- `/new-feature` - Scaffold vertical slice
- `/test-feature` - Run tests for specific feature
- `/simulator-ui-review` - Capture and analyze UI

**Use Agents for specialized help**:
- `@code-reviewer` - Security, performance, Swift 6 compliance
- `@planner` - Architectural planning, system design
- `@test-engineer` - Test coverage analysis, TDD guidance

---

## Project State

**Current Features**: Dog (CRUD + Auth), Items (HTTP integration)
**Tests**: 333 passing (33 Dog unit + 4 integration + others)
**Architecture**: Complete (Domain, Infrastructure, Presentation layers)

**Reference Implementation**: `Features/Items/` (HTTP repository, full CRUD)

---

## Safety

**Auto-formatting**: SwiftLint runs on every Edit/Write (via hooks)
**Push confirmation**: Prompts before `git push` to remote
**Test enforcement**: Pre-commit hook blocks without passing tests

---

_Last Updated: 2026-02-14 | Lines: 95_
