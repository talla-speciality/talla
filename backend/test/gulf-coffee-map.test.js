const test = require("node:test");
const assert = require("node:assert/strict");
const {
    aggregateRatings,
    defaultDirectory,
    directoryFor,
    normalizeRatingInput,
    normalizeStore,
    publicReviews,
    replaceDirectory,
    ratingsFor,
    eventRSVPsFor,
    eventRSVPSummary,
    saveEventRSVP,
    saveRating
} = require("../modules/discovery/gulf-coffee-map");

test("Gulf Coffee Map ratings validate, upsert per offering, and aggregate", () => {
    const store = normalizeStore({});
    assert.equal(normalizeRatingInput("reader@example.com", { spotID: "bhr-seef", offeringID: "bhr-seef-v60", rating: 6 }), null);

    const first = saveRating(store, "reader@example.com", {
        spotID: "bhr-seef",
        offeringID: "bhr-seef-v60",
        rating: 4,
        note: "Peach and tea-like."
    });
    assert.equal(first.rating, 4);

    saveRating(store, "reader@example.com", {
        spotID: "bhr-seef",
        offeringID: "bhr-seef-v60",
        rating: 5,
        note: "Still bright after the update."
    });
    saveRating(store, "second@example.com", {
        spotID: "bhr-seef",
        offeringID: "bhr-seef-v60",
        rating: 3
    });

    assert.equal(ratingsFor(store, "reader@example.com").length, 1);
    assert.equal(ratingsFor(store, "reader@example.com")[0].rating, 5);
    assert.deepEqual(aggregateRatings(store), [{ offeringID: "bhr-seef-v60", count: 2, average: 4, reviewCount: 1 }]);
    assert.deepEqual(publicReviews(store).map(({ offeringID, rating, note }) => ({ offeringID, rating, note })), [
        { offeringID: "bhr-seef-v60", rating: 5, note: "Still bright after the update." }
    ]);
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

test("directory profiles preserve verified regional knowledge safely", () => {
    const next = replaceDirectory(normalizeStore({}), [{
        id: "bhr-test",
        name: "Test Roaster",
        city: "Manama",
        country: "Bahrain",
        description: { en: "A careful profile.", ar: "ملف موثق." },
        tastingNotes: { en: "Date, cocoa", ar: "تمر، كاكاو" },
        verifiedAt: "2026-10-12T00:00:00.000Z",
        verifiedBy: "editor@example.com",
        lastCheckedAt: "2026-10-12T00:00:00.000Z",
        sourceURL: "https://example.com/roaster",
        offerings: [{
            id: "bhr-test-bean",
            name: "House lot",
            detail: "Cocoa · date",
            detailAR: "كاكاو · تمر",
            kind: "bean",
            brewMethod: "V60",
            brewRatio: "15 g · 250 g",
            brewTip: "Start with a medium grind."
        }],
        events: [{ id: "bhr-test-cupping", title: { en: "Friday cupping", ar: "جلسة تذوق الجمعة" }, startsAt: "2026-10-16T16:00:00.000Z", kind: "cupping", url: "https://example.com/cupping" }]
    }]);
    const profile = directoryFor(next)[0];
    assert.equal(profile.description.ar, "ملف موثق.");
    assert.equal(profile.offerings[0].brewMethod, "V60");
    assert.equal(profile.events[0].title.ar, "جلسة تذوق الجمعة");
    assert.equal(profile.events[0].status, "published");
});

test("published Gulf Coffee Map events support idempotent RSVPs", () => {
    const store = normalizeStore({ directory: [{
        id: "bhr-test",
        name: "Test Roaster",
        city: "Manama",
        country: "Bahrain",
        events: [{ id: "cupping-1", title: { en: "Friday cupping" }, startsAt: "2026-10-16T16:00:00.000Z", status: "published" }]
    }] });
    const first = saveEventRSVP(store, "reader@example.com", { spotID: "bhr-test", eventID: "cupping-1" });
    const second = saveEventRSVP(store, "reader@example.com", { spotID: "bhr-test", eventID: "cupping-1" });
    assert.equal(first.eventID, "cupping-1");
    assert.equal(second.id, first.id);
    assert.equal(eventRSVPsFor(store, "reader@example.com").length, 1);
    assert.equal(saveEventRSVP(store, "reader@example.com", { spotID: "bhr-test", eventID: "missing" }), null);
    assert.equal(eventRSVPSummary(store)[0].rsvpCount, 1);
});
