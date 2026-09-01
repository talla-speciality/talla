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

function toList(value) {
    return String(value || "")
        .split(",")
        .map((entry) => entry.trim().toLowerCase())
        .filter(Boolean);
}

const host = process.env.HOST || "0.0.0.0";
const port = toNumber(process.env.PORT, 8787);
const dataDirectory = toAbsolutePath(process.env.DATA_DIRECTORY) || path.join(__dirname, "data");
const walletPassTemplateDirectory = toAbsolutePath(process.env.WALLET_PASS_TEMPLATE_DIRECTORY)
    || path.join(__dirname, "..", "WalletPass", "TallaLoyalty.pass");
const adminDirectory = path.join(__dirname, "admin");
const appURL = process.env.APP_URL || `http://localhost:${port}`;
const isProduction = process.env.NODE_ENV === "production";
module.exports = {
    host,
    port,
    appURL,
    dataDirectory,
    adminDirectory,
    adminUsername: process.env.ADMIN_USERNAME || "",
    adminPassword: process.env.ADMIN_PASSWORD || "",
    adminSessionSecret: process.env.ADMIN_SESSION_SECRET || "",
    adminAppEmails: toList(process.env.ADMIN_APP_EMAILS || process.env.ADMIN_USERNAME || ""),
    adminSessionHours: toNumber(process.env.ADMIN_SESSION_HOURS, 12),
    webPushVapidPublicKey: process.env.WEB_PUSH_VAPID_PUBLIC_KEY || "",
    webPushVapidPrivateKey: process.env.WEB_PUSH_VAPID_PRIVATE_KEY || "",
    webPushVapidSubject: process.env.WEB_PUSH_VAPID_SUBJECT || "mailto:admin@tallaspeciality.com",
    customerTokenSecret: process.env.CUSTOMER_TOKEN_SECRET || process.env.ADMIN_SESSION_SECRET || "",
    customerTokenHours: toNumber(process.env.CUSTOMER_TOKEN_HOURS, 168),
    resendAPIKey: process.env.RESEND_API_KEY || "",
    emailFromAddress: process.env.EMAIL_FROM_ADDRESS || "",
    appleSignInClientID: process.env.APPLE_SIGN_IN_CLIENT_ID || "Talla-Speciality.Talla-Speciality",
    appAttestAppID: process.env.APP_ATTEST_APP_ID || "TAG9WXY85M.Talla-Speciality.Talla-Speciality",
    appAttestEnforce: process.env.APP_ATTEST_ENFORCE
        ? process.env.APP_ATTEST_ENFORCE === "true"
        : isProduction,
    appAttestAllowDevelopment: process.env.APP_ATTEST_ALLOW_DEVELOPMENT
        ? process.env.APP_ATTEST_ALLOW_DEVELOPMENT !== "false"
        : !isProduction,
    applePaySettlementProvider: process.env.APPLE_PAY_SETTLEMENT_PROVIDER || "",
    benefitTranportalID: process.env.BENEFIT_TRANPORTAL_ID || "",
    benefitTranportalPassword: process.env.BENEFIT_TRANPORTAL_PASSWORD || "",
    benefitResourceKey: process.env.BENEFIT_RESOURCE_KEY || "",
    benefitAPIEndpoint: process.env.BENEFIT_API_ENDPOINT
        || "https://www.benefit-gateway.bh/payment/API/hosted.htm",
    benefitSuccessURL: process.env.BENEFIT_SUCCESS_URL || "",
    benefitErrorURL: process.env.BENEFIT_ERROR_URL || "",
    benefitNotificationURL: process.env.BENEFIT_NOTIFICATION_URL || "",
    benefitPayAppID: process.env.BENEFITPAY_APP_ID || "",
    benefitPayMerchantID: process.env.BENEFITPAY_MERCHANT_ID || "",
    benefitPaySecretKey: process.env.BENEFITPAY_SECRET_KEY || "",
    benefitPayCheckStatusURL: process.env.BENEFITPAY_CHECK_STATUS_URL || "",
    benefitPayMerchantName: process.env.BENEFITPAY_MERCHANT_NAME || "",
    benefitPayMerchantCity: process.env.BENEFITPAY_MERCHANT_CITY || "",
    benefitPayMerchantCategoryCode: process.env.BENEFITPAY_MCC || "",
    benefitPayCountryCode: process.env.BENEFITPAY_COUNTRY_CODE || "BH",
    mpgsMerchantID: process.env.MPGS_MERCHANT_ID || "",
    mpgsAPIPassword: process.env.MPGS_API_PASSWORD || "",
    mpgsAPISecondaryPassword: process.env.MPGS_API_PASSWORD_SECONDARY || "",
    mpgsAPIVersion: process.env.MPGS_API_VERSION || "100",
    mpgsBaseURL: process.env.MPGS_BASE_URL || "https://eazypay.gateway.mastercard.com",
    eazyAppID: process.env.EAZY_APP_ID || "",
    eazySecretKey: process.env.EAZY_SECRET_KEY || "",
    eazyAPIBaseURL: process.env.EAZY_API_BASE_URL || "https://api.eazy.net",
    eazyPaymentMethods: process.env.EAZY_PAYMENT_METHODS || "BENEFITGATEWAY,CREDITCARD,APPLEPAY",
    apnsKeyID: process.env.APNS_KEY_ID || "",
    apnsTeamID: process.env.APNS_TEAM_ID || "",
    apnsBundleID: process.env.APNS_BUNDLE_ID || process.env.APPLE_SIGN_IN_CLIENT_ID || "",
    apnsAdminBundleID: process.env.APNS_ADMIN_BUNDLE_ID || "Talla-Speciality.Talla-Admin",
    apnsUseSandbox: process.env.APNS_USE_SANDBOX
        ? process.env.APNS_USE_SANDBOX !== "false"
        : !isProduction,
    apnsPrivateKeyPath: toAbsolutePath(process.env.APNS_PRIVATE_KEY_PATH),
    apnsPrivateKeyBase64: process.env.APNS_PRIVATE_KEY_BASE64 || "",
    googleCloudProjectID: process.env.GOOGLE_CLOUD_PROJECT_ID || "",
    googleServiceAccountJSONBase64: process.env.GOOGLE_SERVICE_ACCOUNT_JSON_BASE64 || "",
    playIntegrityPackageName: process.env.PLAY_INTEGRITY_PACKAGE_NAME || "com.talla.speciality",
    playIntegrityEnforce: process.env.PLAY_INTEGRITY_ENFORCE
        ? process.env.PLAY_INTEGRITY_ENFORCE === "true"
        : isProduction,
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
    shopifyWebhookSecret: process.env.SHOPIFY_WEBHOOK_SECRET || "",
    stores: {
        loyalty: path.join(dataDirectory, "loyalty.json"),
        accounts: path.join(dataDirectory, "accounts.json"),
        orders: path.join(dataDirectory, "orders.json"),
        vouchers: path.join(dataDirectory, "vouchers.json"),
        alerts: path.join(dataDirectory, "alerts.json"),
        pushDevices: path.join(dataDirectory, "pushDevices.json"),
        adminPushSubscriptions: path.join(dataDirectory, "adminPushSubscriptions.json"),
        adminPushDevices: path.join(dataDirectory, "adminPushDevices.json"),
        addresses: path.join(dataDirectory, "addresses.json"),
        alertInbox: path.join(dataDirectory, "alertInbox.json"),
        campaignSettings: path.join(dataDirectory, "campaignSettings.json"),
        events: path.join(dataDirectory, "events.json"),
        homeSettings: path.join(dataDirectory, "homeSettings.json"),
        passportSettings: path.join(dataDirectory, "passportSettings.json"),
        appSettings: path.join(dataDirectory, "appSettings.json"),
        tasteMemory: path.join(dataDirectory, "tasteMemory.json"),
        customerLibrary: path.join(dataDirectory, "customerLibrary.json"),
        passwordResetTokens: path.join(dataDirectory, "passwordResetTokens.json"),
        benefitPayments: path.join(dataDirectory, "benefitPayments.json"),
        cardPayments: path.join(dataDirectory, "cardPayments.json"),
        shopifyEazyPayments: path.join(dataDirectory, "shopifyEazyPayments.json"),
        shopifyOrderExports: path.join(dataDirectory, "shopifyOrderExports.json"),
        walletPasses: path.join(dataDirectory, "walletPasses.json"),
        appAttest: path.join(dataDirectory, "appAttest.json")
    },
    corsAllowedOrigin: process.env.CORS_ALLOWED_ORIGIN || "*",
    walletPassTemplateDirectory,
    walletPassCertificatePath: toAbsolutePath(process.env.WALLET_P12_PATH),
    walletPassCertificateBase64: process.env.WALLET_P12_BASE64 || "",
    walletPassCertificatePassword: process.env.WALLET_P12_PASSWORD || "",
    walletPassWWDRPath: toAbsolutePath(process.env.WALLET_WWDR_PATH),
    walletPassWWDRBase64: process.env.WALLET_WWDR_BASE64 || "",
    walletPassWebServiceURL: process.env.WALLET_WEB_SERVICE_URL || `${appURL.replace(/\/$/, "")}/wallet`
};
