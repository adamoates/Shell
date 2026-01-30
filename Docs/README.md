# Test Documentation

This directory contains documentation for each expert test area. Each test branch adds its own `Test-XX.md` file.

## Documentation Structure

Each test doc should include:

### 1. Overview
- What skill area is being tested
- What was built
- Why this demonstrates the skill

### 2. Implementation Details
- Key files and their purpose
- Architecture decisions
- Technical approach

### 3. Running the Test
- How to build and run
- How to execute tests
- How to verify functionality

### 4. Pass Criteria
- Specific, measurable success criteria
- How to verify each criterion
- Expected outcomes

### 5. Key Demonstrations
- List of specific skills demonstrated
- Code locations for each demonstration
- Why each matters

### 6. Screenshots (optional)
- UI screenshots
- Instruments screenshots
- Test results

## Test Documentation Index

When test branches are created, they will add:

- `Test-01.md` - Storyboard UI/UX (branch: test/01-storyboard-ui)
- `Test-02.md` - Swift Language (branch: test/02-swift-language)
- `Test-03.md` - Architecture MVVM+Coordinator (branch: test/03-architecture-mvvm-coordinator)
- `Test-04.md` - UIKit Programmatic (branch: test/04-uikit-programmatic)
- `Test-05.md` - SwiftUI Foundations (branch: test/05-swiftui-foundations)
- `Test-06.md` - SwiftUI Advanced (branch: test/06-swiftui-advanced)
- `Test-07.md` - Testing XCTest (branch: test/07-testing-xctest)
- `Test-08.md` - Networking (branch: test/08-networking)
- `Test-09.md` - Core Data (branch: test/09-coredata)
- `Test-10.md` - Performance (branch: test/10-performance)
- `Test-11.md` - Security (branch: test/11-security)
- `Test-12.md` - Debugging (branch: test/12-debugging)

## Template

```markdown
# Test XX: [Test Name]

## Overview
**Expert Area**: [Area name]
**Branch**: `test/XX-branch-name`
**Status**: ✅ Complete / 🚧 In Progress

[Brief description of what was built and why]

## What Was Built
- Feature 1
- Feature 2
- Feature 3

## Implementation Details

### Architecture
[Explain the architecture and design decisions]

### Key Files
- `Path/To/File.swift` - Description
- `Path/To/Another.swift` - Description

### Technical Approach
[Explain the technical implementation]

## Running the Test

### Prerequisites
- Xcode 15.0+
- iOS 16.0+

### Steps
1. Checkout the branch: `git checkout test/XX-branch-name`
2. Open `Shell.xcodeproj`
3. [Additional steps]

### Running Tests
\`\`\`bash
xcodebuild test -project Shell.xcodeproj -scheme Shell -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
\`\`\`

## Pass Criteria

### Criterion 1: [Name]
- [ ] Requirement 1
- [ ] Requirement 2

**How to verify**: [Specific steps]

### Criterion 2: [Name]
- [ ] Requirement 1
- [ ] Requirement 2

**How to verify**: [Specific steps]

## Key Demonstrations

### 1. [Skill/Pattern Name]
**Location**: `Path/To/File.swift:123`
**Demonstrates**: [What this shows]
**Why it matters**: [Importance]

### 2. [Skill/Pattern Name]
**Location**: `Path/To/File.swift:456`
**Demonstrates**: [What this shows]
**Why it matters**: [Importance]

## Notes
[Any additional notes, gotchas, or learnings]

## References
- [Link to Apple docs]
- [Link to WWDC video]
- [Link to relevant resources]
```
