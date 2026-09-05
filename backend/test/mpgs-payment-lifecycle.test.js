const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const dataDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-mpgs-lifecycle-"));
process.env.DATA_DIRECTORY = dataDirectory;
process.env.MPGS_MERCHANT_ID = "TESTMERCHANT";
process.env.MPGS_API_PASSWORD = "test-password-never-log";
process.env.MPGS_API_VERSION = "100";
process.env.MPGS_BASE_URL = "https://eazypay.gateway.mastercard.com";
delete process.env.DATABASE_URL;

const {
    applyConfirmedMpgsPayment,
    verifyConfirmedMpgsOrder,
    verifyMpgsAuthenticationForPurchase
} = require("../server");

const mpgsGateway = require("../modules/commerce/mpgs-gateway");

const email = "mpgs.customer@example.com";
const localOrderID = "checkout_mpgs_lifecycle";
const paymentID = "cardpay_lifecycle";
const sessionID = "SESSION1234567890123456789012345";
const ordersPath = path.join(dataDirectory, "orders.json");
const loyaltyPath = path.join(dataDirectory, "loyalty.json");
const paymentsPath = path.join(dataDirectory, "cardPayments.json");

function seed(paymentMethod = "CARD") {
    fs.writeFileSync(ordersPath, JSON.stringify({
        orders: {
            [email]: [{
                id: localOrderID,
                title: "MPGS test order",
                total: "BHD 12.800",
                totalNumber: 12.8,
                status: "Pending",
                items: [{ name: "Coffee", quantity: 1 }],
                createdAt: "2026-08-03T00:00:00.000Z"
            }]
        }
    }, null, 2));
    fs.writeFileSync(loyaltyPath, JSON.stringify({
        accounts: {
            [email]: {
                memberID: "TALLA-MPGS",
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
            [paymentID]: {
                paymentID,
                localOrderID,
                mpgsOrderID: "TALLAORDER1",
                sessionID,
                sessionVersion: "0000000002",
                amount: "12.800",
                currency: "BHD",
                email,
                paymentMethod,
                authenticationTransactionID: paymentMethod === "CARD" ? "AUTH1" : null,
                purchaseTransactionID: "PAY1",
                status: "Processing",
                createdAt: "2026-08-03T00:00:00.000Z",
                updatedAt: "2026-08-03T00:00:00.000Z"
            }
        }
    }, null, 2));
}

function gatewayOrder(overrides = {}) {
    return {
        result: "SUCCESS",
        order: {
            id: "TALLAORDER1",
            amount: "12.800",
            currency: "BHD",
            status: "CAPTURED",
            ...(overrides.order || {})
        },
        transaction: overrides.transaction || [
            {
                result: "SUCCESS",
                transaction: { id: "AUTH1", type: "AUTHENTICATION" },
                authentication: { "3ds2": { transactionStatus: "Y" } }
            },
            {
                result: "SUCCESS",
                transaction: { id: "PAY1", type: "PAYMENT" },
                response: { gatewayCode: "APPROVED" }
            }
        ]
    };
}

function storedPayment() {
    return JSON.parse(fs.readFileSync(paymentsPath, "utf8")).payments[paymentID];
}

function storedOrder() {
    return JSON.parse(fs.readFileSync(ordersPath, "utf8")).orders[email][0];
}

test("MPGS card success confirms the order without completing or awarding loyalty", async () => {
    seed("CARD");
    verifyMpgsAuthenticationForPurchase(storedPayment(), gatewayOrder());
    const first = await applyConfirmedMpgsPayment(paymentID, gatewayOrder());
    const duplicate = await applyConfirmedMpgsPayment(paymentID, gatewayOrder());
    assert.equal(first.applied, true);
    assert.equal(duplicate.applied, false);
    assert.equal(storedOrder().status, "Confirmed");
    const loyalty = JSON.parse(fs.readFileSync(loyaltyPath, "utf8")).accounts[email];
    assert.equal(loyalty.pointsBalance, 0);
    assert.equal(loyalty.transactions.length, 0);
});

test("MPGS card decline cannot complete an order", () => {
    seed("CARD");
    const declined = gatewayOrder({
        order: { status: "FAILED" },
        transaction: [{ result: "FAILURE", transaction: { id: "PAY1", type: "PAYMENT" } }]
    });
    assert.throws(
        () => verifyConfirmedMpgsOrder(storedPayment(), { ...storedOrder(), email }, declined),
        (error) => error.code === "MPGS_PAYMENT_NOT_APPROVED"
    );
    assert.equal(storedOrder().status, "Pending");
});

test("3DS failure prevents PURCHASE verification", () => {
    seed("CARD");
    const failedAuthentication = gatewayOrder({
        transaction: [{
            result: "FAILURE",
            transaction: { id: "AUTH1", type: "AUTHENTICATION" },
            authentication: { "3ds2": { transactionStatus: "N" } }
        }]
    });
    assert.throws(
        () => verifyMpgsAuthenticationForPurchase(storedPayment(), failedAuthentication),
        (error) => error.code === "MPGS_AUTHENTICATION_FAILED"
    );
});

test("Apple Pay and Click to Pay confirmed orders await manual completion", async () => {
    for (const method of ["APPLE_PAY", "CLICK_TO_PAY"]) {
        seed(method);
        const result = await applyConfirmedMpgsPayment(paymentID, gatewayOrder());
        assert.equal(result.applied, true);
        assert.equal(storedOrder().status, "Confirmed");
    }
});

test("Apple Pay or Click to Pay cancellation never confirms payment", () => {
    for (const method of ["APPLE_PAY", "CLICK_TO_PAY"]) {
        seed(method);
        const cancelled = gatewayOrder({
            order: { status: "CANCELLED" },
            transaction: []
        });
        assert.throws(
            () => verifyConfirmedMpgsOrder(storedPayment(), { ...storedOrder(), email }, cancelled),
            (error) => error.code === "MPGS_PAYMENT_NOT_APPROVED"
        );
        assert.equal(storedOrder().status, "Pending");
    }
});

test("amount and currency mismatches are rejected", () => {
    seed("CLICK_TO_PAY");
    assert.throws(
        () => verifyConfirmedMpgsOrder(
            storedPayment(),
            { ...storedOrder(), email },
            gatewayOrder({ order: { amount: "1.000" } })
        ),
        (error) => error.code === "MPGS_AMOUNT_MISMATCH"
    );
    assert.throws(
        () => verifyConfirmedMpgsOrder(
            storedPayment(),
            { ...storedOrder(), email },
            gatewayOrder({ order: { currency: "USD" } })
        ),
        (error) => error.code === "MPGS_CURRENCY_MISMATCH"
    );
});

test("Apple Pay PURCHASE identifies the wallet provider", async () => {
    let requestBody;
    const fetchImpl = async (_url, options) => {
        requestBody = JSON.parse(options.body);
        return new Response(JSON.stringify({ result: "SUCCESS" }), {
            status: 200,
            headers: { "content-type": "application/json" }
        });
    };
    await mpgsGateway.executeMpgsPurchase({
        merchantId: "TESTMERCHANT",
        apiPassword: "test-password-never-log",
        apiVersion: "100",
        baseUrl: "https://eazypay.gateway.mastercard.com"
    }, {
        orderId: "TALLAORDER1",
        transactionId: "APAY1",
        sessionId: sessionID,
        amount: "12.800",
        walletProvider: "APPLE_PAY"
    }, fetchImpl);
    assert.equal(requestBody.order.walletProvider, "APPLE_PAY");
    assert.equal(requestBody.order.currency, "BHD");
});
