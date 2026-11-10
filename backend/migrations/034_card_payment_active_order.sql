-- One order may have only one payment that can still move money.
-- If this fails on existing duplicate active rows, reconcile them against the
-- gateway before retrying the migration; do not silently discard payments.
DROP INDEX IF EXISTS card_payments_one_pending_order_idx;

CREATE UNIQUE INDEX IF NOT EXISTS card_payments_one_active_order_idx
    ON card_payments (local_order_id)
    WHERE status IN ('Pending', 'Authenticating', 'AwaitingChallenge', 'Authenticated', 'Processing');
