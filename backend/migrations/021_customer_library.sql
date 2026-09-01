CREATE TABLE IF NOT EXISTS customer_product_library (
    email TEXT NOT NULL REFERENCES accounts(email) ON UPDATE CASCADE ON DELETE CASCADE,
    product_id TEXT NOT NULL,
    is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    favorite_updated_at TIMESTAMPTZ,
    last_viewed_at TIMESTAMPTZ,
    PRIMARY KEY (email, product_id)
);

CREATE INDEX IF NOT EXISTS customer_product_library_recent_idx
    ON customer_product_library (email, last_viewed_at DESC)
    WHERE last_viewed_at IS NOT NULL;

CREATE TABLE IF NOT EXISTS brew_journal_entries (
    email TEXT NOT NULL REFERENCES accounts(email) ON UPDATE CASCADE ON DELETE CASCADE,
    id TEXT NOT NULL,
    title TEXT NOT NULL,
    method TEXT NOT NULL,
    coffee_grams DOUBLE PRECISION,
    ratio DOUBLE PRECISION,
    water_grams DOUBLE PRECISION,
    brew_time_seconds INTEGER,
    rating INTEGER NOT NULL,
    notes TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (email, id),
    CONSTRAINT brew_journal_rating_range CHECK (rating BETWEEN 1 AND 5)
);

CREATE INDEX IF NOT EXISTS brew_journal_entries_created_idx
    ON brew_journal_entries (email, created_at DESC);
