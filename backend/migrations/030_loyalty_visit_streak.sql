ALTER TABLE loyalty_accounts
    ADD COLUMN IF NOT EXISTS visit_streak_days INTEGER NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS last_visit_date DATE;
