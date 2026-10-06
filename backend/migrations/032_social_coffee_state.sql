CREATE TABLE IF NOT EXISTS social_coffee_state (
    id SMALLINT PRIMARY KEY CHECK (id = 1),
    state JSONB NOT NULL DEFAULT '{"customers":{},"groups":{}}'::jsonb,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO social_coffee_state (id) VALUES (1) ON CONFLICT (id) DO NOTHING;
