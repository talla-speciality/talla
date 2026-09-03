CREATE SEQUENCE IF NOT EXISTS coffee_sync_cursor_seq;

CREATE TABLE IF NOT EXISTS coffee_records (
    email TEXT NOT NULL REFERENCES accounts(email) ON UPDATE CASCADE ON DELETE CASCADE,
    entity_type TEXT NOT NULL,
    record_id UUID NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    revision BIGINT NOT NULL DEFAULT 1,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ,
    updated_by_device TEXT NOT NULL,
    sync_cursor BIGINT NOT NULL DEFAULT nextval('coffee_sync_cursor_seq'),
    PRIMARY KEY (email, entity_type, record_id),
    CONSTRAINT coffee_records_entity_type CHECK (entity_type IN (
        'coffeeLot', 'purchasedCoffee', 'equipment', 'calibration', 'recipe',
        'recipeVersion', 'brewSession', 'sample', 'tasteFeedback', 'maintenance'
    )),
    CONSTRAINT coffee_records_payload_object CHECK (jsonb_typeof(payload) = 'object')
);

CREATE INDEX IF NOT EXISTS coffee_records_sync_idx ON coffee_records (email, sync_cursor);
CREATE INDEX IF NOT EXISTS coffee_records_active_type_idx ON coffee_records (email, entity_type, updated_at DESC) WHERE deleted_at IS NULL;
