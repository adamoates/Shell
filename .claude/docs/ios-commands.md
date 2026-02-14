# iOS Development Commands Reference

**Quick reference for xcodebuild and simulator commands**

---

## Build Commands

### Build App
```bash
xcodebuild build \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Clean Build
```bash
xcodebuild clean -scheme Shell
```

### Build with Verbose Output
```bash
xcodebuild build \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -verbose
```

---

## Test Commands

### Run All Tests
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:ShellUITests
```

### Run Specific Test Class
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/DogListViewModelTests
```

### Run Specific Test Method
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/CreateDogUseCaseTests/testCreateDogSuccess
```

### Run Tests with Logging
```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skip-testing:ShellUITests \
  2>&1 | tee /tmp/shell_last_test.log

# Save timestamp for pre-commit hook
date +%s > /tmp/shell_last_test_time
```

---

## Simulator Commands

### List All Simulators
```bash
xcrun simctl list devices
```

### List Booted Simulators
```bash
xcrun simctl list devices booted
```

### Boot Simulator
```bash
xcrun simctl boot "iPhone 17 Pro"
```

### Launch App
```bash
xcrun simctl launch booted com.adamcodertrader.Shell
```

### Terminate App
```bash
xcrun simctl terminate booted com.adamcodertrader.Shell
```

### Uninstall App
```bash
xcrun simctl uninstall booted com.adamcodertrader.Shell
```

### Get App Container Path
```bash
xcrun simctl get_app_container booted com.adamcodertrader.Shell
```

### Take Screenshot
```bash
xcrun simctl io booted screenshot /tmp/shell-screenshot.png
```

### Record Video
```bash
# Start recording
xcrun simctl io booted recordVideo /tmp/shell-video.mov

# Stop with Ctrl+C
```

### Reset Simulator
```bash
xcrun simctl erase booted
```

---

## Debugging Commands

### Show Build Settings
```bash
xcodebuild -showBuildSettings -scheme Shell
```

### Show Available Schemes
```bash
xcodebuild -list
```

### Show Available Destinations
```bash
xcodebuild -showdestinations -scheme Shell
```

### Derive Data Location
```bash
xcodebuild -showBuildSettings -scheme Shell | grep BUILD_DIR
```

---

## SwiftLint

### Lint All Files
```bash
swiftlint
```

### Lint Specific File
```bash
swiftlint --path Shell/Features/Dog/DogListViewModel.swift
```

### Auto-Fix Issues
```bash
swiftlint --fix
```

### Auto-Fix Specific File
```bash
swiftlint --fix --path Shell/Features/Dog/DogListViewModel.swift
```

---

## Common Destinations

### iPhone Simulators
```bash
# iPhone 17 Pro
'platform=iOS Simulator,name=iPhone 17 Pro'

# iPhone 17
'platform=iOS Simulator,name=iPhone 17'

# iPhone SE (3rd generation)
'platform=iOS Simulator,name=iPhone SE (3rd generation)'
```

### iPad Simulators
```bash
# iPad Pro 12.9-inch
'platform=iOS Simulator,name=iPad Pro (12.9-inch) (7th generation)'

# iPad Air
'platform=iOS Simulator,name=iPad Air (5th generation)'
```

---

## Verification Workflow

### Complete Build + Test + Launch
```bash
# 1. Build
xcodebuild build -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 2. Test
xcodebuild test -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -skip-testing:ShellUITests 2>&1 | tee /tmp/shell_last_test.log

# 3. Save timestamp
date +%s > /tmp/shell_last_test_time

# 4. Verify
grep -F "** TEST SUCCEEDED **" /tmp/shell_last_test.log && echo $?

# 5. Launch
xcrun simctl launch booted com.adamcodertrader.Shell

# 6. Screenshot
xcrun simctl io booted screenshot /tmp/shell-verify.png
```

---

## Troubleshooting

### Simulator Not Booting
```bash
# Check available devices
xcrun simctl list devices

# Boot specific device
xcrun simctl boot "<Device ID>"

# Or by name
xcrun simctl boot "iPhone 17 Pro"
```

### App Not Installing
```bash
# Clean build folder
xcodebuild clean -scheme Shell

# Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Rebuild
xcodebuild build -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Tests Not Found
```bash
# Check if test target is built
xcodebuild build-for-testing -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Then run tests
xcodebuild test-without-building -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

---

## Performance Tips

### Build Faster
```bash
# Use build-for-testing for repeated test runs
xcodebuild build-for-testing -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# Then run tests multiple times without rebuilding
xcodebuild test-without-building -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

### Parallel Testing
```bash
# Run tests in parallel (faster)
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled YES
```

---

**Key Principle**: Verify everything. Never assume builds or tests passed.
