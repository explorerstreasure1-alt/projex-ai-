-- PROJEX AI - Supabase Database Schema
-- Run this in Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users with additional fields)
CREATE TABLE IF NOT EXISTS public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Projects table
CREATE TABLE IF NOT EXISTS public.projects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'active', -- 'active', 'completed', 'archived'
  color TEXT DEFAULT '#3b82f6',
  budget NUMERIC DEFAULT 0,
  progress INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tasks table
CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT DEFAULT 'medium', -- 'low', 'medium', 'high'
  status TEXT DEFAULT 'todo', -- 'todo', 'in_progress', 'done'
  assignee TEXT DEFAULT '',
  date TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Meetings table
CREATE TABLE IF NOT EXISTS public.meetings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  date TEXT,
  time TEXT,
  duration INTEGER DEFAULT 60,
  duration_preset TEXT DEFAULT '60', -- '15', '30', '45', '60', '90', '120', 'custom'
  timezone TEXT DEFAULT 'Europe/Istanbul', -- IANA timezone
  recurrence TEXT DEFAULT 'none', -- 'none', 'daily', 'weekly', 'biweekly', 'monthly', 'custom'
  recurrence_end_date TEXT, -- YYYY-MM-DD
  meeting_link TEXT, -- External meeting link (Zoom, Google Meet, etc.)
  attendees JSONB DEFAULT '[]', -- Array of participant objects
  location TEXT, -- Physical location or virtual
  description TEXT,
  -- Category 3: In-meeting features
  recording_status TEXT DEFAULT 'none', -- 'none', 'recording', 'paused', 'completed'
  recording_url TEXT, -- URL to recorded meeting
  chat_messages JSONB DEFAULT '[]', -- Meeting chat history
  reactions JSONB DEFAULT '[]', -- Meeting reactions (raise hand, thumbs up, etc.)
  polls JSONB DEFAULT '[]', -- Meeting polls
  whiteboard_data JSONB, -- Whiteboard content
  transcription TEXT, -- Meeting transcription text
  -- End Category 3
  -- Category 4: Post-meeting features
  summary TEXT, -- AI-generated meeting summary
  action_items JSONB DEFAULT '[]', -- Action items extracted from meeting
  attendance_report JSONB, -- Attendance report (who joined, duration, etc.)
  export_formats TEXT DEFAULT 'json', -- Available export formats: 'json', 'pdf', 'doc', 'md'
  meeting_notes TEXT, -- Additional meeting notes
  -- End Category 4
  -- Category 6: Notifications
  reminder_minutes INTEGER DEFAULT 15, -- Reminder before meeting (minutes): 0 (none), 5, 15, 30, 60
  notification_sent BOOLEAN DEFAULT false, -- Whether notification was sent
  late_warning_sent BOOLEAN DEFAULT false, -- Whether late warning was sent
  notification_preferences JSONB DEFAULT '{}', -- User notification preferences (email, push, sound)
  -- End Category 6
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Meeting participants table (for detailed tracking)
CREATE TABLE IF NOT EXISTS public.meeting_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meeting_id UUID REFERENCES public.meetings(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE, -- NULL for guests
  email TEXT, -- For guest participants
  name TEXT, -- Display name
  role TEXT DEFAULT 'participant', -- 'organizer', 'presenter', 'participant', 'assistant'
  status TEXT DEFAULT 'invited', -- 'invited', 'accepted', 'declined', 'tentative'
  joined_at TIMESTAMP WITH TIME ZONE,
  left_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Integrations table (for Category 5)
CREATE TABLE IF NOT EXISTS public.integrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  integration_type TEXT NOT NULL, -- 'calendar', 'storage', 'project', 'crm', 'messaging'
  provider TEXT NOT NULL, -- 'google', 'outlook', 'dropbox', 'jira', 'trello', 'asana', 'hubspot', 'salesforce', 'slack', 'teams'
  config JSONB, -- Integration-specific configuration (API keys, webhooks, etc.)
  enabled BOOLEAN DEFAULT true,
  last_sync TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Team table
CREATE TABLE IF NOT EXISTS public.team (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  role TEXT,
  dept TEXT,
  email TEXT,
  initials TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Posts table (social feed)
CREATE TABLE IF NOT EXISTS public.posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  author TEXT NOT NULL,
  content TEXT NOT NULL,
  image TEXT,
  likes INTEGER DEFAULT 0,
  comments INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comments table
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  author TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notes table
CREATE TABLE IF NOT EXISTS public.notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT,
  tags TEXT[], -- array of tags
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Images table
CREATE TABLE IF NOT EXISTS public.images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  prompt TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Resources table
CREATE TABLE IF NOT EXISTS public.resources (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  url TEXT,
  description TEXT,
  type TEXT DEFAULT 'link',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Budget table
CREATE TABLE IF NOT EXISTS public.budget (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  amount NUMERIC,
  spent NUMERIC DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Risks table
CREATE TABLE IF NOT EXISTS public.risks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  probability TEXT DEFAULT 'medium',
  impact TEXT DEFAULT 'medium',
  mitigation TEXT,
  status TEXT DEFAULT 'open',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activity log table
CREATE TABLE IF NOT EXISTS public.activity (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  icon TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Voice notes table
CREATE TABLE IF NOT EXISTS public.voice_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  transcript TEXT,
  analysis TEXT,
  provider TEXT DEFAULT 'groq',
  audio_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User settings table
CREATE TABLE IF NOT EXISTS public.user_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE UNIQUE,
  pomodoro_goal INTEGER DEFAULT 4,
  pomodoro_duration INTEGER DEFAULT 25,
  break_duration INTEGER DEFAULT 5,
  ai_provider TEXT DEFAULT 'groq',
  theme TEXT DEFAULT 'dark',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscription table
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE UNIQUE,
  plan TEXT DEFAULT 'trial', -- 'trial', 'free', 'pro'
  trial_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  trial_days INTEGER DEFAULT 15,
  pro_expiry TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON public.projects(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON public.tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_meetings_user_id ON public.meetings(user_id);
CREATE INDEX IF NOT EXISTS idx_team_user_id ON public.team(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_notes_user_id ON public.notes(user_id);
CREATE INDEX IF NOT EXISTS idx_images_user_id ON public.images(user_id);
CREATE INDEX IF NOT EXISTS idx_resources_user_id ON public.resources(user_id);
CREATE INDEX IF NOT EXISTS idx_budget_user_id ON public.budget(user_id);
CREATE INDEX IF NOT EXISTS idx_risks_user_id ON public.risks(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_user_id ON public.activity(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_notes_user_id ON public.voice_notes(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON public.subscriptions(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.risks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies: Users can only access their own data
-- Drop any previously created policies (including Turkish-named ones)
DROP POLICY IF EXISTS "Kullanıcılar kendi profilini görebilir" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can view own projects" ON public.projects;
CREATE POLICY "Users can view own projects" ON public.projects
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own projects" ON public.projects;
CREATE POLICY "Users can insert own projects" ON public.projects
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own projects" ON public.projects;
CREATE POLICY "Users can update own projects" ON public.projects
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own projects" ON public.projects;
CREATE POLICY "Users can delete own projects" ON public.projects
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own tasks" ON public.tasks;
CREATE POLICY "Users can view own tasks" ON public.tasks
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own tasks" ON public.tasks;
CREATE POLICY "Users can insert own tasks" ON public.tasks
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own tasks" ON public.tasks;
CREATE POLICY "Users can update own tasks" ON public.tasks
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own tasks" ON public.tasks;
CREATE POLICY "Users can delete own tasks" ON public.tasks
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own meetings" ON public.meetings;
CREATE POLICY "Users can view own meetings" ON public.meetings
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own meetings" ON public.meetings;
CREATE POLICY "Users can insert own meetings" ON public.meetings
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own meetings" ON public.meetings;
CREATE POLICY "Users can update own meetings" ON public.meetings
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own meetings" ON public.meetings;
CREATE POLICY "Users can delete own meetings" ON public.meetings
  FOR DELETE USING (auth.uid() = user_id);

-- Meeting participants RLS
DROP POLICY IF EXISTS "Users can view meeting participants" ON public.meeting_participants;
CREATE POLICY "Users can view meeting participants" ON public.meeting_participants
  FOR SELECT USING (
    auth.uid() IN (
      SELECT user_id FROM public.meetings WHERE id = meeting_participants.meeting_id
    )
  );
DROP POLICY IF EXISTS "Users can insert meeting participants" ON public.meeting_participants;
CREATE POLICY "Users can insert meeting participants" ON public.meeting_participants
  FOR INSERT WITH CHECK (
    auth.uid() IN (
      SELECT user_id FROM public.meetings WHERE id = meeting_participants.meeting_id
    )
  );
DROP POLICY IF EXISTS "Users can update meeting participants" ON public.meeting_participants;
CREATE POLICY "Users can update meeting participants" ON public.meeting_participants
  FOR UPDATE USING (
    auth.uid() IN (
      SELECT user_id FROM public.meetings WHERE id = meeting_participants.meeting_id
    )
  );
DROP POLICY IF EXISTS "Users can delete meeting participants" ON public.meeting_participants;
CREATE POLICY "Users can delete meeting participants" ON public.meeting_participants
  FOR DELETE USING (
    auth.uid() IN (
      SELECT user_id FROM public.meetings WHERE id = meeting_participants.meeting_id
    )
  );

-- Integrations RLS
DROP POLICY IF EXISTS "Users can view own integrations" ON public.integrations;
CREATE POLICY "Users can view own integrations" ON public.integrations
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own integrations" ON public.integrations;
CREATE POLICY "Users can insert own integrations" ON public.integrations
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own integrations" ON public.integrations;
CREATE POLICY "Users can update own integrations" ON public.integrations
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own integrations" ON public.integrations;
CREATE POLICY "Users can delete own integrations" ON public.integrations
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own team" ON public.team;
CREATE POLICY "Users can view own team" ON public.team
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own team" ON public.team;
CREATE POLICY "Users can insert own team" ON public.team
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own team" ON public.team;
CREATE POLICY "Users can update own team" ON public.team
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own team" ON public.team;
CREATE POLICY "Users can delete own team" ON public.team
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own posts" ON public.posts;
CREATE POLICY "Users can view own posts" ON public.posts
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own posts" ON public.posts;
CREATE POLICY "Users can insert own posts" ON public.posts
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
CREATE POLICY "Users can update own posts" ON public.posts
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own posts" ON public.posts;
CREATE POLICY "Users can delete own posts" ON public.posts
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own comments" ON public.comments;
CREATE POLICY "Users can view own comments" ON public.comments
  FOR SELECT USING (auth.uid() = (SELECT user_id FROM public.posts WHERE id = post_id));
DROP POLICY IF EXISTS "Users can insert own comments" ON public.comments;
CREATE POLICY "Users can insert own comments" ON public.comments
  FOR INSERT WITH CHECK (auth.uid() = (SELECT user_id FROM public.posts WHERE id = post_id));

DROP POLICY IF EXISTS "Users can view own notes" ON public.notes;
CREATE POLICY "Users can view own notes" ON public.notes
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own notes" ON public.notes;
CREATE POLICY "Users can insert own notes" ON public.notes
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own notes" ON public.notes;
CREATE POLICY "Users can update own notes" ON public.notes
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own notes" ON public.notes;
CREATE POLICY "Users can delete own notes" ON public.notes
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own images" ON public.images;
CREATE POLICY "Users can view own images" ON public.images
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own images" ON public.images;
CREATE POLICY "Users can insert own images" ON public.images
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own images" ON public.images;
CREATE POLICY "Users can delete own images" ON public.images
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own resources" ON public.resources;
CREATE POLICY "Users can view own resources" ON public.resources
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own resources" ON public.resources;
CREATE POLICY "Users can insert own resources" ON public.resources
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own resources" ON public.resources;
CREATE POLICY "Users can update own resources" ON public.resources
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own resources" ON public.resources;
CREATE POLICY "Users can delete own resources" ON public.resources
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own budget" ON public.budget;
CREATE POLICY "Users can view own budget" ON public.budget
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own budget" ON public.budget;
CREATE POLICY "Users can insert own budget" ON public.budget
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own budget" ON public.budget;
CREATE POLICY "Users can update own budget" ON public.budget
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own budget" ON public.budget;
CREATE POLICY "Users can delete own budget" ON public.budget
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own risks" ON public.risks;
CREATE POLICY "Users can view own risks" ON public.risks
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own risks" ON public.risks;
CREATE POLICY "Users can insert own risks" ON public.risks
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own risks" ON public.risks;
CREATE POLICY "Users can update own risks" ON public.risks
  FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own risks" ON public.risks;
CREATE POLICY "Users can delete own risks" ON public.risks
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own activity" ON public.activity;
CREATE POLICY "Users can view own activity" ON public.activity
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own activity" ON public.activity;
CREATE POLICY "Users can insert own activity" ON public.activity
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own voice notes" ON public.voice_notes;
CREATE POLICY "Users can view own voice notes" ON public.voice_notes
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own voice notes" ON public.voice_notes;
CREATE POLICY "Users can insert own voice notes" ON public.voice_notes
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete own voice notes" ON public.voice_notes;
CREATE POLICY "Users can delete own voice notes" ON public.voice_notes
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own settings" ON public.user_settings;
CREATE POLICY "Users can view own settings" ON public.user_settings
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own settings" ON public.user_settings;
CREATE POLICY "Users can insert own settings" ON public.user_settings
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own settings" ON public.user_settings;
CREATE POLICY "Users can update own settings" ON public.user_settings
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own subscription" ON public.subscriptions;
CREATE POLICY "Users can view own subscription" ON public.subscriptions
  FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own subscription" ON public.subscriptions;
CREATE POLICY "Users can insert own subscription" ON public.subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own subscription" ON public.subscriptions;
CREATE POLICY "Users can update own subscription" ON public.subscriptions
  FOR UPDATE USING (auth.uid() = user_id);

-- Function to create user profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name');

  INSERT INTO public.user_settings (user_id)
  VALUES (NEW.id);

  INSERT INTO public.subscriptions (user_id)
  VALUES (NEW.id);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call handle_new_user on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ═══════════════════════════════════════════════════════════════
-- MIGRATION HELPERS - Run these if you encounter schema errors
-- ═══════════════════════════════════════════════════════════════

-- Add missing columns to existing tables
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS budget NUMERIC DEFAULT 0;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS progress INTEGER DEFAULT 0;
ALTER TABLE public.tasks ADD COLUMN IF NOT EXISTS assignee TEXT DEFAULT '';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS duration INTEGER DEFAULT 60;
ALTER TABLE public.posts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Category 1: Meeting Planning & Scheduling columns
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS duration_preset TEXT DEFAULT '60';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS timezone TEXT DEFAULT 'Europe/Istanbul';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS recurrence TEXT DEFAULT 'none';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS recurrence_end_date TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS meeting_link TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS attendees JSONB DEFAULT '[]';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS location TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS description TEXT;

-- Category 2: Meeting participants table
CREATE TABLE IF NOT EXISTS public.meeting_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meeting_id UUID REFERENCES public.meetings(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  email TEXT,
  name TEXT,
  role TEXT DEFAULT 'participant',
  status TEXT DEFAULT 'invited',
  joined_at TIMESTAMP WITH TIME ZONE,
  left_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Category 3: In-meeting features
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS recording_status TEXT DEFAULT 'none';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS recording_url TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS chat_messages JSONB DEFAULT '[]';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS reactions JSONB DEFAULT '[]';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS polls JSONB DEFAULT '[]';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS whiteboard_data JSONB;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS transcription TEXT;

-- Category 4: Post-meeting features
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS summary TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS action_items JSONB DEFAULT '[]';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS attendance_report JSONB;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS export_formats TEXT DEFAULT 'json';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS meeting_notes TEXT;

-- Category 6: Notifications
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS reminder_minutes INTEGER DEFAULT 15;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS notification_sent BOOLEAN DEFAULT false;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS late_warning_sent BOOLEAN DEFAULT false;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS notification_preferences JSONB DEFAULT '{}';

-- Category 5: Integrations table
CREATE TABLE IF NOT EXISTS public.integrations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  integration_type TEXT NOT NULL,
  provider TEXT NOT NULL,
  config JSONB,
  enabled BOOLEAN DEFAULT true,
  last_sync TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
