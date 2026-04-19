CREATE TABLE IF NOT EXISTS ops_alert_state (
    alert_key TEXT PRIMARY KEY,
    last_sent_at TIMESTAMPTZ,
    last_payload JSONB NOT NULL DEFAULT '{}'::jsonb
);
