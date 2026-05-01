-- ================================================================
-- MEETING FEATURE TABLES (Video Meeting Support)
-- Run this after main schema
-- ================================================================

-- Create the updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Meeting participants for video meetings
CREATE TABLE IF NOT EXISTS public.meeting_participants (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meeting_id  UUID REFERENCES public.meetings(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  email       TEXT,
  peer_id     TEXT,                    -- PeerJS peer ID
  joined_at   TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  left_at     TIMESTAMP WITH TIME ZONE,
  is_host     BOOLEAN DEFAULT false,
  is_muted    BOOLEAN DEFAULT false,
  is_video_off BOOLEAN DEFAULT false,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(meeting_id, user_id)
);

-- Meeting chat messages
CREATE TABLE IF NOT EXISTS public.meeting_messages (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meeting_id  UUID REFERENCES public.meetings(id) ON DELETE CASCADE,
  sender_id   UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  sender_name TEXT,
  message     TEXT NOT NULL,
  message_type TEXT DEFAULT 'text',    -- text, system, reaction
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Meeting polls
CREATE TABLE IF NOT EXISTS public.meeting_polls (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meeting_id  UUID REFERENCES public.meetings(id) ON DELETE CASCADE,
  question    TEXT NOT NULL,
  options     JSONB NOT NULL,          -- ["option1", "option2", ...]
  results     JSONB DEFAULT '{}',      -- {"option1": 5, "option2": 3}
  created_by  UUID REFERENCES public.user_profiles(id),
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active   BOOLEAN DEFAULT true
);

-- Meeting poll votes (prevent duplicate voting)
CREATE TABLE IF NOT EXISTS public.meeting_poll_votes (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  poll_id     UUID REFERENCES public.meeting_polls(id) ON DELETE CASCADE,
  user_id     UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  option_index INTEGER NOT NULL,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(poll_id, user_id)
);

-- Meeting whiteboard snapshots (periodic saves)
CREATE TABLE IF NOT EXISTS public.meeting_whiteboards (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meeting_id  UUID REFERENCES public.meetings(id) ON DELETE CASCADE,
  canvas_data TEXT,                    -- Base64 encoded canvas
  created_by  UUID REFERENCES public.user_profiles(id),
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Meeting recordings metadata
CREATE TABLE IF NOT EXISTS public.meeting_recordings (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  meeting_id  UUID REFERENCES public.meetings(id) ON DELETE CASCADE,
  recording_url TEXT,                  -- Storage URL
  started_at  TIMESTAMP WITH TIME ZONE,
  ended_at    TIMESTAMP WITH TIME ZONE,
  recorded_by UUID REFERENCES public.user_profiles(id),
  file_size   INTEGER,
  duration_seconds INTEGER,
  created_at  TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add columns to existing meetings table
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT false;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS peer_id TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS recording_blob_url TEXT;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS whiteboard_enabled BOOLEAN DEFAULT true;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS chat_enabled BOOLEAN DEFAULT true;
ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS polls_enabled BOOLEAN DEFAULT true;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_meeting_participants_meeting ON public.meeting_participants(meeting_id);
CREATE INDEX IF NOT EXISTS idx_meeting_participants_user ON public.meeting_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_meeting_messages_meeting ON public.meeting_messages(meeting_id);
CREATE INDEX IF NOT EXISTS idx_meeting_messages_created ON public.meeting_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_meeting_polls_meeting ON public.meeting_polls(meeting_id);

-- Enable RLS
ALTER TABLE public.meeting_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_poll_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_whiteboards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meeting_recordings ENABLE ROW LEVEL SECURITY;

-- RLS Policies for meeting_participants
DROP POLICY IF EXISTS "Meeting participants viewable by meeting members" ON public.meeting_participants;
CREATE POLICY "Meeting participants viewable by meeting members"
  ON public.meeting_participants FOR SELECT
  USING (meeting_id IN (
    SELECT id FROM public.meetings WHERE user_id = auth.uid()
    UNION
    SELECT meeting_id FROM public.meeting_participants WHERE user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "Users can join meetings" ON public.meeting_participants;
CREATE POLICY "Users can join meetings"
  ON public.meeting_participants FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own participant status" ON public.meeting_participants;
CREATE POLICY "Users can update own participant status"
  ON public.meeting_participants FOR UPDATE
  USING (auth.uid() = user_id);

-- RLS Policies for meeting_messages
DROP POLICY IF EXISTS "Meeting messages viewable by meeting members" ON public.meeting_messages;
CREATE POLICY "Meeting messages viewable by meeting members"
  ON public.meeting_messages FOR SELECT
  USING (meeting_id IN (
    SELECT id FROM public.meetings WHERE user_id = auth.uid()
    UNION
    SELECT meeting_id FROM public.meeting_participants WHERE user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "Meeting members can send messages" ON public.meeting_messages;
CREATE POLICY "Meeting members can send messages"
  ON public.meeting_messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND
    meeting_id IN (
      SELECT id FROM public.meetings WHERE user_id = auth.uid()
      UNION
      SELECT meeting_id FROM public.meeting_participants WHERE user_id = auth.uid()
    )
  );

-- RLS Policies for meeting_polls
DROP POLICY IF EXISTS "Meeting polls viewable by meeting members" ON public.meeting_polls;
CREATE POLICY "Meeting polls viewable by meeting members"
  ON public.meeting_polls FOR SELECT
  USING (meeting_id IN (
    SELECT id FROM public.meetings WHERE user_id = auth.uid()
    UNION
    SELECT meeting_id FROM public.meeting_participants WHERE user_id = auth.uid()
  ));

DROP POLICY IF EXISTS "Meeting members can create polls" ON public.meeting_polls;
CREATE POLICY "Meeting members can create polls"
  ON public.meeting_polls FOR INSERT
  WITH CHECK (
    created_by = auth.uid() AND
    meeting_id IN (
      SELECT id FROM public.meetings WHERE user_id = auth.uid()
      UNION
      SELECT meeting_id FROM public.meeting_participants WHERE user_id = auth.uid()
    )
  );

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_meeting_participants_updated_at ON public.meeting_participants;
CREATE TRIGGER update_meeting_participants_updated_at
  BEFORE UPDATE ON public.meeting_participants
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_meeting_polls_updated_at ON public.meeting_polls;
CREATE TRIGGER update_meeting_polls_updated_at
  BEFORE UPDATE ON public.meeting_polls
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
