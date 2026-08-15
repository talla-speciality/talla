const test = require("node:test");
const assert = require("node:assert/strict");

const { remotePushPayload } = require("../server");

test("urgent order updates use the time-sensitive interruption level", () => {
    const payload = remotePushPayload({
        title: "Order ready",
        body: "Your order is ready for pickup.",
        type: "order_ready"
    });

    assert.equal(payload.aps["interruption-level"], "time-sensitive");
});

test("campaign and product notifications remain at the standard interruption level", () => {
    for (const type of ["campaign", "eid_campaign", "customer_campaign", "stock_alert"]) {
        const payload = remotePushPayload({
            title: "Talla update",
            body: "Take a look in the app.",
            type
        });

        assert.equal(payload.aps["interruption-level"], undefined);
    }
});

test("an arbitrary caller cannot opt a promotion into time-sensitive delivery", () => {
    const payload = remotePushPayload({
        title: "Offer",
        body: "A promotion",
        type: "campaign",
        timeSensitive: true
    });

    assert.equal(payload.aps["interruption-level"], undefined);
});
