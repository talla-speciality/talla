const assert = require("node:assert/strict");
const fs = require("node:fs");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const testResourceKey = "0123456789ABCDEF0123456789ABCDEF";
const dataDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-benefit-test-"));
process.env.DATA_DIRECTORY = dataDirectory;
process.env.BENEFIT_TRANPORTAL_ID = "test-terminal";
process.env.BENEFIT_TRANPORTAL_PASSWORD = "test-password";
process.env.BENEFIT_RESOURCE_KEY = testResourceKey;
process.env.BENEFIT_API_ENDPOINT = "https://benefit.test/payment/API/hosted.htm";
process.env.BENEFIT_SUCCESS_URL = "https://merchant.test/api/payments/benefit/result";
process.env.BENEFIT_ERROR_URL = "https://merchant.test/api/payments/benefit/result";
process.env.BENEFIT_NOTIFICATION_URL = "https://merchant.test/api/payments/benefit/response";
process.env.BENEFITPAY_APP_ID = "app-test";
process.env.BENEFITPAY_MERCHANT_ID = "merchant-test";
process.env.BENEFITPAY_SECRET_KEY = "benefitpay-test-secret";
process.env.BENEFITPAY_CHECK_STATUS_URL = "https://api.test-benefitpay.bh/web/v1/merchant/transaction/check-status";
process.env.BENEFITPAY_MERCHANT_NAME = "Talla Test";
process.env.BENEFITPAY_MERCHANT_CITY = "Manama";
process.env.BENEFITPAY_MCC = "5814";
delete process.env.DATABASE_URL;

const benefitGateway = require("../benefit-gateway");
const {
    createBenefitPayCheckStatusSignature,
    renderBenefitResultPage,
    server,
    verifyBenefitNotification
} = require("../server");

const customerEmail = "customer@example.com";
const orderID = "checkout_benefit_test";
const trackID = "TRACKBENEFIT123";
const resultToken = "opaque-result-token_123";
const ordersPath = path.join(dataDirectory, "orders.json");
const loyaltyPath = path.join(dataDirectory, "loyalty.json");
const paymentsPath = path.join(dataDirectory, "benefitPayments.json");
let serverBaseURL = "";

test.before(async () => {
    await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
    const address = server.address();
    serverBaseURL = `http://127.0.0.1:${address.port}`;
});

test.after(async () => {
    await new Promise((resolve, reject) => {
        server.close((error) => error ? reject(error) : resolve());
    });
});

function sha256(value) {
    return require("node:crypto").createHash("sha256").update(value).digest("hex");
}

test("BenefitPay check-status signature matches the documented KEYVAL HMAC vector", () => {
    assert.equal(
        createBenefitPayCheckStatusSignature({
            reference_id: "BP123",
            merchant_id: "merchant-test"
        }),
        "l8fB6TaPtQRlTpPnbkv160AE1S3WLrE1en+B/KvFJIU="
    );
});

