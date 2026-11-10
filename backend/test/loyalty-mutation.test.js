const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

process.env.DATA_DIRECTORY = fs.mkdtempSync(path.join(os.tmpdir(), "talla-loyalty-mutation-"));
process.env.DATABASE_URL = "postgresql://loyalty-mutation-test.invalid/talla";
const database = require("../database");
const { updateLoyaltyAccount } = require("../server");

const email = "mutation@example.com";
const accountRow = {
    email,
    member_id: "TALLA-MUTATION",
    points_balance: 10,
    tier: "Bronze",
    next_reward: "",
    perks: [],
    streak_days: 0,
    birthday_reward_available: false,
    cross_cafe_visits: 0,
    last_brew_date: null,
    visit_streak_days: 0,
    last_visit_date: null,
    visited_cafe_ids: []
};

function fakeDatabase(t, failInsert = false) {
    const statements = [];
    const originalConnect = database.connect;
    const originalQuery = database.query;
    database.query = async () => { throw new Error("QUERY_OUTSIDE_TRANSACTION"); };
    database.connect = async () => ({
        async query(sql, params = []) {
            const text = String(sql);
            statements.push({ text, params });
            if (text.includes("FOR UPDATE")) return { rowCount: 1, rows: [{ email }] };
            if (text.includes("FROM loyalty_accounts")) return { rowCount: 1, rows: [accountRow] };
            if (text.includes("FROM loyalty_transactions")) return { rowCount: 0, rows: [] };
            if (failInsert && text.includes("INSERT INTO loyalty_transactions")) throw new Error("HISTORY_WRITE_FAILED");
            return { rowCount: 1, rows: [] };
        },
        release() { statements.push({ text: "RELEASE", params: [] }); }
    });
    t.after(() => {
        database.connect = originalConnect;
        database.query = originalQuery;
    });
    return statements;
}

function award(account) {
    account.pointsBalance += 5;
    account.transactions.unshift({
        id: "brew:atomic-example",
        type: "earn",
        points: 5,
        note: "Brew logged",
        createdAt: "2026-11-06T00:00:00.000Z"
    });
}

test("balance and history commit on the same locked PostgreSQL client", async (t) => {
    const statements = fakeDatabase(t);
    const updated = await updateLoyaltyAccount(email, award);
    assert.equal(updated.pointsBalance, 15);
    assert.equal(updated.transactions[0].id, "brew:atomic-example");
    const texts = statements.map(({ text }) => text);
    assert.equal(texts[0], "BEGIN");
    assert.ok(texts[1].includes("FOR UPDATE"));
    assert.ok(texts.findIndex((text) => text.includes("UPDATE loyalty_accounts")) < texts.findIndex((text) => text.includes("INSERT INTO loyalty_transactions")));
    assert.deepEqual(texts.slice(-2), ["COMMIT", "RELEASE"]);
});

test("history insert failure rolls back the balance update", async (t) => {
    const statements = fakeDatabase(t, true);
    await assert.rejects(() => updateLoyaltyAccount(email, award), /HISTORY_WRITE_FAILED/);
    const texts = statements.map(({ text }) => text);
    assert.ok(texts.some((text) => text.includes("UPDATE loyalty_accounts")));
    assert.equal(texts.includes("COMMIT"), false);
    assert.deepEqual(texts.slice(-2), ["ROLLBACK", "RELEASE"]);
});
