const test = require("node:test");
const assert = require("node:assert/strict");
const { normalizeTelemetryBatch, normalizeTelemetryEvent, safeProperties } = require("../telemetry");

test("normalizes mobile product and diagnostics events", () => {
    const event = normalizeTelemetryEvent({
        eventName: "checkout_started",
        category: "analytics",
        platform: "ios",
        anonymousId: "install-1",
        sessionId: "session-1",
        appVersion: "2.4.0",
        occurredAt: new Date().toISOString(),
        properties: { itemCount: 2, method: "benefit", success: true }
    });
    assert.equal(event.eventName, "checkout_started");
    assert.deepEqual(event.properties, { itemCount: 2, method: "benefit", success: true });
});

test("drops malformed events and sensitive properties", () => {
    assert.equal(normalizeTelemetryEvent({ eventName: "BAD EVENT" }), null);
    assert.deepEqual(safeProperties({ token: "secret", cardNumber: "4111", rating: 5 }), { rating: 5 });
});

test("caps telemetry batches", () => {
    const events = Array.from({ length: 60 }, (_, index) => ({
        eventName: "retention_active",
        category: "analytics",
        platform: "android",
        anonymousId: `install-${index}`,
        sessionId: "session",
        occurredAt: new Date().toISOString()
    }));
    assert.equal(normalizeTelemetryBatch({ events }).length, 50);
});
