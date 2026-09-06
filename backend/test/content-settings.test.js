const test = require("node:test");
const assert = require("node:assert/strict");
const {
    defaultCampaignSettings,
    normalizeCampaignSettings,
    normalizeEventSettings,
    activeEventSettings,
    normalizeHomeSettings,
} = require("../modules/application/content-settings");

test("content settings normalize safely outside the HTTP entry point", () => {
    assert.deepEqual(defaultCampaignSettings(), { eidModeEnabled: true, eidOfferEndsAt: null, updatedAt: null });
    assert.equal(normalizeCampaignSettings({ eidOfferEndsAt: "not-a-date" }).eidOfferEndsAt, null);

    const settings = normalizeEventSettings({ events: [
        { id: "Launch Event", enabled: true, titleEN: "Launch", priority: 4, startAt: "2020-01-01" },
        { id: "future", enabled: true, titleEN: "Future", startAt: "2999-01-01" },
    ] });
    assert.equal(settings.events[0].id, "launch-event");
    assert.equal(activeEventSettings(settings, new Date("2025-01-01")).events.length, 1);

    const home = normalizeHomeSettings({ signatureRoastProductIDs: ["a", "a", "b"] });
    assert.deepEqual(home.signatureRoastProductIDs, ["a", "b"]);
});
