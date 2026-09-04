const crypto = require("crypto");
const fs = require("fs");
const { verifyAttestation, verifyAssertion } = require("appattest-checker-node");
const config = require("../../config");
const database = require("../../database");
const googleMobileServices = require("./google-mobile-services");

const challengeLifetimeMs = 5 * 60 * 1000;
const challenges = new Map();

const protectedPaths = new Set([
    "/orders/checkout-started",
    "/api/payments/apple-pay/session",
    "/api/payments/apple-pay/authorize",
    "/api/payments/card/session",
    "/api/payments/card/authentication/initiate",
    "/api/payments/card/authentication/complete",
    "/api/payments/card/complete",
    "/api/payments/click-to-pay/create",
    "/api/payments/benefitpay/session",
    "/api/payments/benefitpay/confirm",
    "/api/payments/benefit/create",
    "/api/payments/benefit/status",
    "/api/payments/eazy/shopify/session",
    "/addresses/save",
    "/addresses/preferred",
    "/addresses/delete",
    "/loyalty/transactions/redeem",
    "/loyalty/transactions/earn",
    "/vouchers/consume",
    "/notifications/push/register",
    "/notifications/push/unregister",
    "/accounts/profile/update",
    "/accounts/password/change",
    "/customer-library"
]);

function cleanExpiredChallenges() {
    const now = Date.now();
    for (const [token, record] of challenges) {
        if (record.expiresAt <= now) challenges.delete(token);
    }
}

function issueChallenge({ purpose, method = "POST", path = "" }) {
    cleanExpiredChallenges();
    if (!["attestation", "assertion"].includes(purpose)) {
        throw new Error("INVALID_CHALLENGE_PURPOSE");
    }
    if (purpose === "assertion" && !protectedPaths.has(path)) {
        throw new Error("UNPROTECTED_ASSERTION_PATH");
    }
    const bytes = crypto.randomBytes(32);
    const challenge = bytes.toString("base64");
    challenges.set(challenge, {
        purpose,
        method: String(method).toUpperCase(),
        path,
        expiresAt: Date.now() + challengeLifetimeMs
    });
    return challenge;
}

function consumeChallenge(challenge, expected) {
    cleanExpiredChallenges();
    const record = challenges.get(challenge);
    challenges.delete(challenge);
    if (!record || record.purpose !== expected.purpose
        || (expected.method && record.method !== expected.method)
        || (expected.path && record.path !== expected.path)) {
        throw new Error("INVALID_OR_EXPIRED_CHALLENGE");
    }
    const bytes = Buffer.from(challenge, "base64");
    if (bytes.length !== 32) throw new Error("INVALID_CHALLENGE");
    return bytes;
}

function readJSONStore() {
    if (!fs.existsSync(config.stores.appAttest)) return { keys: {} };
    return JSON.parse(fs.readFileSync(config.stores.appAttest, "utf8"));
}

function writeJSONStore(store) {
    fs.writeFileSync(config.stores.appAttest, JSON.stringify(store, null, 2));
}

async function saveKey(keyId, record) {
    if (database.isEnabled()) {
        await database.query(
            `INSERT INTO app_attest_keys
                (key_id, public_key_pem, receipt_base64, sign_count, environment)
             VALUES ($1, $2, $3, 0, $4)
             ON CONFLICT (key_id) DO UPDATE SET
                public_key_pem = EXCLUDED.public_key_pem,
                receipt_base64 = EXCLUDED.receipt_base64,
                sign_count = 0,
                environment = EXCLUDED.environment,
                last_seen_at = NOW()`,
            [keyId, record.publicKeyPem, record.receiptBase64, record.environment]
        );
        return;
    }
    const store = readJSONStore();
    store.keys[keyId] = { ...record, signCount: 0, createdAt: new Date().toISOString() };
    writeJSONStore(store);
}

async function loadKey(keyId) {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT public_key_pem, sign_count FROM app_attest_keys WHERE key_id = $1`,
            [keyId]
        );
        if (!result.rowCount) return null;
        return { publicKeyPem: result.rows[0].public_key_pem, signCount: Number(result.rows[0].sign_count) };
    }
    return readJSONStore().keys[keyId] || null;
}

async function updateCounter(keyId, previousCount, nextCount) {
    if (database.isEnabled()) {
        const result = await database.query(
            `UPDATE app_attest_keys SET sign_count = $1, last_seen_at = NOW()
             WHERE key_id = $2 AND sign_count = $3`,
            [nextCount, keyId, previousCount]
        );
        return result.rowCount === 1;
    }
    const store = readJSONStore();
    const record = store.keys[keyId];
    if (!record || Number(record.signCount) !== previousCount) return false;
    record.signCount = nextCount;
    record.lastSeenAt = new Date().toISOString();
    writeJSONStore(store);
    return true;
}

async function register({ keyId, challenge, attestationObject }) {
    const challengeBytes = consumeChallenge(challenge, { purpose: "attestation" });
    const environments = config.appAttestAllowDevelopment ? [false, true] : [false];
    let verified = null;
    let environment = "production";
    for (const developmentEnv of environments) {
        const result = await verifyAttestation(
            { appId: config.appAttestAppID, developmentEnv },
            keyId,
            challengeBytes,
            Buffer.from(attestationObject, "base64")
        );
        if (result && result.publicKeyPem) {
            verified = result;
            environment = developmentEnv ? "development" : "production";
            break;
        }
    }
    if (!verified) throw new Error("ATTESTATION_FAILED");
    await saveKey(keyId, {
        publicKeyPem: verified.publicKeyPem,
        receiptBase64: verified.receipt ? Buffer.from(verified.receipt).toString("base64") : null,
        environment
    });
}

function header(request, name) {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
}

async function verifyRequest(request, path, rawBody = "") {
    if (!protectedPaths.has(path)) return { allowed: true };
    const playIntegrityToken = header(request, "x-talla-play-integrity-token");
    if (playIntegrityToken) {
        return googleMobileServices.verifyPlayIntegrity({
            token: playIntegrityToken,
            method: request.method,
            path,
            rawBody
        });
    }
    const keyId = header(request, "x-talla-app-attest-key-id");
    const challenge = header(request, "x-talla-app-attest-challenge");
    const assertion = header(request, "x-talla-app-attest-assertion");
    if (!keyId || !challenge || !assertion) {
        return config.appAttestEnforce
            ? { allowed: false, error: "APP_ATTEST_REQUIRED" }
            : { allowed: true, rolloutBypass: true };
    }
    try {
        const challengeBytes = consumeChallenge(challenge, {
            purpose: "assertion",
            method: String(request.method || "GET").toUpperCase(),
            path
        });
        const key = await loadKey(keyId);
        if (!key) throw new Error("UNKNOWN_APP_ATTEST_KEY");
        const clientDataHash = crypto.createHash("sha256").update(challengeBytes).digest();
        const result = await verifyAssertion(
            clientDataHash,
            key.publicKeyPem,
            config.appAttestAppID,
            Buffer.from(assertion, "base64")
        );
        if (!result || !Number.isInteger(result.signCount) || result.signCount <= key.signCount) {
            throw new Error("INVALID_ASSERTION_COUNTER");
        }
        if (!await updateCounter(keyId, key.signCount, result.signCount)) {
            throw new Error("ASSERTION_REPLAYED");
        }
        return { allowed: true };
    } catch (error) {
        return { allowed: false, error: error.message || "APP_ATTEST_FAILED" };
    }
}

module.exports = { issueChallenge, protectedPaths, register, verifyRequest };
