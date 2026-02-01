require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 3000;

// Database connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'shell_db',
  user: process.env.DB_USER || 'shell',
  password: process.env.DB_PASSWORD || 'shell_dev_password'
});

// Middleware
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'healthy', database: 'connected' });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: error.message });
  }
});

// GET /v1/users/:userID/profile - Fetch user profile
app.get('/v1/users/:userID/profile', async (req, res) => {
  const { userID } = req.params;

  try {
    const result = await pool.query(
      'SELECT user_id, screen_name, birthday, avatar_url, created_at, updated_at FROM user_profiles WHERE user_id = $1',
      [userID]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'profile_not_found',
        message: 'No profile exists for this user'
      });
    }

    const profile = result.rows[0];

    // Format dates to ISO 8601
    const response = {
      userID: profile.user_id,
      screenName: profile.screen_name,
      birthday: profile.birthday.toISOString().split('T')[0], // YYYY-MM-DD
      avatarURL: profile.avatar_url,
      createdAt: profile.created_at.toISOString(),
      updatedAt: profile.updated_at.toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Error fetching profile:', error);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to fetch profile'
    });
  }
});

// PUT /v1/users/:userID/profile - Create or update user profile
app.put('/v1/users/:userID/profile', async (req, res) => {
  const { userID } = req.params;
  const { screenName, birthday, avatarURL } = req.body;

  // Validation
  if (!screenName || !birthday) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'screenName and birthday are required',
      field: !screenName ? 'screenName' : 'birthday'
    });
  }

  try {
    const result = await pool.query(
      `INSERT INTO user_profiles (user_id, screen_name, birthday, avatar_url)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id)
       DO UPDATE SET
         screen_name = EXCLUDED.screen_name,
         birthday = EXCLUDED.birthday,
         avatar_url = EXCLUDED.avatar_url,
         updated_at = NOW()
       RETURNING user_id, screen_name, birthday, avatar_url, created_at, updated_at`,
      [userID, screenName, birthday, avatarURL || null]
    );

    const profile = result.rows[0];

    const response = {
      userID: profile.user_id,
      screenName: profile.screen_name,
      birthday: profile.birthday.toISOString().split('T')[0],
      avatarURL: profile.avatar_url,
      createdAt: profile.created_at.toISOString(),
      updatedAt: profile.updated_at.toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Error saving profile:', error);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to save profile'
    });
  }
});

// DELETE /v1/users/:userID/profile - Delete user profile
app.delete('/v1/users/:userID/profile', async (req, res) => {
  const { userID } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM user_profiles WHERE user_id = $1 RETURNING user_id',
      [userID]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'profile_not_found',
        message: 'No profile exists for this user'
      });
    }

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting profile:', error);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to delete profile'
    });
  }
});

// GET /v1/users/:userID/identity-status - Check if user has completed identity setup
app.get('/v1/users/:userID/identity-status', async (req, res) => {
  const { userID } = req.params;

  try {
    const result = await pool.query(
      'SELECT user_id, screen_name FROM user_profiles WHERE user_id = $1',
      [userID]
    );

    const hasCompletedIdentitySetup = result.rows.length > 0 && result.rows[0].screen_name.length > 0;

    res.json({
      hasCompletedIdentitySetup
    });
  } catch (error) {
    console.error('Error checking identity status:', error);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to check identity status'
    });
  }
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'not_found',
    message: `Route ${req.method} ${req.path} not found`
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({
    error: 'internal_error',
    message: 'An unexpected error occurred'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`Shell Backend API running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing connections...');
  await pool.end();
  process.exit(0);
});
