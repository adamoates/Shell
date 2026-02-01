# Test Feature Skill

Run tests for a specific feature module instead of the entire test suite.

## When to use

When you want to run only the tests related to a specific feature (Items, Profile, Auth, etc.) for faster feedback during development.

## Steps

### 1. Ask which feature to test

Prompt the user:
```
Which feature would you like to test?
- Items
- Profile
- Auth
- SwiftSDK (Storage/Validation/Observation)
- All (run full test suite)
```

### 2. Map feature to test targets

Map the user's choice to the corresponding test suite:

| Feature | Test Target |
|---------|-------------|
| Items | `ShellTests/ItemsListViewModelTests`, `ShellTests/CreateItemUseCaseTests`, `ShellTests/InMemoryItemsRepositoryTests` |
| Profile | `ShellTests/ProfileEditorViewModelTests`, `ShellTests/CompleteIdentitySetupUseCaseTests`, `ShellTests/InMemoryUserProfileRepositoryTests` |
| Auth | `ShellTests/LoginViewModelTests`, `ShellTests/ValidateCredentialsUseCaseTests` |
| SwiftSDK | `ShellTests/InMemoryStorageTests`, `ShellTests/ValidatorTests`, `ShellTests/ObserverTests` |
| Core | `ShellTests/CoordinatorTests`, `ShellTests/RouteParametersTests` |
| All | Run entire `ShellTests` suite |

### 3. Run targeted tests

Execute the appropriate xcodebuild command:

```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/<TestSuiteName>
```

**Examples:**

For Items feature:
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/ItemsListViewModelTests \
  -only-testing:ShellTests/CreateItemUseCaseTests \
  -only-testing:ShellTests/FetchItemsUseCaseTests \
  -only-testing:ShellTests/UpdateItemUseCaseTests \
  -only-testing:ShellTests/DeleteItemUseCaseTests \
  -only-testing:ShellTests/InMemoryItemsRepositoryTests
```

For Profile feature:
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/ProfileEditorViewModelTests \
  -only-testing:ShellTests/CompleteIdentitySetupUseCaseTests \
  -only-testing:ShellTests/FetchProfileUseCaseTests \
  -only-testing:ShellTests/InMemoryUserProfileRepositoryTests \
  -only-testing:ShellTests/IdentityTests
```

For SwiftSDK:
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/InMemoryStorageTests \
  -only-testing:ShellTests/InMemoryCacheTests \
  -only-testing:ShellTests/ValidatorTests \
  -only-testing:ShellTests/StringLengthValidatorTests \
  -only-testing:ShellTests/RegexValidatorTests \
  -only-testing:ShellTests/CharacterSetValidatorTests \
  -only-testing:ShellTests/DateAgeValidatorTests \
  -only-testing:ShellTests/RangeValidatorTests \
  -only-testing:ShellTests/ComposedValidatorTests \
  -only-testing:ShellTests/ObserverTests
```

For all tests:
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### 4. Parse and summarize results

Extract key metrics from the test output:

```bash
# Count passing tests
grep " passed on " | wc -l

# Count failing tests
grep " failed on " | wc -l

# Find first failure
grep " failed on " | head -1
```

### 5. Display summary

Print a formatted summary:

```
📊 Test Results for <FeatureName>

✅ Passed: <count> tests
❌ Failed: <count> tests
⏱️  Duration: <seconds>s

<If failures exist:>
❌ First failure:
   Test: <TestClassName>.<testMethodName>
   Location: <FilePath>:<LineNumber>

<If all pass:>
✅ All tests passed!

Next steps:
- Review test coverage
- Run full suite: xcodebuild test -scheme Shell
- Check build warnings
```

## Advanced Options

### Run specific test class

If user provides a specific test class name:

```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/<TestClassName>
```

### Run specific test method

If user provides class + method:

```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/<TestClassName>/<testMethodName>
```

### Example:
```bash
# Run only the save success test in ProfileEditorViewModelTests
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/ProfileEditorViewModelTests/testSaveSuccess
```

## Notes

- Tests run on iOS Simulator (iPhone 17 Pro by default)
- Test output is verbose - summary extracts key information
- Failed tests include file path for quick navigation
- Use this for rapid iteration during feature development
- Run full suite (`All`) before commits and PRs
