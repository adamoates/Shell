# Quick Test Fix Checklist

**Goal:** Get ShellTests running in under 5 minutes

---

## 🚀 Quick Fix (Most Common Issue)

### ✅ Step 1: Enable ShellTests in Scheme (2 minutes)

1. Open Xcode
2. Press `⌘ + <` (Edit Scheme)
3. Click "Test" in left sidebar
4. ✓ Check the box next to "ShellTests"
5. Click "Close"
6. Press `⌘ + U` (Run Tests)

**If tests pass → DONE! 🎉**

**If tests still fail with "Undefined symbol" errors → Continue to Step 2**

---

## ⚙️ Step 2: Fix Test Target Configuration (5 minutes)

### In Xcode:

1. **Click on "Shell.xcodeproj"** (blue icon, top of Project Navigator)
2. **Under TARGETS, select "ShellTests"**
3. **General tab:**
   - Host Application: Should say "Shell"
   - If blank/None → Select "Shell" from dropdown
4. **Build Phases tab:**
   - Expand "Link Binary With Libraries"
   - Should include "Shell.app"
   - If missing → Click "+" → Select "Shell.app" → Add
5. **Build Settings tab:**
   - Search: "TEST_HOST"
   - Should be: `$(BUILT_PRODUCTS_DIR)/Shell.app/Shell`
   - Search: "BUNDLE_LOADER"
   - Should be: `$(TEST_HOST)`
6. **Press `⌘ + U`** (Run Tests)

**If tests pass → DONE! 🎉**

**If tests still fail → Continue to Step 3**

---

## 🧹 Step 3: Clean Build (2 minutes)

1. Press `⌘ + Shift + K` (Clean Build Folder)
2. Wait for "Clean Finished"
3. Press `⌘ + U` (Run Tests)

**Still failing? → Nuclear option:**

1. Close Xcode
2. Open Terminal:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Shell-*
   ```
3. Reopen Xcode
4. Press `⌘ + U`

---

## ✅ Success Looks Like This

**Test Navigator (⌘ + 6):**
```
✓ ShellTests (181 tests)
  ✓ CreateItemUseCaseTests (8 tests)
  ✓ UpdateItemUseCaseTests (9 tests)
  ✓ ItemEditorViewModelTests (14 tests)
  ✓ LoginViewModelTests (...)
  ✓ ProfileViewModelTests (...)
  ✓ ... all green checkmarks
```

**Console Output:**
```
Test Suite 'All tests' passed
Executed 181 tests, with 0 failures in X.XXX seconds
```

---

## 🐛 Still Broken?

See detailed guide: `TEST_CONFIGURATION_FIX_GUIDE.md`

Or report:
- Which step failed
- Full error message from Xcode console
- Xcode version (Xcode → About Xcode)

---

## 📊 What You Should See

**Epic 2 Tests (31 new):**
- ✓ CreateItemUseCaseTests: 8 tests
- ✓ UpdateItemUseCaseTests: 9 tests
- ✓ ItemEditorViewModelTests: 14 tests

**Existing Tests (150+):**
- ✓ All previous tests still passing

**Total: ~181 tests** (exact count may vary)

---

**Estimated Time:** 2-5 minutes
**Last Updated:** 2026-01-31
