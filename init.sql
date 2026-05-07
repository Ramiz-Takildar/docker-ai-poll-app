-- SQL Script to Initialize PostgreSQL Database
-- This script creates the votes table for the AI Poll application
-- Run this script after starting the PostgreSQL container

-- Create votes table if it doesn't exist
CREATE TABLE IF NOT EXISTS votes (
    -- Primary key: unique identifier for each vote
    id SERIAL PRIMARY KEY,
    
    -- Vote option: 'yes' or 'no'
    option VARCHAR(10) NOT NULL,
    
    -- Timestamp when vote was cast (defaults to current UTC time)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Index on option for faster queries when counting votes
    CONSTRAINT valid_option CHECK (option IN ('yes', 'no'))
);

-- Create index on option column for faster vote counting
-- This improves query performance when filtering by 'yes' or 'no'
CREATE INDEX IF NOT EXISTS idx_votes_option ON votes(option);

-- Create index on created_at for time-based queries
CREATE INDEX IF NOT EXISTS idx_votes_created_at ON votes(created_at);

-- Insert sample data for testing (optional)
-- Comment out if you want to start with zero votes
-- INSERT INTO votes (option) VALUES ('yes');
-- INSERT INTO votes (option) VALUES ('no');
-- INSERT INTO votes (option) VALUES ('yes');
