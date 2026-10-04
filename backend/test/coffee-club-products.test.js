const assert = require("node:assert/strict");
const test = require("node:test");
const { coffeeClubProductEligible } = require("../modules/commerce/coffee-club-products");

function product(title, productType, handle, tags = []) {
    return { product: { title, productType, tags, collections: { nodes: [{ handle }] } } };
}

test("future plan swaps are restricted to products eligible for that plan", () => {
    const arabicBeans = product("Arabic Coffee", "Coffee Beans", "arabic-coffee-beans");
    const dripBags = product("Weekly Drip Bags", "Coffee", "drip-bags");
    const filters = product("V60 Paper Filters", "Coffee Equipment", "coffee-equipment");
    const arabicFilters = product("فلاتر قهوة", "Coffee Equipment", "coffee-equipment");
    const descaler = product("Espresso Machine Descaler", "Coffee Equipment Consumable", "coffee-equipment");
    const grinder = product("Coffee Grinder", "Coffee Equipment", "coffee-equipment");
    const seasonalBox = product("Talla Box", "Gift", "gifts", ["Arabic"]);

    assert.equal(coffeeClubProductEligible("office", arabicBeans), true);
    assert.equal(coffeeClubProductEligible("arabic-coffee", arabicBeans), true);
    assert.equal(coffeeClubProductEligible("arabic-coffee", product("Colombia", "Coffee Beans", "coffee-beans")), false);
    assert.equal(coffeeClubProductEligible("office", dripBags), false);
    assert.equal(coffeeClubProductEligible("drip-bags", dripBags), true);
    assert.equal(coffeeClubProductEligible("filters", filters), true);
    assert.equal(coffeeClubProductEligible("filters", arabicFilters), true);
    assert.equal(coffeeClubProductEligible("equipment", descaler), true);
    assert.equal(coffeeClubProductEligible("equipment", grinder), false);
    assert.equal(coffeeClubProductEligible("seasonal-box", seasonalBox), true);
    assert.equal(coffeeClubProductEligible("arabic-coffee", seasonalBox), false);
    assert.equal(coffeeClubProductEligible("beans", seasonalBox), false);
});