function resetStores(options = {}) {
    const storedOrderID = options.orderID || orderID;
    fs.writeFileSync(ordersPath, JSON.stringify({
        orders: {
            [customerEmail]: options.omitOrder ? [] : [{
                id: storedOrderID,
                title: "BENEFIT test checkout",
                total: "BHD 12.800",
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
                memberID: "TALLA-BENEFIT",
                pointsBalance: 0,
                tier: "Bronze",
                nextReward: "",
                perks: [],
                transactions: []
            }
        }
    }, null, 2));
    fs.writeFileSync(paymentsPath, JSON.stringify({
        payments: {
            [trackID]: {
                trackID,
                orderID: storedOrderID,
                email: customerEmail,
                amount: "12.800",
                currency: "BHD",
                status: "Initiated",
                resultTokenHash: sha256(resultToken),
                hostedPaymentURL: "https://benefit.test/pay/test",
                createdAt: "2026-07-30T10:00:00.000Z",
                updatedAt: "2026-07-30T10:00:00.000Z"
            }
        }
    }, null, 2));
}

function notificationFields(overrides = {}) {
    return {
        paymentId: "PAYMENT123",
        result: "CAPTURED",
        transId: "TRANSACTION456",
        ref: "REFERENCE789",
        trackId: trackID,
        amt: "12.800",
        udf1: orderID,
        udf2: resultToken,
        authCode: "AUTH00",
        authRespCode: "00",
        date: "0730",
        ...overrides
    };
}

function encryptedNotification(overrides = {}) {
    const plaintext = benefitGateway.serializePythonStringMapArray(notificationFields(overrides));
    return benefitGateway.encryptBenefitPayload(plaintext, testResourceKey);
}

function requestServer(method, requestPath, body = null, contentType = "application/x-www-form-urlencoded") {
    return new Promise((resolve, reject) => {
        const request = http.request(`${serverBaseURL}${requestPath}`, {
            method,
            headers: body === null ? {} : {
                "Content-Type": contentType,
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

async function postEncryptedNotification(overrides = {}) {
    const body = new URLSearchParams({
        trandata: encryptedNotification(overrides)
    }).toString();
    return requestServer("POST", "/api/payments/benefit/response", body);
}

async function waitForPaymentStatus(expectedStatus) {
    const deadline = Date.now() + 1_000;
    while (Date.now() < deadline) {
        const payment = JSON.parse(fs.readFileSync(paymentsPath, "utf8")).payments[trackID];
        if (payment?.status === expectedStatus) {
            return payment;
        }
        await new Promise((resolve) => setTimeout(resolve, 10));
    }
    throw new Error(`Timed out waiting for payment status ${expectedStatus}`);
}

test("Python-compatible AES-CBC encryption matches an independent OpenSSL vector", () => {
    const plaintext = benefitGateway.serializePythonStringMapArray({
        action: "1",
        currencycode: "048"
    });
    assert.equal(plaintext, '[{"action": "1", "currencycode": "048"}]');
    const encrypted = benefitGateway.encryptBenefitPayload(plaintext, testResourceKey);
    assert.equal(
        encrypted,
        "EAAAB422E5166AACC803B3BE3F51185AB0D0E31B3EA187C6604754E93B0FD803BE6EB809E1F42D465D2530F41C1DC17DA503208A8923E469097633A12AE15C323D35114E2052688299020CA081229FA2"
    );
    assert.equal(benefitGateway.decryptBenefitPayload(encrypted, testResourceKey), plaintext);
});

test("request plaintext follows the official Python field order and constants", () => {
    const plaintext = benefitGateway.buildBenefitRequestPlaintext({
        amount: "12.800",
        tranportalID: "terminal",
        tranportalPassword: "password",
        resourceKey: testResourceKey,
        trackID,
        responseURL: "https://merchant.test/response",
        errorURL: "https://merchant.test/response",
        orderID,
        resultToken
    });
    const parsed = JSON.parse(plaintext)[0];
    assert.equal(parsed.action, "1");
    assert.equal(parsed.currencycode, "048");
    assert.equal(parsed.cardType, "D");
    assert.equal(parsed.amt, "12.800");
    assert.equal(parsed.trackId, trackID);
    assert.equal(parsed.udf1, orderID);
    assert.equal(parsed.udf2, resultToken);
});

test("approved CAPTURED notification acknowledges first and applies payment once", async () => {
    resetStores();
    const response = await postEncryptedNotification();
    assert.equal(response.statusCode, 200);
    assert.equal(
        response.body,
        `REDIRECT=https://merchant.test/api/payments/benefit/result?payment=${resultToken}`
    );
    const payment = await waitForPaymentStatus("Captured");
    assert.ok(payment.effectsAppliedAt);
    const order = JSON.parse(fs.readFileSync(ordersPath, "utf8")).orders[customerEmail][0];
    const loyalty = JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[customerEmail];
    assert.equal(order.status, "Completed");
    assert.equal(loyalty.pointsBalance, 64);
    assert.equal(loyalty.transactions.length, 1);
});

test("declined NOT CAPTURED notification does not complete the order", async () => {
    resetStores();
    await postEncryptedNotification({
        result: "NOT CAPTURED",
        authRespCode: "05"
    });
    await waitForPaymentStatus("Declined");
    const order = JSON.parse(fs.readFileSync(ordersPath, "utf8")).orders[customerEmail][0];
    assert.equal(order.status, "Pending");
});

test("customer CANCELED notification is recorded without payment effects", async () => {
    resetStores();
    await postEncryptedNotification({
        result: "CANCELED",
        transId: ""
    });
    await waitForPaymentStatus("Canceled");
    const loyalty = JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[customerEmail];
    assert.equal(loyalty.pointsBalance, 0);
});

test("DENIED BY RISK notification is recorded without payment effects", async () => {
    resetStores();
    await postEncryptedNotification({
        result: "DENIED BY RISK",
        authRespCode: ""
    });
    await waitForPaymentStatus("DeniedByRisk");
    const loyalty = JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[customerEmail];
    assert.equal(loyalty.transactions.length, 0);
});

test("amount mismatch is rejected and redirects safely", async () => {
    resetStores();
    const response = await postEncryptedNotification({ amt: "1.000" });
    assert.equal(response.body, "REDIRECT=https://merchant.test/api/payments/benefit/result");
    const payment = JSON.parse(fs.readFileSync(paymentsPath, "utf8")).payments[trackID];
    assert.equal(payment.status, "Initiated");
});

test("track ID mismatch is rejected", async () => {
    resetStores();
    const response = await postEncryptedNotification({ trackId: "UNKNOWNTRACK" });
    assert.equal(response.body, "REDIRECT=https://merchant.test/api/payments/benefit/result");
});

test("unknown order is rejected", async () => {
    resetStores({ orderID: "unknown_order", omitOrder: true });
    const response = await postEncryptedNotification({ udf1: "unknown_order" });
    assert.equal(response.body, "REDIRECT=https://merchant.test/api/payments/benefit/result");
});

test("duplicate callback cannot duplicate loyalty or fulfilment effects", async () => {
    resetStores();
    const [first, duplicate] = await Promise.all([
        postEncryptedNotification(),
        postEncryptedNotification()
    ]);
    assert.equal(first.statusCode, 200);
    assert.equal(duplicate.statusCode, 200);
    await waitForPaymentStatus("Captured");
    const loyalty = JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[customerEmail];
    assert.equal(loyalty.pointsBalance, 64);
    assert.equal(loyalty.transactions.length, 1);
});

test("malformed encrypted response returns exact safe REDIRECT acknowledgement", async () => {
    resetStores();
    const body = new URLSearchParams({ trandata: "not-hex" }).toString();
    const response = await requestServer("POST", "/api/payments/benefit/response", body);
    assert.equal(response.statusCode, 200);
    assert.equal(response.body, "REDIRECT=https://merchant.test/api/payments/benefit/result");
});

test("invalid padding is rejected", async () => {
    resetStores();
    const encrypted = Buffer.from(encryptedNotification(), "hex");
    encrypted[encrypted.length - 1] ^= 0xff;
    const body = new URLSearchParams({ trandata: encrypted.toString("hex") }).toString();
    const response = await requestServer("POST", "/api/payments/benefit/response", body);
    assert.equal(response.body, "REDIRECT=https://merchant.test/api/payments/benefit/result");
});

test("documented direct error fields are accepted and stored", async () => {
    resetStores();
    const body = new URLSearchParams({
        paymentid: "PAYMENT123",
        Error: "GV00007",
        ErrorText: "Signature validation failed",
        trackid: trackID,
        amt: "12.800",
        udf1: orderID
    }).toString();
    const response = await requestServer("POST", "/api/payments/benefit/response", body);
    assert.equal(response.statusCode, 200);
    await waitForPaymentStatus("GatewayError");
    const payment = JSON.parse(fs.readFileSync(paymentsPath, "utf8")).payments[trackID];
    assert.equal(payment.errorCode, "GV00007");
});

test("result page uses backend state rather than claimed query status", async () => {
    resetStores();
    const response = await requestServer(
        "GET",
        `/api/payments/benefit/result?payment=${resultToken}&status=success`
    );
    assert.equal(response.statusCode, 200);
    assert.match(response.body, /Payment pending/);
    assert.doesNotMatch(response.body, /test-password|test-terminal/);
});

test("GET notification return renders stored state without processing payment", async () => {
    resetStores();
    const pendingResponse = await requestServer(
        "GET",
        `/api/payments/benefit/response?trackid=${trackID}`
    );
    assert.equal(pendingResponse.statusCode, 200);
    assert.match(pendingResponse.body, /Payment pending/);

    await postEncryptedNotification();
    await waitForPaymentStatus("Captured");
    const capturedResponse = await requestServer(
        "GET",
        `/api/payments/benefit/response?trackId=${trackID}`
    );
    assert.equal(capturedResponse.statusCode, 200);
    assert.match(capturedResponse.body, /Payment confirmed/);
    assert.doesNotMatch(capturedResponse.body, /PAYMENT123|TRANS123|test-password|test-terminal/);
});

test("Safari return path variants never fall through to JSON Not found", async () => {
    resetStores();
    await postEncryptedNotification();
    await waitForPaymentStatus("Captured");

    const paths = [
        `/api/payments/benefit/result/?payment=${resultToken}`,
        `/api/payments/benefit/response/%E2%80%8B?trackid=${trackID}`,
        `/api/payments/benefit/return?payment=${resultToken}`,
        `/api/payments/benefit/callback?trackID=${trackID}`,
        `/api/payments/benefit/result%3Fpayment=${resultToken}`,
        `/api-payments-benefit-result?payment=${resultToken}`,
        `/unexpected-safari-path?payment=${resultToken}`,
        `/unexpected-safari-path/payment=${resultToken}`
    ];
    for (const path of paths) {
        const response = await requestServer("GET", path);
        assert.equal(response.statusCode, 200);
        assert.match(response.body, /Payment confirmed/);
        assert.doesNotMatch(response.body, /"error":"Not found"/);
        assert.match(response.headers["cache-control"], /no-store/);
    }
});

test("verification rejects a result-token mismatch", () => {
    assert.throws(
        () => verifyBenefitNotification(
            {
                trackID,
                orderID,
                amount: "12.800",
                currency: "BHD",
                resultTokenHash: sha256(resultToken)
            },
            {
                id: orderID,
                total: "BHD 12.800",
                totalNumber: 12.8
            },
            benefitGateway.normalizeBenefitNotification(notificationFields({
                udf2: "wrong-token"
            }))
        ),
        (error) => error.code === "BENEFIT_RESULT_TOKEN_MISMATCH"
    );
});

test("rendered result never exposes provider identifiers", () => {
    const html = renderBenefitResultPage({
        status: "Captured",
        effectsAppliedAt: "2026-07-30T11:00:00.000Z",
        paymentID: "SECRET-PAYMENT-ID"
    });
    assert.match(html, /Payment confirmed/);
    assert.doesNotMatch(html, /SECRET-PAYMENT-ID/);
});
