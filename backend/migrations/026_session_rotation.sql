ALTER TABLE customer_sessions
    ADD COLUMN IF NOT EXISTS family_id TEXT,
    ADD COLUMN IF NOT EXISTS rotated_from_session_id TEXT,
    ADD COLUMN IF NOT EXISTS refresh_expires_at TIMESTAMPTZ;

UPDATE customer_sessions
SET family_id = id
WHERE family_id IS NULL;

CREATE INDEX IF NOT EXISTS customer_sessions_family_idx
    ON customer_sessions(family_id);

CREATE TABLE IF NOT EXISTS customer_refresh_tokens (
    token_hash TEXT PRIMARY KEY,
    session_id TEXT NOT NULL REFERENCES customer_sessions(id) ON DELETE CASCADE,
    family_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed_at TIMESTAMPTZ,
    replaced_by_token_hash TEXT
);

CREATE INDEX IF NOT EXISTS customer_refresh_tokens_family_idx
    ON customer_refresh_tokens(family_id);
