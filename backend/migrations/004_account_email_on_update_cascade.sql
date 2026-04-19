ALTER TABLE loyalty_accounts
    DROP CONSTRAINT IF EXISTS loyalty_accounts_email_fkey,
    ADD CONSTRAINT loyalty_accounts_email_fkey
        FOREIGN KEY (email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE loyalty_transactions
    DROP CONSTRAINT IF EXISTS loyalty_transactions_email_fkey,
    ADD CONSTRAINT loyalty_transactions_email_fkey
        FOREIGN KEY (email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE wallet_passes
    DROP CONSTRAINT IF EXISTS wallet_passes_email_fkey,
    ADD CONSTRAINT wallet_passes_email_fkey
        FOREIGN KEY (email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE addresses
    DROP CONSTRAINT IF EXISTS addresses_email_fkey,
    ADD CONSTRAINT addresses_email_fkey
        FOREIGN KEY (email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE vouchers
    DROP CONSTRAINT IF EXISTS vouchers_email_fkey,
    ADD CONSTRAINT vouchers_email_fkey
        FOREIGN KEY (email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE orders
    DROP CONSTRAINT IF EXISTS orders_email_fkey,
    ADD CONSTRAINT orders_email_fkey
        FOREIGN KEY (email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE stock_alerts
    DROP CONSTRAINT IF EXISTS stock_alerts_email_fkey,
    ADD CONSTRAINT stock_alerts_email_fkey
        FOREIGN KEY (email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE alert_inbox
    DROP CONSTRAINT IF EXISTS alert_inbox_email_fkey,
    ADD CONSTRAINT alert_inbox_email_fkey
        FOREIGN KEY (email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE admin_audit_logs
    DROP CONSTRAINT IF EXISTS admin_audit_logs_target_email_fkey,
    ADD CONSTRAINT admin_audit_logs_target_email_fkey
        FOREIGN KEY (target_email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE customer_sessions
    DROP CONSTRAINT IF EXISTS customer_sessions_email_fkey,
    ADD CONSTRAINT customer_sessions_email_fkey
        FOREIGN KEY (email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE password_reset_tokens
    DROP CONSTRAINT IF EXISTS password_reset_tokens_email_fkey,
    ADD CONSTRAINT password_reset_tokens_email_fkey
        FOREIGN KEY (email) REFERENCES accounts(email) ON DELETE CASCADE ON UPDATE CASCADE;
