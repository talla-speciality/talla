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
const benefitGateway = require("./modules/commerce/benefit-gateway");
const mpgsGateway = require("./modules/commerce/mpgs-gateway");
const eazyPay = require("./modules/commerce/eazypay");
const appAttest = require("./modules/account/app-attest");
const webPush = require("web-push");
const googleMobileServices = require("./modules/account/google-mobile-services");
const { writeWalletStampStrips } = require("./modules/loyalty/wallet-pass-artwork");
const {
    emptyCustomerLibrary,
    mergeCustomerLibraryRecords,
    normalizeBrewJournalEntry,
    normalizeCustomerProductIDs
} = require("./modules/brewing/customer-library");
const { createCoffeeSyncService } = require("./modules/brewing/coffee-sync");
const { normalizeTelemetryBatch, normalizeTelemetryEvent, persistTelemetryEvent } = require("./modules/observability/telemetry");
const { createTokenPair, hashToken, publicTokenPair } = require("./modules/account/session-tokens");
const {
    authenticateAdmin,
    hasPermission,
    mobileAdminPrincipal,
    permissionForAdminRequest
} = require("./modules/account/admin-authorization");

const host = config.host;
const port = config.port;
const dataDirectory = config.dataDirectory;
const loyaltyStorePath = config.stores.loyalty;
const accountsStorePath = config.stores.accounts;
const ordersStorePath = config.stores.orders;
const vouchersStorePath = config.stores.vouchers;
const alertsStorePath = config.stores.alerts;
const pushDevicesStorePath = config.stores.pushDevices;
const adminPushSubscriptionsStorePath = config.stores.adminPushSubscriptions;
const adminPushDevicesStorePath = config.stores.adminPushDevices;
const addressesStorePath = config.stores.addresses;
const alertInboxStorePath = config.stores.alertInbox;
const campaignSettingsStorePath = config.stores.campaignSettings;
const eventsStorePath = config.stores.events;
const homeSettingsStorePath = config.stores.homeSettings;
const passportSettingsStorePath = config.stores.passportSettings;
const appSettingsStorePath = config.stores.appSettings;
const tasteMemoryStorePath = config.stores.tasteMemory;
const customerLibraryStorePath = config.stores.customerLibrary;
const passwordResetTokensStorePath = config.stores.passwordResetTokens;
const benefitPaymentsStorePath = config.stores.benefitPayments;
const cardPaymentsStorePath = config.stores.cardPayments;
const shopifyEazyPaymentsStorePath = config.stores.shopifyEazyPayments;
const shopifyOrderExportsStorePath = config.stores.shopifyOrderExports;
const walletPassesStorePath = config.stores.walletPasses;
const appAttestStorePath = config.stores.appAttest;
const telemetryStorePath = config.stores.telemetry;
const adminDirectory = config.adminDirectory;
const adminUsername = config.adminUsername;
const adminPassword = config.adminPassword;
const adminAppEmails = config.adminAppEmails;
const adminAppRoles = config.adminAppRoles;
const adminUsers = config.adminUsers;
const adminSessionSecret = config.adminSessionSecret;
const adminSessionHours = config.adminSessionHours;
const webPushVapidPublicKey = config.webPushVapidPublicKey;
const webPushVapidPrivateKey = config.webPushVapidPrivateKey;
const webPushVapidSubject = config.webPushVapidSubject;
const customerTokenSecret = config.customerTokenSecret;
const customerTokenHours = config.customerTokenHours;
const customerRefreshTokenDays = config.customerRefreshTokenDays;
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
const apnsAdminBundleID = config.apnsAdminBundleID;
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
const walletPassWebServiceURL = config.walletPassWebServiceURL;
const adminSessionCookieName = "talla_admin_session";
const adminSessions = new Map();
const adminOrderStreamClients = new Set();
const announcedAdminOrderIDs = new Map();
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
let walletPushCredentialsCache = null;
const walletPassUpdateTimers = new Map();

ensureStoreFile(loyaltyStorePath, { accounts: {} });
ensureStoreFile(accountsStorePath, { accounts: {} });
ensureStoreFile(ordersStorePath, { orders: {} });
ensureStoreFile(vouchersStorePath, { vouchers: {} });
ensureStoreFile(alertsStorePath, { alerts: {} });
ensureStoreFile(pushDevicesStorePath, { devices: [] });
ensureStoreFile(adminPushSubscriptionsStorePath, { subscriptions: [] });
ensureStoreFile(adminPushDevicesStorePath, { devices: [] });
ensureStoreFile(walletPassesStorePath, { passes: {}, devices: {}, registrations: [] });
ensureStoreFile(addressesStorePath, { addresses: {} });
ensureStoreFile(alertInboxStorePath, { alerts: {} });
ensureStoreFile(campaignSettingsStorePath, { campaignSettings: defaultCampaignSettings() });
ensureStoreFile(eventsStorePath, { eventSettings: defaultEventSettings() });
ensureStoreFile(homeSettingsStorePath, { homeSettings: defaultHomeSettings() });
ensureStoreFile(passportSettingsStorePath, { passportSettings: defaultPassportSettings() });
ensureStoreFile(appSettingsStorePath, { appSettings: defaultAppSettings() });
ensureStoreFile(tasteMemoryStorePath, { tasteMemory: {} });
ensureStoreFile(customerLibraryStorePath, { customerLibrary: {} });
ensureStoreFile(passwordResetTokensStorePath, { tokens: [] });
ensureStoreFile(benefitPaymentsStorePath, { payments: {} });
ensureStoreFile(cardPaymentsStorePath, { payments: {} });
ensureStoreFile(shopifyEazyPaymentsStorePath, { payments: {} });
ensureStoreFile(shopifyOrderExportsStorePath, { exports: {} });
ensureStoreFile(appAttestStorePath, { keys: {} });
ensureStoreFile(telemetryStorePath, { events: [] });

async function recordTelemetry(payload, accountEmail = null) {
    const event = normalizeTelemetryEvent(payload);
    if (!event) return false;
    await persistTelemetryEvent(event, { database, fallbackPath: telemetryStorePath, accountEmail });
    return true;
}

const runtimeAppSettings = {
    value: normalizeAppSettings(readJSON(appSettingsStorePath).appSettings || {})
};

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

function defaultEventSettings() {
    return {
        events: [],
        updatedAt: null
    };
}

function normalizeEventSettings(value = {}) {
    const trimText = (text, maxLength) => String(text || "").trim().slice(0, maxLength);
    const eventID = (candidate, fallback) => {
        const normalized = trimText(candidate || fallback, 60)
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, "-")
            .replace(/^-+|-+$/g, "");
        return normalized || fallback;
    };
    const isoDate = (candidate) => {
        if (!candidate) return null;
        const date = new Date(candidate);
        return Number.isFinite(date.getTime()) ? date.toISOString() : null;
    };
    const httpsURL = (candidate) => {
        const value = trimText(candidate, 500);
        if (!value) return "";
        try {
            const parsed = new URL(value);
            return parsed.protocol === "https:" ? parsed.toString() : "";
        } catch {
            return "";
        }
    };
    const hexColor = (candidate, fallback) => {
        const value = trimText(candidate, 7).toUpperCase();
        return /^#[0-9A-F]{6}$/.test(value) ? value : fallback;
    };
    const seenIDs = new Set();
    const sourceEvents = Array.isArray(value.events) ? value.events : [];
    const events = sourceEvents.slice(0, 30).map((event, index) => {
        let id = eventID(event?.id, `event-${index + 1}`);
        if (seenIDs.has(id)) {
            id = `${id}-${index + 1}`;
        }
        seenIDs.add(id);

        const seenProductIDs = new Set();
        const productIDs = (Array.isArray(event?.productIDs) ? event.productIDs : [])
            .map((productID) => trimText(productID, 180))
            .filter((productID) => {
                if (!productID || seenProductIDs.has(productID)) return false;
                seenProductIDs.add(productID);
                return true;
            })
            .slice(0, 40);
        const priority = Number(event?.priority);

        return {
            id,
            enabled: Boolean(event?.enabled),
            name: trimText(event?.name || event?.titleEN || id, 80),
            titleEN: trimText(event?.titleEN, 80),
            titleAR: trimText(event?.titleAR, 80),
            subtitleEN: trimText(event?.subtitleEN, 220),
            subtitleAR: trimText(event?.subtitleAR, 220),
            badgeEN: trimText(event?.badgeEN, 40),
            badgeAR: trimText(event?.badgeAR, 40),
            ctaEN: trimText(event?.ctaEN, 32),
            ctaAR: trimText(event?.ctaAR, 32),
            categoryTitleEN: trimText(event?.categoryTitleEN, 60),
            categoryTitleAR: trimText(event?.categoryTitleAR, 60),
            categorySubtitleEN: trimText(event?.categorySubtitleEN, 100),
            categorySubtitleAR: trimText(event?.categorySubtitleAR, 100),
            startAt: isoDate(event?.startAt),
            endAt: isoDate(event?.endAt),
            imageURL: httpsURL(event?.imageURL),
            accentHex: hexColor(event?.accentHex, "#C8965A"),
            secondaryHex: hexColor(event?.secondaryHex, "#2A1D14"),
            symbol: trimText(event?.symbol || "sparkles", 60),
            productIDs,
            priority: Number.isFinite(priority) ? Math.max(-1000, Math.min(1000, Math.round(priority))) : 0
        };
    });

    return {
        events,
        updatedAt: value.updatedAt || null
    };
}

function activeEventSettings(settings, now = new Date()) {
    const nowTime = now.getTime();
    return {
        ...settings,
        events: settings.events
            .filter((event) => {
                if (!event.enabled || !event.titleEN) return false;
                const startTime = event.startAt ? new Date(event.startAt).getTime() : null;
                const endTime = event.endAt ? new Date(event.endAt).getTime() : null;
                return (startTime === null || startTime <= nowTime)
                    && (endTime === null || endTime > nowTime);
            })
            .sort((left, right) => right.priority - left.priority || left.name.localeCompare(right.name))
    };
}

