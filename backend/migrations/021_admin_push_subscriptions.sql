CREATE TABLE IF NOT EXISTS admin_push_subscriptions (
    endpoint TEXT PRIMARY KEY,
    admin_username TEXT NOT NULL,
    subscription JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    last_sent_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS admin_push_subscriptions_admin_username_idx
    ON admin_push_subscriptions(admin_username);
