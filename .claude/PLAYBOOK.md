# Shell Development Playbook

**Single Source of Truth for Daily Development**

---

## 🎯 Current Focus

**Project Stage:** Product Discovery / MVP Development
**Architecture:** Clean Architecture + MVVM (Complete)
**Current Goal:** Ship user-facing features weekly

---

## 🚀 Active Work

### Current Epic
```
Epic: Items Module - HTTP Integration (COMPLETE ✅)
Status: Done
Next: Choose next epic (Profile editing OR New feature)
```

### Current Feature
```
Feature: TBD (Choose your next feature below)
Status: Planning
Branch: N/A
```

---

## 📋 Definition of Done

A feature is DONE when:

- ✅ Domain logic complete with tests
- ✅ Repository implemented (in-memory first, HTTP later)
- ✅ ViewModel + UI working
- ✅ Navigation integrated
- ✅ Error handling works
- ✅ **Tests PROVEN to pass** (see verification protocol below)
- ✅ No compiler warnings
- ✅ App launches in simulator
- ✅ Critical user flow tested end-to-end
- ✅ Committed to `main`

**No partial features. No TODOs. Ship complete vertical slices.**

### Test Verification Protocol 🔬

**CRITICAL**: Never claim tests pass without proving it.

```bash
# 1. Run tests (actually execute, don't assume)
xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skip-testing:ShellUITests

# 2. Verify exit code
echo $?  # Must be 0

# 3. Verify success message
# Look for: ** TEST SUCCEEDED **

# 4. Count passing tests
grep -c "passed" output.txt

# 5. Launch app in simulator
xcrun simctl launch booted com.adamcodertrader.Shell

# 6. Test critical path manually
# Example: Login → Dog List → Add Dog → Logout
```

**Red-Green TDD Workflow:**
1. Write failing test first
2. Run it, confirm it fails
3. Write implementation
4. Run it, confirm it passes
5. See `** TEST SUCCEEDED **` before claiming done

---

## 🛠️ The Only 3 Tools You Need

### 1. `/new-feature` (Primary Workflow)
**Use for:** Building any new feature
**Creates:** Complete vertical slice (Domain → Infrastructure → Presentation → Tests)
**When:** Starting work on a new feature

### 2. `/test-feature` (Testing)
**Use for:** Running tests for specific features
**When:** During development, before commits

### 3. `/simulator-ui-review` (Visual Verification)
**Use for:** Checking UI layout and visuals
**When:** Debugging UI, verifying changes

**That's it. Everything else is archived.**

---

## 🚫 What NOT to Do

### Stop These Immediately

❌ **Architecture validation loops**
→ Architecture is stable. Build features, not guardrails.

❌ **Refactoring without user value**
→ Only refactor when blocked or explicitly needed.

❌ **Meta work (tooling, documentation, process)**
→ If it doesn't help a user this week, skip it.

❌ **Multiple features at once**
→ One feature at a time. Finish, ship, move on.

❌ **Premature optimization**
→ Build it first. Optimize when you have data.

❌ **Analysis paralysis**
→ Make a decision. Build. Learn. Iterate.

---

## ⚡ Weekly Ritual

Every week, follow this cycle:

### Monday
1. Choose ONE feature to build
2. Define acceptance criteria
3. Start branch: `feature/name`

### Tuesday-Thursday
1. Use `/new-feature` to scaffold
2. Build domain → infrastructure → presentation
3. Write tests alongside code
4. Use `/test-feature` frequently

### Friday
1. Run full test suite
2. Commit to `main`
3. Demo to yourself or users
4. Plan next week's feature

**Repeat. Ship weekly.**

---

## 🎯 Next Feature Options

Choose ONE of these for your next sprint:

### Option 1: Profile Editing
**User Value:** Users can update their profile
**Complexity:** Medium
**Duration:** 2-3 days
**Uses existing:** Profile domain model

### Option 2: Items Offline Support
**User Value:** Items work without network
**Complexity:** Medium
**Duration:** 2-3 days
**Uses existing:** Items module + Core Data

### Option 3: New Feature Module
**Examples:** Notes, Watchlist, Alerts, Settings
**Complexity:** Medium-High
**Duration:** 3-5 days
**Uses existing:** Architecture patterns from Items

**Pick one. Build it. Ship it.**

---

## 🧠 Decision Framework

When you're stuck, ask:

### "Does this help a user THIS WEEK?"
- **Yes** → Do it
- **No** → Skip it

### "Is this blocking me RIGHT NOW?"
- **Yes** → Fix it
- **No** → Defer it

### "Am I overthinking this?"
- **Yes** → Pick the simplest option and build it
- **No** → Keep going

---

## 📊 Success Metrics

You're on track when you feel:

✅ Clear focus
✅ Daily progress
✅ Less friction
✅ More shipped features
✅ Reduced mental load

You're off track when you feel:

❌ Analysis loops
❌ Tooling work
❌ Documentation work
❌ Architecture debates
❌ Slow progress

---

## 🔥 When You're Stuck

### Problem: "I don't know what to build"
**Solution:** Pick Option 1 above. Just start.

### Problem: "Architecture feels wrong"
**Solution:** Your architecture is fine. Keep building.

### Problem: "I should refactor this"
**Solution:** Only if it's blocking you RIGHT NOW.

### Problem: "I need to improve tooling"
**Solution:** No you don't. Build features instead.

### Problem: "I should write documentation"
**Solution:** Ship working code. Document later.

---

## 📚 Reference (When Needed)

For deep technical details, see:
- `.claude/CLAUDE.md` - Architecture patterns and rules
- `.claude/archive/Context/` - Detailed design docs (if needed)

**But default to building, not reading.**

---

## 🎯 Remember

You're in **product discovery mode**.

Your job is:
- ✅ Build features
- ✅ Learn from users
- ✅ Iterate fast
- ✅ Ship weekly

Not:
- ❌ Perfect architecture
- ❌ Comprehensive tooling
- ❌ Process optimization
- ❌ Heavy documentation

**Build. Ship. Learn. Repeat.**

---

## 📚 Templates & References

When starting something new, these templates can help:

### Building a New Product on Shell?
→ [Context/product-strategy.md](.claude/Context/product-strategy.md)
- Define your niche
- Create user persona
- Determine MVP scope

### Need Detailed Feature Workflow?
→ [Context/workflow-product.md](.claude/Context/workflow-product.md)
- Vertical slice development
- Test-first approach
- Definition of done

### Building Scheduling/Booking Features?
→ [Context/booking-scheduling.md](.claude/Context/booking-scheduling.md)
- Domain model examples
- Common pitfalls
- MVP vs. v2 features

### Growing Your Team?
→ [Context/team-scaling.md](.claude/Context/team-scaling.md)
- Scaling stages (1 to 15 engineers)
- Vertical ownership model
- Hiring strategy

**These are optional references. Your daily workflow is this PLAYBOOK.**

---

**Last Updated:** 2026-02-14
**Status:** Active
**Stage:** Product Discovery / MVP
