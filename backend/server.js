const http = require("http");
const http2 = require("http2");
const crypto = require("crypto");
const { execFileSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { URL } = require("url");
const config = require("./config");
const database = require("./database");
const benefitGateway = require("./benefit-gateway");
const mpgsGateway = require("./mpgs-gateway");
const eazyPay = require("./eazypay");
const { writeWalletStampStrips } = require("./wallet-pass-artwork");

const host = config.host;
const port = config.port;
const dataDirectory = config.dataDirectory;
const loyaltyStorePath = config.stores.loyalty;
const accountsStorePath = config.stores.accounts;
const ordersStorePath = config.stores.orders;
const vouchersStorePath = config.stores.vouchers;
const alertsStorePath = config.stores.alerts;
const pushDevicesStorePath = config.stores.pushDevices;
const addressesStorePath = config.stores.addresses;
const alertInboxStorePath = config.stores.alertInbox;
const campaignSettingsStorePath = config.stores.campaignSettings;
const homeSettingsStorePath = config.stores.homeSettings;
const passportSettingsStorePath = config.stores.passportSettings;
const tasteMemoryStorePath = config.stores.tasteMemory;
const passwordResetTokensStorePath = config.stores.passwordResetTokens;
const benefitPaymentsStorePath = config.stores.benefitPayments;
const cardPaymentsStorePath = config.stores.cardPayments;
const shopifyEazyPaymentsStorePath = config.stores.shopifyEazyPayments;
const shopifyOrderExportsStorePath = config.stores.shopifyOrderExports;
const adminDirectory = config.adminDirectory;
const adminUsername = config.adminUsername;
const adminPassword = config.adminPassword;
const adminAppEmails = config.adminAppEmails;
const adminSessionSecret = config.adminSessionSecret;
const adminSessionHours = config.adminSessionHours;
const customerTokenSecret = config.customerTokenSecret;
const customerTokenHours = config.customerTokenHours;
const resendAPIKey = config.resendAPIKey;
const emailFromAddress = config.emailFromAddress;
const appleSignInClientID = config.appleSignInClientID;
const applePaySettlementProvider = config.applePaySettlementProvider;
const benefitTranportalID = config.benefitTranportalID;
const benefitTranportalPassword = config.benefitTranportalPassword;
const benefitResourceKey = config.benefitResourceKey;
const benefitAPIEndpoint = config.benefitAPIEndpoint;
const benefitSuccessURL = config.benefitSuccessURL;
const benefitErrorURL = config.benefitErrorURL;
const benefitNotificationURL = config.benefitNotificationURL;
const benefitPayConfiguration = {
    appID: config.benefitPayAppID,
    merchantID: config.benefitPayMerchantID,
    secretKey: config.benefitPaySecretKey,
    checkStatusURL: config.benefitPayCheckStatusURL,
    merchantName: config.benefitPayMerchantName,
    merchantCity: config.benefitPayMerchantCity,
    merchantCategoryCode: config.benefitPayMerchantCategoryCode,
    countryCode: config.benefitPayCountryCode
};
const mpgsConfiguration = {
    merchantId: config.mpgsMerchantID,
    apiPassword: config.mpgsAPIPassword,
    secondaryApiPassword: config.mpgsAPISecondaryPassword,
    apiVersion: config.mpgsAPIVersion,
    baseURL: config.mpgsBaseURL
};
const eazyConfiguration = {
    appId: config.eazyAppID,
    secretKey: config.eazySecretKey,
    apiBaseURL: config.eazyAPIBaseURL,
    paymentMethods: config.eazyPaymentMethods
};
const apnsKeyID = config.apnsKeyID;
const apnsTeamID = config.apnsTeamID;
const apnsBundleID = config.apnsBundleID;
const apnsUseSandbox = config.apnsUseSandbox;
const apnsPrivateKeyPath = config.apnsPrivateKeyPath;
const apnsPrivateKeyBase64 = config.apnsPrivateKeyBase64;
const passwordResetTokenHours = config.passwordResetTokenHours;
const rateLimitWindowMs = config.rateLimitWindowMs;
const rateLimitMaxRequests = config.rateLimitMaxRequests;
const requestLoggingEnabled = config.requestLoggingEnabled;
const opsAlertWebhookURL = config.opsAlertWebhookURL;
const opsAlertCheckIntervalMs = config.opsAlertCheckIntervalMs;
const opsAlertWindowMinutes = config.opsAlertWindowMinutes;
const opsAlert5xxThreshold = config.opsAlert5xxThreshold;
const opsAlert429Threshold = config.opsAlert429Threshold;
const opsAlertCooldownMinutes = config.opsAlertCooldownMinutes;
const shopifyAdminShopDomain = config.shopifyAdminShopDomain;
const shopifyAdminAccessToken = config.shopifyAdminAccessToken;
const shopifyAdminAPIVersion = config.shopifyAdminAPIVersion;
const shopifyAdminPublicationID = config.shopifyAdminPublicationID;
const shopifyWebhookSecret = config.shopifyWebhookSecret;
const loyaltyPointsPerBHD = 5;
const sampleOrderTotal = 8.5;
const sampleOrderItems = [
    { name: "Brazil", quantity: 1 },
    { name: "Colombia", quantity: 1 }
];
const approvedProductTypes = new Set([
    "Coffee Beans",
    "Arabic Coffee",
    "Drip Bags",
    "Cups",
    "Drinks",
    "CRMB",
    "Summer Drinks",
    "Spreads",
    "Hot Chocolate",
    "Coffee Equipment",
    "Gifts"
]);
const managedProductBadgeTags = ["NEW", "LIMITED", "STAFF PICK", "BESTSELLER"];
const walletPassTemplateDirectory = config.walletPassTemplateDirectory;
const walletPassArtworkDirectory = path.join(__dirname, "assets", "wallet");
const walletPassCertificatePath = config.walletPassCertificatePath;
const walletPassCertificateBase64 = config.walletPassCertificateBase64;
const walletPassCertificatePassword = config.walletPassCertificatePassword;
const walletPassWWDRPath = config.walletPassWWDRPath;
const walletPassWWDRBase64 = config.walletPassWWDRBase64;
const adminSessionCookieName = "talla_admin_session";
const adminSessions = new Map();
const rateLimitBuckets = new Map();
const benefitPaymentLocks = new Map();
const cardPaymentLocks = new Map();
const shopifyEazyPaymentLocks = new Map();
const shopifyOrderExportLocks = new Map();
let opsAlertTimer = null;
let appleSigningKeysCache = null;
let appleSigningKeysFetchedAt = 0;
let apnsBearerTokenCache = "";
let apnsBearerTokenExpiresAt = 0;
let apnsPrivateKeyCache = null;

ensureStoreFile(loyaltyStorePath, { accounts: {} });
ensureStoreFile(accountsStorePath, { accounts: {} });
ensureStoreFile(ordersStorePath, { orders: {} });
ensureStoreFile(vouchersStorePath, { vouchers: {} });
ensureStoreFile(alertsStorePath, { alerts: {} });
ensureStoreFile(pushDevicesStorePath, { devices: [] });
ensureStoreFile(addressesStorePath, { addresses: {} });
ensureStoreFile(alertInboxStorePath, { alerts: {} });
ensureStoreFile(campaignSettingsStorePath, { campaignSettings: defaultCampaignSettings() });
ensureStoreFile(homeSettingsStorePath, { homeSettings: defaultHomeSettings() });
ensureStoreFile(passportSettingsStorePath, { passportSettings: defaultPassportSettings() });
ensureStoreFile(tasteMemoryStorePath, { tasteMemory: {} });
ensureStoreFile(passwordResetTokensStorePath, { tokens: [] });
ensureStoreFile(benefitPaymentsStorePath, { payments: {} });
ensureStoreFile(cardPaymentsStorePath, { payments: {} });
ensureStoreFile(shopifyEazyPaymentsStorePath, { payments: {} });
ensureStoreFile(shopifyOrderExportsStorePath, { exports: {} });

function ensureStoreFile(filePath, fallback) {
    if (!fs.existsSync(dataDirectory)) {
        fs.mkdirSync(dataDirectory, { recursive: true });
    }

    if (!fs.existsSync(filePath)) {
        fs.writeFileSync(filePath, JSON.stringify(fallback, null, 2));
    }
}

function readJSON(filePath) {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

function writeJSON(filePath, payload) {
    fs.writeFileSync(filePath, JSON.stringify(payload, null, 2));
}

function defaultCampaignSettings() {
    return {
        eidModeEnabled: true,
        eidOfferEndsAt: null,
        updatedAt: null
    };
}

function normalizeCampaignSettings(value = {}) {
    const fallback = defaultCampaignSettings();
    const offerEndDate = value.eidOfferEndsAt ? new Date(value.eidOfferEndsAt) : null;
    const eidOfferEndsAt = offerEndDate && Number.isFinite(offerEndDate.getTime())
        ? offerEndDate.toISOString()
        : null;
    return {
        eidModeEnabled: value.eidModeEnabled === undefined ? fallback.eidModeEnabled : Boolean(value.eidModeEnabled),
        eidOfferEndsAt,
        updatedAt: value.updatedAt || fallback.updatedAt
    };
}

function defaultHomeSettings() {
    return {
        signatureRoastProductIDs: [],
        funPickProductID: "",
        heroEyebrow: "",
        heroTitle: "",
        heroSubtitle: "",
        heroBadge: "",
        primaryButtonTitle: "",
        secondaryButtonTitle: "",
        updatedAt: null
    };
}

function normalizeHomeSettings(value = {}) {
    const fallback = defaultHomeSettings();
    const seen = new Set();
    const signatureRoastProductIDs = Array.isArray(value.signatureRoastProductIDs)
        ? value.signatureRoastProductIDs
            .map((productID) => String(productID || "").trim())
            .filter((productID) => {
                if (!productID || seen.has(productID)) {
                    return false;
                }
                seen.add(productID);
                return true;
            })
            .slice(0, 4)
        : fallback.signatureRoastProductIDs;
    const trimText = (text, maxLength) => String(text || "").trim().slice(0, maxLength);

    return {
        signatureRoastProductIDs,
        funPickProductID: trimText(value.funPickProductID, 180),
        heroEyebrow: trimText(value.heroEyebrow, 40),
        heroTitle: trimText(value.heroTitle, 80),
        heroSubtitle: trimText(value.heroSubtitle, 180),
        heroBadge: trimText(value.heroBadge, 40),
        primaryButtonTitle: trimText(value.primaryButtonTitle, 28),
        secondaryButtonTitle: trimText(value.secondaryButtonTitle, 28),
        updatedAt: value.updatedAt || fallback.updatedAt
    };
}

function defaultPassportSettings() {
    return {
        origins: [
            { id: "ethiopia", title: "Ethiopia", emoji: "🇪🇹", keywords: ["ethiopia", "ethiopian"], rewardLabel: "" },
            { id: "yemen", title: "Yemen", emoji: "🇾🇪", keywords: ["yemen", "yemeni"], rewardLabel: "" },
            { id: "colombia", title: "Colombia", emoji: "🇨🇴", keywords: ["colombia", "colombian"], rewardLabel: "" },
            { id: "brazil", title: "Brazil", emoji: "🇧🇷", keywords: ["brazil", "brazilian"], rewardLabel: "" }
        ],
        completionRewardTitle: "Passport reward",
        completionRewardDetail: "Complete your passport to unlock a reward.",
        updatedAt: null
    };
}

function normalizePassportSettings(value = {}) {
    const fallback = defaultPassportSettings();
    const trimText = (text, maxLength) => String(text || "").trim().slice(0, maxLength);
    const fallbackByID = new Map(fallback.origins.map((origin) => [origin.id, origin]));
    const seen = new Set();
    const sourceOrigins = Array.isArray(value.origins) ? value.origins : fallback.origins;
    const origins = sourceOrigins
        .map((origin) => {
            const id = trimText(origin?.id, 40).toLowerCase().replace(/[^a-z0-9-]/g, "-");
            if (!id || seen.has(id)) {
                return null;
            }
            seen.add(id);
            const fallbackOrigin = fallbackByID.get(id) || {};
            const keywords = Array.isArray(origin?.keywords)
                ? origin.keywords
                : String(origin?.keywords || "")
                    .split(",");

            return {
                id,
                title: trimText(origin?.title || fallbackOrigin.title || id, 40),
                emoji: trimText(origin?.emoji || fallbackOrigin.emoji || "☕️", 8),
                keywords: keywords
                    .map((keyword) => trimText(keyword, 40).toLowerCase())
                    .filter(Boolean)
                    .slice(0, 8),
                rewardLabel: trimText(origin?.rewardLabel || "", 80)
            };
        })
        .filter(Boolean)
        .slice(0, 8);

    return {
        origins: origins.length ? origins : fallback.origins,
        completionRewardTitle: trimText(value.completionRewardTitle || fallback.completionRewardTitle, 80),
        completionRewardDetail: trimText(value.completionRewardDetail || fallback.completionRewardDetail, 180),
        updatedAt: value.updatedAt || fallback.updatedAt
    };
}

function sendJSON(response, statusCode, payload, extraHeaders = {}) {
    response.writeHead(statusCode, {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": config.corsAllowedOrigin,
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
        ...extraHeaders
    });
    response.end(JSON.stringify(payload));
}

function sendHTML(response, statusCode, payload, extraHeaders = {}) {
    response.writeHead(statusCode, {
        "Content-Type": "text/html; charset=utf-8",
        ...extraHeaders
    });
    response.end(payload);
}

function escapeHTML(value) {
    return String(value || "")
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
}

function passwordResetEmailConfigured() {
    return Boolean(resendAPIKey && emailFromAddress && config.appURL);
}

function buildPasswordResetLink(token) {
    const resetURL = new URL("/password-reset", config.appURL);
    resetURL.searchParams.set("token", token);
    return resetURL.toString();
}

function applePaySettlementConfigured() {
    return Boolean(applePaySettlementProvider);
}

function remotePushConfigured() {
    return Boolean(apnsKeyID && apnsTeamID && apnsBundleID && (apnsPrivateKeyPath || apnsPrivateKeyBase64));
}

function base64URLEncode(buffer) {
    return Buffer.from(buffer)
        .toString("base64")
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/g, "");
}

function readAPNSPrivateKey() {
    if (apnsPrivateKeyCache) {
        return apnsPrivateKeyCache;
    }

    if (apnsPrivateKeyPath && fs.existsSync(apnsPrivateKeyPath)) {
        apnsPrivateKeyCache = fs.readFileSync(apnsPrivateKeyPath, "utf8");
        return apnsPrivateKeyCache;
    }

    if (apnsPrivateKeyBase64) {
        apnsPrivateKeyCache = Buffer.from(apnsPrivateKeyBase64, "base64").toString("utf8");
        return apnsPrivateKeyCache;
    }

    return "";
}

function apnsBearerToken() {
    if (!remotePushConfigured()) {
        throw new Error("APNS_NOT_CONFIGURED");
    }

    if (apnsBearerTokenCache && Date.now() < apnsBearerTokenExpiresAt) {
        return apnsBearerTokenCache;
    }

    const issuedAt = Math.floor(Date.now() / 1000);
    const header = base64URLEncode(JSON.stringify({ alg: "ES256", kid: apnsKeyID }));
    const payload = base64URLEncode(JSON.stringify({ iss: apnsTeamID, iat: issuedAt }));
    const signingInput = `${header}.${payload}`;
    const privateKey = readAPNSPrivateKey();

    if (!privateKey) {
        throw new Error("APNS_PRIVATE_KEY_MISSING");
    }

    const signature = crypto.sign("sha256", Buffer.from(signingInput), {
        key: privateKey,
        dsaEncoding: "ieee-p1363"
    });

    apnsBearerTokenCache = `${signingInput}.${base64URLEncode(signature)}`;
    apnsBearerTokenExpiresAt = Date.now() + (50 * 60 * 1000);
    return apnsBearerTokenCache;
}

function renderPasswordResetPage(token) {
    const escapedToken = escapeHTML(token);
    const tokenJSON = JSON.stringify(String(token || ""));

    return `<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Reset Password | Talla Speciality</title>
    <style>
        :root {
            color-scheme: light;
            --bg: #f4ede4;
            --panel: rgba(255, 250, 244, 0.92);
            --text: #24160c;
            --muted: #735641;
            --accent: #c8965a;
            --accent-dark: #8f6030;
            --border: rgba(143, 96, 48, 0.16);
            --error: #a13f35;
            --success: #2f6f47;
        }

        * { box-sizing: border-box; }
        body {
            margin: 0;
            min-height: 100vh;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background:
                radial-gradient(circle at top left, rgba(200, 150, 90, 0.18), transparent 30%),
                linear-gradient(180deg, #f8f1e7 0%, var(--bg) 100%);
            color: var(--text);
            display: grid;
            place-items: center;
            padding: 24px;
        }
        .panel {
            width: min(100%, 420px);
            background: var(--panel);
            border: 1px solid var(--border);
            border-radius: 24px;
            padding: 28px;
            box-shadow: 0 24px 60px rgba(36, 22, 12, 0.08);
            backdrop-filter: blur(20px);
        }
        h1 {
            margin: 0 0 10px;
            font-size: 28px;
            line-height: 1.1;
        }
        p {
            margin: 0 0 18px;
            color: var(--muted);
            line-height: 1.5;
        }
        label {
            display: block;
            margin: 14px 0 8px;
            font-size: 13px;
            font-weight: 700;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            color: var(--muted);
        }
        input {
            width: 100%;
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 14px 16px;
            font-size: 16px;
            background: white;
            color: var(--text);
        }
        button {
            width: 100%;
            margin-top: 18px;
            border: 0;
            border-radius: 999px;
            padding: 14px 18px;
            font-size: 13px;
            font-weight: 800;
            letter-spacing: 0.14em;
            text-transform: uppercase;
            background: var(--accent);
            color: #0a0804;
            cursor: pointer;
        }
        button:disabled {
            opacity: 0.6;
            cursor: default;
        }
        .message {
            min-height: 20px;
            margin-top: 14px;
            font-size: 14px;
        }
        .message.error { color: var(--error); }
        .message.success { color: var(--success); }
        .status {
            margin-bottom: 16px;
            font-size: 14px;
            color: var(--muted);
        }
        .hidden { display: none; }
    </style>
</head>
<body>
    <main class="panel">
        <h1>Reset your password</h1>
        <p>Choose a new password for your Talla Speciality account. Then return to the app and sign in normally.</p>
        <div id="status" class="status">Checking your reset link…</div>
        <form id="reset-form" class="hidden">
            <input type="hidden" name="token" value="${escapedToken}">
            <label for="password">New password</label>
            <input id="password" name="password" type="password" autocomplete="new-password" required minlength="5">
            <label for="confirm-password">Confirm password</label>
            <input id="confirm-password" name="confirm-password" type="password" autocomplete="new-password" required minlength="5">
            <button id="submit-button" type="submit">Reset Password</button>
        </form>
        <div id="message" class="message"></div>
    </main>
    <script>
        const token = ${tokenJSON};
        const status = document.getElementById("status");
        const form = document.getElementById("reset-form");
        const message = document.getElementById("message");
        const submitButton = document.getElementById("submit-button");

        function setMessage(text, type) {
            message.textContent = text;
            message.className = "message" + (type ? " " + type : "");
        }

        async function validateToken() {
            if (!token) {
                status.textContent = "This reset link is missing its token.";
                setMessage("Request a new password reset link from the app.", "error");
                return;
            }

            try {
                const response = await fetch("/accounts/password/reset-token/validate?token=" + encodeURIComponent(token));
                if (!response.ok) {
                    throw new Error("invalid");
                }
                status.textContent = "Reset link confirmed.";
                form.classList.remove("hidden");
            } catch (error) {
                status.textContent = "This reset link is invalid or expired.";
                setMessage("Request a new password reset link from the app and try again.", "error");
            }
        }

        form.addEventListener("submit", async (event) => {
            event.preventDefault();
            const password = document.getElementById("password").value;
            const confirmPassword = document.getElementById("confirm-password").value;

            if (password.length < 5) {
                setMessage("Use a password with at least 5 characters.", "error");
                return;
            }

            if (password !== confirmPassword) {
                setMessage("The password confirmation does not match.", "error");
                return;
            }

            submitButton.disabled = true;
            setMessage("", "");

            try {
                const response = await fetch("/accounts/password/complete-reset", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        "Accept": "application/json"
                    },
                    body: JSON.stringify({ token, newPassword: password })
                });

                const payload = await response.json().catch(() => ({}));

                if (!response.ok) {
                    throw new Error(payload.error || "Password reset failed");
                }

                status.textContent = "Password updated.";
                form.classList.add("hidden");
                setMessage("Your password has been updated. Return to the app and sign in with the new password.", "success");
            } catch (error) {
                setMessage(error.message || "Password reset failed.", "error");
                submitButton.disabled = false;
            }
        });

        validateToken();
    </script>
</body>
</html>`;
}

function shopifyAdminConfigured() {
    return Boolean(shopifyAdminShopDomain && shopifyAdminAccessToken);
}

async function shopifyAdminGraphQLRequest(query, variables = {}) {
    if (!shopifyAdminConfigured()) {
        throw new Error("SHOPIFY_ADMIN_NOT_CONFIGURED");
    }

    const response = await fetch(`https://${shopifyAdminShopDomain}/admin/api/${shopifyAdminAPIVersion}/graphql.json`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "X-Shopify-Access-Token": shopifyAdminAccessToken
        },
        body: JSON.stringify({ query, variables }),
        signal: AbortSignal.timeout(10_000)
    });

    const payload = await response.json().catch(() => ({}));
    if (!response.ok) {
        throw new Error(payload.errors?.[0]?.message || payload.error || `Shopify request failed with ${response.status}.`);
    }

    if (Array.isArray(payload.errors) && payload.errors.length > 0) {
        throw new Error(payload.errors.map((entry) => entry.message).filter(Boolean).join(" "));
    }

    return payload.data || {};
}

function assertShopifyUserErrors(errors) {
    if (!Array.isArray(errors) || errors.length === 0) {
        return;
    }

    const message = errors
        .map((entry) => entry.message)
        .filter(Boolean)
        .join(" ");

    throw new Error(message || "Shopify product update failed.");
}

function shopifyOrderExportTag(localOrderID) {
    return `talla-app-${crypto.createHash("sha256").update(String(localOrderID || "")).digest("hex").slice(0, 20)}`;
}

function shopifyOrderExportRowToRecord(row) {
    return {
        localOrderID: row.local_order_id,
        email: normalizeEmail(row.email),
        shopifyOrderGID: row.shopify_order_gid || null,
        shopifyOrderName: row.shopify_order_name || null,
        exportTag: row.export_tag,
        status: row.status,
        failureCode: row.failure_code || null,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updatedAt: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at
    };
}

async function findShopifyOrderExport(localOrderID) {
    const normalizedID = String(localOrderID || "").trim();
    if (!normalizedID) return null;
    if (database.isEnabled()) {
        const result = await database.query(
            "SELECT * FROM shopify_order_exports WHERE local_order_id = $1 LIMIT 1",
            [normalizedID]
        );
        return result.rowCount > 0 ? shopifyOrderExportRowToRecord(result.rows[0]) : null;
    }
    return readJSON(shopifyOrderExportsStorePath).exports?.[normalizedID] || null;
}

async function persistShopifyOrderExport(record) {
    const timestamp = new Date().toISOString();
    const normalized = {
        localOrderID: String(record.localOrderID || "").trim(),
        email: normalizeEmail(record.email),
        shopifyOrderGID: record.shopifyOrderGID || null,
        shopifyOrderName: record.shopifyOrderName || null,
        exportTag: record.exportTag || shopifyOrderExportTag(record.localOrderID),
        status: record.status || "Pending",
        failureCode: record.failureCode || null,
        createdAt: record.createdAt || timestamp,
        updatedAt: timestamp
    };
    if (!normalized.localOrderID || !normalized.email) throw new Error("INVALID_SHOPIFY_ORDER_EXPORT");
    if (database.isEnabled()) {
        const result = await database.query(
            `INSERT INTO shopify_order_exports
             (local_order_id, email, shopify_order_gid, shopify_order_name, export_tag, status, failure_code, created_at, updated_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
             ON CONFLICT (local_order_id) DO UPDATE SET
                shopify_order_gid = EXCLUDED.shopify_order_gid,
                shopify_order_name = EXCLUDED.shopify_order_name,
                status = EXCLUDED.status,
                failure_code = EXCLUDED.failure_code,
                updated_at = EXCLUDED.updated_at
             RETURNING *`,
            [normalized.localOrderID, normalized.email, normalized.shopifyOrderGID, normalized.shopifyOrderName,
                normalized.exportTag, normalized.status, normalized.failureCode, normalized.createdAt, normalized.updatedAt]
        );
        return shopifyOrderExportRowToRecord(result.rows[0]);
    }
    const store = readJSON(shopifyOrderExportsStorePath);
    store.exports = store.exports || {};
    store.exports[normalized.localOrderID] = normalized;
    writeJSON(shopifyOrderExportsStorePath, store);
    return normalized;
}

async function withShopifyOrderExportLock(localOrderID, operation) {
    const key = String(localOrderID || "").trim();
    const existing = shopifyOrderExportLocks.get(key);
    if (existing) return existing;
    const pending = Promise.resolve().then(operation);
    shopifyOrderExportLocks.set(key, pending);
    try {
        return await pending;
    } finally {
        if (shopifyOrderExportLocks.get(key) === pending) shopifyOrderExportLocks.delete(key);
    }
}

function normalizeShopifyOrderPhone(value) {
    const phone = String(value || "").trim();
    if (!phone || phone.length > 32 || !/^\+?[0-9 ()-]{6,32}$/.test(phone)) return "";
    let digits = phone.replace(/\D/g, "");
    if (phone.startsWith("00")) digits = digits.slice(2);
    if (!phone.startsWith("+") && !phone.startsWith("00")) {
        if (digits.length === 8) digits = `973${digits}`;
        else if (!digits.startsWith("973")) return "";
    }
    const normalized = `+${digits}`;
    return /^\+[1-9]\d{7,14}$/.test(normalized) ? normalized : "";
}

async function customerPhoneForShopifyOrder(order) {
    const storedPhone = normalizeShopifyOrderPhone(order?.customerPhone || order?.phone);
    if (storedPhone) return storedPhone;
    const addresses = await addressesFor(order?.email);
    const preferredAddress = addresses.find((address) => address.isPreferred) || addresses[0];
    return normalizeShopifyOrderPhone(preferredAddress?.phone);
}

function shopifyOrderCreateInput(order, customerPhone = "") {
    const orderItems = Array.isArray(order.items) ? order.items : [];
    const lineItems = orderItems.map((item) => {
        const variantID = String(item.variantId || item.variantID || "").trim();
        if (!variantID.startsWith("gid://shopify/ProductVariant/")) return null;
        return {
            variantId: variantID,
            quantity: Math.max(1, Math.round(Number(item.quantity || 1)))
        };
    });
    const itemSummary = orderItems.map((item) => (
        `${String(item.name || "Item").trim() || "Item"} ×${Math.max(1, Math.round(Number(item.quantity || 1)))}`
    )).join(", ");
    const usesHistoricalFallback = lineItems.length === 0 || lineItems.some((item) => !item);
    if (usesHistoricalFallback) {
        lineItems.splice(0, lineItems.length, {
            title: (`Talla app order — ${itemSummary || "Order items"}`).slice(0, 255),
            quantity: 1,
            requiresShipping: true,
            taxable: false,
            priceSet: {
                shopMoney: {
                    amount: numericOrderTotal(order).toFixed(3),
                    currencyCode: "BHD"
                }
            }
        });
    }
    const phone = normalizeShopifyOrderPhone(customerPhone);
    return {
        email: normalizeEmail(order.email),
        ...(phone ? { phone } : {}),
        currency: "BHD",
        financialStatus: "PENDING",
        lineItems,
        processedAt: order.createdAt || new Date().toISOString(),
        sourceIdentifier: String(order.id),
        tags: ["Talla iOS", shopifyOrderExportTag(order.id)],
        note: usesHistoricalFallback
            ? `Order placed in the Talla app. Historical item details: ${itemSummary || "Unavailable"}.`
            : "Order placed in the Talla app."
    };
}

async function findShopifyOrderByExportTag(exportTag) {
    const data = await shopifyAdminGraphQLRequest(
        `query TallaExportedOrder($query: String!) {
            orders(first: 1, query: $query) { nodes { id name displayFinancialStatus } }
        }`,
        { query: `tag:${exportTag}` }
    );
    return data.orders?.nodes?.[0] || null;
}

async function createShopifyAppOrder(orderInput) {
    const mutation = `mutation CreateTallaAppOrder($order: OrderCreateOrderInput!, $options: OrderCreateOptionsInput) {
        orderCreate(order: $order, options: $options) {
            order { id name displayFinancialStatus }
            userErrors { field message }
        }
    }`;
    const variablesFor = (order) => ({
        order,
        options: { inventoryBehaviour: "BYPASS", sendReceipt: false }
    });
    let input = orderInput;
    let data = await shopifyAdminGraphQLRequest(mutation, variablesFor(input));
    const phoneRejected = input.phone && data.orderCreate?.userErrors?.some((error) => (
        /phone/i.test(String(error.field || "")) || /phone is invalid/i.test(String(error.message || ""))
    ));
    if (phoneRejected) {
        input = { ...input };
        delete input.phone;
        data = await shopifyAdminGraphQLRequest(mutation, variablesFor(input));
    }
    assertShopifyUserErrors(data.orderCreate?.userErrors);
    return data.orderCreate?.order || null;
}

async function exportCompletedOrderToShopify(localOrderID) {
    const normalizedID = String(localOrderID || "").trim();
    if (!normalizedID || normalizedID.startsWith("shopify_") || !shopifyAdminConfigured()) return null;
    return withShopifyOrderExportLock(normalizedID, async () => {
        const existing = await findShopifyOrderExport(normalizedID);
        if (existing?.status === "Synced" && existing.shopifyOrderGID) return existing;
        const order = await findOrderByID(normalizedID);
        if (!order || !completedOrderStatuses().has(order.status)) return existing;
        const exportTag = shopifyOrderExportTag(normalizedID);
        try {
            const customerPhone = await customerPhoneForShopifyOrder(order);
            let shopifyOrder = await findShopifyOrderByExportTag(exportTag);
            if (!shopifyOrder) {
                shopifyOrder = await createShopifyAppOrder(shopifyOrderCreateInput(order, customerPhone));
            }
            if (!shopifyOrder?.id) throw new Error("SHOPIFY_ORDER_CREATE_INVALID_RESPONSE");
            const synced = await persistShopifyOrderExport({
                localOrderID: normalizedID,
                email: order.email,
                shopifyOrderGID: shopifyOrder.id,
                shopifyOrderName: shopifyOrder.name,
                exportTag,
                status: "Synced"
            });
            console.info(`[SHOPIFY_APP_ORDER_SYNCED] localOrder=${normalizedID} shopifyOrder=${shopifyOrder.name || shopifyOrder.id}`);
            return synced;
        } catch (error) {
            await persistShopifyOrderExport({
                localOrderID: normalizedID,
                email: order.email,
                exportTag,
                status: "Failed",
                failureCode: String(error.message || "SHOPIFY_ORDER_EXPORT_FAILED").slice(0, 120)
            });
            console.error(`[SHOPIFY_APP_ORDER_FAILED] localOrder=${normalizedID} code=${String(error.message || "SHOPIFY_ORDER_EXPORT_FAILED").slice(0, 120)}`);
            throw error;
        }
    });
}

function queueShopifyOrderExport(localOrderID) {
    if (!shopifyAdminConfigured()) return;
    setImmediate(() => {
        void exportCompletedOrderToShopify(localOrderID).catch(() => {});
    });
}

function shopifyAdminProductPayload(node) {
    const firstVariant = node?.variants?.edges?.[0]?.node || null;
    const firstInventoryLevel = firstVariant?.inventoryItem?.inventoryLevels?.edges?.[0]?.node || null;
    const availableQuantity = Array.isArray(firstInventoryLevel?.quantities)
        ? (firstInventoryLevel.quantities.find((entry) => entry.name === "available")?.quantity ?? null)
        : null;
    const firstImage = node?.media?.nodes?.find((entry) => entry?.image?.url) || null;
    return {
        id: node.id,
        title: node.title,
        descriptionHTML: node.descriptionHtml || "",
        status: node.status,
        productType: node.productType || "",
        tags: Array.isArray(node.tags) ? node.tags : [],
        badge: productBadgeFromTags(node.tags || ""),
        onlineStoreURL: node.onlineStoreUrl || null,
        imageID: firstImage?.id || null,
        imageURL: firstImage?.image?.url || "",
        imageAlt: firstImage?.alt || "",
        defaultVariantID: firstVariant?.id || null,
        inventoryItemID: firstVariant?.inventoryItem?.id || null,
        inventoryLocationID: firstInventoryLevel?.location?.id || null,
        inventoryLocationName: firstInventoryLevel?.location?.name || "",
        availableQuantity,
        price: firstVariant?.price || "",
        availableForSale: firstVariant?.availableForSale ?? false,
        inventoryPolicy: firstVariant?.inventoryPolicy || "",
        inventoryTracked: Boolean(firstVariant?.inventoryItem?.tracked)
    };
}

function productBadgeFromTags(tags = []) {
    const uppercasedTags = new Set((Array.isArray(tags) ? tags : []).map((tag) => String(tag || "").trim().toUpperCase()));
    return managedProductBadgeTags.find((tag) => uppercasedTags.has(tag)) || "";
}

function nextProductTags(existingTags = [], badge = "") {
    const normalizedBadge = String(badge || "").trim().toUpperCase();
    if (normalizedBadge && !managedProductBadgeTags.includes(normalizedBadge)) {
        throw new Error("Choose one of the approved product badges.");
    }

    const nextTags = (Array.isArray(existingTags) ? existingTags : [])
        .map((tag) => String(tag || "").trim())
        .filter(Boolean)
        .filter((tag) => !managedProductBadgeTags.includes(tag.toUpperCase()));

    if (normalizedBadge) {
        nextTags.push(normalizedBadge);
    }

    return Array.from(new Set(nextTags));
}

async function listShopifyAdminProducts(first = 250) {
    const limit = Math.min(Math.max(Number(first) || 250, 1), 250);
    const data = await shopifyAdminGraphQLRequest(
        `query AdminProducts($first: Int!) {
            products(first: $first, sortKey: UPDATED_AT, reverse: true) {
                edges {
                    node {
                        id
                        title
                        descriptionHtml
                        status
                        productType
                        tags
                        onlineStoreUrl
                        media(first: 6) {
                            nodes {
                                ... on MediaImage {
                                    id
                                    alt
                                    image {
                                        url
                                    }
                                }
                            }
                        }
                        variants(first: 1) {
                            edges {
                                node {
                                    id
                                    price
                                    availableForSale
                                    inventoryPolicy
                                    inventoryItem {
                                        id
                                        tracked
                                        inventoryLevels(first: 1) {
                                            edges {
                                                node {
                                                    location {
                                                        id
                                                        name
                                                    }
                                                    quantities(names: ["available"]) {
                                                        name
                                                        quantity
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }`,
        { first: limit }
    );

    return (data.products?.edges || []).map(({ node }) => shopifyAdminProductPayload(node));
}

async function publishShopifyProduct(productID) {
    if (!shopifyAdminPublicationID) {
        return false;
    }

    const data = await shopifyAdminGraphQLRequest(
        `mutation PublishProduct($id: ID!, $input: [PublicationInput!]!) {
            publishablePublish(id: $id, input: $input) {
                userErrors {
                    field
                    message
                }
            }
        }`,
        {
            id: productID,
            input: [{ publicationId: shopifyAdminPublicationID }]
        }
    );

    assertShopifyUserErrors(data.publishablePublish?.userErrors);
    return true;
}

async function createShopifyAdminProduct({ title, price, productType }) {
    const data = await shopifyAdminGraphQLRequest(
        `mutation CreateProduct($product: ProductCreateInput!) {
            productCreate(product: $product) {
                product {
                    id
                    title
                    descriptionHtml
                    status
                    productType
                    onlineStoreUrl
                    media(first: 6) {
                        nodes {
                            ... on MediaImage {
                                id
                                alt
                                image {
                                    url
                                }
                            }
                        }
                    }
                    variants(first: 1) {
                        edges {
                            node {
                                id
                                price
                                availableForSale
                                inventoryPolicy
                                inventoryItem {
                                    id
                                    tracked
                                    inventoryLevels(first: 1) {
                                        edges {
                                            node {
                                                location {
                                                    id
                                                    name
                                                }
                                                quantities(names: ["available"]) {
                                                    name
                                                    quantity
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                userErrors {
                    field
                    message
                }
            }
        }`,
        {
            product: {
                title,
                productType: productType || undefined,
                status: "ACTIVE"
            }
        }
    );

    assertShopifyUserErrors(data.productCreate?.userErrors);
    const product = shopifyAdminProductPayload(data.productCreate.product);

    if (product.defaultVariantID && typeof price === "number") {
        await updateShopifyAdminProduct({
            productID: product.id,
            defaultVariantID: product.defaultVariantID,
            price
        });
    }

    const published = await publishShopifyProduct(product.id);
    const refreshedProducts = await listShopifyAdminProducts();
    const refreshed = refreshedProducts.find((entry) => entry.id === product.id) || product;
    return {
        product: refreshed,
        published
    };
}

async function updateShopifyAdminProduct({ productID, title, productType, descriptionHTML, status, tags, defaultVariantID, price }) {
    if (title || productType !== undefined || descriptionHTML !== undefined || status !== undefined || tags !== undefined) {
        const productUpdateData = await shopifyAdminGraphQLRequest(
            `mutation UpdateProduct($product: ProductUpdateInput!) {
                productUpdate(product: $product) {
                    product {
                        id
                    }
                    userErrors {
                        field
                        message
                    }
                }
            }`,
            {
                product: {
                    id: productID,
                    title: title || undefined,
                    productType,
                    descriptionHtml: descriptionHTML,
                    status,
                    tags
                }
            }
        );

        assertShopifyUserErrors(productUpdateData.productUpdate?.userErrors);
    }

    if (defaultVariantID && typeof price === "number") {
        const variantUpdateData = await shopifyAdminGraphQLRequest(
            `mutation UpdateVariantPrice($productId: ID!, $variants: [ProductVariantsBulkInput!]!) {
                productVariantsBulkUpdate(productId: $productId, variants: $variants) {
                    userErrors {
                        field
                        message
                    }
                }
            }`,
            {
                productId: productID,
                variants: [{
                    id: defaultVariantID,
                    price: price.toFixed(2)
                }]
            }
        );

        assertShopifyUserErrors(variantUpdateData.productVariantsBulkUpdate?.userErrors);
    }

    const products = await listShopifyAdminProducts();
    return products.find((entry) => entry.id === productID) || null;
}

async function addShopifyProductImage({ productID, imageURL, altText }) {
    const data = await shopifyAdminGraphQLRequest(
        `mutation AddProductImage($productId: ID!, $media: [CreateMediaInput!]!) {
            productCreateMedia(productId: $productId, media: $media) {
                mediaUserErrors {
                    field
                    message
                }
            }
        }`,
        {
            productId: productID,
            media: [{
                mediaContentType: "IMAGE",
                originalSource: imageURL,
                alt: altText || undefined
            }]
        }
    );

    assertShopifyUserErrors(data.productCreateMedia?.mediaUserErrors);
    const products = await listShopifyAdminProducts();
    return products.find((entry) => entry.id === productID) || null;
}

async function updateShopifyProductInventory({ inventoryItemID, locationID, quantity, compareQuantity }) {
    const data = await shopifyAdminGraphQLRequest(
        `mutation SetInventoryQuantity($input: InventorySetQuantitiesInput!) {
            inventorySetQuantities(input: $input) {
                userErrors {
                    field
                    message
                }
            }
        }`,
        {
            input: {
                name: "available",
                reason: "correction",
                referenceDocumentUri: `talla-admin://inventory/${inventoryItemID}`,
                quantities: [{
                    inventoryItemId: inventoryItemID,
                    locationId: locationID,
                    quantity,
                    compareQuantity
                }]
            }
        }
    );

    assertShopifyUserErrors(data.inventorySetQuantities?.userErrors);
}

async function deleteShopifyAdminProduct(productID) {
    const data = await shopifyAdminGraphQLRequest(
        `mutation DeleteProduct($input: ProductDeleteInput!, $synchronous: Boolean) {
            productDelete(input: $input, synchronous: $synchronous) {
                deletedProductId
                userErrors {
                    field
                    message
                }
            }
        }`,
        {
            input: { id: productID },
            synchronous: true
        }
    );

    assertShopifyUserErrors(data.productDelete?.userErrors);
    return data.productDelete?.deletedProductId || productID;
}

function clientIPAddress(request) {
    const forwarded = request.headers["x-forwarded-for"];
    if (typeof forwarded === "string" && forwarded.trim()) {
        return forwarded.split(",")[0].trim();
    }

    return request.socket?.remoteAddress || "unknown";
}

function pruneRateLimitBuckets(now = Date.now()) {
    for (const [key, bucket] of rateLimitBuckets.entries()) {
        if (now - bucket.windowStart >= rateLimitWindowMs) {
            rateLimitBuckets.delete(key);
        }
    }
}

function applyRateLimit(request, response) {
    if (rateLimitWindowMs <= 0 || rateLimitMaxRequests <= 0) {
        return true;
    }

    if (request.method === "OPTIONS") {
        return true;
    }

    const pathName = request.url ? new URL(request.url, `http://${host}:${port}`).pathname : "";
    if (pathName === "/health") {
        return true;
    }

    const now = Date.now();
    pruneRateLimitBuckets(now);
    const key = `${clientIPAddress(request)}:${pathName}`;
    const current = rateLimitBuckets.get(key);

    if (!current || now - current.windowStart >= rateLimitWindowMs) {
        rateLimitBuckets.set(key, { count: 1, windowStart: now });
        return true;
    }

    current.count += 1;
    if (current.count > rateLimitMaxRequests) {
        sendJSON(response, 429, {
            error: "Rate limit exceeded. Try again shortly."
        }, {
            "Retry-After": String(Math.ceil(rateLimitWindowMs / 1000))
        });
        return false;
    }

    return true;
}

async function logRequest({ request, statusCode, startedAt, accountEmail = null }) {
    if (!requestLoggingEnabled || !database.isEnabled()) {
        return;
    }

    const durationMs = Math.max(0, Date.now() - startedAt);
    const pathName = request.url ? new URL(request.url, `http://${host}:${port}`).pathname : "";
    try {
        await database.query(
            `INSERT INTO request_logs
             (id, method, path, status_code, ip_address, duration_ms, user_agent, account_email, created_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
            [
                `req_${Date.now()}_${crypto.randomBytes(3).toString("hex")}`,
                request.method || "GET",
                pathName,
                statusCode,
                clientIPAddress(request),
                durationMs,
                request.headers["user-agent"] || null,
                accountEmail,
                new Date(startedAt).toISOString()
            ]
        );
    } catch (error) {
        console.error("Failed to write request log.", error);
    }
}

function encodeBase64URL(value) {
    return Buffer.from(String(value))
        .toString("base64")
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=+$/g, "");
}

function decodeBase64URL(value) {
    const normalized = String(value)
        .replace(/-/g, "+")
        .replace(/_/g, "/");
    const padded = normalized + "=".repeat((4 - normalized.length % 4) % 4);
    return Buffer.from(padded, "base64").toString("utf8");
}

function adminCredentialsConfigured() {
    return Boolean(adminUsername && adminPassword && adminSessionSecret);
}

function customerTokensConfigured() {
    return Boolean(customerTokenSecret);
}

function signSessionValue(value) {
    return crypto
        .createHmac("sha256", adminSessionSecret)
        .update(String(value))
        .digest("hex");
}

function signCustomerTokenPayload(value) {
    return crypto
        .createHmac("sha256", customerTokenSecret)
        .update(String(value))
        .digest("hex");
}

function hashCustomerToken(token) {
    return crypto
        .createHash("sha256")
        .update(String(token))
        .digest("hex");
}

function parseCookies(headerValue) {
    if (!headerValue) {
        return {};
    }

    return headerValue.split(";").reduce((cookies, segment) => {
        const separatorIndex = segment.indexOf("=");
        if (separatorIndex < 0) {
            return cookies;
        }

        const key = segment.slice(0, separatorIndex).trim();
        const value = segment.slice(separatorIndex + 1).trim();
        cookies[key] = decodeURIComponent(value);
        return cookies;
    }, {});
}

function pruneAdminSessions() {
    const now = Date.now();
    for (const [sessionID, session] of adminSessions.entries()) {
        if (session.expiresAt <= now) {
            adminSessions.delete(sessionID);
        }
    }
}

function adminSessionCookieAttributes(expiresAt) {
    const attributes = [
        `${adminSessionCookieName}=`,
        "Path=/admin",
        "HttpOnly",
        "SameSite=Lax"
    ];

    if (config.appURL.startsWith("https://")) {
        attributes.push("Secure");
    }

    if (expiresAt) {
        attributes[0] = `${adminSessionCookieName}=`;
        attributes.push(`Expires=${new Date(expiresAt).toUTCString()}`);
    } else {
        attributes.push("Expires=Thu, 01 Jan 1970 00:00:00 GMT");
    }

    return attributes;
}

function createAdminSession(username) {
    pruneAdminSessions();
    const sessionID = crypto.randomBytes(24).toString("hex");
    const expiresAt = Date.now() + adminSessionHours * 60 * 60 * 1000;
    adminSessions.set(sessionID, { username, expiresAt });
    const signedValue = `${sessionID}.${signSessionValue(sessionID)}`;

    return {
        username,
        expiresAt,
        cookie: adminSessionCookieAttributes(expiresAt).map((part, index) => (
            index === 0 ? `${adminSessionCookieName}=${encodeURIComponent(signedValue)}` : part
        )).join("; ")
    };
}

function clearAdminSessionCookie() {
    return adminSessionCookieAttributes(null).join("; ");
}

function getAdminSession(request) {
    pruneAdminSessions();
    const cookies = parseCookies(request.headers.cookie);
    const rawValue = cookies[adminSessionCookieName];

    if (!rawValue) {
        return null;
    }

    const separatorIndex = rawValue.indexOf(".");
    if (separatorIndex < 0) {
        return null;
    }

    const sessionID = rawValue.slice(0, separatorIndex);
    const providedSignature = rawValue.slice(separatorIndex + 1);
    const expectedSignature = signSessionValue(sessionID);
    const providedBuffer = Buffer.from(providedSignature);
    const expectedBuffer = Buffer.from(expectedSignature);

    if (providedBuffer.length !== expectedBuffer.length || !crypto.timingSafeEqual(providedBuffer, expectedBuffer)) {
        return null;
    }

    const session = adminSessions.get(sessionID);
    if (!session || session.expiresAt <= Date.now()) {
        adminSessions.delete(sessionID);
        return null;
    }

    return {
        id: sessionID,
        username: session.username,
        expiresAt: session.expiresAt
    };
}

function parseAdminLogin(body) {
    const username = String(body.username || "").trim();
    const password = String(body.password || "");
    return { username, password };
}

function createCustomerAccessToken(email) {
    const rawToken = crypto.randomBytes(32).toString("hex");
    const expiresAt = new Date(Date.now() + customerTokenHours * 60 * 60 * 1000).toISOString();

    return {
        accessToken: rawToken,
        tokenHash: hashCustomerToken(rawToken),
        expiresAt
    };
}

function getBearerToken(request) {
    const authorization = request.headers.authorization;
    if (!authorization || !authorization.startsWith("Bearer ")) {
        return null;
    }

    const token = authorization.slice(7).trim();
    return token || null;
}

function authenticateCustomer(request, response, explicitEmail = null) {
    if (!customerTokensConfigured()) {
        sendJSON(response, 503, { error: "Customer tokens are not configured." });
        return false;
    }

    const token = getBearerToken(request);
    if (!token) {
        sendJSON(response, 401, { error: "Customer authorization required." });
        return false;
    }

    if (!database.isEnabled()) {
        sendJSON(response, 503, { error: "Customer sessions require database storage." });
        return false;
    }

    return {
        token,
        explicitEmail: explicitEmail ? normalizeEmail(explicitEmail) : null
    };
}

async function resolveCustomerSession(authenticatedRequest, response) {
    const result = await database.query(
        `SELECT email, expires_at, revoked_at
         FROM customer_sessions
         WHERE token_hash = $1`,
        [hashCustomerToken(authenticatedRequest.token)]
    );

    if (result.rowCount === 0) {
        sendJSON(response, 401, { error: "Invalid customer token." });
        return false;
    }

    const row = result.rows[0];
    if (row.revoked_at) {
        sendJSON(response, 401, { error: "Customer session revoked." });
        return false;
    }

    const expiresAt = row.expires_at instanceof Date ? row.expires_at.getTime() : new Date(row.expires_at).getTime();
    if (!Number.isFinite(expiresAt) || expiresAt <= Date.now()) {
        sendJSON(response, 401, { error: "Customer token expired." });
        return false;
    }

    const email = normalizeEmail(row.email);
    const account = await getAccountByEmail(email);
    if (!account) {
        sendJSON(response, 404, { error: "Account not found." });
        return false;
    }

    if (account.isActive === false) {
        await revokeCustomerSessionsForEmail(email);
        sendJSON(response, 403, { error: "Customer account is deactivated." });
        return false;
    }

    if (authenticatedRequest.explicitEmail && authenticatedRequest.explicitEmail != email) {
        sendJSON(response, 403, { error: "Token does not match this customer account." });
        return false;
    }

    if (authenticatedRequest.request) {
        authenticatedRequest.request.authenticatedCustomerEmail = email;
    }

    return {
        email,
        expiresAt: new Date(expiresAt).toISOString()
    };
}

async function createCustomerSession(email) {
    if (!database.isEnabled()) {
        throw new Error("CUSTOMER_SESSIONS_REQUIRE_DATABASE");
    }

    const session = createCustomerAccessToken(email);
    const id = `custsess_${Date.now()}_${crypto.randomBytes(3).toString("hex")}`;
    await database.query(
        `INSERT INTO customer_sessions
         (id, email, token_hash, created_at, expires_at, revoked_at)
         VALUES ($1, $2, $3, $4, $5, NULL)`,
        [id, email, session.tokenHash, new Date().toISOString(), session.expiresAt]
    );

    return {
        accessToken: session.accessToken,
        expiresAt: session.expiresAt
    };
}

async function revokeCustomerSession(token) {
    if (!database.isEnabled()) {
        return;
    }

    await database.query(
        `UPDATE customer_sessions
         SET revoked_at = NOW()
         WHERE token_hash = $1 AND revoked_at IS NULL`,
        [hashCustomerToken(token)]
    );
}

async function revokeCustomerSessionsForEmail(email) {
    if (!database.isEnabled()) {
        return;
    }

    await database.query(
        `UPDATE customer_sessions
         SET revoked_at = NOW()
         WHERE email = $1 AND revoked_at IS NULL`,
        [email]
    );
}

function parseAuthenticatedCustomer(request, response, explicitEmail = null) {
    const authenticated = authenticateCustomer(request, response, explicitEmail);
    if (!authenticated) {
        sendJSON(response, 401, { error: "Invalid customer token." });
        return false;
    }

    return {
        ...authenticated,
        request
    };
}

function ensureAdminAccess(request, response) {
    if (!adminCredentialsConfigured()) {
        sendJSON(response, 503, { error: "Admin credentials are not configured." });
        return false;
    }

    const session = getAdminSession(request);
    if (!session) {
        sendJSON(response, 401, { error: "Admin authorization required." });
        return false;
    }

    return session;
}

async function ensureMobileAdminAccess(request, response) {
    const authenticated = parseAuthenticatedCustomer(request, response);
    if (!authenticated) {
        return false;
    }

    const customer = await resolveCustomerSession(authenticated, response);
    if (!customer) {
        return false;
    }

    if (!adminAppEmails.includes(normalizeEmail(customer.email))) {
        sendJSON(response, 403, { error: "This account does not have admin access." });
        return false;
    }

    return {
        username: customer.email,
        email: customer.email
    };
}

function normalizeEmail(email) {
    return String(email || "").trim().toLowerCase();
}

function requestBodyTooLargeError() {
    const error = new Error("REQUEST_BODY_TOO_LARGE");
    error.code = "REQUEST_BODY_TOO_LARGE";
    return error;
}

function readBody(request, maxBytes = 1_048_576) {
    return new Promise((resolve, reject) => {
        let body = "";
        let bodyBytes = 0;
        let rejected = false;

        request.on("data", (chunk) => {
            bodyBytes += Buffer.byteLength(chunk);
            if (bodyBytes > maxBytes) {
                if (!rejected) {
                    rejected = true;
                    reject(requestBodyTooLargeError());
                }
                return;
            }

            body += chunk;
        });

        request.on("end", () => {
            if (rejected) {
                return;
            }

            if (!body) {
                resolve({});
                return;
            }

            try {
                resolve(JSON.parse(body));
            } catch (error) {
                reject(error);
            }
        });

        request.on("error", reject);
    });
}

function readRawBody(request, maxBytes = 1_048_576) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        let bodyBytes = 0;
        let rejected = false;

        request.on("data", (chunk) => {
            const buffer = Buffer.from(chunk);
            bodyBytes += buffer.length;
            if (bodyBytes > maxBytes) {
                if (!rejected) {
                    rejected = true;
                    reject(requestBodyTooLargeError());
                }
                return;
            }

            chunks.push(buffer);
        });

        request.on("end", () => {
            if (rejected) {
                return;
            }

            resolve(Buffer.concat(chunks));
        });

        request.on("error", reject);
    });
}

function verifyShopifyWebhook(rawBody, hmacHeader) {
    if (!shopifyWebhookSecret || !hmacHeader) {
        return false;
    }

    const expected = crypto
        .createHmac("sha256", shopifyWebhookSecret)
        .update(rawBody)
        .digest("base64");
    const expectedBuffer = Buffer.from(expected, "utf8");
    const receivedBuffer = Buffer.from(String(hmacHeader), "utf8");

    return expectedBuffer.length === receivedBuffer.length
        && crypto.timingSafeEqual(expectedBuffer, receivedBuffer);
}

function hashPassword(password) {
    return crypto.createHash("sha256").update(String(password)).digest("hex");
}

function sha256Hex(value) {
    return crypto.createHash("sha256").update(String(value)).digest("hex");
}

function createPasswordResetToken() {
    return crypto.randomBytes(32).toString("hex");
}

function base64URLDecode(input) {
    const normalized = String(input || "")
        .replace(/-/g, "+")
        .replace(/_/g, "/");
    const padding = normalized.length % 4 === 0 ? "" : "=".repeat(4 - (normalized.length % 4));
    return Buffer.from(normalized + padding, "base64");
}

async function appleSigningKeys() {
    const oneHour = 60 * 60 * 1000;
    if (appleSigningKeysCache && (Date.now() - appleSigningKeysFetchedAt) < oneHour) {
        return appleSigningKeysCache;
    }

    const response = await fetch("https://appleid.apple.com/auth/keys");
    if (!response.ok) {
        throw new Error("APPLE_KEYS_UNAVAILABLE");
    }

    const payload = await response.json();
    appleSigningKeysCache = Array.isArray(payload.keys) ? payload.keys : [];
    appleSigningKeysFetchedAt = Date.now();
    return appleSigningKeysCache;
}

async function verifyAppleIdentityToken(identityToken, nonce) {
    const parts = String(identityToken || "").split(".");
    if (parts.length !== 3) {
        throw new Error("APPLE_TOKEN_INVALID");
    }

    const [encodedHeader, encodedPayload, encodedSignature] = parts;
    const header = JSON.parse(base64URLDecode(encodedHeader).toString("utf8"));
    const payload = JSON.parse(base64URLDecode(encodedPayload).toString("utf8"));

    if (header.alg !== "RS256" || !header.kid) {
        throw new Error("APPLE_TOKEN_INVALID");
    }

    const signingKeys = await appleSigningKeys();
    const jwk = signingKeys.find((key) => key.kid === header.kid && key.kty === "RSA");
    if (!jwk) {
        throw new Error("APPLE_SIGNING_KEY_NOT_FOUND");
    }

    const verificationData = Buffer.from(`${encodedHeader}.${encodedPayload}`);
    const signature = base64URLDecode(encodedSignature);
    const publicKey = crypto.createPublicKey({ key: jwk, format: "jwk" });
    const signatureIsValid = crypto.verify("RSA-SHA256", verificationData, publicKey, signature);

    if (!signatureIsValid) {
        throw new Error("APPLE_TOKEN_SIGNATURE_INVALID");
    }

    const audience = payload.aud;
    const audienceMatches = Array.isArray(audience)
        ? audience.includes(appleSignInClientID)
        : audience === appleSignInClientID;

    if (!audienceMatches || payload.iss !== "https://appleid.apple.com") {
        throw new Error("APPLE_TOKEN_CLAIMS_INVALID");
    }

    const expiration = Number(payload.exp);
    if (!Number.isFinite(expiration) || (expiration * 1000) <= Date.now()) {
        throw new Error("APPLE_TOKEN_EXPIRED");
    }

    if (!payload.sub) {
        throw new Error("APPLE_TOKEN_SUB_MISSING");
    }

    if (nonce && payload.nonce !== sha256Hex(nonce)) {
        throw new Error("APPLE_TOKEN_NONCE_INVALID");
    }

    return payload;
}

function profilePayload(account) {
    return {
        id: account.id,
        firstName: account.firstName,
        lastName: account.lastName,
        email: account.email,
        isActive: account.isActive !== false,
        deactivatedAt: account.deactivatedAt || null
    };
}

function accountRecordFromRow(row) {
    return {
        id: row.id,
        email: row.email,
        firstName: row.first_name,
        lastName: row.last_name,
        passwordHash: row.password_hash,
        appleUserID: row.apple_user_id || null,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        isActive: row.is_active !== false,
        deactivatedAt: row.deactivated_at instanceof Date ? row.deactivated_at.toISOString() : (row.deactivated_at || null)
    };
}

function loyaltyPayload(account) {
    return {
        memberID: account.memberID,
        pointsBalance: account.pointsBalance,
        tier: account.tier,
        nextReward: account.nextReward,
        perks: loyaltyPerksFor(account.pointsBalance),
        transactions: account.transactions || []
    };
}

function adminAuditRowToRecord(row) {
    return {
        id: row.id,
        adminUsername: row.admin_username,
        action: row.action,
        targetEmail: row.target_email,
        detail: row.detail,
        metadata: row.metadata && typeof row.metadata === "object" ? row.metadata : {},
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at
    };
}

function defaultLoyaltyPerks() {
    return [
        "Collect Beans across coffees, beans, and accessories",
        "Unlock seasonal offers and member-only extras"
    ];
}

function loyaltyPerksFor(pointsBalance) {
    if (pointsBalance >= 500) {
        return [
            "Everything in Silver",
            "Priority access to limited roast drops",
            "Exclusive Gold-only reward unlocks and concierge WhatsApp support"
        ];
    }

    if (pointsBalance >= 250) {
        return [
            "Collect Beans across coffees, beans, and accessories",
            "Early access to seasonal offers and member-only extras",
            "Silver status recognition across future loyalty promos"
        ];
    }

    return defaultLoyaltyPerks();
}

async function getAccountByEmail(email) {
    if (!database.isEnabled()) {
        const store = readJSON(accountsStorePath);
        return store.accounts[email] || null;
    }

    const result = await database.query(
        `SELECT id, email, first_name, last_name, password_hash, apple_user_id, created_at, is_active, deactivated_at
         FROM accounts
         WHERE email = $1`,
        [email]
    );

    if (result.rowCount === 0) {
        return null;
    }

    return accountRecordFromRow(result.rows[0]);
}

async function getAccountByAppleUserID(appleUserID) {
    if (!appleUserID) {
        return null;
    }

    if (!database.isEnabled()) {
        const store = readJSON(accountsStorePath);
        return Object.values(store.accounts || {}).find((account) => account.appleUserID === appleUserID) || null;
    }

    const result = await database.query(
        `SELECT id, email, first_name, last_name, password_hash, apple_user_id, created_at, is_active, deactivated_at
         FROM accounts
         WHERE apple_user_id = $1`,
        [appleUserID]
    );

    if (result.rowCount === 0) {
        return null;
    }

    return accountRecordFromRow(result.rows[0]);
}

async function allAccounts() {
    if (!database.isEnabled()) {
        const store = readJSON(accountsStorePath);
        return Object.values(store.accounts || {})
            .map((account) => ({
                id: account.id,
                email: account.email,
                firstName: account.firstName,
                lastName: account.lastName,
                passwordHash: account.passwordHash,
                appleUserID: account.appleUserID || null,
                createdAt: account.createdAt,
                isActive: account.isActive !== false,
                deactivatedAt: account.deactivatedAt || null
            }))
            .sort((lhs, rhs) => new Date(rhs.createdAt).getTime() - new Date(lhs.createdAt).getTime());
    }

    const result = await database.query(
        `SELECT id, email, first_name, last_name, password_hash, apple_user_id, created_at, is_active, deactivated_at
         FROM accounts
         ORDER BY created_at DESC
         LIMIT 500`
    );

    return result.rows.map(accountRecordFromRow);
}

async function createAccountRecord({ id, email, firstName, lastName, passwordHash, appleUserID = null, createdAt, isActive = true, deactivatedAt = null }) {
    const account = { id, email, firstName, lastName, passwordHash, appleUserID, createdAt, isActive, deactivatedAt };

    if (!database.isEnabled()) {
        const store = readJSON(accountsStorePath);
        store.accounts[email] = account;
        writeJSON(accountsStorePath, store);
        return account;
    }

    await database.query(
        `INSERT INTO accounts (id, email, first_name, last_name, password_hash, apple_user_id, created_at, is_active, deactivated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [id, email, firstName, lastName, passwordHash, appleUserID, createdAt, isActive, deactivatedAt]
    );

    return account;
}

async function updateAccountProfileRecord(email, firstName, lastName) {
    if (!database.isEnabled()) {
        const store = readJSON(accountsStorePath);
        const account = store.accounts[email];
        if (!account) {
            return null;
        }

        account.firstName = firstName;
        account.lastName = lastName;
        writeJSON(accountsStorePath, store);
        return account;
    }

    const result = await database.query(
        `UPDATE accounts
         SET first_name = $2, last_name = $3
         WHERE email = $1
         RETURNING id, email, first_name, last_name, password_hash, apple_user_id, created_at, is_active, deactivated_at`,
        [email, firstName, lastName]
    );

    if (result.rowCount === 0) {
        return null;
    }

    return accountRecordFromRow(result.rows[0]);
}

async function linkAppleUserIDToAccount(email, appleUserID) {
    if (!email || !appleUserID) {
        return null;
    }

    if (!database.isEnabled()) {
        const store = readJSON(accountsStorePath);
        const account = store.accounts[email];
        if (!account) {
            return null;
        }

        account.appleUserID = appleUserID;
        writeJSON(accountsStorePath, store);
        return account;
    }

    const result = await database.query(
        `UPDATE accounts
         SET apple_user_id = $2
         WHERE email = $1
         RETURNING id, email, first_name, last_name, password_hash, apple_user_id, created_at, is_active, deactivated_at`,
        [email, appleUserID]
    );

    if (result.rowCount === 0) {
        return null;
    }

    return accountRecordFromRow(result.rows[0]);
}

async function updateAccountRecord(currentEmail, { nextEmail, firstName, lastName }) {
    const normalizedCurrentEmail = normalizeEmail(currentEmail);
    const normalizedNextEmail = normalizeEmail(nextEmail) || normalizedCurrentEmail;

    if (!normalizedCurrentEmail || !normalizedNextEmail || !firstName || !lastName) {
        return null;
    }

    if (!database.isEnabled()) {
        const accountsStore = readJSON(accountsStorePath);
        const account = accountsStore.accounts[normalizedCurrentEmail];
        if (!account) {
            return null;
        }

        if (normalizedCurrentEmail !== normalizedNextEmail && accountsStore.accounts[normalizedNextEmail]) {
            throw new Error("ACCOUNT_EMAIL_EXISTS");
        }

        delete accountsStore.accounts[normalizedCurrentEmail];
        account.email = normalizedNextEmail;
        account.firstName = firstName;
        account.lastName = lastName;
        accountsStore.accounts[normalizedNextEmail] = account;
        writeJSON(accountsStorePath, accountsStore);

        const loyaltyStore = readJSON(loyaltyStorePath);
        if (loyaltyStore.accounts[normalizedCurrentEmail]) {
            loyaltyStore.accounts[normalizedNextEmail] = loyaltyStore.accounts[normalizedCurrentEmail];
            delete loyaltyStore.accounts[normalizedCurrentEmail];
            writeJSON(loyaltyStorePath, loyaltyStore);
        }

        const ordersStore = readJSON(ordersStorePath);
        if (ordersStore.orders[normalizedCurrentEmail]) {
            ordersStore.orders[normalizedNextEmail] = ordersStore.orders[normalizedCurrentEmail];
            delete ordersStore.orders[normalizedCurrentEmail];
            writeJSON(ordersStorePath, ordersStore);
        }

        const addressesStore = readJSON(addressesStorePath);
        if (addressesStore.addresses[normalizedCurrentEmail]) {
            addressesStore.addresses[normalizedNextEmail] = addressesStore.addresses[normalizedCurrentEmail];
            delete addressesStore.addresses[normalizedCurrentEmail];
            writeJSON(addressesStorePath, addressesStore);
        }

        const alertsStore = readJSON(alertsStorePath);
        if (alertsStore.alerts[normalizedCurrentEmail]) {
            alertsStore.alerts[normalizedNextEmail] = alertsStore.alerts[normalizedCurrentEmail];
            delete alertsStore.alerts[normalizedCurrentEmail];
            writeJSON(alertsStorePath, alertsStore);
        }

        const pushDevicesStore = readJSON(pushDevicesStorePath);
        pushDevicesStore.devices = (pushDevicesStore.devices || []).map((device) => (
            normalizeEmail(device.email) === normalizedCurrentEmail
                ? { ...device, email: normalizedNextEmail, updatedAt: new Date().toISOString() }
                : device
        ));
        writeJSON(pushDevicesStorePath, pushDevicesStore);

        const inboxStore = readJSON(alertInboxStorePath);
        if (inboxStore.alerts[normalizedCurrentEmail]) {
            inboxStore.alerts[normalizedNextEmail] = inboxStore.alerts[normalizedCurrentEmail];
            delete inboxStore.alerts[normalizedCurrentEmail];
            writeJSON(alertInboxStorePath, inboxStore);
        }

        const vouchersStore = readJSON(vouchersStorePath);
        Object.values(vouchersStore.vouchers || {}).forEach((voucher) => {
            if (voucher.email === normalizedCurrentEmail) {
                voucher.email = normalizedNextEmail;
            }
        });
        writeJSON(vouchersStorePath, vouchersStore);

        const passwordResetStore = readJSON(passwordResetTokensStorePath);
        passwordResetStore.tokens = (passwordResetStore.tokens || []).map((entry) => (
            entry.email === normalizedCurrentEmail ? { ...entry, email: normalizedNextEmail } : entry
        ));
        writeJSON(passwordResetTokensStorePath, passwordResetStore);

        return account;
    }

    try {
        await database.query("BEGIN");

        const existing = await database.query(
            `SELECT id, email, first_name, last_name, password_hash, created_at, apple_user_id, is_active, deactivated_at
             FROM accounts
             WHERE email = $1`,
            [normalizedCurrentEmail]
        );

        if (existing.rowCount === 0) {
            await database.query("ROLLBACK");
            return null;
        }

        if (normalizedCurrentEmail !== normalizedNextEmail) {
            const conflict = await database.query(
                `SELECT 1
                 FROM accounts
                 WHERE email = $1`,
                [normalizedNextEmail]
            );
            if (conflict.rowCount > 0) {
                await database.query("ROLLBACK");
                throw new Error("ACCOUNT_EMAIL_EXISTS");
            }
        }

        const result = await database.query(
            `UPDATE accounts
             SET email = $2, first_name = $3, last_name = $4
             WHERE email = $1
             RETURNING id, email, first_name, last_name, password_hash, created_at, apple_user_id, is_active, deactivated_at`,
            [normalizedCurrentEmail, normalizedNextEmail, firstName, lastName]
        );

        await database.query(
            `UPDATE request_logs
             SET account_email = $2
             WHERE account_email = $1`,
            [normalizedCurrentEmail, normalizedNextEmail]
        );

        await database.query("COMMIT");

        return accountRecordFromRow(result.rows[0]);
    } catch (error) {
        await database.query("ROLLBACK");
        throw error;
    }
}

async function updateAccountPasswordRecord(email, passwordHash) {
    if (!database.isEnabled()) {
        const store = readJSON(accountsStorePath);
        const account = store.accounts[email];
        if (!account) {
            return null;
        }

        account.passwordHash = passwordHash;
        writeJSON(accountsStorePath, store);
        return account;
    }

    const result = await database.query(
        `UPDATE accounts
         SET password_hash = $2
         WHERE email = $1
         RETURNING id`,
        [email, passwordHash]
    );

    return result.rowCount === 0 ? null : { id: result.rows[0].id };
}

async function setAccountActiveState(email, isActive) {
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) {
        return null;
    }

    if (!database.isEnabled()) {
        const store = readJSON(accountsStorePath);
        const account = store.accounts[normalizedEmail];
        if (!account) {
            return null;
        }

        account.isActive = Boolean(isActive);
        account.deactivatedAt = isActive ? null : new Date().toISOString();
        writeJSON(accountsStorePath, store);
        return account;
    }

    const result = await database.query(
        `UPDATE accounts
         SET is_active = $2,
             deactivated_at = CASE WHEN $2 THEN NULL ELSE NOW() END
         WHERE email = $1
         RETURNING id, email, first_name, last_name, password_hash, apple_user_id, created_at, is_active, deactivated_at`,
        [normalizedEmail, Boolean(isActive)]
    );

    return result.rowCount === 0 ? null : accountRecordFromRow(result.rows[0]);
}

async function deleteAccountRecord(email) {
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) {
        return false;
    }

    if (!database.isEnabled()) {
        const accountsStore = readJSON(accountsStorePath);
        if (!accountsStore.accounts[normalizedEmail]) {
            return false;
        }

        delete accountsStore.accounts[normalizedEmail];
        writeJSON(accountsStorePath, accountsStore);

        const loyaltyStore = readJSON(loyaltyStorePath);
        delete loyaltyStore.accounts[normalizedEmail];
        writeJSON(loyaltyStorePath, loyaltyStore);

        const ordersStore = readJSON(ordersStorePath);
        delete ordersStore.orders[normalizedEmail];
        writeJSON(ordersStorePath, ordersStore);

        const addressesStore = readJSON(addressesStorePath);
        delete addressesStore.addresses[normalizedEmail];
        writeJSON(addressesStorePath, addressesStore);

        const alertsStore = readJSON(alertsStorePath);
        delete alertsStore.alerts[normalizedEmail];
        writeJSON(alertsStorePath, alertsStore);

        const pushDevicesStore = readJSON(pushDevicesStorePath);
        pushDevicesStore.devices = (pushDevicesStore.devices || []).filter((device) => normalizeEmail(device.email) !== normalizedEmail);
        writeJSON(pushDevicesStorePath, pushDevicesStore);

        const inboxStore = readJSON(alertInboxStorePath);
        delete inboxStore.alerts[normalizedEmail];
        writeJSON(alertInboxStorePath, inboxStore);

        const vouchersStore = readJSON(vouchersStorePath);
        Object.keys(vouchersStore.vouchers || {}).forEach((code) => {
            if (vouchersStore.vouchers[code]?.email === normalizedEmail) {
                delete vouchersStore.vouchers[code];
            }
        });
        writeJSON(vouchersStorePath, vouchersStore);

        const passwordResetStore = readJSON(passwordResetTokensStorePath);
        passwordResetStore.tokens = (passwordResetStore.tokens || []).filter((entry) => entry.email !== normalizedEmail);
        writeJSON(passwordResetTokensStorePath, passwordResetStore);

        return true;
    }

    const result = await database.query(
        `DELETE FROM accounts
         WHERE email = $1
         RETURNING id`,
        [normalizedEmail]
    );

    return result.rowCount > 0;
}

async function activeCustomerSessionsForEmail(email) {
    if (!database.isEnabled()) {
        return [];
    }

    const result = await database.query(
        `SELECT id, created_at, expires_at
         FROM customer_sessions
         WHERE email = $1 AND revoked_at IS NULL AND expires_at > NOW()
         ORDER BY created_at DESC`,
        [email]
    );

    return result.rows.map((row) => ({
        id: row.id,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        expiresAt: row.expires_at instanceof Date ? row.expires_at.toISOString() : row.expires_at
    }));
}

async function revokeCustomerSessionByID(email, sessionID) {
    if (!database.isEnabled()) {
        return null;
    }

    const result = await database.query(
        `UPDATE customer_sessions
         SET revoked_at = NOW()
         WHERE email = $1 AND id = $2 AND revoked_at IS NULL
         RETURNING id`,
        [email, sessionID]
    );

    return result.rowCount > 0 ? { id: result.rows[0].id } : null;
}

async function createPasswordResetTokenRecord({ email, tokenHash, createdAt, expiresAt }) {
    if (!database.isEnabled()) {
        const store = readJSON(passwordResetTokensStorePath);
        store.tokens = (store.tokens || []).map((record) => (
            record.email === email && !record.usedAt
                ? { ...record, usedAt: createdAt }
                : record
        ));
        store.tokens.push({
            email,
            tokenHash,
            createdAt,
            expiresAt,
            usedAt: null
        });
        writeJSON(passwordResetTokensStorePath, store);
        return;
    }

    await database.query(
        `UPDATE password_reset_tokens
         SET used_at = $2
         WHERE email = $1
           AND used_at IS NULL`,
        [email, createdAt]
    );

    await database.query(
        `INSERT INTO password_reset_tokens (token_hash, email, created_at, expires_at, used_at)
         VALUES ($1, $2, $3, $4, NULL)`,
        [tokenHash, email, createdAt, expiresAt]
    );
}

async function passwordResetTokenIsValid(tokenHash) {
    if (!database.isEnabled()) {
        const store = readJSON(passwordResetTokensStorePath);
        const now = Date.now();

        return (store.tokens || []).some((record) => (
            record.tokenHash === tokenHash
            && !record.usedAt
            && Date.parse(record.expiresAt) > now
        ));
    }

    const result = await database.query(
        `SELECT 1
         FROM password_reset_tokens
         WHERE token_hash = $1
           AND used_at IS NULL
           AND expires_at > NOW()`,
        [tokenHash]
    );

    return result.rowCount > 0;
}

async function consumePasswordResetTokenRecord(tokenHash) {
    if (!database.isEnabled()) {
        const store = readJSON(passwordResetTokensStorePath);
        const index = (store.tokens || []).findIndex((record) => (
            record.tokenHash === tokenHash
            && !record.usedAt
            && Date.parse(record.expiresAt) > Date.now()
        ));

        if (index === -1) {
            return null;
        }

        const record = store.tokens[index];
        store.tokens[index] = {
            ...record,
            usedAt: new Date().toISOString()
        };
        writeJSON(passwordResetTokensStorePath, store);
        return { email: record.email };
    }

    const client = await database.connect();
    try {
        await client.query("BEGIN");
        const result = await client.query(
            `UPDATE password_reset_tokens
             SET used_at = NOW()
             WHERE token_hash = $1
               AND used_at IS NULL
               AND expires_at > NOW()
             RETURNING email`,
            [tokenHash]
        );

        await client.query("COMMIT");
        if (result.rowCount === 0) {
            return null;
        }

        return { email: result.rows[0].email };
    } catch (error) {
        await client.query("ROLLBACK");
        throw error;
    } finally {
        client.release();
    }
}

async function sendPasswordResetEmail(email, token) {
    const resetLink = buildPasswordResetLink(token);
    const response = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
            "Authorization": `Bearer ${resendAPIKey}`,
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            from: emailFromAddress,
            to: [email],
            subject: "Reset your Talla Speciality password",
            text: `Reset your Talla Speciality password by opening this link: ${resetLink}`,
            html: `<p>Reset your Talla Speciality password by opening the link below:</p><p><a href="${escapeHTML(resetLink)}">${escapeHTML(resetLink)}</a></p><p>If you did not request this, you can ignore this email.</p>`
        })
    });

    if (!response.ok) {
        const payload = await response.text();
        throw new Error(`Password reset email failed: ${payload || response.statusText}`);
    }
}

async function getLoyaltyTransactions(email) {
    if (!database.isEnabled()) {
        const store = readJSON(loyaltyStorePath);
        return (store.accounts[email]?.transactions || []).slice();
    }

    const result = await database.query(
        `SELECT id, type, points, note, voucher_code, voucher_detail, voucher_expires_at,
                voucher_single_use, voucher_status, created_at
         FROM loyalty_transactions
         WHERE email = $1
         ORDER BY created_at DESC`,
        [email]
    );

    return result.rows.map((row) => ({
        id: row.id,
        type: row.type,
        points: row.points,
        note: row.note,
        voucherCode: row.voucher_code,
        voucherDetail: row.voucher_detail,
        voucherExpiresAt: row.voucher_expires_at instanceof Date ? row.voucher_expires_at.toISOString() : row.voucher_expires_at,
        voucherSingleUse: row.voucher_single_use,
        voucherStatus: row.voucher_status,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at
    }));
}

async function getLoyaltyAccount(email) {
    if (!database.isEnabled()) {
        const store = readJSON(loyaltyStorePath);
        return store.accounts[email] || null;
    }

    const result = await database.query(
        `SELECT email, member_id, points_balance, tier, next_reward, perks
         FROM loyalty_accounts
         WHERE email = $1`,
        [email]
    );

    if (result.rowCount === 0) {
        return null;
    }

    const row = result.rows[0];
    return {
        memberID: row.member_id,
        pointsBalance: row.points_balance,
        tier: row.tier,
        nextReward: row.next_reward,
        perks: loyaltyPerksFor(row.points_balance)
    };
}

async function ensureLoyaltyAccount(email) {
    if (!database.isEnabled()) {
        const store = readJSON(loyaltyStorePath);
        const existing = store.accounts[email];

        if (existing) {
            existing.tier = tierFor(existing.pointsBalance || 0);
            existing.nextReward = nextRewardText(existing.pointsBalance || 0);
            existing.perks = loyaltyPerksFor(existing.pointsBalance || 0);
            writeJSON(loyaltyStorePath, store);
            return existing;
        }

        const created = {
            memberID: memberIDFor(email),
            pointsBalance: 0,
            tier: tierFor(0),
            nextReward: nextRewardText(0),
            perks: loyaltyPerksFor(0),
            transactions: []
        };

        store.accounts[email] = created;
        writeJSON(loyaltyStorePath, store);
        return created;
    }

    const existing = await getLoyaltyAccount(email);
    if (existing) {
        return {
            ...existing,
            transactions: await getLoyaltyTransactions(email)
        };
    }

    const created = {
        memberID: memberIDFor(email),
        pointsBalance: 0,
        tier: tierFor(0),
        nextReward: nextRewardText(0),
        perks: loyaltyPerksFor(0)
    };

    await database.query(
        `INSERT INTO loyalty_accounts (email, member_id, points_balance, tier, next_reward, perks)
         VALUES ($1, $2, $3, $4, $5, $6::jsonb)`,
        [email, created.memberID, created.pointsBalance, created.tier, created.nextReward, JSON.stringify(created.perks)]
    );

    return {
        ...created,
        transactions: []
    };
}

async function updateLoyaltyAccount(email, mutate) {
    if (!database.isEnabled()) {
        const store = readJSON(loyaltyStorePath);
        const account = store.accounts[email];

        if (!account) {
            return null;
        }

        mutate(account);
        account.tier = tierFor(account.pointsBalance);
        account.nextReward = nextRewardText(account.pointsBalance);
        account.perks = loyaltyPerksFor(account.pointsBalance);
        writeJSON(loyaltyStorePath, store);
        return account;
    }

    const account = await getLoyaltyAccount(email);
    if (!account) {
        return null;
    }

    const working = {
        ...account,
        transactions: await getLoyaltyTransactions(email)
    };

    const beforeCount = working.transactions.length;
    mutate(working);
    working.tier = tierFor(working.pointsBalance);
    working.nextReward = nextRewardText(working.pointsBalance);
    working.perks = loyaltyPerksFor(working.pointsBalance);

    await database.query(
        `UPDATE loyalty_accounts
         SET points_balance = $2, tier = $3, next_reward = $4, perks = $5::jsonb
         WHERE email = $1`,
        [email, working.pointsBalance, working.tier, working.nextReward, JSON.stringify(working.perks)]
    );

    if (working.transactions.length > beforeCount) {
        const newTransactions = working.transactions.slice(0, working.transactions.length - beforeCount);
        for (const transaction of newTransactions) {
            await database.query(
                `INSERT INTO loyalty_transactions
                 (id, email, type, points, note, voucher_code, voucher_detail, voucher_expires_at, voucher_single_use, voucher_status, created_at)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
                [
                    transaction.id,
                    email,
                    transaction.type,
                    transaction.points,
                    transaction.note,
                    transaction.voucherCode || null,
                    transaction.voucherDetail || null,
                    transaction.voucherExpiresAt || null,
                    transaction.voucherSingleUse ?? null,
                    transaction.voucherStatus || null,
                    transaction.createdAt
                ]
            );
        }
    }

    return {
        ...working,
        transactions: await getLoyaltyTransactions(email)
    };
}

async function ensureWalletPassRecord(email, memberID, passTypeIdentifier) {
    if (!database.isEnabled()) {
        return `${memberID}-${Date.now()}`;
    }

    const existing = await database.query(
        `SELECT serial_number
         FROM wallet_passes
         WHERE email = $1`,
        [email]
    );

    const timestamp = new Date().toISOString();
    if (existing.rowCount > 0) {
        const serialNumber = existing.rows[0].serial_number;
        await database.query(
            `UPDATE wallet_passes
             SET pass_type_identifier = $2,
                 last_generated_at = $3,
                 updated_at = $3
             WHERE email = $1`,
            [email, passTypeIdentifier, timestamp]
        );
        return serialNumber;
    }

    const serialNumber = `${memberID}-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;
    await database.query(
        `INSERT INTO wallet_passes
         (email, serial_number, pass_type_identifier, last_generated_at, updated_at)
         VALUES ($1, $2, $3, $4, $4)`,
        [email, serialNumber, passTypeIdentifier, timestamp]
    );
    return serialNumber;
}

function orderRowToRecord(row) {
    return {
        id: row.id,
        title: row.title,
        total: row.total,
        status: row.status,
        items: Array.isArray(row.items) ? row.items : [],
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at
    };
}

function completedOrderStatuses() {
    return new Set(["Completed", "Fulfilled", "Delivered"]);
}

function allowedOrderStatuses() {
    return new Set([
        "Pending",
        "Confirmed",
        "Preparing",
        "Roasting",
        "Resting",
        "Packed",
        "On its way",
        "Ready",
        "Completed",
        "Fulfilled",
        "Delivered",
        "Cancelled"
    ]);
}

function normalizeOrderStatus(status) {
    const rawStatus = String(status || "").trim();
    if (!rawStatus) {
        return "";
    }

    const normalizedStatus = rawStatus.toLowerCase();
    return Array.from(allowedOrderStatuses()).find((entry) => entry.toLowerCase() === normalizedStatus) || "";
}

function loyaltyTransactionIDForOrder(order) {
    return `txn_${order.id}`;
}

function orderBeansFor(order) {
    if (!completedOrderStatuses().has(order.status)) {
        return 0;
    }

    return Math.max(0, Math.round(numericOrderTotal(order) * loyaltyPointsPerBHD));
}

async function orderPayloadWithRewardState(email, order) {
    const pointsAwarded = orderBeansFor(order);
    const beansAwarded = pointsAwarded > 0
        ? await hasLoyaltyTransaction(email, loyaltyTransactionIDForOrder(order))
        : false;

    return {
        ...order,
        beansAwarded,
        pointsAwarded: beansAwarded ? pointsAwarded : 0
    };
}

async function ordersWithRewardState(email, orders) {
    return Promise.all(
        (orders || []).map((order) => orderPayloadWithRewardState(email, order))
    );
}

async function ordersPayload(email) {
    let orders;
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, title, total, status, items, created_at
             FROM orders
             WHERE email = $1
             ORDER BY created_at DESC`,
            [email]
        );
        orders = result.rows.map(orderRowToRecord);
    } else {
        const store = readJSON(ordersStorePath);
        orders = store.orders[email] || [];
    }

    return ordersWithRewardState(email, orders);
}

async function allOrdersPayload() {
    let orders;
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, email, title, total, status, items, created_at
             FROM orders
             ORDER BY created_at DESC`
        );
        orders = result.rows.map((row) => ({
            ...orderRowToRecord(row),
            email: normalizeEmail(row.email)
        }));
    } else {
        const store = readJSON(ordersStorePath);
        orders = Object.entries(store.orders || {})
            .flatMap(([email, customerOrders]) => (
                (Array.isArray(customerOrders) ? customerOrders : []).map((order) => ({
                    ...order,
                    email: normalizeEmail(email)
                }))
            ))
            .sort((first, second) => new Date(second.createdAt).getTime() - new Date(first.createdAt).getTime());
    }

    return Promise.all(
        orders.map((order) => orderPayloadWithRewardState(order.email, order))
    );
}

function tasteMemoryRowToRecord(row) {
    return {
        id: row.id,
        orderID: row.order_id,
        productName: row.product_name,
        reaction: row.reaction,
        tags: Array.isArray(row.tags) ? row.tags : [],
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updatedAt: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at
    };
}

function allowedTasteMemoryTags() {
    return new Set(["Chocolate", "Fruity", "Floral", "Caramel", "Citrus", "Nutty"]);
}

function normalizeTasteMemoryTags(tags) {
    const allowed = allowedTasteMemoryTags();
    return [...new Set((Array.isArray(tags) ? tags : [])
        .map((tag) => String(tag || "").trim())
        .filter((tag) => allowed.has(tag)))]
        .slice(0, 6);
}

function normalizeTasteMemoryReaction(reaction) {
    const normalized = String(reaction || "").trim().toLowerCase();
    return ["loved", "not-for-me"].includes(normalized) ? normalized : "";
}

function tasteMemoryIDFor(email, orderID, productName) {
    const rawID = `${normalizeEmail(email)}|${String(orderID || "").trim()}|${String(productName || "").trim().toLowerCase()}`;
    return `taste_${crypto.createHash("sha256").update(rawID).digest("hex").slice(0, 18)}`;
}

function normalizeTasteMemoryInput(email, body) {
    const orderID = String(body.orderID || body.orderId || body.order_id || "").trim();
    const productName = String(body.productName || body.product_name || "").trim();
    const reaction = normalizeTasteMemoryReaction(body.reaction);
    const tags = normalizeTasteMemoryTags(body.tags);
    const submittedCreatedAt = body.createdAt ? new Date(body.createdAt) : null;

    if (!orderID || !productName || !reaction) {
        return null;
    }

    return {
        id: String(body.id || "").trim() || tasteMemoryIDFor(email, orderID, productName),
        orderID,
        productName,
        reaction,
        tags,
        createdAt: submittedCreatedAt && Number.isFinite(submittedCreatedAt.getTime())
            ? submittedCreatedAt.toISOString()
            : new Date().toISOString()
    };
}

async function tasteMemoryPayload(email) {
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) {
        return [];
    }

    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, order_id, product_name, reaction, tags, created_at, updated_at
             FROM taste_memory
             WHERE email = $1
             ORDER BY updated_at DESC`,
            [normalizedEmail]
        );
        return result.rows.map(tasteMemoryRowToRecord);
    }

    const store = readJSON(tasteMemoryStorePath);
    return (store.tasteMemory?.[normalizedEmail] || [])
        .slice()
        .sort((first, second) => new Date(second.updatedAt || second.createdAt).getTime() - new Date(first.updatedAt || first.createdAt).getTime());
}

async function allTasteMemoryPayload() {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT email, id, order_id, product_name, reaction, tags, created_at, updated_at
             FROM taste_memory
             ORDER BY updated_at DESC`
        );
        return result.rows.map((row) => ({
            ...tasteMemoryRowToRecord(row),
            email: normalizeEmail(row.email)
        }));
    }

    const store = readJSON(tasteMemoryStorePath);
    return Object.entries(store.tasteMemory || {})
        .flatMap(([email, records]) => (
            (Array.isArray(records) ? records : []).map((record) => ({
                ...record,
                email: normalizeEmail(email)
            }))
        ))
        .sort((first, second) => new Date(second.updatedAt || second.createdAt).getTime() - new Date(first.updatedAt || first.createdAt).getTime());
}

async function saveTasteMemoryRecord(email, input) {
    const normalizedEmail = normalizeEmail(email);
    const record = normalizeTasteMemoryInput(normalizedEmail, input);
    if (!normalizedEmail || !record) {
        return null;
    }

    const timestamp = new Date().toISOString();
    if (database.isEnabled()) {
        const result = await database.query(
            `INSERT INTO taste_memory
             (email, id, order_id, product_name, reaction, tags, created_at, updated_at)
             VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7, $8)
             ON CONFLICT (email, id)
             DO UPDATE SET
                order_id = EXCLUDED.order_id,
                product_name = EXCLUDED.product_name,
                reaction = EXCLUDED.reaction,
                tags = EXCLUDED.tags,
                updated_at = EXCLUDED.updated_at
             RETURNING id, order_id, product_name, reaction, tags, created_at, updated_at`,
            [
                normalizedEmail,
                record.id,
                record.orderID,
                record.productName,
                record.reaction,
                JSON.stringify(record.tags),
                record.createdAt,
                timestamp
            ]
        );
        return tasteMemoryRowToRecord(result.rows[0]);
    }

    const store = readJSON(tasteMemoryStorePath);
    const records = Array.isArray(store.tasteMemory?.[normalizedEmail])
        ? store.tasteMemory[normalizedEmail]
        : [];
    const nextRecord = {
        ...record,
        updatedAt: timestamp
    };
    const nextRecords = [
        nextRecord,
        ...records.filter((entry) => entry.id !== record.id)
    ].slice(0, 120);

    store.tasteMemory = store.tasteMemory || {};
    store.tasteMemory[normalizedEmail] = nextRecords;
    writeJSON(tasteMemoryStorePath, store);
    return nextRecord;
}

async function findOrderByID(orderID) {
    const normalizedOrderID = String(orderID || "").trim();
    if (!normalizedOrderID) {
        return null;
    }

    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, email, title, total, status, items, created_at
             FROM orders
             WHERE id = $1
             LIMIT 1`,
            [normalizedOrderID]
        );

        if (result.rowCount === 0) {
            return null;
        }

        const row = result.rows[0];
        return {
            ...orderRowToRecord(row),
            email: normalizeEmail(row.email)
        };
    }

    const store = readJSON(ordersStorePath);
    for (const [email, orders] of Object.entries(store.orders || {})) {
        const order = (Array.isArray(orders) ? orders : []).find((entry) => entry.id === normalizedOrderID);
        if (order) {
            return {
                ...order,
                email: normalizeEmail(email)
            };
        }
    }

    return null;
}

async function updateOrderStatusByID(orderID, status) {
    const order = await findOrderByID(orderID);
    if (!order) {
        return null;
    }

    return updateOrderStatusAndAward(order.email, orderID, status);
}

function orderStatusFromShopifyOrder(shopifyOrder, topic = "") {
    const normalizedTopic = String(topic || "").toLowerCase();
    const financialStatus = String(shopifyOrder.financial_status || "").toLowerCase();
    const fulfillmentStatus = String(shopifyOrder.fulfillment_status || "").toLowerCase();

    if (normalizedTopic.includes("fulfilled") || fulfillmentStatus === "fulfilled") {
        return "Fulfilled";
    }

    if (normalizedTopic.includes("paid") || financialStatus === "paid" || financialStatus === "partially_paid") {
        return "Completed";
    }

    if (financialStatus === "voided" || financialStatus === "refunded") {
        return "Cancelled";
    }

    return "Pending";
}

function orderStatusFromShopifyAdminOrder(order) {
    const displayFinancialStatus = String(order.displayFinancialStatus || "").toLowerCase();
    const displayFulfillmentStatus = String(order.displayFulfillmentStatus || "").toLowerCase();
    const cancelledAt = order.cancelledAt || null;

    if (cancelledAt || displayFinancialStatus.includes("voided") || displayFinancialStatus.includes("refunded")) {
        return "Cancelled";
    }

    if (displayFulfillmentStatus.includes("fulfilled")) {
        return "Fulfilled";
    }

    if (displayFinancialStatus.includes("paid") || displayFinancialStatus.includes("partially_paid")) {
        return "Completed";
    }

    if (displayFinancialStatus.includes("pending")) {
        return "Pending";
    }

    return "Pending";
}

function shopifyOrderRecord(shopifyOrder, topic = "") {
    const id = `shopify_${shopifyOrder.id || shopifyOrder.admin_graphql_api_id || shopifyOrder.name || Date.now()}`;
    const email = normalizeEmail(shopifyOrder.email || shopifyOrder.contact_email || shopifyOrder.customer?.email);
    const totalNumber = Number(shopifyOrder.current_total_price || shopifyOrder.total_price || 0);
    const currency = String(shopifyOrder.currency || "BHD").toUpperCase();
    const items = Array.isArray(shopifyOrder.line_items)
        ? shopifyOrder.line_items.map((item) => ({
            name: String(item.name || item.title || "Item"),
            quantity: Number(item.quantity || 1)
        }))
        : [];

    return {
        id,
        email,
        title: String(shopifyOrder.name || `Order ${shopifyOrder.order_number || ""}`).trim() || "Shopify Order",
        total: `${currency} ${Number.isFinite(totalNumber) ? totalNumber.toFixed(3) : "0.000"}`,
        totalNumber: Number.isFinite(totalNumber) ? totalNumber : 0,
        status: orderStatusFromShopifyOrder(shopifyOrder, topic),
        items,
        createdAt: shopifyOrder.created_at || new Date().toISOString()
    };
}

function shopifyAdminOrderRecord(node, fallbackEmail) {
    const totalAmount = Number(node.currentTotalPriceSet?.shopMoney?.amount || node.totalPriceSet?.shopMoney?.amount || 0);
    const currency = String(node.currentTotalPriceSet?.shopMoney?.currencyCode || node.totalPriceSet?.shopMoney?.currencyCode || "BHD").toUpperCase();
    const items = (node.lineItems?.edges || []).map(({ node: item }) => ({
        name: String(item.name || item.title || "Item"),
        quantity: Number(item.quantity || 1)
    }));

    return {
        id: `shopify_${node.legacyResourceId || node.id || node.name || Date.now()}`,
        email: normalizeEmail(node.email || fallbackEmail),
        title: String(node.name || "Shopify Order"),
        total: `${currency} ${Number.isFinite(totalAmount) ? totalAmount.toFixed(3) : "0.000"}`,
        totalNumber: Number.isFinite(totalAmount) ? totalAmount : 0,
        status: orderStatusFromShopifyAdminOrder(node),
        items,
        createdAt: node.createdAt || new Date().toISOString()
    };
}

function numericOrderTotal(order) {
    if (Number.isFinite(order.totalNumber)) {
        return order.totalNumber;
    }

    const match = String(order.total || "").match(/-?\d+(?:\.\d+)?/);
    const parsed = match ? Number(match[0]) : 0;
    return Number.isFinite(parsed) ? parsed : 0;
}

async function upsertOrderRecord(order) {
    if (!order.email || !order.id) {
        return null;
    }

    const account = await getAccountByEmail(order.email);
    if (!account) {
        return null;
    }

    await deleteMatchingPendingCheckout(order);

    if (database.isEnabled()) {
        const result = await database.query(
            `INSERT INTO orders
             (id, email, title, total, status, items, created_at)
             VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7)
             ON CONFLICT (id)
             DO UPDATE SET
                email = EXCLUDED.email,
                title = EXCLUDED.title,
                total = EXCLUDED.total,
                status = EXCLUDED.status,
                items = EXCLUDED.items
             RETURNING id, title, total, status, items, created_at`,
            [order.id, order.email, order.title, order.total, order.status, JSON.stringify(order.items), order.createdAt]
        );
        return orderRowToRecord(result.rows[0]);
    }

    const store = readJSON(ordersStorePath);
    const orders = store.orders[order.email] || [];
    const index = orders.findIndex((entry) => entry.id === order.id);
    const nextOrder = {
        id: order.id,
        title: order.title,
        total: order.total,
        status: order.status,
        items: order.items,
        createdAt: order.createdAt
    };

    if (index >= 0) {
        orders[index] = { ...orders[index], ...nextOrder };
    } else {
        orders.unshift(nextOrder);
    }

    store.orders[order.email] = orders;
    writeJSON(ordersStorePath, store);
    return nextOrder;
}

async function deleteMatchingPendingCheckout(order) {
    if (!order.email || String(order.id || "").startsWith("checkout_")) {
        return;
    }

    const orderTotal = numericOrderTotal(order);
    const createdAt = new Date(order.createdAt || Date.now()).getTime();
    const isSimilarPendingOrder = (candidate) => {
        const candidateCreatedAt = new Date(candidate.createdAt || candidate.created_at || Date.now()).getTime();
        const ageDifference = Math.abs(createdAt - candidateCreatedAt);
        return String(candidate.id || "").startsWith("checkout_")
            && String(candidate.status || "").toLowerCase() === "pending"
            && Math.abs(numericOrderTotal(candidate) - orderTotal) < 0.001
            && ageDifference < 2 * 24 * 60 * 60 * 1000;
    };

    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, email, title, total, status, items, created_at
             FROM orders
             WHERE email = $1 AND id LIKE 'checkout_%' AND status = 'Pending'
             ORDER BY created_at DESC
             LIMIT 10`,
            [order.email]
        );
        const matchingOrder = result.rows.map(orderRowToRecord).find(isSimilarPendingOrder);
        if (matchingOrder) {
            await database.query(
                `DELETE FROM orders WHERE email = $1 AND id = $2`,
                [order.email, matchingOrder.id]
            );
        }
        return;
    }

    const store = readJSON(ordersStorePath);
    const orders = Array.isArray(store.orders[order.email]) ? store.orders[order.email] : [];
    const nextOrders = orders.filter((candidate) => !isSimilarPendingOrder(candidate));
    if (nextOrders.length !== orders.length) {
        store.orders[order.email] = nextOrders;
        writeJSON(ordersStorePath, store);
    }
}

async function hasLoyaltyTransaction(email, transactionID) {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT 1
             FROM loyalty_transactions
             WHERE email = $1 AND id = $2`,
            [email, transactionID]
        );
        return result.rowCount > 0;
    }

    const store = readJSON(loyaltyStorePath);
    const transactions = store.accounts[email]?.transactions || [];
    return transactions.some((transaction) => transaction.id === transactionID);
}

async function awardOrderBeans(order) {
    if (!completedOrderStatuses().has(order.status)) {
        return { awarded: false, points: 0, reason: "ORDER_NOT_COMPLETED" };
    }

    const points = orderBeansFor(order);
    if (points <= 0) {
        return { awarded: false, points: 0, reason: "NO_POINTS" };
    }

    const transactionID = loyaltyTransactionIDForOrder(order);
    if (await hasLoyaltyTransaction(order.email, transactionID)) {
        return { awarded: false, points, reason: "ALREADY_AWARDED" };
    }

    const updated = await updateLoyaltyAccount(order.email, (account) => {
        account.pointsBalance += points;
        account.transactions = account.transactions || [];
        account.transactions.unshift({
            id: transactionID,
            type: "earn",
            points,
            note: `Completed order ${order.title} • ${points} Beans • ${order.total}`,
            createdAt: new Date().toISOString()
        });
    });

    if (!updated) {
        return { awarded: false, points, reason: "LOYALTY_ACCOUNT_NOT_FOUND" };
    }

    return { awarded: true, points };
}

function cardPaymentRowToRecord(row) {
    return {
        paymentID: row.payment_id,
        localOrderID: row.local_order_id,
        mpgsOrderID: row.mpgs_order_id,
        sessionID: row.session_id,
        sessionVersion: row.session_version,
        amount: row.amount,
        currency: row.currency,
        email: normalizeEmail(row.email),
        paymentMethod: row.payment_method || "CARD",
        authenticationTransactionID: row.authentication_transaction_id || null,
        purchaseTransactionID: row.purchase_transaction_id || null,
        gatewayResult: row.gateway_result || null,
        gatewayTransactionResult: row.gateway_transaction_result || null,
        resultTokenHash: row.result_token_hash || null,
        successIndicatorHash: row.success_indicator_hash || null,
        status: row.status,
        completedAt: row.completed_at instanceof Date ? row.completed_at.toISOString() : row.completed_at || null,
        effectsAppliedAt: row.effects_applied_at instanceof Date
            ? row.effects_applied_at.toISOString()
            : row.effects_applied_at || null,
        lastGatewayResponseAt: row.last_gateway_response_at instanceof Date
            ? row.last_gateway_response_at.toISOString()
            : row.last_gateway_response_at || null,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updatedAt: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at
    };
}

function normalizeCardPaymentIdentifier(value, maxLength = 255) {
    const normalized = String(value || "").trim();
    if (!normalized
        || normalized.length > maxLength
        || !/^[A-Za-z0-9][A-Za-z0-9._:#-]*$/.test(normalized)) {
        return "";
    }
    return normalized;
}

async function findPendingCardPayment(localOrderID, email) {
    const normalizedOrderID = String(localOrderID || "").trim();
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedOrderID || !normalizedEmail) {
        return null;
    }
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT *
             FROM card_payments
             WHERE local_order_id = $1 AND email = $2 AND status = 'Pending'
             ORDER BY created_at DESC
             LIMIT 1`,
            [normalizedOrderID, normalizedEmail]
        );
        return result.rowCount > 0 ? cardPaymentRowToRecord(result.rows[0]) : null;
    }
    const store = readJSON(cardPaymentsStorePath);
    return Object.values(store.payments || {})
        .filter((payment) => (
            payment.localOrderID === normalizedOrderID
            && normalizeEmail(payment.email) === normalizedEmail
            && payment.status === "Pending"
        ))
        .sort((first, second) => new Date(second.createdAt).getTime() - new Date(first.createdAt).getTime())[0] || null;
}

async function findCardPayment(identifier, email) {
    const normalizedIdentifier = String(identifier || "").trim();
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedIdentifier || normalizedIdentifier.length > 255 || !normalizedEmail) {
        return null;
    }
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT *
             FROM card_payments
             WHERE email = $1 AND (payment_id = $2 OR local_order_id = $2)
             ORDER BY created_at DESC
             LIMIT 1`,
            [normalizedEmail, normalizedIdentifier]
        );
        return result.rowCount > 0 ? cardPaymentRowToRecord(result.rows[0]) : null;
    }
    const store = readJSON(cardPaymentsStorePath);
    return Object.values(store.payments || {})
        .filter((payment) => (
            normalizeEmail(payment.email) === normalizedEmail
            && (payment.paymentID === normalizedIdentifier || payment.localOrderID === normalizedIdentifier)
        ))
        .sort((first, second) => new Date(second.createdAt).getTime() - new Date(first.createdAt).getTime())[0] || null;
}

async function persistCardPayment(payment) {
    if (database.isEnabled()) {
        try {
            const result = await database.query(
                `INSERT INTO card_payments
                 (payment_id, local_order_id, mpgs_order_id, session_id, session_version,
                  amount, currency, email, payment_method, result_token_hash, success_indicator_hash,
                  status, created_at, updated_at)
                 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $13)
                 RETURNING *`,
                [
                    payment.paymentID,
                    payment.localOrderID,
                    payment.mpgsOrderID,
                    payment.sessionID,
                    payment.sessionVersion,
                    payment.amount,
                    payment.currency,
                    payment.email,
                    payment.paymentMethod || "CARD",
                    payment.resultTokenHash || null,
                    payment.successIndicatorHash || null,
                    payment.status,
                    payment.createdAt
                ]
            );
            return cardPaymentRowToRecord(result.rows[0]);
        } catch (error) {
            if (error?.code === "23505") {
                const existing = await findPendingCardPayment(payment.localOrderID, payment.email);
                if (existing) {
                    return existing;
                }
            }
            throw error;
        }
    }
    const store = readJSON(cardPaymentsStorePath);
    store.payments = store.payments || {};
    const existing = Object.values(store.payments).find((candidate) => (
        candidate.localOrderID === payment.localOrderID
        && normalizeEmail(candidate.email) === normalizeEmail(payment.email)
        && candidate.status === "Pending"
    ));
    if (existing) {
        return existing;
    }
    store.payments[payment.paymentID] = payment;
    writeJSON(cardPaymentsStorePath, store);
    return payment;
}

async function updateCardPaymentSessionVersion(paymentID, sessionVersion) {
    const normalizedVersion = String(sessionVersion || "").trim();
    if (!normalizedVersion) {
        return;
    }
    const updatedAt = new Date().toISOString();
    if (database.isEnabled()) {
        await database.query(
            `UPDATE card_payments
             SET session_version = $2, updated_at = $3
             WHERE payment_id = $1`,
            [paymentID, normalizedVersion, updatedAt]
        );
        return;
    }
    const store = readJSON(cardPaymentsStorePath);
    if (store.payments?.[paymentID]) {
        store.payments[paymentID].sessionVersion = normalizedVersion;
        store.payments[paymentID].updatedAt = updatedAt;
        writeJSON(cardPaymentsStorePath, store);
    }
}

async function findCardPaymentByID(paymentID) {
    const normalizedPaymentID = normalizeCardPaymentIdentifier(paymentID);
    if (!normalizedPaymentID) {
        return null;
    }
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT * FROM card_payments WHERE payment_id = $1 LIMIT 1`,
            [normalizedPaymentID]
        );
        return result.rowCount > 0 ? cardPaymentRowToRecord(result.rows[0]) : null;
    }
    return readJSON(cardPaymentsStorePath).payments?.[normalizedPaymentID] || null;
}

async function findCardPaymentByResultToken(resultToken) {
    const normalizedToken = normalizeCardPaymentIdentifier(resultToken, 200);
    if (!normalizedToken) {
        return null;
    }
    const tokenHash = sha256Hex(normalizedToken);
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT * FROM card_payments WHERE result_token_hash = $1 LIMIT 1`,
            [tokenHash]
        );
        return result.rowCount > 0 ? cardPaymentRowToRecord(result.rows[0]) : null;
    }
    const store = readJSON(cardPaymentsStorePath);
    return Object.values(store.payments || {}).find((payment) => (
        payment.resultTokenHash && timingSafeStringEqual(payment.resultTokenHash, tokenHash)
    )) || null;
}

async function updateCardPaymentLifecycle(paymentID, fields = {}) {
    const updatedAt = new Date().toISOString();
    if (database.isEnabled()) {
        const result = await database.query(
            `UPDATE card_payments
             SET authentication_transaction_id = COALESCE($2, authentication_transaction_id),
                 purchase_transaction_id = COALESCE($3, purchase_transaction_id),
                 gateway_result = COALESCE($4, gateway_result),
                 gateway_transaction_result = COALESCE($5, gateway_transaction_result),
                 status = COALESCE($6, status),
                 completed_at = COALESCE($7, completed_at),
                 effects_applied_at = COALESCE($8, effects_applied_at),
                 last_gateway_response_at = COALESCE($9, last_gateway_response_at),
                 session_version = COALESCE($10, session_version),
                 updated_at = $11
             WHERE payment_id = $1
             RETURNING *`,
            [
                paymentID,
                fields.authenticationTransactionID || null,
                fields.purchaseTransactionID || null,
                fields.gatewayResult || null,
                fields.gatewayTransactionResult || null,
                fields.status || null,
                fields.completedAt || null,
                fields.effectsAppliedAt || null,
                fields.lastGatewayResponseAt || null,
                fields.sessionVersion || null,
                updatedAt
            ]
        );
        return result.rowCount > 0 ? cardPaymentRowToRecord(result.rows[0]) : null;
    }
    const store = readJSON(cardPaymentsStorePath);
    const payment = store.payments?.[paymentID];
    if (!payment) {
        return null;
    }
    for (const [key, value] of Object.entries(fields)) {
        if (value !== undefined && value !== null && value !== "") {
            payment[key] = value;
        }
    }
    payment.updatedAt = updatedAt;
    writeJSON(cardPaymentsStorePath, store);
    return payment;
}

function createMpgsTransactionID(prefix) {
    return `${prefix}${Date.now()}${crypto.randomBytes(6).toString("hex")}`.slice(0, 40);
}

function mpgsTransactions(gatewayOrder) {
    const transactions = gatewayOrder?.transaction;
    if (Array.isArray(transactions)) {
        return transactions;
    }
    if (transactions && typeof transactions === "object") {
        return Object.values(transactions);
    }
    return [];
}

function verifyConfirmedMpgsOrder(payment, order, gatewayOrder) {
    mpgsGateway.verifyMpgsOrderPayment(payment, order, payment?.email);
    const gatewayCurrency = String(gatewayOrder?.order?.currency || gatewayOrder?.currency || "").toUpperCase();
    const gatewayAmount = bhdFils(gatewayOrder?.order?.amount ?? gatewayOrder?.amount);
    if (String(gatewayOrder?.order?.id || gatewayOrder?.id || "") !== payment.mpgsOrderID) {
        throw benefitPaymentError("MPGS_ORDER_MISMATCH", 409, "Gateway order does not match.");
    }
    if (gatewayCurrency !== "BHD") {
        throw benefitPaymentError("MPGS_CURRENCY_MISMATCH", 409, "Gateway currency does not match.");
    }
    if (gatewayAmount === null || gatewayAmount !== bhdFils(payment.amount)) {
        throw benefitPaymentError("MPGS_AMOUNT_MISMATCH", 409, "Gateway amount does not match.");
    }
    const transactions = mpgsTransactions(gatewayOrder);
    const successfulTransaction = transactions.find((transaction) => {
        const idMatches = !payment.purchaseTransactionID
            || String(transaction?.transaction?.id || transaction?.id || "") === payment.purchaseTransactionID;
        const result = String(transaction?.result || "").toUpperCase();
        const type = String(transaction?.transaction?.type || transaction?.type || "").toUpperCase();
        return idMatches && result === "SUCCESS" && ["PAYMENT", "PURCHASE"].includes(type);
    });
    const orderStatus = String(gatewayOrder?.order?.status || gatewayOrder?.status || "").toUpperCase();
    if (!successfulTransaction || !["CAPTURED", "PAID"].includes(orderStatus)) {
        throw benefitPaymentError("MPGS_PAYMENT_NOT_APPROVED", 402, "Card payment was not approved.");
    }
    return successfulTransaction;
}

function verifyMpgsAuthenticationForPurchase(payment, gatewayOrder) {
    if (payment.paymentMethod !== "CARD") {
        return true;
    }
    if (!payment.authenticationTransactionID) {
        throw benefitPaymentError("MPGS_AUTHENTICATION_REQUIRED", 409, "Payer authentication is required.");
    }
    const authentication = mpgsTransactions(gatewayOrder).find((transaction) => (
        String(transaction?.transaction?.id || transaction?.id || "") === payment.authenticationTransactionID
    ));
    const result = String(authentication?.result || "").toUpperCase();
    const status = String(
        authentication?.authentication?.["3ds2"]?.transactionStatus
        || authentication?.authentication?.transactionStatus
        || ""
    ).toUpperCase();
    if (result !== "SUCCESS" || !["Y", "A"].includes(status)) {
        throw benefitPaymentError("MPGS_AUTHENTICATION_FAILED", 402, "Payer authentication was not successful.");
    }
    return true;
}

async function applyConfirmedMpgsPayment(paymentID, gatewayOrder) {
    const payment = await findCardPaymentByID(paymentID);
    const order = payment ? await findOrderByID(payment.localOrderID) : null;
    const transaction = verifyConfirmedMpgsOrder(payment, order, gatewayOrder);
    const completedAt = new Date().toISOString();

    if (database.isEnabled()) {
        const client = await database.connect();
        try {
            await client.query("BEGIN");
            const paymentResult = await client.query(
                `SELECT * FROM card_payments WHERE payment_id = $1 FOR UPDATE`,
                [paymentID]
            );
            if (paymentResult.rowCount === 0) {
                throw benefitPaymentError("MPGS_PAYMENT_NOT_FOUND", 404, "Card payment was not found.");
            }
            const lockedPayment = cardPaymentRowToRecord(paymentResult.rows[0]);
            const orderResult = await client.query(
                `SELECT id, email, title, total, status, items, created_at
                 FROM orders WHERE id = $1 FOR UPDATE`,
                [lockedPayment.localOrderID]
            );
            if (orderResult.rowCount === 0) {
                throw benefitPaymentError("MPGS_ORDER_NOT_FOUND", 404, "Order was not found.");
            }
            const lockedOrder = {
                ...orderRowToRecord(orderResult.rows[0]),
                email: normalizeEmail(orderResult.rows[0].email)
            };
            verifyConfirmedMpgsOrder(lockedPayment, lockedOrder, gatewayOrder);
            if (lockedPayment.effectsAppliedAt) {
                await client.query("COMMIT");
                return { applied: false, payment: lockedPayment };
            }
            const updatedOrder = await client.query(
                `UPDATE orders
                 SET status = CASE WHEN status IN ('Completed', 'Fulfilled', 'Delivered') THEN status ELSE 'Completed' END
                 WHERE id = $1
                 RETURNING id, email, title, total, status, items, created_at`,
                [lockedOrder.id]
            );
            await awardOrderBeansWithClient(client, {
                ...orderRowToRecord(updatedOrder.rows[0]),
                email: normalizeEmail(updatedOrder.rows[0].email)
            });
            await client.query(
                `UPDATE card_payments
                 SET status = 'Captured', gateway_result = $2, gateway_transaction_result = $3,
                     completed_at = $4, effects_applied_at = $4, last_gateway_response_at = $4, updated_at = $4
                 WHERE payment_id = $1`,
                [paymentID, String(gatewayOrder.result || "SUCCESS"), String(transaction.result || "SUCCESS"), completedAt]
            );
            await client.query("COMMIT");
            queueShopifyOrderExport(lockedOrder.id);
            return { applied: true, payment: { ...lockedPayment, status: "Captured", effectsAppliedAt: completedAt } };
        } catch (error) {
            await client.query("ROLLBACK");
            throw error;
        } finally {
            client.release();
        }
    }

    return withCardPaymentLock(paymentID, async () => {
        const store = readJSON(cardPaymentsStorePath);
        const storedPayment = store.payments?.[paymentID];
        if (!storedPayment) {
            throw benefitPaymentError("MPGS_PAYMENT_NOT_FOUND", 404, "Card payment was not found.");
        }
        if (storedPayment.effectsAppliedAt) {
            return { applied: false, payment: storedPayment };
        }
        const ordersStore = readJSON(ordersStorePath);
        const orders = Array.isArray(ordersStore.orders[storedPayment.email])
            ? ordersStore.orders[storedPayment.email]
            : [];
        const index = orders.findIndex((candidate) => candidate.id === storedPayment.localOrderID);
        if (index === -1) {
            throw benefitPaymentError("MPGS_ORDER_NOT_FOUND", 404, "Order was not found.");
        }
        verifyConfirmedMpgsOrder(storedPayment, { ...orders[index], email: storedPayment.email }, gatewayOrder);
        orders[index] = {
            ...orders[index],
            status: completedOrderStatuses().has(orders[index].status) ? orders[index].status : "Completed"
        };
        ordersStore.orders[storedPayment.email] = orders;
        writeJSON(ordersStorePath, ordersStore);
        await awardOrderBeans({ ...orders[index], email: storedPayment.email });
        Object.assign(storedPayment, {
            status: "Captured",
            gatewayResult: String(gatewayOrder.result || "SUCCESS"),
            gatewayTransactionResult: String(transaction.result || "SUCCESS"),
            completedAt,
            effectsAppliedAt: completedAt,
            lastGatewayResponseAt: completedAt,
            updatedAt: completedAt
        });
        writeJSON(cardPaymentsStorePath, store);
        queueShopifyOrderExport(storedPayment.localOrderID);
        return { applied: true, payment: storedPayment };
    });
}

async function withCardPaymentLock(key, operation) {
    const existing = cardPaymentLocks.get(key);
    if (existing) {
        return existing;
    }
    const pending = Promise.resolve().then(operation);
    cardPaymentLocks.set(key, pending);
    try {
        return await pending;
    } finally {
        if (cardPaymentLocks.get(key) === pending) {
            cardPaymentLocks.delete(key);
        }
    }
}

function maskMpgsSessionID(sessionID) {
    const value = String(sessionID || "");
    return value.length > 8 ? `${value.slice(0, 4)}…${value.slice(-4)}` : "[masked]";
}

function mpgsSessionResponse(payment) {
    return {
        sessionId: payment.sessionID,
        sessionVersion: payment.sessionVersion,
        apiVersion: mpgsConfiguration.apiVersion,
        merchantId: mpgsConfiguration.merchantId,
        orderId: payment.mpgsOrderID,
        amount: payment.amount,
        currency: "BHD"
    };
}

function sanitizedMpgsSessionStatus(payment, gatewaySession) {
    return {
        paymentSessionId: payment.paymentID,
        localOrderId: payment.localOrderID,
        orderId: payment.mpgsOrderID,
        status: payment.status,
        gatewayResult: String(gatewaySession.result || "UNKNOWN").slice(0, 30),
        updateStatus: String(gatewaySession.session?.updateStatus || "UNKNOWN").slice(0, 30),
        sessionVersion: String(gatewaySession.session?.version || payment.sessionVersion),
        amount: payment.amount,
        currency: "BHD"
    };
}

function publicPaymentURL(pathname, resultToken, extraParameters = {}) {
    let resultURL;
    try {
        resultURL = new URL(pathname, config.appURL);
    } catch (error) {
        throw benefitPaymentError("MPGS_PUBLIC_URL_INVALID", 503, "Public payment URL is not configured.");
    }
    const localDevelopment = ["localhost", "127.0.0.1"].includes(resultURL.hostname);
    if ((resultURL.protocol !== "https:" && !localDevelopment) || resultURL.username || resultURL.password) {
        throw benefitPaymentError("MPGS_PUBLIC_URL_INVALID", 503, "Public payment URL is not configured.");
    }
    if (resultToken) resultURL.searchParams.set("payment", resultToken);
    for (const [key, value] of Object.entries(extraParameters)) {
        resultURL.searchParams.set(key, String(value));
    }
    return resultURL.toString();
}

function renderClickToPayLaunch(payment, resultToken) {
    const gatewayOrigin = new URL(mpgsConfiguration.baseURL).origin;
    const checkoutScript = `${gatewayOrigin}/static/checkout/checkout.min.js`;
    const returnURL = publicPaymentURL("/api/payments/click-to-pay/return", resultToken);
    const errorURL = publicPaymentURL("/api/payments/click-to-pay/return", resultToken, { error: 1 });
    const cancelURL = publicPaymentURL("/api/payments/click-to-pay/return", resultToken, { cancelled: 1 });
    const timeoutURL = publicPaymentURL("/api/payments/click-to-pay/return", resultToken, { timeout: 1 });
    return `<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; script-src 'unsafe-inline' ${escapeHTML(gatewayOrigin)}; style-src 'unsafe-inline'; connect-src ${escapeHTML(gatewayOrigin)}; frame-src ${escapeHTML(gatewayOrigin)}; form-action ${escapeHTML(gatewayOrigin)}; base-uri 'none'">
    <title>Opening Click to Pay</title>
    <style>body{font-family:-apple-system,sans-serif;background:#f7f3ea;color:#231f1a;display:grid;min-height:100vh;place-items:center;margin:0}main{text-align:center;padding:2rem}p{line-height:1.5}</style>
    <script>
    function paymentError(){ window.location.replace(${JSON.stringify(errorURL)}); }
    function paymentCancelled(){ window.location.replace(${JSON.stringify(cancelURL)}); }
    function paymentTimeout(){ window.location.replace(${JSON.stringify(timeoutURL)}); }
    </script>
    <script src="${escapeHTML(checkoutScript)}" data-complete="${escapeHTML(returnURL)}" data-error="paymentError" data-cancel="paymentCancelled" data-timeout="paymentTimeout"></script>
</head>
<body><main><h1>Opening secure checkout</h1><p>Please wait while Mastercard Click to Pay opens.</p></main>
<script>
Checkout.configure({session:{id:${JSON.stringify(payment.sessionID)}}});
Checkout.showPaymentPage();
</script></body></html>`;
}

function mpgsResultIndicatorMatches(payment, resultIndicator) {
    const normalizedIndicator = String(resultIndicator || "").trim();
    const expectedHash = String(payment?.successIndicatorHash || "").trim();
    if (!expectedHash || !/^[\x21-\x7E]{16,128}$/.test(normalizedIndicator)) {
        return false;
    }
    return timingSafeStringEqual(expectedHash, sha256Hex(normalizedIndicator));
}

function renderMpgsResultPage(state) {
    const content = {
        success: ["Payment confirmed", "Your payment was confirmed. You can return to Talla."],
        cancelled: ["Payment cancelled", "No payment was confirmed. You can return to Talla and try again."],
        failure: ["Payment not completed", "The payment could not be confirmed. No order was marked paid."],
        pending: ["Payment pending", "The gateway has not confirmed payment yet. Check your order again shortly."]
    }[state] || ["Payment pending", "The payment is still being checked."];
    const appStatus = state === "success"
        ? "success"
        : state === "cancelled" ? "cancelled" : state === "failure" ? "failed" : "pending";
    return `<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${escapeHTML(content[0])}</title><style>body{font-family:-apple-system,sans-serif;background:#f7f3ea;color:#231f1a;display:grid;min-height:100vh;place-items:center;margin:0}main{background:#fffdf8;border-radius:20px;padding:2rem;width:min(84vw,28rem);text-align:center}a{display:inline-block;background:#231f1a;color:white;padding:.8rem 1.2rem;border-radius:999px;text-decoration:none}</style></head><body><main><h1>${escapeHTML(content[0])}</h1><p>${escapeHTML(content[1])}</p><a href="talla://checkout-return?status=${appStatus}">Return to Talla</a></main></body></html>`;
}

function benefitPaymentError(code, statusCode, message) {
    const error = new Error(message);
    error.code = code;
    error.statusCode = statusCode;
    return error;
}

function benefitPublicError(error) {
    if (error?.code === "REQUEST_BODY_TOO_LARGE") {
        return { statusCode: 413, message: "Request body is too large." };
    }
    if (error?.statusCode && error.statusCode < 500) {
        return { statusCode: error.statusCode, message: error.message };
    }
    return {
        statusCode: error?.statusCode || 500,
        message: error?.code === "BENEFIT_NOT_CONFIGURED"
            ? "BENEFIT checkout is not configured."
            : "BENEFIT checkout is temporarily unavailable."
    };
}

function benefitConfigured() {
    return Boolean(
        benefitTranportalID
        && benefitTranportalPassword
        && benefitResourceKey
        && benefitAPIEndpoint
        && benefitSuccessURL
        && benefitErrorURL
        && benefitNotificationURL
    );
}

function benefitPayConfigured() {
    return Object.values(benefitPayConfiguration).every((value) => String(value || "").trim());
}

function createBenefitPayCheckStatusSignature(parameters) {
    const valueToSign = Object.entries(parameters)
        .sort(([firstKey, firstValue], [secondKey, secondValue]) => {
            const keyComparison = firstKey.localeCompare(secondKey);
            return keyComparison || String(firstValue).localeCompare(String(secondValue));
        })
        .map(([key, value]) => `${key}="${String(value)}"`)
        .join(",");
    return crypto
        .createHmac("sha256", benefitPayConfiguration.secretKey)
        .update(valueToSign, "utf8")
        .digest("base64");
}

async function queryBenefitPayTransaction(referenceID) {
    const body = {
        merchant_id: benefitPayConfiguration.merchantID,
        reference_id: referenceID
    };
    const endpoint = safeConfiguredBenefitURL(
        benefitPayConfiguration.checkStatusURL,
        "BenefitPay check-status URL"
    );
    const upstreamResponse = await fetch(endpoint, {
        method: "POST",
        headers: {
            "Content-Type": "application/json; charset=utf-8",
            Accept: "application/json",
            "X-CLIENT-ID": benefitPayConfiguration.appID,
            "X-FOO-Signature": createBenefitPayCheckStatusSignature(body),
            "X-FOO-Signature-Type": "KEYVAL"
        },
        body: JSON.stringify(body),
        signal: AbortSignal.timeout(15_000)
    });
    const responseText = await upstreamResponse.text();
    if (responseText.length > 131_072) {
        throw benefitPaymentError("BENEFITPAY_RESPONSE_INVALID", 502, "BenefitPay returned an invalid response.");
    }
    let payload;
    try {
        payload = JSON.parse(responseText);
    } catch {
        throw benefitPaymentError("BENEFITPAY_RESPONSE_INVALID", 502, "BenefitPay returned an invalid response.");
    }
    if (!upstreamResponse.ok || payload?.meta?.status !== "OK" || !payload?.response) {
        throw benefitPaymentError("BENEFITPAY_QUERY_FAILED", 502, "BenefitPay could not confirm the transaction.");
    }
    return payload.response;
}

function normalizeBenefitIdentifier(value, maxLength = 255) {
    const normalized = String(value || "").trim();
    if (!normalized
        || normalized.length > maxLength
        || !/^[A-Za-z0-9][A-Za-z0-9._:/#-]*$/.test(normalized)) {
        return "";
    }
    return normalized;
}

function normalizeBenefitPayMPQRText(value, maxLength) {
    return Array.from(String(value || "").trim().replace(/\s+/g, " "))
        .slice(0, maxLength)
        .join("")
        .trimEnd();
}

function createBenefitPayReferenceID() {
    return `BP${Date.now().toString(36).toUpperCase()}${crypto.randomBytes(6).toString("hex").toUpperCase()}`;
}

function timingSafeStringEqual(first, second) {
    const firstBuffer = Buffer.from(String(first || ""), "utf8");
    const secondBuffer = Buffer.from(String(second || ""), "utf8");
    return firstBuffer.length === secondBuffer.length
        && crypto.timingSafeEqual(firstBuffer, secondBuffer);
}

function orderCurrency(order) {
    const match = String(order.total || "").trim().match(/^([A-Za-z]{3})\b/);
    return match ? match[1].toUpperCase() : "BHD";
}

function bhdFils(value) {
    const normalized = typeof value === "number"
        ? value.toFixed(3)
        : String(value || "").trim();
    const match = normalized.match(/^(\d+)(?:\.(\d{1,3}))?$/);
    if (!match) {
        return null;
    }
    const whole = Number(match[1]);
    const fractional = Number((match[2] || "").padEnd(3, "0"));
    const fils = whole * 1000 + fractional;
    return Number.isSafeInteger(fils) ? fils : null;
}

function safeConfiguredBenefitURL(value, name, requiredPath = "") {
    let url;
    try {
        url = new URL(String(value || ""));
    } catch (error) {
        throw benefitPaymentError("BENEFIT_NOT_CONFIGURED", 503, `${name} is not configured.`);
    }
    if (url.protocol !== "https:" || url.username || url.password) {
        throw benefitPaymentError("BENEFIT_NOT_CONFIGURED", 503, `${name} must be a secure HTTPS URL.`);
    }
    if (requiredPath && url.pathname !== requiredPath) {
        throw benefitPaymentError("BENEFIT_NOT_CONFIGURED", 503, `${name} must use ${requiredPath}.`);
    }
    return url;
}

function benefitResultURL(baseURL, resultToken = "") {
    const url = safeConfiguredBenefitURL(baseURL, "BENEFIT result URL", "/api/payments/benefit/result");
    if (resultToken) {
        url.searchParams.set("payment", resultToken);
    }
    return url.toString();
}

function normalizedBenefitPathname(pathname) {
    let normalized = String(pathname || "");
    try {
        normalized = decodeURIComponent(normalized);
    } catch {
    }
    normalized = normalized.replace(/[\u200B-\u200D\uFEFF]/g, "");
    normalized = normalized.split(/[?#]/, 1)[0];
    return normalized.length > 1 ? normalized.replace(/\/+$/, "") : normalized;
}

function benefitPathMatches(pathname, expectedPath) {
    return normalizedBenefitPathname(pathname) === expectedPath;
}

function isBenefitBrowserReturnPath(pathname) {
    const normalized = normalizedBenefitPathname(pathname);
    if ([
        "/api/payments/benefit/result",
        "/api/payments/benefit/response",
        "/api/payments/benefit/return",
        "/api/payments/benefit/callback"
    ].includes(normalized)) {
        return true;
    }
    const compact = normalized.toLowerCase().replace(/[^a-z0-9]/g, "");
    return compact.startsWith("apipaymentsbenefit")
        && ["result", "response", "return", "callback"].some((name) => compact.includes(name));
}

function benefitPaymentRowToRecord(row) {
    return {
        trackID: row.track_id,
        orderID: row.order_id,
        email: normalizeEmail(row.email),
        amount: row.amount,
        currency: row.currency,
        status: row.status,
        resultTokenHash: row.result_token_hash,
        hostedPaymentURL: row.hosted_payment_url || null,
        paymentID: row.payment_id || null,
        transactionID: row.transaction_id || null,
        referenceID: row.reference_id || null,
        gatewayResult: row.gateway_result || null,
        authCode: row.auth_code || null,
        authResponseCode: row.auth_response_code || null,
        errorCode: row.error_code || null,
        errorText: row.error_text || null,
        notificationHash: row.notification_hash || null,
        notificationReceivedAt: row.notification_received_at instanceof Date
            ? row.notification_received_at.toISOString()
            : row.notification_received_at || null,
        processedAt: row.processed_at instanceof Date ? row.processed_at.toISOString() : row.processed_at || null,
        effectsAppliedAt: row.effects_applied_at instanceof Date
            ? row.effects_applied_at.toISOString()
            : row.effects_applied_at || null,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updatedAt: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at
    };
}

async function createBenefitPendingPayment(payment) {
    if (database.isEnabled()) {
        const result = await database.query(
            `INSERT INTO benefit_payments
             (track_id, order_id, email, amount, currency, status, result_token_hash, created_at, updated_at)
             VALUES ($1, $2, $3, $4, $5, 'Pending', $6, $7, $7)
             RETURNING *`,
            [
                payment.trackID,
                payment.orderID,
                payment.email,
                payment.amount,
                payment.currency,
                payment.resultTokenHash,
                payment.createdAt
            ]
        );
        return benefitPaymentRowToRecord(result.rows[0]);
    }

    const store = readJSON(benefitPaymentsStorePath);
    store.payments = store.payments || {};
    store.payments[payment.trackID] = {
        ...payment,
        status: "Pending",
        updatedAt: payment.createdAt
    };
    writeJSON(benefitPaymentsStorePath, store);
    return store.payments[payment.trackID];
}

async function findBenefitPaymentByTrackID(trackID) {
    const normalizedTrackID = normalizeBenefitIdentifier(trackID);
    if (!normalizedTrackID) {
        return null;
    }
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT *
             FROM benefit_payments
             WHERE track_id = $1
             LIMIT 1`,
            [normalizedTrackID]
        );
        return result.rowCount > 0 ? benefitPaymentRowToRecord(result.rows[0]) : null;
    }
    const store = readJSON(benefitPaymentsStorePath);
    return store.payments?.[normalizedTrackID] || null;
}

async function findBenefitPaymentByResultToken(resultToken) {
    const normalizedToken = normalizeBenefitIdentifier(resultToken, 200);
    if (!normalizedToken) {
        return null;
    }
    const tokenHash = sha256Hex(normalizedToken);
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT *
             FROM benefit_payments
             WHERE result_token_hash = $1
             LIMIT 1`,
            [tokenHash]
        );
        return result.rowCount > 0 ? benefitPaymentRowToRecord(result.rows[0]) : null;
    }
    const store = readJSON(benefitPaymentsStorePath);
    return Object.values(store.payments || {}).find((payment) => (
        timingSafeStringEqual(payment.resultTokenHash, tokenHash)
    )) || null;
}

async function updateBenefitPaymentInitiation(trackID, hostedPaymentURL, status = "Initiated") {
    const updatedAt = new Date().toISOString();
    if (database.isEnabled()) {
        const result = await database.query(
            `UPDATE benefit_payments
             SET hosted_payment_url = $2, status = $3, updated_at = $4
             WHERE track_id = $1
             RETURNING *`,
            [trackID, hostedPaymentURL || null, status, updatedAt]
        );
        return result.rowCount > 0 ? benefitPaymentRowToRecord(result.rows[0]) : null;
    }
    const store = readJSON(benefitPaymentsStorePath);
    const payment = store.payments?.[trackID];
    if (!payment) {
        return null;
    }
    payment.hostedPaymentURL = hostedPaymentURL || null;
    payment.status = status;
    payment.updatedAt = updatedAt;
    writeJSON(benefitPaymentsStorePath, store);
    return payment;
}

function benefitNotificationStatus(notification) {
    if (notification.errorCode || notification.errorText) {
        return "GatewayError";
    }
    const statuses = {
        "CAPTURED": "NotificationReceived",
        "NOT CAPTURED": "Declined",
        "CANCELED": "Canceled",
        "DENIED BY RISK": "DeniedByRisk",
        "HOST TIMEOUT": "HostTimeout"
    };
    return statuses[notification.result] || "NotificationReceived";
}

function verifyBenefitNotification(payment, order, notification) {
    if (!payment || !order) {
        throw benefitPaymentError("BENEFIT_PAYMENT_NOT_FOUND", 404, "BENEFIT payment was not found.");
    }
    if (!notification.trackID || !timingSafeStringEqual(notification.trackID, payment.trackID)) {
        throw benefitPaymentError("BENEFIT_TRACK_MISMATCH", 409, "BENEFIT track ID does not match.");
    }
    if (!timingSafeStringEqual(payment.orderID, order.id)) {
        throw benefitPaymentError("BENEFIT_ORDER_MISMATCH", 409, "BENEFIT order does not match.");
    }
    if (notification.orderID && !timingSafeStringEqual(notification.orderID, payment.orderID)) {
        throw benefitPaymentError("BENEFIT_ORDER_MISMATCH", 409, "BENEFIT order does not match.");
    }
    if (notification.resultToken
        && !timingSafeStringEqual(sha256Hex(notification.resultToken), payment.resultTokenHash)) {
        throw benefitPaymentError("BENEFIT_RESULT_TOKEN_MISMATCH", 409, "BENEFIT result token does not match.");
    }
    if (orderCurrency(order) !== "BHD" || payment.currency !== "BHD") {
        throw benefitPaymentError("BENEFIT_CURRENCY_MISMATCH", 409, "BENEFIT currency does not match.");
    }
    if (notification.currency && !["048", "BHD"].includes(notification.currency)) {
        throw benefitPaymentError("BENEFIT_CURRENCY_MISMATCH", 409, "BENEFIT currency does not match.");
    }
    const expectedAmount = bhdFils(payment.amount);
    const orderAmount = bhdFils(numericOrderTotal(order));
    const receivedAmount = bhdFils(notification.amount);
    if (expectedAmount === null
        || orderAmount === null
        || receivedAmount === null
        || expectedAmount !== orderAmount
        || receivedAmount !== expectedAmount) {
        throw benefitPaymentError("BENEFIT_AMOUNT_MISMATCH", 409, "BENEFIT amount does not match.");
    }
    if (payment.paymentID
        && notification.paymentID
        && !timingSafeStringEqual(payment.paymentID, notification.paymentID)) {
        throw benefitPaymentError("BENEFIT_PAYMENT_ID_MISMATCH", 409, "BENEFIT payment ID does not match.");
    }
    if (payment.transactionID
        && notification.transactionID
        && !timingSafeStringEqual(payment.transactionID, notification.transactionID)) {
        throw benefitPaymentError("BENEFIT_TRANSACTION_ID_MISMATCH", 409, "BENEFIT transaction ID does not match.");
    }
    if (notification.result === "CAPTURED") {
        if (!notification.resultToken
            || !notification.paymentID
            || !notification.transactionID
            || notification.authResponseCode !== "00") {
            throw benefitPaymentError("BENEFIT_CAPTURE_INVALID", 409, "BENEFIT capture response is incomplete.");
        }
    }
    return true;
}

async function recordBenefitNotification(payment, notification, notificationHash) {
    const notificationReceivedAt = new Date().toISOString();
    const status = benefitNotificationStatus(notification);
    if (database.isEnabled()) {
        const result = await database.query(
            `UPDATE benefit_payments
             SET status = CASE WHEN effects_applied_at IS NOT NULL THEN status ELSE $2 END,
                 payment_id = COALESCE(payment_id, NULLIF($3, '')),
                 transaction_id = COALESCE(transaction_id, NULLIF($4, '')),
                 reference_id = COALESCE(NULLIF($5, ''), reference_id),
                 gateway_result = NULLIF($6, ''),
                 auth_code = NULLIF($7, ''),
                 auth_response_code = NULLIF($8, ''),
                 error_code = NULLIF($9, ''),
                 error_text = NULLIF($10, ''),
                 notification_hash = $11,
                 notification_received_at = $12,
                 updated_at = $12
             WHERE track_id = $1
             RETURNING *`,
            [
                payment.trackID,
                status,
                notification.paymentID,
                notification.transactionID,
                notification.referenceID,
                notification.result,
                notification.authCode,
                notification.authResponseCode,
                notification.errorCode,
                notification.errorText,
                notificationHash,
                notificationReceivedAt
            ]
        );
        return result.rowCount > 0 ? benefitPaymentRowToRecord(result.rows[0]) : null;
    }
    const store = readJSON(benefitPaymentsStorePath);
    const stored = store.payments?.[payment.trackID];
    if (!stored) {
        return null;
    }
    Object.assign(stored, {
        status: stored.effectsAppliedAt ? stored.status : status,
        paymentID: stored.paymentID || notification.paymentID || null,
        transactionID: stored.transactionID || notification.transactionID || null,
        referenceID: notification.referenceID || stored.referenceID || null,
        gatewayResult: notification.result || null,
        authCode: notification.authCode || null,
        authResponseCode: notification.authResponseCode || null,
        errorCode: notification.errorCode || null,
        errorText: notification.errorText || null,
        notificationHash,
        notificationReceivedAt,
        updatedAt: notificationReceivedAt
    });
    writeJSON(benefitPaymentsStorePath, store);
    return stored;
}

async function awardOrderBeansWithClient(client, order) {
    const points = orderBeansFor(order);
    if (points <= 0) {
        return { awarded: false, points: 0, reason: "NO_POINTS" };
    }
    const accountResult = await client.query(
        `SELECT points_balance
         FROM loyalty_accounts
         WHERE email = $1
         FOR UPDATE`,
        [order.email]
    );
    if (accountResult.rowCount === 0) {
        return { awarded: false, points, reason: "LOYALTY_ACCOUNT_NOT_FOUND" };
    }
    const transactionID = loyaltyTransactionIDForOrder(order);
    const transactionResult = await client.query(
        `INSERT INTO loyalty_transactions
         (id, email, type, points, note, voucher_code, voucher_detail, voucher_expires_at, voucher_single_use, voucher_status, created_at)
         VALUES ($1, $2, 'earn', $3, $4, NULL, NULL, NULL, NULL, NULL, $5)
         ON CONFLICT (id) DO NOTHING
         RETURNING id`,
        [
            transactionID,
            order.email,
            points,
            `Completed order ${order.title} • ${points} Beans • ${order.total}`,
            new Date().toISOString()
        ]
    );
    if (transactionResult.rowCount === 0) {
        return { awarded: false, points, reason: "ALREADY_AWARDED" };
    }
    const nextPointsBalance = Number(accountResult.rows[0].points_balance || 0) + points;
    await client.query(
        `UPDATE loyalty_accounts
         SET points_balance = $2, tier = $3, next_reward = $4, perks = $5::jsonb
         WHERE email = $1`,
        [
            order.email,
            nextPointsBalance,
            tierFor(nextPointsBalance),
            nextRewardText(nextPointsBalance),
            JSON.stringify(loyaltyPerksFor(nextPointsBalance))
        ]
    );
    return { awarded: true, points };
}

async function applyBenefitNotification(trackID, notification) {
    const payment = await findBenefitPaymentByTrackID(trackID);
    const order = payment ? await findOrderByID(payment.orderID) : null;
    verifyBenefitNotification(payment, order, notification);
    const isCaptured = notification.result === "CAPTURED";
    const processedAt = new Date().toISOString();

    if (database.isEnabled()) {
        const client = await database.connect();
        try {
            await client.query("BEGIN");
            const paymentResult = await client.query(
                `SELECT *
                 FROM benefit_payments
                 WHERE track_id = $1
                 FOR UPDATE`,
                [trackID]
            );
            if (paymentResult.rowCount === 0) {
                throw benefitPaymentError("BENEFIT_PAYMENT_NOT_FOUND", 404, "BENEFIT payment was not found.");
            }
            const lockedPayment = benefitPaymentRowToRecord(paymentResult.rows[0]);
            const orderResult = await client.query(
                `SELECT id, email, title, total, status, items, created_at
                 FROM orders
                 WHERE id = $1
                 FOR UPDATE`,
                [lockedPayment.orderID]
            );
            if (orderResult.rowCount === 0) {
                throw benefitPaymentError("BENEFIT_ORDER_NOT_FOUND", 404, "BENEFIT order was not found.");
            }
            const lockedOrder = {
                ...orderRowToRecord(orderResult.rows[0]),
                email: normalizeEmail(orderResult.rows[0].email)
            };
            verifyBenefitNotification(lockedPayment, lockedOrder, notification);
            const alreadyApplied = Boolean(lockedPayment.effectsAppliedAt);
            let award = { awarded: false, points: 0, reason: isCaptured ? "ALREADY_APPLIED" : "PAYMENT_NOT_CAPTURED" };

            if (isCaptured && !alreadyApplied) {
                const updatedOrderResult = await client.query(
                    `UPDATE orders
                     SET status = CASE
                            WHEN status IN ('Completed', 'Fulfilled', 'Delivered') THEN status
                            ELSE 'Completed'
                         END
                     WHERE id = $1
                     RETURNING id, email, title, total, status, items, created_at`,
                    [lockedOrder.id]
                );
                const completedOrder = {
                    ...orderRowToRecord(updatedOrderResult.rows[0]),
                    email: normalizeEmail(updatedOrderResult.rows[0].email)
                };
                award = await awardOrderBeansWithClient(client, completedOrder);
                await client.query(
                    `UPDATE benefit_payments
                     SET status = 'Captured', processed_at = $2, effects_applied_at = $2, updated_at = $2
                     WHERE track_id = $1`,
                    [trackID, processedAt]
                );
            } else if (!isCaptured) {
                await client.query(
                    `UPDATE benefit_payments
                     SET status = $2, processed_at = $3, updated_at = $3
                     WHERE track_id = $1`,
                    [trackID, benefitNotificationStatus(notification), processedAt]
                );
            }

            await client.query("COMMIT");
            if (isCaptured) queueShopifyOrderExport(lockedOrder.id);
            return { applied: isCaptured && !alreadyApplied, award };
        } catch (error) {
            await client.query("ROLLBACK");
            throw error;
        } finally {
            client.release();
        }
    }

    const store = readJSON(benefitPaymentsStorePath);
    const storedPayment = store.payments?.[trackID];
    if (!storedPayment) {
        throw benefitPaymentError("BENEFIT_PAYMENT_NOT_FOUND", 404, "BENEFIT payment was not found.");
    }
    const alreadyApplied = Boolean(storedPayment.effectsAppliedAt);
    let award = { awarded: false, points: 0, reason: isCaptured ? "ALREADY_APPLIED" : "PAYMENT_NOT_CAPTURED" };
    if (isCaptured && !alreadyApplied) {
        const ordersStore = readJSON(ordersStorePath);
        const orders = Array.isArray(ordersStore.orders[payment.email]) ? ordersStore.orders[payment.email] : [];
        const index = orders.findIndex((entry) => entry.id === payment.orderID);
        if (index === -1) {
            throw benefitPaymentError("BENEFIT_ORDER_NOT_FOUND", 404, "BENEFIT order was not found.");
        }
        orders[index] = {
            ...orders[index],
            status: completedOrderStatuses().has(orders[index].status) ? orders[index].status : "Completed"
        };
        ordersStore.orders[payment.email] = orders;
        writeJSON(ordersStorePath, ordersStore);
        award = await awardOrderBeans({
            ...orders[index],
            email: payment.email
        });
        storedPayment.status = "Captured";
        storedPayment.effectsAppliedAt = processedAt;
    } else if (!isCaptured) {
        storedPayment.status = benefitNotificationStatus(notification);
    } else {
        const repairedOrder = await findOrderByID(payment.orderID);
        if (repairedOrder) {
            award = await awardOrderBeans(repairedOrder);
        }
    }
    storedPayment.processedAt = processedAt;
    storedPayment.updatedAt = processedAt;
    writeJSON(benefitPaymentsStorePath, store);
    if (isCaptured) queueShopifyOrderExport(payment.orderID);
    return { applied: isCaptured && !alreadyApplied, award };
}

async function withBenefitPaymentLock(trackID, operation) {
    const existing = benefitPaymentLocks.get(trackID);
    if (existing) {
        const result = await existing;
        return {
            ...result,
            applied: false,
            award: {
                ...result.award,
                awarded: false,
                reason: "ALREADY_APPLIED"
            }
        };
    }
    const pending = Promise.resolve().then(operation);
    benefitPaymentLocks.set(trackID, pending);
    try {
        return await pending;
    } finally {
        if (benefitPaymentLocks.get(trackID) === pending) {
            benefitPaymentLocks.delete(trackID);
        }
    }
}

function benefitResultState(payment) {
    if (payment?.status === "Captured" && payment.effectsAppliedAt) {
        return "success";
    }
    if (["Declined", "Canceled", "DeniedByRisk", "GatewayError", "HostTimeout", "InitiationFailed"].includes(payment?.status)) {
        return "failure";
    }
    return "pending";
}

function renderBenefitResultPage(payment) {
    const state = benefitResultState(payment);
    const content = {
        success: {
            title: "Payment confirmed",
            detail: "Your BENEFIT payment was confirmed. You can return to Talla and view your order.",
            accent: "#23603f"
        },
        pending: {
            title: "Payment pending",
            detail: "Your payment is still being confirmed. Return to Talla and check your order again shortly.",
            accent: "#8a5a13"
        },
        failure: {
            title: "Payment not completed",
            detail: "The payment was not completed. No order was marked paid.",
            accent: "#8b2f2f"
        }
    }[state];
    return `<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${escapeHTML(content.title)}</title>
    <style>
        :root { color-scheme: light; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
        body { margin: 0; background: #f7f3ea; color: #231f1a; display: grid; min-height: 100vh; place-items: center; }
        main { box-sizing: border-box; width: min(92vw, 28rem); padding: 2rem; border-radius: 1.25rem; background: #fffdf8; box-shadow: 0 1rem 3rem rgba(52, 39, 24, .12); text-align: center; }
        h1 { color: ${content.accent}; font-size: 1.65rem; margin: 0 0 .75rem; }
        p { line-height: 1.55; margin: 0 0 1.5rem; }
        a { display: inline-block; border-radius: 999px; padding: .8rem 1.2rem; background: #231f1a; color: white; font-weight: 650; text-decoration: none; }
    </style>
</head>
<body>
    <main>
        <h1>${escapeHTML(content.title)}</h1>
        <p>${escapeHTML(content.detail)}</p>
        <a href="talla://checkout-return">Return to Talla</a>
    </main>
</body>
</html>`;
}

function benefitResultPageHeaders() {
    return {
        "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'",
        "Referrer-Policy": "no-referrer",
        "X-Content-Type-Options": "nosniff",
        "Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
        Pragma: "no-cache",
        Expires: "0"
    };
}

async function findBenefitPaymentForBrowserReturn(url) {
    const parameters = new URLSearchParams(url.searchParams);
    let decodedPathname = String(url.pathname || "");
    try {
        decodedPathname = decodeURIComponent(decodedPathname);
    } catch {
    }
    const embeddedQueryIndex = decodedPathname.indexOf("?");
    if (embeddedQueryIndex >= 0) {
        const embeddedParameters = new URLSearchParams(
            decodedPathname.slice(embeddedQueryIndex + 1).replace(/&amp;/gi, "&")
        );
        for (const [key, value] of embeddedParameters) {
            if (!parameters.has(key)) parameters.set(key, value);
        }
    }
    const rawReturnURL = `${decodedPathname}${url.search || ""}`.replace(/&amp;/gi, "&");
    const embeddedTokenMatch = rawReturnURL.match(
        /(?:^|[?&/])(?:payment|udf2)(?:=|%3D)([A-Za-z0-9_-]{16,255})/i
    );
    const resultToken = parameters.get("payment")
        || parameters.get("udf2")
        || embeddedTokenMatch?.[1]
        || "";
    const trackID = normalizeBenefitIdentifier(
        parameters.get("trackid")
        || parameters.get("trackId")
        || parameters.get("trackID")
    );
    let payment = await findBenefitPaymentByResultToken(resultToken);
    if (!payment && trackID) {
        payment = await findBenefitPaymentByTrackID(trackID);
    }
    return payment;
}

function parseBenefitCallbackRequest(rawBody, contentType = "") {
    const text = rawBody.toString("utf8");
    if (!text) {
        throw benefitPaymentError("BENEFIT_CALLBACK_EMPTY", 400, "BENEFIT callback is empty.");
    }
    if (String(contentType).toLowerCase().includes("application/json")) {
        const parsed = JSON.parse(text);
        if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
            throw benefitPaymentError("BENEFIT_CALLBACK_INVALID", 400, "BENEFIT callback is invalid.");
        }
        return parsed;
    }
    return Object.fromEntries(new URLSearchParams(text).entries());
}

function sendBenefitRedirectAcknowledgement(response, redirectURL) {
    response.writeHead(200, {
        "Content-Type": "text/plain; charset=utf-8",
        "Cache-Control": "no-store",
        "Referrer-Policy": "no-referrer",
        "X-Content-Type-Options": "nosniff"
    });
    response.end(`REDIRECT=${redirectURL}`);
}

function validateBenefitHostedPaymentURL(value) {
    const hostedURL = safeConfiguredBenefitURL(value, "BENEFIT hosted payment URL");
    const endpointURL = safeConfiguredBenefitURL(benefitAPIEndpoint, "BENEFIT API endpoint");
    const matchesEndpointHost = hostedURL.hostname === endpointURL.hostname;
    const isBenefitGatewayHost = hostedURL.hostname === "benefit-gateway.bh"
        || hostedURL.hostname.endsWith(".benefit-gateway.bh");
    if (!matchesEndpointHost && !isBenefitGatewayHost) {
        throw benefitPaymentError("BENEFIT_INVALID_PAYMENT_URL", 502, "BENEFIT returned an invalid payment URL.");
    }
    return hostedURL.toString();
}

function normalizeTallaPaymentID(value) {
    const normalized = String(value || "").trim().toUpperCase();
    return /^TL-[A-Z0-9]{12,40}$/.test(normalized) ? normalized : "";
}

function shopifyEazyPaymentRowToRecord(row) {
    if (!row) return null;
    return {
        tallaPaymentId: row.talla_payment_id,
        email: normalizeEmail(row.email),
        shopifyOrderId: row.shopify_order_id || null,
        shopifyOrderGid: row.shopify_order_gid || null,
        shopifyOrderName: row.shopify_order_name || null,
        amount: row.amount || null,
        currency: row.currency || null,
        paymentGateway: row.payment_gateway || null,
        orderItems: Array.isArray(row.order_items) ? row.order_items : [],
        eazyInvoiceId: row.eazy_invoice_id || null,
        eazyGlobalTransactionId: row.eazy_global_transaction_id || null,
        eazyTransactionId: row.eazy_transaction_id || null,
        eazyPaymentUrl: row.eazy_payment_url || null,
        eazyPaymentMethod: row.eazy_payment_method || null,
        status: row.status,
        failureCode: row.failure_code || null,
        failureMessage: row.failure_message || null,
        createdAt: new Date(row.created_at).toISOString(),
        updatedAt: new Date(row.updated_at).toISOString(),
        eazyConfirmedAt: row.eazy_confirmed_at ? new Date(row.eazy_confirmed_at).toISOString() : null,
        paidAt: row.paid_at ? new Date(row.paid_at).toISOString() : null,
        effectsAppliedAt: row.effects_applied_at ? new Date(row.effects_applied_at).toISOString() : null
    };
}

async function findShopifyEazyPayment(tallaPaymentId) {
    const normalizedID = normalizeTallaPaymentID(tallaPaymentId);
    if (!normalizedID) return null;
    if (database.isEnabled()) {
        const result = await database.query(
            "SELECT * FROM shopify_eazy_payments WHERE talla_payment_id = $1 LIMIT 1",
            [normalizedID]
        );
        return shopifyEazyPaymentRowToRecord(result.rows[0]);
    }
    return readJSON(shopifyEazyPaymentsStorePath).payments?.[normalizedID] || null;
}

async function findShopifyEazyPaymentByGlobalTransactionID(globalTransactionId) {
    const normalizedID = eazyPay.normalizeIdentifier(globalTransactionId);
    if (!normalizedID) return null;
    if (database.isEnabled()) {
        const result = await database.query(
            "SELECT * FROM shopify_eazy_payments WHERE eazy_global_transaction_id = $1 LIMIT 1",
            [normalizedID]
        );
        return shopifyEazyPaymentRowToRecord(result.rows[0]);
    }
    return Object.values(readJSON(shopifyEazyPaymentsStorePath).payments || {})
        .find((payment) => payment.eazyGlobalTransactionId === normalizedID) || null;
}

async function persistShopifyEazyPayment(payment) {
    const now = new Date().toISOString();
    const record = {
        tallaPaymentId: normalizeTallaPaymentID(payment.tallaPaymentId),
        email: normalizeEmail(payment.email),
        shopifyOrderId: payment.shopifyOrderId || null,
        shopifyOrderGid: payment.shopifyOrderGid || null,
        shopifyOrderName: payment.shopifyOrderName || null,
        amount: payment.amount || null,
        currency: payment.currency || null,
        paymentGateway: payment.paymentGateway || null,
        orderItems: Array.isArray(payment.orderItems) ? payment.orderItems : [],
        eazyInvoiceId: payment.eazyInvoiceId || null,
        eazyGlobalTransactionId: payment.eazyGlobalTransactionId || null,
        eazyTransactionId: payment.eazyTransactionId || null,
        eazyPaymentUrl: payment.eazyPaymentUrl || null,
        eazyPaymentMethod: payment.eazyPaymentMethod || null,
        status: payment.status || "CREATED",
        failureCode: payment.failureCode || null,
        failureMessage: payment.failureMessage || null,
        createdAt: payment.createdAt || now,
        updatedAt: now,
        eazyConfirmedAt: payment.eazyConfirmedAt || null,
        paidAt: payment.paidAt || null,
        effectsAppliedAt: payment.effectsAppliedAt || null
    };
    if (!record.tallaPaymentId || !record.email) {
        throw new Error("INVALID_SHOPIFY_EAZY_PAYMENT");
    }
    if (database.isEnabled()) {
        const result = await database.query(
            `INSERT INTO shopify_eazy_payments
             (talla_payment_id, email, shopify_order_id, shopify_order_gid, shopify_order_name,
              amount, currency, payment_gateway, order_items, eazy_invoice_id,
              eazy_global_transaction_id, eazy_transaction_id, eazy_payment_url,
              eazy_payment_method, status, failure_code, failure_message, created_at, updated_at,
              eazy_confirmed_at, paid_at, effects_applied_at)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9::jsonb,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22)
             ON CONFLICT (talla_payment_id) DO UPDATE SET
              email = EXCLUDED.email, shopify_order_id = EXCLUDED.shopify_order_id,
              shopify_order_gid = EXCLUDED.shopify_order_gid, shopify_order_name = EXCLUDED.shopify_order_name,
              amount = EXCLUDED.amount, currency = EXCLUDED.currency, payment_gateway = EXCLUDED.payment_gateway,
              order_items = EXCLUDED.order_items, eazy_invoice_id = EXCLUDED.eazy_invoice_id,
              eazy_global_transaction_id = EXCLUDED.eazy_global_transaction_id,
              eazy_transaction_id = EXCLUDED.eazy_transaction_id, eazy_payment_url = EXCLUDED.eazy_payment_url,
              eazy_payment_method = EXCLUDED.eazy_payment_method, status = EXCLUDED.status,
              failure_code = EXCLUDED.failure_code, failure_message = EXCLUDED.failure_message,
              updated_at = EXCLUDED.updated_at, eazy_confirmed_at = EXCLUDED.eazy_confirmed_at,
              paid_at = EXCLUDED.paid_at, effects_applied_at = EXCLUDED.effects_applied_at
             RETURNING *`,
            [record.tallaPaymentId, record.email, record.shopifyOrderId, record.shopifyOrderGid,
                record.shopifyOrderName, record.amount, record.currency, record.paymentGateway,
                JSON.stringify(record.orderItems), record.eazyInvoiceId, record.eazyGlobalTransactionId,
                record.eazyTransactionId, record.eazyPaymentUrl, record.eazyPaymentMethod, record.status,
                record.failureCode, record.failureMessage, record.createdAt, record.updatedAt,
                record.eazyConfirmedAt, record.paidAt, record.effectsAppliedAt]
        );
        return shopifyEazyPaymentRowToRecord(result.rows[0]);
    }
    const store = readJSON(shopifyEazyPaymentsStorePath);
    store.payments ||= {};
    store.payments[record.tallaPaymentId] = record;
    writeJSON(shopifyEazyPaymentsStorePath, store);
    return record;
}

async function withShopifyEazyPaymentLock(tallaPaymentId, operation) {
    const key = normalizeTallaPaymentID(tallaPaymentId);
    const existing = shopifyEazyPaymentLocks.get(key);
    if (existing) return existing;
    const pending = Promise.resolve().then(operation);
    shopifyEazyPaymentLocks.set(key, pending);
    try {
        return await pending;
    } finally {
        if (shopifyEazyPaymentLocks.get(key) === pending) shopifyEazyPaymentLocks.delete(key);
    }
}

function shopifyOrderTallaPaymentID(shopifyOrder) {
    const attributes = Array.isArray(shopifyOrder.note_attributes) ? shopifyOrder.note_attributes : [];
    const attribute = attributes.find((entry) => String(entry?.name || entry?.key || "").toLowerCase() === "talla_payment_id");
    return normalizeTallaPaymentID(attribute?.value);
}

function shopifyOrderPaymentGateways(shopifyOrder) {
    const values = [shopifyOrder.gateway, ...(Array.isArray(shopifyOrder.payment_gateway_names) ? shopifyOrder.payment_gateway_names : [])];
    return values.map((value) => String(value || "").trim()).filter(Boolean);
}

function isEazyPayManualShopifyOrder(shopifyOrder) {
    return shopifyOrderPaymentGateways(shopifyOrder).some((gateway) => gateway.toLowerCase() === "pay with eazypay");
}

async function prepareShopifyEazyOrder(shopifyOrder) {
    if (!isEazyPayManualShopifyOrder(shopifyOrder)) return null;
    const tallaPaymentId = shopifyOrderTallaPaymentID(shopifyOrder);
    if (!tallaPaymentId) {
        console.warn(`[SHOPIFY_ORDER_CREATED] missing talla_payment_id order=${String(shopifyOrder.name || shopifyOrder.id || "unknown")}`);
        return null;
    }
    return withShopifyEazyPaymentLock(tallaPaymentId, async () => {
        const existing = await findShopifyEazyPayment(tallaPaymentId);
        const email = normalizeEmail(shopifyOrder.email || shopifyOrder.contact_email || shopifyOrder.customer?.email || existing?.email);
        if (!email) return null;
        if (existing && existing.email !== email) {
            console.error(`[SHOPIFY_ORDER_CREATED] ownership mismatch payment=${tallaPaymentId}`);
            return null;
        }
        const amountNumber = Number(shopifyOrder.current_total_price || shopifyOrder.total_price);
        const currency = String(shopifyOrder.currency || "").trim().toUpperCase();
        const cancelled = Boolean(shopifyOrder.cancelled_at || shopifyOrder.cancel_reason);
        const payment = await persistShopifyEazyPayment({
            ...(existing || {}),
            tallaPaymentId,
            email,
            shopifyOrderId: String(shopifyOrder.id || ""),
            shopifyOrderGid: String(shopifyOrder.admin_graphql_api_id || (shopifyOrder.id ? `gid://shopify/Order/${shopifyOrder.id}` : "")),
            shopifyOrderName: String(shopifyOrder.name || shopifyOrder.order_number || ""),
            amount: Number.isFinite(amountNumber) && amountNumber > 0 ? amountNumber.toFixed(3) : null,
            currency,
            paymentGateway: "Pay with EazyPay",
            orderItems: Array.isArray(shopifyOrder.line_items) ? shopifyOrder.line_items.map((item) => ({ name: String(item.name || item.title || "Item"), quantity: Number(item.quantity || 1) })) : [],
            status: existing?.status === "PAID" ? "PAID" : (cancelled ? "CANCELLED" : (existing?.eazyPaymentUrl ? existing.status : "WAITING_FOR_EAZYPAY"))
        });
        console.info(`[SHOPIFY_ORDER_CREATED] order=${payment.shopifyOrderName || payment.shopifyOrderId} payment=${tallaPaymentId} status=${payment.status}`);
        return payment;
    });
}

async function ensureShopifyEazyInvoice(tallaPaymentId, options = {}) {
    return withShopifyEazyPaymentLock(tallaPaymentId, async () => {
        const payment = await findShopifyEazyPayment(tallaPaymentId);
        if (!payment) throw eazyPay.paymentError("EAZY_PAYMENT_NOT_FOUND", 404, "Payment was not found.");
        if (payment.eazyPaymentUrl || payment.status === "PAID" || payment.status === "CANCELLED") return payment;
        if (!payment.shopifyOrderId || !payment.amount || payment.currency !== "BHD") return payment;
        try {
            const invoice = await eazyPay.createInvoice({ invoiceId: payment.tallaPaymentId, amount: payment.amount, currency: payment.currency }, eazyConfiguration, options);
            const updated = await persistShopifyEazyPayment({
                ...payment,
                eazyInvoiceId: invoice.invoiceId,
                eazyGlobalTransactionId: invoice.globalTransactionsId,
                eazyPaymentUrl: invoice.paymentUrl,
                status: "PAYMENT_PENDING",
                failureCode: null,
                failureMessage: null
            });
            console.info(`[EAZYPAY_INVOICE_CREATED] order=${updated.shopifyOrderName || updated.shopifyOrderId} payment=${updated.tallaPaymentId} transaction=${updated.eazyGlobalTransactionId}`);
            return updated;
        } catch (error) {
            await persistShopifyEazyPayment({ ...payment, status: "FAILED", failureCode: error.code || "EAZY_CREATE_FAILED", failureMessage: "Payment setup is temporarily unavailable." });
            console.error(`[PAYMENT_FAILED] payment=${payment.tallaPaymentId} stage=invoice code=${error.code || "EAZY_CREATE_FAILED"}`);
            throw error;
        }
    });
}

function verifyEazyTransactionForShopifyPayment(transaction, payment) {
    if (!payment || transaction.invoiceId !== payment.tallaPaymentId) throw eazyPay.paymentError("EAZY_INVOICE_MISMATCH", 409, "EazyPay invoice mismatch.");
    if (transaction.currency !== "BHD" || payment.currency !== "BHD") throw eazyPay.paymentError("EAZY_CURRENCY_MISMATCH", 409, "EazyPay currency mismatch.");
    const expected = bhdFils(payment.amount);
    const received = bhdFils(transaction.amount);
    if (expected === null || received === null || expected !== received) throw eazyPay.paymentError("EAZY_AMOUNT_MISMATCH", 409, "EazyPay amount mismatch.");
    if (payment.eazyGlobalTransactionId && payment.eazyGlobalTransactionId !== transaction.globalTransactionsId) throw eazyPay.paymentError("EAZY_TRANSACTION_MISMATCH", 409, "EazyPay transaction mismatch.");
    if (transaction.isPaid === 1 && !transaction.transactionsId) throw eazyPay.paymentError("EAZY_QUERY_INVALID_RESPONSE", 502, "EazyPay returned an invalid paid transaction.");
    return true;
}

async function markShopifyOrderAsPaid(payment) {
    const orderGid = payment.shopifyOrderGid || (payment.shopifyOrderId ? `gid://shopify/Order/${payment.shopifyOrderId}` : "");
    if (!orderGid) throw new Error("SHOPIFY_ORDER_ID_MISSING");
    const data = await shopifyAdminGraphQLRequest(
        `mutation OrderMarkAsPaid($input: OrderMarkAsPaidInput!) {
            orderMarkAsPaid(input: $input) {
                order { id name displayFinancialStatus }
                userErrors { field message }
            }
        }`,
        { input: { id: orderGid } }
    );
    const payload = data.orderMarkAsPaid || {};
    assertShopifyUserErrors(payload.userErrors);
    const status = String(payload.order?.displayFinancialStatus || "").toUpperCase();
    if (!payload.order?.id || !["PAID", "PARTIALLY_PAID"].includes(status)) throw new Error("SHOPIFY_MARK_PAID_UNCONFIRMED");
    return payload.order;
}

async function applyShopifyEazyLocalEffects(payment) {
    if (payment.effectsAppliedAt) return payment;
    const syntheticOrder = {
        id: payment.shopifyOrderId,
        admin_graphql_api_id: payment.shopifyOrderGid,
        name: payment.shopifyOrderName,
        email: payment.email,
        total_price: payment.amount,
        currency: payment.currency,
        financial_status: "paid",
        line_items: payment.orderItems,
        created_at: payment.createdAt
    };
    await processShopifyOrderWebhook(syntheticOrder, "orders/paid");
    return persistShopifyEazyPayment({ ...payment, effectsAppliedAt: new Date().toISOString() });
}

async function finalizeVerifiedShopifyEazyPayment(payment, transaction) {
    verifyEazyTransactionForShopifyPayment(transaction, payment);
    if (transaction.isPaid !== 1) return payment;
    const confirmedAt = transaction.paidOn || new Date().toISOString();
    let current = await persistShopifyEazyPayment({
        ...payment,
        eazyTransactionId: transaction.transactionsId,
        eazyPaymentMethod: transaction.paymentMethod,
        eazyConfirmedAt: confirmedAt,
        status: "SHOPIFY_MARK_PENDING",
        failureCode: null,
        failureMessage: null
    });
    console.info(`[EAZYPAY_PAYMENT_VERIFIED] order=${current.shopifyOrderName || current.shopifyOrderId} payment=${current.tallaPaymentId} transaction=${current.eazyTransactionId}`);
    try {
        const shopifyOrder = await markShopifyOrderAsPaid(current);
        current = await persistShopifyEazyPayment({ ...current, status: "PAID", paidAt: confirmedAt, failureCode: null, failureMessage: null });
        current = await applyShopifyEazyLocalEffects(current);
        console.info(`[SHOPIFY_MARK_PAID] order=${shopifyOrder.name || current.shopifyOrderName} payment=${current.tallaPaymentId}`);
        console.info(`[PAYMENT_COMPLETED] order=${current.shopifyOrderName || current.shopifyOrderId} payment=${current.tallaPaymentId}`);
        return current;
    } catch (error) {
        current = await persistShopifyEazyPayment({ ...current, status: "SHOPIFY_MARK_PENDING", failureCode: "SHOPIFY_MARK_PAID_FAILED", failureMessage: "Payment is confirmed and Shopify synchronization is pending." });
        console.error(`[PAYMENT_FAILED] payment=${current.tallaPaymentId} stage=shopify_mark_paid code=${error.message || "SHOPIFY_MARK_PAID_FAILED"}`);
        return current;
    }
}

async function confirmShopifyEazyPayment(tallaPaymentId, options = {}) {
    return withShopifyEazyPaymentLock(tallaPaymentId, async () => {
        let payment = await findShopifyEazyPayment(tallaPaymentId);
        if (!payment) throw eazyPay.paymentError("EAZY_PAYMENT_NOT_FOUND", 404, "Payment was not found.");
        if (payment.status === "PAID") return payment;
        if (payment.status === "SHOPIFY_MARK_PENDING" && payment.eazyConfirmedAt) {
            try {
                const shopifyOrder = await markShopifyOrderAsPaid(payment);
                payment = await persistShopifyEazyPayment({ ...payment, status: "PAID", paidAt: payment.eazyConfirmedAt, failureCode: null, failureMessage: null });
                payment = await applyShopifyEazyLocalEffects(payment);
                console.info(`[SHOPIFY_MARK_PAID] order=${shopifyOrder.name || payment.shopifyOrderName} payment=${payment.tallaPaymentId}`);
            } catch (error) {
                console.error(`[PAYMENT_FAILED] payment=${payment.tallaPaymentId} stage=shopify_retry code=${error.message || "SHOPIFY_MARK_PAID_FAILED"}`);
            }
            return payment;
        }
        if (!payment.eazyGlobalTransactionId) return payment;
        const transaction = await eazyPay.queryTransaction(payment.eazyGlobalTransactionId, eazyConfiguration, options);
        return finalizeVerifiedShopifyEazyPayment(payment, transaction);
    });
}

function publicShopifyEazyPayment(payment) {
    return {
        success: true,
        tallaPaymentId: payment.tallaPaymentId,
        shopifyOrderName: payment.shopifyOrderName,
        status: payment.status,
        paymentUrl: payment.eazyPaymentUrl,
        paid: payment.status === "PAID",
        pending: ["CREATED", "WAITING_FOR_EAZYPAY", "PAYMENT_PENDING", "SHOPIFY_MARK_PENDING"].includes(payment.status),
        message: payment.failureMessage || null
    };
}

async function processShopifyOrderWebhook(shopifyOrder, topic = "") {
    const eazyPayment = await prepareShopifyEazyOrder(shopifyOrder);
    const order = shopifyOrderRecord(shopifyOrder, topic);
    if (!order.email) {
        return { recorded: false, awarded: false, reason: "ORDER_EMAIL_MISSING", eazyTallaPaymentId: eazyPayment?.tallaPaymentId || null };
    }

    const recordedOrder = await upsertOrderRecord(order);
    if (!recordedOrder) {
        return { recorded: false, awarded: false, reason: "CUSTOMER_ACCOUNT_NOT_FOUND", email: order.email, eazyTallaPaymentId: eazyPayment?.tallaPaymentId || null };
    }

    const award = await awardOrderBeans(order);
    const rewardAwareOrder = await orderPayloadWithRewardState(order.email, recordedOrder);
    return {
        recorded: true,
        order: rewardAwareOrder,
        award,
        eazyTallaPaymentId: eazyPayment?.tallaPaymentId || null
    };
}

async function syncRecentShopifyOrdersForEmail(email) {
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail || !shopifyAdminConfigured()) {
        return { configured: shopifyAdminConfigured(), syncedCount: 0 };
    }

    const data = await shopifyAdminGraphQLRequest(
        `query CustomerOrders($query: String!) {
            orders(first: 20, query: $query, sortKey: CREATED_AT, reverse: true) {
                edges {
                    node {
                        id
                        legacyResourceId
                        name
                        email
                        createdAt
                        cancelledAt
                        displayFinancialStatus
                        displayFulfillmentStatus
                        currentTotalPriceSet {
                            shopMoney {
                                amount
                                currencyCode
                            }
                        }
                        totalPriceSet {
                            shopMoney {
                                amount
                                currencyCode
                            }
                        }
                        lineItems(first: 30) {
                            edges {
                                node {
                                    name
                                    title
                                    quantity
                                }
                            }
                        }
                    }
                }
            }
        }`,
        { query: `email:${normalizedEmail}` }
    );

    const edges = data.orders?.edges || [];
    let syncedCount = 0;

    for (const { node } of edges) {
        const order = shopifyAdminOrderRecord(node, normalizedEmail);
        const recordedOrder = await upsertOrderRecord(order);
        if (!recordedOrder) {
            continue;
        }

        syncedCount += 1;
        if (completedOrderStatuses().has(order.status)) {
            await awardOrderBeans(order);
        }
    }

    return { configured: true, syncedCount };
}

async function updateOrderStatusRecord(email, orderID, status) {
    if (database.isEnabled()) {
        const result = await database.query(
            `UPDATE orders
             SET status = $3
             WHERE email = $1 AND id = $2
             RETURNING id, title, total, status, items, created_at`,
            [email, orderID, status]
        );

        if (result.rowCount === 0) {
            return null;
        }

        return orderRowToRecord(result.rows[0]);
    }

    const store = readJSON(ordersStorePath);
    const orders = store.orders[email] || [];
    const index = orders.findIndex((entry) => entry.id === orderID);
    if (index === -1) {
        return null;
    }

    orders[index] = {
        ...orders[index],
        status
    };
    store.orders[email] = orders;
    writeJSON(ordersStorePath, store);
    return orders[index];
}

async function updateOrderStatusAndAward(email, orderID, status) {
    const normalizedStatus = normalizeOrderStatus(status);
    if (!normalizedStatus) {
        return null;
    }

    const updatedOrder = await updateOrderStatusRecord(email, orderID, normalizedStatus);
    if (!updatedOrder) {
        return null;
    }

    const orderWithEmail = {
        ...updatedOrder,
        email
    };

    if (completedOrderStatuses().has(updatedOrder.status)) {
        await awardOrderBeans(orderWithEmail);
        queueShopifyOrderExport(orderID);
    }

    return {
        ...(await orderPayloadWithRewardState(email, updatedOrder)),
        email
    };
}

function rewardDetailsFor(reward) {
    const normalized = String(reward || "").trim().toLowerCase();
    const catalog = {
        "free drink": { detail: "One eligible drink of your choice, up to BHD 2.500", expiresInDays: 30 },
        "espresso pour": { detail: "Complimentary espresso or batch brew", expiresInDays: 30 },
        "pastry pairing": { detail: "One pastry on the house", expiresInDays: 21 },
        "signature sip": { detail: "One signature drink on the house", expiresInDays: 30 },
        "eid majlis reward": { detail: "Limited Eid reward for coffee, sweets, or gift boxes", expiresInDays: 14 },
        "coffee bag credit": { detail: "BHD 4.000 off one coffee bag", expiresInDays: 30 },
        "talla box treat": { detail: "Curated reward on a Talla Box", expiresInDays: 45 },
        "gold reserve gift": { detail: "Premium Gold-tier gift reward", expiresInDays: 60 }
    };

    return catalog[normalized] || { detail: reward || "Reward voucher", expiresInDays: 30 };
}

function escapeShellArgument(value) {
    return `'${String(value).replace(/'/g, `'\\''`)}'`;
}

function writeDecodedSecret(targetPath, base64Value) {
    fs.writeFileSync(targetPath, Buffer.from(base64Value, "base64"));
}

function exportWWDRCertificate(sourcePath, outputPath) {
    try {
        execFileSync("/usr/bin/openssl", ["x509", "-inform", "DER", "-in", sourcePath, "-out", outputPath]);
        return;
    } catch (derError) {
        execFileSync("/usr/bin/openssl", ["x509", "-inform", "PEM", "-in", sourcePath, "-out", outputPath]);
    }
}

function ensurePassSigningFiles() {
    if (!fs.existsSync(walletPassTemplateDirectory)) {
        throw new Error("Wallet pass template is missing");
    }

    if ((!walletPassCertificatePath || !fs.existsSync(walletPassCertificatePath)) && !walletPassCertificateBase64) {
        throw new Error("Wallet pass certificate is missing");
    }

    if (!walletPassCertificatePassword) {
        throw new Error("Wallet pass certificate password is missing");
    }

    if ((!walletPassWWDRPath || !fs.existsSync(walletPassWWDRPath)) && !walletPassWWDRBase64) {
        throw new Error("Wallet WWDR certificate is missing");
    }
}

async function generateWalletPass(email) {
    ensurePassSigningFiles();

    const account = await getAccountByEmail(email);
    const loyaltyAccount = await ensureLoyaltyAccount(email);

    if (!account) {
        throw new Error("Account not found");
    }

    const tempDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-wallet-"));
    const passDirectory = path.join(tempDirectory, "TallaLoyalty.pass");
    fs.cpSync(walletPassTemplateDirectory, passDirectory, { recursive: true });

    const passJSONPath = path.join(passDirectory, "pass.json");
    const passJSON = JSON.parse(fs.readFileSync(passJSONPath, "utf8"));
    const memberName = `${account.firstName} ${account.lastName}`.trim();
    const serialNumber = await ensureWalletPassRecord(
        email,
        loyaltyAccount.memberID,
        passJSON.passTypeIdentifier || null
    );

    passJSON.serialNumber = serialNumber;
    passJSON.barcode.message = loyaltyAccount.memberID;
    delete passJSON.barcode.altText;
    passJSON.storeCard.headerFields = [
        {
            key: "tier",
            label: "STATUS",
            value: loyaltyAccount.tier
        }
    ];
    passJSON.storeCard.primaryFields = [];
    passJSON.storeCard.secondaryFields = [
        {
            key: "member",
            label: "MEMBER",
            value: memberName || account.email
        }
    ];
    await writeWalletStampStrips({
        passDirectory,
        artworkDirectory: walletPassArtworkDirectory,
        pointsBalance: loyaltyAccount.pointsBalance
    });
    passJSON.storeCard.auxiliaryFields = [];
    passJSON.storeCard.backFields = [
        {
            key: "email",
            label: "MEMBER EMAIL",
            value: account.email
        },
        {
            key: "member_id",
            label: "ROASTERY ID",
            value: loyaltyAccount.memberID
        },
        {
            key: "next_reward",
            label: "NEXT REWARD",
            value: loyaltyAccount.nextReward
        },
        {
            key: "support",
            label: "WHATSAPP CONCIERGE",
            value: "+973 3939 2414"
        },
        {
            key: "site",
            label: "VISIT TALLA",
            value: "https://talla.me"
        }
    ];

    fs.writeFileSync(passJSONPath, JSON.stringify(passJSON, null, 2));

    const files = fs.readdirSync(passDirectory)
        .filter((fileName) => {
            const fullPath = path.join(passDirectory, fileName);
            return fs.statSync(fullPath).isFile() && fileName !== "manifest.json" && fileName !== "signature";
        })
        .sort();

    const manifest = {};
    for (const fileName of files) {
        const fileContents = fs.readFileSync(path.join(passDirectory, fileName));
        manifest[fileName] = crypto.createHash("sha1").update(fileContents).digest("hex");
    }
    fs.writeFileSync(path.join(passDirectory, "manifest.json"), JSON.stringify(manifest, null, 2));

    const signingDirectory = path.join(tempDirectory, "signing");
    fs.mkdirSync(signingDirectory, { recursive: true });
    const wwdrPEMPath = path.join(signingDirectory, "wwdr.pem");
    const signerCertPEMPath = path.join(signingDirectory, "signerCert.pem");
    const signerKeyPEMPath = path.join(signingDirectory, "signerKey.pem");
    const passwordArgument = `pass:${walletPassCertificatePassword}`;
    const certificatePath = walletPassCertificateBase64
        ? path.join(signingDirectory, "signerCert.p12")
        : walletPassCertificatePath;
    const wwdrSourcePath = walletPassWWDRBase64
        ? path.join(signingDirectory, "AppleWWDR.cer")
        : walletPassWWDRPath;

    if (walletPassCertificateBase64) {
        writeDecodedSecret(certificatePath, walletPassCertificateBase64);
    }

    if (walletPassWWDRBase64) {
        writeDecodedSecret(wwdrSourcePath, walletPassWWDRBase64);
    }

    exportWWDRCertificate(wwdrSourcePath, wwdrPEMPath);
    execFileSync("/usr/bin/openssl", ["pkcs12", "-legacy", "-in", certificatePath, "-clcerts", "-nokeys", "-out", signerCertPEMPath, "-passin", passwordArgument]);
    execFileSync("/usr/bin/openssl", ["pkcs12", "-legacy", "-in", certificatePath, "-nocerts", "-nodes", "-out", signerKeyPEMPath, "-passin", passwordArgument]);
    execFileSync("/usr/bin/openssl", [
        "smime",
        "-binary",
        "-sign",
        "-signer",
        signerCertPEMPath,
        "-inkey",
        signerKeyPEMPath,
        "-certfile",
        wwdrPEMPath,
        "-in",
        path.join(passDirectory, "manifest.json"),
        "-out",
        path.join(passDirectory, "signature"),
        "-outform",
        "DER"
    ]);

    const outputPath = path.join(tempDirectory, "TallaLoyalty.pkpass");
    const zipFiles = fs.readdirSync(passDirectory)
        .filter((fileName) => fs.statSync(path.join(passDirectory, fileName)).isFile())
        .sort();

    const zipCommand = [
        "-rq",
        "-X",
        escapeShellArgument(outputPath),
        ...zipFiles.map(escapeShellArgument)
    ].join(" ");

    execFileSync("/bin/sh", ["-lc", `cd ${escapeShellArgument(passDirectory)} && /usr/bin/zip ${zipCommand}`]);

    return {
        path: outputPath,
        cleanup() {
            fs.rmSync(tempDirectory, { recursive: true, force: true });
        }
    };
}

function memberIDFor(email) {
    const localPart = email.split("@")[0] || "member";
    const normalized = localPart.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 6) || "MEMBER";
    const hashSuffix = crypto
        .createHash("sha256")
        .update(email.trim().toLowerCase())
        .digest("hex")
        .slice(0, 4)
        .toUpperCase();
    return `TALLA-${normalized}${hashSuffix}`;
}

function tierFor(pointsBalance) {
    if (pointsBalance >= 250) return "Gold";
    if (pointsBalance >= 125) return "Silver";
    return "Bronze";
}

function nextRewardText(pointsBalance) {
    const threshold = 50;
    const remainder = pointsBalance % threshold;
    const remaining = remainder === 0 ? threshold : threshold - remainder;
    return `${remaining} Beans to your next reward`;
}

function generateVoucherCode(reward) {
    const rewardPrefix = String(reward || "reward")
        .toUpperCase()
        .replace(/[^A-Z0-9]/g, "")
        .slice(0, 6)
        || "TALLA";
    const randomSuffix = crypto.randomBytes(3).toString("hex").toUpperCase();
    return `${rewardPrefix}-${randomSuffix}`;
}

function buildVoucherRecord(email, reward, points) {
    const generatedAt = new Date();
    const rewardDetails = rewardDetailsFor(reward);
    const expiresAtDate = new Date(generatedAt.getTime() + rewardDetails.expiresInDays * 24 * 60 * 60 * 1000);

    return {
        code: generateVoucherCode(reward),
        email,
        reward,
        points,
        detail: rewardDetails.detail,
        singleUse: true,
        status: "active",
        createdAt: generatedAt.toISOString(),
        expiresAt: expiresAtDate.toISOString()
    };
}

async function storeVoucherRecord(voucher) {
    if (database.isEnabled()) {
        await database.query(
            `INSERT INTO vouchers
             (code, email, reward, points, detail, single_use, status, created_at, expires_at, used_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
            [
                voucher.code,
                voucher.email,
                voucher.reward,
                voucher.points,
                voucher.detail,
                voucher.singleUse,
                voucher.status,
                voucher.createdAt,
                voucher.expiresAt,
                voucher.usedAt || null
            ]
        );
        return;
    }

    const store = readJSON(vouchersStorePath);
    store.vouchers[voucher.code] = voucher;
    writeJSON(vouchersStorePath, store);
}

function voucherRowToRecord(row) {
    return {
        code: row.code,
        email: row.email,
        reward: row.reward,
        points: row.points,
        detail: row.detail,
        singleUse: row.single_use,
        status: row.status,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        expiresAt: row.expires_at instanceof Date ? row.expires_at.toISOString() : row.expires_at,
        usedAt: row.used_at instanceof Date ? row.used_at.toISOString() : row.used_at
    };
}

async function consumeVoucher(code, email) {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT code, email, reward, points, detail, single_use, status, created_at, expires_at, used_at
             FROM vouchers
             WHERE code = $1`,
            [code]
        );
        const voucher = result.rowCount > 0 ? voucherRowToRecord(result.rows[0]) : null;

        if (!voucher) {
            throw new Error("VOUCHER_NOT_FOUND");
        }

        if (email && voucher.email !== email) {
            throw new Error("VOUCHER_EMAIL_MISMATCH");
        }

        if (voucher.status === "used") {
            throw new Error("VOUCHER_ALREADY_USED");
        }

        if (new Date(voucher.expiresAt).getTime() < Date.now()) {
            await database.query(`UPDATE vouchers SET status = 'expired' WHERE code = $1`, [code]);
            throw new Error("VOUCHER_EXPIRED");
        }

        const usedAt = new Date().toISOString();
        await database.query(
            `UPDATE vouchers
             SET status = 'used', used_at = $2
             WHERE code = $1`,
            [code, usedAt]
        );
        return {
            ...voucher,
            status: "used",
            usedAt
        };
    }

    const store = readJSON(vouchersStorePath);
    const voucher = store.vouchers[code];

    if (!voucher) {
        throw new Error("VOUCHER_NOT_FOUND");
    }

    if (email && voucher.email !== email) {
        throw new Error("VOUCHER_EMAIL_MISMATCH");
    }

    if (voucher.status === "used") {
        throw new Error("VOUCHER_ALREADY_USED");
    }

    if (new Date(voucher.expiresAt).getTime() < Date.now()) {
        voucher.status = "expired";
        writeJSON(vouchersStorePath, store);
        throw new Error("VOUCHER_EXPIRED");
    }

    voucher.status = "used";
    voucher.usedAt = new Date().toISOString();
    writeJSON(vouchersStorePath, store);
    return voucher;
}

async function previewVoucher(code, email) {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT code, email, reward, points, detail, single_use, status, created_at, expires_at, used_at
             FROM vouchers
             WHERE code = $1`,
            [code]
        );
        const voucher = result.rowCount > 0 ? voucherRowToRecord(result.rows[0]) : null;

        if (!voucher) {
            throw new Error("VOUCHER_NOT_FOUND");
        }

        if (email && voucher.email !== email) {
            throw new Error("VOUCHER_EMAIL_MISMATCH");
        }

        if (voucher.status === "used") {
            throw new Error("VOUCHER_ALREADY_USED");
        }

        if (new Date(voucher.expiresAt).getTime() < Date.now()) {
            await database.query(`UPDATE vouchers SET status = 'expired' WHERE code = $1`, [code]);
            throw new Error("VOUCHER_EXPIRED");
        }

        return voucher;
    }

    const store = readJSON(vouchersStorePath);
    const voucher = store.vouchers[code];

    if (!voucher) {
        throw new Error("VOUCHER_NOT_FOUND");
    }

    if (email && voucher.email !== email) {
        throw new Error("VOUCHER_EMAIL_MISMATCH");
    }

    if (voucher.status === "used") {
        throw new Error("VOUCHER_ALREADY_USED");
    }

    if (new Date(voucher.expiresAt).getTime() < Date.now()) {
        voucher.status = "expired";
        writeJSON(vouchersStorePath, store);
        throw new Error("VOUCHER_EXPIRED");
    }

    return voucher;
}

async function activeVouchersFor(email) {
    if (database.isEnabled()) {
        await database.query(
            `UPDATE vouchers
             SET status = 'expired'
             WHERE email = $1 AND status <> 'used' AND expires_at < NOW()`,
            [email]
        );

        const result = await database.query(
            `SELECT code, email, reward, points, detail, single_use, status, created_at, expires_at, used_at
             FROM vouchers
             WHERE email = $1 AND status = 'active'
             ORDER BY created_at DESC`,
            [email]
        );

        return result.rows.map(voucherRowToRecord);
    }

    const normalizedEmail = normalizeEmail(email);
    const store = readJSON(vouchersStorePath);
    const now = Date.now();

    return Object.values(store.vouchers)
        .filter((voucher) => voucher.email === normalizedEmail)
        .map((voucher) => {
            if (voucher.status !== "used" && new Date(voucher.expiresAt).getTime() < now) {
                voucher.status = "expired";
            }
            return voucher;
        })
        .filter((voucher) => voucher.status === "active")
        .sort((lhs, rhs) => new Date(rhs.createdAt).getTime() - new Date(lhs.createdAt).getTime());
}

async function allVouchersFor(email) {
    const normalizedEmail = normalizeEmail(email);

    if (database.isEnabled()) {
        await database.query(
            `UPDATE vouchers
             SET status = 'expired'
             WHERE email = $1 AND status = 'active' AND expires_at < NOW()`,
            [normalizedEmail]
        );

        const result = await database.query(
            `SELECT code, email, reward, points, detail, single_use, status, created_at, expires_at, used_at
             FROM vouchers
             WHERE email = $1
             ORDER BY created_at DESC`,
            [normalizedEmail]
        );

        return result.rows.map(voucherRowToRecord);
    }

    const store = readJSON(vouchersStorePath);
    const now = Date.now();

    return Object.values(store.vouchers)
        .filter((voucher) => voucher.email === normalizedEmail)
        .map((voucher) => {
            if (voucher.status === "active" && new Date(voucher.expiresAt).getTime() < now) {
                voucher.status = "expired";
            }
            return voucher;
        })
        .sort((lhs, rhs) => new Date(rhs.createdAt).getTime() - new Date(lhs.createdAt).getTime());
}

async function createAdminVoucherRecord({ email, reward, points, detail, expiresInDays }) {
    const voucher = buildVoucherRecord(email, reward, points);
    voucher.detail = detail || voucher.detail;
    voucher.expiresAt = new Date(Date.now() + expiresInDays * 24 * 60 * 60 * 1000).toISOString();
    await storeVoucherRecord(voucher);
    return voucher;
}

async function revokeVoucherRecord(code) {
    if (database.isEnabled()) {
        const result = await database.query(
            `UPDATE vouchers
             SET status = 'revoked'
             WHERE code = $1
               AND status = 'active'
             RETURNING code, email, reward, points, detail, single_use, status, created_at, expires_at, used_at`,
            [code]
        );

        return result.rowCount === 0 ? null : voucherRowToRecord(result.rows[0]);
    }

    const store = readJSON(vouchersStorePath);
    const voucher = store.vouchers[code];
    if (!voucher || voucher.status !== "active") {
        return null;
    }

    voucher.status = "revoked";
    writeJSON(vouchersStorePath, store);
    return voucher;
}

function stockAlertStatusFor(record, previousRecord) {
    if (!record.isAvailableForSale) {
        return "Waiting for restock";
    }

    if (previousRecord && previousRecord.isAvailableForSale === false && record.isAvailableForSale === true) {
        return "Back in stock";
    }

    if (record.tag) {
        return `${record.tag} watch`;
    }

    return "Roast watch";
}

function stockAlertRowToRecord(row) {
    return {
        productID: row.product_id,
        productName: row.product_name,
        tag: row.tag,
        isAvailableForSale: row.is_available_for_sale,
        status: row.status,
        updatedAt: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at
    };
}

async function stockAlertsFor(email) {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT product_id, product_name, tag, is_available_for_sale, status, updated_at
             FROM stock_alerts
             WHERE email = $1
             ORDER BY updated_at DESC`,
            [email]
        );
        return result.rows.map(stockAlertRowToRecord);
    }

    const store = readJSON(alertsStorePath);
    return store.alerts[email] || [];
}

async function upsertStockAlert(email, payload) {
    if (database.isEnabled()) {
        const existingResult = await database.query(
            `SELECT product_id, product_name, tag, is_available_for_sale, status, updated_at
             FROM stock_alerts
             WHERE email = $1 AND product_id = $2`,
            [email, payload.productID]
        );
        const previousRecord = existingResult.rowCount > 0 ? stockAlertRowToRecord(existingResult.rows[0]) : null;
        const record = {
            productID: payload.productID,
            productName: payload.productName,
            tag: payload.tag || null,
            isAvailableForSale: Boolean(payload.isAvailableForSale),
            status: stockAlertStatusFor(payload, previousRecord),
            updatedAt: new Date().toISOString()
        };

        await database.query(
            `INSERT INTO stock_alerts
             (email, product_id, product_name, tag, is_available_for_sale, status, updated_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7)
             ON CONFLICT (email, product_id)
             DO UPDATE SET
                 product_name = EXCLUDED.product_name,
                 tag = EXCLUDED.tag,
                 is_available_for_sale = EXCLUDED.is_available_for_sale,
                 status = EXCLUDED.status,
                 updated_at = EXCLUDED.updated_at`,
            [email, record.productID, record.productName, record.tag, record.isAvailableForSale, record.status, record.updatedAt]
        );

        return record;
    }

    const store = readJSON(alertsStorePath);
    const alerts = store.alerts[email] || [];
    const existingIndex = alerts.findIndex((alert) => alert.productID === payload.productID);
    const previousRecord = existingIndex >= 0 ? alerts[existingIndex] : null;
    const record = {
        productID: payload.productID,
        productName: payload.productName,
        tag: payload.tag || null,
        isAvailableForSale: Boolean(payload.isAvailableForSale),
        status: stockAlertStatusFor(payload, previousRecord),
        updatedAt: new Date().toISOString()
    };

    if (existingIndex >= 0) {
        alerts[existingIndex] = record;
    } else {
        alerts.unshift(record);
    }

    store.alerts[email] = alerts;
    writeJSON(alertsStorePath, store);
    return record;
}

async function removeStockAlert(email, productID) {
    if (database.isEnabled()) {
        await database.query(
            `DELETE FROM stock_alerts
             WHERE email = $1 AND product_id = $2`,
            [email, productID]
        );
        return;
    }

    const store = readJSON(alertsStorePath);
    const alerts = store.alerts[email] || [];
    store.alerts[email] = alerts.filter((alert) => alert.productID !== productID);
    writeJSON(alertsStorePath, store);
}

function alertInboxRowToRecord(row) {
    return {
        id: row.id,
        title: row.title,
        detail: row.detail,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        productID: row.product_id
    };
}

async function trimAlertInbox(email, maxRecords = 20) {
    if (!database.isEnabled()) {
        return;
    }

    await database.query(
        `DELETE FROM alert_inbox
         WHERE email = $1
           AND id NOT IN (
             SELECT id FROM alert_inbox
             WHERE email = $1
             ORDER BY created_at DESC
             LIMIT $2
           )`,
        [email, maxRecords]
    );
}

function normalizeDeviceToken(deviceToken) {
    const normalized = String(deviceToken || "")
        .trim()
        .toLowerCase()
        .replace(/[^a-f0-9]/g, "");

    if (!normalized || normalized.length < 32 || normalized.length % 2 !== 0) {
        return "";
    }

    return normalized;
}

function pushDeviceRowToRecord(row) {
    return {
        id: row.id,
        email: normalizeEmail(row.email),
        deviceToken: normalizeDeviceToken(row.device_token),
        platform: row.platform,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
        updatedAt: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at,
        lastSentAt: row.last_sent_at instanceof Date ? row.last_sent_at.toISOString() : (row.last_sent_at || null)
    };
}

async function pushDevicesForEmail(email) {
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) {
        return [];
    }

    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, email, device_token, platform, created_at, updated_at, last_sent_at
             FROM push_devices
             WHERE email = $1
             ORDER BY updated_at DESC`,
            [normalizedEmail]
        );
        return result.rows.map(pushDeviceRowToRecord);
    }

    const store = readJSON(pushDevicesStorePath);
    return (store.devices || [])
        .filter((device) => normalizeEmail(device.email) === normalizedEmail)
        .map((device) => ({
            id: device.id,
            email: normalizeEmail(device.email),
            deviceToken: normalizeDeviceToken(device.deviceToken),
            platform: device.platform || "ios",
            createdAt: device.createdAt,
            updatedAt: device.updatedAt,
            lastSentAt: device.lastSentAt || null
        }))
        .filter((device) => device.deviceToken);
}

async function allPushDevices() {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT DISTINCT ON (device_token)
                    id, email, device_token, platform, created_at, updated_at, last_sent_at
             FROM push_devices
             ORDER BY device_token, updated_at DESC`
        );
        return result.rows.map(pushDeviceRowToRecord);
    }

    const store = readJSON(pushDevicesStorePath);
    return (store.devices || [])
        .map((device) => ({
            id: device.id,
            email: normalizeEmail(device.email),
            deviceToken: normalizeDeviceToken(device.deviceToken),
            platform: device.platform || "ios",
            createdAt: device.createdAt,
            updatedAt: device.updatedAt,
            lastSentAt: device.lastSentAt || null
        }))
        .filter((device) => device.deviceToken);
}

async function registerPushDevice(email, deviceToken, platform = "ios") {
    const normalizedEmail = normalizeEmail(email);
    const normalizedToken = normalizeDeviceToken(deviceToken);
    const normalizedPlatform = String(platform || "ios").trim().toLowerCase() || "ios";

    if (!normalizedEmail || !normalizedToken) {
        return null;
    }

    const timestamp = new Date().toISOString();

    if (database.isEnabled()) {
        const result = await database.query(
            `INSERT INTO push_devices
             (id, email, device_token, platform, created_at, updated_at, last_sent_at)
             VALUES ($1, $2, $3, $4, $5, $5, NULL)
             ON CONFLICT (device_token)
             DO UPDATE SET
                 email = EXCLUDED.email,
                 platform = EXCLUDED.platform,
                 updated_at = EXCLUDED.updated_at
             RETURNING id, email, device_token, platform, created_at, updated_at, last_sent_at`,
            [`push_${Date.now()}_${crypto.randomBytes(3).toString("hex")}`, normalizedEmail, normalizedToken, normalizedPlatform, timestamp]
        );
        return result.rowCount === 0 ? null : pushDeviceRowToRecord(result.rows[0]);
    }

    const store = readJSON(pushDevicesStorePath);
    const devices = Array.isArray(store.devices) ? store.devices : [];
    const existingIndex = devices.findIndex((device) => normalizeDeviceToken(device.deviceToken) === normalizedToken);
    const existingRecord = existingIndex >= 0 ? devices[existingIndex] : null;
    const nextRecord = {
        id: existingRecord?.id || `push_${Date.now()}_${crypto.randomBytes(3).toString("hex")}`,
        email: normalizedEmail,
        deviceToken: normalizedToken,
        platform: normalizedPlatform,
        createdAt: existingRecord?.createdAt || timestamp,
        updatedAt: timestamp,
        lastSentAt: existingRecord?.lastSentAt || null
    };

    if (existingIndex >= 0) {
        devices[existingIndex] = nextRecord;
    } else {
        devices.unshift(nextRecord);
    }

    store.devices = devices;
    writeJSON(pushDevicesStorePath, store);
    return nextRecord;
}

async function unregisterPushDevice(email, deviceToken) {
    const normalizedEmail = normalizeEmail(email);
    const normalizedToken = normalizeDeviceToken(deviceToken);

    if (!normalizedEmail || !normalizedToken) {
        return false;
    }

    if (database.isEnabled()) {
        const result = await database.query(
            `DELETE FROM push_devices
             WHERE email = $1 AND device_token = $2
             RETURNING id`,
            [normalizedEmail, normalizedToken]
        );
        return result.rowCount > 0;
    }

    const store = readJSON(pushDevicesStorePath);
    const beforeCount = Array.isArray(store.devices) ? store.devices.length : 0;
    store.devices = (store.devices || []).filter((device) => (
        !(normalizeEmail(device.email) === normalizedEmail && normalizeDeviceToken(device.deviceToken) === normalizedToken)
    ));
    writeJSON(pushDevicesStorePath, store);
    return store.devices.length < beforeCount;
}

async function markPushDeviceSent(deviceToken) {
    const normalizedToken = normalizeDeviceToken(deviceToken);
    if (!normalizedToken) {
        return;
    }

    if (database.isEnabled()) {
        await database.query(
            `UPDATE push_devices
             SET last_sent_at = NOW(), updated_at = NOW()
             WHERE device_token = $1`,
            [normalizedToken]
        );
        return;
    }

    const store = readJSON(pushDevicesStorePath);
    let didUpdate = false;
    store.devices = (store.devices || []).map((device) => {
        if (normalizeDeviceToken(device.deviceToken) !== normalizedToken) {
            return device;
        }

        didUpdate = true;
        return {
            ...device,
            lastSentAt: new Date().toISOString(),
            updatedAt: new Date().toISOString()
        };
    });

    if (didUpdate) {
        writeJSON(pushDevicesStorePath, store);
    }
}

async function prunePushDevice(deviceToken) {
    const normalizedToken = normalizeDeviceToken(deviceToken);
    if (!normalizedToken) {
        return;
    }

    if (database.isEnabled()) {
        await database.query(
            `DELETE FROM push_devices
             WHERE device_token = $1`,
            [normalizedToken]
        );
        return;
    }

    const store = readJSON(pushDevicesStorePath);
    const nextDevices = (store.devices || []).filter((device) => normalizeDeviceToken(device.deviceToken) !== normalizedToken);
    if (nextDevices.length !== (store.devices || []).length) {
        store.devices = nextDevices;
        writeJSON(pushDevicesStorePath, store);
    }
}

async function sendRemotePushToDevice(deviceToken, notification) {
    const normalizedToken = normalizeDeviceToken(deviceToken);
    if (!normalizedToken || !remotePushConfigured()) {
        return false;
    }

    const authority = apnsUseSandbox
        ? "https://api.sandbox.push.apple.com"
        : "https://api.push.apple.com";
    let authorizationToken = "";

    try {
        authorizationToken = apnsBearerToken();
    } catch (error) {
        return false;
    }

    return await new Promise((resolve) => {
        const client = http2.connect(authority);
        const payload = JSON.stringify({
            aps: {
                alert: {
                    title: notification.title,
                    body: notification.body
                },
                sound: "default"
            },
            type: notification.type || "stock_alert",
            productID: notification.productID || null,
            url: notification.url || null
        });

        client.on("error", () => {
            client.close();
            resolve(false);
        });

        const request = client.request({
            ":method": "POST",
            ":path": `/3/device/${normalizedToken}`,
            authorization: `bearer ${authorizationToken}`,
            "apns-topic": apnsBundleID,
            "apns-push-type": "alert",
            "apns-priority": "10"
        });

        let responseBody = "";
        let statusCode = 0;

        request.setEncoding("utf8");
        request.on("response", (headers) => {
            statusCode = Number(headers[http2.constants.HTTP2_HEADER_STATUS] || 0);
        });
        request.on("data", (chunk) => {
            responseBody += chunk;
        });
        request.on("end", async () => {
            client.close();

            if (statusCode === 200) {
                await markPushDeviceSent(normalizedToken);
                resolve(true);
                return;
            }

            try {
                const parsed = responseBody ? JSON.parse(responseBody) : null;
                const reason = parsed?.reason || "";
                if (["BadDeviceToken", "DeviceTokenNotForTopic", "Unregistered"].includes(reason)) {
                    await prunePushDevice(normalizedToken);
                }
            } catch (error) {
                // Ignore malformed APNs error bodies.
            }

            resolve(false);
        });
        request.on("error", () => {
            client.close();
            resolve(false);
        });
        request.end(payload);
    });
}

async function sendStockAlertPush(email, { title, body, productID }) {
    if (!remotePushConfigured()) {
        return;
    }

    const devices = await pushDevicesForEmail(email);
    for (const device of devices) {
        await sendRemotePushToDevice(device.deviceToken, {
            title,
            body,
            type: "stock_alert",
            productID
        });
    }
}

async function sendOrderReadyPush(email, order) {
    if (!remotePushConfigured()) {
        return { configured: false, targetCount: 0, sentCount: 0 };
    }

    const devices = await pushDevicesForEmail(email);
    let sentCount = 0;
    for (const device of devices) {
        const didSend = await sendRemotePushToDevice(device.deviceToken, {
            title: "Your Talla order is ready",
            body: `${order.title || "Your order"} is ready for pickup.`,
            type: "order_ready",
            productID: order.id || null
        });
        if (didSend) {
            sentCount += 1;
        }
    }

    return {
        configured: true,
        targetCount: devices.length,
        sentCount
    };
}

async function sendOrderReadyPushIfNeeded(status, order) {
    if (normalizeOrderStatus(status) !== "Ready" || !order?.email) {
        return null;
    }

    return sendOrderReadyPush(order.email, order);
}

async function sendCampaignPushToAll({ title, body, type = "campaign", url = null }) {
    if (!remotePushConfigured()) {
        return { configured: false, targetCount: 0, sentCount: 0 };
    }

    const devices = await allPushDevices();
    let sentCount = 0;
    for (const device of devices) {
        const didSend = await sendRemotePushToDevice(device.deviceToken, {
            title,
            body,
            type,
            url
        });
        if (didSend) {
            sentCount += 1;
        }
    }

    return {
        configured: true,
        targetCount: devices.length,
        sentCount
    };
}

async function syncStockAlerts(email, alertPayloads) {
    if (database.isEnabled()) {
        const existingAlerts = await stockAlertsFor(email);
        const payloadByID = new Map(alertPayloads.map((alert) => [alert.productID, alert]));
        const synced = [];

        for (const existing of existingAlerts) {
            const payload = payloadByID.get(existing.productID);
            if (!payload) {
                synced.push(existing);
                continue;
            }

            const nextRecord = {
                productID: existing.productID,
                productName: payload.productName || existing.productName,
                tag: payload.tag || existing.tag || null,
                isAvailableForSale: Boolean(payload.isAvailableForSale),
                status: stockAlertStatusFor(payload, existing),
                updatedAt: new Date().toISOString()
            };

            await database.query(
                `UPDATE stock_alerts
                 SET product_name = $3,
                     tag = $4,
                     is_available_for_sale = $5,
                     status = $6,
                     updated_at = $7
                 WHERE email = $1 AND product_id = $2`,
                [email, nextRecord.productID, nextRecord.productName, nextRecord.tag, nextRecord.isAvailableForSale, nextRecord.status, nextRecord.updatedAt]
            );

            if (existing.isAvailableForSale === false && nextRecord.isAvailableForSale === true) {
                const inboxTitle = `${nextRecord.productName} is back`;
                const inboxDetail = `${nextRecord.productName} is available again in the Talla app.`;
                await database.query(
                    `INSERT INTO alert_inbox
                     (id, email, title, detail, created_at, product_id)
                     VALUES ($1, $2, $3, $4, $5, $6)`,
                    [
                        `alert_${Date.now()}_${existing.productID}`,
                        email,
                        inboxTitle,
                        inboxDetail,
                        new Date().toISOString(),
                        existing.productID
                    ]
                );
                await sendStockAlertPush(email, {
                    title: inboxTitle,
                    body: inboxDetail,
                    productID: existing.productID
                });
            }

            synced.push(nextRecord);
        }

        await trimAlertInbox(email);
        return synced.sort((lhs, rhs) => new Date(rhs.updatedAt).getTime() - new Date(lhs.updatedAt).getTime());
    }

    const store = readJSON(alertsStorePath);
    const existingAlerts = store.alerts[email] || [];
    const inboxStore = readJSON(alertInboxStorePath);
    const inbox = inboxStore.alerts[email] || [];
    const payloadByID = new Map(alertPayloads.map((alert) => [alert.productID, alert]));
    const synced = [];
    for (const existing of existingAlerts) {
        const payload = payloadByID.get(existing.productID);
        if (!payload) {
            synced.push(existing);
            continue;
        }

        const nextRecord = {
            productID: existing.productID,
            productName: payload.productName || existing.productName,
            tag: payload.tag || existing.tag || null,
            isAvailableForSale: Boolean(payload.isAvailableForSale),
            status: stockAlertStatusFor(payload, existing),
            updatedAt: new Date().toISOString()
        };

        if (existing.isAvailableForSale === false && nextRecord.isAvailableForSale === true) {
            const inboxTitle = `${nextRecord.productName} is back`;
            const inboxDetail = `${nextRecord.productName} is available again in the Talla app.`;
            inbox.unshift({
                id: `alert_${Date.now()}_${existing.productID}`,
                title: inboxTitle,
                detail: inboxDetail,
                createdAt: new Date().toISOString(),
                productID: existing.productID
            });
            await sendStockAlertPush(email, {
                title: inboxTitle,
                body: inboxDetail,
                productID: existing.productID
            });
        }

        synced.push(nextRecord);
    }

    synced.sort((lhs, rhs) => new Date(rhs.updatedAt).getTime() - new Date(lhs.updatedAt).getTime());

    store.alerts[email] = synced;
    inboxStore.alerts[email] = inbox.slice(0, 20);
    writeJSON(alertsStorePath, store);
    writeJSON(alertInboxStorePath, inboxStore);
    return synced;
}

function addressRowToRecord(row) {
    return {
        id: row.id,
        label: row.label,
        fullName: row.full_name,
        phone: row.phone,
        line1: row.line1,
        city: row.city,
        notes: row.notes,
        isPreferred: row.is_preferred
    };
}

async function addressesFor(email) {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, label, full_name, phone, line1, city, notes, is_preferred, created_at
             FROM addresses
             WHERE email = $1
             ORDER BY is_preferred DESC, created_at DESC`,
            [email]
        );
        return result.rows.map(addressRowToRecord);
    }

    const store = readJSON(addressesStorePath);
    return store.addresses[email] || [];
}

async function saveAddress(email, payload) {
    if (database.isEnabled()) {
        const requestedPreferred = Boolean(payload.isPreferred);
        const result = await database.query(
            `SELECT COUNT(*)::int AS count
             FROM addresses
             WHERE email = $1`,
            [email]
        );
        const hasExistingAddresses = result.rows[0].count > 0;
        const isPreferred = requestedPreferred || !hasExistingAddresses;

        if (isPreferred) {
            await database.query(
                `UPDATE addresses
                 SET is_preferred = FALSE
                 WHERE email = $1`,
                [email]
            );
        }

        if (payload.id) {
            await database.query(
                `UPDATE addresses
                 SET label = $3,
                     full_name = $4,
                     phone = $5,
                     line1 = $6,
                     city = $7,
                     notes = $8,
                     is_preferred = $9
                 WHERE email = $1 AND id = $2`,
                [email, payload.id, payload.label, payload.fullName, payload.phone, payload.line1, payload.city, payload.notes || null, isPreferred]
            );
            return addressesFor(email);
        }

        const id = `addr_${Date.now()}`;
        const createdAt = new Date().toISOString();
        await database.query(
            `INSERT INTO addresses
             (id, email, label, full_name, phone, line1, city, notes, is_preferred, created_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
            [id, email, payload.label, payload.fullName, payload.phone, payload.line1, payload.city, payload.notes || null, isPreferred, createdAt]
        );

        return addressesFor(email);
    }

    const store = readJSON(addressesStorePath);
    const addresses = store.addresses[email] || [];
    const requestedPreferred = Boolean(payload.isPreferred);

    if (payload.id) {
        const updated = addresses.map((address) => {
            if (address.id !== payload.id) {
                return requestedPreferred ? { ...address, isPreferred: false } : address;
            }

            return {
                ...address,
                label: payload.label,
                fullName: payload.fullName,
                phone: payload.phone,
                line1: payload.line1,
                city: payload.city,
                notes: payload.notes || null,
                isPreferred: requestedPreferred || (addresses.length === 1 ? true : address.isPreferred)
            };
        });

        store.addresses[email] = updated.some((address) => address.isPreferred)
            ? updated
            : updated.map((address, index) => ({ ...address, isPreferred: index === 0 }));
        writeJSON(addressesStorePath, store);
        return store.addresses[email];
    }

    const nextAddress = {
        id: `addr_${Date.now()}`,
        label: payload.label,
        fullName: payload.fullName,
        phone: payload.phone,
        line1: payload.line1,
        city: payload.city,
        notes: payload.notes || null,
        isPreferred: requestedPreferred || addresses.length === 0
    };

    store.addresses[email] = [
        nextAddress,
        ...addresses.map((address) => ({
            ...address,
            isPreferred: nextAddress.isPreferred ? false : address.isPreferred
        }))
    ];
    writeJSON(addressesStorePath, store);
    return store.addresses[email];
}

async function deleteAddress(email, addressID) {
    if (database.isEnabled()) {
        await database.query(
            `DELETE FROM addresses
             WHERE email = $1 AND id = $2`,
            [email, addressID]
        );

        const remaining = await addressesFor(email);
        if (remaining.length > 0 && !remaining.some((address) => address.isPreferred)) {
            const nextPreferredID = remaining[0].id;
            await database.query(
                `UPDATE addresses
                 SET is_preferred = CASE WHEN id = $2 THEN TRUE ELSE FALSE END
                 WHERE email = $1`,
                [email, nextPreferredID]
            );
        }

        return addressesFor(email);
    }

    const store = readJSON(addressesStorePath);
    const addresses = store.addresses[email] || [];
    let updated = addresses.filter((address) => address.id !== addressID);

    if (updated.length > 0 && !updated.some((address) => address.isPreferred)) {
        updated = updated.map((address, index) => ({ ...address, isPreferred: index === 0 }));
    }

    store.addresses[email] = updated;
    writeJSON(addressesStorePath, store);
    return updated;
}

async function alertInboxFor(email) {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, title, detail, created_at, product_id
             FROM alert_inbox
             WHERE email = $1
             ORDER BY created_at DESC
             LIMIT 20`,
            [email]
        );
        return result.rows.map(alertInboxRowToRecord);
    }

    const store = readJSON(alertInboxStorePath);
    return store.alerts[email] || [];
}

async function adminAuditLogsFor(email, limit = 20) {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, admin_username, action, target_email, detail, metadata, created_at
             FROM admin_audit_logs
             WHERE target_email = $1
             ORDER BY created_at DESC
             LIMIT $2`,
            [email, limit]
        );
        return result.rows.map(adminAuditRowToRecord);
    }

    return [];
}

async function recentAdminAuditLogs(limit = 8) {
    if (!database.isEnabled()) {
        return [];
    }

    const safeLimit = Math.min(Math.max(Number(limit) || 8, 1), 30);
    const result = await database.query(
        `SELECT id, admin_username, action, target_email, detail, metadata, created_at
         FROM admin_audit_logs
         ORDER BY created_at DESC
         LIMIT $1`,
        [safeLimit]
    );
    return result.rows.map(adminAuditRowToRecord);
}

function buildCustomerTimeline({ account, loyalty, orders, vouchers, inbox, auditLogs, sessions, tasteMemory }) {
    const timeline = [
        {
            id: `account_${account.id}`,
            kind: "account_created",
            title: "Account created",
            detail: `${account.firstName} ${account.lastName}`.trim() || account.email,
            createdAt: account.createdAt
        },
        ...((loyalty.transactions || []).map((transaction) => ({
            id: `loyalty_${transaction.id}`,
            kind: "loyalty_transaction",
            title: transaction.type === "redeem" ? "Loyalty redemption" : "Loyalty earn",
            detail: `${transaction.type === "redeem" ? "Removed" : "Added"} ${transaction.points} Beans${transaction.note ? ` • ${transaction.note}` : ""}`,
            createdAt: transaction.createdAt
        }))),
        ...orders.map((order) => ({
            id: `order_${order.id}`,
            kind: "order",
            title: order.title,
            detail: `${order.status} • ${order.total}`,
            createdAt: order.createdAt
        })),
        ...vouchers.map((voucher) => ({
            id: `voucher_${voucher.code}_${voucher.status}`,
            kind: "voucher",
            title: `Voucher ${voucher.reward}`,
            detail: `${voucher.status} • ${voucher.code}${voucher.detail ? ` • ${voucher.detail}` : ""}`,
            createdAt: voucher.usedAt || voucher.createdAt
        })),
        ...inbox.map((item) => ({
            id: `inbox_${item.id}`,
            kind: "inbox",
            title: item.title,
            detail: item.detail,
            createdAt: item.createdAt
        })),
        ...tasteMemory.map((record) => ({
            id: `taste_${record.id}`,
            kind: "taste_memory",
            title: `Taste memory: ${record.productName}`,
            detail: `${record.reaction === "loved" ? "Loved it" : "Not for me"}${record.tags.length ? ` • ${record.tags.join(", ")}` : ""}`,
            createdAt: record.updatedAt || record.createdAt
        })),
        ...auditLogs.map((entry) => ({
            id: `audit_${entry.id}`,
            kind: "admin_action",
            title: entry.detail,
            detail: `By ${entry.adminUsername}`,
            createdAt: entry.createdAt
        })),
        ...sessions.map((session) => ({
            id: `session_${session.id}`,
            kind: "session",
            title: "Customer session active",
            detail: `Started ${session.createdAt}`,
            createdAt: session.createdAt
        }))
    ];

    return timeline
        .filter((entry) => entry.createdAt)
        .sort((lhs, rhs) => new Date(rhs.createdAt).getTime() - new Date(lhs.createdAt).getTime())
        .slice(0, 80);
}

function requestLogRowToRecord(row) {
    return {
        id: row.id,
        method: row.method,
        path: row.path,
        statusCode: row.status_code,
        ipAddress: row.ip_address,
        durationMs: row.duration_ms,
        userAgent: row.user_agent,
        accountEmail: row.account_email,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at
    };
}

function opsAlertsConfigured() {
    return Boolean(database.isEnabled() && requestLoggingEnabled && opsAlertWebhookURL);
}

async function opsAlertStateFor(alertKey) {
    const result = await database.query(
        `SELECT alert_key, last_sent_at, last_payload
         FROM ops_alert_state
         WHERE alert_key = $1`,
        [alertKey]
    );

    return result.rows[0] || null;
}

async function updateOpsAlertState(alertKey, payload) {
    await database.query(
        `INSERT INTO ops_alert_state (alert_key, last_sent_at, last_payload)
         VALUES ($1, NOW(), $2::jsonb)
         ON CONFLICT (alert_key)
         DO UPDATE SET
            last_sent_at = EXCLUDED.last_sent_at,
            last_payload = EXCLUDED.last_payload`,
        [alertKey, JSON.stringify(payload)]
    );
}

async function sendOpsAlert(title, lines, payload) {
    const message = [title, ...lines].join("\n");
    const response = await fetch(opsAlertWebhookURL, {
        method: "POST",
        headers: {
            "Content-Type": "application/json"
        },
        body: JSON.stringify({
            text: message,
            content: message,
            ...payload
        })
    });

    if (!response.ok) {
        throw new Error(`Ops alert webhook failed with ${response.status}.`);
    }
}

async function maybeSendOpsAlert({ alertKey, title, threshold, whereClause, metricLabel }) {
    if (threshold <= 0) {
        return;
    }

    const summaryResult = await database.query(
        `SELECT COUNT(*)::int AS count
         FROM request_logs
         WHERE created_at >= NOW() - ($1::text || ' minutes')::interval
           AND ${whereClause}`,
        [opsAlertWindowMinutes]
    );

    const count = summaryResult.rows[0]?.count || 0;
    if (count < threshold) {
        return;
    }

    const state = await opsAlertStateFor(alertKey);
    const lastSentAt = state?.last_sent_at ? new Date(state.last_sent_at) : null;
    if (lastSentAt && (Date.now() - lastSentAt.getTime()) < (opsAlertCooldownMinutes * 60_000)) {
        return;
    }

    const recentResult = await database.query(
        `SELECT method, path, status_code, created_at
         FROM request_logs
         WHERE created_at >= NOW() - ($1::text || ' minutes')::interval
           AND ${whereClause}
         ORDER BY created_at DESC
         LIMIT 5`,
        [opsAlertWindowMinutes]
    );

    const lines = [
        `${metricLabel}: ${count} in the last ${opsAlertWindowMinutes} minutes`,
        `App: ${config.appURL}`,
        ...recentResult.rows.map((row) =>
            `- ${row.method} ${row.path} -> ${row.status_code} at ${row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at}`
        )
    ];

    await sendOpsAlert(title, lines, {
        kind: alertKey,
        count,
        threshold,
        windowMinutes: opsAlertWindowMinutes,
        appURL: config.appURL
    });

    await updateOpsAlertState(alertKey, {
        count,
        threshold,
        windowMinutes: opsAlertWindowMinutes
    });
}

async function runOpsAlertChecks() {
    if (!opsAlertsConfigured()) {
        return;
    }

    try {
        await maybeSendOpsAlert({
            alertKey: "ops_5xx_threshold",
            title: "Talla backend alert: elevated 5xx responses",
            threshold: opsAlert5xxThreshold,
            whereClause: "status_code >= 500",
            metricLabel: "5xx responses"
        });

        await maybeSendOpsAlert({
            alertKey: "ops_429_threshold",
            title: "Talla backend alert: elevated rate limiting",
            threshold: opsAlert429Threshold,
            whereClause: "status_code = 429",
            metricLabel: "429 responses"
        });
    } catch (error) {
        console.error("Failed to run ops alert checks.", error);
    }
}

function startOpsAlertMonitor() {
    if (!opsAlertsConfigured() || opsAlertTimer) {
        return;
    }

    const interval = Math.max(60_000, opsAlertCheckIntervalMs);
    opsAlertTimer = setInterval(() => {
        void runOpsAlertChecks();
    }, interval);

    void runOpsAlertChecks();
}

async function adminOperationsSummary() {
    if (!database.isEnabled()) {
        return {
            enabled: false,
            totals: {
                requestsLastHour: 0,
                errorsLastHour: 0,
                rateLimitedLastHour: 0,
                avgDurationMs: 0
            },
            recentErrors: [],
            recentRateLimits: []
        };
    }

    const totalsResult = await database.query(
        `SELECT
            COUNT(*)::int AS requests_last_hour,
            COUNT(*) FILTER (WHERE status_code >= 500)::int AS errors_last_hour,
            COUNT(*) FILTER (WHERE status_code = 429)::int AS rate_limited_last_hour,
            COALESCE(ROUND(AVG(duration_ms))::int, 0) AS avg_duration_ms
         FROM request_logs
         WHERE created_at >= NOW() - INTERVAL '1 hour'`
    );

    const errorsResult = await database.query(
        `SELECT id, method, path, status_code, ip_address, duration_ms, user_agent, account_email, created_at
         FROM request_logs
         WHERE status_code >= 500
         ORDER BY created_at DESC
         LIMIT 10`
    );

    const rateLimitedResult = await database.query(
        `SELECT id, method, path, status_code, ip_address, duration_ms, user_agent, account_email, created_at
         FROM request_logs
         WHERE status_code = 429
         ORDER BY created_at DESC
         LIMIT 10`
    );

    const totals = totalsResult.rows[0] || {};
    return {
        enabled: true,
        totals: {
            requestsLastHour: totals.requests_last_hour || 0,
            errorsLastHour: totals.errors_last_hour || 0,
            rateLimitedLastHour: totals.rate_limited_last_hour || 0,
            avgDurationMs: totals.avg_duration_ms || 0
        },
        recentErrors: errorsResult.rows.map(requestLogRowToRecord),
        recentRateLimits: rateLimitedResult.rows.map(requestLogRowToRecord)
    };
}

async function adminAnalyticsSummary() {
    const [accounts, tasteMemory] = await Promise.all([
        allAccounts(),
        allTasteMemoryPayload()
    ]);
    const customers = await Promise.all(accounts.map(async (account) => {
        const [loyalty, orders, vouchers, alerts] = await Promise.all([
            ensureLoyaltyAccount(account.email),
            ordersPayload(account.email),
            allVouchersFor(account.email),
            stockAlertsFor(account.email)
        ]);

        return {
            id: account.id,
            email: account.email,
            firstName: account.firstName,
            lastName: account.lastName,
            createdAt: account.createdAt,
            loyaltyTier: loyalty.tier,
            pointsBalance: loyalty.pointsBalance,
            orders,
            vouchers,
            alerts
        };
    }));

    const totalOrders = customers.reduce((sum, customer) => sum + customer.orders.length, 0);
    const pendingOrders = customers.reduce((sum, customer) => (
        sum + customer.orders.filter((order) => !completedOrderStatuses().has(order.status) && order.status !== "Cancelled").length
    ), 0);
    const activeVouchers = customers.reduce((sum, customer) => (
        sum + customer.vouchers.filter((voucher) => voucher.status === "active").length
    ), 0);
    const usedVouchers = customers.reduce((sum, customer) => (
        sum + customer.vouchers.filter((voucher) => voucher.status === "used").length
    ), 0);
    const customersWithOrders = customers.filter((customer) => customer.orders.length > 0).length;
    const customersWithAlerts = customers.filter((customer) => customer.alerts.length > 0).length;
    const customersWithTasteMemory = new Set(tasteMemory.map((record) => record.email)).size;
    const averagePoints = customers.length > 0
        ? Math.round(customers.reduce((sum, customer) => sum + customer.pointsBalance, 0) / customers.length)
        : 0;
    const sevenDaysAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
    const newCustomersLast7Days = customers.filter((customer) => {
        const createdAt = new Date(customer.createdAt).getTime();
        return Number.isFinite(createdAt) && createdAt >= sevenDaysAgo;
    }).length;

    const tierCounts = customers.reduce((accumulator, customer) => {
        accumulator[customer.loyaltyTier] = (accumulator[customer.loyaltyTier] || 0) + 1;
        return accumulator;
    }, {});

    const topCustomers = customers
        .slice()
        .sort((lhs, rhs) => rhs.pointsBalance - lhs.pointsBalance)
        .slice(0, 10)
        .map((customer) => ({
            email: customer.email,
            firstName: customer.firstName,
            lastName: customer.lastName,
            loyaltyTier: customer.loyaltyTier,
            pointsBalance: customer.pointsBalance
        }));

    const newestCustomers = customers
        .slice()
        .sort((lhs, rhs) => new Date(rhs.createdAt).getTime() - new Date(lhs.createdAt).getTime())
        .slice(0, 10)
        .map((customer) => ({
            email: customer.email,
            firstName: customer.firstName,
            lastName: customer.lastName,
            createdAt: customer.createdAt
        }));

    return {
        totals: {
            customers: customers.length,
            customersWithOrders,
            customersWithAlerts,
            totalOrders,
            pendingOrders,
            activeVouchers,
            usedVouchers,
            tasteMemory: tasteMemory.length,
            customersWithTasteMemory,
            averagePoints,
            newCustomersLast7Days
        },
        tierCounts,
        topCustomers,
        newestCustomers
    };
}

async function createAdminAuditLog({ adminUser, action, targetEmail, detail, metadata = {} }) {
    if (!database.isEnabled()) {
        return null;
    }

    const createdAt = new Date().toISOString();
    const id = `audit_${Date.now()}_${crypto.randomBytes(3).toString("hex")}`;
    await database.query(
        `INSERT INTO admin_audit_logs
         (id, admin_username, action, target_email, detail, metadata, created_at)
         VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7)`,
        [id, adminUser, action, targetEmail, detail, JSON.stringify(metadata), createdAt]
    );

    return { id, adminUser, action, targetEmail, detail, metadata, createdAt };
}

async function getCampaignSettings() {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT value, updated_at
             FROM app_settings
             WHERE key = $1`,
            ["campaign_settings"]
        );
        if (result.rowCount > 0) {
            return normalizeCampaignSettings({
                ...result.rows[0].value,
                updatedAt: result.rows[0].updated_at?.toISOString?.() || result.rows[0].updated_at
            });
        }
        return defaultCampaignSettings();
    }

    const store = readJSON(campaignSettingsStorePath);
    return normalizeCampaignSettings(store.campaignSettings || {});
}

async function saveCampaignSettings(nextSettings) {
    const settings = normalizeCampaignSettings({
        ...nextSettings,
        updatedAt: new Date().toISOString()
    });

    if (database.isEnabled()) {
        await database.query(
            `INSERT INTO app_settings (key, value, updated_at)
             VALUES ($1, $2::jsonb, NOW())
             ON CONFLICT (key)
             DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()`,
            ["campaign_settings", JSON.stringify(settings)]
        );
        return getCampaignSettings();
    }

    writeJSON(campaignSettingsStorePath, { campaignSettings: settings });
    return settings;
}

async function getHomeSettings() {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT value, updated_at
             FROM app_settings
             WHERE key = $1`,
            ["home_settings"]
        );
        if (result.rowCount > 0) {
            return normalizeHomeSettings({
                ...result.rows[0].value,
                updatedAt: result.rows[0].updated_at?.toISOString?.() || result.rows[0].updated_at
            });
        }
        return defaultHomeSettings();
    }

    const store = readJSON(homeSettingsStorePath);
    return normalizeHomeSettings(store.homeSettings || {});
}

async function saveHomeSettings(nextSettings) {
    const settings = normalizeHomeSettings({
        ...nextSettings,
        updatedAt: new Date().toISOString()
    });

    if (database.isEnabled()) {
        await database.query(
            `INSERT INTO app_settings (key, value, updated_at)
             VALUES ($1, $2::jsonb, NOW())
             ON CONFLICT (key)
             DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()`,
            ["home_settings", JSON.stringify(settings)]
        );
        return getHomeSettings();
    }

    writeJSON(homeSettingsStorePath, { homeSettings: settings });
    return settings;
}

async function getPassportSettings() {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT value, updated_at
             FROM app_settings
             WHERE key = $1`,
            ["passport_settings"]
        );
        if (result.rowCount > 0) {
            return normalizePassportSettings({
                ...result.rows[0].value,
                updatedAt: result.rows[0].updated_at?.toISOString?.() || result.rows[0].updated_at
            });
        }
        return defaultPassportSettings();
    }

    const store = readJSON(passportSettingsStorePath);
    return normalizePassportSettings(store.passportSettings || {});
}

async function savePassportSettings(nextSettings) {
    const settings = normalizePassportSettings({
        ...nextSettings,
        updatedAt: new Date().toISOString()
    });

    if (database.isEnabled()) {
        await database.query(
            `INSERT INTO app_settings (key, value, updated_at)
             VALUES ($1, $2::jsonb, NOW())
             ON CONFLICT (key)
             DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()`,
            ["passport_settings", JSON.stringify(settings)]
        );
        return getPassportSettings();
    }

    writeJSON(passportSettingsStorePath, { passportSettings: settings });
    return settings;
}

async function adminCustomerSummary(email) {
    const account = await getAccountByEmail(email);
    if (!account) {
        return null;
    }

    const [loyalty, orders, alerts, inbox, addresses, vouchers, auditLogs, sessions, tasteMemory] = await Promise.all([
        ensureLoyaltyAccount(email),
        ordersPayload(email),
        stockAlertsFor(email),
        alertInboxFor(email),
        addressesFor(email),
        allVouchersFor(email),
        adminAuditLogsFor(email),
        activeCustomerSessionsForEmail(email),
        tasteMemoryPayload(email)
    ]);

    return {
        profile: profilePayload(account),
        loyalty: loyaltyPayload(loyalty),
        orders,
        alerts,
        inbox,
        addresses,
        vouchers,
        tasteMemory,
        auditLogs,
        sessions,
        timeline: buildCustomerTimeline({
            account,
            loyalty,
            orders,
            vouchers,
            inbox,
            auditLogs,
            sessions,
            tasteMemory
        })
    };
}

async function adminCustomerDirectory() {
    const accounts = await allAccounts();
    const customers = await Promise.all(accounts.map(async (account) => {
        const [loyalty, orders, vouchers, alerts] = await Promise.all([
            ensureLoyaltyAccount(account.email),
            ordersPayload(account.email),
            allVouchersFor(account.email),
            stockAlertsFor(account.email)
        ]);

        return {
            id: account.id,
            email: account.email,
            firstName: account.firstName,
            lastName: account.lastName,
            createdAt: account.createdAt,
            isActive: account.isActive !== false,
            deactivatedAt: account.deactivatedAt || null,
            loyaltyTier: loyalty.tier,
            pointsBalance: loyalty.pointsBalance,
            hasActiveVoucher: vouchers.some((voucher) => voucher.status === "active"),
            hasOrders: orders.length > 0,
            hasStockAlerts: alerts.length > 0
        };
    }));

    return customers.sort((lhs, rhs) => new Date(rhs.createdAt).getTime() - new Date(lhs.createdAt).getTime());
}

function csvEscape(value) {
    const stringValue = String(value ?? "");
    return `"${stringValue.replace(/"/g, "\"\"")}"`;
}

function buildCustomerExportCSV(customers) {
    const headers = [
        "Email",
        "First Name",
        "Last Name",
        "Status",
        "Deactivated At",
        "Tier",
        "Beans",
        "Has Active Voucher",
        "Has Orders",
        "Has Stock Alerts",
        "Created At"
    ];

    const rows = customers.map((customer) => ([
        customer.email,
        customer.firstName || "",
        customer.lastName || "",
        customer.isActive === false ? "Deactivated" : "Active",
        customer.deactivatedAt || "",
        customer.loyaltyTier || "",
        customer.pointsBalance || 0,
        customer.hasActiveVoucher ? "Yes" : "No",
        customer.hasOrders ? "Yes" : "No",
        customer.hasStockAlerts ? "Yes" : "No",
        customer.createdAt || ""
    ].map(csvEscape).join(",")));

    return [headers.map(csvEscape).join(","), ...rows].join("\n");
}

const server = http.createServer(async (request, response) => {
    const startedAt = Date.now();
    response.on("finish", () => {
        void logRequest({
            request,
            statusCode: response.statusCode,
            startedAt,
            accountEmail: request.authenticatedCustomerEmail || null
        });
    });

    if (!request.url) {
        sendJSON(response, 400, { error: "Missing URL" });
        return;
    }

    if (!applyRateLimit(request, response)) {
        return;
    }

    if (request.method === "OPTIONS") {
        sendJSON(response, 204, {});
        return;
    }

    const url = new URL(request.url, `http://${host}:${port}`);

    if (request.method === "GET" && url.pathname === "/health") {
        sendJSON(response, 200, {
            status: "ok",
            appURL: config.appURL,
            host,
            port
        });
        return;
    }

    if (request.method === "GET" && url.pathname === "/password-reset") {
        sendHTML(response, 200, renderPasswordResetPage(url.searchParams.get("token") || ""));
        return;
    }

    if (request.method === "GET" && (url.pathname === "/admin" || url.pathname === "/admin/")) {
        if (!adminCredentialsConfigured()) {
            sendJSON(response, 503, { error: "Admin credentials are not configured." });
            return;
        }

        const adminPagePath = path.join(adminDirectory, "index.html");
        if (!fs.existsSync(adminPagePath)) {
            sendJSON(response, 404, { error: "Admin dashboard not found." });
            return;
        }

        sendHTML(response, 200, fs.readFileSync(adminPagePath, "utf8"));
        return;
    }

    if (request.method === "GET" && url.pathname === "/campaigns/eid") {
        sendJSON(response, 200, await getCampaignSettings());
        return;
    }

    if (request.method === "GET" && url.pathname === "/app/home-settings") {
        sendJSON(response, 200, await getHomeSettings());
        return;
    }

    if (request.method === "GET" && url.pathname === "/app/passport-settings") {
        sendJSON(response, 200, await getPassportSettings());
        return;
    }

    if (request.method === "POST" && ["/shopify/webhooks/orders", "/webhooks/shopify/orders-create"].includes(url.pathname)) {
        try {
            const rawBody = await readRawBody(request, 262_144);
            if (!verifyShopifyWebhook(rawBody, request.headers["x-shopify-hmac-sha256"])) {
                sendJSON(response, 401, { error: "Invalid Shopify webhook signature." });
                return;
            }

            const shopifyOrder = JSON.parse(rawBody.toString("utf8"));
            const topic = request.headers["x-shopify-topic"] || "";
            const result = await processShopifyOrderWebhook(shopifyOrder, topic);
            sendJSON(response, 200, result);
            if (result.eazyTallaPaymentId) {
                void ensureShopifyEazyInvoice(result.eazyTallaPaymentId).catch((error) => {
                    console.error(`[PAYMENT_FAILED] payment=${result.eazyTallaPaymentId} stage=invoice_background code=${error.code || error.message || "EAZY_CREATE_FAILED"}`);
                });
            }
        } catch (error) {
            const statusCode = error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : 400;
            sendJSON(response, statusCode, { error: statusCode === 413 ? "Shopify webhook payload is too large." : "Invalid Shopify webhook payload." });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/eazy/shopify/session") {
        try {
            const body = await readBody(request, 16_384);
            const authenticated = parseAuthenticatedCustomer(request, response);
            if (!authenticated) return;
            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) return;
            const tallaPaymentId = normalizeTallaPaymentID(body.tallaPaymentId);
            if (!tallaPaymentId) {
                sendJSON(response, 400, { error: "A valid Talla payment ID is required." });
                return;
            }
            const payment = await withShopifyEazyPaymentLock(tallaPaymentId, async () => {
                const existing = await findShopifyEazyPayment(tallaPaymentId);
                if (existing && existing.email !== normalizeEmail(customer.email)) {
                    throw eazyPay.paymentError("PAYMENT_OWNERSHIP_MISMATCH", 403, "This payment does not belong to the authenticated customer.");
                }
                return existing || persistShopifyEazyPayment({
                    tallaPaymentId,
                    email: customer.email,
                    status: "CREATED",
                    createdAt: new Date().toISOString()
                });
            });
            sendJSON(response, 201, publicShopifyEazyPayment(payment));
        } catch (error) {
            const statusCode = error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : (error.statusCode || 400);
            sendJSON(response, statusCode, { error: statusCode >= 500 ? "Payment setup is temporarily unavailable." : (error.message || "Invalid payment session request.") });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/api/payments/eazy/shopify/status") {
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const tallaPaymentId = normalizeTallaPaymentID(url.searchParams.get("tallaPaymentId"));
        if (!tallaPaymentId) {
            sendJSON(response, 400, { error: "A valid Talla payment ID is required." });
            return;
        }
        let payment = await findShopifyEazyPayment(tallaPaymentId);
        if (!payment) {
            sendJSON(response, 404, { error: "Payment was not found." });
            return;
        }
        if (payment.email !== normalizeEmail(customer.email)) {
            sendJSON(response, 403, { error: "This payment does not belong to the authenticated customer." });
            return;
        }
        try {
            if (!payment.eazyPaymentUrl && payment.shopifyOrderId && !["PAID", "CANCELLED"].includes(payment.status)) {
                payment = await ensureShopifyEazyInvoice(tallaPaymentId);
            }
            if (payment.eazyGlobalTransactionId && !["PAID", "CANCELLED"].includes(payment.status)) {
                payment = await confirmShopifyEazyPayment(tallaPaymentId);
            }
        } catch (error) {
            console.error(`[PAYMENT_FAILED] payment=${tallaPaymentId} stage=status_refresh code=${error.code || error.message || "PAYMENT_REFRESH_FAILED"}`);
            payment = await findShopifyEazyPayment(tallaPaymentId);
        }
        sendJSON(response, 200, publicShopifyEazyPayment(payment));
        return;
    }

    if (request.method === "POST" && url.pathname === "/webhooks/eazypay") {
        try {
            const rawBody = await readRawBody(request, 65_536);
            const text = rawBody.toString("utf8");
            let payload;
            if (String(request.headers["content-type"] || "").toLowerCase().includes("application/json")) {
                payload = JSON.parse(text);
            } else {
                payload = Object.fromEntries(new URLSearchParams(text).entries());
            }
            const globalTransactionId = eazyPay.extractGlobalTransactionID(payload);
            if (!globalTransactionId) {
                sendJSON(response, 400, { error: "A valid EazyPay transaction ID is required." });
                return;
            }
            const payment = await findShopifyEazyPaymentByGlobalTransactionID(globalTransactionId);
            if (!payment) {
                sendJSON(response, 400, { error: "Unknown EazyPay transaction." });
                return;
            }
            console.info(`[EAZYPAY_WEBHOOK_RECEIVED] payment=${payment.tallaPaymentId} transaction=${globalTransactionId}`);
            sendJSON(response, 200, { received: true });
            // TODO: Add EazyPay webhook signature verification when EazyPay supplies its header and signing specification.
            // The notification is never trusted as payment proof; confirmation always uses EazyPay's Query API below.
            void confirmShopifyEazyPayment(payment.tallaPaymentId).catch((error) => {
                console.error(`[PAYMENT_FAILED] payment=${payment.tallaPaymentId} stage=eazypay_query code=${error.code || error.message || "EAZY_QUERY_FAILED"}`);
            });
        } catch (error) {
            const statusCode = error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : 400;
            sendJSON(response, statusCode, { error: statusCode === 413 ? "EazyPay webhook payload is too large." : "Malformed EazyPay webhook." });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/admin/orders") {
        const admin = await ensureMobileAdminAccess(request, response);
        if (!admin) {
            return;
        }

        sendJSON(response, 200, await allOrdersPayload());
        return;
    }

    if (request.method === "POST" && url.pathname === "/admin/orders/status") {
        const admin = await ensureMobileAdminAccess(request, response);
        if (!admin) {
            return;
        }

        try {
            const body = await readBody(request);
            const orderID = String(body.orderID || body.id || "").trim();
            const status = normalizeOrderStatus(body.status);

            if (!orderID || !status) {
                sendJSON(response, 400, { error: "Provide an orderID and valid status." });
                return;
            }

            const order = await updateOrderStatusByID(orderID, status);
            if (!order) {
                sendJSON(response, 404, { error: "Order not found." });
                return;
            }

            await createAdminAuditLog({
                adminUser: admin.username,
                action: "mobile_order_status_updated",
                targetEmail: order.email,
                detail: `Updated order ${orderID} to ${status} from the app`,
                metadata: {
                    orderID,
                    status
                }
            });

            const pushResult = await sendOrderReadyPushIfNeeded(status, order);
            sendJSON(response, 200, { orders: await allOrdersPayload(), push: pushResult });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid order update payload." });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/admin/orders/notify-ready") {
        const admin = await ensureMobileAdminAccess(request, response);
        if (!admin) {
            return;
        }

        try {
            const body = await readBody(request);
            const orderID = String(body.orderID || body.id || "").trim();

            if (!orderID) {
                sendJSON(response, 400, { error: "Provide an orderID." });
                return;
            }

            const order = await findOrderByID(orderID);
            if (!order) {
                sendJSON(response, 404, { error: "Order not found." });
                return;
            }

            const pushResult = await sendOrderReadyPush(order.email, order);
            await createAdminAuditLog({
                adminUser: admin.username,
                action: "mobile_order_ready_notification_sent",
                targetEmail: order.email,
                detail: `Sent ready notification for order ${orderID}`,
                metadata: {
                    orderID,
                    configured: pushResult.configured,
                    targetCount: pushResult.targetCount,
                    sentCount: pushResult.sentCount
                }
            });

            sendJSON(response, 200, {
                status: "ok",
                order,
                push: pushResult
            });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid ready notification payload." });
        }
        return;
    }

    if (url.pathname.startsWith("/admin/api/")) {
        if (request.method === "GET" && url.pathname === "/admin/api/session") {
            if (!adminCredentialsConfigured()) {
                sendJSON(response, 503, { error: "Admin credentials are not configured." });
                return;
            }

            const session = getAdminSession(request);
            if (!session) {
                sendJSON(response, 200, { authenticated: false });
                return;
            }

            sendJSON(response, 200, {
                authenticated: true,
                username: session.username,
                expiresAt: new Date(session.expiresAt).toISOString()
            });
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/login") {
            try {
                const body = await readBody(request);
                const credentials = parseAdminLogin(body);
                if (credentials.username !== adminUsername || credentials.password !== adminPassword) {
                    sendJSON(response, 401, { error: "Invalid admin credentials." });
                    return;
                }

                const session = createAdminSession(credentials.username);
                sendJSON(response, 200, {
                    authenticated: true,
                    username: session.username,
                    expiresAt: new Date(session.expiresAt).toISOString()
                }, {
                    "Set-Cookie": session.cookie
                });
            } catch {
                sendJSON(response, 400, { error: "Invalid JSON body." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/logout") {
            const session = getAdminSession(request);
            if (session) {
                adminSessions.delete(session.id);
            }

            sendJSON(response, 200, { success: true }, {
                "Set-Cookie": clearAdminSessionCookie()
            });
            return;
        }

        const admin = ensureAdminAccess(request, response);
        if (!admin) {
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/customer") {
            const email = normalizeEmail(url.searchParams.get("email"));

            if (!email) {
                sendJSON(response, 400, { error: "Missing email." });
                return;
            }

            const summary = await adminCustomerSummary(email);
            if (!summary) {
                sendJSON(response, 404, { error: "Customer not found." });
                return;
            }

            sendJSON(response, 200, summary);
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/customers") {
            sendJSON(response, 200, {
                customers: await adminCustomerDirectory()
            });
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customers/export") {
            try {
                const body = await readBody(request);
                const emails = Array.isArray(body.emails)
                    ? [...new Set(body.emails.map((entry) => normalizeEmail(entry)).filter(Boolean))]
                    : [];

                if (emails.length === 0) {
                    sendJSON(response, 400, { error: "Provide one or more customer emails to export." });
                    return;
                }

                const directory = await adminCustomerDirectory();
                const customers = directory.filter((customer) => emails.includes(customer.email));
                const csv = buildCustomerExportCSV(customers);
                response.writeHead(200, {
                    "Content-Type": "text/csv; charset=utf-8",
                    "Content-Disposition": `attachment; filename="talla-customers-${new Date().toISOString().slice(0, 10)}.csv"`
                });
                response.end(csv);
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid export payload." });
            }
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/ops/summary") {
            sendJSON(response, 200, await adminOperationsSummary());
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/analytics/summary") {
            sendJSON(response, 200, await adminAnalyticsSummary());
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/audit/recent") {
            const limit = Number(url.searchParams.get("limit")) || 8;
            sendJSON(response, 200, { auditLogs: await recentAdminAuditLogs(limit) });
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/orders") {
            sendJSON(response, 200, { orders: await allOrdersPayload() });
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/taste-memory") {
            sendJSON(response, 200, { tasteMemory: await allTasteMemoryPayload() });
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/orders/status") {
            try {
                const body = await readBody(request);
                const orderID = String(body.orderID || body.id || "").trim();
                const status = normalizeOrderStatus(body.status);

                if (!orderID || !status) {
                    sendJSON(response, 400, { error: "Provide an orderID and valid status." });
                    return;
                }

                const order = await updateOrderStatusByID(orderID, status);
                if (!order) {
                    sendJSON(response, 404, { error: "Order not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "order_status_updated",
                    targetEmail: order.email,
                    detail: `Updated order ${orderID} to ${status}`,
                    metadata: {
                        orderID,
                        status
                    }
                });
                const pushResult = await sendOrderReadyPushIfNeeded(status, order);
                sendJSON(response, 200, { order, orders: await allOrdersPayload(), push: pushResult });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid order update payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/orders/notify-ready") {
            try {
                const body = await readBody(request);
                const orderID = String(body.orderID || body.id || "").trim();

                if (!orderID) {
                    sendJSON(response, 400, { error: "Provide an orderID." });
                    return;
                }

                const order = await findOrderByID(orderID);
                if (!order) {
                    sendJSON(response, 404, { error: "Order not found." });
                    return;
                }

                const pushResult = await sendOrderReadyPush(order.email, order);
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "order_ready_notification_sent",
                    targetEmail: order.email,
                    detail: `Sent ready notification for order ${orderID}`,
                    metadata: {
                        orderID,
                        configured: pushResult.configured,
                        targetCount: pushResult.targetCount,
                        sentCount: pushResult.sentCount
                    }
                });
                sendJSON(response, 200, { order, push: pushResult });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid ready notification payload." });
            }
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/campaigns/eid") {
            sendJSON(response, 200, await getCampaignSettings());
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/campaigns/eid") {
            try {
                const body = await readBody(request);
                const eidModeEnabled = Boolean(body.eidModeEnabled);
                const rawEndsAt = body.eidOfferEndsAt ? String(body.eidOfferEndsAt).trim() : "";
                const endsAtDate = rawEndsAt ? new Date(rawEndsAt) : null;

                if (rawEndsAt && !Number.isFinite(endsAtDate.getTime())) {
                    sendJSON(response, 400, { error: "Provide a valid Eid offer end date." });
                    return;
                }

                const settings = await saveCampaignSettings({
                    eidModeEnabled,
                    eidOfferEndsAt: endsAtDate ? endsAtDate.toISOString() : null
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "eid_campaign_updated",
                    targetEmail: null,
                    detail: `Eid campaign ${settings.eidModeEnabled ? "enabled" : "disabled"}`,
                    metadata: settings
                });

                sendJSON(response, 200, settings);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not save Eid campaign settings." });
            }
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/home/signature-roasts") {
            sendJSON(response, 200, await getHomeSettings());
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/passport-settings") {
            sendJSON(response, 200, await getPassportSettings());
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/passport-settings") {
            try {
                const body = await readBody(request);
                const settings = normalizePassportSettings({
                    origins: body.origins,
                    completionRewardTitle: body.completionRewardTitle,
                    completionRewardDetail: body.completionRewardDetail
                });
                const savedSettings = await savePassportSettings(settings);

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "passport_settings_updated",
                    targetEmail: null,
                    detail: "Updated Talla Passport settings",
                    metadata: savedSettings
                });

                sendJSON(response, 200, savedSettings);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not save passport settings." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/home/signature-roasts") {
            try {
                const body = await readBody(request);
                if (Array.isArray(body.signatureRoastProductIDs) && body.signatureRoastProductIDs.length > 4) {
                    sendJSON(response, 400, { error: "Choose up to four signature roasts." });
                    return;
                }

                const settings = normalizeHomeSettings({
                    signatureRoastProductIDs: body.signatureRoastProductIDs,
                    funPickProductID: body.funPickProductID,
                    heroEyebrow: body.heroEyebrow,
                    heroTitle: body.heroTitle,
                    heroSubtitle: body.heroSubtitle,
                    heroBadge: body.heroBadge,
                    primaryButtonTitle: body.primaryButtonTitle,
                    secondaryButtonTitle: body.secondaryButtonTitle
                });

                const savedSettings = await saveHomeSettings(settings);

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "signature_roasts_updated",
                    targetEmail: null,
                    detail: "Updated Home signature roasts",
                    metadata: savedSettings
                });

                sendJSON(response, 200, savedSettings);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not save signature roasts." });
            }
            return;
        }

        if (request.method === "GET" && url.pathname === "/admin/api/products") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            const limit = Math.min(Math.max(Number(url.searchParams.get("limit") || 250), 1), 250);
            sendJSON(response, 200, {
                products: await listShopifyAdminProducts(limit),
                publicationConfigured: Boolean(shopifyAdminPublicationID)
            });
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/products") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            try {
                const body = await readBody(request);
                const title = String(body.title || "").trim();
                const productType = String(body.productType || "").trim();
                const price = Number(body.price);

                if (!title || !productType || !Number.isFinite(price) || price < 0) {
                    sendJSON(response, 400, { error: "Provide a title, category, and valid non-negative price." });
                    return;
                }

                if (!approvedProductTypes.has(productType)) {
                    sendJSON(response, 400, { error: "Choose one of the approved product categories." });
                    return;
                }

                const result = await createShopifyAdminProduct({ title, productType, price });
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "product_created",
                    targetEmail: null,
                    detail: `Created product ${title}`,
                    metadata: {
                        productID: result.product?.id || null,
                        title,
                        productType,
                        price,
                        published: result.published
                    }
                });
                sendJSON(response, 200, {
                    product: result.product,
                    publicationConfigured: Boolean(shopifyAdminPublicationID),
                    published: result.published
                });
            } catch (error) {
                if (error.message === "SHOPIFY_ADMIN_NOT_CONFIGURED") {
                    sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                    return;
                }

                sendJSON(response, 400, { error: error.message || "Could not create product." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/products/update") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            try {
                const body = await readBody(request);
                const productID = String(body.id || "").trim();
                const title = String(body.title || "").trim();
                const productType = body.productType === undefined
                    ? undefined
                    : String(body.productType).trim();
                const descriptionHTML = body.descriptionHTML === undefined
                    ? undefined
                    : String(body.descriptionHTML);
                const status = body.status === undefined
                    ? undefined
                    : String(body.status || "").trim().toUpperCase();
                const badge = body.badge === undefined
                    ? undefined
                    : String(body.badge || "").trim().toUpperCase();
                const existingTags = Array.isArray(body.existingTags) ? body.existingTags : [];
                const tags = badge === undefined ? undefined : nextProductTags(existingTags, badge);
                const defaultVariantID = String(body.defaultVariantID || "").trim() || null;
                const hasPrice = body.price !== undefined && body.price !== null && String(body.price).trim() !== "";
                const price = hasPrice ? Number(body.price) : undefined;

                if (!productID || (!title && !hasPrice && descriptionHTML === undefined && productType === undefined && status === undefined && tags === undefined)) {
                    sendJSON(response, 400, { error: "Provide a product plus a field to update." });
                    return;
                }

                if (status !== undefined && !["ACTIVE", "DRAFT", "ARCHIVED"].includes(status)) {
                    sendJSON(response, 400, { error: "Product status must be Active, Draft, or Archived." });
                    return;
                }

                if (productType !== undefined && !approvedProductTypes.has(productType)) {
                    sendJSON(response, 400, { error: "Choose one of the approved product categories." });
                    return;
                }

                if (hasPrice && (!Number.isFinite(price) || price < 0)) {
                    sendJSON(response, 400, { error: "Price must be a valid non-negative number." });
                    return;
                }

                if (hasPrice && !defaultVariantID) {
                    sendJSON(response, 400, { error: "This product has no default variant available for pricing." });
                    return;
                }

                const product = await updateShopifyAdminProduct({
                    productID,
                    title: title || undefined,
                    productType,
                    descriptionHTML,
                    status,
                    tags,
                    defaultVariantID,
                    price
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "product_updated",
                    targetEmail: null,
                    detail: `Updated product ${product.title || productID}`,
                    metadata: {
                        productID,
                        title: title || null,
                        productType: productType === undefined ? null : productType,
                        descriptionUpdated: descriptionHTML !== undefined,
                        status: status || null,
                        badge: badge === undefined ? null : badge,
                        defaultVariantID,
                        price: hasPrice ? price : null
                    }
                });
                sendJSON(response, 200, { product });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not update product." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/products/image") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            try {
                const body = await readBody(request);
                const productID = String(body.id || "").trim();
                const imageURL = String(body.imageURL || "").trim();
                const altText = String(body.altText || "").trim();

                if (!productID || !imageURL) {
                    sendJSON(response, 400, { error: "Provide a product and image URL." });
                    return;
                }

                const product = await addShopifyProductImage({ productID, imageURL, altText });
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "product_image_added",
                    targetEmail: null,
                    detail: `Added image to product ${product.title || productID}`,
                    metadata: {
                        productID,
                        imageURL,
                        altText
                    }
                });
                sendJSON(response, 200, { product });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not add product image." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/products/inventory") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            try {
                const body = await readBody(request);
                const productID = String(body.id || "").trim();
                const inventoryItemID = String(body.inventoryItemID || "").trim();
                const locationID = String(body.locationID || "").trim();
                const compareQuantity = Number(body.compareQuantity);
                const quantity = Number(body.quantity);

                if (!productID || !inventoryItemID || !locationID || !Number.isFinite(quantity) || quantity < 0) {
                    sendJSON(response, 400, { error: "Provide a product and a valid inventory quantity." });
                    return;
                }

                await updateShopifyProductInventory({
                    inventoryItemID,
                    locationID,
                    quantity,
                    compareQuantity: Number.isFinite(compareQuantity) ? compareQuantity : 0
                });

                const product = (await listShopifyAdminProducts()).find((entry) => entry.id === productID) || null;
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "product_inventory_updated",
                    targetEmail: null,
                    detail: `Set inventory for product ${product?.title || productID} to ${quantity}`,
                    metadata: {
                        productID,
                        inventoryItemID,
                        locationID,
                        compareQuantity: Number.isFinite(compareQuantity) ? compareQuantity : 0,
                        quantity
                    }
                });
                sendJSON(response, 200, { product });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not update inventory." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/products/delete") {
            if (!shopifyAdminConfigured()) {
                sendJSON(response, 503, { error: "Shopify Admin API is not configured for product control." });
                return;
            }

            try {
                const body = await readBody(request);
                const productID = String(body.id || "").trim();
                if (!productID) {
                    sendJSON(response, 400, { error: "Missing product id." });
                    return;
                }

                await deleteShopifyAdminProduct(productID);
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "product_deleted",
                    targetEmail: null,
                    detail: `Deleted product ${productID}`,
                    metadata: { productID }
                });
                sendJSON(response, 200, { success: true, id: productID });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Could not delete product." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/update") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.currentEmail || body.email);
                const nextEmail = normalizeEmail(body.nextEmail || body.email);
                const firstName = String(body.firstName || "").trim();
                const lastName = String(body.lastName || "").trim();

                if (!email || !nextEmail || !firstName || !lastName) {
                    sendJSON(response, 400, { error: "Provide an email, first name, and last name." });
                    return;
                }

                const account = await updateAccountRecord(email, { nextEmail, firstName, lastName });
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "customer_profile_updated",
                    targetEmail: nextEmail,
                    detail: "Updated customer profile from admin",
                    metadata: {
                        previousEmail: email,
                        nextEmail,
                        firstName,
                        lastName
                    }
                });
                sendJSON(response, 200, { profile: profilePayload(account) });
            } catch (error) {
                if (error.message === "ACCOUNT_EMAIL_EXISTS") {
                    sendJSON(response, 409, { error: "That email is already in use." });
                    return;
                }
                sendJSON(response, 400, { error: "Invalid customer profile payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/send-reset") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);

                if (!email) {
                    sendJSON(response, 400, { error: "Provide a customer email." });
                    return;
                }

                if (!passwordResetEmailConfigured()) {
                    sendJSON(response, 503, { error: "Password reset email is not configured." });
                    return;
                }

                const account = await getAccountByEmail(email);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                const token = createPasswordResetToken();
                const tokenHash = hashPassword(token);
                const createdAt = new Date().toISOString();
                const expiresAt = new Date(Date.now() + (passwordResetTokenHours * 60 * 60 * 1000)).toISOString();

                await createPasswordResetTokenRecord({
                    email,
                    tokenHash,
                    createdAt,
                    expiresAt
                });
                await sendPasswordResetEmail(email, token);

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "password_reset_requested",
                    targetEmail: email,
                    detail: "Sent password reset email from admin",
                    metadata: { expiresAt }
                });

                sendJSON(response, 200, { status: "ok" });
            } catch (error) {
                console.error("Admin password reset request failed.", error);
                sendJSON(response, 500, { error: "Password reset email could not be sent." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/deactivate") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const nextState = body.isActive === undefined ? false : Boolean(body.isActive);

                if (!email) {
                    sendJSON(response, 400, { error: "Provide a customer email." });
                    return;
                }

                const account = await setAccountActiveState(email, nextState);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                if (!nextState) {
                    await revokeCustomerSessionsForEmail(email);
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: nextState ? "customer_reactivated" : "customer_deactivated",
                    targetEmail: email,
                    detail: nextState ? "Reactivated customer account" : "Deactivated customer account",
                    metadata: { isActive: nextState }
                });

                sendJSON(response, 200, { profile: profilePayload(account) });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid account state payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/delete") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);

                if (!email) {
                    sendJSON(response, 400, { error: "Provide a customer email." });
                    return;
                }

                await revokeCustomerSessionsForEmail(email);
                const deleted = await deleteAccountRecord(email);
                if (!deleted) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "customer_deleted",
                    targetEmail: email,
                    detail: "Deleted customer account and related local records",
                    metadata: { email }
                });
                sendJSON(response, 200, { success: true, email });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid account delete payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/session/revoke") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const sessionID = String(body.sessionID || "").trim();

                if (!email || !sessionID) {
                    sendJSON(response, 400, { error: "Provide a customer email and session id." });
                    return;
                }

                const revoked = await revokeCustomerSessionByID(email, sessionID);
                if (!revoked) {
                    sendJSON(response, 404, { error: "Active session not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "customer_session_revoked",
                    targetEmail: email,
                    detail: "Revoked customer session",
                    metadata: { sessionID }
                });

                sendJSON(response, 200, { session: revoked });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid session revoke payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/address/save") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const label = String(body.label || "").trim();
                const fullName = String(body.fullName || "").trim();
                const phone = String(body.phone || "").trim();
                const line1 = String(body.line1 || "").trim();
                const city = String(body.city || "").trim();
                const notes = body.notes ? String(body.notes).trim() : null;
                const addressID = body.addressID ? String(body.addressID).trim() : null;
                const isPreferred = Boolean(body.isPreferred);

                if (!email || !label || !fullName || !phone || !line1 || !city) {
                    sendJSON(response, 400, { error: "Provide a complete address payload." });
                    return;
                }

                const account = await getAccountByEmail(email);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                const addresses = await saveAddress(email, {
                    id: addressID,
                    label,
                    fullName,
                    phone,
                    line1,
                    city,
                    notes,
                    isPreferred
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: addressID ? "customer_address_updated" : "customer_address_created",
                    targetEmail: email,
                    detail: addressID ? `Updated address ${label}` : `Created address ${label}`,
                    metadata: {
                        addressID,
                        label,
                        fullName,
                        phone,
                        line1,
                        city,
                        hasNotes: Boolean(notes),
                        isPreferred
                    }
                });
                sendJSON(response, 200, { addresses });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid address payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customer/address/delete") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const addressID = String(body.addressID || "").trim();

                if (!email || !addressID) {
                    sendJSON(response, 400, { error: "Provide a customer email and address id." });
                    return;
                }

                const account = await getAccountByEmail(email);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                const addresses = await deleteAddress(email, addressID);
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "customer_address_deleted",
                    targetEmail: email,
                    detail: "Deleted customer address",
                    metadata: { addressID }
                });
                sendJSON(response, 200, { addresses });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid address delete payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/orders/update") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const orderID = String(body.id || "").trim();
                const status = normalizeOrderStatus(body.status);

                if (!email || !orderID || !status) {
                    sendJSON(response, 400, { error: "Provide an email, order, and valid status." });
                    return;
                }

                const order = await updateOrderStatusAndAward(email, orderID, status);
                if (!order) {
                    sendJSON(response, 404, { error: "Order not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "order_status_updated",
                    targetEmail: email,
                    detail: `Updated order ${orderID} to ${status}`,
                    metadata: {
                        orderID,
                        status
                    }
                });
                const pushResult = await sendOrderReadyPushIfNeeded(status, order);
                sendJSON(response, 200, { order, push: pushResult });
            } catch (error) {
                sendJSON(response, 400, { error: "Invalid order update payload." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/vouchers/create") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const reward = String(body.reward || "").trim();
                const detail = String(body.detail || "").trim();
                const points = Number(body.points);
                const expiresInDays = Number(body.expiresInDays);

                if (!email || !reward || !Number.isFinite(points) || points <= 0 || !Number.isFinite(expiresInDays) || expiresInDays <= 0) {
                    sendJSON(response, 400, { error: "Provide email, reward, positive points, and expiry days." });
                    return;
                }

                const account = await getAccountByEmail(email);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                const voucher = await createAdminVoucherRecord({ email, reward, points, detail, expiresInDays });
                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "voucher_created",
                    targetEmail: email,
                    detail: `Created voucher ${voucher.code}`,
                    metadata: {
                        code: voucher.code,
                        reward,
                        points,
                        expiresInDays
                    }
                });
                sendJSON(response, 200, { voucher });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Voucher creation failed." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/customers/bulk-voucher") {
            try {
                const body = await readBody(request);
                const emails = Array.isArray(body.emails)
                    ? body.emails.map((entry) => normalizeEmail(entry)).filter(Boolean)
                    : [];
                const reward = String(body.reward || "").trim();
                const detail = String(body.detail || "").trim();
                const points = Number(body.points);
                const expiresInDays = Number(body.expiresInDays);

                if (emails.length === 0 || !reward || !Number.isFinite(points) || points <= 0 || !Number.isFinite(expiresInDays) || expiresInDays <= 0) {
                    sendJSON(response, 400, { error: "Provide customer emails, reward, positive points, and expiry days." });
                    return;
                }

                const uniqueEmails = [...new Set(emails)];
                const created = [];

                for (const email of uniqueEmails) {
                    const account = await getAccountByEmail(email);
                    if (!account) {
                        continue;
                    }

                    const voucher = await createAdminVoucherRecord({ email, reward, points, detail, expiresInDays });
                    created.push({ email, code: voucher.code });

                    await createAdminAuditLog({
                        adminUser: admin.username,
                        action: "bulk_voucher_created",
                        targetEmail: email,
                        detail: `Granted bulk voucher ${voucher.code}`,
                        metadata: {
                            reward,
                            points,
                            expiresInDays
                        }
                    });
                }

                sendJSON(response, 200, {
                    created,
                    requestedCount: uniqueEmails.length,
                    createdCount: created.length
                });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Bulk voucher creation failed." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/notifications/eid") {
            try {
                const body = await readBody(request);
                const title = String(body.title || "Eid Mubarak from Talla").trim();
                const message = String(body.body || "Eid Gifts and limited rewards are now available in the app.").trim();

                if (!title || !message) {
                    sendJSON(response, 400, { error: "Provide a notification title and message." });
                    return;
                }

                const result = await sendCampaignPushToAll({
                    title,
                    body: message,
                    type: "eid_campaign"
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "eid_push_sent",
                    targetEmail: null,
                    detail: `Sent Eid push campaign to ${result.sentCount}/${result.targetCount} devices`,
                    metadata: {
                        title,
                        message,
                        configured: result.configured,
                        targetCount: result.targetCount,
                        sentCount: result.sentCount
                    }
                });

                sendJSON(response, 200, result);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Eid push campaign failed." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/notifications/push/send-all") {
            try {
                const body = await readBody(request);
                const title = String(body.title || "").trim();
                const message = String(body.body || "").trim();
                const deepLinkURL = String(body.url || "").trim();

                if (!title || !message) {
                    sendJSON(response, 400, { error: "Provide a notification title and message." });
                    return;
                }

                if (title.length > 120 || message.length > 220) {
                    sendJSON(response, 400, { error: "Keep the title under 120 characters and message under 220 characters." });
                    return;
                }

                const result = await sendCampaignPushToAll({
                    title,
                    body: message,
                    type: "customer_campaign",
                    url: deepLinkURL || null
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "customer_push_sent",
                    targetEmail: null,
                    detail: `Sent customer push campaign to ${result.sentCount}/${result.targetCount} devices`,
                    metadata: {
                        title,
                        message,
                        url: deepLinkURL || null,
                        configured: result.configured,
                        targetCount: result.targetCount,
                        sentCount: result.sentCount
                    }
                });

                sendJSON(response, 200, result);
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Customer push campaign failed." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/vouchers/revoke") {
            try {
                const body = await readBody(request);
                const code = String(body.code || "").trim();
                if (!code) {
                    sendJSON(response, 400, { error: "Provide a voucher code." });
                    return;
                }

                const voucher = await revokeVoucherRecord(code);
                if (!voucher) {
                    sendJSON(response, 404, { error: "Active voucher not found." });
                    return;
                }

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "voucher_revoked",
                    targetEmail: voucher.email,
                    detail: `Revoked voucher ${code}`,
                    metadata: {
                        code,
                        reward: voucher.reward,
                        previousStatus: "active"
                    }
                });
                sendJSON(response, 200, { voucher });
            } catch (error) {
                sendJSON(response, 400, { error: error.message || "Voucher revoke failed." });
            }
            return;
        }

        if (request.method === "POST" && url.pathname === "/admin/api/loyalty/adjust") {
            try {
                const body = await readBody(request);
                const email = normalizeEmail(body.email);
                const points = Number(body.points);
                const note = String(body.note || "Admin adjustment").trim() || "Admin adjustment";

                if (!email || !Number.isFinite(points) || points === 0) {
                    sendJSON(response, 400, { error: "Invalid loyalty adjustment payload." });
                    return;
                }

                const account = await getAccountByEmail(email);
                if (!account) {
                    sendJSON(response, 404, { error: "Customer not found." });
                    return;
                }

                await ensureLoyaltyAccount(email);
                const updated = await updateLoyaltyAccount(email, (loyaltyAccount) => {
                    const nextBalance = loyaltyAccount.pointsBalance + points;
                    if (nextBalance < 0) {
                        throw new Error("INSUFFICIENT_POINTS");
                    }

                    loyaltyAccount.pointsBalance = nextBalance;
                    loyaltyAccount.transactions = loyaltyAccount.transactions || [];
                    loyaltyAccount.transactions.unshift({
                        id: `txn_${Date.now()}`,
                        type: points > 0 ? "earn" : "redeem",
                        points: Math.abs(points),
                        note,
                        createdAt: new Date().toISOString()
                    });
                });

                await createAdminAuditLog({
                    adminUser: admin.username,
                    action: "loyalty_adjustment",
                    targetEmail: email,
                    detail: `${points > 0 ? "Added" : "Removed"} ${Math.abs(points)} Beans`,
                    metadata: {
                        points,
                        note,
                        resultingBalance: updated.pointsBalance
                    }
                });

                sendJSON(response, 200, {
                    profile: profilePayload(account),
                    loyalty: loyaltyPayload(updated)
                });
            } catch (error) {
                if (error.message === "INSUFFICIENT_POINTS") {
                    sendJSON(response, 409, { error: "Adjustment would result in negative Beans." });
                    return;
                }

                sendJSON(response, 400, { error: "Invalid JSON body." });
            }
            return;
        }

        sendJSON(response, 404, { error: "Admin route not found." });
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/register") {
        try {
            const body = await readBody(request);
            const email = normalizeEmail(body.email);
            const firstName = String(body.firstName || "").trim();
            const lastName = String(body.lastName || "").trim();
            const password = String(body.password || "");

            if (!email || !firstName || !lastName || password.length < 5) {
                sendJSON(response, 400, { error: "Invalid account payload" });
                return;
            }

            const existingAccount = await getAccountByEmail(email);
            if (existingAccount) {
                sendJSON(response, 409, { error: "Account already exists" });
                return;
            }

            const account = {
                id: `acct_${Date.now()}`,
                firstName,
                lastName,
                email,
                passwordHash: hashPassword(password),
                createdAt: new Date().toISOString()
            };

            await createAccountRecord(account);
            await ensureLoyaltyAccount(email);
            const session = await createCustomerSession(email);
            sendJSON(response, 201, {
                profile: profilePayload(account),
                accessToken: session.accessToken,
                expiresAt: session.expiresAt
            });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/login") {
        try {
            const body = await readBody(request);
            const email = normalizeEmail(body.email);
            const password = String(body.password || "");

            if (!email || !password) {
                sendJSON(response, 400, { error: "Missing email or password" });
                return;
            }

            const account = await getAccountByEmail(email);

            if (!account || account.passwordHash !== hashPassword(password)) {
                sendJSON(response, 401, { error: "Invalid email or password" });
                return;
            }

            if (account.isActive === false) {
                sendJSON(response, 403, { error: "Account is deactivated" });
                return;
            }

            await ensureLoyaltyAccount(email);
            const session = await createCustomerSession(email);
            sendJSON(response, 200, {
                profile: profilePayload(account),
                accessToken: session.accessToken,
                expiresAt: session.expiresAt
            });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/apple") {
        try {
            const body = await readBody(request);
            const identityToken = String(body.identityToken || "");
            const userIdentifier = String(body.userIdentifier || "").trim();
            const nonce = String(body.nonce || "");
            const fallbackEmail = normalizeEmail(body.email);
            const firstName = String(body.firstName || "").trim();
            const lastName = String(body.lastName || "").trim();

            if (!identityToken || !userIdentifier || !nonce) {
                sendJSON(response, 400, { error: "Invalid Apple sign-in payload" });
                return;
            }

            const claims = await verifyAppleIdentityToken(identityToken, nonce);
            if (claims.sub !== userIdentifier) {
                sendJSON(response, 401, { error: "Apple identity mismatch" });
                return;
            }

            const claimedEmail = normalizeEmail(claims.email);
            const email = claimedEmail || fallbackEmail;
            if (!email) {
                sendJSON(response, 400, { error: "Apple sign-in did not return an email address" });
                return;
            }

            let account = await getAccountByAppleUserID(userIdentifier);
            if (!account) {
                account = await getAccountByEmail(email);
                if (account) {
                    account = await linkAppleUserIDToAccount(account.email, userIdentifier);
                }
            }

            const hasProvidedName = Boolean(firstName || lastName);
            const accountUsesApplePlaceholder = account
                && account.firstName === "Apple"
                && account.lastName === "Customer";

            if (account && hasProvidedName && accountUsesApplePlaceholder) {
                account = await updateAccountProfileRecord(
                    account.email,
                    firstName || "",
                    lastName || ""
                );
            }

            if (!account) {
                account = {
                    id: `acct_${Date.now()}`,
                    firstName: firstName || "",
                    lastName: lastName || "",
                    email,
                    passwordHash: hashPassword(`apple:${userIdentifier}:${Date.now()}:${crypto.randomBytes(12).toString("hex")}`),
                    appleUserID: userIdentifier,
                    createdAt: new Date().toISOString()
                };

                await createAccountRecord(account);
            }

            if (account.isActive === false) {
                sendJSON(response, 403, { error: "Account is deactivated" });
                return;
            }

            await ensureLoyaltyAccount(account.email);
            const session = await createCustomerSession(account.email);
            sendJSON(response, 200, {
                profile: profilePayload(account),
                accessToken: session.accessToken,
                expiresAt: session.expiresAt
            });
        } catch (error) {
            console.error("Apple sign-in failed.", error);
            sendJSON(response, 401, { error: "Apple sign-in could not be verified" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/accounts/session") {
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const account = await getAccountByEmail(customer.email);
        if (!account) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, profilePayload(account));
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/logout") {
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        await revokeCustomerSession(authenticated.token);
        sendJSON(response, 200, { status: "ok" });
        return;
    }

    if (request.method === "GET" && url.pathname === "/accounts/profile") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const account = await getAccountByEmail(customer.email);

        if (!account) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, profilePayload(account));
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/profile/update") {
        try {
            const body = await readBody(request);
            const firstName = String(body.firstName || "").trim();
            const lastName = String(body.lastName || "").trim();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!firstName || !lastName) {
                sendJSON(response, 400, { error: "Invalid profile payload" });
                return;
            }

            const account = await updateAccountProfileRecord(customer.email, firstName, lastName);

            if (!account) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }
            sendJSON(response, 200, profilePayload(account));
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/password/request-reset") {
        try {
            const body = await readBody(request);
            const email = normalizeEmail(body.email);

            if (!email) {
                sendJSON(response, 400, { error: "Invalid password reset payload" });
                return;
            }

            if (!passwordResetEmailConfigured()) {
                sendJSON(response, 503, { error: "Password reset email is not configured" });
                return;
            }

            const account = await getAccountByEmail(email);
            if (account) {
                const token = createPasswordResetToken();
                const tokenHash = hashPassword(token);
                const createdAt = new Date().toISOString();
                const expiresAt = new Date(Date.now() + (passwordResetTokenHours * 60 * 60 * 1000)).toISOString();

                await createPasswordResetTokenRecord({
                    email,
                    tokenHash,
                    createdAt,
                    expiresAt
                });
                await sendPasswordResetEmail(email, token);
            }

            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            console.error("Password reset email request failed.", error);
            sendJSON(response, 500, { error: "Password reset email could not be sent" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/accounts/password/reset-token/validate") {
        const token = String(url.searchParams.get("token") || "");
        if (!token) {
            sendJSON(response, 400, { error: "Missing reset token" });
            return;
        }

        if (await passwordResetTokenIsValid(hashPassword(token))) {
            sendJSON(response, 200, { status: "ok" });
            return;
        }

        sendJSON(response, 410, { error: "This password reset link is invalid or expired" });
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/password/complete-reset") {
        try {
            const body = await readBody(request);
            const token = String(body.token || "");
            const newPassword = String(body.newPassword || "");

            if (!token || newPassword.length < 5) {
                sendJSON(response, 400, { error: "Invalid password payload" });
                return;
            }

            const resetRecord = await consumePasswordResetTokenRecord(hashPassword(token));
            if (!resetRecord) {
                sendJSON(response, 410, { error: "This password reset link is invalid or expired" });
                return;
            }

            const account = await updateAccountPasswordRecord(resetRecord.email, hashPassword(newPassword));
            if (!account) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            await revokeCustomerSessionsForEmail(resetRecord.email);
            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/password/reset") {
        try {
            const body = await readBody(request);
            const currentPassword = String(body.currentPassword || "");
            const newPassword = String(body.newPassword || "");
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!currentPassword || newPassword.length < 5) {
                sendJSON(response, 400, { error: "Invalid password payload" });
                return;
            }

            const account = await getAccountByEmail(customer.email);

            if (!account) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            if (account.passwordHash !== hashPassword(currentPassword)) {
                sendJSON(response, 401, { error: "Current password is incorrect" });
                return;
            }

            await updateAccountPasswordRecord(customer.email, hashPassword(newPassword));
            await revokeCustomerSessionsForEmail(customer.email);
            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/accounts/password/change") {
        try {
            const body = await readBody(request);
            const email = normalizeEmail(body.email);
            const currentPassword = String(body.currentPassword || "");
            const newPassword = String(body.newPassword || "");

            if (!email || !currentPassword || newPassword.length < 5) {
                sendJSON(response, 400, { error: "Invalid password payload" });
                return;
            }

            const account = await getAccountByEmail(email);

            if (!account) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            if (account.passwordHash !== hashPassword(currentPassword)) {
                sendJSON(response, 401, { error: "Current password is incorrect" });
                return;
            }

            await updateAccountPasswordRecord(email, hashPassword(newPassword));
            await revokeCustomerSessionsForEmail(email);
            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/loyalty/account") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        const account = await ensureLoyaltyAccount(customer.email);
        sendJSON(response, 200, loyaltyPayload(account));
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/apple-pay/session") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const localOrderID = normalizeCardPaymentIdentifier(body.orderID || body.orderId || body.localOrderId);
        if (!localOrderID) {
            sendJSON(response, 400, { error: "Provide a valid existing orderID." });
            return;
        }
        try {
            const result = await withCardPaymentLock(`${customer.email}:${localOrderID}`, async () => {
                const order = await findOrderByID(localOrderID);
                const existingPayment = await findPendingCardPayment(localOrderID, customer.email);
                if (existingPayment && existingPayment.paymentMethod !== "APPLE_PAY") {
                    throw benefitPaymentError("MPGS_PAYMENT_METHOD_CONFLICT", 409, "Another payment method is already pending for this order.");
                }
                return mpgsGateway.initializeMpgsPayment({
                    configuration: mpgsConfiguration,
                    order,
                    customerEmail: customer.email,
                    existingPayment,
                    paymentMethod: "APPLE_PAY",
                    persistPayment: persistCardPayment
                });
            });
            console.info(`MPGS Apple Pay session prepared: ${maskMpgsSessionID(result.payment.sessionID)}.`);
            sendJSON(response, 200, mpgsSessionResponse(result.payment));
        } catch (error) {
            console.error("MPGS Apple Pay session creation failed:", error.code || "MPGS_APPLE_SESSION_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && [
        "/api/payments/apple-pay/authorize",
        "/payments/apple-pay/authorize"
    ].includes(url.pathname)) {
        let body;
        let paymentForFailure = null;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        if (body.paymentTokenData || body.paymentData || body.token) {
            sendJSON(response, 400, { error: "Apple Pay tokens must be stored in the Mastercard SDK session, not sent to Talla." });
            return;
        }
        const localOrderID = normalizeCardPaymentIdentifier(body.localOrderId || body.orderID || body.orderId);
        const sessionID = normalizeCardPaymentIdentifier(body.sessionId, 100);
        if (!localOrderID || !sessionID) {
            sendJSON(response, 400, { error: "Provide a valid orderID and SDK-created sessionId." });
            return;
        }
        try {
            const payment = await findCardPayment(localOrderID, customer.email);
            paymentForFailure = payment;
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            if (payment.paymentMethod !== "APPLE_PAY" || !timingSafeStringEqual(sessionID, payment.sessionID)) {
                throw benefitPaymentError("MPGS_SESSION_MISMATCH", 409, "Apple Pay session does not match this order.");
            }
            if (payment.effectsAppliedAt) {
                sendJSON(response, 200, { status: "succeeded", orderId: payment.mpgsOrderID, duplicate: true });
                return;
            }
            const purchaseTransactionID = payment.purchaseTransactionID || createMpgsTransactionID("APAY");
            await updateCardPaymentLifecycle(payment.paymentID, { purchaseTransactionID, status: "Processing" });
            const purchaseResponse = await mpgsGateway.executeMpgsPurchase(mpgsConfiguration, {
                orderId: payment.mpgsOrderID,
                transactionId: purchaseTransactionID,
                sessionId: payment.sessionID,
                amount: payment.amount,
                walletProvider: "APPLE_PAY"
            });
            mpgsGateway.assertMpgsPaymentAccepted(purchaseResponse);
            const gatewayOrder = await mpgsGateway.retrieveMpgsOrder(mpgsConfiguration, payment.mpgsOrderID);
            const applied = await applyConfirmedMpgsPayment(payment.paymentID, gatewayOrder);
            console.info(`MPGS Apple Pay confirmed for order ${localOrderID}: applied=${applied.applied}.`);
            sendJSON(response, 200, { status: "succeeded", orderId: payment.mpgsOrderID, duplicate: !applied.applied });
        } catch (error) {
            if (paymentForFailure && Number(error.statusCode) === 402) {
                try {
                    await updateCardPaymentLifecycle(paymentForFailure.paymentID, { status: "Declined" });
                } catch (storageError) {
                    console.error("MPGS Apple Pay decline could not be recorded:", storageError.code || "MPGS_STORAGE_FAILED");
                }
            }
            console.error(
                "MPGS Apple Pay completion failed:",
                error.code || "MPGS_APPLE_PAY_FAILED",
                mpgsGateway.mpgsErrorLogDetails(error)
            );
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/session") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }

        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }
        const localOrderID = normalizeCardPaymentIdentifier(body.orderID || body.orderId || body.localOrderId);
        if (!localOrderID) {
            sendJSON(response, 400, { error: "Provide a valid existing orderID." });
            return;
        }

        try {
            const result = await withCardPaymentLock(`${customer.email}:${localOrderID}`, async () => {
                const order = await findOrderByID(localOrderID);
                const existingPayment = await findPendingCardPayment(localOrderID, customer.email);
                if (existingPayment && existingPayment.paymentMethod !== "CARD") {
                    throw benefitPaymentError("MPGS_PAYMENT_METHOD_CONFLICT", 409, "Another payment method is already pending for this order.");
                }
                return mpgsGateway.initializeMpgsPayment({
                    configuration: mpgsConfiguration,
                    order,
                    customerEmail: customer.email,
                    existingPayment,
                    persistPayment: persistCardPayment
                });
            });
            console.info(
                `MPGS card session ${result.reused ? "reused" : "created"} for order ${localOrderID}: ${maskMpgsSessionID(result.payment.sessionID)}.`
            );
            sendJSON(response, 200, mpgsSessionResponse(result.payment));
        } catch (error) {
            console.error(`MPGS card session creation failed for order ${localOrderID}:`, error.code || "MPGS_SESSION_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/session/retrieve") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }
        const identifier = normalizeCardPaymentIdentifier(
            body.paymentSessionId || body.localOrderId || body.orderID || body.orderId
        );
        if (!identifier) {
            sendJSON(response, 400, { error: "Provide a valid orderID or paymentSessionId." });
            return;
        }

        try {
            const payment = await findCardPayment(identifier, customer.email);
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            const gatewaySession = await mpgsGateway.retrieveMpgsSession(mpgsConfiguration, payment.sessionID);
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email, gatewaySession);
            await updateCardPaymentSessionVersion(payment.paymentID, gatewaySession.session.version);
            console.info(`MPGS card session retrieved: ${maskMpgsSessionID(payment.sessionID)}.`);
            sendJSON(response, 200, sanitizedMpgsSessionStatus(payment, gatewaySession));
        } catch (error) {
            console.error("MPGS card session retrieval failed:", error.code || "MPGS_RETRIEVE_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/authentication/initiate") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const localOrderID = normalizeCardPaymentIdentifier(body.localOrderId || body.orderID || body.orderId);
        const sessionID = normalizeCardPaymentIdentifier(body.sessionId, 100);
        if (!localOrderID || !sessionID) {
            sendJSON(response, 400, { error: "Provide a valid orderID and sessionId." });
            return;
        }
        try {
            const payment = await findCardPayment(localOrderID, customer.email);
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            if (payment.paymentMethod !== "CARD" || !timingSafeStringEqual(sessionID, payment.sessionID)) {
                throw benefitPaymentError("MPGS_SESSION_MISMATCH", 409, "Card payment session does not match.");
            }
            if (body.sdkManaged === true) {
                const requestedTransactionID = normalizeCardPaymentIdentifier(body.transactionId, 40);
                if (!requestedTransactionID) {
                    sendJSON(response, 400, { error: "Provide a valid SDK authentication transactionId." });
                    return;
                }
                const transactionID = payment.authenticationTransactionID || requestedTransactionID;
                if (payment.authenticationTransactionID
                    && !timingSafeStringEqual(payment.authenticationTransactionID, requestedTransactionID)) {
                    console.info(`MPGS SDK authentication reused for order ${localOrderID}.`);
                }
                await updateCardPaymentLifecycle(payment.paymentID, {
                    authenticationTransactionID: transactionID,
                    status: "Authenticating",
                    lastGatewayResponseAt: new Date().toISOString()
                });
                sendJSON(response, 200, {
                    authenticationTransactionId: transactionID,
                    sdkManaged: true
                });
                return;
            }
            const transactionID = payment.authenticationTransactionID || createMpgsTransactionID("AUTH");
            const gatewayResponse = await mpgsGateway.initiateMpgsAuthentication(mpgsConfiguration, {
                orderId: payment.mpgsOrderID,
                transactionId: transactionID,
                sessionId: payment.sessionID
            });
            await updateCardPaymentLifecycle(payment.paymentID, {
                authenticationTransactionID: transactionID,
                gatewayResult: String(gatewayResponse.result || "UNKNOWN"),
                status: "Authenticating",
                lastGatewayResponseAt: new Date().toISOString()
            });
            sendJSON(response, 200, {
                authenticationTransactionId: transactionID,
                recommendation: String(gatewayResponse.response?.gatewayRecommendation || "UNKNOWN"),
                gatewayResult: String(gatewayResponse.result || "UNKNOWN")
            });
        } catch (error) {
            console.error("MPGS authentication initiation failed:", error.code || "MPGS_AUTH_INIT_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/authentication/complete") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const localOrderID = normalizeCardPaymentIdentifier(body.localOrderId || body.orderID || body.orderId);
        const sessionID = normalizeCardPaymentIdentifier(body.sessionId, 100);
        if (!localOrderID || !sessionID) {
            sendJSON(response, 400, { error: "Provide a valid orderID and sessionId." });
            return;
        }
        try {
            const payment = await findCardPayment(localOrderID, customer.email);
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            if (!payment.authenticationTransactionID || !timingSafeStringEqual(sessionID, payment.sessionID)) {
                throw benefitPaymentError("MPGS_AUTHENTICATION_REQUIRED", 409, "Payer authentication was not initiated.");
            }
            const gatewayResponse = await mpgsGateway.authenticateMpgsPayer(mpgsConfiguration, {
                orderId: payment.mpgsOrderID,
                transactionId: payment.authenticationTransactionID,
                sessionId: payment.sessionID,
                amount: payment.amount
            });
            const authenticationOutcome = mpgsGateway.normalizeMpgsAuthenticationOutcome(gatewayResponse);
            await updateCardPaymentLifecycle(payment.paymentID, {
                gatewayResult: authenticationOutcome.result,
                gatewayTransactionResult: authenticationOutcome.transactionStatus,
                status: authenticationOutcome.successful
                    ? "Authenticated"
                    : authenticationOutcome.challengeRequired
                        ? "AwaitingChallenge"
                        : authenticationOutcome.cancelled ? "Cancelled" : "AuthenticationFailed",
                lastGatewayResponseAt: new Date().toISOString()
            });
            sendJSON(response, authenticationOutcome.successful ? 200 : authenticationOutcome.challengeRequired ? 202 : 402, {
                authenticated: authenticationOutcome.successful,
                challengeRequired: authenticationOutcome.challengeRequired,
                cancelled: authenticationOutcome.cancelled,
                transactionStatus: authenticationOutcome.transactionStatus,
                recommendation: String(gatewayResponse.response?.gatewayRecommendation || "UNKNOWN"),
                ...(authenticationOutcome.challengeRequired ? { redirectHtml: authenticationOutcome.redirectHTML } : {})
            });
        } catch (error) {
            console.error("MPGS payer authentication failed:", error.code || "MPGS_AUTH_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/order/retrieve") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const identifier = normalizeCardPaymentIdentifier(body.paymentSessionId || body.localOrderId || body.orderID || body.orderId);
        if (!identifier) {
            sendJSON(response, 400, { error: "Provide a valid orderID or paymentSessionId." });
            return;
        }
        try {
            const payment = await findCardPayment(identifier, customer.email);
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            const gatewayOrder = await mpgsGateway.retrieveMpgsOrder(mpgsConfiguration, payment.mpgsOrderID);
            let confirmed = false;
            try {
                verifyConfirmedMpgsOrder(payment, order, gatewayOrder);
                confirmed = true;
            } catch (error) {
                if (error.code !== "MPGS_PAYMENT_NOT_APPROVED") throw error;
            }
            sendJSON(response, 200, {
                paymentSessionId: payment.paymentID,
                orderId: payment.mpgsOrderID,
                status: confirmed ? "Captured" : payment.status,
                confirmed,
                amount: payment.amount,
                currency: "BHD"
            });
        } catch (error) {
            console.error("MPGS order retrieval failed:", error.code || "MPGS_ORDER_RETRIEVE_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/card/complete") {
        let body;
        let paymentForFailure = null;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) {
            return;
        }
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }
        const localOrderID = normalizeCardPaymentIdentifier(body.localOrderId || body.orderID || body.orderId);
        const sessionID = normalizeCardPaymentIdentifier(body.sessionId, 100);
        if (!localOrderID || !sessionID) {
            sendJSON(response, 400, { error: "Provide a valid orderID and sessionId." });
            return;
        }

        try {
            const payment = await findCardPayment(localOrderID, customer.email);
            paymentForFailure = payment;
            const order = payment ? await findOrderByID(payment.localOrderID) : null;
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email);
            if (!timingSafeStringEqual(sessionID, payment.sessionID)) {
                sendJSON(response, 409, { error: "Card payment session does not match this order." });
                return;
            }
            const gatewaySession = await mpgsGateway.retrieveMpgsSession(mpgsConfiguration, payment.sessionID);
            mpgsGateway.verifyMpgsOrderPayment(payment, order, customer.email, gatewaySession);
            await updateCardPaymentSessionVersion(payment.paymentID, gatewaySession.session.version);
            const authenticationOrder = await mpgsGateway.retrieveMpgsOrder(mpgsConfiguration, payment.mpgsOrderID);
            verifyMpgsAuthenticationForPurchase(payment, authenticationOrder);
            if (payment.effectsAppliedAt) {
                sendJSON(response, 200, { status: "succeeded", orderId: payment.mpgsOrderID, duplicate: true });
                return;
            }
            const purchaseTransactionID = payment.purchaseTransactionID || createMpgsTransactionID("PAY");
            await updateCardPaymentLifecycle(payment.paymentID, {
                purchaseTransactionID,
                status: "Processing"
            });
            const purchaseResponse = await mpgsGateway.executeMpgsPurchase(mpgsConfiguration, {
                orderId: payment.mpgsOrderID,
                transactionId: purchaseTransactionID,
                authenticationTransactionId: payment.authenticationTransactionID,
                sessionId: payment.sessionID,
                amount: payment.amount
            });
            mpgsGateway.assertMpgsPaymentAccepted(purchaseResponse);
            const gatewayOrder = await mpgsGateway.retrieveMpgsOrder(mpgsConfiguration, payment.mpgsOrderID);
            const applied = await applyConfirmedMpgsPayment(payment.paymentID, gatewayOrder);
            console.info(`MPGS card payment confirmed for order ${localOrderID}: applied=${applied.applied}.`);
            sendJSON(response, 200, {
                status: "succeeded",
                orderId: payment.mpgsOrderID,
                duplicate: !applied.applied
            });
        } catch (error) {
            if (paymentForFailure && Number(error.statusCode) === 402) {
                try {
                    await updateCardPaymentLifecycle(paymentForFailure.paymentID, { status: "Declined" });
                } catch (storageError) {
                    console.error("MPGS card decline could not be recorded:", storageError.code || "MPGS_STORAGE_FAILED");
                }
            }
            console.error(
                "MPGS completion verification failed:",
                error.code || "MPGS_COMPLETE_FAILED",
                mpgsGateway.mpgsErrorLogDetails(error)
            );
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/click-to-pay/create") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const localOrderID = normalizeCardPaymentIdentifier(body.orderID || body.orderId || body.localOrderId);
        if (!localOrderID) {
            sendJSON(response, 400, { error: "Provide a valid existing orderID." });
            return;
        }
        try {
            const result = await withCardPaymentLock(`${customer.email}:${localOrderID}`, async () => {
                const order = await findOrderByID(localOrderID);
                if (!order) throw benefitPaymentError("MPGS_ORDER_NOT_FOUND", 404, "Order not found.");
                if (!timingSafeStringEqual(normalizeEmail(order.email), normalizeEmail(customer.email))) {
                    throw benefitPaymentError("MPGS_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
                }
                const existing = await findPendingCardPayment(localOrderID, customer.email);
                if (existing) {
                    throw benefitPaymentError("MPGS_PAYMENT_ALREADY_PENDING", 409, "A payment is already pending for this order.");
                }
                const amount = mpgsGateway.orderAmount(order);
                const identifiers = mpgsGateway.createMpgsIdentifiers();
                const resultToken = crypto.randomBytes(24).toString("base64url");
                const returnURL = publicPaymentURL("/api/payments/click-to-pay/return", resultToken);
                const cancelURL = publicPaymentURL("/api/payments/click-to-pay/return", resultToken, { cancelled: 1 });
                const gatewaySession = await mpgsGateway.initiateMpgsCheckout(mpgsConfiguration, {
                    orderId: identifiers.mpgsOrderID,
                    amount,
                    returnUrl: returnURL,
                    cancelUrl: cancelURL
                });
                const timestamp = new Date().toISOString();
                const payment = await persistCardPayment({
                    paymentID: identifiers.paymentID,
                    localOrderID,
                    mpgsOrderID: identifiers.mpgsOrderID,
                    sessionID: gatewaySession.session.id,
                    sessionVersion: String(gatewaySession.session.version),
                    amount,
                    currency: "BHD",
                    email: customer.email,
                    paymentMethod: "CLICK_TO_PAY",
                    resultTokenHash: sha256Hex(resultToken),
                    successIndicatorHash: sha256Hex(String(gatewaySession.successIndicator || "")),
                    gatewayResult: String(gatewaySession.result || "SUCCESS"),
                    status: "Pending",
                    createdAt: timestamp,
                    updatedAt: timestamp
                });
                return { payment, resultToken };
            });
            console.info(`MPGS Click to Pay session prepared: ${maskMpgsSessionID(result.payment.sessionID)}.`);
            sendJSON(response, 200, {
                paymentUrl: publicPaymentURL("/api/payments/click-to-pay/launch", result.resultToken),
                orderId: result.payment.mpgsOrderID,
                amount: result.payment.amount,
                currency: "BHD"
            });
        } catch (error) {
            console.error("MPGS Click to Pay creation failed:", error.code || "MPGS_CLICK_TO_PAY_FAILED");
            const publicError = mpgsGateway.normalizeMpgsError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/api/payments/click-to-pay/launch") {
        try {
            const resultToken = normalizeCardPaymentIdentifier(url.searchParams.get("payment"), 200);
            const payment = await findCardPaymentByResultToken(resultToken);
            if (!payment || payment.paymentMethod !== "CLICK_TO_PAY") {
                sendHTML(response, 404, renderMpgsResultPage("failure"), { "Cache-Control": "no-store" });
                return;
            }
            sendHTML(response, 200, renderClickToPayLaunch(payment, resultToken), {
                "Cache-Control": "no-store",
                "Referrer-Policy": "no-referrer",
                "X-Content-Type-Options": "nosniff"
            });
        } catch (error) {
            console.error("MPGS Click to Pay launch failed:", error.code || "MPGS_CLICK_LAUNCH_FAILED");
            sendHTML(response, 503, renderMpgsResultPage("failure"), { "Cache-Control": "no-store" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/api/payments/click-to-pay/return") {
        const resultToken = normalizeCardPaymentIdentifier(url.searchParams.get("payment"), 200);
        const cancelled = url.searchParams.get("cancelled") === "1";
        const errored = url.searchParams.get("error") === "1";
        const timedOut = url.searchParams.get("timeout") === "1";
        const resultIndicator = url.searchParams.get("resultIndicator")
            || url.searchParams.get("resultindicator");
        const returnedSessionVersion = String(url.searchParams.get("sessionVersion") || "").trim();
        let state = cancelled ? "cancelled" : errored ? "failure" : "pending";
        try {
            const payment = await findCardPaymentByResultToken(resultToken);
            if (!payment || payment.paymentMethod !== "CLICK_TO_PAY") {
                state = "failure";
            } else if (cancelled || errored || timedOut) {
                await updateCardPaymentLifecycle(payment.paymentID, {
                    status: cancelled ? "Cancelled" : errored ? "Failed" : "Pending",
                    lastGatewayResponseAt: new Date().toISOString(),
                    sessionVersion: returnedSessionVersion || null
                });
                state = cancelled ? "cancelled" : errored ? "failure" : "pending";
            } else if (!mpgsResultIndicatorMatches(payment, resultIndicator)) {
                console.warn("MPGS Click to Pay result indicator did not match.");
                state = "failure";
            } else {
                const order = await findOrderByID(payment.localOrderID);
                mpgsGateway.verifyMpgsOrderPayment(payment, order, payment.email);
                const gatewayOrder = await mpgsGateway.retrieveMpgsOrder(mpgsConfiguration, payment.mpgsOrderID);
                try {
                    const applied = await applyConfirmedMpgsPayment(payment.paymentID, gatewayOrder);
                    console.info(`MPGS Click to Pay confirmed: applied=${applied.applied}.`);
                    state = "success";
                } catch (error) {
                    if (error.code !== "MPGS_PAYMENT_NOT_APPROVED") throw error;
                    await updateCardPaymentLifecycle(payment.paymentID, {
                        status: cancelled ? "Cancelled" : errored ? "Failed" : "Pending",
                        gatewayResult: String(gatewayOrder.result || "UNKNOWN"),
                        lastGatewayResponseAt: new Date().toISOString()
                    });
                }
            }
        } catch (error) {
            console.error(
                "MPGS Click to Pay verification failed:",
                error.code || "MPGS_CLICK_VERIFY_FAILED",
                mpgsGateway.mpgsErrorLogDetails(error)
            );
            state = cancelled ? "cancelled" : errored ? "failure" : "pending";
        }
        sendHTML(response, 200, renderMpgsResultPage(state), {
            "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; form-action 'none'",
            "Cache-Control": "no-store",
            "Referrer-Policy": "no-referrer",
            "X-Content-Type-Options": "nosniff"
        });
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/benefitpay/session") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            sendJSON(response, error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : 400, { error: "Invalid request." });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const orderID = normalizeBenefitIdentifier(body.orderID || body.orderId);
        if (!orderID) {
            sendJSON(response, 400, { error: "Provide a valid existing orderID." });
            return;
        }
        try {
            if (!benefitPayConfigured()) {
                throw benefitPaymentError("BENEFITPAY_NOT_CONFIGURED", 503, "BenefitPay is not configured.");
            }
            const order = await findOrderByID(orderID);
            if (!order) {
                throw benefitPaymentError("BENEFITPAY_ORDER_NOT_FOUND", 404, "Order not found.");
            }
            if (!timingSafeStringEqual(normalizeEmail(order.email), normalizeEmail(customer.email))) {
                throw benefitPaymentError("BENEFITPAY_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
            }
            if (orderCurrency(order) !== "BHD") {
                throw benefitPaymentError("BENEFITPAY_CURRENCY_MISMATCH", 409, "The stored order currency is not BHD.");
            }
            const totalFils = bhdFils(numericOrderTotal(order));
            if (totalFils === null || totalFils <= 0) {
                throw benefitPaymentError("BENEFITPAY_AMOUNT_INVALID", 409, "The stored order does not have a valid payable total.");
            }
            const amount = (totalFils / 1000).toFixed(3);
            const referenceID = createBenefitPayReferenceID();
            const paymentToken = crypto.randomBytes(24).toString("base64url");
            await createBenefitPendingPayment({
                trackID: referenceID,
                orderID,
                email: customer.email,
                amount,
                currency: "BHD",
                resultTokenHash: sha256Hex(paymentToken),
                createdAt: new Date().toISOString()
            });
            console.info(`BenefitPay SDK session prepared for order ${orderID}.`);
            sendJSON(response, 200, {
                appId: benefitPayConfiguration.appID,
                merchantId: benefitPayConfiguration.merchantID,
                merchantName: normalizeBenefitPayMPQRText(benefitPayConfiguration.merchantName, 25),
                merchantCity: normalizeBenefitPayMPQRText(benefitPayConfiguration.merchantCity, 15),
                merchantCategoryCode: benefitPayConfiguration.merchantCategoryCode,
                countryCode: benefitPayConfiguration.countryCode,
                currencyCode: "048",
                amount,
                referenceId: referenceID,
                callbackTag: "tallabenefitpay",
                paymentToken,
                orderId: orderID
            });
        } catch (error) {
            console.error("BenefitPay SDK session creation failed:", error.code || "BENEFITPAY_SESSION_FAILED");
            const publicError = benefitPublicError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/api/payments/benefitpay/confirm") {
        let body;
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            sendJSON(response, error.code === "REQUEST_BODY_TOO_LARGE" ? 413 : 400, { error: "Invalid request." });
            return;
        }
        const authenticated = parseAuthenticatedCustomer(request, response);
        if (!authenticated) return;
        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) return;
        const orderID = normalizeBenefitIdentifier(body.orderID || body.orderId);
        const referenceID = normalizeBenefitIdentifier(body.referenceID || body.referenceId);
        const paymentToken = normalizeBenefitIdentifier(body.paymentToken, 255);
        if (!orderID || !referenceID || !paymentToken) {
            sendJSON(response, 400, { error: "Provide a valid BenefitPay payment reference." });
            return;
        }
        try {
            if (!benefitPayConfigured()) {
                throw benefitPaymentError("BENEFITPAY_NOT_CONFIGURED", 503, "BenefitPay is not configured.");
            }
            const payment = await findBenefitPaymentByTrackID(referenceID);
            const order = payment ? await findOrderByID(payment.orderID) : null;
            if (!payment || !order || !timingSafeStringEqual(payment.orderID, orderID)) {
                throw benefitPaymentError("BENEFITPAY_PAYMENT_NOT_FOUND", 404, "BenefitPay payment was not found.");
            }
            if (!timingSafeStringEqual(normalizeEmail(payment.email), normalizeEmail(customer.email))) {
                throw benefitPaymentError("BENEFITPAY_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
            }
            if (!timingSafeStringEqual(sha256Hex(paymentToken), payment.resultTokenHash)) {
                throw benefitPaymentError("BENEFITPAY_TOKEN_MISMATCH", 409, "BenefitPay payment reference does not match.");
            }
            const transaction = await queryBenefitPayTransaction(referenceID);
            const isPaid = String(transaction.status || "").toLowerCase() === "success";
            const notification = {
                trackID: referenceID,
                orderID,
                resultToken: paymentToken,
                amount: String(transaction.amount || ""),
                currency: String(transaction.currency || "").toUpperCase(),
                result: isPaid ? "CAPTURED" : "NOT CAPTURED",
                paymentID: String(transaction.transaction_receipt || transaction.reference_number || ""),
                transactionID: String(transaction.reference_number || transaction.transaction_receipt || ""),
                referenceID: String(transaction.reference_number || ""),
                authCode: String(transaction.authorization_code || ""),
                authResponseCode: isPaid ? "00" : "",
                errorCode: String(transaction.error_code || ""),
                errorText: String(transaction.error_description || "")
            };
            verifyBenefitNotification(payment, order, notification);
            await recordBenefitNotification(
                payment,
                notification,
                sha256Hex(JSON.stringify({ referenceID, status: notification.result }))
            );
            const result = await withBenefitPaymentLock(
                referenceID,
                () => applyBenefitNotification(referenceID, notification)
            );
            console.info(`BenefitPay transaction confirmed for order ${orderID}: applied=${result.applied}.`);
            sendJSON(response, 200, {
                status: isPaid ? "succeeded" : "failed",
                orderId: orderID,
                duplicate: isPaid && !result.applied
            });
        } catch (error) {
            console.error("BenefitPay transaction confirmation failed:", error.code || "BENEFITPAY_CONFIRM_FAILED");
            const publicError = benefitPublicError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && benefitPathMatches(url.pathname, "/api/payments/benefit/create")) {
        let body;
        let pendingTrackID = "";
        try {
            body = await readBody(request, 16_384);
        } catch (error) {
            const publicError = benefitPublicError(error);
            sendJSON(response, publicError.statusCode === 413 ? 413 : 400, { error: publicError.message });
            return;
        }

        try {
            const authenticated = parseAuthenticatedCustomer(request, response);
            if (!authenticated) {
                return;
            }
            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const orderID = normalizeBenefitIdentifier(body.orderID || body.orderId || body.invoiceId);
            if (!orderID) {
                sendJSON(response, 400, { error: "Provide a valid existing orderID." });
                return;
            }
            if (!benefitConfigured()) {
                console.error("BENEFIT payment creation is unavailable because required configuration is missing.");
                sendJSON(response, 503, { error: "BENEFIT checkout is not configured." });
                return;
            }

            const order = await findOrderByID(orderID);
            if (!order) {
                throw benefitPaymentError("BENEFIT_ORDER_NOT_FOUND", 404, "Order not found.");
            }
            if (!timingSafeStringEqual(normalizeEmail(order.email), normalizeEmail(customer.email))) {
                throw benefitPaymentError("BENEFIT_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
            }
            if (orderCurrency(order) !== "BHD") {
                throw benefitPaymentError("BENEFIT_CURRENCY_MISMATCH", 409, "The stored order currency is not BHD.");
            }
            const total = numericOrderTotal(order);
            const totalFils = bhdFils(total);
            if (totalFils === null || totalFils <= 0) {
                throw benefitPaymentError("BENEFIT_AMOUNT_INVALID", 409, "The stored order does not have a valid payable total.");
            }

            const endpointURL = safeConfiguredBenefitURL(benefitAPIEndpoint, "BENEFIT API endpoint");
            const notificationURL = safeConfiguredBenefitURL(
                benefitNotificationURL,
                "BENEFIT notification URL",
                "/api/payments/benefit/response"
            ).toString();
            const amount = (totalFils / 1000).toFixed(3);
            const trackID = `T${Date.now()}${crypto.randomBytes(10).toString("hex")}`;
            pendingTrackID = trackID;
            const resultToken = crypto.randomBytes(24).toString("base64url");
            const createdAt = new Date().toISOString();
            await createBenefitPendingPayment({
                trackID,
                orderID,
                email: customer.email,
                amount,
                currency: "BHD",
                resultTokenHash: sha256Hex(resultToken),
                createdAt
            });

            const requestPlaintext = benefitGateway.buildBenefitRequestPlaintext({
                amount,
                tranportalID: benefitTranportalID,
                tranportalPassword: benefitTranportalPassword,
                resourceKey: benefitResourceKey,
                trackID,
                responseURL: notificationURL,
                errorURL: notificationURL,
                orderID,
                resultToken
            });
            const encryptedTransactionData = benefitGateway.encryptBenefitPayload(
                requestPlaintext,
                benefitResourceKey
            );
            const upstreamResponse = await fetch(endpointURL, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Accept: "application/json",
                    charset: "utf8"
                },
                body: benefitGateway.buildBenefitAPIRequestBody(
                    benefitTranportalID,
                    encryptedTransactionData
                ),
                signal: AbortSignal.timeout(15_000)
            });
            const responseText = await upstreamResponse.text();
            if (responseText.length > 131_072) {
                throw benefitPaymentError("BENEFIT_INVALID_RESPONSE", 502, "BENEFIT returned an invalid response.");
            }
            let upstreamPayload;
            try {
                upstreamPayload = JSON.parse(responseText);
            } catch (error) {
                throw benefitPaymentError("BENEFIT_INVALID_RESPONSE", 502, "BENEFIT returned an invalid response.");
            }
            const result = Array.isArray(upstreamPayload) ? upstreamPayload[0] : upstreamPayload;
            if (!upstreamResponse.ok || String(result?.status || "") !== "1" || !result?.result) {
                throw benefitPaymentError("BENEFIT_INITIATION_FAILED", 502, "BENEFIT could not create the hosted payment.");
            }
            const paymentURL = validateBenefitHostedPaymentURL(result.result);
            await updateBenefitPaymentInitiation(trackID, paymentURL, "Initiated");
            console.info(`BENEFIT payment initiated for order ${orderID} with track ${trackID}.`);
            sendJSON(response, 200, {
                paymentUrl: paymentURL,
                trackId: trackID
            });
        } catch (error) {
            if (pendingTrackID) {
                try {
                    await updateBenefitPaymentInitiation(pendingTrackID, null, "InitiationFailed");
                } catch (storageError) {
                    console.error(
                        `BENEFIT initiation failure could not be recorded for track ${pendingTrackID}:`,
                        storageError.code || "BENEFIT_STORAGE_FAILED"
                    );
                }
            }
            console.error("BENEFIT payment initiation failed:", error.code || "BENEFIT_INITIATION_FAILED");
            const publicError = benefitPublicError(error);
            sendJSON(response, publicError.statusCode, { error: publicError.message });
        }
        return;
    }

    if (request.method === "POST" && benefitPathMatches(url.pathname, "/api/payments/benefit/response")) {
        let fallbackErrorURL;
        try {
            fallbackErrorURL = benefitResultURL(benefitErrorURL);
        } catch (error) {
            sendJSON(response, 503, { error: "BENEFIT callback is not configured." });
            return;
        }

        let notification;
        let payment;
        try {
            const rawBody = await readRawBody(request, 65_536);
            const callback = parseBenefitCallbackRequest(rawBody, request.headers["content-type"]);
            if (callback.trandata) {
                const decrypted = benefitGateway.decryptBenefitPayload(callback.trandata, benefitResourceKey);
                const record = benefitGateway.parseBenefitNotificationPlaintext(decrypted);
                notification = benefitGateway.normalizeBenefitNotification(record);
            } else {
                notification = benefitGateway.normalizeBenefitNotification(callback);
            }

            notification.trackID = normalizeBenefitIdentifier(notification.trackID);
            notification.resultToken = normalizeBenefitIdentifier(notification.resultToken, 200);
            if (!notification.trackID) {
                throw benefitPaymentError("BENEFIT_TRACK_MISSING", 400, "BENEFIT callback is missing a track ID.");
            }
            payment = await findBenefitPaymentByTrackID(notification.trackID);
            const order = payment ? await findOrderByID(payment.orderID) : null;
            verifyBenefitNotification(payment, order, notification);
            const notificationHash = crypto.createHash("sha256").update(rawBody).digest("hex");
            await recordBenefitNotification(payment, notification, notificationHash);

            const isCaptured = notification.result === "CAPTURED"
                && notification.authResponseCode === "00"
                && !notification.errorCode;
            const redirectURL = benefitResultURL(
                isCaptured ? benefitSuccessURL : benefitErrorURL,
                notification.resultToken
            );
            sendBenefitRedirectAcknowledgement(response, redirectURL);
            console.info(
                `BENEFIT notification recorded for track ${notification.trackID}: result=${notification.result || "ERROR"}.`
            );
            setImmediate(() => {
                void withBenefitPaymentLock(
                    notification.trackID,
                    () => applyBenefitNotification(notification.trackID, notification)
                ).then((result) => {
                    console.info(
                        `BENEFIT notification processed for track ${notification.trackID}: applied=${result.applied}.`
                    );
                }).catch((error) => {
                    console.error(
                        `BENEFIT notification processing failed for track ${notification.trackID}:`,
                        error.code || "BENEFIT_PROCESSING_FAILED"
                    );
                });
            });
        } catch (error) {
            console.error(
                `BENEFIT notification rejected${notification?.trackID ? ` for track ${notification.trackID}` : ""}:`,
                error.code || "BENEFIT_CALLBACK_INVALID"
            );
            sendBenefitRedirectAcknowledgement(response, fallbackErrorURL);
        }
        return;
    }

    if (request.method === "GET" && isBenefitBrowserReturnPath(url.pathname)) {
        const htmlHeaders = benefitResultPageHeaders();
        try {
            const payment = await findBenefitPaymentForBrowserReturn(url);
            sendHTML(response, 200, renderBenefitResultPage(payment), htmlHeaders);
        } catch (error) {
            console.error("BENEFIT browser return failed:", error.code || error.message || "BENEFIT_BROWSER_RETURN_FAILED");
            sendHTML(response, 200, renderBenefitResultPage(null), htmlHeaders);
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/") {
        const htmlHeaders = benefitResultPageHeaders();
        try {
            const payment = await findBenefitPaymentForBrowserReturn(url);
            sendHTML(response, 200, renderBenefitResultPage(payment), htmlHeaders);
        } catch (error) {
            console.error("BENEFIT root return page failed:", error.code || error.message || "BENEFIT_ROOT_RETURN_FAILED");
            sendHTML(response, 200, renderBenefitResultPage(null), htmlHeaders);
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/orders") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        try {
            await syncRecentShopifyOrdersForEmail(customer.email);
        } catch (error) {
            console.warn(`Shopify order sync skipped for ${customer.email}:`, error.message);
        }

        const customerOrders = await ordersPayload(customer.email);
        customerOrders
            .filter((order) => completedOrderStatuses().has(order.status))
            .forEach((order) => queueShopifyOrderExport(order.id));
        sendJSON(response, 200, customerOrders);
        return;
    }

    if (request.method === "GET" && url.pathname === "/taste-memory") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        sendJSON(response, 200, await tasteMemoryPayload(customer.email));
        return;
    }

    if (request.method === "POST" && url.pathname === "/taste-memory/save") {
        try {
            const body = await readBody(request);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const record = await saveTasteMemoryRecord(customer.email, body);
            if (!record) {
                sendJSON(response, 400, { error: "Invalid taste memory payload." });
                return;
            }

            sendJSON(response, 200, {
                record,
                tasteMemory: await tasteMemoryPayload(customer.email)
            });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid taste memory payload." });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/orders/checkout-started") {
        try {
            const body = await readBody(request);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const submittedItems = Array.isArray(body.items) ? body.items : [];
            const items = submittedItems
                .map((item) => {
                    const variantID = String(item.variantId || item.variantID || "").trim();
                    return {
                        name: String(item.name || "Item").trim() || "Item",
                        quantity: Math.max(1, Math.round(Number(item.quantity || 1))),
                        ...(variantID.startsWith("gid://shopify/ProductVariant/") ? { variantId: variantID } : {})
                    };
                })
                .slice(0, 30);

            if (items.length === 0) {
                sendJSON(response, 400, { error: "Order items are required." });
                return;
            }

            const totalNumber = Number(body.total);
            const safeTotal = Number.isFinite(totalNumber) && totalNumber >= 0 ? totalNumber : 0;
            const pendingOrder = {
                id: `checkout_${Date.now()}`,
                email: customer.email,
                title: String(body.title || "Checkout started").trim() || "Checkout started",
                total: `BHD ${safeTotal.toFixed(3)}`,
                totalNumber: safeTotal,
                status: "Pending",
                items,
                createdAt: new Date().toISOString()
            };

            await upsertOrderRecord(pendingOrder);
            sendJSON(response, 200, {
                orderID: pendingOrder.id,
                orders: await ordersPayload(customer.email)
            });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid checkout order." });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/alerts") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, await stockAlertsFor(customer.email));
        return;
    }

    if (request.method === "GET" && url.pathname === "/alerts/inbox") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, await alertInboxFor(customer.email));
        return;
    }

    if (request.method === "POST" && url.pathname === "/notifications/push/register") {
        try {
            const body = await readBody(request);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const deviceToken = normalizeDeviceToken(body.deviceToken);
            const platform = String(body.platform || "ios").trim().toLowerCase() || "ios";
            if (!deviceToken) {
                sendJSON(response, 400, { error: "Invalid push device token" });
                return;
            }

            const device = await registerPushDevice(customer.email, deviceToken, platform);
            sendJSON(response, 200, { status: "ok", device });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/notifications/push/unregister") {
        try {
            const body = await readBody(request);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const deviceToken = normalizeDeviceToken(body.deviceToken);
            if (!deviceToken) {
                sendJSON(response, 400, { error: "Invalid push device token" });
                return;
            }

            await unregisterPushDevice(customer.email, deviceToken);
            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/alerts/watch") {
        try {
            const body = await readBody(request);
            const productID = String(body.productID || "").trim();
            const productName = String(body.productName || "").trim();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!productID || !productName) {
                sendJSON(response, 400, { error: "Invalid alert payload" });
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const record = await upsertStockAlert(customer.email, {
                productID,
                productName,
                tag: body.tag ? String(body.tag).trim() : null,
                isAvailableForSale: Boolean(body.isAvailableForSale)
            });

            sendJSON(response, 200, record);
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/alerts/unwatch") {
        try {
            const body = await readBody(request);
            const productID = String(body.productID || "").trim();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!productID) {
                sendJSON(response, 400, { error: "Invalid alert payload" });
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            await removeStockAlert(customer.email, productID);
            sendJSON(response, 200, { status: "ok" });
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/alerts/sync") {
        try {
            const body = await readBody(request);
            const alerts = Array.isArray(body.alerts) ? body.alerts : [];
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const synced = await syncStockAlerts(
                customer.email,
                alerts
                    .map((alert) => ({
                        productID: String(alert.productID || "").trim(),
                        productName: String(alert.productName || "").trim(),
                        tag: alert.tag ? String(alert.tag).trim() : null,
                        isAvailableForSale: Boolean(alert.isAvailableForSale)
                    }))
                    .filter((alert) => alert.productID && alert.productName)
            );

            sendJSON(response, 200, synced);
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/orders/sample") {
        try {
            const body = await readBody(request);
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            const newOrder = {
                id: `ord_${Date.now()}`,
                title: "Roastery Order",
                total: `BHD ${sampleOrderTotal.toFixed(3)}`,
                status: "Completed",
                items: sampleOrderItems,
                createdAt: new Date().toISOString()
            };

            let orders;
            if (database.isEnabled()) {
                await database.query(
                    `INSERT INTO orders
                     (id, email, title, total, status, items, created_at)
                     VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7)`,
                    [newOrder.id, customer.email, newOrder.title, newOrder.total, newOrder.status, JSON.stringify(newOrder.items), newOrder.createdAt]
                );
                orders = await ordersPayload(customer.email);
            } else {
                const store = readJSON(ordersStorePath);
                orders = store.orders[customer.email] || [];
                orders.unshift(newOrder);
                store.orders[customer.email] = orders;
                writeJSON(ordersStorePath, store);
            }

            const awardedPoints = Math.round(sampleOrderTotal * loyaltyPointsPerBHD);
            await updateLoyaltyAccount(customer.email, (account) => {
                account.pointsBalance += awardedPoints;
                account.transactions = account.transactions || [];
                account.transactions.unshift({
                    id: `txn_${Date.now()}`,
                    type: "earn",
                    points: awardedPoints,
                    note: `Completed order • ${awardedPoints} Beans • BHD ${sampleOrderTotal.toFixed(3)}`,
                    createdAt: new Date().toISOString()
                });
            });

            sendJSON(response, 200, orders);
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/addresses") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, await addressesFor(customer.email));
        return;
    }

    if (request.method === "POST" && url.pathname === "/addresses/save") {
        try {
            const body = await readBody(request);
            const label = String(body.label || "").trim();
            const fullName = String(body.fullName || "").trim();
            const phone = String(body.phone || "").trim();
            const line1 = String(body.line1 || "").trim();
            const city = String(body.city || "").trim();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!label || !fullName || !phone || !line1 || !city) {
                sendJSON(response, 400, { error: "Invalid address payload" });
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            sendJSON(response, 200, await saveAddress(customer.email, {
                label,
                fullName,
                phone,
                line1,
                city,
                notes: body.notes ? String(body.notes).trim() : null
            }));
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/addresses/delete") {
        try {
            const body = await readBody(request);
            const addressID = String(body.addressID || "").trim();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!addressID) {
                sendJSON(response, 400, { error: "Invalid address payload" });
                return;
            }

            const customerAccount = await getAccountByEmail(customer.email);
            if (!customerAccount) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            sendJSON(response, 200, await deleteAddress(customer.email, addressID));
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/wallet/pass") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        const customerAccount = await getAccountByEmail(customer.email);
        if (!customerAccount) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        try {
            const generatedPass = await generateWalletPass(customer.email);

            response.writeHead(200, {
                "Content-Type": "application/vnd.apple.pkpass",
                "Content-Length": fs.statSync(generatedPass.path).size,
                "Access-Control-Allow-Origin": "*"
            });

            const stream = fs.createReadStream(generatedPass.path);
            stream.on("close", () => generatedPass.cleanup());
            stream.on("error", () => generatedPass.cleanup());
            stream.pipe(response);
        } catch (error) {
            sendJSON(response, 500, { error: error.message || "Could not generate Wallet pass" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/loyalty/transactions/earn") {
        try {
            const body = await readBody(request);
            const points = Number(body.points);
            const note = String(body.note || "Beans adjustment");
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!Number.isFinite(points) || points <= 0) {
                sendJSON(response, 400, { error: "Invalid earn payload" });
                return;
            }

            const updated = await updateLoyaltyAccount(customer.email, (account) => {
                account.pointsBalance += points;
                account.transactions = account.transactions || [];
                account.transactions.unshift({
                    id: `txn_${Date.now()}`,
                    type: "earn",
                    points,
                    note,
                    createdAt: new Date().toISOString()
                });
            });

            if (!updated) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            sendJSON(response, 200, loyaltyPayload(updated));
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/loyalty/transactions/redeem") {
        try {
            const body = await readBody(request);
            const points = Number(body.points);
            const reward = String(body.reward || "Reward redemption");
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!Number.isFinite(points) || points <= 0) {
                sendJSON(response, 400, { error: "Invalid redemption payload" });
                return;
            }

            const updated = await updateLoyaltyAccount(customer.email, (account) => {
                if (account.pointsBalance < points) {
                    throw new Error("INSUFFICIENT_POINTS");
                }

                account.pointsBalance -= points;
                account.transactions = account.transactions || [];
                const voucher = buildVoucherRecord(customer.email, reward, points);
                void storeVoucherRecord(voucher);
                account.transactions.unshift({
                    id: `txn_${Date.now()}`,
                    type: "redeem",
                    points,
                    note: reward,
                    voucherCode: voucher.code,
                    voucherDetail: voucher.detail,
                    voucherExpiresAt: voucher.expiresAt,
                    voucherSingleUse: voucher.singleUse,
                    voucherStatus: voucher.status,
                    createdAt: new Date().toISOString()
                });
            });

            if (!updated) {
                sendJSON(response, 404, { error: "Account not found" });
                return;
            }

            sendJSON(response, 200, loyaltyPayload(updated));
        } catch (error) {
            if (error.message === "INSUFFICIENT_POINTS") {
                sendJSON(response, 409, { error: "Insufficient Beans" });
                return;
            }

            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/vouchers/consume") {
        try {
            const body = await readBody(request);
            const code = String(body.code || "").trim().toUpperCase();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!code) {
                sendJSON(response, 400, { error: "Missing voucher code" });
                return;
            }

            const voucher = await consumeVoucher(code, customer.email);
            sendJSON(response, 200, voucher);
        } catch (error) {
            const message = error.message || "Voucher could not be consumed";
            if (message === "VOUCHER_NOT_FOUND") {
                sendJSON(response, 404, { error: "Voucher not found" });
                return;
            }
            if (message === "VOUCHER_EMAIL_MISMATCH") {
                sendJSON(response, 403, { error: "Voucher does not belong to this account" });
                return;
            }
            if (message === "VOUCHER_ALREADY_USED") {
                sendJSON(response, 409, { error: "Voucher already used" });
                return;
            }
            if (message === "VOUCHER_EXPIRED") {
                sendJSON(response, 410, { error: "Voucher expired" });
                return;
            }

            sendJSON(response, 400, { error: "Invalid voucher payload" });
        }
        return;
    }

    if (request.method === "POST" && url.pathname === "/vouchers/preview") {
        try {
            const body = await readBody(request);
            const code = String(body.code || "").trim().toUpperCase();
            const requestedEmail = normalizeEmail(body.email);
            const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
            if (!authenticated) {
                return;
            }

            const customer = await resolveCustomerSession(authenticated, response);
            if (!customer) {
                return;
            }

            if (!code) {
                sendJSON(response, 400, { error: "Missing voucher code" });
                return;
            }

            const voucher = await previewVoucher(code, customer.email);
            sendJSON(response, 200, voucher);
        } catch (error) {
            const message = error.message || "Voucher could not be previewed";
            if (message === "VOUCHER_NOT_FOUND") {
                sendJSON(response, 404, { error: "Voucher not found" });
                return;
            }
            if (message === "VOUCHER_EMAIL_MISMATCH") {
                sendJSON(response, 403, { error: "Voucher does not belong to this account" });
                return;
            }
            if (message === "VOUCHER_ALREADY_USED") {
                sendJSON(response, 409, { error: "Voucher already used" });
                return;
            }
            if (message === "VOUCHER_EXPIRED") {
                sendJSON(response, 410, { error: "Voucher expired" });
                return;
            }

            sendJSON(response, 400, { error: "Invalid voucher payload" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/vouchers") {
        const requestedEmail = normalizeEmail(url.searchParams.get("email"));
        const authenticated = parseAuthenticatedCustomer(request, response, requestedEmail || null);
        if (!authenticated) {
            return;
        }

        const customer = await resolveCustomerSession(authenticated, response);
        if (!customer) {
            return;
        }

        sendJSON(response, 200, await activeVouchersFor(customer.email));
        return;
    }

    if (request.method === "GET") {
        try {
            const payment = await findBenefitPaymentForBrowserReturn(url);
            if (payment) {
                sendHTML(
                    response,
                    200,
                    renderBenefitResultPage(payment),
                    benefitResultPageHeaders()
                );
                return;
            }
        } catch (error) {
            console.error(
                "BENEFIT fallback return lookup failed:",
                error.code || error.message || "BENEFIT_FALLBACK_RETURN_FAILED"
            );
        }
    }

    sendJSON(response, 404, { error: "Not found" });
});

async function startServer() {
    if (!database.isEnabled()) {
        server.listen(port, host, () => {
            console.log(`Talla backend listening on ${config.appURL} (${host}:${port})`);
        });
        return;
    }

    try {
        await database.initializeDatabase();
        console.log("Postgres storage enabled for accounts and loyalty.");
        startOpsAlertMonitor();
        server.listen(port, host, () => {
            console.log(`Talla backend listening on ${config.appURL} (${host}:${port})`);
        });
    } catch (error) {
        console.error("Failed to initialize Postgres storage.", error);
        process.exit(1);
    }
}

if (require.main === module) {
    void startServer();
}

module.exports = {
    applyConfirmedMpgsPayment,
    applyBenefitNotification,
    benefitResultState,
    bhdFils,
    createBenefitPayCheckStatusSignature,
    createBenefitPayReferenceID,
    confirmShopifyEazyPayment,
    ensureShopifyEazyInvoice,
    exportCompletedOrderToShopify,
    findShopifyOrderExport,
    findShopifyEazyPayment,
    isEazyPayManualShopifyOrder,
    normalizeTallaPaymentID,
    prepareShopifyEazyOrder,
    publicShopifyEazyPayment,
    normalizeBenefitPayMPQRText,
    parseBenefitCallbackRequest,
    mpgsResultIndicatorMatches,
    renderClickToPayLaunch,
    renderBenefitResultPage,
    renderMpgsResultPage,
    server,
    startServer,
    shopifyOrderCreateInput,
    verifyConfirmedMpgsOrder,
    verifyEazyTransactionForShopifyPayment,
    verifyMpgsAuthenticationForPurchase,
    verifyBenefitNotification
};
