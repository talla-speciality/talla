const assert = require("node:assert/strict");
const test = require("node:test");
const { orderItemOptions, snapshotCheckoutOptions } = require("../modules/commerce/order-item-options");

test("purchase snapshots preserve named size and grind options", () => {
    assert.deepEqual(orderItemOptions({ productTitle: " Coffee ", variantTitle: "250g / Whole Bean", selectedOptions: [
        { name: "Weight", value: "250g" }, { name: "Grind", value: "Whole Bean" }
    ] }), { productTitle: "Coffee", variantTitle: "250g / Whole Bean", selectedOptions: [
        { name: "Weight", value: "250g" }, { name: "Grind", value: "Whole Bean" }
    ] });
});

test("default variants and malformed options do not create misleading labels", () => {
    assert.deepEqual(orderItemOptions({ variantTitle: " Default Title ", selectedOptions: [
        null, { name: "Title", value: "Default Title" }, { name: "Size", value: "" }, { value: "Small" }
    ] }), {});
    assert.deepEqual(orderItemOptions({}), {});
});

test("legacy checkout snapshots fetch options once and preserve quantities and prices", async () => {
    const items = [{ name: "Cup", quantity: 2, variantId: "gid://shopify/ProductVariant/1", unitPrice: "BHD 2.000" }];
    const result = await snapshotCheckoutOptions(items, async (_query, variables) => {
        assert.deepEqual(variables.ids, [items[0].variantId]);
        return { nodes: [{ id: items[0].variantId, title: "Large", product: { title: "Cup" }, selectedOptions: [{ name: "Size", value: "Large" }] }] };
    });
    assert.equal(result[0].variantTitle, "Large");
    assert.equal(result[0].quantity, 2);
    assert.equal(result[0].unitPrice, "BHD 2.000");
    assert.equal(items[0].variantTitle, undefined);
});

test("missing catalog variants and lookup errors preserve legacy checkout items", async () => {
    const items = [{ name: "Cup", quantity: 1, variantId: "gid://shopify/ProductVariant/1" }];
    assert.deepEqual(await snapshotCheckoutOptions(items, async () => ({ nodes: [null] })), items);
    assert.deepEqual(await snapshotCheckoutOptions(items, async () => { throw new Error("unavailable"); }), items);
});
