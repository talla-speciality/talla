const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const directory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-order-variants-"));
process.env.DATA_DIRECTORY = directory;
delete process.env.DATABASE_URL;
const { shopifyOrderRecord, shopifyAdminOrderRecord } = require("../server");
test.after(() => fs.rmSync(directory, { recursive: true, force: true }));

test("Shopify webhooks retain the purchased variant separately from the product", () => {
    const order = shopifyOrderRecord({ id: 1, email: "test@example.com", line_items: [
        { title: "Cup", name: "Cup - Large", variant_title: "Large", quantity: 2, variant_id: 20, sku: "CUP-L", price: "3" }
    ] });
    assert.equal(order.items[0].productTitle, "Cup");
    assert.equal(order.items[0].variantTitle, "Large");
    assert.equal(order.items[0].name, "Cup - Large");
    assert.equal(order.items[0].quantity, 2);
});

test("Shopify sync uses purchase-time variant titles even after catalog variants change or disappear", () => {
    for (const variant of [null, { id: "gid://shopify/ProductVariant/20", title: "Renamed option" }]) {
        const order = shopifyAdminOrderRecord({ id: "order-1", lineItems: { edges: [{ node: {
            name: "Coffee - 250g / Whole Bean", title: "Coffee", variantTitle: "250g / Whole Bean", quantity: 1, variant
        } }] } }, "test@example.com");
        assert.equal(order.items[0].variantTitle, "250g / Whole Bean");
        assert.equal(order.items[0].productTitle, "Coffee");
    }
});
