const test = require("node:test");
const assert = require("node:assert/strict");

const { normalizeCountryCode } = require("../server");

test("address country codes accept normalized GCC and international ISO-style codes", () => {
    assert.equal(normalizeCountryCode(" sa "), "SA");
    assert.equal(normalizeCountryCode("us"), "US");
    assert.equal(normalizeCountryCode("United States"), "");
    assert.equal(normalizeCountryCode("", "BH"), "BH");
});
