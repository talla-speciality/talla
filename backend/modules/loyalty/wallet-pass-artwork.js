const path = require("path");
const sharp = require("sharp");

const STAMP_COUNT = 6;
const POINTS_PER_STAMP = 50;
const REWARD_THRESHOLD = STAMP_COUNT * POINTS_PER_STAMP;

function walletStampState(pointsBalance) {
    const points = Math.max(0, Math.floor(Number(pointsBalance) || 0));
    const cyclePoints = points % REWARD_THRESHOLD;
    const currentPoints = cyclePoints === 0 && points > 0 ? REWARD_THRESHOLD : cyclePoints;
    const filledCount = Math.min(Math.floor(currentPoints / POINTS_PER_STAMP), STAMP_COUNT);

    return {
        filledCount,
        stampsLeft: Math.max(STAMP_COUNT - filledCount, 0),
        rewardReady: filledCount === STAMP_COUNT
    };
}

async function resizedBottle(sourcePath, width, height) {
    return sharp(sourcePath)
        .trim()
        .resize({
            width,
            height,
            fit: "contain",
            withoutEnlargement: false,
            background: { r: 0, g: 0, b: 0, alpha: 0 }
        })
        .png()
        .toBuffer();
}

async function renderWalletStampStrip({
    emptyBottlePath,
    fullBottlePath,
    filledCount,
    outputPath,
    scale = 1
}) {
    const width = 375 * scale;
    const height = 144 * scale;
    const slotWidth = 72 * scale;
    const slotHeight = 60 * scale;
    const topY = 5 * scale;
    const bottomY = 77 * scale;
    const positions = [
        { left: 48 * scale, top: topY },
        { left: 151 * scale, top: topY },
        { left: 254 * scale, top: topY },
        { left: 48 * scale, top: bottomY },
        { left: 151 * scale, top: bottomY },
        { left: 254 * scale, top: bottomY }
    ];
    const safeFilledCount = Math.min(Math.max(Number(filledCount) || 0, 0), STAMP_COUNT);
    const [emptyBottle, fullBottle] = await Promise.all([
        resizedBottle(emptyBottlePath, slotWidth, slotHeight),
        resizedBottle(fullBottlePath, slotWidth, slotHeight)
    ]);

    await sharp({
        create: {
            width,
            height,
            channels: 4,
            background: { r: 241, g: 234, b: 223, alpha: 1 }
        }
    })
        .composite(positions.map((position, index) => ({
            input: index < safeFilledCount ? fullBottle : emptyBottle,
            ...position
        })))
        .png()
        .toFile(outputPath);
}

async function writeWalletStampStrips({ passDirectory, artworkDirectory, pointsBalance }) {
    const state = walletStampState(pointsBalance);
    const emptyBottlePath = path.join(artworkDirectory, "al-jahra-empty.png");
    const fullBottlePath = path.join(artworkDirectory, "al-jahra-full.png");

    await Promise.all([
        renderWalletStampStrip({
            emptyBottlePath,
            fullBottlePath,
            filledCount: state.filledCount,
            outputPath: path.join(passDirectory, "strip.png"),
            scale: 1
        }),
        renderWalletStampStrip({
            emptyBottlePath,
            fullBottlePath,
            filledCount: state.filledCount,
            outputPath: path.join(passDirectory, "strip@2x.png"),
            scale: 2
        }),
        renderWalletStampStrip({
            emptyBottlePath,
            fullBottlePath,
            filledCount: state.filledCount,
            outputPath: path.join(passDirectory, "strip@3x.png"),
            scale: 3
        })
    ]);

    return state;
}

module.exports = {
    renderWalletStampStrip,
    walletStampState,
    writeWalletStampStrips
};
