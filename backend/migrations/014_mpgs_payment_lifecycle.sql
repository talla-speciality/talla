ALTER TABLE card_payments
    ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT 'CARD',
    ADD COLUMN IF NOT EXISTS authentication_transaction_id TEXT,
    ADD COLUMN IF NOT EXISTS purchase_transaction_id TEXT,
    ADD COLUMN IF NOT EXISTS gateway_result TEXT,
    ADD COLUMN IF NOT EXISTS gateway_transaction_result TEXT,
    ADD COLUMN IF NOT EXISTS result_token_hash TEXT,
    ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS effects_applied_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS last_gateway_response_at TIMESTAMPTZ;

CREATE UNIQUE INDEX IF NOT EXISTS card_payments_result_token_idx
    ON card_payments (result_token_hash)
    WHERE result_token_hash IS NOT NULL;

CREATE INDEX IF NOT EXISTS card_payments_mpgs_order_idx
    ON card_payments (mpgs_order_id);
