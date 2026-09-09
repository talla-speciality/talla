const assert = require("node:assert/strict");
const test = require("node:test");
const createServer = require("../modules/application/create-server");

test("disabled Click to Pay stops creation using its own operational switch", async () => {
    let checkedKey;
    const handler = createServer({
        URL,
        host: "localhost",
        port: 0,
        http: { createServer: (callback) => callback },
        applyRateLimit: () => true,
        appAttest: { protectedPaths: new Set(), verifyRequest: async () => ({ allowed: true }) },
        requireOperationalPayment: async (key, response) => {
            checkedKey = key;
            response.statusCode = 503;
            return false;
        },
        readBody: () => assert.fail("Disabled checkout must not create a session"),
    });
    const response = { on() {} };
    await handler({ method: "POST", url: "/api/payments/click-to-pay/create", headers: {} }, response);
    assert.equal(checkedKey, "clickToPayEnabled");
    assert.equal(response.statusCode, 503);
});
