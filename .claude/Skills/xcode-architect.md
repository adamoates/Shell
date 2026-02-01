# Xcode Architect Skill

Manage Xcode project structure, validate .xcodeproj integrity, and prevent build configuration issues.

## When to use

- After adding/moving/deleting files in the project.
- Before committing changes that affect project structure.
- When build errors mention missing files or target membership.
- After scaffolding new features with `/new-feature`.
- When refactoring module organization.

## Core Responsibilities

1. **Project File Integrity** - Ensure .xcodeproj XML references match filesystem
2. **Target Membership** - Verify files are in correct targets (Shell vs ShellTests)
3. **Build Configuration** - Validate schemes, settings, and dependencies
4. **Circular Dependencies** - Detect import cycles that cause build failures
5. **Modernization Checks** - Suggest Swift 6 patterns over legacy code

## Workflows

### 1. File Structure Validation

After adding new files (manually or via `/new-feature`), verify they're properly integrated:

```bash
# List all Swift files in the project directory
find Shell -name "*.swift" -type f | sort > /tmp/filesystem_files.txt

# Extract file references from .xcodeproj
# (This requires parsing the project.pbxproj file)
grep -E "\.swift|path = " Shell.xcodeproj/project.pbxproj | \
  grep "\.swift" | \
  sed 's/.*path = \(.*\);/\1/' | \
  sort > /tmp/xcodeproj_files.txt

# Compare: files on disk vs files in Xcode project
diff /tmp/filesystem_files.txt /tmp/xcodeproj_files.txt
```

**Interpretation:**
- Lines starting with `<` = Files exist on disk but NOT in Xcode project (orphaned)
- Lines starting with `>` = Files referenced in Xcode but NOT on disk (broken references)

**Fix:**
- Orphaned files: Open Xcode → Right-click target → "Add Files to Shell..."
- Broken references: Remove red references from Xcode project navigator

### 2. Target Membership Validation

Ensure files are in the correct target:

```bash
# Check if a specific file is in the Shell target
xcodebuild -project Shell.xcodeproj \
  -target Shell \
  -showBuildSettings | \
  grep PRODUCT_BUNDLE_IDENTIFIER

# List all files in Shell target (requires xcodebuild -list)
xcodebuild -project Shell.xcodeproj \
  -target Shell \
  -showBuildSettings | \
  grep "SWIFT_SOURCES"
```

**Expected Target Membership:**

| File Location | Target | Reason |
|---------------|--------|--------|
| `Shell/Features/**/*.swift` | Shell (app) | Application code |
| `Shell/Core/**/*.swift` | Shell (app) | Core infrastructure |
| `Shell/App/**/*.swift` | Shell (app) | App lifecycle |
| `ShellTests/**/*.swift` | ShellTests | Unit tests |
| `ShellUITests/**/*.swift` | ShellUITests | UI tests (if exists) |

**Common Violations:**
- ❌ Test files accidentally added to Shell target (bloats app bundle)
- ❌ App files added to test target (causes compilation errors)
- ❌ Files added to multiple targets (causes duplicate symbol errors)

### 3. Build Configuration Audit

Verify project build settings are consistent:

```bash
# Check scheme list
xcodebuild -project Shell.xcodeproj -list

# Show build settings for Shell target
xcodebuild -project Shell.xcodeproj \
  -target Shell \
  -configuration Debug \
  -showBuildSettings | \
  grep -E "SWIFT_VERSION|IPHONEOS_DEPLOYMENT_TARGET|PRODUCT_NAME"

# Expected output:
#   SWIFT_VERSION = 6.0
#   IPHONEOS_DEPLOYMENT_TARGET = 17.0
#   PRODUCT_NAME = Shell
```

**Critical Build Settings to Verify:**

```bash
# Swift 6 Strict Concurrency
xcodebuild -showBuildSettings | grep SWIFT_STRICT_CONCURRENCY
# Should be: SWIFT_STRICT_CONCURRENCY = complete

# Optimization Level
xcodebuild -showBuildSettings | grep SWIFT_OPTIMIZATION_LEVEL
# Debug: -Onone
# Release: -O

# Enable Testability (Debug only)
xcodebuild -showBuildSettings | grep ENABLE_TESTABILITY
# Debug: YES
# Release: NO
```

