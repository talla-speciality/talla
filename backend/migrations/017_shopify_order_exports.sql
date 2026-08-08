CREATE TABLE IF NOT EXISTS shopify_order_exports (
    local_order_id TEXT PRIMARY KEY REFERENCES orders(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    shopify_order_gid TEXT UNIQUE,
    shopify_order_name TEXT,
    export_tag TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL,
    failure_code TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS shopify_order_exports_email_idx
    ON shopify_order_exports(email, updated_at DESC);
