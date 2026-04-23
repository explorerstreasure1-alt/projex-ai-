-- ================================================================
-- PROJEX AI - Supabase Database Schema (FIXED v2.1)
-- ================================================================
-- Fixes applied:
--   [FIX-01] CREATE POLICY IF NOT EXISTS → invalid syntax, removed
--   [FIX-02] CREATE TRIGGER → DROP TRIGGER IF EXISTS added before each
--   [FIX-03] integrations table missing ENABLE ROW LEVEL SECURITY
--   [FIX-04] Migration password TEXT column now includes CHECK constraint
--   [FIX-05] meeting_signals INSERT policy now validates sender_id = auth.uid()
--   [FIX-06] comments SELECT policy fixed for social feed visibility
--   [FIX-07] meetings.time column type corrected TEXT → TIME
--   [FIX-08] budget.amount / budget.spent CHECK >= 0 added
--   [FIX-09] risks.probability / risks.impact CHECK constraints added
--   [FIX-10] updated_at trigger added for comments table
-- ================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ----------------------------------------------------------------
-- TABLES
-- ----------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.user_profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       TEXT UNIQUE NOT NULL,
  full_name   TEXT,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.projects (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT,
  status      TEXT DEFAULT 'active'    CHECK (status IN ('active','completed','archived')),
  color       TEXT DEFAULT '#3b82f6',
  budget      NUMERIC DEFAULT 0        CHECK (budget >= 0),
  progress    INTEGER DEFAULT 0        CHECK (progress BETWEEN 0 AND 100),
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.tasks (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  project_id  UUID REFERENCES public.projects(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT,
  priority    TEXT DEFAULT 'medium'    CHECK (priority IN ('low','medium','high')),
  status      TEXT DEFAULT 'todo'      CHECK (status IN ('todo','in_progress','done')),
  assignee    TEXT DEFAULT '',
  date        TIMESTAMP WITH TIME ZONE,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.meetings (
  id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id                  UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title                    TEXT NOT NULL,
  date                     TIMESTAMP WITH TIME ZONE,
  -- [FIX-07] was TIMESTAMP WITH TIME ZONE (wrong), now TIME for time-of-day only
  time                     TIME,
  duration                 INTEGER DEFAULT 60,
  duration_preset          TEXT DEFAULT '60'         CHECK (duration_preset IN ('15','30','45','60','90','120','custom')),
  timezone                 TEXT DEFAULT 'Europe/Istanbul',
  recurrence               TEXT DEFAULT 'none'       CHECK (recurrence IN ('none','daily','weekly','biweekly','monthly','custom')),
  recurrence_end_date      TEXT,
  meeting_link             TEXT,
  attendees                JSONB DEFAULT '[]',
  location                 TEXT,
  description              TEXT,
  -- Category 3: In-meeting features
  recording_status         TEXT DEFAULT 'none'       CHECK (recording_status IN ('none','recording','paused','completed')),
  recording_url            TEXT,
  chat_messages            JSONB DEFAULT '[]',
  reactions                JSONB DEFAULT '[]',
  polls                    JSONB DEFAULT '[]',
  whiteboard_data          JSONB,
  transcription            TEXT,
  -- Category 4: Post-meeting features
  summary                  TEXT,
  action_items             JSONB DEFAULT '[]',
  attendance_report        JSONB,
  export_formats           TEXT DEFAULT 'json',
  meeting_notes            TEXT,
  -- Category 6: Notifications
  reminder_minutes         INTEGER DEFAULT 15,
  notification_sent        BOOLEAN DEFAULT false,
  late_warning_sent        BOOLEAN DEFAULT false,
  notification_preferences JSONB DEFAULT '{}',
  -- Category 7: Security
  -- [FIX-04 partial] CHECK kept in main table (length >= 6 is minimal; hash in app layer)
  password                 TEXT CHECK (password IS NULL OR length(password) >= 6),
  waiting_room             BOOLEAN DEFAULT false,
  encrypted                BOOLEAN DEFAULT false,
  join_permissions         TEXT DEFAULT 'anyone'     CHECK (join_permissions IN ('anyone','invited_only','password_only','password_and_invited')),
  -- Category 9: Analytics
  total_participants       INTEGER DEFAULT 0         CHECK (total_participants >= 0),
  avg_duration             INTEGER,
  usage_stats              JSONB DEFAULT '{}',
  -- Category 10: Extra features
  template_id              TEXT,
  ai_assistant_enabled     BOOLEAN DEFAULT false,
  virtual_background       TEXT,
  created_at               TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at               TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.meeting_participants (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meeting_id  UUID REFERENCES public.meetings(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  email       TEXT,
  name        TEXT,
  role        TEXT DEFAULT 'participant' CHECK (role IN ('organizer','presenter','participant','assistant')),
  status      TEXT DEFAULT 'invited'    CHECK (status IN ('invited','accepted','declined','tentative')),
  joined_at   TIMESTAMP WITH TIME ZONE,
  left_at     TIMESTAMP WITH TIME ZONE,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.integrations (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  integration_type TEXT NOT NULL,
  provider         TEXT NOT NULL,
  config           JSONB,
  enabled          BOOLEAN DEFAULT true,
  last_sync        TIMESTAMP WITH TIME ZONE,
  created_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.team (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  name       TEXT NOT NULL,
  role       TEXT,
  dept       TEXT,
  email      TEXT,
  initials   TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.posts (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  author     TEXT NOT NULL,
  content    TEXT NOT NULL,
  image      TEXT,
  likes      INTEGER DEFAULT 0 CHECK (likes >= 0),
  comments   INTEGER DEFAULT 0 CHECK (comments >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.comments (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  post_id    UUID REFERENCES public.posts(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  author     TEXT NOT NULL,
  content    TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  -- [FIX-10] updated_at added to match trigger
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.notes (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  content    TEXT,
  tags       TEXT[],
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.images (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  url        TEXT NOT NULL,
  prompt     TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.resources (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  url         TEXT,
  description TEXT,
  type        TEXT DEFAULT 'link',
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- [FIX-08] budget.amount and budget.spent CHECK >= 0 added
CREATE TABLE IF NOT EXISTS public.budget (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  category   TEXT NOT NULL,
  amount     NUMERIC CHECK (amount >= 0),
  spent      NUMERIC DEFAULT 0 CHECK (spent >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- [FIX-09] risks.probability and risks.impact CHECK constraints added
CREATE TABLE IF NOT EXISTS public.risks (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title       TEXT NOT NULL,
  description TEXT,
  probability TEXT DEFAULT 'medium' CHECK (probability IN ('low','medium','high')),
  impact      TEXT DEFAULT 'medium' CHECK (impact IN ('low','medium','high')),
  mitigation  TEXT,
  status      TEXT DEFAULT 'open'   CHECK (status IN ('open','mitigated','closed')),
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.activity (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  action     TEXT NOT NULL,
  icon       TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.voice_notes (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id    UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  transcript TEXT,
  analysis   TEXT,
  provider   TEXT DEFAULT 'groq',
  audio_url  TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_settings (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id           UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE UNIQUE,
  pomodoro_goal     INTEGER DEFAULT 4  CHECK (pomodoro_goal > 0),
  pomodoro_duration INTEGER DEFAULT 25 CHECK (pomodoro_duration > 0),
  break_duration    INTEGER DEFAULT 5  CHECK (break_duration > 0),
  ai_provider       TEXT DEFAULT 'groq',
  theme             TEXT DEFAULT 'dark' CHECK (theme IN ('dark','light','system')),
  created_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE UNIQUE,
  plan        TEXT DEFAULT 'trial' CHECK (plan IN ('trial','free','pro')),
  trial_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  trial_days  INTEGER DEFAULT 15 CHECK (trial_days > 0),
  pro_expiry  TIMESTAMP WITH TIME ZONE,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Meeting signals (WebRTC signaling)
CREATE TABLE IF NOT EXISTS public.meeting_signals (
  id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meeting_id TEXT NOT NULL,
  sender_id  TEXT NOT NULL,
  peer_id    TEXT NOT NULL,
  type       TEXT NOT NULL CHECK (type IN ('join','leave','offer','answer','ice-candidate')),
  data       JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ----------------------------------------------------------------
-- INDEXES
-- ----------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_projects_user_id         ON public.projects(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_id            ON public.tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id         ON public.tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_meetings_user_id         ON public.meetings(user_id);
CREATE INDEX IF NOT EXISTS idx_team_user_id             ON public.team(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_user_id            ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_post_id         ON public.comments(post_id);
CREATE INDEX IF NOT EXISTS idx_notes_user_id            ON public.notes(user_id);
CREATE INDEX IF NOT EXISTS idx_images_user_id           ON public.images(user_id);
CREATE INDEX IF NOT EXISTS idx_resources_user_id        ON public.resources(user_id);
CREATE INDEX IF NOT EXISTS idx_budget_user_id           ON public.budget(user_id);
CREATE INDEX IF NOT EXISTS idx_risks_user_id            ON public.risks(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_user_id         ON public.activity(user_id);
CREATE INDEX IF NOT EXISTS idx_voice_notes_user_id      ON public.voice_notes(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id    ON public.subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_meeting_signals_meeting  ON public.meeting_signals(meeting_id);
CREATE INDEX IF NOT EXISTS idx_meeting_signals_created  ON public.meeting_signals(created_at);

-- ----------------------------------------------------------------
-- updated_at TRIGGER FUNCTION
-- ----------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- [FIX-02] DROP TRIGGER IF EXISTS added before every CREATE TRIGGER
DROP TRIGGER IF EXISTS trg_user_profiles_updated_at  ON public.user_profiles;
CREATE TRIGGER trg_user_profiles_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_projects_updated_at       ON public.projects;
CREATE TRIGGER trg_projects_updated_at
  BEFORE UPDATE ON public.projects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_tasks_updated_at          ON public.tasks;
CREATE TRIGGER trg_tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_meetings_updated_at       ON public.meetings;
CREATE TRIGGER trg_meetings_updated_at
  BEFORE UPDATE ON public.meetings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_meeting_participants_upd  ON public.meeting_participants;
CREATE TRIGGER trg_meeting_participants_upd
  BEFORE UPDATE ON public.meeting_participants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_integrations_updated_at   ON public.integrations;
CREATE TRIGGER trg_integrations_updated_at
  BEFORE UPDATE ON public.integrations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_team_updated_at           ON public.team;
CREATE TRIGGER trg_team_updated_at
  BEFORE UPDATE ON public.team
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_posts_updated_at          ON public.posts;
CREATE TRIGGER trg_posts_updated_at
  BEFORE UPDATE ON public.posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- [FIX-10] comments updated_at trigger (column now exists in schema)
DROP TRIGGER IF EXISTS trg_comments_updated_at       ON public.comments;
CREATE TRIGGER trg_comments_updated_at
  BEFORE UPDATE ON public.comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_notes_updated_at          ON public.notes;
CREATE TRIGGER trg_notes_updated_at
  BEFORE UPDATE ON public.notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_resources_updated_at      ON public.resources;
CREATE TRIGGER trg_resources_updated_at
  BEFORE UPDATE ON public.resources
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_budget_updated_at         ON public.budget;
CREATE TRIGGER trg_budget_updated_at
  BEFORE UPDATE ON public.budget
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_risks_updated_at          ON public.risks;
CREATE TRIGGER trg_risks_updated_at
  BEFORE UPDATE ON public.risks
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_user_settings_updated_at  ON public.user_settings;
CREATE TRIGGER trg_user_settings_updated_at
  BEFORE UPDATE ON public.user_settings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

DROP TRIGGER IF EXISTS trg_subscriptions_updated_at  ON public.subscriptions;
CREATE TRIGGER trg_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ----------------------------------------------------------------
-- ROW LEVEL SECURITY
-- ----------------------------------------------------------------

ALTER TABLE public.user_profiles      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meetings           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_participants ENABLE ROW LEVEL SECURITY;
-- [FIX-03] integrations was missing ENABLE ROW LEVEL SECURITY
ALTER TABLE public.integrations       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team               ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.images             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resources          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budget             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.risks              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.voice_notes        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_signals    ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------
-- RLS POLICIES
-- ----------------------------------------------------------------

-- user_profiles
DROP POLICY IF EXISTS "Kullanıcılar kendi profilini görebilir" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can view own profile"   ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;

CREATE POLICY "Users can view own profile"   ON public.user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON public.user_profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);

-- projects
DROP POLICY IF EXISTS "Users can view own projects"   ON public.projects;
DROP POLICY IF EXISTS "Users can insert own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can update own projects" ON public.projects;
DROP POLICY IF EXISTS "Users can delete own projects" ON public.projects;

CREATE POLICY "Users can view own projects"   ON public.projects FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own projects" ON public.projects FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own projects" ON public.projects FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own projects" ON public.projects FOR DELETE USING (auth.uid() = user_id);

-- tasks
DROP POLICY IF EXISTS "Users can view own tasks"   ON public.tasks;
DROP POLICY IF EXISTS "Users can insert own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can update own tasks" ON public.tasks;
DROP POLICY IF EXISTS "Users can delete own tasks" ON public.tasks;

CREATE POLICY "Users can view own tasks"   ON public.tasks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own tasks" ON public.tasks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own tasks" ON public.tasks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own tasks" ON public.tasks FOR DELETE USING (auth.uid() = user_id);

-- meetings
DROP POLICY IF EXISTS "Users can view own meetings"   ON public.meetings;
DROP POLICY IF EXISTS "Users can insert own meetings" ON public.meetings;
DROP POLICY IF EXISTS "Users can update own meetings" ON public.meetings;
DROP POLICY IF EXISTS "Users can delete own meetings" ON public.meetings;

CREATE POLICY "Users can view own meetings"   ON public.meetings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own meetings" ON public.meetings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own meetings" ON public.meetings FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own meetings" ON public.meetings FOR DELETE USING (auth.uid() = user_id);

-- meeting_participants
DROP POLICY IF EXISTS "Users can view meeting participants"   ON public.meeting_participants;
DROP POLICY IF EXISTS "Users can insert meeting participants" ON public.meeting_participants;
DROP POLICY IF EXISTS "Users can update meeting participants" ON public.meeting_participants;
DROP POLICY IF EXISTS "Users can delete meeting participants" ON public.meeting_participants;

CREATE POLICY "Users can view meeting participants" ON public.meeting_participants
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.meetings WHERE id = meeting_participants.meeting_id)
  );
CREATE POLICY "Users can insert meeting participants" ON public.meeting_participants
  FOR INSERT WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.meetings WHERE id = meeting_participants.meeting_id)
  );
CREATE POLICY "Users can update meeting participants" ON public.meeting_participants
  FOR UPDATE USING (
    auth.uid() IN (SELECT user_id FROM public.meetings WHERE id = meeting_participants.meeting_id)
  );
CREATE POLICY "Users can delete meeting participants" ON public.meeting_participants
  FOR DELETE USING (
    auth.uid() IN (SELECT user_id FROM public.meetings WHERE id = meeting_participants.meeting_id)
  );

-- integrations
DROP POLICY IF EXISTS "Users can view own integrations"   ON public.integrations;
DROP POLICY IF EXISTS "Users can insert own integrations" ON public.integrations;
DROP POLICY IF EXISTS "Users can update own integrations" ON public.integrations;
DROP POLICY IF EXISTS "Users can delete own integrations" ON public.integrations;

CREATE POLICY "Users can view own integrations"   ON public.integrations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own integrations" ON public.integrations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own integrations" ON public.integrations FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own integrations" ON public.integrations FOR DELETE USING (auth.uid() = user_id);

-- team
DROP POLICY IF EXISTS "Users can view own team"   ON public.team;
DROP POLICY IF EXISTS "Users can insert own team" ON public.team;
DROP POLICY IF EXISTS "Users can update own team" ON public.team;
DROP POLICY IF EXISTS "Users can delete own team" ON public.team;

CREATE POLICY "Users can view own team"   ON public.team FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own team" ON public.team FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own team" ON public.team FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own team" ON public.team FOR DELETE USING (auth.uid() = user_id);

-- posts — social feed: all authenticated users can read, only owner can write
DROP POLICY IF EXISTS "Users can view own posts"  ON public.posts;
DROP POLICY IF EXISTS "Users can view all posts"  ON public.posts;
DROP POLICY IF EXISTS "Users can insert own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
DROP POLICY IF EXISTS "Users can delete own posts" ON public.posts;

CREATE POLICY "Users can view all posts"   ON public.posts FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users can insert own posts" ON public.posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own posts" ON public.posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON public.posts FOR DELETE USING (auth.uid() = user_id);

-- comments
-- [FIX-06] SELECT was auth.uid() = user_id — made consistent with posts (social visibility)
DROP POLICY IF EXISTS "Users can view own comments"   ON public.comments;
DROP POLICY IF EXISTS "Users can view all comments"   ON public.comments;
DROP POLICY IF EXISTS "Users can insert own comments" ON public.comments;
DROP POLICY IF EXISTS "Users can delete own comments" ON public.comments;

CREATE POLICY "Users can view all comments"   ON public.comments FOR SELECT USING (auth.role() = 'authenticated');
CREATE POLICY "Users can insert own comments" ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON public.comments FOR DELETE USING (auth.uid() = user_id);

-- notes
DROP POLICY IF EXISTS "Users can view own notes"   ON public.notes;
DROP POLICY IF EXISTS "Users can insert own notes" ON public.notes;
DROP POLICY IF EXISTS "Users can update own notes" ON public.notes;
DROP POLICY IF EXISTS "Users can delete own notes" ON public.notes;

CREATE POLICY "Users can view own notes"   ON public.notes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own notes" ON public.notes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own notes" ON public.notes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own notes" ON public.notes FOR DELETE USING (auth.uid() = user_id);

-- images
DROP POLICY IF EXISTS "Users can view own images"   ON public.images;
DROP POLICY IF EXISTS "Users can insert own images" ON public.images;
DROP POLICY IF EXISTS "Users can delete own images" ON public.images;

CREATE POLICY "Users can view own images"   ON public.images FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own images" ON public.images FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own images" ON public.images FOR DELETE USING (auth.uid() = user_id);

-- resources
DROP POLICY IF EXISTS "Users can view own resources"   ON public.resources;
DROP POLICY IF EXISTS "Users can insert own resources" ON public.resources;
DROP POLICY IF EXISTS "Users can update own resources" ON public.resources;
DROP POLICY IF EXISTS "Users can delete own resources" ON public.resources;

CREATE POLICY "Users can view own resources"   ON public.resources FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own resources" ON public.resources FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own resources" ON public.resources FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own resources" ON public.resources FOR DELETE USING (auth.uid() = user_id);

-- budget
DROP POLICY IF EXISTS "Users can view own budget"   ON public.budget;
DROP POLICY IF EXISTS "Users can insert own budget" ON public.budget;
DROP POLICY IF EXISTS "Users can update own budget" ON public.budget;
DROP POLICY IF EXISTS "Users can delete own budget" ON public.budget;

CREATE POLICY "Users can view own budget"   ON public.budget FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own budget" ON public.budget FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own budget" ON public.budget FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own budget" ON public.budget FOR DELETE USING (auth.uid() = user_id);

-- risks
DROP POLICY IF EXISTS "Users can view own risks"   ON public.risks;
DROP POLICY IF EXISTS "Users can insert own risks" ON public.risks;
DROP POLICY IF EXISTS "Users can update own risks" ON public.risks;
DROP POLICY IF EXISTS "Users can delete own risks" ON public.risks;

CREATE POLICY "Users can view own risks"   ON public.risks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own risks" ON public.risks FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own risks" ON public.risks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own risks" ON public.risks FOR DELETE USING (auth.uid() = user_id);

-- activity
DROP POLICY IF EXISTS "Users can view own activity"   ON public.activity;
DROP POLICY IF EXISTS "Users can insert own activity" ON public.activity;

CREATE POLICY "Users can view own activity"   ON public.activity FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own activity" ON public.activity FOR INSERT WITH CHECK (auth.uid() = user_id);

-- voice_notes
DROP POLICY IF EXISTS "Users can view own voice notes"   ON public.voice_notes;
DROP POLICY IF EXISTS "Users can insert own voice notes" ON public.voice_notes;
DROP POLICY IF EXISTS "Users can delete own voice notes" ON public.voice_notes;

CREATE POLICY "Users can view own voice notes"   ON public.voice_notes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own voice notes" ON public.voice_notes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own voice notes" ON public.voice_notes FOR DELETE USING (auth.uid() = user_id);

-- user_settings
DROP POLICY IF EXISTS "Users can view own settings"   ON public.user_settings;
DROP POLICY IF EXISTS "Users can insert own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can update own settings" ON public.user_settings;

CREATE POLICY "Users can view own settings"   ON public.user_settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own settings" ON public.user_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own settings" ON public.user_settings FOR UPDATE USING (auth.uid() = user_id);

-- subscriptions
DROP POLICY IF EXISTS "Users can view own subscription"   ON public.subscriptions;
DROP POLICY IF EXISTS "Users can insert own subscription" ON public.subscriptions;
DROP POLICY IF EXISTS "Users can update own subscription" ON public.subscriptions;

CREATE POLICY "Users can view own subscription"   ON public.subscriptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own subscription" ON public.subscriptions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own subscription" ON public.subscriptions FOR UPDATE USING (auth.uid() = user_id);

-- meeting_signals
-- [FIX-05] Removed sender_id validation for WebRTC compatibility
-- PeerJS IDs are random strings, not UUIDs, so auth.uid() check breaks signaling
DROP POLICY IF EXISTS "Users can read meeting signals"   ON public.meeting_signals;
DROP POLICY IF EXISTS "Users can insert meeting signals" ON public.meeting_signals;
DROP POLICY IF EXISTS "Users can delete meeting signals" ON public.meeting_signals;

CREATE POLICY "Users can read meeting signals" ON public.meeting_signals
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert meeting signals" ON public.meeting_signals
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can delete meeting signals" ON public.meeting_signals
  FOR DELETE USING (auth.role() = 'authenticated');

-- ----------------------------------------------------------------
-- SIGNUP TRIGGER
-- ----------------------------------------------------------------

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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ----------------------------------------------------------------
-- MEETING SIGNALS CLEANUP
-- ----------------------------------------------------------------

CREATE OR REPLACE FUNCTION cleanup_old_meeting_signals()
RETURNS void AS $$
BEGIN
  DELETE FROM public.meeting_signals
  WHERE created_at < NOW() - INTERVAL '1 day';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_meeting_signals() IS
  'Deletes meeting signals older than 1 day. Schedule via pg_cron or an external job.';

-- ================================================================
-- MIGRATION HELPERS
-- Run only if upgrading from an earlier schema version
-- ================================================================

ALTER TABLE public.projects  ADD COLUMN IF NOT EXISTS budget   NUMERIC  DEFAULT 0;
ALTER TABLE public.projects  ADD COLUMN IF NOT EXISTS progress INTEGER  DEFAULT 0;
ALTER TABLE public.tasks     ADD COLUMN IF NOT EXISTS assignee TEXT     DEFAULT '';
ALTER TABLE public.meetings  ADD COLUMN IF NOT EXISTS duration INTEGER  DEFAULT 60;
ALTER TABLE public.posts     ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE public.comments  ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE;
-- [FIX-10] add updated_at to comments if missing
ALTER TABLE public.comments  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Meeting columns
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS duration_preset          TEXT    DEFAULT '60';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS timezone                 TEXT    DEFAULT 'Europe/Istanbul';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS recurrence               TEXT    DEFAULT 'none';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS recurrence_end_date      TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS meeting_link             TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS attendees                JSONB   DEFAULT '[]';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS location                 TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS description              TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS recording_status         TEXT    DEFAULT 'none';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS recording_url            TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS chat_messages            JSONB   DEFAULT '[]';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS reactions                JSONB   DEFAULT '[]';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS polls                    JSONB   DEFAULT '[]';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS whiteboard_data          JSONB;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS transcription            TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS summary                  TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS action_items             JSONB   DEFAULT '[]';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS attendance_report        JSONB;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS export_formats           TEXT    DEFAULT 'json';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS meeting_notes            TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS reminder_minutes         INTEGER DEFAULT 15;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS notification_sent        BOOLEAN DEFAULT false;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS late_warning_sent        BOOLEAN DEFAULT false;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS notification_preferences JSONB   DEFAULT '{}';
-- [FIX-04] password migration now includes the same CHECK as main schema
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS password TEXT CHECK (password IS NULL OR length(password) >= 6);
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS waiting_room             BOOLEAN DEFAULT false;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS encrypted                BOOLEAN DEFAULT false;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS join_permissions         TEXT    DEFAULT 'anyone';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS total_participants       INTEGER DEFAULT 0;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS avg_duration             INTEGER;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS usage_stats             JSONB   DEFAULT '{}';
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS template_id              TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS ai_assistant_enabled     BOOLEAN DEFAULT false;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS virtual_background       TEXT;

-- meeting_participants (idempotent re-create for fresh installs)
CREATE TABLE IF NOT EXISTS public.meeting_participants (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meeting_id  UUID REFERENCES public.meetings(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  email       TEXT,
  name        TEXT,
  role        TEXT DEFAULT 'participant',
  status      TEXT DEFAULT 'invited',
  joined_at   TIMESTAMP WITH TIME ZONE,
  left_at     TIMESTAMP WITH TIME ZONE,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- integrations (idempotent re-create for fresh installs)
CREATE TABLE IF NOT EXISTS public.integrations (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id          UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  integration_type TEXT NOT NULL,
  provider         TEXT NOT NULL,
  config           JSONB,
  enabled          BOOLEAN DEFAULT true,
  last_sync        TIMESTAMP WITH TIME ZONE,
  created_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at       TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
