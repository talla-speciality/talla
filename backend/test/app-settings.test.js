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
    assert.equal(settings.loyalty.rewards.length, 1);
});


test("only free drinks remain redeemable from a previously saved mixed catalog", () => {
    const settings = normalizeAppSettings({ loyalty: { rewards: [
        { id: "espresso-pour", enabled: true, titleEN: "Drink of Your Choice", points: 50, reward: "Free Drink" },
        { id: "pastry-pairing", enabled: true, titleEN: "Pastry Pairing", points: 75, reward: "Pastry pairing" },
        { id: "signature-sip", enabled: true, titleEN: "Signature Sip", points: 100, reward: "Signature sip" },
        { id: "coffee-bag-credit", enabled: true, titleEN: "Coffee Bag Credit", points: 150, reward: "Coffee bag credit" }
    ] } });
    assert.deepEqual(settings.loyalty.rewards.map(({ reward, points }) => ({ reward, points })), [
        { reward: "Free Drink", points: 50 }
    ]);
    assert.equal(settings.loyalty.rewardStep, 50);
    assert.equal(settings.loyalty.pointsPerBHD, 5);
});

test("a catalog containing only retired rewards falls back to the free drink", () => {
    const settings = normalizeAppSettings({ loyalty: { rewards: [
        { id: "gift", enabled: true, titleEN: "Gift", points: 250, reward: "Gold club gift" }
    ] } });
    assert.equal(settings.loyalty.rewards.length, 1);
    assert.equal(settings.loyalty.rewards[0].reward, "Free Drink");
    assert.equal(settings.loyalty.rewards[0].points, 50);
});
