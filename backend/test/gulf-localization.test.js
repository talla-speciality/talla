const test = require("node:test");
const assert = require("node:assert/strict");
const { normalizeGulfMarkets } = require("../modules/commerce/gulf-localization");

test("unverified delivery and packaging claims are never published", () => {
    const result = normalizeGulfMarkets({ SA: { verified: false, deliveryEN: "Tomorrow", heatSafePackaging: true } });
    assert.equal(result.SA.deliveryEN, "");
    assert.equal(result.SA.heatSafePackaging, false);
    assert.equal(Object.keys(result).length, 6);
});
test("country policies remain independent and preserve bilingual copy", () => {
    const result = normalizeGulfMarkets({ KW: { verified: true, deliveryEN: "4–6 business days after dispatch", deliveryAR: "٤–٦ أيام عمل بعد الشحن", heatSafePackaging: true, packagingEN: "Insulated liner", packagingAR: "بطانة عازلة" } });
    assert.equal(result.KW.deliveryAR, "٤–٦ أيام عمل بعد الشحن");
    assert.equal(result.KW.heatSafePackaging, true);
    assert.equal(result.KW.packagingAR, "بطانة عازلة");
    assert.equal(result.BH.verified, false);
});

test("verification requires bilingual delivery promises and heat-safe packing instructions", () => {
    const result = normalizeGulfMarkets({
        SA: { verified: true, deliveryEN: "2–4 days", deliveryAR: "", heatSafePackaging: true, packagingEN: "Insulated liner", packagingAR: "بطانة عازلة" },
        AE: { verified: true, deliveryEN: "2–4 days", deliveryAR: "يومان إلى أربعة", heatSafePackaging: true, packagingEN: "Insulated liner", packagingAR: "" }
    });
    assert.equal(result.SA.verified, false);
    assert.equal(result.SA.deliveryEN, "");
    assert.equal(result.SA.heatSafePackaging, false);
    assert.equal(result.AE.verified, true);
    assert.equal(result.AE.heatSafePackaging, false);
    assert.equal(result.AE.packagingEN, "");
});

test("merchant settings carry the provided Bahrain and three-day GCC delivery promises", () => {
    const settings = require("../data/appSettings.json").appSettings;
    const result = normalizeGulfMarkets(settings.fulfillment.gulfMarkets);
    assert.equal(result.BH.verified, true);
    assert.match(result.BH.deliveryEN, /same-day/i);
    assert.match(result.BH.deliveryEN, /following morning/i);
    assert.equal(result.BH.heatSafePackaging, true);
    for (const country of ["SA", "KW", "AE", "QA", "OM"]) {
        assert.equal(result[country].deliveryEN, "Delivery within 3 days.");
        assert.equal(result[country].deliveryAR, "التوصيل خلال ٣ أيام.");
        assert.equal(result[country].heatSafePackaging, true);
        assert.equal(result[country].packagingEN, "Use heat-safe packing materials for every order.");
        assert.equal(result[country].packagingAR, "استخدم مواد التغليف المقاومة للحرارة مع كل طلب.");
    }
});
