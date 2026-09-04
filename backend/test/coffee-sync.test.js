const test = require("node:test");
const assert = require("node:assert/strict");
const { hasRevisionConflict, normalizeCoffeeChange } = require("../modules/brewing/coffee-sync");

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
