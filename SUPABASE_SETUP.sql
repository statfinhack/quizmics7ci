-- ============================================================
-- SUPABASE_SETUP.sql — QuizAgent CI
-- Schéma ALIGNÉ sur database.py (noms de colonnes réellement utilisés par
-- l'admin Streamlit ET par les pages agent/*.html).
-- Idempotent : peut être relancé sans risque (SQL Editor → Run).
-- ============================================================

-- 1. TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS agents (
  id          SERIAL PRIMARY KEY,
  nom         TEXT NOT NULL,
  prenom      TEXT DEFAULT '',
  matricule   TEXT DEFAULT '',
  published   INTEGER DEFAULT 0,
  created_at  TEXT DEFAULT (now()::text)
);

CREATE TABLE IF NOT EXISTS quizzes (
  id                   SERIAL PRIMARY KEY,
  titre                TEXT NOT NULL,
  code                 TEXT UNIQUE NOT NULL,
  duree_minutes        INTEGER DEFAULT 30,
  description          TEXT DEFAULT '',
  actif                INTEGER DEFAULT 1,
  show_score           INTEGER DEFAULT 1,
  randomize_questions  INTEGER DEFAULT 0,
  malus_actif          INTEGER DEFAULT 0,
  malus_points         DOUBLE PRECISION DEFAULT 0,
  anticheat_actif      INTEGER DEFAULT 0,
  anticheat_max        INTEGER DEFAULT 3,
  anticheat_agents     TEXT DEFAULT '[]',
  show_correction      INTEGER DEFAULT 0,
  created_at           TEXT DEFAULT (now()::text)
);

CREATE TABLE IF NOT EXISTS questions (
  id                   SERIAL PRIMARY KEY,
  quiz_id              INTEGER NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  texte                TEXT NOT NULL,
  type                 TEXT NOT NULL,
  ordre                INTEGER DEFAULT 0,
  points               DOUBLE PRECISION DEFAULT 1,
  reponse_correcte_num DOUBLE PRECISION,
  reponse_correcte_txt TEXT,
  image_url            TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS options (
  id          SERIAL PRIMARY KEY,
  question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  texte       TEXT NOT NULL,
  is_correct  INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS sessions (
  id                      SERIAL PRIMARY KEY,
  agent_id                INTEGER NOT NULL REFERENCES agents(id)  ON DELETE CASCADE,
  quiz_id                 INTEGER NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
  score                   DOUBLE PRECISION DEFAULT 0,
  max_score               DOUBLE PRECISION DEFAULT 0,
  completed               INTEGER DEFAULT 0,
  start_time_epoch        DOUBLE PRECISION,
  answers_json            TEXT DEFAULT '{}',
  answer_timestamps_json  TEXT DEFAULT '{}',
  started_at              TEXT DEFAULT (now()::text),
  completed_at            TEXT,
  device_info             TEXT DEFAULT '',
  ip_address              TEXT DEFAULT '',
  start_device_info       TEXT DEFAULT '',
  start_ip_address        TEXT DEFAULT '',
  devices_log             TEXT DEFAULT '[]',
  quit_count              INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS answers (
  id          SERIAL PRIMARY KEY,
  session_id  INTEGER NOT NULL REFERENCES sessions(id)  ON DELETE CASCADE,
  question_id INTEGER NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  reponse     TEXT DEFAULT '',
  is_correct  INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_questions_quiz     ON questions(quiz_id);
CREATE INDEX IF NOT EXISTS idx_options_question   ON options(question_id);
CREATE INDEX IF NOT EXISTS idx_sessions_agent_quiz ON sessions(agent_id, quiz_id);
CREATE INDEX IF NOT EXISTS idx_answers_session    ON answers(session_id);
CREATE INDEX IF NOT EXISTS idx_answers_question   ON answers(question_id);

-- 1b. MIGRATION (si les tables existaient déjà avec l'ancien schéma)
-- ============================================================
ALTER TABLE quizzes  ADD COLUMN IF NOT EXISTS description      TEXT DEFAULT '';
ALTER TABLE quizzes  ADD COLUMN IF NOT EXISTS show_correction  INTEGER DEFAULT 0;
ALTER TABLE quizzes  ADD COLUMN IF NOT EXISTS anticheat_max    INTEGER DEFAULT 3;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS completed_at     TEXT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS answer_timestamps_json TEXT DEFAULT '{}';
ALTER TABLE answers  ADD COLUMN IF NOT EXISTS is_correct       INTEGER DEFAULT 0;

-- 2. ROW LEVEL SECURITY (accès des pages agent via la clé anon)
-- ============================================================
ALTER TABLE agents    ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes   ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE options   ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers   ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_agents"    ON agents;
DROP POLICY IF EXISTS "public_read_quizzes"   ON quizzes;
DROP POLICY IF EXISTS "public_read_questions" ON questions;
DROP POLICY IF EXISTS "public_read_options"   ON options;
DROP POLICY IF EXISTS "public_all_sessions"   ON sessions;
DROP POLICY IF EXISTS "public_insert_answers" ON answers;
DROP POLICY IF EXISTS "public_read_answers"   ON answers;

CREATE POLICY "public_read_agents"    ON agents    FOR SELECT TO anon USING (true);
CREATE POLICY "public_read_quizzes"   ON quizzes   FOR SELECT TO anon USING (true);
CREATE POLICY "public_read_questions" ON questions FOR SELECT TO anon USING (true);
CREATE POLICY "public_read_options"   ON options   FOR SELECT TO anon USING (true);
CREATE POLICY "public_all_sessions"   ON sessions  FOR ALL    TO anon USING (true) WITH CHECK (true);
CREATE POLICY "public_insert_answers" ON answers   FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "public_read_answers"   ON answers   FOR SELECT TO anon USING (true);

-- 3. STORAGE (bucket images des questions)
-- ============================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('quiz-images', 'quiz-images', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "public_read_quiz_images"   ON storage.objects;
DROP POLICY IF EXISTS "public_insert_quiz_images" ON storage.objects;
DROP POLICY IF EXISTS "public_update_quiz_images" ON storage.objects;

CREATE POLICY "public_read_quiz_images"   ON storage.objects
  FOR SELECT TO anon, authenticated USING (bucket_id = 'quiz-images');
CREATE POLICY "public_insert_quiz_images" ON storage.objects
  FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'quiz-images');
CREATE POLICY "public_update_quiz_images" ON storage.objects
  FOR UPDATE TO anon, authenticated USING (bucket_id = 'quiz-images');
