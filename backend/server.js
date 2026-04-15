const http = require("http");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const { URL } = require("url");

const host = process.env.HOST || "127.0.0.1";
const port = Number(process.env.PORT || 8787);
const dataDirectory = path.join(__dirname, "data");
const loyaltyStorePath = path.join(dataDirectory, "loyalty.json");
const accountsStorePath = path.join(dataDirectory, "accounts.json");

ensureStoreFile(loyaltyStorePath, { accounts: {} });
ensureStoreFile(accountsStorePath, { accounts: {} });

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

function sendJSON(response, statusCode, payload) {
    response.writeHead(statusCode, {
        "Content-Type": "application/json; charset=utf-8",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type"
    });
    response.end(JSON.stringify(payload));
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

function ensureLoyaltyAccount(email) {
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
        perks: [
            "Collect points across coffees, beans, and accessories",
            "Unlock seasonal offers and member-only extras"
        ],
        transactions: []
    };

    store.accounts[email] = created;
    writeJSON(loyaltyStorePath, store);
    return created;
}

function updateLoyaltyAccount(email, mutate) {
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

const server = http.createServer(async (request, response) => {
    if (!request.url) {
        sendJSON(response, 400, { error: "Missing URL" });
        return;
    }

    if (request.method === "OPTIONS") {
        sendJSON(response, 204, {});
        return;
    }

    const url = new URL(request.url, `http://${host}:${port}`);

    if (request.method === "GET" && url.pathname === "/health") {
        sendJSON(response, 200, { status: "ok" });
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

            const store = readJSON(accountsStorePath);

            if (store.accounts[email]) {
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

            store.accounts[email] = account;
            writeJSON(accountsStorePath, store);
            ensureLoyaltyAccount(email);

            sendJSON(response, 201, profilePayload(account));
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

            const store = readJSON(accountsStorePath);
            const account = store.accounts[email];

            if (!account || account.passwordHash !== hashPassword(password)) {
                sendJSON(response, 401, { error: "Invalid email or password" });
                return;
            }

            ensureLoyaltyAccount(email);
            sendJSON(response, 200, profilePayload(account));
        } catch (error) {
            sendJSON(response, 400, { error: "Invalid JSON body" });
        }
        return;
    }

    if (request.method === "GET" && url.pathname === "/accounts/profile") {
        const email = normalizeEmail(url.searchParams.get("email"));

        if (!email) {
            sendJSON(response, 400, { error: "Missing email" });
            return;
        }

        const store = readJSON(accountsStorePath);
        const account = store.accounts[email];

        if (!account) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        sendJSON(response, 200, profilePayload(account));
        return;
    }

    if (request.method === "GET" && url.pathname === "/loyalty/account") {
        const email = normalizeEmail(url.searchParams.get("email"));

        if (!email) {
            sendJSON(response, 400, { error: "Missing email" });
            return;
        }

        const accountsStore = readJSON(accountsStorePath);
        if (!accountsStore.accounts[email]) {
            sendJSON(response, 404, { error: "Account not found" });
            return;
        }

        const account = ensureLoyaltyAccount(email);
        sendJSON(response, 200, loyaltyPayload(account));
        return;
    }

    if (request.method === "POST" && url.pathname === "/loyalty/transactions/earn") {
        try {
            const body = await readBody(request);
            const email = normalizeEmail(body.email);
            const points = Number(body.points);
            const note = String(body.note || "Points adjustment");

            if (!email || !Number.isFinite(points) || points <= 0) {
                sendJSON(response, 400, { error: "Invalid earn payload" });
                return;
            }

            const updated = updateLoyaltyAccount(email, (account) => {
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
            const email = normalizeEmail(body.email);
            const points = Number(body.points);
            const reward = String(body.reward || "Reward redemption");

            if (!email || !Number.isFinite(points) || points <= 0) {
                sendJSON(response, 400, { error: "Invalid redemption payload" });
                return;
            }

            const updated = updateLoyaltyAccount(email, (account) => {
                if (account.pointsBalance < points) {
                    throw new Error("INSUFFICIENT_POINTS");
                }

                account.pointsBalance -= points;
                account.transactions = account.transactions || [];
                account.transactions.unshift({
                    id: `txn_${Date.now()}`,
                    type: "redeem",
                    points,
                    note: reward,
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

    sendJSON(response, 404, { error: "Not found" });
});

server.listen(port, host, () => {
    console.log(`Talla backend listening on http://${host}:${port}`);
});
