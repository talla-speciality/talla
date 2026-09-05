const crypto = require("crypto");

function positiveHours(value, fallback) {
    const parsed = Number(value);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

function hashToken(token) {
    return crypto.createHash("sha256").update(String(token || "")).digest("hex");
}

function createTokenPair({ accessTokenHours = 1, refreshTokenDays = 30, now = Date.now } = {}) {
    const issuedAt = Number(now());
    const accessHours = positiveHours(accessTokenHours, 1);
    const refreshDays = positiveHours(refreshTokenDays, 30);
    const accessToken = crypto.randomBytes(32).toString("hex");
    const refreshToken = crypto.randomBytes(48).toString("base64url");

    return {
        accessToken,
        accessTokenHash: hashToken(accessToken),
        expiresAt: new Date(issuedAt + accessHours * 60 * 60 * 1000).toISOString(),
        refreshToken,
        refreshTokenHash: hashToken(refreshToken),
        refreshExpiresAt: new Date(issuedAt + refreshDays * 24 * 60 * 60 * 1000).toISOString()
    };
}

function publicTokenPair(pair) {
    return {
        accessToken: pair.accessToken,
        expiresAt: pair.expiresAt,
        refreshToken: pair.refreshToken,
        refreshExpiresAt: pair.refreshExpiresAt
    };
}

module.exports = { createTokenPair, hashToken, positiveHours, publicTokenPair };
