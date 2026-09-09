const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const directory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-order-echo-"));
process.env.DATA_DIRECTORY = directory;
process.env.SHOPIFY_ADMIN_SHOP_DOMAIN = "shop.test";
process.env.SHOPIFY_ADMIN_ACCESS_TOKEN = "test-token";
delete process.env.DATABASE_URL;
const { localOrderForShopifyExport, processShopifyOrderWebhook, syncRecentShopifyOrdersForEmail, shopifyOrderCreateInput } = require("../server");
const original = {
    id: "checkout_echo", email: "customer@example.com", title: "App order", total: "BHD 6.400",
    status: "Completed", items: [{ name: "Coffee", variantTitle: "Large", quantity: 1 }],
    createdAt: "2026-09-08T10:00:00Z", details: { fulfillmentMethod: "delivery" }
};
const input = shopifyOrderCreateInput(original);
const payload = { id: 9001, email: original.email, source_identifier: original.id, tags: input.tags.join(", "), fulfillment_status: "fulfilled" };
const ordersPath = path.join(directory, "orders.json");
const exportsPath = path.join(directory, "shopifyOrderExports.json");

test.beforeEach(() => {
    fs.writeFileSync(ordersPath, JSON.stringify({ orders: { [original.email]: [original] } }));
    fs.writeFileSync(exportsPath, JSON.stringify({ exports: {} }));
});
test.after(() => fs.rmSync(directory, { recursive: true, force: true }));

test("repeated fulfillment callbacks before export persistence keep one completed order", async () => {
    const before = fs.readFileSync(ordersPath, "utf8");
    for (const topic of ["orders/create", "orders/paid", "orders/fulfilled", "orders/fulfilled"]) {
        const result = await processShopifyOrderWebhook(payload, topic);
        assert.equal(result.recorded, true);
        assert.equal(result.order.id, original.id);
        assert.equal(result.order.status, "Completed");
        assert.deepEqual(result.order.items, original.items);
        assert.equal(result.award, null);
    }
    assert.equal(fs.readFileSync(ordersPath, "utf8"), before);
});

test("saved Shopify mapping recognises callbacks even when tags and source are missing", async () => {
    fs.writeFileSync(exportsPath, JSON.stringify({ exports: { [original.id]: {
        localOrderID: original.id, shopifyOrderGID: "gid://shopify/Order/9001"
    } } }));
    assert.equal((await localOrderForShopifyExport({ id: 9001 })).id, original.id);
    assert.equal((await localOrderForShopifyExport({ id: "gid://shopify/Order/9001" })).id, original.id);
});

test("customer order refresh recognises the same app export", async () => {
    const before = fs.readFileSync(ordersPath, "utf8");
    global.fetch = async (_url, options) => {
        const request = JSON.parse(options.body);
        assert.match(request.query, /sourceIdentifier/);
        assert.match(request.query, /tags/);
        return new Response(JSON.stringify({ data: { orders: { edges: [{ node: {
            id: "gid://shopify/Order/9001", sourceIdentifier: original.id, tags: input.tags, email: original.email
        } }] } } }));
    };
    assert.equal((await syncRecentShopifyOrdersForEmail(original.email)).syncedCount, 1);
    assert.equal(fs.readFileSync(ordersPath, "utf8"), before);
});

test("unrelated Shopify orders and invalid source claims are not matched", async () => {
    for (const candidate of [{ id: 8000 }, { ...payload, tags: [] }, { ...payload, email: "other@example.com" }, { ...payload, source_identifier: "missing" }]) {
        assert.equal(await localOrderForShopifyExport(candidate), null);
    }
});
