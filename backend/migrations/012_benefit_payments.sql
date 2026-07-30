CREATE TABLE IF NOT EXISTS benefit_payments (
    track_id TEXT PRIMARY KEY,
    order_id TEXT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    amount TEXT NOT NULL,
    currency TEXT NOT NULL,
    status TEXT NOT NULL,
    result_token_hash TEXT UNIQUE NOT NULL,
    hosted_payment_url TEXT,
    payment_id TEXT UNIQUE,
    transaction_id TEXT UNIQUE,
    reference_id TEXT,
    gateway_result TEXT,
    auth_code TEXT,
    auth_response_code TEXT,
    error_code TEXT,
    error_text TEXT,
    notification_hash TEXT,
    notification_received_at TIMESTAMPTZ,
    processed_at TIMESTAMPTZ,
    effects_applied_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS benefit_payments_order_status_idx
    ON benefit_payments (order_id, status);
