const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");
const sharp = require("sharp");

const {
    renderWalletStampStrip,
    walletStampState
} = require("../wallet-pass-artwork");

const artworkDirectory = path.join(__dirname, "..", "assets", "wallet");
const emptyBottlePath = path.join(artworkDirectory, "al-jahra-empty.png");
const fullBottlePath = path.join(artworkDirectory, "al-jahra-full.png");

test("wallet stamp state fills one bottle per ten Beans", () => {
    assert.deepEqual(walletStampState(0), {
        filledCount: 0,
        stampsLeft: 5,
        rewardReady: false
    });
    assert.equal(walletStampState(29).filledCount, 2);
    assert.deepEqual(walletStampState(50), {
        filledCount: 5,
        stampsLeft: 0,
        rewardReady: true
    });
    assert.equal(walletStampState(51).filledCount, 0);
});

test("wallet strip renders correct Retina dimensions and changes with progress", async () => {
    const directory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-wallet-artwork-"));
    const emptyOutput = path.join(directory, "empty.png");
    const fullOutput = path.join(directory, "full.png");

    try {
        await renderWalletStampStrip({
            emptyBottlePath,
            fullBottlePath,
            filledCount: 0,
            outputPath: emptyOutput,
            scale: 2
        });
        await renderWalletStampStrip({
            emptyBottlePath,
            fullBottlePath,
            filledCount: 5,
            outputPath: fullOutput,
            scale: 2
        });

        const metadata = await sharp(emptyOutput).metadata();
        assert.equal(metadata.width, 750);
        assert.equal(metadata.height, 288);
        assert.notEqual(
            crypto.createHash("sha256").update(fs.readFileSync(emptyOutput)).digest("hex"),
            crypto.createHash("sha256").update(fs.readFileSync(fullOutput)).digest("hex")
        );
    } finally {
        fs.rmSync(directory, { recursive: true, force: true });
    }
});