### 4. Circular Dependency Detection

Detect import cycles that cause "circular dependency" build errors:

```bash
# Create dependency graph
echo "digraph dependencies {" > /tmp/deps.dot

# Extract imports from all Swift files
find Shell -name "*.swift" -exec sh -c '
  FILE=$1
  MODULE=$(echo $FILE | cut -d/ -f2)
  grep "^import " $FILE | while read -r line; do
    IMPORT=$(echo $line | awk "{print \$2}")
    echo "  \"$MODULE\" -> \"$IMPORT\";"
  done
' _ {} \; >> /tmp/deps.dot

echo "}" >> /tmp/deps.dot

# Check for cycles using basic grep (no graphviz needed)
echo "Checking for circular dependencies..."
grep -E "Features.*->.*Features" /tmp/deps.dot || echo "✅ No obvious feature-level cycles"
```

**Shell Architecture Rules:**
- ✅ Features can import Core (SwiftSDK, DI, Coordinators)
- ✅ Core can import Foundation/UIKit/SwiftUI
- ❌ Features MUST NOT import other Features
- ❌ Core MUST NOT import Features

**Example Violation:**
```swift
// Shell/Features/Items/Domain/Item.swift
import Foundation
import Profile  // ❌ Features importing Features = circular dependency
```

**Fix:**
- Move shared types to `Shell/Core/SharedModels/`
- Use dependency injection to break coupling
- Refactor to use protocols instead of concrete types

### 5. Swift Concurrency Modernization Check

Scan for legacy patterns that should use Swift 6 concurrency:

```bash
# Find completion handler patterns
grep -rn "completion: @escaping" Shell/ --include="*.swift"

# Find DispatchQueue.main.async patterns
grep -rn "DispatchQueue.main.async" Shell/ --include="*.swift"

# Find delegate patterns that could be async
grep -rn "protocol.*Delegate" Shell/ --include="*.swift"
```

**Modernization Recommendations:**

| Legacy Pattern | Modern Swift 6 Pattern |
|----------------|------------------------|
| `func fetch(completion: @escaping (Result<Data, Error>) -> Void)` | `func fetch() async throws -> Data` |
| `DispatchQueue.main.async { self.update() }` | `@MainActor func update()` |
| `class MyViewModel { }` (no isolation) | `@MainActor final class MyViewModel` |
| `final class Repository { }` (mutable state) | `actor Repository { }` |
| `var delegate: MyDelegate?` | `async func operation() -> Result` |

### 6. Build Integrity Check

Run a clean build to verify project compiles:

```bash
# Clean build folder
xcodebuild clean \
  -project Shell.xcodeproj \
  -scheme Shell

# Build for simulator (fast validation)
xcodebuild build \
  -project Shell.xcodeproj \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -quiet

# Check exit code
if [ $? -eq 0 ]; then
  echo "✅ Build succeeded"
else
  echo "❌ Build failed - check errors above"
  exit 1
fi
```

**With xcpretty (if installed):**

```bash
# Install xcpretty for readable output
# gem install xcpretty

xcodebuild build \
  -project Shell.xcodeproj \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' | \
  xcpretty --color
```

### 7. Project Structure Report

Generate a comprehensive project health report:

