# Test Configuration Fix Guide

**Status:** Tests compile but fail at link time due to Xcode configuration issues.

**Goal:** Enable ShellTests target in scheme and verify linking configuration.

---

## Issue Summary

After migrating to programmatic UI and adding Epic 2 test foundation:
- ✅ Shell.app builds successfully
- ✅ All Swift files compile without errors
- ❌ ShellTests fail at link time with "Undefined symbol" errors
- ❌ ShellTests not included in test scheme

**Root Causes:**
1. ShellTests target not enabled in Shell scheme's Test action
2. Possible test target linking misconfiguration

---

## Fix #1: Enable ShellTests in Test Scheme (REQUIRED)

### Step-by-Step Instructions:

1. **Open Xcode**
   - Open `/Users/adamoates/Code/Ios/Shell/Shell.xcodeproj` in Xcode

2. **Access Scheme Editor**
   - Click on the scheme selector at the top (shows "Shell > iPhone 17 Pro")
   - Select "Edit Scheme..." from the dropdown
   - **Keyboard shortcut:** `⌘ + <` (Command + Less Than)

3. **Navigate to Test Action**
   - In the left sidebar of the scheme editor, click "Test"
   - You should see a list of test targets and test classes

4. **Enable ShellTests Target**
   - Look for "ShellTests" in the list of test targets
   - There should be a checkbox next to it
   - **Check the box** to enable ShellTests

   **What you should see:**
   ```
   ✓ ShellTests
     ├─ CreateItemUseCaseTests
     ├─ UpdateItemUseCaseTests
     ├─ ItemEditorViewModelTests
     ├─ LoginViewModelTests
     ├─ ProfileViewModelTests
     ├─ ... (more test classes)
   ```

5. **Verify Test Classes are Enabled**
   - Expand the ShellTests target (click the disclosure triangle)
   - Ensure individual test classes are also checked
   - If unchecked, enable:
     - ✓ CreateItemUseCaseTests
     - ✓ UpdateItemUseCaseTests
     - ✓ ItemEditorViewModelTests
     - ✓ All other test classes

6. **Save Scheme**
   - Click "Close" button
   - The scheme will be saved automatically

7. **Verify Scheme File**
   - The scheme file should be at: `Shell.xcodeproj/xcshareddata/xcschemes/Shell.xcscheme`
   - This file should now include test target references

---

## Fix #2: Verify Test Target Configuration (IF LINKING STILL FAILS)

If tests still fail with "Undefined symbol" errors after Fix #1, check the test target configuration:

### Step-by-Step Instructions:

1. **Select ShellTests Target**
   - In Xcode's Project Navigator (left sidebar), click on "Shell.xcodeproj" (blue icon at top)
   - In the main editor area, you'll see TARGETS and PROJECT sections
   - Under TARGETS, select "ShellTests"

2. **Check General Tab**
   - Click "General" tab at the top
   - Verify the following settings:

   **Testing:**
   - Host Application: `Shell` (should show Shell.app)
   - If "None" is selected or it's blank:
     1. Click the dropdown
     2. Select "Shell" from the list
     3. Xcode will prompt about adding a dependency - click "Add"

3. **Check Build Phases Tab**
   - Click "Build Phases" tab at the top
   - Expand "Link Binary With Libraries" section

   **Expected configuration:**
   ```
   Link Binary With Libraries (5 items)
   ├─ XCTest.framework (Required)
   ├─ Foundation.framework (Optional)
   ├─ UIKit.framework (Optional)
   ├─ Combine.framework (Optional)
   └─ Shell.app (Required) ← MOST IMPORTANT
   ```

   **If Shell.app is missing:**
   1. Click the "+" button below the list
   2. In the dialog, find and select "Shell.app"
   3. Click "Add"

4. **Check Build Settings Tab**
   - Click "Build Settings" tab
   - In the search box (top right), type: "TEST_HOST"

   **Verify TEST_HOST setting:**
   - Should be: `$(BUILT_PRODUCTS_DIR)/Shell.app/Shell`
   - If different or empty:
     1. Double-click the value
     2. Paste: `$(BUILT_PRODUCTS_DIR)/Shell.app/Shell`
     3. Press Enter

   **Also search for: "BUNDLE_LOADER"**
   - Should be: `$(TEST_HOST)`
   - If different or empty:
     1. Double-click the value
     2. Enter: `$(TEST_HOST)`
     3. Press Enter

5. **Check Target Dependencies**
   - Still in Build Phases tab
   - Expand "Dependencies" section
   - Should show: `Shell` (the app target)
   - If missing:
     1. Click "+" button
     2. Select "Shell" from the list
     3. Click "Add"

---

## Fix #3: Clean Build Folder (IF STILL FAILING)

Sometimes Xcode caches build artifacts that cause linking issues:

### Step-by-Step Instructions:

1. **Clean Build Folder**
   - Menu: `Product → Clean Build Folder`
   - **Keyboard shortcut:** `⌘ + Shift + K`
   - Wait for "Clean Finished" message in Xcode's activity viewer (top center)

