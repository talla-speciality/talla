const test = require("node:test");
const assert = require("node:assert/strict");

const { normalizeProfile, normalizeRoasterRecipe, visibleCommunity } = require("../modules/brewing/espresso-community");

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

test("community visibility exposes approved equipment matches and private owner records", () => {
    const result = visibleCommunity({
        profiles: [
            { id: "approved", status: "approved", machine: "Linea Mini", ownerEmail: "other@example.com" },
            { id: "pending-own", status: "pending", machine: "Other", ownerEmail: "me@example.com" },
            { id: "pending-other", status: "pending", machine: "Linea Mini", ownerEmail: "other@example.com" }
        ],
        roasterRecipes: [{ id: "recipe", status: "approved" }, { id: "hidden", status: "pending" }],
        startingPoints: [{ id: "start", machine: "Linea Mini" }],
        videoAssessments: [{ id: "video", ownerEmail: "me@example.com" }, { id: "private", ownerEmail: "other@example.com" }]
    }, "me@example.com", "Linea Mini");
    assert.deepEqual(result.profiles.map((item) => item.id), ["approved", "pending-own"]);
    assert.deepEqual(result.roasterRecipes.map((item) => item.id), ["recipe"]);
    assert.deepEqual(result.startingPoints.map((item) => item.id), ["start"]);
    assert.deepEqual(result.videoAssessments.map((item) => item.id), ["video"]);
});
