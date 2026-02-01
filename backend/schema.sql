-- User Profiles table
CREATE TABLE IF NOT EXISTS user_profiles (
    user_id VARCHAR(255) PRIMARY KEY,
    screen_name VARCHAR(20) NOT NULL,
    birthday DATE NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_screen_name ON user_profiles(screen_name);

-- Items table
CREATE TABLE IF NOT EXISTS items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Index for faster queries by completion status
CREATE INDEX IF NOT EXISTS idx_items_is_completed ON items(is_completed);

-- Index for faster queries by creation date
CREATE INDEX IF NOT EXISTS idx_items_created_at ON items(created_at DESC);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-update updated_at for user_profiles
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to auto-update updated_at for items
CREATE TRIGGER update_items_updated_at
    BEFORE UPDATE ON items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
