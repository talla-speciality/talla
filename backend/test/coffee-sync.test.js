const test = require("node:test");
const assert = require("node:assert/strict");
const {
    createCoffeeSyncService,
    hasRevisionConflict,
    normalizeCoffeeChange
} = require("../modules/brewing/coffee-sync");

test("normalizes a valid coffee sync record", () => {
    const value = normalizeCoffeeChange({ entityType: "recipe", id: "550e8400-e29b-41d4-a716-446655440000", payload: { title: "V60" }, baseRevision: 2 });
    assert.equal(value.entityType, "recipe");
    assert.equal(value.baseRevision, 2);
});

test("rejects unknown models and malformed IDs", () => {
    assert.equal(normalizeCoffeeChange({ entityType: "order", id: "nope", payload: {} }), null);
});

test("detects stale edits but permits initial inserts", () => {
    assert.equal(hasRevisionConflict(null, 0), false);
    assert.equal(hasRevisionConflict(4, 3), true);
    assert.equal(hasRevisionConflict(4, 4), false);
});

test("sync service preserves the server record when revisions conflict", async () => {
    const serverRow = {
        entity_type: "recipe",
        record_id: "550e8400-e29b-41d4-a716-446655440000",
        payload: { title: "Server recipe" },
        revision: 4,
        updated_at: new Date("2026-09-05T10:00:00.000Z"),
        deleted_at: null,
        sync_cursor: 9
    };
    const statements = [];
    const client = {
        async query(sql) {
            statements.push(sql);
            if (sql.includes("FOR UPDATE")) return { rows: [serverRow] };
            if (sql.includes("sync_cursor>$2")) return { rows: [] };
            return { rows: [] };
        },
        release() {}
    };
    const synchronize = createCoffeeSyncService({ async connect() { return client; } });

    const result = await synchronize("coffee@example.com", "device-1", "9", [{
        entityType: "recipe",
        id: serverRow.record_id,
        payload: { title: "Offline edit" },
        baseRevision: 3
    }]);

    assert.deepEqual(result.conflicts, [{ entityType: "recipe", id: serverRow.record_id, serverRevision: 4 }]);
    assert.equal(result.records[0].payload.title, "Server recipe");
    assert.equal(statements.some((sql) => sql.includes("INSERT INTO coffee_records")), false);
    assert.equal(statements.at(-1), "COMMIT");
});
