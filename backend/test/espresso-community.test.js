const test = require("node:test");
const assert = require("node:assert/strict");

const { normalizeProfile, normalizeRoasterRecipe } = require("../modules/brewing/espresso-community");

test("espresso profile normalization clamps measurements and marks it pending", () => {
    const profile = normalizeProfile({
        title: "House shot",
        machine: "Linea Mini",
        doseGrams: 999,
        yieldGrams: 0,
        temperatureC: 120,
        equipmentTags: ["Linea Mini", "home"]
    }, "barista@example.com");
    assert.equal(profile.doseGrams, 60);
    assert.equal(profile.yieldGrams, 1);
    assert.equal(profile.temperatureC, 105);
    assert.equal(profile.status, "pending");
    assert.equal(profile.ownerEmail, "barista@example.com");
});

test("roaster recipes require publisher identity and core coffee fields", () => {
    assert.equal(normalizeRoasterRecipe({ title: "Missing coffee", roaster: "Talla" }, "roaster@example.com"), null);
    const recipe = normalizeRoasterRecipe({ title: "House espresso", roaster: "Talla", coffeeName: "Bani Jamra" }, "roaster@example.com");
    assert.equal(recipe.status, "pending");
    assert.equal(recipe.publisherEmail, "roaster@example.com");
});