2. **Delete Derived Data (Nuclear Option)**
   - Close Xcode completely
   - Open Terminal
   - Run:
     ```bash
     rm -rf ~/Library/Developer/Xcode/DerivedData/Shell-*
     ```
   - Reopen Xcode
   - Build and test

---

## Running Tests

### Method 1: Run All Tests

1. **Using Menu:**
   - Menu: `Product → Test`
   - **Keyboard shortcut:** `⌘ + U`

2. **Wait for Results:**
   - Xcode will build the app, then build tests, then run
   - Progress shown in activity viewer (top center)
   - Results appear in Test Navigator (left sidebar, diamond icon)

### Method 2: Run Specific Test Class

1. **Open Test Navigator:**
   - Click diamond icon in left sidebar
   - Or Menu: `View → Navigators → Show Test Navigator`
   - **Keyboard shortcut:** `⌘ + 6`

2. **Run Individual Tests:**
   - Hover over a test class name (e.g., "CreateItemUseCaseTests")
   - Click the play icon (▶) that appears
   - Or right-click → "Run 'CreateItemUseCaseTests'"

3. **Run Single Test Method:**
   - Expand a test class
   - Hover over individual test method
   - Click play icon to run just that test

### Method 3: Run Tests from Source File

1. **Open Test File:**
   - Navigate to a test file (e.g., CreateItemUseCaseTests.swift)

2. **Run Tests:**
   - Look for diamond icons in the gutter (left of line numbers)
   - Click diamond next to class name → runs all tests in class
   - Click diamond next to method → runs single test
   - Green = passed, Red = failed

---

## Expected Test Results

### Epic 2: New Tests (31 total)

**CreateItemUseCaseTests (8 tests):**
```
✓ testExecute_withValidData_createsItem
✓ testExecute_withValidData_callsRepository
✓ testExecute_withEmptyTitle_throwsValidationError
✓ testExecute_withEmptySubtitle_throwsValidationError
✓ testExecute_withEmptyDescription_throwsValidationError
✓ testExecute_whenRepositoryFails_propagatesError
```

**UpdateItemUseCaseTests (9 tests):**
```
✓ testExecute_withValidData_updatesItem
✓ testExecute_preservesOriginalDate
✓ testExecute_withEmptyTitle_throwsValidationError
✓ testExecute_withEmptySubtitle_throwsValidationError
✓ testExecute_withEmptyDescription_throwsValidationError
✓ testExecute_withNonExistentID_throwsNotFoundError
✓ testExecute_whenRepositoryFails_propagatesError
```

**ItemEditorViewModelTests (14 tests):**
```
✓ testInit_createMode_hasEmptyFields
✓ testInit_editMode_prePopulatesFields
✓ testSave_createMode_withValidData_callsCreateUseCase
✓ testSave_createMode_onSuccess_notifiesDelegate
✓ testSave_editMode_withValidData_callsUpdateUseCase
✓ testSave_withEmptyTitle_setsErrorMessage
✓ testSave_withEmptySubtitle_setsErrorMessage
✓ testSave_withEmptyDescription_setsErrorMessage
✓ testSave_whenUseCaseFails_setsErrorMessage
✓ testSave_setsLoadingState
✓ testCancel_notifiesDelegate
```

### Existing Tests (150+)

All existing tests should continue to pass:
- LoginViewModelTests
- ProfileViewModelTests
- FetchItemsUseCaseTests
- ListViewModelTests
- ValidateCredentialsUseCaseTests
- RemoteUserProfileRepositoryTests
- CoordinatorTests
- etc.

---

## Troubleshooting

### Problem: "Undefined symbol" linker errors persist

**Symptoms:**
```
Undefined symbol: Shell.ListViewModel.items.getter
Undefined symbol: Shell.LoginViewModel.login()
Undefined symbol: type metadata accessor for Shell.AppCoordinator
```

**Solutions (try in order):**

1. **Verify Host Application is set:**
   - ShellTests target → General → Host Application = "Shell"

2. **Verify linking:**
   - ShellTests target → Build Phases → Link Binary With Libraries
   - Should include Shell.app

3. **Check @testable import:**
   - Open any test file
   - First line should be: `@testable import Shell`
   - If missing, tests can't access internal types

4. **Rebuild Shell.app first:**
   - Select Shell scheme (not ShellTests)
   - Menu: Product → Build (`⌘ + B`)
   - Wait for success
   - Then run tests

5. **Clean and rebuild:**
   - Product → Clean Build Folder
   - Product → Test

### Problem: Tests run but all fail immediately

**Symptoms:**
- Tests start but immediately fail
- Error: "Failed to load test bundle"

**Solution:**
- Check Console.app for crash logs
- Verify iOS Simulator version matches deployment target
- ShellTests → General → Deployment Info → should match Shell app target

### Problem: Some tests pass, some fail unexpectedly

**Symptoms:**
- CreateItemUseCaseTests pass
- UpdateItemUseCaseTests fail with "Item not found"

**Solution:**
- Mock repositories might have state pollution between tests
- Verify `setUp()` and `tearDown()` methods reset state
- Each test should be independent

### Problem: Xcode can't find test target

