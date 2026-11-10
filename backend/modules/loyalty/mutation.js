function createLoyaltyMutationService({
    database, readJSON, writeJSON, loyaltyStorePath, getLoyaltyAccount,
    getLoyaltyTransactions, tierFor, nextRewardText, loyaltyPerksFor, queueWalletPassUpdate
}) {
    return async function updateLoyaltyAccount(email, mutate) {
        if (!database.isEnabled()) {
            const store = readJSON(loyaltyStorePath);
            const account = store.accounts[email];
            if (!account) return null;
            mutate(account);
            account.tier = tierFor(account.pointsBalance);
            account.nextReward = nextRewardText(account.pointsBalance);
            account.perks = loyaltyPerksFor(account.pointsBalance);
            writeJSON(loyaltyStorePath, store);
            queueWalletPassUpdate(email);
            return account;
        }

        const client = await database.connect();
        let updatedAccount;
        try {
            await client.query("BEGIN");
            const locked = await client.query("SELECT email FROM loyalty_accounts WHERE email = $1 FOR UPDATE", [email]);
            if (locked.rowCount === 0) {
                await client.query("ROLLBACK");
                return null;
            }
            const account = await getLoyaltyAccount(email, client);
            const working = { ...account, transactions: await getLoyaltyTransactions(email, client) };
            const beforeCount = working.transactions.length;
            mutate(working);
            if (!Number.isSafeInteger(working.pointsBalance) || working.pointsBalance < 0) {
                throw new Error("INVALID_LOYALTY_BALANCE");
            }
            working.tier = tierFor(working.pointsBalance);
            working.nextReward = nextRewardText(working.pointsBalance);
            working.perks = loyaltyPerksFor(working.pointsBalance);

            await client.query(
                `UPDATE loyalty_accounts
                 SET points_balance = $2, tier = $3, next_reward = $4, perks = $5::jsonb,
                     streak_days = $6, birthday_reward_available = $7, cross_cafe_visits = $8, last_brew_date = $9,
                     visit_streak_days = $10, last_visit_date = $11, visited_cafe_ids = $12::jsonb
                 WHERE email = $1`,
                [email, working.pointsBalance, working.tier, working.nextReward, JSON.stringify(working.perks),
                    Number(working.streakDays || 0), Boolean(working.birthdayRewardAvailable),
                    Number(working.crossCafeVisits || 0), working.lastBrewDate || null,
                    Number(working.visitStreakDays || 0), working.lastVisitDate || null,
                    JSON.stringify(Array.isArray(working.visitedCafeIDs) ? working.visitedCafeIDs : [])]
            );

            const newTransactions = working.transactions.slice(0, working.transactions.length - beforeCount);
            for (const transaction of newTransactions) {
                await client.query(
                    `INSERT INTO loyalty_transactions
                     (id, email, type, points, note, voucher_code, voucher_detail, voucher_expires_at, voucher_single_use, voucher_status, created_at)
                     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
                    [transaction.id, email, transaction.type, transaction.points, transaction.note,
                        transaction.voucherCode || null, transaction.voucherDetail || null,
                        transaction.voucherExpiresAt || null, transaction.voucherSingleUse ?? null,
                        transaction.voucherStatus || null, transaction.createdAt]
                );
            }
            await client.query("COMMIT");
            updatedAccount = working;
        } catch (error) {
            await client.query("ROLLBACK");
            throw error;
        } finally {
            client.release();
        }
        queueWalletPassUpdate(email);
        return updatedAccount;
    };
}

module.exports = { createLoyaltyMutationService };
