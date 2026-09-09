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


test("Arabic hero fields survive normalization independently of English", () => {
    const input = { heroTitle: "English title", heroTitleAR: "  قهوة مختصة  ",
        heroSubtitleAR: "وصف القهوة", heroEyebrowAR: "المحمصة", heroBadgeAR: "تحميص طازج",
        primaryButtonTitleAR: "تسوق القهوة", secondaryButtonTitleAR: "دليل التحضير" };
    const settings = normalizeHomeSettings(input);
    assert.equal(settings.heroTitle, "English title");
    for (const key of Object.keys(input)) assert.equal(settings[key], input[key].trim());
    assert.deepEqual(normalizeHomeSettings(JSON.parse(JSON.stringify(settings))), settings);
    assert.equal(normalizeHomeSettings({}).heroTitleAR, "");
    assert.equal(normalizeHomeSettings({ ...settings, heroTitleAR: " " }).heroTitleAR, "");
    for (const [key, limit] of Object.entries({ heroTitleAR: 80, heroSubtitleAR: 180,
        heroEyebrowAR: 40, heroBadgeAR: 40, primaryButtonTitleAR: 28, secondaryButtonTitleAR: 28 })) {
        assert.equal(normalizeHomeSettings({ [key]: "ق".repeat(250) })[key].length, limit);
    }
});
