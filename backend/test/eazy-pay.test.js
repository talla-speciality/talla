const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const dataDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-eazy-test-"));
process.env.DATA_DIRECTORY = dataDirectory;
process.env.EAZY_APP_ID = "test-app-id";
process.env.EAZY_SECRET_KEY = "test-secret-key";
process.env.EAZY_API_BASE_URL = "https://eazy.test";
delete process.env.DATABASE_URL;

const {
    confirmEazyTransaction,
    createEazyQuerySecretHash,
    extractEazyGlobalTransactionID,
    normalizeEazyTransaction,
    queryEazyTransaction,
    server,
    verifyEazyTransactionAgainstOrder
} = require("../server");

const customerEmail = "customer@example.com";
const ordersPath = path.join(dataDirectory, "orders.json");
const loyaltyPath = path.join(dataDirectory, "loyalty.json");
let serverBaseURL = "";

test.before(async () => {
    await new Promise((resolve) => {
        server.listen(0, "127.0.0.1", resolve);
    });
    const address = server.address();
    serverBaseURL = `http://127.0.0.1:${address.port}`;
});

test.after(async () => {
    await new Promise((resolve, reject) => {
        server.close((error) => error ? reject(error) : resolve());
    });
});

function resetStores(orderID = "checkout_test", total = "BHD 12.800") {
    fs.writeFileSync(ordersPath, JSON.stringify({
        orders: {
            [customerEmail]: [{
                id: orderID,
                title: "Test checkout",
                total,
                totalNumber: 12.8,
                status: "Pending",
                items: [{ name: "Coffee", quantity: 1 }],
                createdAt: "2026-07-30T10:00:00.000Z"
            }]
        }
    }, null, 2));
    fs.writeFileSync(loyaltyPath, JSON.stringify({
        accounts: {
            [customerEmail]: {
                memberID: "TALLA-TEST",
                pointsBalance: 0,
                tier: "Green",
                nextReward: "",
                perks: [],
                transactions: []
            }
        }
    }, null, 2));
}

function transactionPayload(overrides = {}) {
    return {
        globalTransactionsId: "global_txn_123",
        transactionsId: "paid_txn_456",
        invoiceId: "checkout_test",
        currency: "BHD",
        amount: "12.800",
        isPaid: 1,
        paidOn: "2026-07-30T11:00:00.000Z",
        paymentMethod: "BENEFITGATEWAY",
        errorCode: "0",
        errorMessage: "",
        ...overrides
    };
}

function mockFetch(payload, status = 200, capture = null) {
    return async (url, options) => {
        if (capture) {
            capture.url = url;
            capture.options = options;
        }
        return new Response(JSON.stringify({ data: payload }), {
            status,
            headers: { "Content-Type": "application/json" }
        });
    };
}

function requestServer(method, requestPath, body = null) {
    return new Promise((resolve, reject) => {
        const request = http.request(`${serverBaseURL}${requestPath}`, {
            method,
            headers: body === null ? {} : {
                "Content-Type": "application/json",
                "Content-Length": Buffer.byteLength(body)
            }
        }, (response) => {
            const chunks = [];
            response.on("data", (chunk) => chunks.push(Buffer.from(chunk)));
            response.on("end", () => {
                resolve({
                    statusCode: response.statusCode,
                    headers: response.headers,
                    body: Buffer.concat(chunks).toString("utf8")
                });
            });
        });
        request.on("error", reject);
        if (body !== null) {
            request.write(body);
        }
        request.end();
    });
}

test("successful paid transaction is verified, stored, and awarded once", async () => {
    resetStores();
    const capture = {};
    const timestamp = "1785398400123";
    const result = await confirmEazyTransaction("global_txn_123", {
        fetchImpl: mockFetch(transactionPayload(), 200, capture),
        timestamp
    });

    assert.equal(result.transaction.isPaid, 1);
    assert.equal(result.applied, true);
    assert.equal(result.award.awarded, true);
    assert.equal(capture.url, "https://eazy.test/merchant/checkout/query");
    assert.equal(capture.options.headers.Timestamp, timestamp);
    assert.equal(
        capture.options.headers["Secret-Hash"],
        crypto.createHmac("sha256", "test-secret-key").update(`${timestamp}test-app-id`).digest("hex")
    );

    const storedOrder = JSON.parse(fs.readFileSync(ordersPath, "utf8")).orders[customerEmail][0];
    assert.equal(storedOrder.status, "Completed");
    assert.equal(storedOrder.eazyGlobalTransactionsId, "global_txn_123");
    assert.equal(storedOrder.eazyTransactionsId, "paid_txn_456");
    assert.equal(storedOrder.eazyPaymentMethod, "BENEFITGATEWAY");
    assert.equal(storedOrder.eazyPaidAmount, "12.800");
    assert.equal(storedOrder.eazyPaidOn, "2026-07-30T11:00:00.000Z");

    const loyalty = JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[customerEmail];
    assert.equal(loyalty.pointsBalance, 64);
    assert.equal(loyalty.transactions.length, 1);
});

test("pending transaction does not update the order", async () => {
    resetStores();
    const result = await confirmEazyTransaction("global_txn_123", {
        fetchImpl: mockFetch(transactionPayload({
            transactionsId: "",
            isPaid: 0,
            paidOn: null
        }))
    });

    assert.equal(result.transaction.isPaid, 0);
    assert.equal(result.applied, false);
    const storedOrder = JSON.parse(fs.readFileSync(ordersPath, "utf8")).orders[customerEmail][0];
    assert.equal(storedOrder.status, "Pending");
    assert.equal(storedOrder.eazyGlobalTransactionsId, undefined);
});

