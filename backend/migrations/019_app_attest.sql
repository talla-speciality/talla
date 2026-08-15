CREATE TABLE IF NOT EXISTS app_attest_keys (
    key_id TEXT PRIMARY KEY,
    public_key_pem TEXT NOT NULL,
    receipt_base64 TEXT,
    sign_count BIGINT NOT NULL DEFAULT 0,
    environment TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
