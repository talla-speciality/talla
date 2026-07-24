CREATE TABLE IF NOT EXISTS taste_memory (
    email TEXT NOT NULL REFERENCES accounts(email) ON UPDATE CASCADE ON DELETE CASCADE,
    id TEXT NOT NULL,
    order_id TEXT NOT NULL,
    product_name TEXT NOT NULL,
    reaction TEXT NOT NULL,
    tags JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (email, id)
);
