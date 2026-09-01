const test = require("node:test");
const assert = require("node:assert/strict");

const { remotePushPayload, stockAlertStatusFor } = require("../server");

test("availability alerts describe the real product state without watch terminology", () => {
    assert.equal(
        stockAlertStatusFor({ isAvailableForSale: false }, null),
        "Waiting for availability"
    );
    assert.equal(
        stockAlertStatusFor(
            { isAvailableForSale: true },
            { isAvailableForSale: false }
        ),
        "Back in stock"
    );
    assert.equal(
        stockAlertStatusFor({ isAvailableForSale: true }, null),
        "Available now"
    );
});

test("urgent order updates use the time-sensitive interruption level", () => {
    const payload = remotePushPayload({
        title: "Order ready",
        body: "Your order is ready for pickup.",
        type: "order_ready"
    });

    assert.equal(payload.aps["interruption-level"], "time-sensitive");
});

test("native admin new-order alerts carry the order ID and are time-sensitive", () => {
    const payload = remotePushPayload({
        title: "New Talla order",
        body: "#1842 • BHD 12.500",
        type: "admin_new_order",
        orderID: "shopify_1842"
    });

    assert.equal(payload.aps["interruption-level"], "time-sensitive");
    assert.equal(payload.orderID, "shopify_1842");
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
