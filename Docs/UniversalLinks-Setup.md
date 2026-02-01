# Universal Links Setup Guide

## Overview

This guide walks through setting up Universal Links for the Shell iOS app, enabling seamless web-to-app navigation.

## Prerequisites

- Apple Developer account access
- Domain with HTTPS hosting (e.g., shell.app)
- Xcode with project access

## Step 1: Apple Developer Portal Configuration

### Enable Associated Domains Capability

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers** → Your App ID (matches bundle identifier: `com.adamcodertrader.Shell`)
4. Go to **Capabilities** tab
5. Find **Associated Domains** and check the box to enable it
6. Click **Save**

### Regenerate Provisioning Profiles

**CRITICAL:** After enabling Associated Domains, you MUST regenerate all provisioning profiles:

1. Go to **Profiles** section
2. Select each profile (Development, Distribution, Ad Hoc)
3. Click **Edit** → **Save**
4. Download the updated profile
5. Double-click to install in Xcode

**Why?** iOS only recognizes the Associated Domains entitlement when profiles include it.

## Step 2: Host AASA File

### Get Your Team ID

1. Go to [Apple Developer Account](https://developer.apple.com/account)
2. Find your **Team ID** in the top right (10-character string)
3. Update `apple-app-site-association.json` with your Team ID:
   ```json
   "appIDs": ["YOUR_TEAM_ID.com.adamcodertrader.Shell"]
   ```

### Host the AASA File

Host the `apple-app-site-association` file (no .json extension) at:

**Primary location (required):**
```
https://shell.app/.well-known/apple-app-site-association
```

**Fallback location (optional):**
```
https://shell.app/apple-app-site-association
```

### Server Requirements

- ✅ **HTTPS only** (no HTTP)
- ✅ **Content-Type:** `application/json`
- ✅ **No file extension** on the file
- ✅ **No redirects**
- ✅ **Publicly accessible** (no authentication required)
- ✅ **No caching** (or very short cache time during testing)

### Example Nginx Configuration

```nginx
location /.well-known/apple-app-site-association {
    default_type application/json;
    add_header Cache-Control "no-cache";
    alias /var/www/shell.app/apple-app-site-association;
}
```

### Validate AASA File

Use Apple's official validator:
- [Apple Search Validation Tool](https://search.developer.apple.com/appsearch-validation-tool/)

Enter your domain: `shell.app`

Or use Branch's validator:
- [Branch AASA Validator](https://branch.io/resources/aasa-validator/)

## Step 3: Configure Xcode

### Add Associated Domains Capability

1. Open `Shell.xcodeproj` in Xcode
2. Select the **Shell** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability**
5. Search for and add **Associated Domains**
6. Under Domains, click **+** and add:
   ```
   applinks:shell.app
   ```

### For Multiple Environments

If you have staging/dev environments:
```
applinks:shell.app
applinks:staging.shell.app
applinks:dev.shell.app
```

### Verify Entitlements File

Check that `Shell.entitlements` was created with:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:shell.app</string>
</array>
```

## Step 4: Delete and Reinstall App

**CRITICAL:** iOS only updates Universal Link permissions on fresh install.

1. Delete the Shell app from your device/simulator
2. Clean build folder: Product → Clean Build Folder (⇧⌘K)
3. Build and run the app fresh
4. Wait 24 hours for AASA to propagate through Apple's CDN (first time only)

## Testing Universal Links

### What DOESN'T Work

Universal Links will **NOT** work if:
- ❌ Clicked directly in Safari address bar
- ❌ Pasted into Safari
- ❌ Tapped after redirect from another domain
- ❌ Using HTTP (must be HTTPS)

### What DOES Work

Universal Links work when:
- ✅ Tapped in **Messages** (iMessage)
- ✅ Tapped in **Mail**
- ✅ Tapped in **Notes**
- ✅ Tapped from another app (Twitter, Slack, etc.)
- ✅ Tapped from Safari **after** visiting a different domain first

### Test Links

Send these links via Messages to test:

```
https://shell.app/
https://shell.app/profile/user123
https://shell.app/settings
https://shell.app/settings/account
https://shell.app/identity
https://shell.app/identity/screenname
```

These should **NOT** open the app (excluded):
```
https://shell.app/login
https://shell.app/signup
https://shell.app/logout
https://shell.app/forgot-password
```

### Simulator Testing

Use terminal command to test:

```bash
# Test profile link
xcrun simctl openurl booted "https://shell.app/profile/user123"

# Test settings link
xcrun simctl openurl booted "https://shell.app/settings/account"

# Test home link
xcrun simctl openurl booted "https://shell.app/"
```

### Debug Console

Check Console.app for Universal Link debug messages:

1. Open Console.app
2. Connect your device
3. Filter for: `swcd` or `com.apple.duetexpertd`
4. Tap a Universal Link
5. Look for AASA download and validation logs

## Expected User Flow

### Authenticated User Taps Link

```
User taps: https://shell.app/profile/user123
    ↓
iOS checks AASA file on shell.app
    ↓
Launches Shell app (not Safari)
    ↓
SceneDelegate receives URL
    ↓
AppCoordinator parses to .profile(userID: "user123")
    ↓
AuthGuard checks authentication → Allowed
    ↓
User sees profile screen
```

### Unauthenticated User Taps Link

```
User taps: https://shell.app/settings/privacy
    ↓
iOS launches Shell app
    ↓
SceneDelegate receives URL
    ↓
AppCoordinator parses to .settings(section: .privacy)
    ↓
AuthGuard checks authentication → Denied
    ↓
AppCoordinator saves pending route
    ↓
User sees login screen
    ↓
User logs in successfully
    ↓
AppCoordinator restores .settings(section: .privacy)
    ↓
User sees privacy settings
```

## Troubleshooting

### Links Open in Safari Instead of App

1. **Delete and reinstall app** - iOS caches Universal Link associations
2. **Check AASA file is accessible** - Visit `https://shell.app/.well-known/apple-app-site-association` in browser
3. **Verify Team ID** - Must match exactly in AASA file
4. **Regenerate provisioning profiles** - After enabling Associated Domains
5. **Wait 24 hours** - First-time AASA propagation through Apple's CDN
6. **Test from Messages, not Safari** - Safari address bar doesn't trigger Universal Links

### AASA File Not Found

1. **Check file location** - Must be exactly `/.well-known/apple-app-site-association`
2. **No file extension** - File should NOT have `.json` extension
3. **HTTPS required** - HTTP will fail
4. **Content-Type header** - Must be `application/json`
5. **No redirects** - Direct access only

### App Doesn't Handle URL

1. **Check SceneDelegate** - Verify `scene(_:continue:)` is implemented
2. **Check AppDelegate** - Verify Universal Link handler exists
3. **Check logs** - Look for "🔗 Universal Link" debug messages
4. **Verify route parsing** - Check URL → Route conversion logic

## Production Checklist

Before deploying to production:

- [ ] Team ID updated in AASA file
- [ ] AASA file hosted at production domain
- [ ] AASA file validates with Apple's tool
- [ ] Associated Domains capability enabled in Developer Portal
- [ ] Provisioning profiles regenerated and downloaded
- [ ] Associated Domains configured in Xcode
- [ ] Entitlements file includes correct domains
- [ ] App tested with real Universal Links from Messages
- [ ] Unauthenticated flow tested (link → login → original destination)
- [ ] Authenticated flow tested (link → direct navigation)
- [ ] Excluded paths (login, signup) tested to stay in Safari

## Support

- Apple's Official Guide: [Supporting Universal Links](https://developer.apple.com/documentation/xcode/allowing-apps-and-websites-to-link-to-your-content)
- AASA Format Spec: [Apple App Site Association](https://developer.apple.com/documentation/bundleresources/applinks)
- Debug Tool: [Apple's AASA Validator](https://search.developer.apple.com/appsearch-validation-tool/)
