# Auth Integration Tests - README

## Overview

These tests verify the complete authentication flow between the iOS app and Node.js backend.

---

## Prerequisites

### 1. Start Backend

```bash
cd backend
docker compose up -d
```

**Verify backend is running:**
```bash
curl http://localhost:3000/health
# Expected: {"status":"healthy","database":"connected"}
```

### 2. Run Backend Tests (Optional)

```bash
cd backend
./test-auth.sh
```

This verifies:
- Registration works
- Login returns tokens
- Token refresh with rotation
- Reuse detection
- Logout invalidates sessions

---

## Running iOS Integration Tests

### Option 1: Run All Integration Tests

```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/AuthIntegrationTests
```

### Option 2: Run Specific Test

```bash
xcodebuild test \
  -scheme Shell \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:ShellTests/AuthIntegrationTests/testLoginFlow_withValidCredentials_savesSessionToKeychain
```

### Option 3: Run from Xcode

1. Open `Shell.xcodeproj`
2. Navigate to `ShellTests/Integration/AuthIntegrationTests.swift`
3. Click the diamond icon next to any test method
4. Or: `Cmd+U` to run all tests

---

## Test Coverage

### Test 1: Login Flow ✅
**File:** `testLoginFlow_withValidCredentials_savesSessionToKeychain()`
**Verifies:**
- iOS can authenticate with backend
- Tokens are saved to Keychain
- Session is valid after login

**File:** `testLoginFlow_withInvalidCredentials_throwsError()`
**Verifies:**
- Invalid credentials rejected
- No session saved on failure

### Test 2: Token Refresh ✅
**File:** `testTokenRefresh_withValidRefreshToken_returnsNewTokens()`
**Verifies:**
- Refresh endpoint rotates tokens
- New tokens saved to Keychain
- Old tokens are different from new tokens

**File:** `testTokenRefresh_withOldRefreshToken_fails()`
**Verifies:**
- Reuse detection works
- Old refresh token rejected
- Session cleared on security breach

### Test 3: Logout ✅
**File:** `testLogout_clearsKeychainAndBackendSession()`
**Verifies:**
- Logout clears Keychain
- Backend session invalidated
- Old tokens no longer work

### Test 4: Protected Routes ✅
**File:** `testProtectedRoute_withoutToken_returns401()`
**Verifies:**
- Protected routes require authentication
- 401 returned without token

**File:** `testProtectedRoute_withValidToken_succeeds()`
**Verifies:**
- Valid token grants access
- Protected routes return 200

### Test 5: Rate Limiting ✅
**File:** `testRateLimit_after5FailedAttempts_blocksLogin()`
**Verifies:**
- 5 failed attempts trigger rate limit
- 6th attempt blocked
- Backend rate limiting works

### Test 6: Concurrent Requests ✅
**File:** `testConcurrentLogin_onlyOneSucceeds()`
**Verifies:**
- Concurrent login attempts handled
- Backend allows multiple sessions per user
- No race conditions

### Test 7: Session Persistence ✅
**File:** `testSessionPersistence_acrossAppRestarts()`
**Verifies:**
- Session persists in Keychain
- App restart retrieves session
- Tokens still valid after restart

---

## Test Data

**Test User:**
- Email: `integration-test@example.com`
- Password: `Test123!@#`

The tests automatically register this user if it doesn't exist.

---

## Troubleshooting

### Error: "Backend is not running"

**Solution:**
```bash
cd backend
docker compose up -d
curl http://localhost:3000/health
```

### Error: "Connection refused"

**Check:**
1. Docker Desktop is running
2. Backend containers are up: `docker compose ps`
3. Port 3000 is not in use: `lsof -i :3000`

**Restart:**
```bash
docker compose down
docker compose up -d
```

### Error: "Database connection failed"

**Solution:**
```bash
# Check database logs
docker compose logs postgres

# Restart database
docker compose restart postgres
```

### Test Fails: "Rate limit exceeded"

**Solution:**
Wait 15 minutes or restart Redis:
```bash
docker compose restart redis
```

### Test Fails: "Session not found"

**Clear Keychain:**
```swift
// In test setUp()
try await sessionRepository.clearSession()
```

Or delete Simulator:
```bash
xcrun simctl erase all
```

---

## Performance Benchmarks