test("failed EazyPay query returns a safe upstream error", async () => {
    await assert.rejects(
        queryEazyTransaction("global_txn_123", {
            fetchImpl: mockFetch({ errorMessage: "provider failure" }, 500)
        }),
        (error) => error.code === "EAZY_QUERY_FAILED" && error.statusCode === 502
    );
});

test("amount mismatch is rejected", () => {
    assert.throws(
        () => verifyEazyTransactionAgainstOrder(
            normalizeEazyTransaction(transactionPayload({ amount: "12.700" })),
            { id: "checkout_test", total: "BHD 12.800", totalNumber: 12.8 }
        ),
        (error) => error.code === "EAZY_AMOUNT_MISMATCH"
    );
});

test("currency mismatch is rejected", () => {
    assert.throws(
        () => verifyEazyTransactionAgainstOrder(
            normalizeEazyTransaction(transactionPayload({ currency: "USD" })),
            { id: "checkout_test", total: "BHD 12.800", totalNumber: 12.8 }
        ),
        (error) => error.code === "EAZY_CURRENCY_MISMATCH"
    );
});

test("unknown invoice is rejected", async () => {
    resetStores();
    await assert.rejects(
        confirmEazyTransaction("global_txn_123", {
            fetchImpl: mockFetch(transactionPayload({ invoiceId: "unknown_order" }))
        }),
        (error) => error.code === "EAZY_ORDER_NOT_FOUND"
    );
});

test("duplicate webhook callbacks cannot duplicate loyalty or payment effects", async () => {
    resetStores();
    const options = { fetchImpl: mockFetch(transactionPayload()) };
    const [first, duplicate] = await Promise.all([
        confirmEazyTransaction("global_txn_123", options),
        confirmEazyTransaction("global_txn_123", options)
    ]);

    assert.equal(first.applied, true);
    assert.equal(duplicate.applied, false);
    const loyalty = JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[customerEmail];
    assert.equal(loyalty.pointsBalance, 64);
    assert.equal(loyalty.transactions.length, 1);
});

test("duplicate return requests remain idempotent after the first confirmation", async () => {
    resetStores();
    const options = { fetchImpl: mockFetch(transactionPayload()) };
    const first = await confirmEazyTransaction("global_txn_123", options);
    const duplicate = await confirmEazyTransaction("global_txn_123", options);

    assert.equal(first.applied, true);
    assert.equal(duplicate.applied, false);
    const loyalty = JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[customerEmail];
    assert.equal(loyalty.pointsBalance, 64);
    assert.equal(loyalty.transactions.length, 1);
});

test("missing transaction ID is rejected", async () => {
    await assert.rejects(
        queryEazyTransaction(""),
        (error) => error.code === "EAZY_INVALID_TRANSACTION_ID" && error.statusCode === 400
    );
});

test("malformed webhook payload has no usable transaction ID", () => {
    assert.equal(extractEazyGlobalTransactionID({ payment: "paid" }), "");
    assert.equal(extractEazyGlobalTransactionID(null), "");
});

test("webhook route rejects malformed JSON", async () => {
    const response = await requestServer("POST", "/api/payments/eazy/webhook", "{bad-json");
    assert.equal(response.statusCode, 400);
});

test("webhook route applies duplicate notifications only once", async () => {
    resetStores();
    const originalFetch = global.fetch;
    global.fetch = mockFetch(transactionPayload());
    try {
        const body = JSON.stringify({ globalTransactionsId: "global_txn_123", isPaid: 1 });
        const [first, duplicate] = await Promise.all([
            requestServer("POST", "/api/payments/eazy/webhook", body),
            requestServer("POST", "/api/payments/eazy/webhook", body)
        ]);
        assert.equal(first.statusCode, 200);
        assert.equal(duplicate.statusCode, 200);
    } finally {
        global.fetch = originalFetch;
    }

    const loyalty = JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[customerEmail];
    assert.equal(loyalty.pointsBalance, 64);
    assert.equal(loyalty.transactions.length, 1);
});

test("return route handles missing and duplicate transaction IDs safely", async () => {
    const missing = await requestServer("GET", "/api/payments/eazy/return");
    assert.equal(missing.statusCode, 400);

    resetStores();
    const originalFetch = global.fetch;
    global.fetch = mockFetch(transactionPayload());
    try {
        const [first, duplicate] = await Promise.all([
            requestServer("GET", "/api/payments/eazy/return?id=global_txn_123"),
            requestServer("GET", "/api/payments/eazy/return?globalTransactionId=global_txn_123")
        ]);
        assert.equal(first.statusCode, 200);
        assert.equal(duplicate.statusCode, 200);
        assert.match(first.body, /Payment confirmed/);
        assert.match(duplicate.body, /Payment confirmed/);
        assert.doesNotMatch(first.body, /test-secret-key|test-app-id/);
    } finally {
        global.fetch = originalFetch;
    }

    const loyalty = JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[customerEmail];
    assert.equal(loyalty.pointsBalance, 64);
    assert.equal(loyalty.transactions.length, 1);
});

test("query hash uses timestamp plus app ID only", () => {
    assert.equal(
        createEazyQuerySecretHash("123", "app", "secret"),
        crypto.createHmac("sha256", "secret").update("123app").digest("hex")
    );
});
