ALTER TABLE admin_push_devices
    ADD COLUMN IF NOT EXISTS environment TEXT NOT NULL DEFAULT 'production';

UPDATE admin_push_devices
SET environment = 'production'
WHERE environment NOT IN ('sandbox', 'production');
