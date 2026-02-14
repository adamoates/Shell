---
name: code-quality-check
description: Audit Swift code for quality metrics (function length, class size, complexity, naming, force unwraps, error handling). Use after writing or editing Swift files to ensure code meets Shell's quality bar.
allowed-tools: Read, Grep, Glob
---

# Code Quality Check

Audit Swift files for Shell's code quality standards. Read `.claude/Context/code-quality.md` for the full rule set.

If `$ARGUMENTS` is provided, check only that file/directory. Otherwise check recently modified or all Swift files.

## Checks to Perform

### 1. Size Limits

**Functions** (max 50 lines, ideal 10-20):
- Count lines between `func` declaration and closing `}`
- VIOLATION if any function exceeds 50 lines
- WARNING if any function exceeds 30 lines

**Types** (max 300 lines, ideal 100-200):
- Count lines for each `class`, `struct`, `enum`, `actor`
- VIOLATION if any type exceeds 300 lines
- WARNING if any type exceeds 200 lines

### 2. Naming Conventions

**Types** must be PascalCase. **Functions/Methods** must be camelCase, verb-based. **Boolean getters** must use `is`/`has`/`can`/`should` prefix. **Variables** must be camelCase, descriptive (no abbreviations like `req`, `vc`, `mgr` except `id`, `url`). **Collections** must be plural nouns.

### 3. Safety Checks

**Force unwraps** (`!`):
- VIOLATION in production code (`Shell/`)
- ALLOWED in test files and `fatalError("init(coder:)")` patterns

**Silenced errors** (`try?`):
- VIOLATION without justification comment

**Force casts** (`as!`):
- VIOLATION in production code

### 4. Error Handling

- Error types should be typed enums conforming to `Error`
- VIOLATION: throwing generic `NSError` or raw `Error`
- Errors must be mapped at layer boundaries

### 5. Access Control

- Default should be `private`; escalate only when needed
- Classes should be `final` unless designed for inheritance
- VIOLATION if public properties/methods exist without protocol justification

### 6. Code Organization

WARNING if files over 100 lines lack MARK comment organization:
- `// MARK: - Properties`
- `// MARK: - Initialization`
- `// MARK: - Lifecycle`

### 7. Parameters

- WARNING if any function has more than 3 parameters
- VIOLATION if more than 5 (should use parameter object)

## Output Format

```
## Code Quality Report

### File: SomeFile.swift

| Check | Status | Details |
|-------|--------|---------|
| Function size | PASS | Longest: 28 lines |
| Type size | PASS | 156 lines |
| Naming | PASS | All conventions followed |
| Force unwraps | VIOLATION | Line 45: `user!.name` |
| Error handling | PASS | Typed errors used |
| Access control | WARNING | 3 internal methods could be private |

### Summary
- Files checked: N
- Violations: N
- Warnings: N
```
