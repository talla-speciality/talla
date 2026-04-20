ALTER TABLE accounts
    ADD COLUMN IF NOT EXISTS apple_user_id TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS accounts_apple_user_id_key
    ON accounts (apple_user_id);
