const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

process.env.DATA_DIRECTORY = fs.mkdtempSync(path.join(os.tmpdir(), "talla-loyalty-ranks-test-"));
delete process.env.DATABASE_URL;

const { loyaltyPerksFor, tierFor } = require("../server");

test("loyalty ranks use aligned Bronze, Silver, and Gold thresholds", () => {
    assert.equal(tierFor(0), "Bronze");
    assert.equal(tierFor(149), "Bronze");
    assert.equal(tierFor(150), "Silver");
    assert.equal(tierFor(299), "Silver");
    assert.equal(tierFor(300), "Gold");

    assert.match(loyaltyPerksFor(150).join(" "), /Silver status/);
    assert.match(loyaltyPerksFor(300).join(" "), /Gold-only/);
});
