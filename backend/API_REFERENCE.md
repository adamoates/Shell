# Shell Backend API Reference

**Base URL**: `http://localhost:3000`
**Authentication**: Bearer Token (JWT)

---

## Authentication Endpoints

### POST /auth/register
Register a new user account.

**Request**:
```json
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

**Validation**:
- Email: Valid format, unique in database
- Password: Min 8 chars, 1 uppercase, 1 number, 1 special char
- Passwords must match

**Error Responses**:
- `400` - Validation error (invalid email, weak password, passwords don't match)
- `500` - Internal server error

---

### POST /auth/login
Authenticate user and receive tokens.

**Rate Limit**: 5 attempts per email per 15 minutes

**Request**:
```json
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

**Token Details**:
- Access Token: JWT, 15 min expiry
- Refresh Token: UUID v4, 7 day expiry

**Error Responses**:
- `400` - Missing email or password
- `401` - Invalid credentials
- `429` - Rate limit exceeded
- `500` - Internal server error

---

### POST /auth/refresh
Refresh access token using refresh token.

**Rate Limit**: 10 attempts per IP per 15 minutes

**Request**:
```json
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

**Security Features**:
- Old refresh token is invalidated
- New refresh token is generated (token rotation)
- Reusing old token invalidates ALL user sessions

**Error Responses**:
- `400` - Missing refresh token
- `401` - Invalid or expired refresh token
- `429` - Rate limit exceeded
- `500` - Internal server error

---

### POST /auth/logout
Logout and invalidate session.

**Authentication**: Required (Bearer token)

**Request**:
```json
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

**Error Responses**:
- `400` - Missing refresh token
- `401` - Invalid or missing access token
- `404` - Session not found
- `500` - Internal server error

---

## Items Endpoints

All items endpoints require authentication.

### GET /v1/items
Fetch all items.

**Authentication**: Required

**Request**:
```
GET /v1/items
Authorization: Bearer <access-token>
```

**Response (200)**:
```json
[
  {
    "id": "uuid",
    "name": "Item name",
    "description": "Item description",
    "isCompleted": false,
    "createdAt": "2026-02-14T10:00:00.000Z",
    "updatedAt": "2026-02-14T10:00:00.000Z"
  }
]
```

**Error Responses**:
- `401` - Missing or invalid access token
- `500` - Internal server error

---

### POST /v1/items
Create a new item.

**Authentication**: Required

**Request**:
```json
{
  "name": "New item",
  "description": "Optional description",
  "isCompleted": false
}
```

**Response (201)**:
```json
{
  "id": "uuid",
  "name": "New item",
  "description": "Optional description",
  "isCompleted": false,
  "createdAt": "2026-02-14T10:00:00.000Z",
  "updatedAt": "2026-02-14T10:00:00.000Z"
}
```

**Validation**:
- `name` is required and cannot be empty

**Error Responses**:
- `400` - Validation error (missing or empty name)
- `401` - Missing or invalid access token
- `500` - Internal server error

---

### PUT /v1/items/:id
Update an existing item.

**Authentication**: Required

**Request**:
```json
{
  "name": "Updated name",
  "description": "Updated description",
  "isCompleted": true
}
```

**Response (200)**:
```json
{
  "id": "uuid",
  "name": "Updated name",
  "description": "Updated description",
  "isCompleted": true,
  "createdAt": "2026-02-14T10:00:00.000Z",
  "updatedAt": "2026-02-14T10:05:00.000Z"
}
```

**Error Responses**:
- `400` - Validation error (missing or empty name)
- `401` - Missing or invalid access token
- `404` - Item not found
- `500` - Internal server error

---

### DELETE /v1/items/:id
Delete an item.

**Authentication**: Required

**Request**:
```
DELETE /v1/items/:id
Authorization: Bearer <access-token>
```

**Response (204)**:
No content

**Error Responses**:
- `401` - Missing or invalid access token
- `404` - Item not found
- `500` - Internal server error

---

## Profile Endpoints

All profile endpoints require authentication and authorization.
Users can only access their own profile (userID must match JWT sub claim).

### GET /v1/users/:userID/profile
Fetch user profile.

**Authentication**: Required
**Authorization**: userID must match authenticated user

**Request**:
```
GET /v1/users/:userID/profile
Authorization: Bearer <access-token>
```

**Response (200)**:
```json
{
  "userID": "uuid",
  "screenName": "User123",
  "birthday": "1990-01-15",
  "avatarURL": "https://example.com/avatar.jpg",
  "createdAt": "2026-02-14T10:00:00.000Z",
  "updatedAt": "2026-02-14T10:00:00.000Z"
}
```

