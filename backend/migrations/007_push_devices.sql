CREATE TABLE IF NOT EXISTS push_devices (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL REFERENCES accounts(email) ON UPDATE CASCADE ON DELETE CASCADE,
    device_token TEXT NOT NULL UNIQUE,
    platform TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    last_sent_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS push_devices_email_idx
    ON push_devices(email);
