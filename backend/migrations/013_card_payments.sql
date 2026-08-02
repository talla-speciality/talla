CREATE TABLE IF NOT EXISTS card_payments (
    payment_id TEXT PRIMARY KEY,
    local_order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    mpgs_order_id TEXT UNIQUE NOT NULL,
    session_id TEXT UNIQUE NOT NULL,
    session_version TEXT NOT NULL,
    amount TEXT NOT NULL,
    currency TEXT NOT NULL,
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS card_payments_one_pending_order_idx
    ON card_payments (local_order_id)
    WHERE status = 'Pending';

CREATE INDEX IF NOT EXISTS card_payments_email_created_idx
    ON card_payments (email, created_at DESC);
