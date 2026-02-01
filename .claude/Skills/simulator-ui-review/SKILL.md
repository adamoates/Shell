---
name: simulator-ui-review
description: Capture a screenshot of the iOS Simulator and analyze the UI for layout issues, visual bugs, missing elements, and correctness. Use when debugging UI, verifying visual changes, testing layouts, or when the user asks what the screen looks like.
argument-hint: [focus-area-or-expected-state]
---

# Simulator UI Review

Capture and visually analyze the current state of the running iOS Simulator.

## Steps

### 1. Capture Screenshot

Find the booted simulator and take a screenshot:

```bash
# Get the booted device ID
DEVICE_ID=$(xcrun simctl list devices booted -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['state'] == 'Booted':
            print(d['udid'])
            sys.exit(0)
print('NONE')
")

if [ "$DEVICE_ID" = "NONE" ]; then
    echo "ERROR: No booted simulator found. Launch the app first."
    exit 1
fi

# Capture with timestamp for before/after comparisons
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCREENSHOT_PATH="/tmp/shell-simulator-${TIMESTAMP}.png"
xcrun simctl io booted screenshot "$SCREENSHOT_PATH"
echo "Screenshot saved: $SCREENSHOT_PATH"
```

### 2. View the Screenshot

Use the Read tool to open the screenshot file at the path printed above. Claude will see the image and can analyze it visually.

### 3. Analyze the UI

Check the screenshot against these criteria:

#### Layout & Structure
- Navigation bar present with correct title
- Content properly within safe area insets
- No overlapping elements
- Proper spacing and alignment
- Table/list cells evenly sized and aligned
- Scroll indicators visible when content overflows

#### Shell-Specific Elements
- Toolbar buttons present when expected ("Setup Identity", "View Profile")
- ErrorBannerView visible and properly positioned when errors occur
- Loading spinner centered and visible during async operations
- Empty state messaging when no data

#### Text & Typography
- No text truncation (check labels, buttons, cells)
- Font sizes readable
- Text contrast sufficient against background
- Dynamic Type support (text scales appropriately)

#### Interactive Elements
- Buttons visually distinct and tappable (minimum 44pt touch target)
- Text fields have clear borders/backgrounds
- Selected/highlighted states visible
- Disabled states visually distinct

#### Visual Quality
- No rendering artifacts
- Colors consistent with system appearance (light/dark)
- Images loaded (no placeholder or broken image indicators)
- Status bar readable

### 4. Report Findings

If `$ARGUMENTS` is provided, focus analysis on that area or compare against that expected state.

Report format:

```
## Simulator UI Review

### Screen: <identified screen name>
### Device: <simulator device>

### Issues Found

1. **[LAYOUT]** <description>
   - Location: <where on screen>
   - Fix: <suggested code change>

2. **[TEXT]** <description>
   - Location: <where on screen>
   - Fix: <suggested change>

### Looks Good
- <element that looks correct>
- <element that looks correct>

### Recommendations
- <optional improvement suggestions>
```

If no issues found, confirm the UI looks correct.

### 5. Before/After Comparison

When called multiple times in a session, compare the current screenshot against previous ones:

```bash
# List recent Shell simulator screenshots
ls -lt /tmp/shell-simulator-*.png | head -5
```

Use the Read tool on both the current and previous screenshot to describe what changed.

## Additional Commands

### Record Video (for animations/transitions)

```bash
# Start recording
xcrun simctl io booted recordVideo /tmp/shell-simulator-recording.mov

# Stop with Ctrl+C, then analyze key frames
```

### Capture Specific Window State

```bash
# Get app status
xcrun simctl get_app_container booted com.yourcompany.Shell

# Check if app is running
xcrun simctl launch --console-pty booted com.yourcompany.Shell 2>&1 | head -1
```

### Trigger Deep Link for Navigation

```bash
# Navigate to a specific screen before capturing
xcrun simctl openurl booted "shell://profile/user123"
sleep 1
xcrun simctl io booted screenshot "/tmp/shell-simulator-$(date +%Y%m%d_%H%M%S).png"
```
