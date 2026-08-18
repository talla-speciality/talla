ALTER TABLE addresses
ADD COLUMN IF NOT EXISTS country_code TEXT NOT NULL DEFAULT 'BH';

ALTER TABLE addresses
DROP CONSTRAINT IF EXISTS addresses_country_code_format;

ALTER TABLE addresses
ADD CONSTRAINT addresses_country_code_format
CHECK (country_code ~ '^[A-Z]{2}$');