```bash
echo "📊 Xcode Project Health Report"
echo "================================"
echo ""

echo "📁 Project Structure:"
find Shell -type d -maxdepth 2 | sort

echo ""
echo "📄 File Counts:"
echo "  Swift files: $(find Shell -name "*.swift" | wc -l)"
echo "  Test files: $(find ShellTests -name "*.swift" | wc -l)"
echo "  Storyboards: $(find Shell -name "*.storyboard" | wc -l)"

echo ""
echo "🎯 Targets:"
xcodebuild -project Shell.xcodeproj -list | grep -A 10 "Targets:"

echo ""
echo "⚙️  Build Settings:"
xcodebuild -showBuildSettings -project Shell.xcodeproj -target Shell | \
  grep -E "SWIFT_VERSION|IPHONEOS_DEPLOYMENT_TARGET|PRODUCT_BUNDLE_IDENTIFIER"

echo ""
echo "🔍 Potential Issues:"
# Check for missing files
ORPHANED=$(find Shell -name "*.swift" -type f | wc -l)
echo "  Files to audit: $ORPHANED"

# Check for legacy patterns
COMPLETIONS=$(grep -r "completion: @escaping" Shell --include="*.swift" | wc -l)
if [ $COMPLETIONS -gt 0 ]; then
  echo "  ⚠️  Found $COMPLETIONS completion handler patterns (consider async/await)"
fi

DISPATCH=$(grep -r "DispatchQueue.main.async" Shell --include="*.swift" | wc -l)
if [ $DISPATCH -gt 0 ]; then
  echo "  ⚠️  Found $DISPATCH DispatchQueue patterns (consider @MainActor)"
fi

echo ""
echo "✅ Validation Complete"
```

## Integration with Other Skills

### After `/new-feature`

```bash
# 1. Scaffold new feature
/new-feature VideoPlayer

# 2. Validate Xcode project integrity
/xcode-architect

# 3. Fix any orphaned files
# (Add files to Xcode via drag-drop or File → Add Files)

# 4. Verify build succeeds
xcodebuild -scheme Shell build
```

### Before `/commit`

```bash
# 1. Check for architectural violations
/mvvm-enforcer

# 2. Validate project structure
/xcode-architect

# 3. Run tests
/test-feature All

# 4. Commit if clean
/commit
```

### After Major Refactoring

```bash
# 1. Run full project audit
/xcode-architect

# 2. Check for circular dependencies
# (Review dependency graph output)

# 3. Modernize legacy patterns
# (Review completion handler / DispatchQueue findings)

# 4. Verify build
xcodebuild clean build
```

## Common Issues and Fixes

### Issue: "No such module 'Profile'" error

**Cause:** Features importing other features (circular dependency).

**Fix:**
```bash
# Find the violation
grep -rn "import Profile" Shell/Features/Items/
# Output: Shell/Features/Items/Domain/Item.swift:3:import Profile

# Remove the import and refactor to use protocols
```

### Issue: File appears red in Xcode

**Cause:** File exists in .xcodeproj but not on filesystem.

**Fix:**
```bash
# Find broken references
grep -E "path = .*\.swift" Shell.xcodeproj/project.pbxproj | \
  while read line; do
    FILE=$(echo $line | sed 's/.*path = \(.*\);/\1/')
    if [ ! -f "Shell/$FILE" ]; then
      echo "❌ Missing: $FILE"
    fi
  done

# Remove broken references manually in Xcode
```

### Issue: "Duplicate symbol" error

**Cause:** File added to multiple targets.

**Fix:**
```bash
# Open Xcode
# Select the file in Project Navigator
# Check File Inspector (⌘⌥1)
# Verify only ONE target is checked under "Target Membership"
```

### Issue: Build succeeds in Xcode but fails in terminal

**Cause:** Different derived data paths or scheme settings.

**Fix:**
```bash
# Use same derived data path
xcodebuild \
  -project Shell.xcodeproj \
  -scheme Shell \
  -derivedDataPath ./DerivedData \
  build

# Or clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## Notes

- Always run `/xcode-architect` after moving files between directories
- The .xcodeproj file is XML—manual edits can corrupt the project
- Use Xcode's "Add Files" feature rather than editing .pbxproj directly
- Circular dependencies between features violate Clean Architecture
- Swift 6 strict concurrency requires explicit actor annotations
- Keep build settings consistent between Debug and Release (except optimization)
- Run clean builds periodically to catch cached state issues

## Advanced: .xcodeproj Structure

The Shell.xcodeproj directory contains:

```
Shell.xcodeproj/
├── project.pbxproj          # Main project file (XML format)
├── project.xcworkspace/     # Workspace metadata
│   └── contents.xcworkspacedata
└── xcshareddata/
    └── xcschemes/
        └── Shell.xcscheme   # Build scheme definition
```

**Never manually edit these files unless you understand Xcode's internal format.**

Instead, use:
- Xcode GUI for file operations
- `xcodebuild` for build operations
- This skill for validation and auditing
