const path = require("path");

function toNumber(value, fallback) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : fallback;
}

function toAbsolutePath(value) {
    if (!value) {
        return null;
    }

    return path.isAbsolute(value) ? value : path.resolve(__dirname, value);
}

const host = process.env.HOST || "0.0.0.0";
const port = toNumber(process.env.PORT, 8787);
const dataDirectory = toAbsolutePath(process.env.DATA_DIRECTORY) || path.join(__dirname, "data");
const walletPassTemplateDirectory = toAbsolutePath(process.env.WALLET_PASS_TEMPLATE_DIRECTORY)
    || path.join(__dirname, "..", "WalletPass", "TallaLoyalty.pass");
const adminDirectory = path.join(__dirname, "admin");
module.exports = {
    host,
    port,
    appURL: process.env.APP_URL || `http://localhost:${port}`,
    dataDirectory,
    adminDirectory,
    adminUsername: process.env.ADMIN_USERNAME || "",
    adminPassword: process.env.ADMIN_PASSWORD || "",
    adminSessionSecret: process.env.ADMIN_SESSION_SECRET || "",
    adminSessionHours: toNumber(process.env.ADMIN_SESSION_HOURS, 12),
    customerTokenSecret: process.env.CUSTOMER_TOKEN_SECRET || process.env.ADMIN_SESSION_SECRET || "",
    customerTokenHours: toNumber(process.env.CUSTOMER_TOKEN_HOURS, 168),
    resendAPIKey: process.env.RESEND_API_KEY || "",
    emailFromAddress: process.env.EMAIL_FROM_ADDRESS || "",
    appleSignInClientID: process.env.APPLE_SIGN_IN_CLIENT_ID || "Talla-Speciality.Talla-Speciality",
    applePaySettlementProvider: process.env.APPLE_PAY_SETTLEMENT_PROVIDER || "",
    apnsKeyID: process.env.APNS_KEY_ID || "",
    apnsTeamID: process.env.APNS_TEAM_ID || "",
    apnsBundleID: process.env.APNS_BUNDLE_ID || process.env.APPLE_SIGN_IN_CLIENT_ID || "",
    apnsUseSandbox: process.env.APNS_USE_SANDBOX !== "false",
    apnsPrivateKeyPath: toAbsolutePath(process.env.APNS_PRIVATE_KEY_PATH),
    apnsPrivateKeyBase64: process.env.APNS_PRIVATE_KEY_BASE64 || "",
    passwordResetTokenHours: toNumber(process.env.PASSWORD_RESET_TOKEN_HOURS, 1),
    rateLimitWindowMs: toNumber(process.env.RATE_LIMIT_WINDOW_MS, 60_000),
    rateLimitMaxRequests: toNumber(process.env.RATE_LIMIT_MAX_REQUESTS, 240),
    requestLoggingEnabled: process.env.REQUEST_LOGGING_ENABLED !== "false",
    opsAlertWebhookURL: process.env.OPS_ALERT_WEBHOOK_URL || "",
    opsAlertCheckIntervalMs: toNumber(process.env.OPS_ALERT_CHECK_INTERVAL_MS, 300_000),
    opsAlertWindowMinutes: toNumber(process.env.OPS_ALERT_WINDOW_MINUTES, 15),
    opsAlert5xxThreshold: toNumber(process.env.OPS_ALERT_5XX_THRESHOLD, 5),
    opsAlert429Threshold: toNumber(process.env.OPS_ALERT_429_THRESHOLD, 20),
    opsAlertCooldownMinutes: toNumber(process.env.OPS_ALERT_COOLDOWN_MINUTES, 30),
    shopifyAdminShopDomain: process.env.SHOPIFY_ADMIN_SHOP_DOMAIN || "",
    shopifyAdminAccessToken: process.env.SHOPIFY_ADMIN_ACCESS_TOKEN || "",
    shopifyAdminAPIVersion: process.env.SHOPIFY_ADMIN_API_VERSION || "2025-10",
    shopifyAdminPublicationID: process.env.SHOPIFY_ADMIN_PUBLICATION_ID || "",
    stores: {
        loyalty: path.join(dataDirectory, "loyalty.json"),
        accounts: path.join(dataDirectory, "accounts.json"),
        orders: path.join(dataDirectory, "orders.json"),
        vouchers: path.join(dataDirectory, "vouchers.json"),
        alerts: path.join(dataDirectory, "alerts.json"),
        pushDevices: path.join(dataDirectory, "pushDevices.json"),
        addresses: path.join(dataDirectory, "addresses.json"),
        alertInbox: path.join(dataDirectory, "alertInbox.json"),
        passwordResetTokens: path.join(dataDirectory, "passwordResetTokens.json")
    },
    corsAllowedOrigin: process.env.CORS_ALLOWED_ORIGIN || "*",
    walletPassTemplateDirectory,
    walletPassCertificatePath: toAbsolutePath(process.env.WALLET_P12_PATH),
    walletPassCertificateBase64: process.env.WALLET_P12_BASE64 || "",
    walletPassCertificatePassword: process.env.WALLET_P12_PASSWORD || "",
    walletPassWWDRPath: toAbsolutePath(process.env.WALLET_WWDR_PATH),
    walletPassWWDRBase64: process.env.WALLET_WWDR_BASE64 || ""
};
