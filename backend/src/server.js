require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const argon2 = require('argon2');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { randomUUID } = crypto; // Use Node.js built-in UUID instead of 'uuid' package
const { createClient } = require('redis');
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis').default;

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
  console.error('FATAL: JWT_SECRET not set in environment variables');
  process.exit(1);
}

// Database connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'shell_db',
  user: process.env.DB_USER || 'shell',
  password: process.env.DB_PASSWORD || 'shell_dev_password'
});

// Redis client for rate limiting
let redisClient;
const REDIS_HOST = process.env.REDIS_HOST || 'localhost';
const REDIS_PORT = process.env.REDIS_PORT || 6379;

(async () => {
  try {
    redisClient = createClient({
      socket: {
        host: REDIS_HOST,
        port: REDIS_PORT
      }
    });
    
    redisClient.on('error', (err) => {
      console.error('Redis Client Error:', err);
    });
    
    await redisClient.connect();
    console.log('Redis connected successfully');
  } catch (error) {
    console.warn('Redis connection failed, rate limiting will use memory store:', error.message);
    redisClient = null;
  }
})();

// Middleware
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

// Hash password with Argon2id
async function hashPassword(password) {
  return await argon2.hash(password, {
    type: argon2.argon2id,
    timeCost: 3,
    memoryCost: 65536, // 64 MB
    parallelism: 4
  });
}

// Verify password with Argon2id
async function verifyPassword(hash, password) {
  try {
    return await argon2.verify(hash, password);
  } catch (error) {
    return false;
  }
}

// Generate JWT access token
function generateAccessToken(userID, email) {
  return jwt.sign(
    {
      sub: userID,
      email: email
    },
    JWT_SECRET,
    {
      algorithm: 'HS256',
      expiresIn: '15m' // 15 minutes
    }
  );
}

// Generate refresh token (UUID v4)
function generateRefreshToken() {
  return randomUUID();
}

// Hash refresh token with SHA-256
function hashRefreshToken(token) {
  return crypto.createHash('sha256').update(token).digest('hex');
}

