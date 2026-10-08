// Operational promises are published only after the merchant verifies them.
const countries = ["BH", "SA", "KW", "AE", "QA", "OM"];
function normalizeGulfMarkets(value = {}) {
    return Object.fromEntries(countries.map(country => {
        const source = value?.[country] || {};
        const text = key => String(source[key] || "").trim().slice(0, 240);
        const requestedVerification = source.verified === true;
        const deliveryEN = text("deliveryEN");
        const deliveryAR = text("deliveryAR");
        const verified = requestedVerification && deliveryEN.length > 0 && deliveryAR.length > 0;
        const requestedHeatSafePackaging = verified && source.heatSafePackaging === true;
        const packagingEN = text("packagingEN");
        const packagingAR = text("packagingAR");
        const heatSafePackaging = requestedHeatSafePackaging && packagingEN.length > 0 && packagingAR.length > 0;
        return [country, {
            verified,
            deliveryEN: verified ? deliveryEN : "",
            deliveryAR: verified ? deliveryAR : "",
            heatSafePackaging,
            packagingEN: heatSafePackaging ? packagingEN : "",
            packagingAR: heatSafePackaging ? packagingAR : ""
        }];
    }));
}
module.exports = { normalizeGulfMarkets };
