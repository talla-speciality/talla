const test = require("node:test");
const assert = require("node:assert/strict");

const { normalizeCountryCode, preferAddressRecords } = require("../server");

test("address country codes accept normalized GCC and international ISO-style codes", () => {
    assert.equal(normalizeCountryCode(" sa "), "SA");
    assert.equal(normalizeCountryCode("us"), "US");
    assert.equal(normalizeCountryCode("United States"), "");
    assert.equal(normalizeCountryCode("", "BH"), "BH");
});

test("customers can select exactly one preferred delivery address", () => {
    const addresses = [
        { id: "bh", countryCode: "BH", isPreferred: true },
        { id: "sa", countryCode: "SA", isPreferred: false }
    ];
    assert.deepEqual(preferAddressRecords(addresses, "sa"), [
        { id: "bh", countryCode: "BH", isPreferred: false },
        { id: "sa", countryCode: "SA", isPreferred: true }
    ]);
    assert.equal(preferAddressRecords(addresses, "missing"), null);
});
