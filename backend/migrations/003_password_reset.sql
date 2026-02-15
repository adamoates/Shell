-- Migration: Add password reset token fields to users table
-- Version: 003
-- Created: 2026-02-14

-- Add reset token columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token_hash VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token_expires_at TIMESTAMP WITH TIME ZONE;

-- Add index for faster token lookups
CREATE INDEX IF NOT EXISTS idx_users_reset_token_hash ON users(reset_token_hash);

-- Log migration
INSERT INTO schema_migrations (version, description, applied_at)
VALUES ('003', 'Add password reset token fields', NOW())
ON CONFLICT (version) DO NOTHING;
