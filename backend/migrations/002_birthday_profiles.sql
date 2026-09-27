CREATE TABLE IF NOT EXISTS customer_birthday_profiles (
    email TEXT PRIMARY KEY REFERENCES accounts(email) ON DELETE CASCADE,
    birth_month INTEGER NOT NULL CHECK (birth_month BETWEEN 1 AND 12),
    birth_day INTEGER NOT NULL CHECK (birth_day BETWEEN 1 AND 31),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
