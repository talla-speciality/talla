const assert = require("node:assert/strict");
const test = require("node:test");
const { Pool } = require("pg");

process.env.DATABASE_URL = "postgresql://migration-test.invalid/talla";
process.env.PGSSLMODE = "disable";
const database = require("../database");

async function withFakeClient(t, failMigration = false) {
    const statements = [];
    const originalConnect = Pool.prototype.connect;
    const originalQuery = Pool.prototype.query;
    Pool.prototype.query = async () => { throw new Error("POOL_QUERY_BYPASSED_CLIENT"); };
    Pool.prototype.connect = async () => ({
        async query(sql, params = []) {
            const text = String(sql);
            statements.push({ text, params });
            if (text.includes("FROM schema_migrations")) {
                return { rowCount: params[0] === "034_card_payment_active_order" ? 0 : 1, rows: [] };
            }
            if (failMigration && text.includes("CREATE UNIQUE INDEX")) throw new Error("MIGRATION_FAILED");
            return { rowCount: 1, rows: [] };
        },
        release() { statements.push({ text: "RELEASE", params: [] }); }
    });
    t.after(() => {
        Pool.prototype.connect = originalConnect;
        Pool.prototype.query = originalQuery;
    });
    return statements;
}

test("migrations use one locked client from schema creation through commit", async (t) => {
    const statements = await withFakeClient(t);
    await database.initializeDatabase();
    const texts = statements.map(({ text }) => text);
    const begin = texts.indexOf("BEGIN");
    const migration = texts.findIndex((text) => text.includes("CREATE UNIQUE INDEX"));
    const record = texts.findIndex((text) => text.includes("INSERT INTO schema_migrations"));
    const commit = texts.indexOf("COMMIT");
    assert.ok(texts[0].includes("pg_advisory_lock"));
    assert.ok(begin >= 0 && begin < migration && migration < record && record < commit);
    assert.ok(texts.at(-2).includes("pg_advisory_unlock"));
    assert.equal(texts.at(-1), "RELEASE");
});

test("a failed migration rolls back before releasing the startup lock", async (t) => {
    const statements = await withFakeClient(t, true);
    await assert.rejects(() => database.initializeDatabase(), /MIGRATION_FAILED/);
    const texts = statements.map(({ text }) => text);
    assert.ok(texts.includes("BEGIN"));
    assert.ok(texts.includes("ROLLBACK"));
    assert.equal(texts.includes("COMMIT"), false);
    assert.ok(texts.at(-2).includes("pg_advisory_unlock"));
    assert.equal(texts.at(-1), "RELEASE");
});
