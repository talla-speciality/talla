const { GoogleAuth } = require("google-auth-library");
const crypto = require("crypto");
const config = require("../../config");

const firebaseMessagingScope = "https://www.googleapis.com/auth/firebase.messaging";
const playIntegrityScope = "https://www.googleapis.com/auth/playintegrity";
let authCache = null;

function serviceAccountCredentials() {
    if (!config.googleServiceAccountJSONBase64) return null;
    try {
        return JSON.parse(Buffer.from(config.googleServiceAccountJSONBase64, "base64").toString("utf8"));
    } catch {
        throw new Error("INVALID_GOOGLE_SERVICE_ACCOUNT_JSON_BASE64");
    }
}

function googleAuth() {
    if (authCache) return authCache;
    const credentials = serviceAccountCredentials();
    authCache = new GoogleAuth({
        ...(credentials ? { credentials } : {}),
        scopes: [firebaseMessagingScope, playIntegrityScope]
    });
    return authCache;
}

function fcmConfigured() {
    return Boolean(config.googleCloudProjectID && config.googleServiceAccountJSONBase64);
}

function playIntegrityConfigured() {
    return Boolean(config.googleServiceAccountJSONBase64 && config.playIntegrityPackageName);
}

function requestHash(method, path, rawBody = "") {
    return crypto.createHash("sha256")
        .update(`${String(method || "GET").toUpperCase()}\n${path}\n${rawBody}`)
        .digest("base64url");
}

async function authorizedFetch(url, options) {
    const client = await googleAuth().getClient();
    const authHeaders = await client.getRequestHeaders(url);
    const headers = new Headers(options.headers || {});
    authHeaders.forEach((value, key) => headers.set(key, value));
    return fetch(url, {
        ...options,
        headers
    });
}

async function sendFCM(deviceToken, notification) {
    if (!fcmConfigured()) return { configured: false, sent: false };
    const data = {
        type: notification.type || "stock_alert",
        productID: notification.productID || "",
        url: notification.url || ""
    };
    const response = await authorizedFetch(
        `https://fcm.googleapis.com/v1/projects/${encodeURIComponent(config.googleCloudProjectID)}/messages:send`,
        {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({
                message: {
                    token: deviceToken,
                    notification: { title: notification.title, body: notification.body },
                    data,
                    android: {
                        priority: notification.type === "order_ready" ? "high" : "normal",
                        notification: { channel_id: notification.type === "order_ready" ? "orders" : "updates" }
                    }
                }
            })
        }
    );
    const payload = await response.json().catch(() => ({}));
    return {
        configured: true,
        sent: response.ok,
        shouldPrune: response.status === 404 || payload?.error?.details?.some?.((detail) => detail.errorCode === "UNREGISTERED") === true,
        error: response.ok ? null : (payload?.error?.message || `FCM_HTTP_${response.status}`)
    };
}

async function verifyPlayIntegrity({ token, method, path, rawBody }) {
    if (!playIntegrityConfigured()) {
        return config.playIntegrityEnforce
            ? { allowed: false, error: "PLAY_INTEGRITY_NOT_CONFIGURED" }
            : { allowed: true, rolloutBypass: true };
    }
    if (!token) {
        return config.playIntegrityEnforce
            ? { allowed: false, error: "PLAY_INTEGRITY_REQUIRED" }
            : { allowed: true, rolloutBypass: true };
    }
    try {
        const url = `https://playintegrity.googleapis.com/v1/${encodeURIComponent(config.playIntegrityPackageName)}:decodeIntegrityToken`;
        const response = await authorizedFetch(url, {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ integrity_token: token })
        });
        const payload = await response.json().catch(() => ({}));
        if (!response.ok) throw new Error(payload?.error?.message || `PLAY_INTEGRITY_HTTP_${response.status}`);

        const verdict = payload.tokenPayloadExternal || {};
        const details = verdict.requestDetails || {};
        const expectedHash = requestHash(method, path, rawBody);
        const ageMs = Date.now() - Number(details.timestampMillis || 0);
        const recognized = verdict.appIntegrity?.appRecognitionVerdict === "PLAY_RECOGNIZED";
        const deviceVerdicts = verdict.deviceIntegrity?.deviceRecognitionVerdict || [];
        if (details.requestPackageName !== config.playIntegrityPackageName) throw new Error("PLAY_INTEGRITY_PACKAGE_MISMATCH");
        if (details.requestHash !== expectedHash) throw new Error("PLAY_INTEGRITY_REQUEST_MISMATCH");
        if (!Number.isFinite(ageMs) || ageMs < -30_000 || ageMs > 120_000) throw new Error("PLAY_INTEGRITY_STALE");
        if (!recognized) throw new Error("PLAY_INTEGRITY_APP_UNRECOGNIZED");
        if (!deviceVerdicts.includes("MEETS_DEVICE_INTEGRITY")) throw new Error("PLAY_INTEGRITY_DEVICE_FAILED");
        return { allowed: true };
    } catch (error) {
        return { allowed: false, error: error.message || "PLAY_INTEGRITY_FAILED" };
    }
}

module.exports = {
    fcmConfigured,
    requestHash,
    sendFCM,
    verifyPlayIntegrity
};
