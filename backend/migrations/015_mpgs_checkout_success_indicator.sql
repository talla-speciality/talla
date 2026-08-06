ALTER TABLE card_payments
    ADD COLUMN IF NOT EXISTS success_indicator_hash TEXT;
