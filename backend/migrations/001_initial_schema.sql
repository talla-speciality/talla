CREATE TABLE IF NOT EXISTS schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS accounts (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS loyalty_accounts (
    email TEXT PRIMARY KEY REFERENCES accounts(email) ON DELETE CASCADE,
    member_id TEXT UNIQUE NOT NULL,
    points_balance INTEGER NOT NULL,
    tier TEXT NOT NULL,
    next_reward TEXT NOT NULL,
    perks JSONB NOT NULL DEFAULT '[]'::jsonb
);

CREATE TABLE IF NOT EXISTS loyalty_transactions (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    type TEXT NOT NULL,
    points INTEGER NOT NULL,
    note TEXT NOT NULL,
    voucher_code TEXT,
    voucher_detail TEXT,
    voucher_expires_at TIMESTAMPTZ,
    voucher_single_use BOOLEAN,
    voucher_status TEXT,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS wallet_passes (
    email TEXT PRIMARY KEY REFERENCES accounts(email) ON DELETE CASCADE,
    serial_number TEXT UNIQUE NOT NULL,
    pass_type_identifier TEXT,
    last_generated_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS addresses (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    label TEXT NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    line1 TEXT NOT NULL,
    city TEXT NOT NULL,
    notes TEXT,
    is_preferred BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS vouchers (
    code TEXT PRIMARY KEY,
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    reward TEXT NOT NULL,
    points INTEGER NOT NULL,
    detail TEXT NOT NULL,
    single_use BOOLEAN NOT NULL DEFAULT TRUE,
    status TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    used_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS orders (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    title TEXT NOT NULL,
    total TEXT NOT NULL,
    status TEXT NOT NULL,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS stock_alerts (
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    product_name TEXT NOT NULL,
    tag TEXT,
    is_available_for_sale BOOLEAN NOT NULL,
    status TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (email, product_id)
);

CREATE TABLE IF NOT EXISTS alert_inbox (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    title TEXT NOT NULL,
    detail TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    product_id TEXT
);

CREATE TABLE IF NOT EXISTS admin_audit_logs (
    id TEXT PRIMARY KEY,
    admin_username TEXT NOT NULL,
    action TEXT NOT NULL,
    target_email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    detail TEXT NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS customer_sessions (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    token_hash TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS request_logs (
    id TEXT PRIMARY KEY,
    method TEXT NOT NULL,
    path TEXT NOT NULL,
    status_code INTEGER NOT NULL,
    ip_address TEXT NOT NULL,
    duration_ms INTEGER NOT NULL,
    user_agent TEXT,
    account_email TEXT,
    created_at TIMESTAMPTZ NOT NULL
);
