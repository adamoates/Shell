---
name: simulator
description: Commands to boot, install, and interact with the iOS Simulator.
disable-model-invocation: false
---

# iOS Simulator Skill

Use this skill to manage the app lifecycle and verify UI changes on the iPhone 17 Pro.

## Core Commands
- **Boot Device:** `xcrun simctl boot "iPhone 17 Pro"`
- **Install App:** `xcrun simctl install booted <path_to_app_bundle>`
- **Launch App:** `xcrun simctl launch booted <bundle_id>`
- **Screenshot:** `xcrun simctl io booted screenshot ./DerivedData/current_ui.png`

## Workflow for UI Verification
1. Build the app using `xcodebuild` with the `-destination` set to 'platform=iOS Simulator,name=iPhone 17 Pro'.
2. Use this skill to install and launch the app.
3. Take a screenshot and describe the visual layout to the Human Lead for final approval.

## Common Workflows

### Full Build-Install-Launch-Screenshot Flow

```bash
# 1. Boot the simulator (if not already booted)
xcrun simctl boot "iPhone 17 Pro" 2>/dev/null || echo "Simulator already booted"

# 2. Build the app for simulator
xcodebuild \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath ./DerivedData \
  build

# 3. Find the built app bundle
APP_BUNDLE=$(find ./DerivedData/Build/Products -name "Shell.app" | head -1)

# 4. Install the app
xcrun simctl install booted "$APP_BUNDLE"

# 5. Launch the app
xcrun simctl launch booted com.shell.Shell

# 6. Wait for app to render (adjust timing as needed)
sleep 2

# 7. Take screenshot
xcrun simctl io booted screenshot ./DerivedData/current_ui.png

# 8. Display success message
echo "✅ Screenshot saved to ./DerivedData/current_ui.png"
```

### Quick Reinstall (After Code Changes)

Use this when you've made code changes and want to quickly verify in simulator:

```bash
# Build and install in one flow
xcodebuild \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath ./DerivedData \
  build && \
xcrun simctl install booted "$(find ./DerivedData/Build/Products -name 'Shell.app' | head -1)" && \
xcrun simctl launch booted com.shell.Shell
```

### Screenshot Only (App Already Running)

```bash
xcrun simctl io booted screenshot ./DerivedData/ui_$(date +%Y%m%d_%H%M%S).png
```

### Record Video

```bash
# Start recording
xcrun simctl io booted recordVideo ./DerivedData/demo.mp4 &
RECORDING_PID=$!

# ... interact with the app ...

# Stop recording
kill -SIGINT $RECORDING_PID
```

## Device Management

### List Available Simulators

```bash
xcrun simctl list devices available
```

### Check If iPhone 17 Pro Is Booted

```bash
xcrun simctl list devices | grep "iPhone 17 Pro" | grep "Booted"
```

### Shutdown Simulator

```bash
xcrun simctl shutdown "iPhone 17 Pro"
```

### Erase Simulator (Reset to Factory State)

```bash
xcrun simctl erase "iPhone 17 Pro"
```

## App Management

### Uninstall App

```bash
xcrun simctl uninstall booted com.shell.Shell
```

### List Installed Apps

```bash
xcrun simctl listapps booted
```

### Terminate Running App

```bash
xcrun simctl terminate booted com.shell.Shell
```

## UI Verification Checklist

When taking screenshots for visual verification, check:

- ✅ **Layout:** Are UI elements positioned correctly?
- ✅ **Safe Areas:** Does content respect notch/home indicator?
- ✅ **Spacing:** Are margins and padding consistent?
- ✅ **Text:** Is all text readable at the default size?
- ✅ **Colors:** Do colors match the design system?
- ✅ **Dark Mode:** Does the UI adapt correctly? (Test with both appearances)
- ✅ **Accessibility:** Are touch targets at least 44x44 points?

## Debugging Tips

### View Console Logs

```bash
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Shell"' --level debug
```

### Check App Container Path

```bash
xcrun simctl get_app_container booted com.shell.Shell
```

### Open App Data Directory in Finder

```bash
open "$(xcrun simctl get_app_container booted com.shell.Shell data)"
```

## Integration with Other Skills

### After Using `/new-feature`

1. Build the app
2. Install and launch in simulator
3. Take screenshot to verify the new UI is rendering
4. Report visual issues back to the Human Lead

### Before Using `/commit`

1. Build and launch app
2. Take screenshot of affected screens
3. Verify UI changes match requirements
4. Include screenshot path in commit message if applicable

### During `/test-feature`

1. Run unit tests first
2. If tests pass, deploy to simulator for manual verification
3. Take screenshots of critical user flows
4. Report both test results and visual confirmation

## Notes

- The iPhone 17 Pro simulator matches the device specified in test-feature.md
- Screenshots are saved to `./DerivedData/` to avoid cluttering the repository
- Always verify the simulator is booted before attempting install/launch operations
- Use `xcrun simctl` (not `xcrun instruments`) for programmatic control
- Bundle ID is `com.shell.Shell` (check Info.plist if this changes)
