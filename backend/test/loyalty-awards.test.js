const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const dataDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-loyalty-awards-"));
process.env.DATA_DIRECTORY = dataDirectory;
delete process.env.DATABASE_URL;
const { awardBrewJournalRewards, awardMonthlyMissionIfComplete } = require("../server");

const email = "award@example.com";
const loyaltyPath = path.join(dataDirectory, "loyalty.json");
function seed(transactions = [], balance = 0) {
    fs.writeFileSync(loyaltyPath, JSON.stringify({ accounts: { [email]: {
        memberID: "TALLA-AWARD", pointsBalance: balance, tier: "Bronze", nextReward: "", perks: [], transactions
    } } }));
}
function account() { return JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[email]; }

test("a later fourth brewing method awards achievement even when the monthly mission was already earned", async () => {
    const year = new Date().getUTCFullYear();
    const month = String(new Date().getUTCMonth() + 1).padStart(2, "0");
    seed([{ id: `phase6:mission:${year}-${month}`, type: "earn", points: 40, note: "Monthly brewing mission", createdAt: new Date().toISOString() }], 40);
    const journal = ["V60", "French press", "Espresso", "Chemex"].map((method, index) => ({
        id: `method-${index}`, method, createdAt: new Date().toISOString()
    }));
    await awardMonthlyMissionIfComplete(email, journal);
    await awardMonthlyMissionIfComplete(email, journal);
    assert.equal(account().pointsBalance, 70);
    assert.equal(account().transactions.filter((entry) => entry.id === "phase6:achievement").length, 1);
});

test("duplicate journal entries produce one brew award", async () => {
    seed();
    const entry = { id: "same-brew", method: "V60", createdAt: new Date().toISOString(), rating: 0, notes: "" };
    await awardBrewJournalRewards(email, [entry, entry]);
    await awardBrewJournalRewards(email, [entry, entry]);
    const awards = account().transactions.filter((transaction) => transaction.id === "brew:same-brew");
    assert.equal(awards.length, 1);
    assert.equal(account().pointsBalance, awards[0].points);
});
