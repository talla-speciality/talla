const test = require("node:test");
const assert = require("node:assert/strict");

const { mergeCustomerLibraryRecords, normalizeBrewJournalEntry } = require("../modules/brewing/customer-library");

test("customer library merge preserves records from iOS and Android without duplicates", () => {
    const merged = mergeCustomerLibraryRecords(
        {
            favorites: ["coffee-a", "coffee-b"],
            recentlyViewed: ["coffee-b", "coffee-c"],
            brewJournal: [{
                id: "journal-server",
                title: "Server brew",
                method: "V60",
                rating: 4,
                notes: "Sweet",
                createdAt: "2026-08-01T10:00:00.000Z"
            }]
        },
        {
            favorites: ["coffee-b", "coffee-c"],
            recentlyViewed: ["coffee-a", "coffee-b"],
            brewJournal: [{
                id: "journal-phone",
                title: "Phone brew",
                method: "Chemex",
                rating: 5,
                notes: "Floral",
                createdAt: "2026-08-02T10:00:00.000Z"
            }]
        }
    );

    assert.deepEqual(merged.favorites, ["coffee-b", "coffee-c", "coffee-a"]);
    assert.deepEqual(merged.recentlyViewed, ["coffee-a", "coffee-b", "coffee-c"]);
    assert.deepEqual(merged.brewJournal.map((entry) => entry.id), ["journal-phone", "journal-server"]);
});

test("brew journal normalization clamps ratings and rejects malformed entries", () => {
    assert.equal(normalizeBrewJournalEntry({ id: "", title: "Coffee", method: "V60" }), null);
    const entry = normalizeBrewJournalEntry({
        id: "journal-1",
        title: "Morning cup",
        method: "V60",
        coffeeGrams: 20,
        ratio: 15,
        waterGrams: 300,
        brewTimeSeconds: 180,
        rating: 99,
        notes: "Balanced",
        createdAt: "2026-08-30T12:00:00.000Z"
    });
    assert.equal(entry.rating, 5);
    assert.equal(entry.createdAt, "2026-08-30T12:00:00.000Z");
});
