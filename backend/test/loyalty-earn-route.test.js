const assert = require("node:assert/strict");
const test = require("node:test");
const createServer = require("../modules/application/create-server");

test("customers cannot mint mission or achievement Beans through a supplied key", async () => {
    const responses = [];
    const handler = createServer({
        URL,
        host: "localhost",
        port: 0,
        http: { createServer: (callback) => callback },
        applyRateLimit: () => true,
        benefitPathMatches: () => false,
        isBenefitBrowserReturnPath: () => false,
        appAttest: { protectedPaths: new Set(), verifyRequest: async () => ({ allowed: true }) },
        readBody: () => assert.fail("Unverified earn payload must not be parsed"),
        updateLoyaltyAccount: () => assert.fail("Unverified earn payload must not change balance"),
        sendJSON: (_response, status, body) => responses.push({ status, body })
    });
    for (const key of ["phase6:mission:2030-01", "phase6:achievement"]) {
        await handler({ method: "POST", url: "/loyalty/transactions/earn", headers: {}, body: JSON.stringify({ points: 40, idempotencyKey: key }) }, { on() {} });
    }
    assert.equal(responses.length, 2);
    assert.ok(responses.every(({ status, body }) => status === 403 && /verified server activity/i.test(body.error)));
});
