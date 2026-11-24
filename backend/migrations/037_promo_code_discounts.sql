ALTER TABLE vouchers
    DROP CONSTRAINT IF EXISTS vouchers_email_fkey;

ALTER TABLE vouchers
    ALTER COLUMN email DROP NOT NULL;

ALTER TABLE vouchers
    ADD COLUMN IF NOT EXISTS discount_type TEXT,
    ADD COLUMN IF NOT EXISTS discount_value NUMERIC;
