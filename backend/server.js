const http = require("http");
const crypto = require("crypto");
const { execFileSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { URL } = require("url");
const config = require("./config");
const database = require("./database");

const host = config.host;
const port = config.port;
const dataDirectory = config.dataDirectory;
const loyaltyStorePath = config.stores.loyalty;
const accountsStorePath = config.stores.accounts;
const ordersStorePath = config.stores.orders;
const vouchersStorePath = config.stores.vouchers;
const alertsStorePath = config.stores.alerts;
const addressesStorePath = config.stores.addresses;
const alertInboxStorePath = config.stores.alertInbox;
const adminDirectory = config.adminDirectory;
const adminUsername = config.adminUsername;
const adminPassword = config.adminPassword;
const adminSessionSecret = config.adminSessionSecret;
const adminSessionHours = config.adminSessionHours;
const customerTokenSecret = config.customerTokenSecret;
const customerTokenHours = config.customerTokenHours;
const rateLimitWindowMs = config.rateLimitWindowMs;
const rateLimitMaxRequests = config.rateLimitMaxRequests;
const requestLoggingEnabled = config.requestLoggingEnabled;
const loyaltyPointsPerBHD = 10;
const sampleOrderTotal = 8.5;
const sampleOrderItems = [
    { name: "Brazil", quantity: 1 },
    { name: "Colombia", quantity: 1 }
];
const walletPassTemplateDirectory = config.walletPassTemplateDirectory;
const walletPassCertificatePath = config.walletPassCertificatePath;
const walletPassCertificateBase64 = config.walletPassCertificateBase64;
const walletPassCertificatePassword = config.walletPassCertificatePassword;
const walletPassWWDRPath = config.walletPassWWDRPath;
const walletPassWWDRBase64 = config.walletPassWWDRBase64;
const adminSessionCookieName = "talla_admin_session";
const adminSessions = new Map();
const rateLimitBuckets = new Map();

ensureStoreFile(loyaltyStorePath, { accounts: {} });
ensureStoreFile(accountsStorePath, { accounts: {} });
ensureStoreFile(ordersStorePath, { orders: {} });
ensureStoreFile(vouchersStorePath, { vouchers: {} });
ensureStoreFile(alertsStorePath, { alerts: {} });
ensureStoreFile(addressesStorePath, { addresses: {} });
ensureStoreFile(alertInboxStorePath, { alerts: {} });

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

function sendJSON(response, statusCode, payload, extraHeaders = {}) {
    response.writeHead(statusCode, {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": config.corsAllowedOrigin,
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
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

function normalizeEmail(email) {
    return String(email || "").trim().toLowerCase();
}

function readBody(request) {
    return new Promise((resolve, reject) => {
        let body = "";

        request.on("data", (chunk) => {
            body += chunk;
        });

        request.on("end", () => {
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

function hashPassword(password) {
    return crypto.createHash("sha256").update(String(password)).digest("hex");
}

function profilePayload(account) {
    return {
        id: account.id,
        firstName: account.firstName,
        lastName: account.lastName,
        email: account.email
    };
}

function loyaltyPayload(account) {
    return {
        memberID: account.memberID,
        pointsBalance: account.pointsBalance,
        tier: account.tier,
        nextReward: account.nextReward,
        perks: account.perks,
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
        "Collect points across coffees, beans, and accessories",
        "Unlock seasonal offers and member-only extras"
    ];
}

async function getAccountByEmail(email) {
    if (!database.isEnabled()) {
        const store = readJSON(accountsStorePath);
        return store.accounts[email] || null;
    }

    const result = await database.query(
        `SELECT id, email, first_name, last_name, password_hash, created_at
         FROM accounts
         WHERE email = $1`,
        [email]
    );

    if (result.rowCount === 0) {
        return null;
    }

    const row = result.rows[0];
    return {
        id: row.id,
        email: row.email,
        firstName: row.first_name,
        lastName: row.last_name,
        passwordHash: row.password_hash,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at
    };
}

async function createAccountRecord({ id, email, firstName, lastName, passwordHash, createdAt }) {
    const account = { id, email, firstName, lastName, passwordHash, createdAt };

    if (!database.isEnabled()) {
        const store = readJSON(accountsStorePath);
        store.accounts[email] = account;
        writeJSON(accountsStorePath, store);
        return account;
    }

    await database.query(
        `INSERT INTO accounts (id, email, first_name, last_name, password_hash, created_at)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [id, email, firstName, lastName, passwordHash, createdAt]
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
         RETURNING id, email, first_name, last_name, password_hash, created_at`,
        [email, firstName, lastName]
    );

    if (result.rowCount === 0) {
        return null;
    }

    const row = result.rows[0];
    return {
        id: row.id,
        email: row.email,
        firstName: row.first_name,
        lastName: row.last_name,
        passwordHash: row.password_hash,
        createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at
    };
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
        perks: Array.isArray(row.perks) ? row.perks : []
    };
}

async function ensureLoyaltyAccount(email) {
    if (!database.isEnabled()) {
        const store = readJSON(loyaltyStorePath);
        const existing = store.accounts[email];

        if (existing) {
            return existing;
        }

        const created = {
            memberID: memberIDFor(email),
            pointsBalance: 0,
            tier: tierFor(0),
            nextReward: nextRewardText(0),
            perks: defaultLoyaltyPerks(),
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
        perks: defaultLoyaltyPerks()
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

async function ordersPayload(email) {
    if (database.isEnabled()) {
        const result = await database.query(
            `SELECT id, title, total, status, items, created_at
             FROM orders
             WHERE email = $1
             ORDER BY created_at DESC`,
            [email]
        );
        return result.rows.map(orderRowToRecord);
    }

    const store = readJSON(ordersStorePath);
    return store.orders[email] || [];
}

function rewardDetailsFor(reward) {
    const normalized = String(reward || "").trim().toLowerCase();
    const catalog = {
        "free drink": { detail: "Complimentary brewed drink", expiresInDays: 30 },
        "pastry pairing": { detail: "One pastry on the house", expiresInDays: 21 },
        "bag discount": { detail: "10% off one coffee bag", expiresInDays: 30 },
        "brew bar credit": { detail: "BHD 3.000 brew bar credit", expiresInDays: 30 },
        "talla box reward": { detail: "Special discount on a Talla Box", expiresInDays: 45 },
        "roastery gold reward": { detail: "Premium member reward voucher", expiresInDays: 60 }
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
    passJSON.barcode.altText = loyaltyAccount.memberID;
    passJSON.storeCard.primaryFields[0].value = loyaltyAccount.pointsBalance;
    passJSON.storeCard.secondaryFields[0].value = memberName || account.email;
    passJSON.storeCard.secondaryFields[1].value = loyaltyAccount.tier;
    passJSON.storeCard.auxiliaryFields[0].value = loyaltyAccount.nextReward;
    passJSON.storeCard.backFields = [
        {
            key: "email",
            label: "EMAIL",
            value: account.email
        },
        {
            key: "member_id",
            label: "MEMBER ID",
            value: loyaltyAccount.memberID
        },
        {
            key: "support",
            label: "WHATSAPP",
            value: "+973 3939 2414"
        },
        {
            key: "site",
            label: "SITE",
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
    const normalized = localPart.toUpperCase().replace(/[^A-Z0-9]/g, "").slice(0, 8);
    return `TALLA-${normalized || "MEMBER"}`;
}

function tierFor(pointsBalance) {
    if (pointsBalance >= 500) return "Roastery Gold";
    if (pointsBalance >= 250) return "Roastery Silver";
    return "Roastery Member";
}

function nextRewardText(pointsBalance) {
    const threshold = 100;
    const remainder = pointsBalance % threshold;
    const remaining = remainder === 0 ? threshold : threshold - remainder;
    return `${remaining} points to your next reward`;
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
                await database.query(
                    `INSERT INTO alert_inbox
                     (id, email, title, detail, created_at, product_id)
                     VALUES ($1, $2, $3, $4, $5, $6)`,
                    [
                        `alert_${Date.now()}_${existing.productID}`,
                        email,
                        `${nextRecord.productName} is back`,
                        `${nextRecord.productName} is available again in the Talla app.`,
                        new Date().toISOString(),
                        existing.productID
                    ]
                );
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
    const synced = existingAlerts
        .map((existing) => {
            const payload = payloadByID.get(existing.productID);
            if (!payload) {
                return existing;
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
                inbox.unshift({
                    id: `alert_${Date.now()}_${existing.productID}`,
                    title: `${nextRecord.productName} is back`,
                    detail: `${nextRecord.productName} is available again in the Talla app.`,
                    createdAt: new Date().toISOString(),
                    productID: existing.productID
                });
            }

            return nextRecord;
        })
        .sort((lhs, rhs) => new Date(rhs.updatedAt).getTime() - new Date(lhs.updatedAt).getTime());

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
        const result = await database.query(
            `SELECT COUNT(*)::int AS count
             FROM addresses
             WHERE email = $1`,
            [email]
        );
        const isPreferred = result.rows[0].count === 0;
        const id = `addr_${Date.now()}`;
        const createdAt = new Date().toISOString();

        if (isPreferred) {
            await database.query(
                `UPDATE addresses
                 SET is_preferred = FALSE
                 WHERE email = $1`,
                [email]
            );
        }

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
    const nextAddress = {
        id: `addr_${Date.now()}`,
        label: payload.label,
        fullName: payload.fullName,
        phone: payload.phone,
        line1: payload.line1,
        city: payload.city,
        notes: payload.notes || null,
        isPreferred: addresses.length === 0
    };

    store.addresses[email] = [nextAddress, ...addresses.map((address) => ({ ...address, isPreferred: false }))];
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

async function adminCustomerSummary(email) {
    const account = await getAccountByEmail(email);
    if (!account) {
        return null;
    }

    const [loyalty, orders, alerts, inbox, addresses, vouchers, auditLogs] = await Promise.all([
        ensureLoyaltyAccount(email),
        ordersPayload(email),
        stockAlertsFor(email),
        alertInboxFor(email),
        addressesFor(email),
        activeVouchersFor(email),
        adminAuditLogsFor(email)
    ]);

    return {
        profile: profilePayload(account),
        loyalty: loyaltyPayload(loyalty),
        orders,
        alerts,
        inbox,
        addresses,
        vouchers,
        auditLogs
    };
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
                    detail: `${points > 0 ? "Added" : "Removed"} ${Math.abs(points)} points`,
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
                    sendJSON(response, 409, { error: "Adjustment would result in negative points." });
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

        sendJSON(response, 200, await ordersPayload(customer.email));
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
                    note: `Completed order • BHD ${sampleOrderTotal.toFixed(3)}`,
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
            const note = String(body.note || "Points adjustment");
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
                sendJSON(response, 409, { error: "Insufficient points" });
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

    sendJSON(response, 404, { error: "Not found" });
});

(async () => {
    if (!database.isEnabled()) {
        server.listen(port, host, () => {
            console.log(`Talla backend listening on ${config.appURL} (${host}:${port})`);
        });
        return;
    }

    try {
        await database.initializeDatabase();
        console.log("Postgres storage enabled for accounts and loyalty.");
        server.listen(port, host, () => {
            console.log(`Talla backend listening on ${config.appURL} (${host}:${port})`);
        });
    } catch (error) {
        console.error("Failed to initialize Postgres storage.", error);
        process.exit(1);
    }
})();