**Error Responses**:
- `401` - Missing or invalid access token
- `403` - Forbidden (accessing another user's profile)
- `404` - Profile not found
- `500` - Internal server error

---

### PUT /v1/users/:userID/profile
Create or update user profile.

**Authentication**: Required
**Authorization**: userID must match authenticated user

**Request**:
```json
{
  "screenName": "NewName",
  "birthday": "1990-01-15",
  "avatarURL": "https://example.com/avatar.jpg"
}
```

**Response (200)**:
```json
{
  "userID": "uuid",
  "screenName": "NewName",
  "birthday": "1990-01-15",
  "avatarURL": "https://example.com/avatar.jpg",
  "createdAt": "2026-02-14T10:00:00.000Z",
  "updatedAt": "2026-02-14T10:05:00.000Z"
}
```

**Validation**:
- `screenName` is required
- `birthday` is required (YYYY-MM-DD format)
- `avatarURL` is optional

**Error Responses**:
- `400` - Validation error (missing screenName or birthday)
- `401` - Missing or invalid access token
- `403` - Forbidden (updating another user's profile)
- `500` - Internal server error

---

### DELETE /v1/users/:userID/profile
Delete user profile.

**Authentication**: Required
**Authorization**: userID must match authenticated user

**Request**:
```
DELETE /v1/users/:userID/profile
Authorization: Bearer <access-token>
```

**Response (204)**:
No content

**Error Responses**:
- `401` - Missing or invalid access token
- `403` - Forbidden (deleting another user's profile)
- `404` - Profile not found
- `500` - Internal server error

---

### GET /v1/users/:userID/identity-status
Check if user has completed identity setup.

**Authentication**: Required
**Authorization**: userID must match authenticated user

**Request**:
```
GET /v1/users/:userID/identity-status
Authorization: Bearer <access-token>
```

**Response (200)**:
```json
{
  "hasCompletedIdentitySetup": true
}
```

**Error Responses**:
- `401` - Missing or invalid access token
- `403` - Forbidden (checking another user's status)
- `500` - Internal server error

---

## Health Check

### GET /health
Check backend and database health.

**Authentication**: Not required

**Request**:
```
GET /health
```

**Response (200)**:
```json
{
  "status": "healthy",
  "database": "connected"
}
```

**Error Responses**:
- `503` - Service unavailable (database connection failed)

---

## Error Response Format

All errors follow this format:

```json
{
  "error": "error_code",
  "message": "Human-readable error message",
  "field": "fieldName"
}
```

**Error Codes**:
- `validation_error` - Invalid input (400)
- `unauthorized` - Missing or invalid credentials (401)
- `token_expired` - Access token expired (401)
- `forbidden` - Insufficient permissions (403)
- `not_found` - Resource not found (404)
- `rate_limit_exceeded` - Too many requests (429)
- `internal_error` - Server error (500)

---

## Rate Limiting

**Login Endpoint**:
- 5 attempts per email per 15 minutes
- Tracked by email address

**Refresh Endpoint**:
- 10 attempts per IP per 15 minutes
- Tracked by IP address

**Rate Limit Response**:
```json
{
  "error": "rate_limit_exceeded",
  "message": "Too many login attempts. Please try again in 15 minutes."
}
```

HTTP Status: `429 Too Many Requests`

---

## Authentication Flow

### 1. Initial Login
```
Client → POST /auth/login (email, password)
Server → Returns: accessToken (15min), refreshToken (7 days)
Client → Stores both tokens in iOS Keychain
```

### 2. API Request
```
Client → GET /v1/items
        Headers: Authorization: Bearer <accessToken>
Server → Returns: Data (if token valid)
```

### 3. Token Expiry
```
Client → GET /v1/items
        Headers: Authorization: Bearer <expired-token>
Server → Returns: 401 Unauthorized (token_expired)
Client → POST /auth/refresh (refreshToken)
Server → Returns: NEW accessToken + NEW refreshToken
Client → Retries original request with new accessToken
```

### 4. Logout
```
Client → POST /auth/logout (accessToken, refreshToken)
Server → Deletes session from database
Client → Clears tokens from Keychain
```

---

## JWT Token Structure

**Access Token** (JWT):
```json
{
  "sub": "user-uuid",
  "email": "user@example.com",
  "iat": 1706745600,
  "exp": 1706746500
}
```

**Algorithm**: HS256 (HMAC-SHA256)
**Expiry**: 15 minutes

**Refresh Token**:
- Format: UUID v4
- Storage: SHA-256 hash in database
- Expiry: 7 days

---

## Security Features

1. **Password Hashing**: Argon2id (PHC winner)
2. **Token Rotation**: New refresh token on each use
3. **Reuse Detection**: Invalidates all sessions if old token reused
4. **Rate Limiting**: Redis-backed, per-email and per-IP
5. **Security Logging**: All auth events logged to database
6. **Authorization**: Users can only access their own resources
7. **HTTPS**: Required in production (TLS 1.3)

---

## Testing Examples

### Complete Flow Test
```bash
# 1. Register
REGISTER=$(curl -s -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPass123!","confirmPassword":"TestPass123!"}')
echo $REGISTER

# 2. Login
LOGIN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"TestPass123!"}')
echo $LOGIN

# Extract tokens
ACCESS_TOKEN=$(echo $LOGIN | jq -r '.accessToken')
REFRESH_TOKEN=$(echo $LOGIN | jq -r '.refreshToken')

# 3. Get items
curl -X GET http://localhost:3000/v1/items \
  -H "Authorization: Bearer $ACCESS_TOKEN"

# 4. Create item
curl -X POST http://localhost:3000/v1/items \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","description":"Created via API","isCompleted":false}'

# 5. Refresh token
REFRESH=$(curl -s -X POST http://localhost:3000/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$REFRESH_TOKEN\"}")
echo $REFRESH

# Extract new tokens
NEW_ACCESS_TOKEN=$(echo $REFRESH | jq -r '.accessToken')
NEW_REFRESH_TOKEN=$(echo $REFRESH | jq -r '.refreshToken')

# 6. Logout
curl -X POST http://localhost:3000/auth/logout \
  -H "Authorization: Bearer $NEW_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"refreshToken\":\"$NEW_REFRESH_TOKEN\"}"
```

---

**Last Updated**: 2026-02-14
**API Version**: 1.0
