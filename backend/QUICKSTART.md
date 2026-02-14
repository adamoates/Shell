# Quick Start Guide - Shell Backend Authentication

## Prerequisites
- Docker Desktop installed and running
- curl or Postman for API testing

## Starting the Backend

### 1. Start All Services
```bash
cd backend
docker compose up -d
```

This starts:
- PostgreSQL database (port 5432)
- Redis cache (port 6379)
- Node.js backend (port 3000)

### 2. Verify Services
```bash
# Check Docker containers
docker compose ps

# Check backend health
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "healthy",
  "database": "connected"
}
```

### 3. Run Auth Tests
```bash
./test-auth.sh
```

This script tests all authentication flows including:
- User registration
- Login/logout
- Token refresh
- Token rotation
- Reuse detection
- Protected route access

## Manual Testing

### Register a New User
```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@example.com",
    "password": "SecurePass123!",
    "confirmPassword": "SecurePass123!"
  }'
```

### Login
```bash
curl -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "demo@example.com",
    "password": "SecurePass123!"
  }'
```

Save the `accessToken` and `refreshToken` from the response.

### Access Protected Route
```bash
curl -X GET http://localhost:3000/v1/items \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE"
```

### Refresh Token
```bash
curl -X POST http://localhost:3000/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "YOUR_REFRESH_TOKEN_HERE"
  }'
```

### Logout
```bash
curl -X POST http://localhost:3000/auth/logout \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "YOUR_REFRESH_TOKEN_HERE"
  }'
```

## Database Access

### Connect to PostgreSQL
```bash
docker exec -it shell-postgres psql -U shell -d shell_db
```

### Useful SQL Queries
```sql
-- View registered users
SELECT user_id, email, email_verified, created_at FROM users;

-- View active sessions
SELECT session_id, user_id, expires_at, last_used_at FROM sessions WHERE expires_at > NOW();

-- View auth logs
SELECT event_type, success, ip_address, created_at FROM auth_logs ORDER BY created_at DESC LIMIT 20;

-- Clean up expired sessions
SELECT cleanup_expired_sessions();
```

## Stopping the Backend

```bash
# Stop services
docker compose down

# Stop and remove all data (DESTRUCTIVE)
docker compose down -v
```

## Troubleshooting

### Docker Not Running
```bash
# Start Docker Desktop application
open -a Docker

# Wait for Docker to start, then retry
docker compose up -d
```

### Port Already in Use
```bash
# Check what's using port 3000
lsof -i :3000

# Kill the process or change PORT in .env
```

### Redis Connection Failed
Redis is optional for rate limiting. If Redis fails, the backend will fall back to in-memory rate limiting.

### Database Migration Failed
```bash
# Apply migrations manually
docker exec -it shell-postgres psql -U shell -d shell_db -f /docker-entrypoint-initdb.d/02_auth_schema.sql
```

## Next Steps

1. Read `AUTH_IMPLEMENTATION.md` for detailed documentation
2. Review `Docs/auth-spec.md` for security requirements
3. Implement iOS client authentication (see spec for Keychain storage)
4. Test token refresh flow in iOS app
5. Implement auto-retry with interceptor for 401 responses

## Environment Variables

All configuration is in `.env`:

```env
NODE_ENV=development
PORT=3000
DB_HOST=localhost
DB_PORT=5432
DB_NAME=shell_db
DB_USER=shell
DB_PASSWORD=shell_dev_password
JWT_SECRET=<generated-secret>
REDIS_HOST=localhost
REDIS_PORT=6379
```

**IMPORTANT**: Never commit `.env` to git. Use `.env.example` for templates.

---

For production deployment, see `AUTH_IMPLEMENTATION.md` section on security hardening.
