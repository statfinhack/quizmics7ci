-- ============================================================
-- SUPABASE_SETUP.sql — À exécuter UNE SEULE FOIS sur le nouveau projet
-- SQL Editor → coller tout ce fichier → Run
-- ============================================================

-- 1. TABLES
-- ============================================================

CREATE TABLE IF NOT EXISTS agents (
  id          SERIAL PRIMARY KEY,
  nom         TEXT NOT NULL,
  prenom      TEXT DEFAULT '',
  matricule   TEXT DEFAULT '',
  groupe      TEXT DEFAULT '',
  published   INTEGER DEFAULT 0,
  created_at  TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS quizzes (
  id                   SERIAL PRIMARY KEY,
  titre                TEXT NOT NULL,
  code                 TEXT UNIQUE NOT NULL,
  duree_minutes        INTEGER DEFAULT 10,
  actif                INTEGER DEFAULT 0,
  show_score           INTEGER DEFAULT 1,
  randomize_questions  INTEGER DEFAULT 0,
  malus_actif          INTEGER DEFAULT 0,
  malus_points         REAL DEFAULT 0,
  anticheat_actif      INTEGER DEFAULT 0,
  anticheat_max        INTEGER DEFAULT 3,
  anticheat_agents     TEXT DEFAULT '',
  show_correction      INTEGER DEFAULT 0,
  created_at           TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS questions (
  id                   SERIAL PRIMARY KEY,
  quiz_id              INTEGER REFERENCES quizzes(id) ON DELETE CASCADE,
  texte                TEXT NOT NULL,
  type                 TEXT NOT NULL,
  ordre                INTEGER DEFAULT 0,
  points               REAL DEFAULT 1,
  reponse_correcte_num REAL,
  reponse_correcte_txt TEXT,
  image_url            TEXT DEFAULT '',
  created_at           TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS options (
  id          SERIAL PRIMARY KEY,
  question_id INTEGER REFERENCES questions(id) ON DELETE CASCADE,
  texte       TEXT NOT NULL,
  is_correct  INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS sessions (
  id                      SERIAL PRIMARY KEY,
  agent_id                INTEGER REFERENCES agents(id),
  quiz_id                 INTEGER REFERENCES quizzes(id),
  score                   REAL DEFAULT 0,
  max_score               REAL DEFAULT 0,
  completed               INTEGER DEFAULT 0,
  started_at              TIMESTAMP DEFAULT now(),
  submitted_at            TIMESTAMP,
  answers_json            TEXT DEFAULT '{}',
  answer_timestamps_json  TEXT DEFAULT '{}',
  device_info             TEXT DEFAULT '',
  ip_address              TEXT DEFAULT '',
  start_device_info       TEXT DEFAULT '',
  start_ip_address        TEXT DEFAULT '',
  devices_log             TEXT DEFAULT '[]',
  quit_count              INTEGER DEFAULT 0,
  start_time_epoch        REAL
);

CREATE TABLE IF NOT EXISTS answers (
  id              SERIAL PRIMARY KEY,
  session_id      INTEGER REFERENCES sessions(id) ON DELETE CASCADE,
  question_id     INTEGER REFERENCES questions(id),
  reponse         TEXT DEFAULT '',
  est_correcte    INTEGER DEFAULT 0,
  points_obtenus  REAL DEFAULT 0
);


-- 2. ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE agents    ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes   ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE options   ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers   ENABLE ROW LEVEL SECURITY;

-- Lecture publique (pages GitHub Pages)
CREATE POLICY "public_read_agents"    ON agents    FOR SELECT TO anon USING (true);
CREATE POLICY "public_read_quizzes"   ON quizzes   FOR SELECT TO anon USING (true);
CREATE POLICY "public_read_questions" ON questions FOR SELECT TO anon USING (true);
CREATE POLICY "public_read_options"   ON options   FOR SELECT TO anon USING (true);

-- Sessions : lecture + écriture pour les agents
CREATE POLICY "public_all_sessions" ON sessions FOR ALL TO anon USING (true) WITH CHECK (true);

-- Answers : INSERT autorisé pour les agents  ← CORRECTION BUG RLS
CREATE POLICY "public_insert_answers" ON answers FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "public_read_answers"   ON answers FOR SELECT TO anon USING (true);


-- 3. STORAGE (bucket images questions)
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('quiz-images', 'quiz-images', true)
ON CONFLICT DO NOTHING;

DROP POLICY IF EXISTS "public_read_quiz_images"   ON storage.objects;
DROP POLICY IF EXISTS "public_insert_quiz_images" ON storage.objects;
DROP POLICY IF EXISTS "public_update_quiz_images" ON storage.objects;

CREATE POLICY "public_read_quiz_images"   ON storage.objects
  FOR SELECT TO anon, authenticated USING (bucket_id = 'quiz-images');

CREATE POLICY "public_insert_quiz_images" ON storage.objects
  FOR INSERT TO anon, authenticated WITH CHECK (bucket_id = 'quiz-images');

CREATE POLICY "public_update_quiz_images" ON storage.objects
  FOR UPDATE TO anon, authenticated USING (bucket_id = 'quiz-images');
