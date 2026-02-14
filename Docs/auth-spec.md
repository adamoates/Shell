# Authentication System Specification: Shell App & Node Backend

**Version:** 1.0
**Last Updated:** 2026-02-14
**Status:** Implementation Pending

---

## 1. System Overview

### Architecture
- **Pattern:** OAuth 2.0 / OIDC-inspired Token Refresh Pattern
- **Client:** Shell iOS App (Swift 6, UIKit) - Acts as "Public Client"
- **Backend:** Node.js Express API (Docker container `backend`)
- **Data Store:** PostgreSQL (Users, Sessions) + Redis (Rate Limiting, Token Blacklist)

### Security Principles
1. **Defense in Depth:** Multiple layers of security (transport, storage, validation)
2. **Least Privilege:** Tokens expire quickly; refresh tokens rotated on use
3. **Zero Trust:** All requests validated; tokens can be revoked server-side
4. **Industry Standard:** Follows OAuth 2.0 RFC 6749 and OWASP best practices

---

## 2. Core Authentication Flows

### A. User Registration (Sign Up)
**Endpoint:** `POST /auth/register`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "confirmPassword": "SecurePass123!"
}
```

**Validation (Backend):**
- Email: Valid format, unique in database
- Password: Min 8 chars, 1 uppercase, 1 number, 1 special character
- Passwords match

**Security:**
- Hash password with **Argon2id** (iterations: 3, memory: 64MB, parallelism: 4)
- Store hashed password in `users` table
- NEVER store plaintext passwords

**Response (Success):**
```json
{
  "userID": "uuid-v4",
  "email": "user@example.com",
  "message": "Registration successful"
}
```

**Response (Error):**
```json
{
  "error": "validation_error",
  "field": "email",
  "message": "Email already registered"
}
```

---

### B. User Login
**Endpoint:** `POST /auth/login`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Backend Process:**
1. Lookup user by email
2. Verify password using Argon2id.verify()
3. Generate tokens:
   - **Access Token:** JWT, 15 min expiry, claims: `{userID, email, iat, exp}`
   - **Refresh Token:** Opaque UUID v4, 7 day expiry, stored in `sessions` table
4. Store session in PostgreSQL:
   ```sql
   INSERT INTO sessions (session_id, user_id, refresh_token_hash, expires_at, created_at)
   VALUES (uuid_generate_v4(), $userID, sha256($refreshToken), NOW() + INTERVAL '7 days', NOW())
   ```
5. Return tokens

**Response (Success):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "expiresIn": 900,
  "tokenType": "Bearer",
  "userID": "uuid"
}
```

