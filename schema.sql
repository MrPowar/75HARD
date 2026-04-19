-- Run this in your Supabase SQL Editor

-- 1. Create custom types
CREATE TYPE user_status AS ENUM ('active', 'failed', 'completed');

-- 2. Users extension table (hooks into auth.users optionally, but handled standalone here for simplicity)
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  name TEXT,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  current_day INTEGER NOT NULL DEFAULT 1,
  status user_status NOT NULL DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Daily Logs
CREATE TABLE daily_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  date DATE NOT NULL,
  tasks BOOLEAN[] NOT NULL DEFAULT '{false, false, false, false, false, false}',
  sleep_hours NUMERIC DEFAULT 0,
  completed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, date)
);

-- 4. Failures
CREATE TABLE failures (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) NOT NULL,
  date DATE NOT NULL,
  reason TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Row Level Security (RLS) policies
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE failures ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert/select/update their own data
CREATE POLICY "Users can manage their own profile" 
  ON users FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can manage their own logs" 
  ON daily_logs FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own failures" 
  ON failures FOR ALL USING (auth.uid() = user_id);
