CREATE TABLE IF NOT EXISTS education_quiz_attempts (
    email TEXT PRIMARY KEY REFERENCES accounts(email) ON DELETE CASCADE,
    window_started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    wrong_count INTEGER NOT NULL DEFAULT 0 CHECK (wrong_count >= 0)
);
