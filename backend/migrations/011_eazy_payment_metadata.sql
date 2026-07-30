ALTER TABLE orders
    ADD COLUMN IF NOT EXISTS eazy_global_transaction_id TEXT,
    ADD COLUMN IF NOT EXISTS eazy_transaction_id TEXT,
    ADD COLUMN IF NOT EXISTS eazy_payment_method TEXT,
    ADD COLUMN IF NOT EXISTS eazy_paid_amount TEXT,
    ADD COLUMN IF NOT EXISTS eazy_paid_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS eazy_confirmed_at TIMESTAMPTZ;

CREATE UNIQUE INDEX IF NOT EXISTS orders_eazy_global_transaction_id_unique
    ON orders (eazy_global_transaction_id)
    WHERE eazy_global_transaction_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS orders_eazy_transaction_id_unique
    ON orders (eazy_transaction_id)
    WHERE eazy_transaction_id IS NOT NULL;
