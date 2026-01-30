# Shell - iOS Expert Skills Testing Framework

A comprehensive testing framework demonstrating mastery across 12 iOS development skill areas.

## Purpose

This repository contains practical demonstrations of iOS development expertise. Each skill area has its own isolated branch with working code, tests, and documentation proving competence.

## Architecture

### Base Branch (main)
- Clean iOS project starter
- CI/CD configuration
- Linting setup
- Documentation structure
- All agent definitions

### Test Branches

Each test branch demonstrates one expert skill area with:
- Working code implementation
- Unit/UI tests where applicable
- Documentation in `/Docs/Test-XX.md`
- Clear pass/fail criteria
- Independent merge capability

## Test Branch Overview

| # | Branch | Expert Area | Key Demonstrations |
|---|--------|-------------|-------------------|
| 01 | `test/01-storyboard-ui` | Storyboard & Interface Builder | 3-screen flow, Auto Layout, Dynamic Type, size classes |
| 02 | `test/02-swift-language` | Swift Language Mastery | Protocol-oriented design, generics, async/await, memory management |
| 03 | `test/03-architecture-mvvm-coordinator` | iOS Architecture | MVVM + Coordinator pattern, dependency injection, layer separation |
| 04 | `test/04-uikit-programmatic` | UIKit Programmatic | Diffable data source, compositional layout, custom animations |
| 05 | `test/05-swiftui-foundations` | SwiftUI Foundations | State management, composition, NavigationStack, async loading |
| 06 | `test/06-swiftui-advanced` | SwiftUI Advanced | Custom layouts, matched geometry, accessibility |
| 07 | `test/07-testing-xctest` | Testing & TDD | Unit tests, integration tests, UI tests, test pyramid |
| 08 | `test/08-networking` | Networking | URLSession, Codable, error handling, auth flows |
| 09 | `test/09-coredata` | Core Data | Persistence, migrations, background saves, fetch optimization |
| 10 | `test/10-performance` | Performance Optimization | Instruments profiling, bottleneck identification, optimization |
| 11 | `test/11-security` | Security & Privacy | Keychain, biometrics, encryption, secure storage |
| 12 | `test/12-debugging` | Debugging Techniques | LLDB, breakpoints, crash analysis, memory debugging |

## Success Criteria

Each test branch must meet its documented criteria (see `/Docs/Test-XX.md` in each branch):

### Universal Requirements
- ✅ Code compiles and runs without warnings
- ✅ No constraint ambiguity or runtime layout errors
- ✅ Tests pass (where applicable)
- ✅ Clean git history
- ✅ Documentation explains what was built and why

### Scoring
Each branch self-documents its pass criteria. Examples:
- **Storyboard**: Rotate + XXL text = 0 layout warnings
- **Swift**: Instruments shows no leaks
- **Testing**: Tests run in parallel without flakiness
- **Networking**: Requests are cancellable
- **Performance**: Before/after profiling numbers

## Running Tests

### Check out a specific test
```bash
git checkout test/01-storyboard-ui
open Shell.xcodeproj
# Read Docs/Test-01.md for specific instructions
```

### View all branches
```bash
git branch -a
```

### Compare implementations
```bash
# Compare Storyboard vs UIKit vs SwiftUI approaches
git diff test/01-storyboard-ui..test/04-uikit-programmatic
```

## Project Structure

```
Shell/
├── .claude/
│   ├── Agents/          # Expert agent definitions
│   ├── Context/         # Project context
│   └── Skills/          # Custom skills
├── Docs/                # Test documentation (per branch)
│   ├── Test-01.md
│   ├── Test-02.md
│   └── ...
├── Shell/               # iOS app source
├── ShellTests/          # Unit tests
├── ShellUITests/        # UI tests
├── .github/workflows/   # CI configuration
├── .swiftlint.yml       # Linting rules
└── README.md            # This file
```

## Development Environment

- **Xcode**: 15.0+
- **iOS Target**: 16.0+
- **Swift**: 5.9+
- **Testing**: XCTest
- **CI**: GitHub Actions

## CI/CD

Each branch runs:
- SwiftLint checks
- Build verification
- Unit tests
- UI tests (where applicable)

## Contributing

This is a skills demonstration repository. Each branch represents a completed test case.

### Adding a New Test
1. Branch from `main`
2. Implement the feature/demonstration
3. Add documentation to `Docs/Test-XX.md`
4. Ensure all criteria are met
5. Keep branch independent (don't depend on other test branches)

## Expert Agent System

This project uses specialized expert agents defined in `.claude/Agents/`:

- `storyboard-expert.md` - Storyboard & UI/UX
- `swift-expert.md` - Swift language
- `ios-architecture-expert.md` - Architecture patterns
- `uikit-expert.md` - UIKit programmatic
- `swiftui-expert.md` - SwiftUI
- `testing-expert.md` - Testing strategies
- `networking-expert.md` - Networking & APIs
- `core-data-expert.md` - Data persistence
- `performance-expert.md` - Optimization
- `security-expert.md` - Security & privacy
- `debugging-expert.md` - Debugging techniques

These agents provide specialized knowledge and best practices for each domain.

## License

MIT

## Author

Adam Oates - iOS Development Skills Demonstration
