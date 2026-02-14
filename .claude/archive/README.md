# Archive

**Why these files are archived:**

This project had accumulated **13 agents**, **18+ skills**, and **18 context documents**.

This created:
- Decision paralysis
- Overlapping workflows
- Analysis loops
- Slow progress
- Mental overhead

## What Was Archived (2026-02-14)

### Agents/ (13 agents)
- core-data-expert
- debugging-expert
- ios-architecture-expert
- networking-expert
- performance-expert
- security-expert
- storyboard-expert
- swift-6-expert
- swift-expert
- swift-reviewer
- swiftui-expert
- testing-expert
- uikit-expert

**Why:** Too many overlapping agents creating confusion. Use standard Claude instead.

### Skills/ (15+ skills)
- architecture-check
- ci-checklist
- code-quality-check
- coordinator-review
- di-audit
- git-diff-reviewer
- git-hooks-setup
- git-maintenance
- http-repo
- regression-suite
- release-notes
- scaffold-use-case
- swiftlint
- commit
- mvvm-enforcer
- xcode-architect
- ... and more

**Why:** Reduced to 3 core skills (new-feature, test-feature, simulator-ui-review). Everything else is premature optimization.

### Context/ (18 docs)
- architecture.md
- branch-strategy.md
- code-quality.md
- current-state.md
- design-patterns.md
- identity-sandbox-module.md
- navigation.md
- project-structure.md
- requirements.md
- schema-driven-ux.md
- starter-kit-use-cases.md
- tdd-requirements.md
- EPIC_2_IMPLEMENTATION_GUIDE.md
- TEST_CONFIGURATION_FIX_GUIDE.md
- TESTING_FIX_GUIDE.md
- QUICK_TEST_FIX_CHECKLIST.md
- README.md

**Why:** Consolidated into PLAYBOOK.md (workflow) and CLAUDE.md (technical reference). 18 docs is too many competing sources of truth.

## Current Active Files

Only 2 files matter now:
- **PLAYBOOK.md** - Daily workflow and decision making
- **CLAUDE.md** - Technical reference for architecture and patterns

And 3 skills:
- **/new-feature** - Build features
- **/test-feature** - Run tests
- **/simulator-ui-review** - Visual debugging

## When to Use Archived Content

These files are NOT deleted - they're archived for future reference.

Use them only when:
- You need deep technical details not in CLAUDE.md
- You're troubleshooting a specific pattern
- You're researching a particular topic

**But default to PLAYBOOK.md for daily work.**

## Philosophy

This archive represents a shift from:

❌ Process-heavy, tool-heavy development
✅ Product-focused, ship-focused development

The goal: **Build features, not tooling.**

---

**Archived:** 2026-02-14
**Reason:** Tooling bloat cleanup
**Impact:** Faster development, clearer focus
