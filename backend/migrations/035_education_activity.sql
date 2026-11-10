CREATE TABLE IF NOT EXISTS education_activity (
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    kind TEXT NOT NULL CHECK (kind IN ('lesson', 'answer')),
    item_id TEXT NOT NULL,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (email, kind, item_id)
);
