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
    stores: {
        loyalty: path.join(dataDirectory, "loyalty.json"),
        accounts: path.join(dataDirectory, "accounts.json"),
        orders: path.join(dataDirectory, "orders.json"),
        vouchers: path.join(dataDirectory, "vouchers.json"),
        alerts: path.join(dataDirectory, "alerts.json"),
        addresses: path.join(dataDirectory, "addresses.json"),
        alertInbox: path.join(dataDirectory, "alertInbox.json")
    },
    corsAllowedOrigin: process.env.CORS_ALLOWED_ORIGIN || "*",
    walletPassTemplateDirectory,
    walletPassCertificatePath: toAbsolutePath(process.env.WALLET_P12_PATH),
    walletPassCertificateBase64: process.env.WALLET_P12_BASE64 || "",
    walletPassCertificatePassword: process.env.WALLET_P12_PASSWORD || "",
    walletPassWWDRPath: toAbsolutePath(process.env.WALLET_WWDR_PATH),
    walletPassWWDRBase64: process.env.WALLET_WWDR_BASE64 || ""
};
