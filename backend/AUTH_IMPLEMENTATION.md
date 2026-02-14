# Authentication Implementation - Shell Backend

## Overview

This backend implements a secure authentication system following OAuth 2.0 best practices with:
- **Argon2id password hashing** (PHC winner)
- **JWT access tokens** (15 min expiry)
- **Refresh token rotation** (7 day expiry)
- **Redis-based rate limiting**
- **Comprehensive security logging**

## Security Features

### 1. Password Security
- **Algorithm**: Argon2id
- **Parameters**: `timeCost: 3, memoryCost: 65536, parallelism: 4`
- **Library**: `argon2`
- Passwords never stored in plaintext

### 2. Token Security
- **Access Token**: JWT with HS256, 15 min expiry
- **Refresh Token**: UUID v4, stored as SHA-256 hash
- **Token Rotation**: New refresh token on each use
- **Reuse Detection**: Invalidates all sessions if old token reused

### 3. Rate Limiting (Redis)
- **Login**: 5 attempts per email per 15 minutes
- **Refresh**: 10 attempts per IP per 15 minutes
- **Storage**: Redis for distributed rate limiting

### 4. Security Logging
All auth events logged to `auth_logs` table:
- Registration attempts
- Login attempts (success/failure)
- Token refresh operations
- Logout events
- Security violations (token reuse)

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

### Sessions Table
```sql
CREATE TABLE sessions (
    session_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    refresh_token_hash VARCHAR(64) UNIQUE,
    expires_at TIMESTAMP,
    last_used_at TIMESTAMP,
    user_agent TEXT,
    ip_address INET
);
```

### Auth Logs Table
```sql
CREATE TABLE auth_logs (
    log_id UUID PRIMARY KEY,
    user_id UUID REFERENCES users(user_id),
    event_type VARCHAR(50),
    success BOOLEAN,
    ip_address INET,
    user_agent TEXT,
    error_message TEXT,
    created_at TIMESTAMP
);
```

## API Endpoints

### 1. Register User
```bash
POST /auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "confirmPassword": "SecurePass123!"
}
```

**Response (201)**:
```json
{
  "userID": "uuid-v4",
  "email": "user@example.com",
  "message": "Registration successful"
}
```

**Validation Rules**:
- Email: Valid format, unique
- Password: Min 8 chars, 1 uppercase, 1 number, 1 special char
- Passwords must match

### 2. Login
```bash
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePass123!"
}
```

**Response (200)**:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "expiresIn": 900,
  "tokenType": "Bearer",
  "userID": "uuid"
}
```

**Rate Limiting**: 5 attempts per email per 15 minutes

### 3. Refresh Token
```bash
POST /auth/refresh
Content-Type: application/json

