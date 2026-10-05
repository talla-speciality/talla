ALTER TABLE loyalty_accounts
    ADD COLUMN IF NOT EXISTS visited_cafe_ids JSONB NOT NULL DEFAULT '[]'::jsonb;
