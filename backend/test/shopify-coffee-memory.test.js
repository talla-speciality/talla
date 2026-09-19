const test = require("node:test");
const assert = require("node:assert/strict");
const { gramsForItem, importShopifyCoffeePurchases, isCoffeeItem, stableUUID } = require("../modules/brewing/shopify-coffee-memory");

test("recognizes coffee merchandise and excludes equipment", () => {
    assert.equal(isCoffeeItem({ productType: "Coffee", name: "Guji Natural" }), true);
    assert.equal(isCoffeeItem({ tags: ["single origin"], name: "Los Pirineos" }), true);
    assert.equal(isCoffeeItem({ productType: "Coffee equipment", name: "V60 Dripper" }), false);
});

test("derives stable IDs and bag weights", () => {
    assert.equal(stableUUID("same"), stableUUID("same"));
    assert.match(stableUUID("same"), /^[0-9a-f-]{36}$/);
    assert.equal(gramsForItem({ variantTitle: "1 kg" }), 1000);
    assert.equal(gramsForItem({ grams: 250 }), 250);
});

test("imports a Shopify coffee lot and purchase idempotently", async () => {
    const calls = [];
    const database = { isEnabled: () => true, query: async (sql, values) => { calls.push({ sql, values }); return { rowCount: 1 }; } };
    const order = { id: "shopify_1", email: "coffee@example.com", createdAt: "2026-09-19T10:00:00Z", items: [
        { name: "Guji Natural", productType: "Coffee", productId: "10", variantId: "20", grams: 250, quantity: 2 }
    ] };
    assert.equal(await importShopifyCoffeePurchases(database, order), 1);
    assert.equal(calls.length, 2);
    assert.equal(calls[0].values[1], "coffeeLot");
    assert.equal(calls[1].values[1], "purchasedCoffee");
    assert.equal(JSON.parse(calls[1].values[3]).initialQuantityGrams, 500);
});
