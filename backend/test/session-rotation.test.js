const test = require("node:test");
const assert = require("node:assert/strict");

process.env.DATABASE_URL = "postgresql://rotation-test.invalid/talla";
const database = require("../database");
const { rotateCustomerSession } = require("../server");

function fakeClient(record) {
    const statements = [];
    return {
        statements,
        async query(text, params = []) {
            statements.push({ text: String(text), params });
            if (String(text).includes("FROM customer_refresh_tokens")) {
                return { rowCount: record ? 1 : 0, rows: record ? [record] : [] };
            }
            return { rowCount: 1, rows: [] };
        },
        release() {}
    };
}

test("refresh rotation consumes the old credential and issues a replacement pair", async () => {
    const client = fakeClient({
        session_id: "session-old",
        family_id: "family-one",
        email: "customer@example.com",
        expires_at: new Date(Date.now() + 60_000),
        consumed_at: null
    });
    database.connect = async () => client;

    const session = await rotateCustomerSession("single-use-refresh-token");
    assert.match(session.accessToken, /^[0-9a-f]{64}$/);
    assert.ok(session.refreshToken.length >= 64);
    assert.notEqual(session.refreshToken, "single-use-refresh-token");
    assert.equal(client.statements.some(({ text }) => text.includes("SET consumed_at = NOW()")), true);
    assert.equal(client.statements.some(({ text }) => text.includes("rotated_from_session_id")), true);
    assert.equal(client.statements.at(-2).text.includes("revoked_at"), true);
});

test("reuse of a consumed refresh credential revokes its whole token family", async () => {
    const client = fakeClient({
        session_id: "session-old",
        family_id: "family-compromised",
        email: "customer@example.com",
        expires_at: new Date(Date.now() + 60_000),
        consumed_at: new Date()
    });
    database.connect = async () => client;

    await assert.rejects(() => rotateCustomerSession("reused-refresh-token"), { code: "REFRESH_TOKEN_REUSED" });
    const revocation = client.statements.find(({ text }) => text.includes("WHERE family_id = $1"));
    assert.deepEqual(revocation.params, ["family-compromised"]);
});
