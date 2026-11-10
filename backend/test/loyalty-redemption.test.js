const assert = require("node:assert/strict");
const test = require("node:test");
const { createLoyaltyRedemptionService } = require("../modules/loyalty/redemption");

const email = "member@example.test";
const voucher = {
    code: "COFFEE-ABC123",
    email,
    reward: "Coffee Bag Credit",
    points: 50,
    detail: "Credit on a coffee bag",
    singleUse: true,
    status: "active",
    createdAt: "2026-11-06T10:00:00.000Z",
    expiresAt: "2026-12-06T10:00:00.000Z"
};

function harness({ balance = 100, failOnVoucher = false, accountExists = true, previousTransaction = null } = {}) {
    const statements = [];
    let released = false;
    let queued = false;
    const client = {
        async query(sql, params = []) {
            const text = String(sql).trim();
            statements.push({ text, params });
            if (text.includes("FROM loyalty_accounts") && text.includes("FOR UPDATE")) {
                return { rowCount: accountExists ? 1 : 0, rows: accountExists ? [{ points_balance: balance }] : [] };
            }
            if (text.includes("FROM loyalty_transactions") && text.includes("WHERE id = $1")) {
                return { rowCount: previousTransaction ? 1 : 0, rows: previousTransaction ? [previousTransaction] : [] };
            }
            if (failOnVoucher && text.startsWith("INSERT INTO vouchers")) throw new Error("VOUCHER_WRITE_FAILED");
            return { rowCount: 1, rows: [] };
        },
        release() { released = true; }
    };
    const redeem = createLoyaltyRedemptionService({
        database: { isEnabled: () => true, connect: async () => client },
        normalizeEmail: (value) => String(value).toLowerCase(),
        tierFor: () => "Bronze",
        nextRewardText: () => "50 Beans to your next reward",
        loyaltyPerksFor: () => [],
        queueWalletPassUpdate: () => { queued = true; },
        getLoyaltyAccount: async () => ({ pointsBalance: balance - voucher.points }),
        getLoyaltyTransactions: async () => [{ voucherCode: voucher.code }],
        updateLoyaltyAccount: () => { throw new Error("JSON_FALLBACK_USED"); },
        storeVoucherRecord: () => { throw new Error("SEPARATE_VOUCHER_WRITE_USED"); }
    });
    return { redeem, statements, get released() { return released; }, get queued() { return queued; } };
}

test("redemption commits Beans, history, and voucher together", async () => {
    const run = harness();
    const result = await run.redeem(email, voucher);
    assert.equal(result.pointsBalance, 50);
    assert.equal(result.transactions[0].voucherCode, voucher.code);
    assert.deepEqual(run.statements.map(({ text }) => text.split(" ")[0]),
        ["BEGIN", "SELECT", "UPDATE", "INSERT", "INSERT", "COMMIT"]);
    assert.equal(run.statements[2].params[1], 50);
    assert.equal(run.statements[3].params[5], voucher.code);
    assert.equal(run.statements[4].params[0], voucher.code);
    assert.equal(run.queued, true);
    assert.equal(run.released, true);
});

test("voucher insert failure rolls back the Beans deduction and history", async () => {
    const run = harness({ failOnVoucher: true });
    await assert.rejects(run.redeem(email, voucher), /VOUCHER_WRITE_FAILED/);
    assert.equal(run.statements.at(-1).text, "ROLLBACK");
    assert.equal(run.statements.some(({ text }) => text === "COMMIT"), false);
    assert.equal(run.queued, false);
    assert.equal(run.released, true);
});

test("insufficient Beans cannot insert a voucher", async () => {
    const run = harness({ balance: 20 });
    await assert.rejects(run.redeem(email, voucher), /INSUFFICIENT_POINTS/);
    assert.deepEqual(run.statements.map(({ text }) => text.split(" ")[0]), ["BEGIN", "SELECT", "ROLLBACK"]);
    assert.equal(run.queued, false);
});

test("file-backed voucher failure restores the Beans balance and history", async () => {
    const account = { pointsBalance: 100, transactions: [] };
    const redeem = createLoyaltyRedemptionService({
        database: { isEnabled: () => false },
        normalizeEmail: (value) => String(value).toLowerCase(),
        updateLoyaltyAccount: async (_email, mutate) => { mutate(account); return account; },
        storeVoucherRecord: async () => { throw new Error("VOUCHER_WRITE_FAILED"); }
    });
    await assert.rejects(redeem(email, voucher), /VOUCHER_WRITE_FAILED/);
    assert.equal(account.pointsBalance, 100);
    assert.deepEqual(account.transactions, []);
});

test("a replayed redemption key returns the original account without another debit", async () => {
    const key = "redeem:550e8400-e29b-41d4-a716-446655440000";
    const run = harness({ previousTransaction: { email, points: voucher.points, note: voucher.reward } });
    const result = await run.redeem(email, voucher, key);
    assert.equal(result.transactions[0].voucherCode, voucher.code);
    assert.deepEqual(run.statements.map(({ text }) => text.split(" ")[0]),
        ["BEGIN", "SELECT", "SELECT", "COMMIT"]);
});

test("a redemption key cannot be reused for a different reward", async () => {
    const key = "redeem:550e8400-e29b-41d4-a716-446655440000";
    const run = harness({ previousTransaction: { email, points: voucher.points, note: "Free Drink" } });
    await assert.rejects(run.redeem(email, voucher, key), /REDEMPTION_KEY_CONFLICT/);
    assert.equal(run.statements.at(-1).text, "ROLLBACK");
});

test("file-backed redemption replay preserves the original voucher and balance", async () => {
    const key = "redeem:550e8400-e29b-41d4-a716-446655440000";
    const account = { pointsBalance: 50, transactions: [{
        id: key, type: "redeem", points: 50, note: voucher.reward, voucherCode: "ORIGINAL-CODE"
    }] };
    let voucherWrites = 0;
    const redeem = createLoyaltyRedemptionService({
        database: { isEnabled: () => false },
        normalizeEmail: (value) => String(value).toLowerCase(),
        updateLoyaltyAccount: async (_email, mutate) => { mutate(account); return account; },
        storeVoucherRecord: async () => { voucherWrites += 1; }
    });
    const result = await redeem(email, voucher, key);
    assert.equal(result.pointsBalance, 50);
    assert.equal(result.transactions[0].voucherCode, "ORIGINAL-CODE");
    assert.equal(voucherWrites, 0);
});
