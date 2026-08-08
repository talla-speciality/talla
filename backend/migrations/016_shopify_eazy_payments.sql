CREATE TABLE IF NOT EXISTS shopify_eazy_payments (
    talla_payment_id TEXT PRIMARY KEY,
    email TEXT NOT NULL REFERENCES accounts(email) ON DELETE CASCADE,
    shopify_order_id TEXT,
    shopify_order_gid TEXT,
    shopify_order_name TEXT,
    amount TEXT,
    currency TEXT,
    payment_gateway TEXT,
    order_items JSONB NOT NULL DEFAULT '[]'::jsonb,
    eazy_invoice_id TEXT,
    eazy_global_transaction_id TEXT UNIQUE,
    eazy_transaction_id TEXT UNIQUE,
    eazy_payment_url TEXT,
    eazy_payment_method TEXT,
    status TEXT NOT NULL,
    failure_code TEXT,
    failure_message TEXT,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    eazy_confirmed_at TIMESTAMPTZ,
    paid_at TIMESTAMPTZ,
    effects_applied_at TIMESTAMPTZ
);

CREATE UNIQUE INDEX IF NOT EXISTS shopify_eazy_payments_shopify_order_idx
    ON shopify_eazy_payments (shopify_order_id)
    WHERE shopify_order_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS shopify_eazy_payments_email_created_idx
    ON shopify_eazy_payments (email, created_at DESC);

CREATE INDEX IF NOT EXISTS shopify_eazy_payments_retry_idx
    ON shopify_eazy_payments (status, updated_at);
