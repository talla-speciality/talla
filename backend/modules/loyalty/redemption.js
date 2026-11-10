const crypto = require("node:crypto");

function createLoyaltyRedemptionService({
    database,
    normalizeEmail,
    updateLoyaltyAccount,
    storeVoucherRecord,
    tierFor,
    nextRewardText,
    loyaltyPerksFor,
    queueWalletPassUpdate,
    getLoyaltyAccount,
    getLoyaltyTransactions
}) {
    return async function redeemLoyaltyVoucher(email, voucher, idempotencyKey = null) {
        const points = Number(voucher.points);
        if (!Number.isSafeInteger(points) || points <= 0 || normalizeEmail(voucher.email) !== normalizeEmail(email)) {
            throw new Error("INVALID_REDEMPTION");
        }
        const suppliedKey = String(idempotencyKey || "").trim();
        if (suppliedKey && !/^redeem:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(suppliedKey)) {
            throw new Error("INVALID_REDEMPTION_KEY");
        }
        const transaction = {
            id: suppliedKey || `txn_${crypto.randomUUID()}`,
            type: "redeem",
            points,
            note: voucher.reward,
            voucherCode: voucher.code,
            voucherDetail: voucher.detail,
            voucherExpiresAt: voucher.expiresAt,
            voucherSingleUse: voucher.singleUse,
            voucherStatus: voucher.status,
            createdAt: new Date().toISOString()
        };

        if (!database.isEnabled()) {
            let duplicate = false;
            const updated = await updateLoyaltyAccount(email, (account) => {
                const previous = (account.transactions || []).find((entry) => entry.id === transaction.id);
                if (previous) {
                    if (previous.note !== voucher.reward || Number(previous.points) !== points) {
                        throw new Error("REDEMPTION_KEY_CONFLICT");
                    }
                    duplicate = true;
                    return;
                }
                if (account.pointsBalance < points) throw new Error("INSUFFICIENT_POINTS");
                account.pointsBalance -= points;
                account.transactions = account.transactions || [];
                account.transactions.unshift(transaction);
            });
            if (updated && !duplicate) {
                try {
                    await storeVoucherRecord(voucher);
                } catch (error) {
                    await updateLoyaltyAccount(email, (account) => {
                        const index = (account.transactions || []).findIndex((entry) => entry.id === transaction.id);
                        if (index >= 0) {
                            account.transactions.splice(index, 1);
                            account.pointsBalance += points;
                        }
                    });
                    throw error;
                }
            }
            return updated;
        }

        const client = await database.connect();
        try {
            await client.query("BEGIN");
            const locked = await client.query(
                "SELECT points_balance FROM loyalty_accounts WHERE email = $1 FOR UPDATE",
                [email]
            );
            if (locked.rowCount === 0) {
                await client.query("ROLLBACK");
                return null;
            }
            if (suppliedKey) {
                const previous = await client.query(
                    "SELECT email, points, note FROM loyalty_transactions WHERE id = $1",
                    [suppliedKey]
                );
                if (previous.rowCount > 0) {
                    const prior = previous.rows[0];
                    if (normalizeEmail(prior.email) !== normalizeEmail(email)
                        || Number(prior.points) !== points || prior.note !== voucher.reward) {
                        throw new Error("REDEMPTION_KEY_CONFLICT");
                    }
                    await client.query("COMMIT");
                    return { ...await getLoyaltyAccount(email), transactions: await getLoyaltyTransactions(email) };
                }
            }
            const balance = Number(locked.rows[0].points_balance);
            if (balance < points) throw new Error("INSUFFICIENT_POINTS");
            const remaining = balance - points;
            await client.query(
                `UPDATE loyalty_accounts
                 SET points_balance = $2, tier = $3, next_reward = $4, perks = $5::jsonb
                 WHERE email = $1`,
                [email, remaining, tierFor(remaining), nextRewardText(remaining), JSON.stringify(loyaltyPerksFor(remaining))]
            );
            await client.query(
                `INSERT INTO loyalty_transactions
                 (id, email, type, points, note, voucher_code, voucher_detail, voucher_expires_at, voucher_single_use, voucher_status, created_at)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
                [transaction.id, email, transaction.type, points, transaction.note, voucher.code,
                    voucher.detail, voucher.expiresAt, voucher.singleUse, voucher.status, transaction.createdAt]
            );
            await client.query(
                `INSERT INTO vouchers
                 (code, email, reward, points, detail, single_use, status, created_at, expires_at, used_at)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
                [voucher.code, email, voucher.reward, points, voucher.detail, voucher.singleUse,
                    voucher.status, voucher.createdAt, voucher.expiresAt, voucher.usedAt || null]
            );
            await client.query("COMMIT");
        } catch (error) {
            await client.query("ROLLBACK");
            throw error;
        } finally {
            client.release();
        }
        queueWalletPassUpdate(email);
        return { ...await getLoyaltyAccount(email), transactions: await getLoyaltyTransactions(email) };
    };
}

module.exports = { createLoyaltyRedemptionService };
