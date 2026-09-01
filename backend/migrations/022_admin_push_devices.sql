CREATE TABLE IF NOT EXISTS admin_push_devices (
    device_token TEXT PRIMARY KEY,
    admin_username TEXT NOT NULL,
    platform TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    last_sent_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS admin_push_devices_admin_username_idx
    ON admin_push_devices(admin_username);
