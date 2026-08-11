ALTER TABLE wallet_passes
    ADD COLUMN IF NOT EXISTS authentication_token TEXT,
    ADD COLUMN IF NOT EXISTS update_tag BIGINT NOT NULL DEFAULT 0;

UPDATE wallet_passes
SET authentication_token = replace(gen_random_uuid()::text, '-', '')
WHERE authentication_token IS NULL;

ALTER TABLE wallet_passes
    ALTER COLUMN authentication_token SET NOT NULL;

CREATE TABLE IF NOT EXISTS wallet_pass_devices (
    device_library_identifier TEXT PRIMARY KEY,
    push_token TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS wallet_pass_registrations (
    device_library_identifier TEXT NOT NULL REFERENCES wallet_pass_devices(device_library_identifier) ON DELETE CASCADE,
    serial_number TEXT NOT NULL REFERENCES wallet_passes(serial_number) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (device_library_identifier, serial_number)
);
