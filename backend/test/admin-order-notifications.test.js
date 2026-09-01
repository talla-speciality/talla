const test = require("node:test");
const assert = require("node:assert/strict");

const { adminOrderNotificationPayload, normalizeWebPushSubscription } = require("../server");

test("admin new-order notifications contain useful order context", () => {
    const order = {
        id: "shopify_1842",
        title: "#1842",
        total: "BHD 12.500",
        items: [{ name: "Brazil", quantity: 2 }, { name: "Cup", quantity: 1 }]
    };
    const payload = adminOrderNotificationPayload(order);

    assert.equal(payload.title, "New Talla order");
    assert.match(payload.body, /#1842/);
    assert.match(payload.body, /BHD 12\.500/);
    assert.match(payload.body, /3 items/);
    assert.equal(payload.order.id, order.id);
    assert.equal(payload.url, "/admin/#orders-section");
});

test("admin push subscriptions require an HTTPS endpoint and both browser keys", () => {
    assert.equal(normalizeWebPushSubscription({ endpoint: "http://push.example", keys: { auth: "a", p256dh: "b" } }), null);
    assert.equal(normalizeWebPushSubscription({ endpoint: "https://push.example", keys: { auth: "", p256dh: "b" } }), null);
    assert.deepEqual(
        normalizeWebPushSubscription({ endpoint: "https://push.example/device", keys: { auth: "auth", p256dh: "key" } }),
        { endpoint: "https://push.example/device", expirationTime: null, keys: { auth: "auth", p256dh: "key" } }
    );
});
