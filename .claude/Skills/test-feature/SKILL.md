---
name: test-feature
description: Run tests for a specific feature module (Items, Profile, Auth, etc.) for faster feedback during development. Use when the user asks to test a feature or run specific tests.
argument-hint: [feature-name]
---

# Test Feature

Run tests for a specific feature module instead of the entire test suite.

Read `.claude/Context/tdd-requirements.md` for the full testing standards.

## Input

Feature name from `$ARGUMENTS`. If not provided, ask:

```
Which feature would you like to test?
- Items
- Profile
- Auth
- Core (navigation, routing)
- All (full test suite)
```

## Feature to Test Target Mapping

| Feature | Test Targets |
|---------|-------------|
| Dog | `ShellTests/CreateDogUseCaseTests`, `ShellTests/UpdateDogUseCaseTests`, `ShellTests/DeleteDogUseCaseTests`, `ShellTests/FetchDogsUseCaseTests`, `ShellTests/DogListViewModelTests`, `ShellTests/DogEditorViewModelTests`, `ShellTests/AuthenticationFlowTests` |
| Items | `ShellTests/ListViewModelTests`, `ShellTests/FetchItemsUseCaseTests` |
| Profile | `ShellTests/ProfileViewModelTests`, `ShellTests/CompleteIdentitySetupUseCaseTests`, `ShellTests/IdentitySetupViewModelTests`, `ShellTests/IdentityDataTests`, `ShellTests/RemoteUserProfileRepositoryTests`, `ShellTests/FetchProfileUseCaseTests` |
| Auth | `ShellTests/LoginViewModelTests`, `ShellTests/ValidateCredentialsUseCaseTests`, `ShellTests/RestoreSessionUseCaseTests`, `ShellTests/AuthenticationFlowTests` |
| Core | `ShellTests/RouteResolverTests`, `ShellTests/AuthGuardTests`, `ShellTests/DeepLinkHandlerTests`, `ShellTests/RouteParametersTests`, `ShellTests/ArchitectureEnforcementTests` |
| Boot | `ShellTests/AppBootstrapperTests`, `ShellTests/PostLoginRedirectTests` |
| All | Run entire `ShellTests` suite |

## Execution

**CRITICAL**: Always save test results for pre-commit hook verification.

### Targeted tests

```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/<TestSuiteName> \
  2>&1 | tee /tmp/shell_last_test.log

# Save timestamp for pre-commit hook
date +%s > /tmp/shell_last_test_time
```

Chain multiple `-only-testing:` flags for multi-suite features.

### Specific class or method

```bash
# Class only
-only-testing:ShellTests/<TestClassName>

# Class + method
-only-testing:ShellTests/<TestClassName>/<testMethodName>
```

### All tests

```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:ShellUITests \
  2>&1 | tee /tmp/shell_last_test.log

# Save timestamp for pre-commit hook
date +%s > /tmp/shell_last_test_time
```

### Verification Protocol

After running tests, ALWAYS verify:
1. Exit code is 0: `echo $?`
2. Output contains: `** TEST SUCCEEDED **`
3. No `** TEST FAILED **` messages
4. Count matches expected: `grep "passed" /tmp/shell_last_test.log | wc -l`

## Parse and Summarize

Extract from output:
- Passing: `grep "Test Case.*passed" | wc -l`
- Failing: `grep "Test Case.*failed" | wc -l`
- First failure details

## Display Summary

```
Test Results for <FeatureName>

Passed: <count> tests
Failed: <count> tests

<If all pass:> All tests passed!
<If failures:> First failure: <TestClassName>.<testMethodName> - <error>
```