| Test | Expected Duration | Network Calls |
|------|------------------|---------------|
| Login Flow | ~1-2 seconds | 2 (register + login) |
| Token Refresh | ~500ms | 1 (refresh) |
| Logout | ~500ms | 1 (logout) |
| Protected Route | ~200ms | 1 (GET /items) |
| Rate Limiting | ~5 seconds | 6 (5 failed + 1 blocked) |
| Concurrent Login | ~2 seconds | 3 (parallel) |
| Session Persistence | <100ms | 0 (Keychain only) |

**Total Test Suite**: ~15-20 seconds

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Integration Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v3

      - name: Start Backend
        run: |
          cd backend
          docker compose up -d
          sleep 10  # Wait for services to be ready
          curl --retry 5 --retry-delay 2 http://localhost:3000/health

      - name: Run Integration Tests
        run: |
          xcodebuild test \
            -scheme Shell \
            -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
            -only-testing:ShellTests/AuthIntegrationTests

      - name: Stop Backend
        if: always()
        run: |
          cd backend
          docker compose down
```

---

## Manual Testing Checklist

### 1. Login Flow
- [ ] Start backend: `docker compose up -d`
- [ ] Run iOS Simulator
- [ ] Enter credentials
- [ ] Login → Backend authenticates
- [ ] Check Keychain: tokens saved
- [ ] Navigate to main app

### 2. Token Expiry
- [ ] Login successfully
- [ ] Wait 15 minutes (access token expires)
- [ ] Make API call → Auto-refresh
- [ ] Request succeeds with new token

### 3. Logout
- [ ] Login successfully
- [ ] Logout
- [ ] Check Keychain: tokens cleared
- [ ] Try API call → 401 Unauthorized

### 4. Invalid Credentials
- [ ] Enter wrong email/password
- [ ] Login fails
- [ ] Error message displayed
- [ ] No tokens saved

### 5. Rate Limiting
- [ ] Attempt 5 failed logins
- [ ] 6th attempt blocked
- [ ] Wait 15 minutes or restart Redis
- [ ] Can login again

---

## Debugging Tips

### Enable Backend Logs

```bash
docker compose logs -f backend
```

### Check Database

```bash
docker compose exec postgres psql -U shell -d shell_db

# Check users
SELECT * FROM users;

# Check sessions
SELECT * FROM sessions;

# Check auth logs
SELECT * FROM auth_logs ORDER BY created_at DESC LIMIT 10;
```

### Check Redis

```bash
docker compose exec redis redis-cli

# Check rate limit keys
KEYS *rate-limit*

# Check token blacklist
KEYS *token-blacklist*
```

### Inspect Keychain (Simulator)

```bash
# Find Simulator data
xcrun simctl get_app_container booted com.adamcodertrader.Shell data

# Keychain is in Library/Keychains/
# Cannot be read directly (encrypted)
```

### Network Debugging

Use Charles Proxy or Proxyman to inspect HTTP traffic:
1. Configure Simulator proxy
2. Install SSL certificate
3. Monitor `/auth/*` endpoints

---

## Security Notes

1. **Test Credentials**: Only use `integration-test@example.com` for testing
2. **Clean Up**: Tests automatically clear sessions in `tearDown()`
3. **Rate Limiting**: Tests may trigger rate limits (wait 15 min)
4. **Token Reuse**: Test 2 deliberately tries to reuse tokens (security test)

---

## Expected Results

All 7 tests should pass when backend is running:

```
Test Suite 'AuthIntegrationTests' passed
    testLoginFlow_withValidCredentials_savesSessionToKeychain (1.2 seconds)
    testLoginFlow_withInvalidCredentials_throwsError (0.8 seconds)
    testTokenRefresh_withValidRefreshToken_returnsNewTokens (1.5 seconds)
    testTokenRefresh_withOldRefreshToken_fails (1.0 seconds)
    testLogout_clearsKeychainAndBackendSession (1.0 seconds)
    testProtectedRoute_withoutToken_returns401 (0.3 seconds)
    testProtectedRoute_withValidToken_succeeds (0.5 seconds)
    testRateLimit_after5FailedAttempts_blocksLogin (5.2 seconds)
    testConcurrentLogin_onlyOneSucceeds (2.0 seconds)
    testSessionPersistence_acrossAppRestarts (0.1 seconds)

Test Suite 'AuthIntegrationTests' passed (15.6 seconds)
```

---

**Last Updated**: 2026-02-14
**Backend Version**: 1.0.0
**iOS Version**: 26.2+
