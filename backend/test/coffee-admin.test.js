const test = require("node:test");
const assert = require("node:assert/strict");
const { coffeeMetadataFromTags, createCoffeeAdminService, nextCoffeeTags, normalizeCoffeeMemorySettings } = require("../modules/brewing/coffee-admin");

test("coffee metadata round trips through managed Shopify tags", () => {
    const tags = nextCoffeeTags(["LIMITED", "Talla Origin: Old"], {
        origin: "Ethiopia", process: "Natural", bagWeightGrams: 250,
        replacementProductID: "gid://shopify/Product/9", excludeFromReplacements: true
    });
    assert.deepEqual(coffeeMetadataFromTags(tags), {
        origin: "Ethiopia", process: "Natural", bagWeightGrams: "250",
        replacementProductID: "gid://shopify/Product/9", excludeFromReplacements: true
    });
    assert.equal(tags.includes("Talla Origin: Old"), false);
    assert.equal(tags.includes("LIMITED"), true);
});

test("coffee memory switches preserve safe defaults", () => {
    assert.deepEqual(normalizeCoffeeMemorySettings({ automaticPurchaseImport: false }), {
        enabled: true, automaticPurchaseImport: false, roastDateOCR: true, replacementRecommendations: true
    });
});

test("admin coffee memory service summarizes and deletes records", async () => {
    const calls = [];
    const database = { isEnabled: () => true, query: async (sql, values) => {
        calls.push({ sql, values });
        if (sql.startsWith("SELECT COUNT")) return { rows: [{ customers: 2, lots: 3, purchased_bags: 4, shopify_imports: 2 }] };
        if (sql.startsWith("SELECT email")) return { rows: [{ email: "a@example.com", entity_type: "coffeeLot", record_id: "lot-1", payload: { name: "Guji" }, revision: 1, updated_at: "2026-09-19", updated_by_device: "shopify" }] };
        return { rows: [{ record_id: "lot-1" }] };
    } };
    const service = createCoffeeAdminService(database);
    const summary = await service.summary();
    assert.equal(summary.totals.purchasedBags, 4);
    assert.equal(summary.recentRecords[0].title, "Guji");
    assert.equal(await service.deleteRecord(" A@Example.com ", "coffeeLot", "lot-1"), true);
    assert.deepEqual(calls.at(-1).values, ["a@example.com", "coffeeLot", "lot-1"]);
    assert.match(calls.at(-1).sql, /deleted_at=NOW\(\)/);
    assert.doesNotMatch(calls.at(-1).sql, /DELETE FROM/);
});

test("admin customer coffee summary exposes Shelf, journal, sessions, and dose usage", async () => {
    const database = {
        isEnabled: () => true,
        query: async (sql) => {
            assert.match(sql, /entity_type IN \('purchasedCoffee', 'brewSession', 'doseUsage'\)/);
            return { rows: [
                {
                    entity_type: "purchasedCoffee", record_id: "bag-1", updated_at: "2026-11-07T00:00:00.000Z",
                    payload: { productName: "Hawar Islands", initialQuantityGrams: 250, remainingQuantityGrams: 214, roastDate: "2026-10-20" }
                },
                {
                    entity_type: "doseUsage", record_id: "dose-1", updated_at: "2026-11-07T00:00:00.000Z",
                    payload: { purchasedCoffeeID: "bag-1", grams: 18, createdAt: "2026-11-07T00:00:00.000Z" }
                },
                {
                    entity_type: "brewSession", record_id: "brew-1", updated_at: "2026-11-07T00:00:00.000Z",
                    payload: { title: "Morning V60", method: "V60", coffeeGrams: 18, waterGrams: 288, brewTimeSeconds: 190, isReference: true }
                }
            ] };
        }
    };
    const service = createCoffeeAdminService(database, (value) => String(value).trim().toLowerCase(), async () => ({
        brewJournal: [{ id: "journal-1", title: "Morning V60", method: "V60" }]
    }));
    const summary = await service.customerSummary("A@Example.com");

    assert.equal(summary.inventory[0].remainingQuantityGrams, 214);
    assert.equal(summary.inventory[0].usedQuantityGrams, 18);
    assert.equal(summary.brewJournal[0].title, "Morning V60");
    assert.equal(summary.brewSessions[0].isReference, true);
    assert.equal(summary.doseUsage[0].grams, 18);
});