**Security:**
- Rate limit: 5 login attempts per email per 15 minutes (Redis)
- Log failed attempts to `auth_logs` table
- Return generic "Invalid credentials" on failure (don't reveal if email exists)

---

### C. Token Refresh (Critical for Industry Standard)
**Endpoint:** `POST /auth/refresh`

**Request:**
```json
{
  "refreshToken": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Backend Process (Refresh Token Rotation):**
1. Hash incoming refresh token with SHA-256
2. Lookup session by `refresh_token_hash`
3. **If session not found OR expired:**
   - Return `401 Unauthorized`
4. **If session found and valid:**
   - Generate NEW access token (15 min expiry)
   - Generate NEW refresh token (7 days expiry)
   - **Invalidate old refresh token** (update `sessions` row)
   - Store new refresh token hash
   - Return new tokens
5. **Reuse Detection:** If old refresh token used again, invalidate ALL sessions for that user

**Response (Success):**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "new-uuid-v4-token",
  "expiresIn": 900,
  "tokenType": "Bearer"
}
```

**Why Token Rotation Matters:**
- Prevents replay attacks
- Limits damage if refresh token is stolen
- Industry best practice per OAuth 2.0 Security Best Current Practice (RFC 8252)

---

### D. Logout
**Endpoint:** `POST /auth/logout`

**Headers:**
```
Authorization: Bearer <accessToken>
```

**Request:**
```json
{
  "refreshToken": "current-refresh-token"
}
```

**Backend Process:**
1. Verify access token (extract userID)
2. Delete session from `sessions` table by `refresh_token_hash`
3. Add access token to Redis blacklist (TTL = time until expiry)

**Response:**
```json
{
  "message": "Logged out successfully"
}
```

---

## 3. iOS Client Implementation

### A. Session Storage (iOS Keychain)
**CRITICAL:** Tokens MUST be stored in iOS Keychain (Secure Enclave), NEVER `UserDefaults`.

**File:** `Shell/Features/Auth/Infrastructure/KeychainSessionRepository.swift`

**Interface:**
```swift
protocol SessionRepository: Actor {
    func saveSession(accessToken: String, refreshToken: String, expiresAt: Date) async throws
    func getSession() async throws -> Session?
    func clearSession() async throws
}

struct Session: Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
}
```

**Implementation:**
```swift
actor KeychainSessionRepository: SessionRepository {
    private let service = "com.adamcodertrader.Shell"
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let expiresAtKey = "expiresAt"

    func saveSession(accessToken: String, refreshToken: String, expiresAt: Date) async throws {
        // Store in Keychain with kSecAttrAccessible = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        // Use Security framework's SecItemAdd/SecItemUpdate
    }

    func getSession() async throws -> Session? {
        // Retrieve from Keychain with SecItemCopyMatching
    }

    func clearSession() async throws {
        // Delete from Keychain with SecItemDelete
    }
}
```

**Keychain Attributes:**
- `kSecAttrAccessible`: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` (no iCloud sync)
- `kSecAttrService`: Bundle identifier
- `kSecAttrAccount`: Token key name
- `kSecClass`: `kSecClassGenericPassword`

---

### B. HTTP Request Interceptor (Auto Token Refresh)
**File:** `Shell/Core/Infrastructure/HTTP/AuthRequestInterceptor.swift`

**Purpose:** Intercept 401 responses, refresh token, retry request

**Interface:**
```swift
protocol RequestInterceptor {
    func adapt(_ request: URLRequest) async throws -> URLRequest
    func retry(_ request: URLRequest, with error: Error) async throws -> Bool
}
```

**Implementation:**
```swift
actor AuthRequestInterceptor: RequestInterceptor {
    private let sessionRepository: SessionRepository
    private let authHTTPClient: AuthHTTPClient
    private var isRefreshing = false
    private var refreshTask: Task<Session, Error>?

    // Add Authorization header to all requests
    func adapt(_ request: URLRequest) async throws -> URLRequest {
        guard let session = try await sessionRepository.getSession() else {
            return request // No session, pass through
        }

        var mutableRequest = request
        mutableRequest.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        return mutableRequest
    }

    // Retry failed requests after refreshing token
    func retry(_ request: URLRequest, with error: Error) async throws -> Bool {
        guard let httpResponse = (error as? URLError)?.userInfo[NSURLErrorFailingURLPeerTrustErrorKey] as? HTTPURLResponse,
              httpResponse.statusCode == 401 else {
            return false // Not a 401, don't retry
        }

        // Prevent multiple concurrent refresh attempts
        if isRefreshing {
            // Wait for existing refresh task
            _ = try await refreshTask?.value
            return true
        }

        isRefreshing = true
        refreshTask = Task {
            do {
                let session = try await sessionRepository.getSession()
                guard let refreshToken = session?.refreshToken else {
                    throw AuthError.noRefreshToken
                }

                // Call /auth/refresh endpoint
                let newSession = try await authHTTPClient.refresh(refreshToken: refreshToken)
                try await sessionRepository.saveSession(
                    accessToken: newSession.accessToken,
                    refreshToken: newSession.refreshToken,
                    expiresAt: newSession.expiresAt
                )
                return newSession
            } catch {
                // Refresh failed, clear session and logout
                try await sessionRepository.clearSession()
                throw AuthError.refreshFailed
            }
        }

        defer {
            isRefreshing = false
            refreshTask = nil
        }

        _ = try await refreshTask?.value
        return true // Retry original request with new token
    }
}
```

---

### C. Deep Link Handling
**URL Scheme:** `shell://auth/callback?token=...`

**Use Case:** Magic links, OAuth redirects (future)

**File:** `Shell/App/Coordinators/DeepLinkCoordinator.swift`

**Implementation:**
```swift
func handleDeepLink(_ url: URL) {
    guard url.scheme == "shell",
          url.host == "auth",
          url.path == "/callback" else {
        return
    }

    let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    if let token = components?.queryItems?.first(where: { $0.name == "token" })?.value {
        // Handle magic link token
        Task {
            try await authUseCase.authenticateWithMagicLink(token: token)
        }
    }
}
```

---

## 4. Backend Database Schema

### Users Table
```sql
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    email_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
```

### Sessions Table (Refresh Tokens)
```sql
CREATE TABLE IF NOT EXISTS sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(64) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    last_used_at TIMESTAMP NOT NULL DEFAULT NOW(),
    user_agent TEXT,
    ip_address INET
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_refresh_token_hash ON sessions(refresh_token_hash);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
```

### Auth Logs Table (Security Auditing)
```sql
CREATE TABLE IF NOT EXISTS auth_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) ON DELETE SET NULL,
    event_type VARCHAR(50) NOT NULL, -- 'login', 'logout', 'refresh', 'failed_login'
    ip_address INET,
    user_agent TEXT,
    success BOOLEAN NOT NULL,
    error_message TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_auth_logs_user_id ON auth_logs(user_id);
CREATE INDEX idx_auth_logs_created_at ON auth_logs(created_at DESC);
```

---

## 5. Security Requirements

### Password Security
- **Hashing:** Argon2id (winner of Password Hashing Competition)
- **Parameters:** `argon2.hash(password, {type: argon2.argon2id, timeCost: 3, memoryCost: 65536, parallelism: 4})`
- **Library:** `npm install argon2`

### JWT Security
- **Algorithm:** HS256 (HMAC-SHA256)
- **Secret:** 256-bit random key stored in `.env` (NEVER commit)
- **Claims:**
  ```json
  {
    "sub": "userID",
    "email": "user@example.com",
    "iat": 1706745600,
    "exp": 1706746500
  }
  ```
- **Library:** `npm install jsonwebtoken`

### Rate Limiting (Redis)
- **Login:** 5 attempts per email per 15 minutes
- **Refresh:** 10 attempts per IP per 15 minutes
- **Library:** `npm install redis express-rate-limit rate-limit-redis`

### HTTPS Enforcement
- **iOS:** App Transport Security (ATS) enabled (enforces HTTPS)
- **Backend:** HTTPS in production (TLS 1.3)
- **Development:** iOS Simulator allows localhost HTTP exception

---

## 6. Error Handling

### iOS Error Types
```swift
enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case networkError(Error)
    case tokenExpired
    case noRefreshToken
    case refreshFailed
    case keychainError(OSStatus)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .tokenExpired:
            return "Your session has expired"
        case .noRefreshToken:
            return "No refresh token available"
        case .refreshFailed:
            return "Failed to refresh session"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .invalidResponse:
            return "Invalid server response"
        }
    }
}
```

### Backend Error Responses
```json
{
  "error": "error_code",
  "message": "Human-readable message",
  "field": "fieldName" // Optional, for validation errors
}
```

**Error Codes:**
- `validation_error` (400): Invalid input
- `unauthorized` (401): Invalid credentials or expired token
- `forbidden` (403): Valid token but insufficient permissions
- `not_found` (404): Resource not found
- `rate_limit_exceeded` (429): Too many requests
- `internal_error` (500): Server error

---

## 7. Testing Strategy

### Backend Tests
1. **Unit Tests:**
   - Password hashing with Argon2id
   - JWT token generation and verification
   - Token refresh rotation logic
   - Reuse detection

2. **Integration Tests:**
   - POST /auth/register → Creates user
   - POST /auth/login → Returns tokens
   - POST /auth/refresh → Rotates tokens
   - POST /auth/logout → Invalidates session
   - Reuse old refresh token → 401 + all sessions invalidated

### iOS Tests
1. **Unit Tests:**
   - `KeychainSessionRepository` save/get/clear
   - `AuthRequestInterceptor` 401 handling
   - `LoginViewModel` state management

2. **Integration Tests:**
   - Login → Token saved to Keychain → API call succeeds
   - Access protected route without token → 401
   - Manually expire token → Auto-refresh → Request retried
   - Logout → Keychain cleared → Routed to login

---

## 8. Implementation Checklist

### Backend Tasks
- [ ] Install dependencies: `argon2`, `jsonwebtoken`, `redis`, `express-rate-limit`
- [ ] Create database migration for `users`, `sessions`, `auth_logs` tables
- [ ] Implement `POST /auth/register` endpoint
- [ ] Implement `POST /auth/login` endpoint with Argon2id verification
- [ ] Implement `POST /auth/refresh` endpoint with token rotation
- [ ] Implement `POST /auth/logout` endpoint
- [ ] Add JWT middleware to protect existing routes (`/v1/items`, `/v1/users/:userID/profile`)
- [ ] Add rate limiting middleware (Redis)
- [ ] Add auth logging for security events
- [ ] Test refresh token reuse detection

### iOS Tasks
- [ ] Create `KeychainSessionRepository` actor
- [ ] Create `AuthHTTPClient` for auth endpoints
- [ ] Implement `AuthRequestInterceptor` for 401 handling
- [ ] Update `AppBootstrapper` to check Keychain on launch
- [ ] Update `AppCoordinator` to route based on session state
- [ ] Create `LoginUseCase` (call backend /auth/login)
- [ ] Create `LogoutUseCase` (call backend /auth/logout + clear Keychain)
- [ ] Create `RefreshSessionUseCase` (call backend /auth/refresh)
- [ ] Update `LoginViewModel` to use new use cases
- [ ] Add deep link handler for `shell://auth/callback`
- [ ] Write unit tests for Keychain repository
- [ ] Write integration tests for login flow

### QA Verification
- [ ] User can register new account
- [ ] User can login with valid credentials
- [ ] Invalid credentials return error
- [ ] Access token expires after 15 minutes → Auto-refresh
- [ ] Refresh token expires after 7 days → Logout required
- [ ] Reusing old refresh token invalidates all sessions
- [ ] Rate limiting blocks excessive login attempts
- [ ] Logout clears tokens from Keychain and backend
- [ ] Protected routes return 401 without token
- [ ] Network interceptor retries requests after refresh

---

## 9. Deployment Checklist

### Environment Variables (Backend)
```env
# JWT Secret (generate with: openssl rand -base64 32)
JWT_SECRET=your-256-bit-secret-key-here

# Redis (for rate limiting)
REDIS_HOST=localhost
REDIS_PORT=6379

# Database (already configured)
DB_HOST=localhost
DB_PORT=5432
DB_NAME=shell_db
DB_USER=shell
DB_PASSWORD=shell_dev_password
```

### iOS Configuration
- [ ] Update `Info.plist` with custom URL scheme: `shell`
- [ ] Configure ATS exception for localhost (development only)
- [ ] Set Keychain access group (for app group sharing, optional)

---

## 10. Future Enhancements

### Phase 2: Multi-Device Support
- Device fingerprinting
- Push notifications for new device login
- Device management UI (revoke sessions)

### Phase 3: Biometric Authentication
- Face ID / Touch ID for app unlock
- Encrypted local session cache (faster app launch)

### Phase 4: OAuth 2.0 Providers
- Sign in with Apple
- Sign in with Google
- OIDC integration

### Phase 5: Advanced Security
- TOTP 2FA (Two-Factor Authentication)
- Email verification
- Password reset flow
- Account recovery

---

## 11. References

- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [iOS Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [Argon2 Password Hashing](https://github.com/P-H-C/phc-winner-argon2)

---

**Last Updated:** 2026-02-14
**Approved By:** Adam Oates
**Implementation Status:** Ready for Agent Team Execution
