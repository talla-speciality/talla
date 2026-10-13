const test = require("node:test");
const assert = require("node:assert/strict");
const { buildCoffeeInsights } = require("../modules/discovery/coffee-insights");

test("coffee insights calculate remaining brews and a replacement target", () => {
    const result = buildCoffeeInsights({
        records: [{ entityType: "purchasedCoffee", recordId: "bag-1", payload: { productID: "old", productName: "House Espresso", initialQuantityGrams: 250, remainingQuantityGrams: 36, replacementProductID: "new" } }],
        doseGrams: 18
    });
    assert.equal(result.inventory[0].estimatedBrews, 2);
    assert.equal(result.reorder[0].replacementProductID, "new");
    assert.match(result.reorder[0].reason, /brews left/);
});

test("coffee insights expose freshness and ignore empty bags", () => {
    const result = buildCoffeeInsights({
        records: [
            { entityType: "purchasedCoffee", payload: { productName: "Old Bag", remainingQuantityGrams: 20, roastDate: "2026-08-01T00:00:00.000Z" } },
            { entityType: "purchasedCoffee", payload: { productName: "Empty Bag", remainingQuantityGrams: 0 } }
        ],
        now: new Date("2026-10-01T00:00:00.000Z")
    });
    assert.equal(result.inventory.length, 1);
    assert.equal(result.inventory[0].freshness.state, "stale-risk");
    assert.equal(result.freshness["stale-risk"], 1);
});
