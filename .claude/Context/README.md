# Shell iOS App - Claude Code Context

## Overview

This directory contains the **master requirements, rules, and standards** for the Shell iOS app.

**These are non-negotiable.** Every line of code must meet these standards.

## Files in This Directory

### Core Requirements
- **[requirements.md](requirements.md)** - Master requirements and app concept
  - Global objectives
  - App concept (Field Notes / Shell)
  - UI strategy
  - Acceptance criteria
  - Success metrics

### Architecture & Design
- **[architecture.md](architecture.md)** - Architecture rules and patterns
  - Clean Architecture (Domain → Data ← UI)
  - Layer responsibilities and dependencies
  - Design patterns with justifications
  - Testing strategies per layer

- **[design-patterns.md](design-patterns.md)** - Pattern reference guide
  - When and how to use each pattern
  - Code examples for all patterns
  - Pattern selection guide
  - Anti-patterns to avoid

- **[project-structure.md](project-structure.md)** - Folder organization
  - Directory structure
  - File naming conventions
  - Import rules per layer
  - How to create new features

### Code Quality
- **[code-quality.md](code-quality.md)** - Code quality standards
  - Naming conventions
  - Function/class size limits
  - Error handling rules
  - Comment guidelines
  - SwiftLint configuration
  - Complexity metrics

### Testing
- **[tdd-requirements.md](tdd-requirements.md)** - TDD requirements
  - Test-first approach
  - What must be tested (coverage targets)
  - Test structure (AAA pattern)
  - Test doubles (mocks, stubs, fakes)
  - Integration test strategies

### Process
- **[branch-strategy.md](branch-strategy.md)** - Branch workflow
  - Branch naming convention
  - One branch = one vertical slice
  - Branch content requirements
  - Merge checklist

## How to Use This Context

### When Starting Work
1. Read [requirements.md](requirements.md) to understand the app vision
2. Review [architecture.md](architecture.md) for architecture rules
3. Check [project-structure.md](project-structure.md) for where files go

### When Writing Code
1. Follow [code-quality.md](code-quality.md) standards
2. Use [design-patterns.md](design-patterns.md) as a reference
3. Apply [tdd-requirements.md](tdd-requirements.md) for testing

### When Creating a Branch
1. Follow [branch-strategy.md](branch-strategy.md)
2. Ensure all quality standards met
3. Write comprehensive documentation

### When Reviewing Code
Use these files as the review criteria:
- Architecture boundaries respected?
- Code quality standards met?
- Tests written first?
- Design patterns used appropriately?

## The Standard

This codebase must:
- ✅ Pass staff-level code review
- ✅ Scale to new features easily
- ✅ Survive refactors safely
- ✅ Be maintainable for years
- ✅ Demonstrate production practices

Not:
- ❌ A tutorial or demo app
- ❌ Quick and dirty prototypes
- ❌ Cutting corners for speed
- ❌ Accepting technical debt

## Quick Reference Card

### Architecture
```
UI → Domain ← Data
```
- Domain: Pure business logic, no dependencies
- Data: Implements domain protocols
- UI: Uses domain use cases

### Patterns
- Navigation: Coordinator
- Presentation: MVVM
- Business Logic: Use Case
- Data Access: Repository
- Platform Integration: Adapter
- Cross-cutting: Decorator

### Quality
- Zero warnings
- Zero force unwraps
- Functions < 50 lines
- Classes < 300 lines
- Cyclomatic complexity < 10
- >80% test coverage

### Testing
- Tests first (TDD)
- Use cases: 100% covered
- ViewModels: 100% covered
- Repositories: 80%+ covered
- Deterministic, fast, independent

### Process
- One branch per feature
- Complete vertical slices
- Documentation required
- All tests pass before merge
- Clean git history

## Questions?

If anything is unclear:
1. Check the relevant file in this directory
2. Look at existing code for examples
3. Ask for clarification

**These standards are the foundation of quality. No exceptions.**
