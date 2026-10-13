const test = require("node:test");
const assert = require("node:assert/strict");
const { freshnessState, recommendNextCup } = require("../modules/discovery/next-cup-recommendations");

test("next cup favors loved taste signals and explains the choice", () => {
    const result = recommendNextCup({ products: [{ id: "floral", title: "Ethiopia Floral", tags: ["floral", "washed"], availableForSale: true }, { id: "nutty", title: "Brazil Nutty", tags: ["nutty"], availableForSale: true }], tasteMemory: [{ productName: "Ethiopia", reaction: "loved", tags: ["Floral"] }] });
    assert.equal(result.recommendations[0].productID, "floral");
    assert.match(result.recommendations[0].recommendation.summary, /enjoyed before/);
    assert.deepEqual(result.recommendations[0].actions.map((action) => action.kind), ["brew", "buy", "save"]);
});

test("next cup penalizes disliked signals and supports explicit requests", () => {
    const result = recommendNextCup({ query: "nutty", products: [{ id: "floral", title: "Ethiopia Floral", tags: ["floral"], availableForSale: true }, { id: "nutty", title: "Brazil Nutty", tags: ["nutty"], availableForSale: true }], tasteMemory: [{ productName: "Ethiopia", reaction: "not-for-me", tags: ["Nutty"] }] });
    assert.equal(result.recommendations[0].productID, "nutty");
    assert.match(result.recommendations[0].recommendation.summary, /current request/);
});

test("freshness is safe when roast date is missing and warns after 45 days", () => {
    assert.deepEqual(freshnessState({}), { state: "unknown", days: null });
    assert.equal(freshnessState({ roastDate: "2026-08-01T00:00:00.000Z" }, new Date("2026-10-01T00:00:00.000Z")).state, "stale-risk");
});

test("next cup exposes synced bag freshness at the top level", () => {
    const result = recommendNextCup({
        products: [{ id: "new", title: "Fresh Coffee", availableForSale: true }],
        coffeeInsights: { inventory: [{ freshness: { state: "stale-risk", days: 60 } }], reorder: [] }
    });
    assert.deepEqual(result.freshness, { state: "stale-risk", days: 60 });
});
