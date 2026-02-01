# Shell Backend API

Backend API service for the Shell iOS application. Provides user profile management endpoints backed by PostgreSQL.

## Prerequisites

- Node.js 18+ and npm
- Docker and Docker Compose

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Start Database

Start PostgreSQL in Docker:

```bash
docker-compose up -d
```

The database will initialize automatically with the schema from `schema.sql`.

Check database health:

```bash
docker-compose ps
```

### 3. Configure Environment

Copy the example environment file:

```bash
cp .env.example .env
```

The default configuration works with the Docker Compose setup.

### 4. Start API Server

Development mode with auto-reload:

```bash
npm run dev
```

Production mode:

```bash
npm start
```

The API will be available at `http://localhost:3000`

### 5. Verify Installation

Check the health endpoint:

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{"status":"healthy","database":"connected"}
```

## API Endpoints

### Health Check

```
GET /health
```

Returns API and database connection status.

### User Profile Endpoints

#### Fetch Profile

```
GET /v1/users/:userID/profile
```

Returns user profile if exists, 404 if not found.

Response:
```json
{
  "userID": "user123",
  "screenName": "trader123",
  "birthday": "1990-05-15",
  "avatarURL": "https://cdn.shell.app/avatar.jpg",
  "createdAt": "2026-01-30T12:00:00Z",
  "updatedAt": "2026-01-30T12:00:00Z"
}
```

#### Create/Update Profile

```
PUT /v1/users/:userID/profile
```

Request body:
```json
{
  "screenName": "trader123",
  "birthday": "1990-05-15",
  "avatarURL": "https://cdn.shell.app/avatar.jpg"
}
```

#### Delete Profile

```
DELETE /v1/users/:userID/profile
```

Returns 204 on success, 404 if profile doesn't exist.

#### Identity Status

```
GET /v1/users/:userID/identity-status
```

Response:
```json
{
  "hasCompletedIdentitySetup": true
}
```

## Database Management

### Stop Database

```bash
docker-compose down
```

### Reset Database

Remove all data and restart:

```bash
docker-compose down -v
docker-compose up -d
```

### View Database Logs

```bash
docker-compose logs -f postgres
```

### Connect to Database

```bash
docker exec -it shell-postgres psql -U shell -d shell_db
```

## Testing with curl

Create a profile:

```bash
curl -X PUT http://localhost:3000/v1/users/user123/profile \
  -H "Content-Type: application/json" \
  -d '{
    "screenName": "trader123",
    "birthday": "1990-05-15",
    "avatarURL": "https://cdn.shell.app/avatar.jpg"
  }'
```

Fetch a profile:

```bash
curl http://localhost:3000/v1/users/user123/profile
```

Check identity status:

```bash
curl http://localhost:3000/v1/users/user123/identity-status
```

Delete a profile:

```bash
curl -X DELETE http://localhost:3000/v1/users/user123/profile
```

## iOS App Configuration

To use this backend with the Shell iOS app:

1. Start the backend (steps above)
2. In Xcode, open `Shell/Core/Infrastructure/Config/APIConfig.swift`
3. Verify the local configuration points to `http://localhost:3000/v1`
4. Set `RepositoryConfig.useRemoteRepository = true` to enable remote repository
5. Run the app on simulator (simulator can reach localhost)

The iOS app will now communicate with your local backend API.