// Log auth event to database
async function logAuthEvent(userID, eventType, success, ipAddress, userAgent, errorMessage = null) {
  try {
    await pool.query(
      `INSERT INTO auth_logs (user_id, event_type, success, ip_address, user_agent, error_message)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [userID, eventType, success, ipAddress, userAgent, errorMessage]
    );
  } catch (error) {
    console.error('Failed to log auth event:', error);
  }
}

// Validate email format
function isValidEmail(email) {
  const emailRegex = /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i;
  return emailRegex.test(email);
}

// Validate password strength
function isValidPassword(password) {
  // Min 8 chars, 1 uppercase, 1 number, 1 special char
  const minLength = password.length >= 8;
  const hasUppercase = /[A-Z]/.test(password);
  const hasNumber = /[0-9]/.test(password);
  const hasSpecial = /[!@#$%^&*(),.?":{}|<>]/.test(password);
  
  return minLength && hasUppercase && hasNumber && hasSpecial;
}

// ============================================================================
// RATE LIMITING MIDDLEWARE
// ============================================================================

// Login rate limiter: 5 attempts per email per 15 minutes
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  store: redisClient ? new RedisStore({
    sendCommand: (...args) => redisClient.sendCommand(args),
    prefix: 'rl:login:'
  }) : undefined,
  keyGenerator: (req) => {
    // Rate limit by email
    return req.body.email || req.ip;
  },
  handler: (req, res) => {
    res.status(429).json({
      error: 'rate_limit_exceeded',
      message: 'Too many login attempts. Please try again in 15 minutes.'
    });
  }
});

// Refresh rate limiter: 10 attempts per IP per 15 minutes
const refreshLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  store: redisClient ? new RedisStore({
    sendCommand: (...args) => redisClient.sendCommand(args),
    prefix: 'rl:refresh:'
  }) : undefined,
  handler: (req, res) => {
    res.status(429).json({
      error: 'rate_limit_exceeded',
      message: 'Too many refresh attempts. Please try again later.'
    });
  }
});

// ============================================================================
// JWT AUTHENTICATION MIDDLEWARE
// ============================================================================

async function authenticateJWT(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'unauthorized',
      message: 'Missing or invalid authorization header'
    });
  }
  
  const token = authHeader.substring(7); // Remove 'Bearer ' prefix
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET, { algorithms: ['HS256'] });
    req.userID = decoded.sub;
    req.userEmail = decoded.email;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'token_expired',
        message: 'Access token has expired'
      });
    }
    
    return res.status(401).json({
      error: 'unauthorized',
      message: 'Invalid access token'
    });
  }
}

// ============================================================================
// AUTHENTICATION ENDPOINTS
// ============================================================================

// POST /auth/register - User registration
app.post('/auth/register', async (req, res) => {
  const { email, password, confirmPassword } = req.body;
  const ipAddress = req.ip;
  const userAgent = req.headers['user-agent'];
  
  // Validation
  if (!email || !password || !confirmPassword) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'Email, password, and confirmPassword are required',
      field: !email ? 'email' : !password ? 'password' : 'confirmPassword'
    });
  }
  
  if (!isValidEmail(email)) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'Invalid email format',
      field: 'email'
    });
  }
  
  if (password !== confirmPassword) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'Passwords do not match',
      field: 'confirmPassword'
    });
  }
  
  if (!isValidPassword(password)) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'Password must be at least 8 characters with 1 uppercase, 1 number, and 1 special character',
      field: 'password'
    });
  }
  
  try {
    // Check if email already exists
    const existingUser = await pool.query(
      'SELECT user_id FROM users WHERE email = $1',
      [email.toLowerCase()]
    );
    
    if (existingUser.rows.length > 0) {
      await logAuthEvent(null, 'register', false, ipAddress, userAgent, 'Email already registered');
      return res.status(400).json({
        error: 'validation_error',
        message: 'Email already registered',
        field: 'email'
      });
    }
    
    // Hash password
    const passwordHash = await hashPassword(password);
    
    // Create user
    const result = await pool.query(
      `INSERT INTO users (email, password_hash)
       VALUES ($1, $2)
       RETURNING user_id, email, created_at`,
      [email.toLowerCase(), passwordHash]
    );
    
    const user = result.rows[0];
    
    await logAuthEvent(user.user_id, 'register', true, ipAddress, userAgent);
    
    res.status(201).json({
      userID: user.user_id,
      email: user.email,
      message: 'Registration successful'
    });
  } catch (error) {
    console.error('Error during registration:', error);
    await logAuthEvent(null, 'register', false, ipAddress, userAgent, error.message);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to register user'
    });
  }
});

// POST /auth/login - User login
app.post('/auth/login', loginLimiter, async (req, res) => {
  const { email, password } = req.body;
  const ipAddress = req.ip;
  const userAgent = req.headers['user-agent'];
  
  // Validation
  if (!email || !password) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'Email and password are required',
      field: !email ? 'email' : 'password'
    });
  }
  
  try {
    // Lookup user
    const result = await pool.query(
      'SELECT user_id, email, password_hash FROM users WHERE email = $1',
      [email.toLowerCase()]
    );
    
    if (result.rows.length === 0) {
      await logAuthEvent(null, 'failed_login', false, ipAddress, userAgent, 'User not found');
      return res.status(401).json({
        error: 'unauthorized',
        message: 'Invalid credentials'
      });
    }
    
    const user = result.rows[0];
    
    // Verify password
    const isValidPassword = await verifyPassword(user.password_hash, password);
    
    if (!isValidPassword) {
      await logAuthEvent(user.user_id, 'failed_login', false, ipAddress, userAgent, 'Invalid password');
      return res.status(401).json({
        error: 'unauthorized',
        message: 'Invalid credentials'
      });
    }
    
    // Generate tokens
    const accessToken = generateAccessToken(user.user_id, user.email);
    const refreshToken = generateRefreshToken();
    const refreshTokenHash = hashRefreshToken(refreshToken);
    
    // Store session
    await pool.query(
      `INSERT INTO sessions (user_id, refresh_token_hash, expires_at, user_agent, ip_address)
       VALUES ($1, $2, NOW() + INTERVAL '7 days', $3, $4)`,
      [user.user_id, refreshTokenHash, userAgent, ipAddress]
    );
    
    await logAuthEvent(user.user_id, 'login', true, ipAddress, userAgent);
    
    res.json({
      accessToken,
      refreshToken,
      expiresIn: 900, // 15 minutes in seconds
      tokenType: 'Bearer',
      userID: user.user_id
    });
  } catch (error) {
    console.error('Error during login:', error);
    await logAuthEvent(null, 'failed_login', false, ipAddress, userAgent, error.message);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to login'
    });
  }
});

// POST /auth/refresh - Refresh access token
app.post('/auth/refresh', refreshLimiter, async (req, res) => {
  const { refreshToken } = req.body;
  const ipAddress = req.ip;
  const userAgent = req.headers['user-agent'];
  
  if (!refreshToken) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'Refresh token is required',
      field: 'refreshToken'
    });
  }
  
  try {
    const refreshTokenHash = hashRefreshToken(refreshToken);
    
    // Lookup session
    const sessionResult = await pool.query(
      `SELECT session_id, user_id, expires_at, last_used_at
       FROM sessions
       WHERE refresh_token_hash = $1`,
      [refreshTokenHash]
    );
    
    if (sessionResult.rows.length === 0) {
      // REUSE DETECTION: Check if this token was used before (exists in auth_logs but not in sessions)
      // If so, invalidate ALL sessions for potential security breach
      const logResult = await pool.query(
        `SELECT user_id FROM auth_logs 
         WHERE event_type = 'refresh' AND success = true 
         ORDER BY created_at DESC LIMIT 1`
      );
      
      if (logResult.rows.length > 0) {
        const userID = logResult.rows[0].user_id;
        await pool.query('DELETE FROM sessions WHERE user_id = $1', [userID]);
        await logAuthEvent(userID, 'refresh', false, ipAddress, userAgent, 'SECURITY: Refresh token reuse detected - all sessions invalidated');
        
        return res.status(401).json({
          error: 'unauthorized',
          message: 'Invalid refresh token - all sessions have been invalidated for security'
        });
      }
      
      await logAuthEvent(null, 'refresh', false, ipAddress, userAgent, 'Invalid refresh token');
      return res.status(401).json({
        error: 'unauthorized',
        message: 'Invalid refresh token'
      });
    }
    
    const session = sessionResult.rows[0];
    
    // Check if expired
    if (new Date(session.expires_at) < new Date()) {
      await pool.query('DELETE FROM sessions WHERE session_id = $1', [session.session_id]);
      await logAuthEvent(session.user_id, 'refresh', false, ipAddress, userAgent, 'Expired refresh token');
      return res.status(401).json({
        error: 'unauthorized',
        message: 'Refresh token has expired'
      });
    }
    
    // Get user info
    const userResult = await pool.query(
      'SELECT user_id, email FROM users WHERE user_id = $1',
      [session.user_id]
    );
    
    if (userResult.rows.length === 0) {
      return res.status(401).json({
        error: 'unauthorized',
        message: 'User not found'
      });
    }
    
    const user = userResult.rows[0];
    
    // TOKEN ROTATION: Generate new tokens
    const newAccessToken = generateAccessToken(user.user_id, user.email);
    const newRefreshToken = generateRefreshToken();
    const newRefreshTokenHash = hashRefreshToken(newRefreshToken);
    
    // Invalidate old refresh token and store new one
    await pool.query(
      `UPDATE sessions
       SET refresh_token_hash = $1,
           expires_at = NOW() + INTERVAL '7 days',
           last_used_at = NOW(),
           user_agent = $2,
           ip_address = $3
       WHERE session_id = $4`,
      [newRefreshTokenHash, userAgent, ipAddress, session.session_id]
    );
    
    await logAuthEvent(user.user_id, 'refresh', true, ipAddress, userAgent);
    
    res.json({
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresIn: 900,
      tokenType: 'Bearer'
    });
  } catch (error) {
    console.error('Error during token refresh:', error);
    await logAuthEvent(null, 'refresh', false, ipAddress, userAgent, error.message);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to refresh token'
    });
  }
});

// POST /auth/logout - Logout and invalidate session
app.post('/auth/logout', authenticateJWT, async (req, res) => {
  const { refreshToken } = req.body;
  const userID = req.userID;
  const ipAddress = req.ip;
  const userAgent = req.headers['user-agent'];
  
  if (!refreshToken) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'Refresh token is required',
      field: 'refreshToken'
    });
  }
  
  try {
    const refreshTokenHash = hashRefreshToken(refreshToken);
    
    // Delete session
    const result = await pool.query(
      'DELETE FROM sessions WHERE refresh_token_hash = $1 AND user_id = $2 RETURNING session_id',
      [refreshTokenHash, userID]
    );
    
    if (result.rows.length === 0) {
      await logAuthEvent(userID, 'logout', false, ipAddress, userAgent, 'Session not found');
      return res.status(404).json({
        error: 'not_found',
        message: 'Session not found'
      });
    }
    
    await logAuthEvent(userID, 'logout', true, ipAddress, userAgent);
    
    res.json({
      message: 'Logged out successfully'
    });
  } catch (error) {
    console.error('Error during logout:', error);
    await logAuthEvent(userID, 'logout', false, ipAddress, userAgent, error.message);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to logout'
    });
  }
});

// ============================================================================
// PROTECTED ROUTES (with JWT middleware)
// ============================================================================

// Health check endpoint (public)
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'healthy', database: 'connected' });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: error.message });
  }
});

// GET /v1/users/:userID/profile - Fetch user profile (PROTECTED)
app.get('/v1/users/:userID/profile', authenticateJWT, async (req, res) => {
  const { userID } = req.params;
  
  // Verify user can only access their own profile
  if (req.userID !== userID) {
    return res.status(403).json({
      error: 'forbidden',
      message: 'You can only access your own profile'
    });
  }

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
    console.error('Error fetching profile:', error);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to fetch profile'
    });
  }
});

// PUT /v1/users/:userID/profile - Create or update user profile (PROTECTED)
app.put('/v1/users/:userID/profile', authenticateJWT, async (req, res) => {
  const { userID } = req.params;
  const { screenName, birthday, avatarURL } = req.body;
  
  // Verify user can only update their own profile
  if (req.userID !== userID) {
    return res.status(403).json({
      error: 'forbidden',
      message: 'You can only update your own profile'
    });
  }

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

// DELETE /v1/users/:userID/profile - Delete user profile (PROTECTED)
app.delete('/v1/users/:userID/profile', authenticateJWT, async (req, res) => {
  const { userID } = req.params;
  
  // Verify user can only delete their own profile
  if (req.userID !== userID) {
    return res.status(403).json({
      error: 'forbidden',
      message: 'You can only delete your own profile'
    });
  }

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

// GET /v1/users/:userID/identity-status - Check identity setup (PROTECTED)
app.get('/v1/users/:userID/identity-status', authenticateJWT, async (req, res) => {
  const { userID } = req.params;
  
  // Verify user can only check their own status
  if (req.userID !== userID) {
    return res.status(403).json({
      error: 'forbidden',
      message: 'You can only check your own identity status'
    });
  }

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

// GET /v1/items - Fetch all items (PROTECTED)
app.get('/v1/items', authenticateJWT, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, description, is_completed, created_at, updated_at FROM items ORDER BY created_at DESC'
    );

    const items = result.rows.map(row => ({
      id: row.id,
      name: row.name,
      description: row.description,
      isCompleted: row.is_completed,
      createdAt: row.created_at.toISOString(),
      updatedAt: row.updated_at.toISOString()
    }));

    res.json(items);
  } catch (error) {
    console.error('Error fetching items:', error);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to fetch items'
    });
  }
});

// POST /v1/items - Create a new item (PROTECTED)
app.post('/v1/items', authenticateJWT, async (req, res) => {
  const { name, description, isCompleted } = req.body;

  if (!name || name.trim().length === 0) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'name is required',
      field: 'name'
    });
  }

  try {
    const result = await pool.query(
      `INSERT INTO items (name, description, is_completed)
       VALUES ($1, $2, $3)
       RETURNING id, name, description, is_completed, created_at, updated_at`,
      [name.trim(), description || null, isCompleted || false]
    );

    const item = result.rows[0];

    const response = {
      id: item.id,
      name: item.name,
      description: item.description,
      isCompleted: item.is_completed,
      createdAt: item.created_at.toISOString(),
      updatedAt: item.updated_at.toISOString()
    };

    res.status(201).json(response);
  } catch (error) {
    console.error('Error creating item:', error);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to create item'
    });
  }
});

// PUT /v1/items/:id - Update an item (PROTECTED)
app.put('/v1/items/:id', authenticateJWT, async (req, res) => {
  const { id } = req.params;
  const { name, description, isCompleted } = req.body;

  if (!name || name.trim().length === 0) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'name is required',
      field: 'name'
    });
  }

  try {
    const result = await pool.query(
      `UPDATE items
       SET name = $1, description = $2, is_completed = $3, updated_at = NOW()
       WHERE id = $4
       RETURNING id, name, description, is_completed, created_at, updated_at`,
      [name.trim(), description || null, isCompleted || false, id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'item_not_found',
        message: 'Item not found'
      });
    }

    const item = result.rows[0];

    const response = {
      id: item.id,
      name: item.name,
      description: item.description,
      isCompleted: item.is_completed,
      createdAt: item.created_at.toISOString(),
      updatedAt: item.updated_at.toISOString()
    };

    res.json(response);
  } catch (error) {
    console.error('Error updating item:', error);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to update item'
    });
  }
});

// DELETE /v1/items/:id - Delete an item (PROTECTED)
app.delete('/v1/items/:id', authenticateJWT, async (req, res) => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      'DELETE FROM items WHERE id = $1 RETURNING id',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'item_not_found',
        message: 'Item not found'
      });
    }

    res.status(204).send();
  } catch (error) {
    console.error('Error deleting item:', error);
    res.status(500).json({
      error: 'internal_error',
      message: 'Failed to delete item'
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
  console.log(`JWT Authentication enabled`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, closing connections...');
  if (redisClient) {
    await redisClient.quit();
  }
  await pool.end();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('SIGINT received, closing connections...');
  if (redisClient) {
    await redisClient.quit();
  }
  await pool.end();
  process.exit(0);
});
