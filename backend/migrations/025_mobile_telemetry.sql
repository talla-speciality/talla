CREATE TABLE IF NOT EXISTS telemetry_events (
    id TEXT PRIMARY KEY,
    event_name TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('analytics', 'crash', 'performance')),
    platform TEXT NOT NULL CHECK (platform IN ('ios', 'android', 'watchos', 'widget', 'backend')),
    anonymous_id TEXT NOT NULL,
    session_id TEXT NOT NULL,
    account_email TEXT REFERENCES accounts(email) ON UPDATE CASCADE ON DELETE SET NULL,
    app_version TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    properties JSONB NOT NULL DEFAULT '{}'::jsonb,
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS telemetry_events_name_occurred_idx
    ON telemetry_events(event_name, occurred_at DESC);

CREATE INDEX IF NOT EXISTS telemetry_events_platform_occurred_idx
    ON telemetry_events(platform, occurred_at DESC);

CREATE INDEX IF NOT EXISTS telemetry_events_account_occurred_idx
    ON telemetry_events(account_email, occurred_at DESC)
    WHERE account_email IS NOT NULL;
