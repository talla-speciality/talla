const test = require("node:test");
const assert = require("node:assert/strict");
const {
    aggregateRatings,
    defaultDirectory,
    directoryFor,
    normalizeRatingInput,
    normalizeStore,
    replaceDirectory,
    ratingsFor,
    saveRating
} = require("../modules/discovery/gulf-coffee-map");

test("Gulf Coffee Map ratings validate, upsert per offering, and aggregate", () => {
    const store = normalizeStore({});
    assert.equal(normalizeRatingInput("reader@example.com", { spotID: "bhr-seef", offeringID: "bhr-seef-v60", rating: 6 }), null);

    const first = saveRating(store, "reader@example.com", {
        spotID: "bhr-seef",
        offeringID: "bhr-seef-v60",
        rating: 4
    });
    assert.equal(first.rating, 4);

    saveRating(store, "reader@example.com", {
        spotID: "bhr-seef",
        offeringID: "bhr-seef-v60",
        rating: 5
    });
    saveRating(store, "second@example.com", {
        spotID: "bhr-seef",
        offeringID: "bhr-seef-v60",
        rating: 3
    });

    assert.equal(ratingsFor(store, "reader@example.com").length, 1);
    assert.equal(ratingsFor(store, "reader@example.com")[0].rating, 5);
    assert.deepEqual(aggregateRatings(store), [{ offeringID: "bhr-seef-v60", count: 2, average: 4 }]);
});

test("Gulf Coffee Map directory has one pilot entry per GCC market and supports replacement", () => {
    const store = normalizeStore({});
    assert.equal(directoryFor(store).length, 9);
    assert.equal(defaultDirectory.find((place) => place.id === "not-just-beans").neighborhood, "Online store");
    assert.equal(defaultDirectory.find((place) => place.id === "not-just-beans").websiteURL, "https://notjustbeans.shop/collections/talla-speciality-roasters");
    assert.equal(defaultDirectory.find((place) => place.id === "hambella-riffa").city, "Riffa");
    assert.equal(defaultDirectory.find((place) => place.id === "hambella-riffa").websiteURL, "https://maps.app.goo.gl/DU2Gy8kmZ1rGYVLy6?g_st=ic");
    assert.equal(defaultDirectory.find((place) => place.id === "hambella-riffa").phone, "3332 2609");
    assert.equal(defaultDirectory.find((place) => place.id === "tumma-roast-zinj").neighborhood, "Zinj");
    assert.equal(defaultDirectory.find((place) => place.id === "tumma-roast-zinj").websiteURL, "https://maps.app.goo.gl/Kd7Fwxq9afe4nirt8?g_st=ic");
    assert.equal(defaultDirectory.find((place) => place.id === "tumma-roast-zinj").phone, "3201 6614");
    assert.deepEqual(defaultDirectory.filter((place) => ["not-just-beans", "hambella-riffa", "tumma-roast-zinj"].includes(place.id)).map((place) => place.id), ["not-just-beans", "hambella-riffa", "tumma-roast-zinj"]);
    assert.deepEqual(new Set(defaultDirectory.filter((place) => place.country !== "GCC").map((place) => place.country)), new Set([
        "Bahrain", "Saudi Arabia", "UAE", "Kuwait", "Qatar", "Oman"
    ]));
});

test("an explicitly empty admin directory stays empty", () => {
    const next = replaceDirectory(normalizeStore({}), []);
    assert.deepEqual(directoryFor(next), []);
});
