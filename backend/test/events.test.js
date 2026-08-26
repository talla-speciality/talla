const test = require("node:test");
const assert = require("node:assert/strict");

const { activeEventSettings, eventSettingsFromLegacyEid, normalizeEventSettings } = require("../server");

test("event settings sanitize content, URLs, colors, and duplicate products", () => {
    const settings = normalizeEventSettings({
        events: [{
            id: " World Cup 2026 ",
            enabled: true,
            name: "World Cup 2026",
            titleEN: "Match Days",
            imageURL: "http://insecure.example/banner.jpg",
            accentHex: "#12abEF",
            secondaryHex: "not-a-color",
            productIDs: ["gid://shopify/Product/1", "gid://shopify/Product/1", ""]
        }]
    });

    assert.equal(settings.events[0].id, "world-cup-2026");
    assert.equal(settings.events[0].imageURL, "");
    assert.equal(settings.events[0].accentHex, "#12ABEF");
    assert.equal(settings.events[0].secondaryHex, "#2A1D14");
    assert.deepEqual(settings.events[0].productIDs, ["gid://shopify/Product/1"]);
});

test("the public event feed includes only enabled events inside their schedule", () => {
    const settings = normalizeEventSettings({
        events: [
            { id: "live", enabled: true, name: "Live", titleEN: "Live", priority: 5, startAt: "2026-01-01T00:00:00.000Z", endAt: "2026-12-31T00:00:00.000Z" },
            { id: "later", enabled: true, name: "Later", titleEN: "Later", startAt: "2027-01-01T00:00:00.000Z" },
            { id: "ended", enabled: true, name: "Ended", titleEN: "Ended", endAt: "2026-01-01T00:00:00.000Z" },
            { id: "off", enabled: false, name: "Off", titleEN: "Off" },
            { id: "missing-title", enabled: true, name: "Missing title", titleEN: "" }
        ]
    });

    const active = activeEventSettings(settings, new Date("2026-06-01T00:00:00.000Z"));
    assert.deepEqual(active.events.map((event) => event.id), ["live"]);
});

test("an explicitly saved legacy Eid campaign migrates into the generic event feed", () => {
    const settings = eventSettingsFromLegacyEid({
        eidModeEnabled: true,
        eidOfferEndsAt: "2026-09-01T00:00:00.000Z",
        updatedAt: "2026-08-01T00:00:00.000Z"
    });

    assert.equal(settings.events.length, 1);
    assert.equal(settings.events[0].id, "eid");
    assert.equal(settings.events[0].titleAR, "العيد في تالا");
    assert.equal(settings.events[0].endAt, "2026-09-01T00:00:00.000Z");
    assert.deepEqual(eventSettingsFromLegacyEid({ updatedAt: null }).events, []);
});