**Symptoms:**
- Test Navigator shows "No tests"
- Product → Test is grayed out

**Solution:**
1. Close Xcode
2. Delete `Shell.xcodeproj/xcuserdata/` folder
3. Delete `Shell.xcodeproj/project.xcworkspace/xcuserdata/` folder
4. Reopen Xcode
5. File → Close Workspace
6. File → Open → Select Shell.xcodeproj

---

## Verification Checklist

After completing the fixes, verify:

- [ ] ShellTests target is checked in Shell scheme's Test action
- [ ] ShellTests → General → Host Application = "Shell"
- [ ] ShellTests → Build Phases → Link Binary With Libraries includes Shell.app
- [ ] ShellTests → Build Phases → Dependencies includes Shell
- [ ] ShellTests → Build Settings → TEST_HOST = `$(BUILT_PRODUCTS_DIR)/Shell.app/Shell`
- [ ] ShellTests → Build Settings → BUNDLE_LOADER = `$(TEST_HOST)`
- [ ] Product → Test (`⌘ + U`) builds successfully
- [ ] All 31 new Epic 2 tests pass (green checkmarks)
- [ ] All 150+ existing tests pass (green checkmarks)
- [ ] Test Navigator shows test count: "181 tests" (or similar)
- [ ] No red X marks in Test Navigator

---

## Success Criteria

✅ **All tests pass:**
```
Test Suite 'All tests' passed at [timestamp]
Executed 181 tests, with 0 failures (0 unexpected) in X.XXX seconds
```

✅ **Epic 2 foundation verified:**
- CreateItemUseCase: ✓ 8/8 tests passing
- UpdateItemUseCase: ✓ 9/9 tests passing
- ItemEditorViewModel: ✓ 14/14 tests passing

✅ **Ready for Epic 2 implementation:**
- ItemEditorViewController (UI)
- Coordinator wiring
- DI container setup
- Manual QA

---

## Next Steps After Tests Pass

1. **Report Results**
   - Confirm test count: "X tests passed"
   - Note any unexpected failures
   - Share screenshot of Test Navigator (optional)

2. **Proceed with Epic 2**
   - Implement ItemEditorViewController (programmatic UI)
   - Wire up ItemsCoordinator (showCreateItem, showEditItem)
   - Update AppDependencyContainer (use case factories)
   - Update ListViewController (add "+" button)
   - Manual QA testing

3. **Git Commit** (recommended)
   ```bash
   git add .
   git commit -m "Epic 2: Test foundation complete - 31 tests added

   - CreateItemUseCase with validation and repository integration
   - UpdateItemUseCase with date preservation
   - DeleteItemUseCase for item removal
   - ItemsRepository protocol and InMemoryItemsRepository
   - ItemEditorViewModel for create/edit modes
   - Fixed Item.id type: Int → String (UUID support)
   - Made HTTPClient, HTTPRequest, HTTPResponse, ItemError public
   - Fixed test scheme configuration
   - Fixed actor isolation in mock repositories

   All tests passing (181 total, 31 new)

   Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
   ```

---

## Additional Resources

### Xcode Test Documentation
- [Apple: Testing Your Apps in Xcode](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)
- [Apple: Writing Tests](https://developer.apple.com/documentation/xctest/writing_tests)

### Project Files to Review
- Test scheme: `Shell.xcodeproj/xcshareddata/xcschemes/Shell.xcscheme`
- Project config: `Shell.xcodeproj/project.pbxproj`

### Test Files Created (Epic 2)
```
ShellTests/Features/Items/Domain/UseCases/
├── CreateItemUseCaseTests.swift       (8 tests)
├── UpdateItemUseCaseTests.swift       (9 tests)
└── FetchItemsUseCaseTests.swift       (existing)

ShellTests/Features/Items/Presentation/ItemEditor/
└── ItemEditorViewModelTests.swift     (14 tests)
```

### Production Files Created (Epic 2)
```
Shell/Features/Items/Domain/
├── UseCases/
│   ├── CreateItemUseCase.swift
│   ├── UpdateItemUseCase.swift
│   └── DeleteItemUseCase.swift
├── Contracts/
│   └── ItemsRepository.swift
└── Entities/
    └── Item.swift (modified: Int → String ID)

Shell/Features/Items/Infrastructure/
└── InMemoryItemsRepository.swift

Shell/Features/Items/Presentation/ItemEditor/
└── ItemEditorViewModel.swift
```

---

## Questions?

If you encounter issues not covered in this guide:

1. **Check Xcode Console**
   - View → Debug Area → Show Debug Area (`⌘ + Shift + Y`)
   - Look for error messages during test execution

2. **Check Build Log**
   - View → Navigators → Show Report Navigator (`⌘ + 9`)
   - Click on latest build/test run
   - Review errors in detail

3. **Report the Error**
   - Copy the full error message
   - Share which step failed
   - Include Xcode version: Xcode → About Xcode

---

**Last Updated:** 2026-01-31
**Created By:** Claude Code (Epic 2 Implementation)
**Estimated Time:** 10-15 minutes for configuration fixes