{
  "refreshToken": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Response (200)**:
```json
{
  "accessToken": "new-jwt-token",
  "refreshToken": "new-refresh-token",
  "expiresIn": 900,
  "tokenType": "Bearer"
}
```

**Security**: Old refresh token is invalidated. Reusing old token invalidates ALL user sessions.

### 4. Logout
```bash
POST /auth/logout
Authorization: Bearer <accessToken>
Content-Type: application/json

{
  "refreshToken": "current-refresh-token"
}
```

**Response (200)**:
```json
{
  "message": "Logged out successfully"
}
```

## Protected Routes

All routes below require JWT authentication via `Authorization: Bearer <token>` header:

- `GET /v1/items` - Fetch all items
- `POST /v1/items` - Create item
- `PUT /v1/items/:id` - Update item
- `DELETE /v1/items/:id` - Delete item
- `GET /v1/users/:userID/profile` - Get profile (own only)
- `PUT /v1/users/:userID/profile` - Update profile (own only)
- `DELETE /v1/users/:userID/profile` - Delete profile (own only)
- `GET /v1/users/:userID/identity-status` - Check identity status (own only)

**Authorization**: Users can only access their own resources (enforced by matching JWT `sub` claim with `:userID`).

## Error Responses

### 400 Bad Request
```json
{
  "error": "validation_error",
  "message": "Email already registered",
  "field": "email"
}
```

### 401 Unauthorized
```json
{
  "error": "unauthorized",
  "message": "Invalid credentials"
}
```

### 403 Forbidden
```json
{
  "error": "forbidden",
  "message": "You can only access your own profile"
}
```

### 429 Too Many Requests
```json
{
  "error": "rate_limit_exceeded",
  "message": "Too many login attempts. Please try again in 15 minutes."
}
```

## Environment Variables

Required in `.env`:

```env
# JWT Secret (MUST be 256-bit random key)
JWT_SECRET=<generate with: openssl rand -base64 32>

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=shell_db
DB_USER=shell
DB_PASSWORD=shell_dev_password
```

## Running the Backend

### 1. Start Services (Docker)
```bash
cd backend
docker compose up -d
```

This starts:
- PostgreSQL (port 5432)
- Redis (port 6379)
- Node.js backend (port 3000)

### 2. Verify Health
```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "healthy",
  "database": "connected"
}
```

### 3. Apply Migrations
Migrations are automatically applied on first Docker startup via `docker-entrypoint-initdb.d/`.

## Testing the Auth Flow

### 1. Register User
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!",
    "confirmPassword": "TestPass123!"
  }'
```

### 2. Login
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!"
  }'
```

Save the `accessToken` and `refreshToken` from response.

### 3. Access Protected Route
```bash
curl -X GET http://localhost:3000/v1/items \
  -H "Authorization: Bearer <accessToken>"
```

### 4. Refresh Token
```bash
curl -X POST http://localhost:3000/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "<refreshToken>"
  }'
```

### 5. Logout
```bash
curl -X POST http://localhost:3000/auth/logout \
  -H "Authorization: Bearer <accessToken>" \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "<refreshToken>"
  }'
```

## Security Best Practices

### Token Storage (iOS Client)
- **MUST**: Store tokens in iOS Keychain
- **NEVER**: Store in UserDefaults or NSUserDefaults
- **Keychain Attributes**:
  - `kSecAttrAccessible`: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
  - `kSecClass`: `kSecClassGenericPassword`

### HTTPS Enforcement
- **Production**: MUST use HTTPS (TLS 1.3)
- **Development**: iOS Simulator allows localhost HTTP exception
- **iOS**: App Transport Security (ATS) enabled by default

### Password Requirements
- Minimum 8 characters
- At least 1 uppercase letter
- At least 1 number
- At least 1 special character
- No maximum length (prevents truncation attacks)

### Token Expiry Strategy
- **Access Token**: 15 minutes (short-lived, reduces exposure)
- **Refresh Token**: 7 days (long-lived, convenience vs security)
- **Rotation**: New refresh token on every use (limits replay attacks)

## Monitoring and Maintenance

### Security Logs
Query auth events:
```sql
SELECT * FROM auth_logs 
WHERE event_type = 'failed_login' 
  AND success = false 
ORDER BY created_at DESC 
LIMIT 100;
```

### Session Cleanup
Remove expired sessions:
```sql
SELECT cleanup_expired_sessions();
```

Run this as a cron job daily.

### Rate Limit Reset
Redis keys automatically expire. To manually clear:
```bash
docker exec -it shell-redis redis-cli KEYS "rl:*" | xargs redis-cli DEL
```

## Dependencies

```json
{
  "argon2": "^0.31.2",
  "jsonwebtoken": "^9.0.2",
  "redis": "^4.6.12",
  "express-rate-limit": "^7.1.5",
  "rate-limit-redis": "^4.2.0",
  "uuid": "^9.0.1"
}
```

## References

- [OAuth 2.0 RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749)
- [OAuth 2.0 Security Best Current Practice](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [Argon2 Password Hashing](https://github.com/P-H-C/phc-winner-argon2)

---

**Implementation Date**: 2026-02-14
**Status**: Complete
**Version**: 1.0
