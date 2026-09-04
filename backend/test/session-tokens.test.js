const test = require("node:test");
const assert = require("node:assert/strict");
const { createTokenPair, hashToken, publicTokenPair } = require("../modules/account/session-tokens");

test("session token pairs use independent high-entropy access and refresh credentials", () => {
    const pair = createTokenPair({ accessTokenHours: 1, refreshTokenDays: 30, now: () => Date.UTC(2026, 8, 4) });
    assert.match(pair.accessToken, /^[0-9a-f]{64}$/);
    assert.ok(pair.refreshToken.length >= 64);
    assert.notEqual(pair.accessToken, pair.refreshToken);
    assert.equal(pair.accessTokenHash, hashToken(pair.accessToken));
    assert.equal(pair.refreshTokenHash, hashToken(pair.refreshToken));
    assert.equal(pair.expiresAt, "2026-09-04T01:00:00.000Z");
    assert.equal(pair.refreshExpiresAt, "2026-10-04T00:00:00.000Z");
});

test("public token pairs never expose stored token hashes", () => {
    const value = publicTokenPair(createTokenPair());
    assert.deepEqual(Object.keys(value).sort(), ["accessToken", "expiresAt", "refreshExpiresAt", "refreshToken"]);
    assert.doesNotMatch(JSON.stringify(value), /Hash/);
});
