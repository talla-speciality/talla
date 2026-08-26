const test = require("node:test");
const assert = require("node:assert/strict");

const { normalizeAppSettings } = require("../server");

test("production app controls preserve safe defaults and validate operational values", () => {
    const settings = normalizeAppSettings({
        payments: { benefitPayEnabled: false, cardEnabled: false },
        fulfillment: {
            deliveryEnabled: true,
            pickupEnabled: false,
            bahrainRate: 2.75,
            maximumKhaleejiWeightGrams: 4500,
            khaleejiTiers: [
                { maximumWeightGrams: 1000, rate: 6.5 },
                { maximumWeightGrams: 500, rate: 5.5 }
            ]
        },
        release: { maintenanceEnabled: true, minimumSupportedVersion: "2.4.0" },
        loyalty: {
            pointsPerBHD: 8,
            silverThreshold: 200,
            goldThreshold: 400,
            rewardStep: 75,
            rewards: [{ id: "drink", enabled: true, titleEN: "Drink", points: 75, reward: "Free Drink" }]
        }
    });

    assert.equal(settings.payments.applePayEnabled, true);
    assert.equal(settings.payments.benefitPayEnabled, false);
    assert.equal(settings.fulfillment.bahrainRate, 2.75);
    assert.deepEqual(settings.fulfillment.khaleejiTiers.map((tier) => tier.maximumWeightGrams), [500, 1000]);
    assert.equal(settings.release.maintenanceEnabled, true);
    assert.equal(settings.release.minimumSupportedVersion, "2.4.0");
    assert.equal(settings.loyalty.pointsPerBHD, 8);
    assert.equal(settings.loyalty.rewards[0].points, 75);
});

test("unsafe links, invalid rates, and malformed rewards cannot reach the public settings", () => {
    const settings = normalizeAppSettings({
        fulfillment: {
            pickupMapsURL: "javascript:alert(1)",
            bahrainRate: -20,
            khaleejiTiers: [{ maximumWeightGrams: -1, rate: -9 }]
        },
        release: { appStoreURL: "file:///tmp/app" },
        loyalty: { rewards: [{ id: "bad", titleEN: "", points: -1, reward: "" }] }
    });

    assert.equal(settings.fulfillment.pickupMapsURL, "");
    assert.equal(settings.fulfillment.bahrainRate, 0);
    assert.equal(settings.fulfillment.khaleejiTiers.length, 8);
    assert.equal(settings.release.appStoreURL, "");
    assert.equal(settings.loyalty.rewards.length, 7);
});