function defaultHomeSettings() {
    return {
        signatureRoastProductIDs: [],
        quickDrinkProductIDs: [],
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
    const normalizeProductIDs = (productIDs, limit) => {
        const seen = new Set();
        return Array.isArray(productIDs)
            ? productIDs
                .map((productID) => String(productID || "").trim())
                .filter((productID) => {
                    if (!productID || seen.has(productID)) {
                        return false;
                    }
                    seen.add(productID);
                    return true;
                })
                .slice(0, limit)
            : [];
    };
    const signatureRoastProductIDs = Array.isArray(value.signatureRoastProductIDs)
        ? normalizeProductIDs(value.signatureRoastProductIDs, 4)
        : fallback.signatureRoastProductIDs;
    const quickDrinkProductIDs = Array.isArray(value.quickDrinkProductIDs)
        ? normalizeProductIDs(value.quickDrinkProductIDs, 6)
        : fallback.quickDrinkProductIDs;
    const trimText = (text, maxLength) => String(text || "").trim().slice(0, maxLength);

    return {
        signatureRoastProductIDs,
        quickDrinkProductIDs,
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

function defaultAppSettings() {
    return {
        announcement: {
            enabled: false,
            title: "",
            message: "",
            actionLabel: "",
            actionURL: ""
        },
        support: {
            whatsappURL: "https://wa.me/97339392414",
            privacyURL: "https://duneroastery.myshopify.com/policies/privacy-policy",
            termsURL: "https://duneroastery.myshopify.com/policies/terms-of-service"
        },
        homeSections: {
            showQuickDrinks: true,
            showFunPick: true,
            showSignatureRoasts: true,
            showPassport: true
        },
        payments: {
            applePayEnabled: true,
            benefitPayEnabled: true,
            benefitEnabled: true,
            cardEnabled: true,
            cashOnDeliveryEnabled: true,
            noticeEN: "",
            noticeAR: ""
        },
        fulfillment: {
            deliveryEnabled: true,
            pickupEnabled: true,
            pickupNameEN: "Talla, Riffa",
            pickupNameAR: "تالة، الرفاع",
            pickupAddressEN: "Villa 336, Street 1307, Riffa 913",
            pickupAddressAR: "فيلا 336، طريق 1307، الرفاع 913",
            pickupMapsURL: "",
            openingHoursEN: "",
            openingHoursAR: "",
            bahrainRate: 2,
            khaleejiCashOnDeliverySurcharge: 2,
            maximumKhaleejiWeightGrams: 4000,
            khaleejiTransitEN: "3 to 5 business days",
            khaleejiTransitAR: "من 3 إلى 5 أيام عمل",
            khaleejiTiers: [
                { maximumWeightGrams: 500, rate: 5.5 },
                { maximumWeightGrams: 1000, rate: 6.5 },
                { maximumWeightGrams: 1500, rate: 7.5 },
                { maximumWeightGrams: 2000, rate: 8.5 },
                { maximumWeightGrams: 2500, rate: 9.5 },
                { maximumWeightGrams: 3000, rate: 10.5 },
                { maximumWeightGrams: 3500, rate: 11.5 },
                { maximumWeightGrams: 4000, rate: 12.5 }
            ]
        },
        release: {
            maintenanceEnabled: false,
            checkoutMaintenanceEnabled: false,
            minimumSupportedVersion: "",
            latestVersion: "",
            appStoreURL: "",
            titleEN: "We'll be right back",
            titleAR: "سنعود قريباً",
            messageEN: "Talla is being updated. Please try again shortly.",
            messageAR: "يتم تحديث تالة. يرجى المحاولة بعد قليل.",
            updateMessageEN: "A new version of Talla is available.",
            updateMessageAR: "يتوفر إصدار جديد من تطبيق تالة."
        },
        loyalty: {
            pointsPerBHD: 5,
            silverThreshold: 150,
            goldThreshold: 300,
            rewardStep: 50,
            rewards: [
                { id: "espresso-pour", enabled: true, titleEN: "Drink of Your Choice", titleAR: "مشروب من اختيارك", detailEN: "Choose any eligible drink", detailAR: "اختر أي مشروب مؤهل", points: 50, reward: "Free Drink" },
                { id: "pastry-pairing", enabled: true, titleEN: "Pastry Pairing", titleAR: "حلوى مع القهوة", detailEN: "Pastry with coffee", detailAR: "حلوى مع القهوة", points: 75, reward: "Pastry pairing" },
                { id: "signature-sip", enabled: true, titleEN: "Signature Sip", titleAR: "مشروب تالة المميز", detailEN: "One signature drink", detailAR: "مشروب مميز واحد", points: 100, reward: "Signature sip" },
                { id: "majlis-hosting", enabled: true, titleEN: "Majlis Hosting Reward", titleAR: "مكافأة ضيافة المجلس", detailEN: "Hosting credit", detailAR: "رصيد للضيافة", points: 120, reward: "Majlis hosting reward" },
                { id: "coffee-bag-credit", enabled: true, titleEN: "Coffee Bag Credit", titleAR: "رصيد كيس قهوة", detailEN: "Credit toward a coffee bag", detailAR: "رصيد لشراء كيس قهوة", points: 150, reward: "Coffee bag credit" },
                { id: "talla-box-treat", enabled: true, titleEN: "Talla Box Treat", titleAR: "هدية صندوق تالة", detailEN: "Gift box credit", detailAR: "رصيد لصندوق هدايا", points: 200, reward: "Talla box treat" },
                { id: "gold-club-gift", enabled: true, titleEN: "Gold Club Gift", titleAR: "هدية النادي الذهبي", detailEN: "Exclusive Talla Club gift", detailAR: "هدية حصرية من نادي تالة", points: 250, reward: "Gold club gift" }
            ]
        },
        updatedAt: null
    };
}

function normalizeAppSettings(value = {}) {
    const fallback = defaultAppSettings();
    const trimText = (text, maxLength) => String(text || "").trim().slice(0, maxLength);
    const safeURL = (candidate, fallbackValue) => {
        const value = trimText(candidate, 500);
        if (!value) return fallbackValue;
        try {
            const parsed = new URL(value);
            return ["https:", "talla:"].includes(parsed.protocol) ? parsed.toString() : fallbackValue;
        } catch {
            return fallbackValue;
        }
    };
    const safeVersion = (candidate) => {
        const version = trimText(candidate, 30);
        return /^\d+(?:\.\d+){0,3}$/.test(version) ? version : "";
    };
    const announcement = value.announcement || {};
    const support = value.support || {};
    const homeSections = value.homeSections || {};
    const payments = value.payments || {};
    const fulfillment = value.fulfillment || {};
    const release = value.release || {};
    const loyalty = value.loyalty || {};
    const requestedDeliveryEnabled = fulfillment.deliveryEnabled === undefined
        ? fallback.fulfillment.deliveryEnabled
        : Boolean(fulfillment.deliveryEnabled);
    const requestedPickupEnabled = fulfillment.pickupEnabled === undefined
        ? fallback.fulfillment.pickupEnabled
        : Boolean(fulfillment.pickupEnabled);
    const hasFulfillmentMethod = requestedDeliveryEnabled || requestedPickupEnabled;
    const boundedNumber = (candidate, fallbackValue, minimum, maximum) => {
        const number = Number(candidate);
        return Number.isFinite(number) ? Math.min(maximum, Math.max(minimum, number)) : fallbackValue;
    };
    const normalizedTiers = Array.isArray(fulfillment.khaleejiTiers)
        ? fulfillment.khaleejiTiers
            .map((tier) => {
                const maximumWeightGrams = Number(tier?.maximumWeightGrams);
                const rate = Number(tier?.rate);
                if (!Number.isFinite(maximumWeightGrams) || maximumWeightGrams <= 0 || !Number.isFinite(rate) || rate < 0) {
                    return null;
                }
                return {
                    maximumWeightGrams: Math.round(Math.min(maximumWeightGrams, 50_000)),
                    rate: Math.min(rate, 500)
                };
            })
            .filter(Boolean)
            .sort((a, b) => a.maximumWeightGrams - b.maximumWeightGrams)
            .slice(0, 20)
        : fallback.fulfillment.khaleejiTiers;
    const normalizedRewards = Array.isArray(loyalty.rewards)
        ? loyalty.rewards.map((reward, index) => ({
            id: trimText(reward?.id || `reward-${index + 1}`, 60).toLowerCase().replace(/[^a-z0-9-]/g, "-") || `reward-${index + 1}`,
            enabled: reward?.enabled === undefined ? true : Boolean(reward.enabled),
            titleEN: trimText(reward?.titleEN, 80),
            titleAR: trimText(reward?.titleAR, 80),
            detailEN: trimText(reward?.detailEN, 160),
            detailAR: trimText(reward?.detailAR, 160),
            points: Math.round(boundedNumber(reward?.points, 50, 1, 1_000_000)),
            reward: trimText(reward?.reward, 100)
        })).filter((reward) => reward.titleEN && reward.reward).slice(0, 30)
        : fallback.loyalty.rewards;
    const silverThreshold = Math.round(boundedNumber(loyalty.silverThreshold, fallback.loyalty.silverThreshold, 1, 1_000_000));
    const goldThreshold = Math.max(
        Math.round(boundedNumber(loyalty.goldThreshold, fallback.loyalty.goldThreshold, 1, 1_000_000)),
        silverThreshold + 1
    );

    return {
        announcement: {
            enabled: Boolean(announcement.enabled),
            title: trimText(announcement.title, 60),
            message: trimText(announcement.message, 220),
            actionLabel: trimText(announcement.actionLabel, 28),
            actionURL: safeURL(announcement.actionURL, "")
        },
        support: {
            whatsappURL: safeURL(support.whatsappURL, fallback.support.whatsappURL),
            privacyURL: safeURL(support.privacyURL, fallback.support.privacyURL),
            termsURL: safeURL(support.termsURL, fallback.support.termsURL)
        },
        homeSections: {
            showQuickDrinks: homeSections.showQuickDrinks === undefined ? true : Boolean(homeSections.showQuickDrinks),
            showFunPick: homeSections.showFunPick === undefined ? true : Boolean(homeSections.showFunPick),
            showSignatureRoasts: homeSections.showSignatureRoasts === undefined ? true : Boolean(homeSections.showSignatureRoasts),
            showPassport: homeSections.showPassport === undefined ? true : Boolean(homeSections.showPassport)
        },
        payments: {
            applePayEnabled: payments.applePayEnabled === undefined ? fallback.payments.applePayEnabled : Boolean(payments.applePayEnabled),
            benefitPayEnabled: payments.benefitPayEnabled === undefined ? fallback.payments.benefitPayEnabled : Boolean(payments.benefitPayEnabled),
            benefitEnabled: payments.benefitEnabled === undefined ? fallback.payments.benefitEnabled : Boolean(payments.benefitEnabled),
            cardEnabled: payments.cardEnabled === undefined ? fallback.payments.cardEnabled : Boolean(payments.cardEnabled),
            cashOnDeliveryEnabled: payments.cashOnDeliveryEnabled === undefined ? fallback.payments.cashOnDeliveryEnabled : Boolean(payments.cashOnDeliveryEnabled),
            noticeEN: trimText(payments.noticeEN, 220),
            noticeAR: trimText(payments.noticeAR, 220)
        },
        fulfillment: {
            deliveryEnabled: hasFulfillmentMethod ? requestedDeliveryEnabled : fallback.fulfillment.deliveryEnabled,
            pickupEnabled: hasFulfillmentMethod ? requestedPickupEnabled : fallback.fulfillment.pickupEnabled,
            pickupNameEN: trimText(fulfillment.pickupNameEN, 100) || fallback.fulfillment.pickupNameEN,
            pickupNameAR: trimText(fulfillment.pickupNameAR, 100) || fallback.fulfillment.pickupNameAR,
            pickupAddressEN: trimText(fulfillment.pickupAddressEN, 180) || fallback.fulfillment.pickupAddressEN,
            pickupAddressAR: trimText(fulfillment.pickupAddressAR, 180) || fallback.fulfillment.pickupAddressAR,
            pickupMapsURL: safeURL(fulfillment.pickupMapsURL, ""),
            openingHoursEN: trimText(fulfillment.openingHoursEN, 160),
            openingHoursAR: trimText(fulfillment.openingHoursAR, 160),
            bahrainRate: boundedNumber(fulfillment.bahrainRate, fallback.fulfillment.bahrainRate, 0, 500),
            khaleejiCashOnDeliverySurcharge: boundedNumber(fulfillment.khaleejiCashOnDeliverySurcharge, fallback.fulfillment.khaleejiCashOnDeliverySurcharge, 0, 500),
            maximumKhaleejiWeightGrams: boundedNumber(fulfillment.maximumKhaleejiWeightGrams, fallback.fulfillment.maximumKhaleejiWeightGrams, 1, 50_000),
            khaleejiTransitEN: trimText(fulfillment.khaleejiTransitEN, 100) || fallback.fulfillment.khaleejiTransitEN,
            khaleejiTransitAR: trimText(fulfillment.khaleejiTransitAR, 100) || fallback.fulfillment.khaleejiTransitAR,
            khaleejiTiers: normalizedTiers.length ? normalizedTiers : fallback.fulfillment.khaleejiTiers
        },
        release: {
            maintenanceEnabled: Boolean(release.maintenanceEnabled),
            checkoutMaintenanceEnabled: Boolean(release.checkoutMaintenanceEnabled),
            minimumSupportedVersion: safeVersion(release.minimumSupportedVersion),
            latestVersion: safeVersion(release.latestVersion),
            appStoreURL: safeURL(release.appStoreURL, ""),
            titleEN: trimText(release.titleEN, 80) || fallback.release.titleEN,
            titleAR: trimText(release.titleAR, 80) || fallback.release.titleAR,
            messageEN: trimText(release.messageEN, 300) || fallback.release.messageEN,
            messageAR: trimText(release.messageAR, 300) || fallback.release.messageAR,
            updateMessageEN: trimText(release.updateMessageEN, 220) || fallback.release.updateMessageEN,
            updateMessageAR: trimText(release.updateMessageAR, 220) || fallback.release.updateMessageAR
        },
        loyalty: {
            pointsPerBHD: boundedNumber(loyalty.pointsPerBHD, fallback.loyalty.pointsPerBHD, 0, 10_000),
            silverThreshold,
            goldThreshold,
            rewardStep: Math.round(boundedNumber(loyalty.rewardStep, fallback.loyalty.rewardStep, 1, 1_000_000)),
            rewards: normalizedRewards.length ? normalizedRewards : fallback.loyalty.rewards
        },
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

function webPushConfigured() {
    return Boolean(webPushVapidPublicKey && webPushVapidPrivateKey && webPushVapidSubject);
}

function configureWebPush() {
    if (!webPushConfigured()) return false;
    webPush.setVapidDetails(webPushVapidSubject, webPushVapidPublicKey, webPushVapidPrivateKey);
    return true;
}

function normalizeWebPushSubscription(value) {
    const endpoint = String(value?.endpoint || "").trim();
    const auth = String(value?.keys?.auth || "").trim();
    const p256dh = String(value?.keys?.p256dh || "").trim();
    if (!endpoint.startsWith("https://") || !auth || !p256dh) return null;
    return { endpoint, expirationTime: value.expirationTime || null, keys: { auth, p256dh } };
}

async function saveAdminPushSubscription(adminUsername, value) {
    const subscription = normalizeWebPushSubscription(value);
    if (!subscription) throw new Error("INVALID_WEB_PUSH_SUBSCRIPTION");
    const timestamp = new Date().toISOString();

    if (database.isEnabled()) {
        await database.query(
            `INSERT INTO admin_push_subscriptions
             (endpoint, admin_username, subscription, created_at, updated_at, last_sent_at)
             VALUES ($1, $2, $3::jsonb, $4, $4, NULL)
             ON CONFLICT (endpoint) DO UPDATE SET
                admin_username = EXCLUDED.admin_username,
                subscription = EXCLUDED.subscription,
                updated_at = EXCLUDED.updated_at`,
            [subscription.endpoint, adminUsername, JSON.stringify(subscription), timestamp]
        );
        return subscription;
    }

    const store = readJSON(adminPushSubscriptionsStorePath);
    const subscriptions = Array.isArray(store.subscriptions) ? store.subscriptions : [];
    const index = subscriptions.findIndex((entry) => entry.subscription?.endpoint === subscription.endpoint);
    const record = { adminUsername, subscription, createdAt: index >= 0 ? subscriptions[index].createdAt : timestamp, updatedAt: timestamp };
    if (index >= 0) subscriptions[index] = record;
    else subscriptions.push(record);
    store.subscriptions = subscriptions;
    writeJSON(adminPushSubscriptionsStorePath, store);
    return subscription;
}

async function removeAdminPushSubscription(endpoint) {
    const normalizedEndpoint = String(endpoint || "").trim();
    if (!normalizedEndpoint) return;
    if (database.isEnabled()) {
        await database.query("DELETE FROM admin_push_subscriptions WHERE endpoint = $1", [normalizedEndpoint]);
        return;
    }
    const store = readJSON(adminPushSubscriptionsStorePath);
    store.subscriptions = (store.subscriptions || []).filter((entry) => entry.subscription?.endpoint !== normalizedEndpoint);
    writeJSON(adminPushSubscriptionsStorePath, store);
}

async function adminPushSubscriptions() {
    if (database.isEnabled()) {
        const result = await database.query("SELECT subscription FROM admin_push_subscriptions ORDER BY created_at ASC");
        return result.rows.map((row) => row.subscription).filter(Boolean);
    }
    return (readJSON(adminPushSubscriptionsStorePath).subscriptions || []).map((entry) => entry.subscription).filter(Boolean);
}

function adminOrderNotificationPayload(order) {
    const itemCount = (order.items || []).reduce((total, item) => total + Math.max(0, Number(item.quantity || 0)), 0);
    return {
        title: "New Talla order",
        body: `${order.title || order.id} • ${order.total || "Total unavailable"}${itemCount ? ` • ${itemCount} item${itemCount === 1 ? "" : "s"}` : ""}`,
        url: "/admin/#orders-section",
        order
    };
}

function publishAdminOrderEvent(order) {
    const event = `event: new-order\ndata: ${JSON.stringify(order)}\n\n`;
    for (const response of adminOrderStreamClients) {
        try {
            response.write(event);
        } catch {
            adminOrderStreamClients.delete(response);
        }
    }
}

async function sendAdminNewOrderPush(order) {
    if (!configureWebPush()) return { configured: false, targetCount: 0, sentCount: 0 };
    const subscriptions = await adminPushSubscriptions();
    let sentCount = 0;
    await Promise.all(subscriptions.map(async (subscription) => {
        try {
            await webPush.sendNotification(subscription, JSON.stringify(adminOrderNotificationPayload(order)), { TTL: 300, urgency: "high" });
            sentCount += 1;
        } catch (error) {
            if ([404, 410].includes(error.statusCode)) {
                await removeAdminPushSubscription(subscription.endpoint);
                return;
            }
            console.error("Admin order push failed:", error.statusCode || error.code || error.message || "WEB_PUSH_FAILED");
        }
    }));
    return { configured: true, targetCount: subscriptions.length, sentCount };
}

function announceNewAdminOrder(order) {
    const orderID = String(order.id || "");
    const now = Date.now();
    for (const [announcedID, announcedAt] of announcedAdminOrderIDs) {
        if (now - announcedAt > 10 * 60 * 1000) announcedAdminOrderIDs.delete(announcedID);
    }
    if (!orderID || announcedAdminOrderIDs.has(orderID)) return;
    announcedAdminOrderIDs.set(orderID, now);
    const adminOrder = { ...order, email: normalizeEmail(order.email) };
    publishAdminOrderEvent(adminOrder);
    void sendAdminNewOrderPush(adminOrder).catch((error) => {
        console.error("Admin order notification failed:", error.code || error.message || "ADMIN_ORDER_PUSH_FAILED");
    });
    void sendAdminNativeNewOrderPush(adminOrder).catch((error) => {
        console.error("Native admin order notification failed:", error.code || error.message || "ADMIN_NATIVE_PUSH_FAILED");
    });
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

function remotePushConfigured(topic = apnsBundleID) {
    return Boolean(apnsKeyID && apnsTeamID && topic && (apnsPrivateKeyPath || apnsPrivateKeyBase64));
}

function normalizeAPNSEnvironment(value) {
    return String(value || "").trim().toLowerCase() === "sandbox" ? "sandbox" : "production";
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

function apnsBearerToken(topic = apnsBundleID) {
    if (!remotePushConfigured(topic)) {
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
    return Boolean(adminUsers.length && adminSessionSecret);
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
    return hashToken(token);
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

function createAdminSession(principal) {
    pruneAdminSessions();
    const sessionID = crypto.randomBytes(24).toString("hex");
    const expiresAt = Date.now() + adminSessionHours * 60 * 60 * 1000;
    const sessionPrincipal = typeof principal === "string"
        ? { username: principal, role: "owner", permissions: ["*"] }
        : principal;
    adminSessions.set(sessionID, { ...sessionPrincipal, expiresAt });
    const signedValue = `${sessionID}.${signSessionValue(sessionID)}`;

    return {
        username: sessionPrincipal.username,
        role: sessionPrincipal.role,
        permissions: sessionPrincipal.permissions,
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
        role: session.role,
        permissions: session.permissions,
        expiresAt: session.expiresAt
    };
}

function parseAdminLogin(body) {
    const username = String(body.username || "").trim();
    const password = String(body.password || "");
    return { username, password };
}

function createCustomerAccessToken(email) {
    const pair = createTokenPair({ accessTokenHours: customerTokenHours, refreshTokenDays: customerRefreshTokenDays });
    return { ...pair, tokenHash: pair.accessTokenHash, email: normalizeEmail(email) };
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
    const familyID = `custfam_${crypto.randomBytes(18).toString("hex")}`;
    const createdAt = new Date().toISOString();
    const client = await database.connect();
    try {
        await client.query("BEGIN");
        await client.query(
            `INSERT INTO customer_sessions
             (id, email, token_hash, created_at, expires_at, revoked_at, family_id, refresh_expires_at)
             VALUES ($1, $2, $3, $4, $5, NULL, $6, $7)`,
            [id, email, session.accessTokenHash, createdAt, session.expiresAt, familyID, session.refreshExpiresAt]
        );
        await client.query(
            `INSERT INTO customer_refresh_tokens
             (token_hash, session_id, family_id, created_at, expires_at, consumed_at, replaced_by_token_hash)
             VALUES ($1, $2, $3, $4, $5, NULL, NULL)`,
            [session.refreshTokenHash, id, familyID, createdAt, session.refreshExpiresAt]
        );
        await client.query("COMMIT");
    } catch (error) {
        await client.query("ROLLBACK");
        throw error;
    } finally {
        client.release();
    }
    return publicTokenPair(session);
}

async function rotateCustomerSession(refreshToken) {
    if (!database.isEnabled() || !String(refreshToken || "").trim()) return null;
    const refreshHash = hashCustomerToken(refreshToken);
    const client = await database.connect();
    try {
        await client.query("BEGIN");
        const result = await client.query(
            `SELECT rt.session_id, rt.family_id, rt.expires_at, rt.consumed_at, cs.email
             FROM customer_refresh_tokens rt
             JOIN customer_sessions cs ON cs.id = rt.session_id
             WHERE rt.token_hash = $1
             FOR UPDATE`,
            [refreshHash]
        );
        if (result.rowCount === 0) {
            await client.query("ROLLBACK");
            return null;
        }
        const record = result.rows[0];
        if (record.consumed_at) {
            await client.query("UPDATE customer_sessions SET revoked_at = COALESCE(revoked_at, NOW()) WHERE family_id = $1", [record.family_id]);
            await client.query("COMMIT");
            const error = new Error("REFRESH_TOKEN_REUSED");
            error.code = "REFRESH_TOKEN_REUSED";
            error.transactionCommitted = true;
            throw error;
        }
        if (new Date(record.expires_at).getTime() <= Date.now()) {
            await client.query("UPDATE customer_sessions SET revoked_at = COALESCE(revoked_at, NOW()) WHERE id = $1", [record.session_id]);
            await client.query("COMMIT");
            return null;
        }

        const next = createCustomerAccessToken(record.email);
        const nextID = `custsess_${Date.now()}_${crypto.randomBytes(3).toString("hex")}`;
        const createdAt = new Date().toISOString();
        await client.query(
            `INSERT INTO customer_sessions
             (id, email, token_hash, created_at, expires_at, revoked_at, family_id, rotated_from_session_id, refresh_expires_at)
             VALUES ($1, $2, $3, $4, $5, NULL, $6, $7, $8)`,
            [nextID, record.email, next.accessTokenHash, createdAt, next.expiresAt, record.family_id, record.session_id, next.refreshExpiresAt]
        );
        await client.query(
            `UPDATE customer_refresh_tokens SET consumed_at = NOW(), replaced_by_token_hash = $2 WHERE token_hash = $1`,
            [refreshHash, next.refreshTokenHash]
        );
        await client.query(
            `INSERT INTO customer_refresh_tokens
             (token_hash, session_id, family_id, created_at, expires_at, consumed_at, replaced_by_token_hash)
             VALUES ($1, $2, $3, $4, $5, NULL, NULL)`,
            [next.refreshTokenHash, nextID, record.family_id, createdAt, next.refreshExpiresAt]
        );
        await client.query("UPDATE customer_sessions SET revoked_at = COALESCE(revoked_at, NOW()) WHERE id = $1", [record.session_id]);
        await client.query("COMMIT");
        return publicTokenPair(next);
    } catch (error) {
        if (!error.transactionCommitted) {
            try { await client.query("ROLLBACK"); } catch {}
        }
        throw error;
    } finally {
        client.release();
    }
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

    const principal = mobileAdminPrincipal(customer.email, adminAppRoles);
    if (!principal) {
        sendJSON(response, 403, { error: "This account does not have admin access." });
        return false;
    }
    return principal;
}

function normalizeEmail(email) {
    return String(email || "").trim().toLowerCase();
}

function normalizeCountryCode(value, fallback = "") {
    const countryCode = String(value || "").trim().toUpperCase();
    return /^[A-Z]{2}$/.test(countryCode) ? countryCode : fallback;
}

function requestBodyTooLargeError() {
    const error = new Error("REQUEST_BODY_TOO_LARGE");
    error.code = "REQUEST_BODY_TOO_LARGE";
    return error;
}

function readRawBody(request, maxBytes = 1_048_576) {
    if (request.tallaRawBody !== undefined) {
        return Promise.resolve(request.tallaRawBody);
    }
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

            request.tallaRawBody = body;
            resolve(body);
        });

        request.on("error", reject);
    });
}

async function readBody(request, maxBytes = 1_048_576) {
    const body = await readRawBody(request, maxBytes);
    if (!body) return {};
    return JSON.parse(body);
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
    if (pointsBalance >= 300) {
        return [
            "Everything in Silver",
            "Priority access to limited roast drops",
            "Exclusive Gold-only reward unlocks and concierge WhatsApp support"
        ];
    }

    if (pointsBalance >= 150) {
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

        const customerLibraryStore = readJSON(customerLibraryStorePath);
        if (customerLibraryStore.customerLibrary?.[normalizedCurrentEmail]) {
            customerLibraryStore.customerLibrary[normalizedNextEmail] = customerLibraryStore.customerLibrary[normalizedCurrentEmail];
            delete customerLibraryStore.customerLibrary[normalizedCurrentEmail];
            writeJSON(customerLibraryStorePath, customerLibraryStore);
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

        const customerLibraryStore = readJSON(customerLibraryStorePath);
        if (customerLibraryStore.customerLibrary) {
            delete customerLibraryStore.customerLibrary[normalizedEmail];
            writeJSON(customerLibraryStorePath, customerLibraryStore);
        }

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
        queueWalletPassUpdate(email);
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

    const updatedAccount = {
        ...working,
        transactions: await getLoyaltyTransactions(email)
    };
    queueWalletPassUpdate(email);
    return updatedAccount;
}

async function ensureWalletPassRecord(email, memberID, passTypeIdentifier) {
    if (!database.isEnabled()) {
        const store = readJSON(walletPassesStorePath);
        store.passes = store.passes || {};
        const existing = Object.values(store.passes).find((pass) => normalizeEmail(pass.email) === email);
        const timestamp = Date.now();
        if (existing) {
            existing.serialNumber = existing.serialNumber || Object.keys(store.passes).find((key) => store.passes[key] === existing);
            existing.passTypeIdentifier = passTypeIdentifier;
            existing.authenticationToken = existing.authenticationToken || crypto.randomBytes(32).toString("hex");
            existing.updateTag = Number(existing.updateTag || timestamp);
            existing.lastGeneratedAt = new Date(timestamp).toISOString();
            writeJSON(walletPassesStorePath, store);
            return existing;
        }

        const record = {
            email,
            serialNumber: `${memberID}-${crypto.randomBytes(4).toString("hex").toUpperCase()}`,
            passTypeIdentifier,
            authenticationToken: crypto.randomBytes(32).toString("hex"),
            updateTag: timestamp,
            lastGeneratedAt: new Date(timestamp).toISOString()
        };
        store.passes[record.serialNumber] = record;
        writeJSON(walletPassesStorePath, store);
        return record;
    }

    const existing = await database.query(
        `SELECT email, serial_number, pass_type_identifier, authentication_token, update_tag, last_generated_at
         FROM wallet_passes
         WHERE email = $1`,
        [email]
    );

    const timestamp = new Date().toISOString();
    if (existing.rowCount > 0) {
        const row = existing.rows[0];
        const authenticationToken = row.authentication_token || crypto.randomBytes(32).toString("hex");
        await database.query(
            `UPDATE wallet_passes
             SET pass_type_identifier = $2,
                 authentication_token = $3,
                 last_generated_at = $4
             WHERE email = $1`,
            [email, passTypeIdentifier, authenticationToken, timestamp]
        );
        return {
            email,
            serialNumber: row.serial_number,
            passTypeIdentifier,
            authenticationToken,
            updateTag: Number(row.update_tag || 0),
            lastGeneratedAt: timestamp
        };
    }

    const serialNumber = `${memberID}-${crypto.randomBytes(4).toString("hex").toUpperCase()}`;
    const authenticationToken = crypto.randomBytes(32).toString("hex");
    const updateTag = Date.now();
    await database.query(
        `INSERT INTO wallet_passes
         (email, serial_number, pass_type_identifier, authentication_token, update_tag, last_generated_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $6)`,
        [email, serialNumber, passTypeIdentifier, authenticationToken, updateTag, timestamp]
    );
    return { email, serialNumber, passTypeIdentifier, authenticationToken, updateTag, lastGeneratedAt: timestamp };
}

function validWalletIdentifier(value, maxLength = 160) {
    const normalized = String(value || "").trim();
    return normalized.length > 0
        && normalized.length <= maxLength
        && /^[A-Za-z0-9._-]+$/.test(normalized);
}

function walletAuthorizationToken(request) {
    const authorization = String(request.headers.authorization || "");
    return authorization.startsWith("ApplePass ") ? authorization.slice("ApplePass ".length) : "";
}

function secureStringEqual(first, second) {
    const firstBuffer = Buffer.from(String(first || ""));
    const secondBuffer = Buffer.from(String(second || ""));
    return firstBuffer.length === secondBuffer.length
        && firstBuffer.length > 0
        && crypto.timingSafeEqual(firstBuffer, secondBuffer);
}

async function walletPassRecordBySerial(passTypeIdentifier, serialNumber) {
    if (!database.isEnabled()) {
        const store = readJSON(walletPassesStorePath);
        const record = store.passes?.[serialNumber];
        return record?.passTypeIdentifier === passTypeIdentifier ? record : null;
    }

    const result = await database.query(
        `SELECT email, serial_number, pass_type_identifier, authentication_token, update_tag, last_generated_at
         FROM wallet_passes
         WHERE pass_type_identifier = $1 AND serial_number = $2`,
        [passTypeIdentifier, serialNumber]
    );
    if (result.rowCount === 0) {
        return null;
    }

    const row = result.rows[0];
    return {
        email: normalizeEmail(row.email),
        serialNumber: row.serial_number,
        passTypeIdentifier: row.pass_type_identifier,
        authenticationToken: row.authentication_token,
        updateTag: Number(row.update_tag || 0),
        lastGeneratedAt: row.last_generated_at instanceof Date
            ? row.last_generated_at.toISOString()
            : row.last_generated_at
    };
}

async function registerWalletPassDevice({ deviceLibraryIdentifier, pushToken, serialNumber }) {
    const timestamp = new Date().toISOString();
    if (!database.isEnabled()) {
        const store = readJSON(walletPassesStorePath);
        store.devices = store.devices || {};
        store.registrations = Array.isArray(store.registrations) ? store.registrations : [];
        const alreadyRegistered = store.registrations.some((registration) => (
            registration.deviceLibraryIdentifier === deviceLibraryIdentifier
                && registration.serialNumber === serialNumber
        ));
        store.devices[deviceLibraryIdentifier] = { pushToken, updatedAt: timestamp };
        if (!alreadyRegistered) {
            store.registrations.push({ deviceLibraryIdentifier, serialNumber, createdAt: timestamp });
        }
        writeJSON(walletPassesStorePath, store);
        return !alreadyRegistered;
    }

    await database.query(
        `INSERT INTO wallet_pass_devices (device_library_identifier, push_token, updated_at)
         VALUES ($1, $2, $3)
         ON CONFLICT (device_library_identifier)
         DO UPDATE SET push_token = EXCLUDED.push_token, updated_at = EXCLUDED.updated_at`,
        [deviceLibraryIdentifier, pushToken, timestamp]
    );
    const result = await database.query(
        `INSERT INTO wallet_pass_registrations (device_library_identifier, serial_number, created_at)
         VALUES ($1, $2, $3)
         ON CONFLICT DO NOTHING`,
        [deviceLibraryIdentifier, serialNumber, timestamp]
    );
    return result.rowCount > 0;
}

async function unregisterWalletPassDevice(deviceLibraryIdentifier, serialNumber) {
    if (!database.isEnabled()) {
        const store = readJSON(walletPassesStorePath);
        store.registrations = (store.registrations || []).filter((registration) => !(
            registration.deviceLibraryIdentifier === deviceLibraryIdentifier
                && registration.serialNumber === serialNumber
        ));
        const hasOtherRegistrations = store.registrations.some((registration) => (
            registration.deviceLibraryIdentifier === deviceLibraryIdentifier
        ));
        if (!hasOtherRegistrations && store.devices) {
            delete store.devices[deviceLibraryIdentifier];
        }
        writeJSON(walletPassesStorePath, store);
        return;
    }

    await database.query(
        `DELETE FROM wallet_pass_registrations
         WHERE device_library_identifier = $1 AND serial_number = $2`,
        [deviceLibraryIdentifier, serialNumber]
    );
    await database.query(
        `DELETE FROM wallet_pass_devices d
         WHERE d.device_library_identifier = $1
           AND NOT EXISTS (
               SELECT 1 FROM wallet_pass_registrations r
               WHERE r.device_library_identifier = d.device_library_identifier
           )`,
        [deviceLibraryIdentifier]
    );
}

async function updatedWalletPassesForDevice(deviceLibraryIdentifier, passTypeIdentifier, previousUpdateTag) {
    const parsedPrevious = Number(previousUpdateTag || 0);
    const previous = Number.isFinite(parsedPrevious) && parsedPrevious >= 0 ? parsedPrevious : 0;
    if (!database.isEnabled()) {
        const store = readJSON(walletPassesStorePath);
        const serialNumbers = (store.registrations || [])
            .filter((registration) => registration.deviceLibraryIdentifier === deviceLibraryIdentifier)
            .map((registration) => store.passes?.[registration.serialNumber])
            .filter((pass) => pass?.passTypeIdentifier === passTypeIdentifier && Number(pass.updateTag || 0) > previous)
            .map((pass) => pass.serialNumber);
        const lastUpdated = serialNumbers.reduce(
            (latest, serialNumber) => Math.max(latest, Number(store.passes[serialNumber].updateTag || 0)),
            previous
        );
        return { serialNumbers, lastUpdated };
    }

    const result = await database.query(
        `SELECT p.serial_number, p.update_tag
         FROM wallet_pass_registrations r
         JOIN wallet_passes p ON p.serial_number = r.serial_number
         WHERE r.device_library_identifier = $1
           AND p.pass_type_identifier = $2
           AND p.update_tag > $3
         ORDER BY p.update_tag ASC`,
        [deviceLibraryIdentifier, passTypeIdentifier, previous]
    );
    return {
        serialNumbers: result.rows.map((row) => row.serial_number),
        lastUpdated: result.rows.reduce((latest, row) => Math.max(latest, Number(row.update_tag || 0)), previous)
    };
}

async function walletPushDevicesForSerial(serialNumber) {
    if (!database.isEnabled()) {
        const store = readJSON(walletPassesStorePath);
        return (store.registrations || [])
            .filter((registration) => registration.serialNumber === serialNumber)
            .map((registration) => ({
                deviceLibraryIdentifier: registration.deviceLibraryIdentifier,
                pushToken: store.devices?.[registration.deviceLibraryIdentifier]?.pushToken || ""
            }))
            .filter((device) => device.pushToken);
    }

    const result = await database.query(
        `SELECT d.device_library_identifier, d.push_token
         FROM wallet_pass_registrations r
         JOIN wallet_pass_devices d ON d.device_library_identifier = r.device_library_identifier
         WHERE r.serial_number = $1`,
        [serialNumber]
    );
    return result.rows.map((row) => ({
        deviceLibraryIdentifier: row.device_library_identifier,
        pushToken: row.push_token
    }));
}

async function removeWalletPushDevice(deviceLibraryIdentifier) {
    if (!database.isEnabled()) {
        const store = readJSON(walletPassesStorePath);
        if (store.devices) {
            delete store.devices[deviceLibraryIdentifier];
        }
        store.registrations = (store.registrations || []).filter((registration) => (
            registration.deviceLibraryIdentifier !== deviceLibraryIdentifier
        ));
        writeJSON(walletPassesStorePath, store);
        return;
    }
    await database.query(
        `DELETE FROM wallet_pass_devices WHERE device_library_identifier = $1`,
        [deviceLibraryIdentifier]
    );
}

function walletPushTLSCredentials() {
    if (walletPushCredentialsCache) {
        return walletPushCredentialsCache;
    }
    ensurePassSigningFiles();
    const tempDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-wallet-push-"));
    try {
        const certificatePath = walletPassCertificateBase64
            ? path.join(tempDirectory, "wallet-pass.p12")
            : walletPassCertificatePath;
        if (walletPassCertificateBase64) {
            writeDecodedSecret(certificatePath, walletPassCertificateBase64);
        }
        const certPath = path.join(tempDirectory, "cert.pem");
        const keyPath = path.join(tempDirectory, "key.pem");
        const passwordArgument = `pass:${walletPassCertificatePassword}`;
        execFileSync("/usr/bin/openssl", ["pkcs12", "-legacy", "-in", certificatePath, "-clcerts", "-nokeys", "-out", certPath, "-passin", passwordArgument]);
        execFileSync("/usr/bin/openssl", ["pkcs12", "-legacy", "-in", certificatePath, "-nocerts", "-nodes", "-out", keyPath, "-passin", passwordArgument]);
        walletPushCredentialsCache = {
            cert: fs.readFileSync(certPath),
            key: fs.readFileSync(keyPath)
        };
        return walletPushCredentialsCache;
    } finally {
        fs.rmSync(tempDirectory, { recursive: true, force: true });
    }
}

async function sendWalletPassPush(device, passTypeIdentifier) {
    const pushToken = normalizeDeviceToken(device.pushToken);
    if (!pushToken) {
        return false;
    }
    let credentials;
    try {
        credentials = walletPushTLSCredentials();
    } catch (error) {
        console.error("Wallet pass push certificate is unavailable.");
        return false;
    }

    return new Promise((resolve) => {
        let settled = false;
        const finish = (value) => {
            if (!settled) {
                settled = true;
                resolve(value);
            }
        };
        const client = http2.connect("https://api.push.apple.com", credentials);
        client.on("error", () => {
            client.close();
            finish(false);
        });
        const pushRequest = client.request({
            ":method": "POST",
            ":path": `/3/device/${pushToken}`,
            "apns-topic": passTypeIdentifier,
            "apns-push-type": "background",
            "apns-priority": "5"
        });
        let statusCode = 0;
        let responseBody = "";
        pushRequest.setEncoding("utf8");
        pushRequest.on("response", (headers) => {
            statusCode = Number(headers[http2.constants.HTTP2_HEADER_STATUS] || 0);
        });
        pushRequest.on("data", (chunk) => {
            responseBody += chunk;
        });
        pushRequest.on("end", async () => {
            client.close();
            if (statusCode === 200) {
                finish(true);
                return;
            }
            try {
                const reason = responseBody ? JSON.parse(responseBody).reason : "";
                if (["BadDeviceToken", "DeviceTokenNotForTopic", "Unregistered"].includes(reason)) {
                    await removeWalletPushDevice(device.deviceLibraryIdentifier);
                }
            } catch (error) {
                // Ignore malformed APNs error bodies.
            }
            finish(false);
        });
        pushRequest.on("error", () => {
            client.close();
            finish(false);
        });
        pushRequest.end("{}");
    });
}

async function markWalletPassUpdatedAndNotify(email) {
    let record;
    const updateTag = Date.now();
    if (!database.isEnabled()) {
        const store = readJSON(walletPassesStorePath);
        record = Object.values(store.passes || {}).find((pass) => normalizeEmail(pass.email) === email);
        if (!record) {
            return;
        }
        record.updateTag = Math.max(updateTag, Number(record.updateTag || 0) + 1);
        writeJSON(walletPassesStorePath, store);
    } else {
        const result = await database.query(
            `UPDATE wallet_passes
             SET update_tag = GREATEST($2, update_tag + 1), updated_at = NOW()
             WHERE email = $1
             RETURNING email, serial_number, pass_type_identifier, authentication_token, update_tag`,
            [email, updateTag]
        );
        if (result.rowCount === 0) {
            return;
        }
        const row = result.rows[0];
        record = {
            email: normalizeEmail(row.email),
            serialNumber: row.serial_number,
            passTypeIdentifier: row.pass_type_identifier,
            authenticationToken: row.authentication_token,
            updateTag: Number(row.update_tag)
        };
    }

    const devices = await walletPushDevicesForSerial(record.serialNumber);
    await Promise.all(devices.map((device) => sendWalletPassPush(device, record.passTypeIdentifier)));
}

function queueWalletPassUpdate(email) {
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) {
        return;
    }
    const existingTimer = walletPassUpdateTimers.get(normalizedEmail);
    if (existingTimer) {
        clearTimeout(existingTimer);
    }
    const timer = setTimeout(() => {
        walletPassUpdateTimers.delete(normalizedEmail);
        void markWalletPassUpdatedAndNotify(normalizedEmail).catch((error) => {
            console.error("Wallet pass update notification failed:", error.code || error.message || "WALLET_PUSH_FAILED");
        });
    }, 250);
    timer.unref?.();
    walletPassUpdateTimers.set(normalizedEmail, timer);
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

    return Math.max(0, Math.round(numericOrderTotal(order) * runtimeAppSettings.value.loyalty.pointsPerBHD));
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

async function customerLibraryPayload(email) {
    const normalizedEmail = normalizeEmail(email);
    if (!normalizedEmail) return emptyCustomerLibrary();

    if (database.isEnabled()) {
        const [favoriteResult, recentResult, journalResult] = await Promise.all([
            database.query(
                `SELECT product_id FROM customer_product_library
                 WHERE email = $1 AND is_favorite = TRUE
                 ORDER BY favorite_updated_at DESC NULLS LAST, product_id`,
                [normalizedEmail]
            ),
            database.query(
                `SELECT product_id FROM customer_product_library
                 WHERE email = $1 AND last_viewed_at IS NOT NULL
                 ORDER BY last_viewed_at DESC
                 LIMIT 20`,
                [normalizedEmail]
            ),
            database.query(
                `SELECT id, title, method, coffee_grams, ratio, water_grams, brew_time_seconds, rating, notes, created_at
                 FROM brew_journal_entries
                 WHERE email = $1
                 ORDER BY created_at DESC
                 LIMIT 20`,
                [normalizedEmail]
            )
        ]);
        return {
            favorites: favoriteResult.rows.map((row) => row.product_id),
            recentlyViewed: recentResult.rows.map((row) => row.product_id),
            brewJournal: journalResult.rows.map((row) => ({
                id: row.id,
                title: row.title,
                method: row.method,
                coffeeGrams: row.coffee_grams,
                ratio: row.ratio,
                waterGrams: row.water_grams,
                brewTimeSeconds: row.brew_time_seconds,
                rating: row.rating,
                notes: row.notes,
                createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at
            }))
        };
    }

    const store = readJSON(customerLibraryStorePath);
    return mergeCustomerLibraryRecords(emptyCustomerLibrary(), store.customerLibrary?.[normalizedEmail] || {});
}

async function saveDatabaseBrewJournalEntry(email, entry) {
    await database.query(
        `INSERT INTO brew_journal_entries
         (email, id, title, method, coffee_grams, ratio, water_grams, brew_time_seconds, rating, notes, created_at, updated_at)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, NOW())
         ON CONFLICT (email, id)
         DO UPDATE SET title = EXCLUDED.title,
                       method = EXCLUDED.method,
                       coffee_grams = EXCLUDED.coffee_grams,
                       ratio = EXCLUDED.ratio,
                       water_grams = EXCLUDED.water_grams,
                       brew_time_seconds = EXCLUDED.brew_time_seconds,
                       rating = EXCLUDED.rating,
                       notes = EXCLUDED.notes,
                       updated_at = NOW()`,
        [email, entry.id, entry.title, entry.method, entry.coffeeGrams, entry.ratio, entry.waterGrams,
            entry.brewTimeSeconds === null ? null : Math.round(entry.brewTimeSeconds), entry.rating, entry.notes, entry.createdAt]
    );
}

async function mutateCustomerLibrary(email, body) {
    const normalizedEmail = normalizeEmail(email);
    const action = String(body?.action || "").trim();
    if (!normalizedEmail || !["merge", "setFavorite", "recordRecent", "clearRecent", "saveJournal", "deleteJournal"].includes(action)) {
        return null;
    }

    if (!database.isEnabled()) {
        const store = readJSON(customerLibraryStorePath);
        const current = mergeCustomerLibraryRecords(emptyCustomerLibrary(), store.customerLibrary?.[normalizedEmail] || {});
        let next = current;
        if (action === "merge") {
            next = mergeCustomerLibraryRecords(current, body);
        } else if (action === "setFavorite") {
            const productID = normalizeCustomerProductIDs([body.productID], 1)[0];
            if (!productID || typeof body.favorite !== "boolean") return null;
            next = {
                ...current,
                favorites: body.favorite
                    ? normalizeCustomerProductIDs([productID, ...current.favorites])
                    : current.favorites.filter((id) => id !== productID)
            };
        } else if (action === "recordRecent") {
            const productID = normalizeCustomerProductIDs([body.productID], 1)[0];
            if (!productID) return null;
            next = { ...current, recentlyViewed: [productID, ...current.recentlyViewed.filter((id) => id !== productID)].slice(0, 20) };
        } else if (action === "clearRecent") {
            next = { ...current, recentlyViewed: [] };
        } else if (action === "saveJournal") {
            const entry = normalizeBrewJournalEntry(body.journal);
            if (!entry) return null;
            next = {
                ...current,
                brewJournal: [entry, ...current.brewJournal.filter((item) => item.id !== entry.id)]
                    .sort((first, second) => new Date(second.createdAt).getTime() - new Date(first.createdAt).getTime())
                    .slice(0, 20)
            };
        } else {
            const journalID = String(body.journalID || "").trim();
            if (!journalID) return null;
            next = { ...current, brewJournal: current.brewJournal.filter((entry) => entry.id !== journalID) };
        }
        store.customerLibrary = store.customerLibrary || {};
        store.customerLibrary[normalizedEmail] = next;
        writeJSON(customerLibraryStorePath, store);
        return next;
    }

    if (action === "merge") {
        for (const productID of normalizeCustomerProductIDs(body.favorites)) {
            await database.query(
                `INSERT INTO customer_product_library (email, product_id, is_favorite, favorite_updated_at)
                 VALUES ($1, $2, TRUE, NOW())
                 ON CONFLICT (email, product_id)
                 DO UPDATE SET is_favorite = TRUE, favorite_updated_at = NOW()`,
                [normalizedEmail, productID]
            );
        }
        const recentIDs = normalizeCustomerProductIDs(body.recentlyViewed, 20);
        for (const [index, productID] of recentIDs.entries()) {
            await database.query(
                `INSERT INTO customer_product_library (email, product_id, last_viewed_at)
                 VALUES ($1, $2, $3)
                 ON CONFLICT (email, product_id)
                 DO UPDATE SET last_viewed_at = GREATEST(customer_product_library.last_viewed_at, EXCLUDED.last_viewed_at)`,
                [normalizedEmail, productID, new Date(Date.now() - index * 1000).toISOString()]
            );
        }
        for (const entry of (Array.isArray(body.brewJournal) ? body.brewJournal : []).map(normalizeBrewJournalEntry).filter(Boolean).slice(0, 20)) {
            await saveDatabaseBrewJournalEntry(normalizedEmail, entry);
        }
    } else if (action === "setFavorite") {
        const productID = normalizeCustomerProductIDs([body.productID], 1)[0];
        if (!productID || typeof body.favorite !== "boolean") return null;
        await database.query(
            `INSERT INTO customer_product_library (email, product_id, is_favorite, favorite_updated_at)
             VALUES ($1, $2, $3, NOW())
             ON CONFLICT (email, product_id)
             DO UPDATE SET is_favorite = EXCLUDED.is_favorite, favorite_updated_at = NOW()`,
            [normalizedEmail, productID, body.favorite]
        );
    } else if (action === "recordRecent") {
        const productID = normalizeCustomerProductIDs([body.productID], 1)[0];
        if (!productID) return null;
        await database.query(
            `INSERT INTO customer_product_library (email, product_id, last_viewed_at)
             VALUES ($1, $2, NOW())
             ON CONFLICT (email, product_id)
             DO UPDATE SET last_viewed_at = NOW()`,
            [normalizedEmail, productID]
        );
    } else if (action === "clearRecent") {
        await database.query(
            `UPDATE customer_product_library SET last_viewed_at = NULL WHERE email = $1`,
            [normalizedEmail]
        );
    } else if (action === "saveJournal") {
        const entry = normalizeBrewJournalEntry(body.journal);
        if (!entry) return null;
        await saveDatabaseBrewJournalEntry(normalizedEmail, entry);
    } else {
        const journalID = String(body.journalID || "").trim();
        if (!journalID) return null;
        await database.query(`DELETE FROM brew_journal_entries WHERE email = $1 AND id = $2`, [normalizedEmail, journalID]);
    }

    return customerLibraryPayload(normalizedEmail);
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

    const existingOrder = await findOrderByID(order.id);

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
        const recordedOrder = orderRowToRecord(result.rows[0]);
        if (!existingOrder) announceNewAdminOrder({ ...recordedOrder, email: order.email });
        return recordedOrder;
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
    if (!existingOrder) announceNewAdminOrder({ ...nextOrder, email: order.email });
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

function benefitPayQueryErrorDetails(upstreamResponse, payload) {
    const providerResponse = payload?.response && typeof payload.response === "object"
        ? payload.response
        : {};
    const safeValue = (value, maxLength = 120) => String(value || "")
        .replace(/[^A-Za-z0-9 _.,:/#-]/g, "")
        .trim()
        .slice(0, maxLength);
    return {
        upstreamStatus: Number(upstreamResponse?.status) || 0,
        providerStatus: safeValue(payload?.meta?.status, 32),
        providerCode: safeValue(
            providerResponse.error_code || providerResponse.code || payload?.error_code || payload?.code,
            48
        ),
        providerMessage: safeValue(
            providerResponse.error_description
                || providerResponse.message
                || payload?.error_description
                || payload?.message,
            120
        )
    };
}

function benefitPayTransactionIsPending(details) {
    return details.providerStatus.toUpperCase() === "FAILED"
        && /transaction.*(?:does not exist|doesnt exist|not exist|not found)/i.test(details.providerMessage);
}

function wait(milliseconds) {
    return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function queryBenefitPayTransaction(referenceID, options = {}) {
    const body = {
        merchant_id: benefitPayConfiguration.merchantID,
        reference_id: referenceID
    };
    const endpoint = safeConfiguredBenefitURL(
        benefitPayConfiguration.checkStatusURL,
        "BenefitPay check-status URL",
        "/web/v1/merchant/transaction/check-status"
    );
    const retryDelays = Array.isArray(options.retryDelays) ? options.retryDelays : [500, 1_000, 2_000];
    const attempts = Math.max(1, Number(options.attempts) || retryDelays.length + 1);
    let lastPendingDetails = null;
    for (let attempt = 0; attempt < attempts; attempt += 1) {
        let upstreamResponse;
        try {
            upstreamResponse = await fetch(endpoint, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json; charset=utf-8",
                    Accept: "application/json",
                    "X-CLIENT-ID": benefitPayConfiguration.appID,
                    "X-FOO-Signature": createBenefitPayCheckStatusSignature(body),
                    "X-FOO-Signature-Type": "KEYVAL"
                },
                body: JSON.stringify(body),
                signal: AbortSignal.timeout(8_000)
            });
        } catch {
            const error = benefitPaymentError(
                "BENEFITPAY_QUERY_UNAVAILABLE",
                502,
                "BenefitPay could not confirm the transaction."
            );
            error.upstreamStatus = 0;
            throw error;
        }
        const responseText = await upstreamResponse.text();
        if (responseText.length > 131_072) {
            throw benefitPaymentError("BENEFITPAY_RESPONSE_INVALID", 502, "BenefitPay returned an invalid response.");
        }
        let payload;
        try {
            payload = JSON.parse(responseText);
        } catch {
            const error = benefitPaymentError(
                "BENEFITPAY_RESPONSE_INVALID",
                502,
                "BenefitPay returned an invalid response."
            );
            error.upstreamStatus = upstreamResponse.status;
            throw error;
        }
        if (upstreamResponse.ok && payload?.meta?.status === "OK" && payload?.response) {
            return payload.response;
        }
        const details = benefitPayQueryErrorDetails(upstreamResponse, payload);
        if (benefitPayTransactionIsPending(details)) {
            lastPendingDetails = details;
            if (attempt + 1 < attempts) {
                await wait(retryDelays[Math.min(attempt, retryDelays.length - 1)] || 0);
                continue;
            }
            const error = benefitPaymentError(
                "BENEFITPAY_TRANSACTION_PENDING",
                202,
                "BenefitPay is still confirming the transaction."
            );
            Object.assign(error, details);
            throw error;
        }
        const error = benefitPaymentError("BENEFITPAY_QUERY_FAILED", 502, "BenefitPay could not confirm the transaction.");
        Object.assign(error, details);
        throw error;
    }
    const error = benefitPaymentError(
        "BENEFITPAY_TRANSACTION_PENDING",
        202,
        "BenefitPay is still confirming the transaction."
    );
    Object.assign(error, lastPendingDetails || {});
    throw error;
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

async function findBenefitPaymentByOrderID(orderID) {
    const normalizedOrderID = normalizeBenefitIdentifier(orderID);
    if (!normalizedOrderID) {
        return null;
    }
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT *
             FROM benefit_payments
             WHERE order_id = $1
             ORDER BY updated_at DESC
             LIMIT 1`,
            [normalizedOrderID]
        );
        return result.rowCount > 0 ? benefitPaymentRowToRecord(result.rows[0]) : null;
    }
    const store = readJSON(benefitPaymentsStorePath);
    return Object.values(store.payments || {})
        .filter((payment) => timingSafeStringEqual(payment.orderID, normalizedOrderID))
        .sort((left, right) => String(right.updatedAt || "").localeCompare(String(left.updatedAt || "")))[0]
        || null;
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
        const validationIssues = [
            !notification.paymentID ? "paymentID" : "",
            !notification.transactionID ? "transactionID" : "",
            notification.authResponseCode !== "00" ? "authResponseCode" : ""
        ].filter(Boolean);
        if (validationIssues.length > 0) {
            const error = benefitPaymentError("BENEFIT_CAPTURE_INVALID", 409, "BENEFIT capture response is incomplete.");
            error.validationIssues = validationIssues;
            throw error;
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
    if (payment?.status === "Canceled") {
        return "cancelled";
    }
    if (["Declined", "Canceled", "DeniedByRisk", "GatewayError", "HostTimeout", "InitiationFailed"].includes(payment?.status)) {
        return "failure";
    }
    return "pending";
}

function benefitClientPaymentStatus(payment) {
    const state = benefitResultState(payment);
    return {
        status: state === "success"
            ? "succeeded"
            : state === "cancelled" ? "cancelled" : state === "failure" ? "failed" : "pending",
        paid: state === "success"
    };
}

function renderBenefitResultPage(payment) {
    const state = benefitResultState(payment);
    const content = {
        success: {
            title: "Payment confirmed",
            detail: "Your BENEFIT payment was confirmed. You can return to Talla and view your order.",
            accent: "#23603f"
        },
        cancelled: {
            title: "Payment cancelled",
            detail: "The payment was cancelled. No order was marked paid.",
            accent: "#8b2f2f"
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
    const appStatus = benefitClientPaymentStatus(payment).status;
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
        <a href="talla://checkout-return?status=${appStatus}">Return to Talla</a>
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

function benefitGatewayHostEnvironment(hostname) {
    const normalizedHostname = String(hostname || "").trim().toLowerCase();
    if (normalizedHostname === "benefit-gateway.bh"
        || normalizedHostname === "www.benefit-gateway.bh") {
        return "production";
    }
    if (normalizedHostname === "test.benefit-gateway.bh"
        || normalizedHostname === "www.test.benefit-gateway.bh") {
        return "test";
    }
    return "custom";
}

function validateBenefitHostedPaymentURL(value, configuredEndpoint = benefitAPIEndpoint) {
    const hostedURL = safeConfiguredBenefitURL(value, "BENEFIT hosted payment URL");
    const endpointURL = safeConfiguredBenefitURL(
        configuredEndpoint,
        "BENEFIT API endpoint",
        "/payment/API/hosted.htm"
    );
    const matchesEndpointHost = hostedURL.hostname === endpointURL.hostname;
    const endpointEnvironment = benefitGatewayHostEnvironment(endpointURL.hostname);
    const hostedEnvironment = benefitGatewayHostEnvironment(hostedURL.hostname);
    const matchesGatewayEnvironment = endpointEnvironment !== "custom"
        && endpointEnvironment === hostedEnvironment;
    if (!matchesEndpointHost && !matchesGatewayEnvironment) {
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
        "free drink": { detail: "One eligible drink of your choice", expiresInDays: 30 },
        "espresso pour": { detail: "Complimentary espresso or batch brew", expiresInDays: 30 },
        "pastry pairing": { detail: "One pastry on the house", expiresInDays: 21 },
        "signature sip": { detail: "One signature drink on the house", expiresInDays: 30 },
        "eid majlis reward": { detail: "Limited Eid reward for coffee, sweets, or gift boxes", expiresInDays: 14 },
        "coffee bag credit": { detail: "BHD 4.000 off one coffee bag", expiresInDays: 30 },
        "talla box treat": { detail: "Curated reward on a Talla Box", expiresInDays: 45 },
        "gold club gift": { detail: "Premium Gold-tier Talla Club gift", expiresInDays: 60 }
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
    const walletPassRecord = await ensureWalletPassRecord(
        email,
        loyaltyAccount.memberID,
        passJSON.passTypeIdentifier || null
    );

    passJSON.serialNumber = walletPassRecord.serialNumber;
    passJSON.webServiceURL = walletPassWebServiceURL;
    passJSON.authenticationToken = walletPassRecord.authenticationToken;
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
    passJSON.storeCard.auxiliaryFields = [
        {
            key: "bottle_reward",
            value: "1 bottle = 1 free drink"
        }
    ];
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
    const loyalty = runtimeAppSettings.value.loyalty;
    if (pointsBalance >= loyalty.goldThreshold) return "Gold";
    if (pointsBalance >= loyalty.silverThreshold) return "Silver";
    return "Bronze";
}

function nextRewardText(pointsBalance) {
    const threshold = runtimeAppSettings.value.loyalty.rewardStep;
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
        return "Waiting for availability";
    }

    if (previousRecord && previousRecord.isAvailableForSale === false && record.isAvailableForSale === true) {
        return "Back in stock";
    }

    return "Available now";
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
    const normalized = String(deviceToken || "").trim();
    if (normalized.length < 16 || normalized.length > 4096 || !/^[A-Za-z0-9:_-]+$/.test(normalized)) return "";
    return /^[a-fA-F0-9]+$/.test(normalized) && normalized.length % 2 === 0
        ? normalized.toLowerCase()
        : normalized;
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

async function adminNativePushDevices() {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT device_token, admin_username, platform, environment, created_at, updated_at, last_sent_at
             FROM admin_push_devices
             ORDER BY updated_at DESC`
        );
        return result.rows.map((row) => ({
            deviceToken: normalizeDeviceToken(row.device_token),
            adminUsername: row.admin_username,
            platform: row.platform,
            environment: normalizeAPNSEnvironment(row.environment),
            createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
            updatedAt: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at,
            lastSentAt: row.last_sent_at instanceof Date ? row.last_sent_at.toISOString() : (row.last_sent_at || null)
        })).filter((device) => device.deviceToken);
    }
    return (readJSON(adminPushDevicesStorePath).devices || [])
        .map((device) => ({
            ...device,
            deviceToken: normalizeDeviceToken(device.deviceToken),
            environment: normalizeAPNSEnvironment(device.environment)
        }))
        .filter((device) => device.deviceToken);
}

async function registerAdminNativePushDevice(adminUsername, deviceToken, platform = "ios", environment = "production") {
    const normalizedToken = normalizeDeviceToken(deviceToken);
    const username = String(adminUsername || "").trim();
    if (!normalizedToken || !username) return null;
    const timestamp = new Date().toISOString();
    const normalizedPlatform = String(platform || "ios").trim().toLowerCase() || "ios";
    const normalizedEnvironment = normalizeAPNSEnvironment(environment);

    if (database.isEnabled()) {
        const result = await database.query(
            `INSERT INTO admin_push_devices
             (device_token, admin_username, platform, environment, created_at, updated_at, last_sent_at)
             VALUES ($1, $2, $3, $4, $5, $5, NULL)
             ON CONFLICT (device_token) DO UPDATE SET
                admin_username = EXCLUDED.admin_username,
                platform = EXCLUDED.platform,
                environment = EXCLUDED.environment,
                updated_at = EXCLUDED.updated_at
             RETURNING device_token`,
            [normalizedToken, username, normalizedPlatform, normalizedEnvironment, timestamp]
        );
        return {
            deviceToken: normalizeDeviceToken(result.rows[0]?.device_token),
            adminUsername: username,
            platform: normalizedPlatform,
            environment: normalizedEnvironment
        };
    }

    const store = readJSON(adminPushDevicesStorePath);
    const devices = Array.isArray(store.devices) ? store.devices : [];
    const index = devices.findIndex((device) => normalizeDeviceToken(device.deviceToken) === normalizedToken);
    const record = {
        deviceToken: normalizedToken,
        adminUsername: username,
        platform: normalizedPlatform,
        environment: normalizedEnvironment,
        createdAt: index >= 0 ? devices[index].createdAt : timestamp,
        updatedAt: timestamp,
        lastSentAt: index >= 0 ? devices[index].lastSentAt || null : null
    };
    if (index >= 0) devices[index] = record;
    else devices.unshift(record);
    store.devices = devices;
    writeJSON(adminPushDevicesStorePath, store);
    return record;
}

async function unregisterAdminNativePushDevice(deviceToken) {
    const normalizedToken = normalizeDeviceToken(deviceToken);
    if (!normalizedToken) return false;
    if (database.isEnabled()) {
        const result = await database.query("DELETE FROM admin_push_devices WHERE device_token = $1 RETURNING device_token", [normalizedToken]);
        return result.rowCount > 0;
    }
    const store = readJSON(adminPushDevicesStorePath);
    const beforeCount = (store.devices || []).length;
    store.devices = (store.devices || []).filter((device) => normalizeDeviceToken(device.deviceToken) !== normalizedToken);
    writeJSON(adminPushDevicesStorePath, store);
    return store.devices.length < beforeCount;
}

async function markAdminPushDeviceSent(deviceToken) {
    const normalizedToken = normalizeDeviceToken(deviceToken);
    if (!normalizedToken) return;
    if (database.isEnabled()) {
        await database.query("UPDATE admin_push_devices SET last_sent_at = NOW(), updated_at = NOW() WHERE device_token = $1", [normalizedToken]);
        return;
    }
    const store = readJSON(adminPushDevicesStorePath);
    store.devices = (store.devices || []).map((device) => normalizeDeviceToken(device.deviceToken) === normalizedToken
        ? { ...device, lastSentAt: new Date().toISOString(), updatedAt: new Date().toISOString() }
        : device);
    writeJSON(adminPushDevicesStorePath, store);
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

const timeSensitiveRemotePushTypes = new Set([
    "admin_new_order",
    "order_ready",
    "order_out_for_delivery",
    "delivery_arriving"
]);

function remotePushPayload(notification) {
    const aps = {
        alert: {
            title: notification.title,
            body: notification.body
        },
        sound: "default"
    };

    if (timeSensitiveRemotePushTypes.has(notification.type)) {
        aps["interruption-level"] = "time-sensitive";
    }

    return {
        aps,
        type: notification.type || "stock_alert",
        orderID: notification.orderID || null,
        productID: notification.productID || null,
        url: notification.url || null
    };
}

async function sendAPNsPushToDevice(deviceToken, notification, options = {}) {
    const normalizedToken = normalizeDeviceToken(deviceToken);
    const topic = options.topic || apnsBundleID;
    if (!normalizedToken || !remotePushConfigured(topic)) {
        return false;
    }

    const useSandbox = options.sandbox ?? apnsUseSandbox;
    const authority = useSandbox
        ? "https://api.sandbox.push.apple.com"
        : "https://api.push.apple.com";
    let authorizationToken = "";

    try {
        authorizationToken = apnsBearerToken(topic);
    } catch (error) {
        return false;
    }

    return await new Promise((resolve) => {
        const client = http2.connect(authority);
        const payload = JSON.stringify(remotePushPayload(notification));

        client.on("error", () => {
            client.close();
            resolve(false);
        });

        const request = client.request({
            ":method": "POST",
            ":path": `/3/device/${normalizedToken}`,
            authorization: `bearer ${authorizationToken}`,
            "apns-topic": topic,
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
                if (options.adminDevice) await markAdminPushDeviceSent(normalizedToken);
                else await markPushDeviceSent(normalizedToken);
                resolve(true);
                return;
            }

            try {
                const parsed = responseBody ? JSON.parse(responseBody) : null;
                const reason = parsed?.reason || "";
                if (["BadDeviceToken", "DeviceTokenNotForTopic", "Unregistered"].includes(reason)) {
                    if (options.adminDevice) await unregisterAdminNativePushDevice(normalizedToken);
                    else await prunePushDevice(normalizedToken);
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

async function sendAdminNativeNewOrderPush(order) {
    if (!remotePushConfigured(apnsAdminBundleID)) {
        return { configured: false, targetCount: 0, sentCount: 0 };
    }
    const devices = await adminNativePushDevices();
    const itemCount = (order.items || []).reduce((total, item) => total + Math.max(0, Number(item.quantity || 0)), 0);
    let sentCount = 0;
    for (const device of devices) {
        const didSend = await sendRemotePushToDevice(device, {
            title: "New Talla order",
            body: `${order.title || order.id} • ${order.total || "Total unavailable"}${itemCount ? ` • ${itemCount} item${itemCount === 1 ? "" : "s"}` : ""}`,
            type: "admin_new_order",
            orderID: order.id,
            url: "talla-admin://orders"
        }, {
            topic: apnsAdminBundleID,
            adminDevice: true,
            sandbox: device.environment === "sandbox"
        });
        if (didSend) sentCount += 1;
    }
    return { configured: true, targetCount: devices.length, sentCount };
}

async function sendRemotePushToDevice(device, notification, options = {}) {
    const platform = String(device?.platform || "ios").toLowerCase();
    const deviceToken = normalizeDeviceToken(typeof device === "string" ? device : device?.deviceToken);
    if (!deviceToken) return false;
    if (platform === "android") {
        const result = await googleMobileServices.sendFCM(deviceToken, notification).catch(() => ({ sent: false }));
        if (result.shouldPrune) await prunePushDevice(deviceToken);
        if (result.sent) await markPushDeviceSent(deviceToken);
        return Boolean(result.sent);
    }
    return sendAPNsPushToDevice(deviceToken, notification, options);
}

async function sendStockAlertPush(email, { title, body, productID }) {
    if (!remotePushConfigured() && !googleMobileServices.fcmConfigured()) {
        return;
    }

    const devices = await pushDevicesForEmail(email);
    for (const device of devices) {
        await sendRemotePushToDevice(device, {
            title,
            body,
            type: "stock_alert",
            productID
        });
    }
}

async function sendOrderReadyPush(email, order) {
    if (!remotePushConfigured() && !googleMobileServices.fcmConfigured()) {
        return { configured: false, targetCount: 0, sentCount: 0 };
    }

    const devices = await pushDevicesForEmail(email);
    let sentCount = 0;
    for (const device of devices) {
        const didSend = await sendRemotePushToDevice(device, {
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
    if (!remotePushConfigured() && !googleMobileServices.fcmConfigured()) {
        return { configured: false, targetCount: 0, sentCount: 0 };
    }

    const devices = await allPushDevices();
    let sentCount = 0;
    for (const device of devices) {
        const didSend = await sendRemotePushToDevice(device, {
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
        countryCode: normalizeCountryCode(row.country_code, "BH"),
        notes: row.notes,
        isPreferred: row.is_preferred
    };
}

async function addressesFor(email) {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, label, full_name, phone, line1, city, country_code, notes, is_preferred, created_at
             FROM addresses
             WHERE email = $1
             ORDER BY is_preferred DESC, created_at DESC`,
            [email]
        );
        return result.rows.map(addressRowToRecord);
    }

    const store = readJSON(addressesStorePath);
    return (store.addresses[email] || []).map((address) => ({
        ...address,
        countryCode: normalizeCountryCode(address.countryCode, "BH")
    }));
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
                     country_code = $8,
                     notes = $9,
                     is_preferred = $10
                 WHERE email = $1 AND id = $2`,
                [email, payload.id, payload.label, payload.fullName, payload.phone, payload.line1, payload.city, payload.countryCode, payload.notes || null, isPreferred]
            );
            return addressesFor(email);
        }

        const id = `addr_${Date.now()}`;
        const createdAt = new Date().toISOString();
        await database.query(
            `INSERT INTO addresses
             (id, email, label, full_name, phone, line1, city, country_code, notes, is_preferred, created_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
            [id, email, payload.label, payload.fullName, payload.phone, payload.line1, payload.city, payload.countryCode, payload.notes || null, isPreferred, createdAt]
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
                countryCode: payload.countryCode,
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
        countryCode: payload.countryCode,
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

function preferAddressRecords(addresses, addressID) {
    if (!addresses.some((address) => address.id === addressID)) return null;
    return addresses.map((address) => ({
        ...address,
        isPreferred: address.id === addressID
    }));
}

async function setPreferredAddress(email, addressID) {
    if (database.isEnabled()) {
        const existing = await database.query(
            `SELECT 1 FROM addresses WHERE email = $1 AND id = $2`,
            [email, addressID]
        );
        if (existing.rowCount === 0) return null;

        await database.query(
            `UPDATE addresses
             SET is_preferred = (id = $2)
             WHERE email = $1`,
            [email, addressID]
        );
        return addressesFor(email);
    }

    const store = readJSON(addressesStorePath);
    const updated = preferAddressRecords(store.addresses[email] || [], addressID);
    if (!updated) return null;
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

async function getEventSettings() {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT value, updated_at
             FROM app_settings
             WHERE key = $1`,
            ["event_settings"]
        );
        if (result.rowCount > 0) {
            return normalizeEventSettings({
                ...result.rows[0].value,
                updatedAt: result.rows[0].updated_at?.toISOString?.() || result.rows[0].updated_at
            });
        }
        return eventSettingsFromLegacyEid(await getCampaignSettings());
    }

    const store = readJSON(eventsStorePath);
    const settings = normalizeEventSettings(store.eventSettings || {});
    if (settings.updatedAt || settings.events.length > 0) {
        return settings;
    }
    return eventSettingsFromLegacyEid(await getCampaignSettings());
}

function eventSettingsFromLegacyEid(campaignSettings) {
    if (!campaignSettings?.updatedAt) {
        return defaultEventSettings();
    }
    return normalizeEventSettings({
        updatedAt: campaignSettings.updatedAt,
        events: [{
            id: "eid",
            enabled: campaignSettings.eidModeEnabled,
            name: "Eid",
            titleEN: "Eid at Talla",
            titleAR: "العيد في تالا",
            subtitleEN: "Seasonal gifts and coffee made for sharing.",
            subtitleAR: "هدايا موسمية وقهوة صنعت للمشاركة.",
            badgeEN: "Eid collection",
            badgeAR: "مجموعة العيد",
            ctaEN: "Explore",
            ctaAR: "استكشف",
            categoryTitleEN: "Eid Gifts",
            categoryTitleAR: "هدايا العيد",
            categorySubtitleEN: "Seasonal gifts",
            categorySubtitleAR: "هدايا موسمية",
            startAt: null,
            endAt: campaignSettings.eidOfferEndsAt,
            imageURL: "",
            accentHex: "#D6A667",
            secondaryHex: "#26372D",
            symbol: "moon.stars.fill",
            productIDs: [],
            priority: 80
        }]
    });
}

async function saveEventSettings(nextSettings) {
    const settings = normalizeEventSettings({
        ...nextSettings,
        updatedAt: new Date().toISOString()
    });

    if (database.isEnabled()) {
        await database.query(
            `INSERT INTO app_settings (key, value, updated_at)
             VALUES ($1, $2::jsonb, NOW())
             ON CONFLICT (key)
             DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()`,
            ["event_settings", JSON.stringify(settings)]
        );
        return getEventSettings();
    }

    writeJSON(eventsStorePath, { eventSettings: settings });
    return settings;
}

async function syncLegacyEidCampaignToEvents(campaignSettings) {
    const settings = await getEventSettings();
    const legacy = eventSettingsFromLegacyEid({
        ...campaignSettings,
        updatedAt: campaignSettings.updatedAt || new Date().toISOString()
    }).events[0];
    const index = settings.events.findIndex((event) => event.id === "eid");
    if (index >= 0) {
        settings.events[index] = {
            ...settings.events[index],
            enabled: legacy.enabled,
            endAt: legacy.endAt
        };
    } else {
        settings.events.push(legacy);
    }
    return saveEventSettings(settings);
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

async function getAppSettings() {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT value, updated_at
             FROM app_settings
             WHERE key = $1`,
            ["app_settings"]
        );
        if (result.rowCount > 0) {
            runtimeAppSettings.value = normalizeAppSettings({
                ...result.rows[0].value,
                updatedAt: result.rows[0].updated_at?.toISOString?.() || result.rows[0].updated_at
            });
            return runtimeAppSettings.value;
        }
        runtimeAppSettings.value = defaultAppSettings();
        return runtimeAppSettings.value;
    }

    const store = readJSON(appSettingsStorePath);
    runtimeAppSettings.value = normalizeAppSettings(store.appSettings || {});
    return runtimeAppSettings.value;
}

async function saveAppSettings(nextSettings) {
    const settings = normalizeAppSettings({
        ...nextSettings,
        updatedAt: new Date().toISOString()
    });

    if (database.isEnabled()) {
        await database.query(
            `INSERT INTO app_settings (key, value, updated_at)
             VALUES ($1, $2::jsonb, NOW())
             ON CONFLICT (key)
             DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()`,
            ["app_settings", JSON.stringify(settings)]
        );
        return getAppSettings();
    }

    writeJSON(appSettingsStorePath, { appSettings: settings });
    runtimeAppSettings.value = settings;
    return settings;
}

async function requireOperationalPayment(paymentKey, response) {
    const settings = await getAppSettings();
    if (settings.release.maintenanceEnabled || settings.release.checkoutMaintenanceEnabled) {
        sendJSON(response, 503, { error: "Checkout is temporarily unavailable." });
        return false;
    }
    if (!settings.payments[paymentKey]) {
        sendJSON(response, 503, { error: "This payment method is temporarily unavailable." });
        return false;
    }
    return true;
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

const synchronizeCoffeeRecords = createCoffeeSyncService(database);

const createServer = require("./modules/application/create-server");
const server = createServer({
    URL,
    accountRecordFromRow,
    accountsStorePath,
    activeCustomerSessionsForEmail,
    activeEventSettings,
    activeVouchersFor,
    addShopifyProductImage,
    addressRowToRecord,
    addressesFor,
    addressesStorePath,
    adminAnalyticsSummary,
    adminAppEmails,
    adminAuditLogsFor,
    adminAuditRowToRecord,
    adminCredentialsConfigured,
    adminCustomerDirectory,
    adminCustomerSummary,
    adminDirectory,
    adminNativePushDevices,
    adminOperationsSummary,
    adminOrderNotificationPayload,
    adminOrderStreamClients,
    adminPassword,
    adminPushDevicesStorePath,
    adminPushSubscriptions,
    adminPushSubscriptionsStorePath,
    adminSessionCookieAttributes,
    adminSessionCookieName,
    adminSessionHours,
    adminSessionSecret,
    adminSessions,
    adminUsername,
    adminUsers,
    alertInboxFor,
    alertInboxRowToRecord,
    alertInboxStorePath,
    alertsStorePath,
    allAccounts,
    allOrdersPayload,
    allPushDevices,
    allTasteMemoryPayload,
    allVouchersFor,
    allowedOrderStatuses,
    allowedTasteMemoryTags,
    announceNewAdminOrder,
    announcedAdminOrderIDs,
    apnsAdminBundleID,
    apnsBearerToken,
    apnsBearerTokenCache,
    apnsBearerTokenExpiresAt,
    apnsBundleID,
    apnsKeyID,
    apnsPrivateKeyBase64,
    apnsPrivateKeyCache,
    apnsPrivateKeyPath,
    apnsTeamID,
    apnsUseSandbox,
    appAttest,
    appAttestStorePath,
    appSettingsStorePath,
    applePaySettlementConfigured,
    applePaySettlementProvider,
    appleSignInClientID,
    appleSigningKeys,
    appleSigningKeysCache,
    appleSigningKeysFetchedAt,
    applyBenefitNotification,
    applyConfirmedMpgsPayment,
    applyRateLimit,
    applyShopifyEazyLocalEffects,
    approvedProductTypes,
    assertShopifyUserErrors,
    authenticateAdmin,
    authenticateCustomer,
    awardOrderBeans,
    awardOrderBeansWithClient,
    base64URLDecode,
    base64URLEncode,
    benefitAPIEndpoint,
    benefitClientPaymentStatus,
    benefitConfigured,
    benefitErrorURL,
    benefitGateway,
    benefitGatewayHostEnvironment,
    benefitNotificationStatus,
    benefitNotificationURL,
    benefitPathMatches,
    benefitPayConfiguration,
    benefitPayConfigured,
    benefitPayQueryErrorDetails,
    benefitPayTransactionIsPending,
    benefitPaymentError,
    benefitPaymentLocks,
    benefitPaymentRowToRecord,
    benefitPaymentsStorePath,
    benefitPublicError,
    benefitResourceKey,
    benefitResultPageHeaders,
    benefitResultState,
    benefitResultURL,
    benefitSuccessURL,
    benefitTranportalID,
    benefitTranportalPassword,
    bhdFils,
    buildCustomerExportCSV,
    buildCustomerTimeline,
    buildPasswordResetLink,
    buildVoucherRecord,
    campaignSettingsStorePath,
    cardPaymentLocks,
    cardPaymentRowToRecord,
    cardPaymentsStorePath,
    clearAdminSessionCookie,
    clientIPAddress,
    completedOrderStatuses,
    config,
    configureWebPush,
    confirmShopifyEazyPayment,
    consumePasswordResetTokenRecord,
    consumeVoucher,
    createAccountRecord,
    createAdminAuditLog,
    createAdminSession,
    createAdminVoucherRecord,
    createBenefitPayCheckStatusSignature,
    createBenefitPayReferenceID,
    createBenefitPendingPayment,
    createCustomerAccessToken,
    createCustomerSession,
    createMpgsTransactionID,
    createPasswordResetToken,
    createPasswordResetTokenRecord,
    createShopifyAdminProduct,
    createShopifyAppOrder,
    crypto,
    csvEscape,
    customerLibraryPayload,
    customerLibraryStorePath,
    customerPhoneForShopifyOrder,
    customerTokenHours,
    customerTokenSecret,
    customerTokensConfigured,
    dataDirectory,
    database,
    decodeBase64URL,
    defaultAppSettings,
    defaultCampaignSettings,
    defaultEventSettings,
    defaultHomeSettings,
    defaultLoyaltyPerks,
    defaultPassportSettings,
    deleteAccountRecord,
    deleteAddress,
    deleteMatchingPendingCheckout,
    deleteShopifyAdminProduct,
    eazyConfiguration,
    eazyPay,
    emailFromAddress,
    emptyCustomerLibrary,
    encodeBase64URL,
    ensureAdminAccess,
    ensureLoyaltyAccount,
    ensureMobileAdminAccess,
    ensurePassSigningFiles,
    ensureShopifyEazyInvoice,
    ensureStoreFile,
    ensureWalletPassRecord,
    escapeHTML,
    escapeShellArgument,
    eventSettingsFromLegacyEid,
    eventsStorePath,
    execFileSync,
    exportCompletedOrderToShopify,
    exportWWDRCertificate,
    finalizeVerifiedShopifyEazyPayment,
    findBenefitPaymentByOrderID,
    findBenefitPaymentByResultToken,
    findBenefitPaymentByTrackID,
    findBenefitPaymentForBrowserReturn,
    findCardPayment,
    findCardPaymentByID,
    findCardPaymentByResultToken,
    findOrderByID,
    findPendingCardPayment,
    findShopifyEazyPayment,
    findShopifyEazyPaymentByGlobalTransactionID,
    findShopifyOrderByExportTag,
    findShopifyOrderExport,
    fs,
    generateVoucherCode,
    generateWalletPass,
    getAccountByAppleUserID,
    getAccountByEmail,
    getAdminSession,
    getAppSettings,
    getBearerToken,
    getCampaignSettings,
    getEventSettings,
    getHomeSettings,
    getLoyaltyAccount,
    getLoyaltyTransactions,
    getPassportSettings,
    googleMobileServices,
    hasPermission,
    hasLoyaltyTransaction,
    hashCustomerToken,
    hashPassword,
    homeSettingsStorePath,
    host,
    http,
    http2,
    isBenefitBrowserReturnPath,
    isEazyPayManualShopifyOrder,
    linkAppleUserIDToAccount,
    listShopifyAdminProducts,
    logRequest,
    loyaltyPayload,
    loyaltyPerksFor,
    loyaltyStorePath,
    loyaltyTransactionIDForOrder,
    managedProductBadgeTags,
    markAdminPushDeviceSent,
    markPushDeviceSent,
    markShopifyOrderAsPaid,
    markWalletPassUpdatedAndNotify,
    maskMpgsSessionID,
    maybeSendOpsAlert,
    memberIDFor,
    mergeCustomerLibraryRecords,
    mpgsConfiguration,
    mpgsGateway,
    mpgsResultIndicatorMatches,
    mpgsSessionResponse,
    mpgsTransactions,
    mutateCustomerLibrary,
    nextProductTags,
    nextRewardText,
    normalizeAPNSEnvironment,
    normalizeAppSettings,
    normalizeBenefitIdentifier,
    normalizeBenefitPayMPQRText,
    normalizeBrewJournalEntry,
    normalizeCampaignSettings,
    normalizeCardPaymentIdentifier,
    normalizeCountryCode,
    normalizeCustomerProductIDs,
    normalizeDeviceToken,
    normalizeEmail,
    normalizeEventSettings,
    normalizeHomeSettings,
    normalizeOrderStatus,
    normalizePassportSettings,
    normalizeShopifyOrderPhone,
    normalizeTallaPaymentID,
    normalizeTasteMemoryInput,
    normalizeTasteMemoryReaction,
    normalizeTasteMemoryTags,
    normalizeTelemetryBatch,
    normalizeTelemetryEvent,
    normalizeWebPushSubscription,
    normalizedBenefitPathname,
    numericOrderTotal,
    opsAlert429Threshold,
    opsAlert5xxThreshold,
    opsAlertCheckIntervalMs,
    opsAlertCooldownMinutes,
    opsAlertStateFor,
    opsAlertTimer,
    opsAlertWebhookURL,
    opsAlertWindowMinutes,
    opsAlertsConfigured,
    orderBeansFor,
    orderCurrency,
    orderPayloadWithRewardState,
    orderRowToRecord,
    orderStatusFromShopifyAdminOrder,
    orderStatusFromShopifyOrder,
    ordersPayload,
    ordersStorePath,
    ordersWithRewardState,
    os,
    parseAdminLogin,
    parseAuthenticatedCustomer,
    parseBenefitCallbackRequest,
    parseCookies,
    passportSettingsStorePath,
    passwordResetEmailConfigured,
    passwordResetTokenHours,
    passwordResetTokenIsValid,
    passwordResetTokensStorePath,
    path,
    persistCardPayment,
    persistShopifyEazyPayment,
    persistShopifyOrderExport,
    persistTelemetryEvent,
    port,
    preferAddressRecords,
    prepareShopifyEazyOrder,
    permissionForAdminRequest,
    previewVoucher,
    processShopifyOrderWebhook,
    productBadgeFromTags,
    profilePayload,
    pruneAdminSessions,
    prunePushDevice,
    pruneRateLimitBuckets,
    publicPaymentURL,
    publicShopifyEazyPayment,
    publishAdminOrderEvent,
    publishShopifyProduct,
    pushDeviceRowToRecord,
    pushDevicesForEmail,
    pushDevicesStorePath,
    queryBenefitPayTransaction,
    queueShopifyOrderExport,
    queueWalletPassUpdate,
    rateLimitBuckets,
    rateLimitMaxRequests,
    rateLimitWindowMs,
    readAPNSPrivateKey,
    readBody,
    readJSON,
    readRawBody,
    recentAdminAuditLogs,
    recordBenefitNotification,
    recordTelemetry,
    registerAdminNativePushDevice,
    registerPushDevice,
    registerWalletPassDevice,
    remotePushConfigured,
    remotePushPayload,
    removeAdminPushSubscription,
    removeStockAlert,
    removeWalletPushDevice,
    renderBenefitResultPage,
    renderClickToPayLaunch,
    renderMpgsResultPage,
    renderPasswordResetPage,
    requestBodyTooLargeError,
    requestLogRowToRecord,
    requestLoggingEnabled,
    requireOperationalPayment,
    resendAPIKey,
    resolveCustomerSession,
    revokeCustomerSession,
    rotateCustomerSession,
    revokeCustomerSessionByID,
    revokeCustomerSessionsForEmail,
    revokeVoucherRecord,
    rewardDetailsFor,
    runOpsAlertChecks,
    runtimeAppSettings,
    safeConfiguredBenefitURL,
    sampleOrderItems,
    sampleOrderTotal,
    sanitizedMpgsSessionStatus,
    saveAddress,
    saveAdminPushSubscription,
    saveAppSettings,
    saveCampaignSettings,
    saveDatabaseBrewJournalEntry,
    saveEventSettings,
    saveHomeSettings,
    savePassportSettings,
    saveTasteMemoryRecord,
    secureStringEqual,
    sendAPNsPushToDevice,
    sendAdminNativeNewOrderPush,
    sendAdminNewOrderPush,
    sendBenefitRedirectAcknowledgement,
    sendCampaignPushToAll,
    sendHTML,
    sendJSON,
    sendOpsAlert,
    sendOrderReadyPush,
    sendOrderReadyPushIfNeeded,
    sendPasswordResetEmail,
    sendRemotePushToDevice,
    sendStockAlertPush,
    sendWalletPassPush,
    setAccountActiveState,
    setPreferredAddress,
    sha256Hex,
    shopifyAdminAPIVersion,
    shopifyAdminAccessToken,
    shopifyAdminConfigured,
    shopifyAdminGraphQLRequest,
    shopifyAdminOrderRecord,
    shopifyAdminProductPayload,
    shopifyAdminPublicationID,
    shopifyAdminShopDomain,
    shopifyEazyPaymentLocks,
    shopifyEazyPaymentRowToRecord,
    shopifyEazyPaymentsStorePath,
    shopifyOrderCreateInput,
    shopifyOrderExportLocks,
    shopifyOrderExportRowToRecord,
    shopifyOrderExportTag,
    shopifyOrderExportsStorePath,
    shopifyOrderPaymentGateways,
    shopifyOrderRecord,
    shopifyOrderTallaPaymentID,
    shopifyWebhookSecret,
    signCustomerTokenPayload,
    signSessionValue,
    startOpsAlertMonitor,
    stockAlertRowToRecord,
    stockAlertStatusFor,
    stockAlertsFor,
    storeVoucherRecord,
    syncLegacyEidCampaignToEvents,
    syncRecentShopifyOrdersForEmail,
    syncStockAlerts,
    synchronizeCoffeeRecords,
    tasteMemoryIDFor,
    tasteMemoryPayload,
    tasteMemoryRowToRecord,
    tasteMemoryStorePath,
    telemetryStorePath,
    tierFor,
    timeSensitiveRemotePushTypes,
    timingSafeStringEqual,
    trimAlertInbox,
    unregisterAdminNativePushDevice,
    unregisterPushDevice,
    unregisterWalletPassDevice,
    updateAccountPasswordRecord,
    updateAccountProfileRecord,
    updateAccountRecord,
    updateBenefitPaymentInitiation,
    updateCardPaymentLifecycle,
    updateCardPaymentSessionVersion,
    updateLoyaltyAccount,
    updateOpsAlertState,
    updateOrderStatusAndAward,
    updateOrderStatusByID,
    updateOrderStatusRecord,
    updateShopifyAdminProduct,
    updateShopifyProductInventory,
    updatedWalletPassesForDevice,
    upsertOrderRecord,
    upsertStockAlert,
    validWalletIdentifier,
    validateBenefitHostedPaymentURL,
    verifyAppleIdentityToken,
    verifyBenefitNotification,
    verifyConfirmedMpgsOrder,
    verifyEazyTransactionForShopifyPayment,
    verifyMpgsAuthenticationForPurchase,
    verifyShopifyWebhook,
    voucherRowToRecord,
    vouchersStorePath,
    wait,
    walletAuthorizationToken,
    walletPassArtworkDirectory,
    walletPassCertificateBase64,
    walletPassCertificatePassword,
    walletPassCertificatePath,
    walletPassRecordBySerial,
    walletPassTemplateDirectory,
    walletPassUpdateTimers,
    walletPassWWDRBase64,
    walletPassWWDRPath,
    walletPassWebServiceURL,
    walletPassesStorePath,
    walletPushCredentialsCache,
    walletPushDevicesForSerial,
    walletPushTLSCredentials,
    webPush,
    webPushConfigured,
    webPushVapidPrivateKey,
    webPushVapidPublicKey,
    webPushVapidSubject,
    withBenefitPaymentLock,
    withCardPaymentLock,
    withShopifyEazyPaymentLock,
    withShopifyOrderExportLock,
    writeDecodedSecret,
    writeJSON,
    writeWalletStampStrips
});

async function startServer() {
    if (!database.isEnabled()) {
        await getAppSettings();
        server.listen(port, host, () => {
            console.log(`Talla backend listening on ${config.appURL} (${host}:${port})`);
        });
        return;
    }

    try {
        await database.initializeDatabase();
        await getAppSettings();
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
    adminOrderNotificationPayload,
    activeEventSettings,
    applyConfirmedMpgsPayment,
    applyBenefitNotification,
    benefitGatewayHostEnvironment,
    benefitResultState,
    bhdFils,
    benefitClientPaymentStatus,
    createBenefitPayCheckStatusSignature,
    createBenefitPayReferenceID,
    createCustomerSession,
    queryBenefitPayTransaction,
    confirmShopifyEazyPayment,
    ensureShopifyEazyInvoice,
    eventSettingsFromLegacyEid,
    exportCompletedOrderToShopify,
    findShopifyOrderExport,
    findShopifyEazyPayment,
    isEazyPayManualShopifyOrder,
    loyaltyPerksFor,
    defaultAppSettings,
    normalizeAppSettings,
    normalizeCountryCode,
    normalizeAPNSEnvironment,
    normalizeWebPushSubscription,
    normalizeEventSettings,
    normalizeTallaPaymentID,
    normalizeTelemetryEvent,
    prepareShopifyEazyOrder,
    preferAddressRecords,
    publicShopifyEazyPayment,
    normalizeBenefitPayMPQRText,
    parseBenefitCallbackRequest,
    mpgsResultIndicatorMatches,
    mergeCustomerLibraryRecords,
    normalizeBrewJournalEntry,
    renderClickToPayLaunch,
    renderBenefitResultPage,
    renderMpgsResultPage,
    remotePushPayload,
    rotateCustomerSession,
    server,
    stockAlertStatusFor,
    startServer,
    tierFor,
    shopifyOrderCreateInput,
    verifyConfirmedMpgsOrder,
    verifyEazyTransactionForShopifyPayment,
    validateBenefitHostedPaymentURL,
    verifyMpgsAuthenticationForPurchase,
    verifyBenefitNotification
};
