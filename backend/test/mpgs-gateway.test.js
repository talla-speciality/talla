const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const mpgsGateway = require("../mpgs-gateway");

const configuration = {
    merchantId: "TESTMERCHANT",
    apiPassword: "super-secret-api-password",
    apiVersion: "100",
    baseURL: "https://eazypay.gateway.mastercard.com"
};
const sessionID = "SESSION1234567890123456789012345";
const customerEmail = "card.customer@example.com";

function order(overrides = {}) {
    return {
        id: "checkout_card_test",
        email: customerEmail,
        total: "BHD 12.800",
        totalNumber: 12.8,
        status: "Pending",
        ...overrides
    };
}

function jsonResponse(payload, status = 200) {
    return {
        ok: status >= 200 && status < 300,
        status,
        text: async () => JSON.stringify(payload)
    };
}

function successfulFetch(calls) {
    return async (url, options) => {
        calls.push({ url: String(url), options });
        if (options.method === "POST") {
            return jsonResponse({
                result: "SUCCESS",
                session: {
                    id: sessionID,
                    version: "0000000001",
                    updateStatus: "NO_UPDATE"
                }
            });
        }
        return jsonResponse({
            result: "SUCCESS",
            session: {
                id: sessionID,
                version: "0000000002",
                updateStatus: "SUCCESS"
            }
        });
    };
}

test("valid card session creation calls Mastercard create and update endpoints", async () => {
    const calls = [];
    let persisted = null;
    const result = await mpgsGateway.initializeMpgsPayment({
        configuration,
        order: order(),
        customerEmail,
        persistPayment: async (payment) => {
            persisted = payment;
            return payment;
        },
        fetchImpl: successfulFetch(calls)
    });

    assert.equal(calls.length, 2);
    assert.equal(calls[0].options.method, "POST");
    assert.equal(
        calls[0].url,
        "https://eazypay.gateway.mastercard.com/api/rest/version/100/merchant/TESTMERCHANT/session"
    );
    assert.deepEqual(JSON.parse(calls[0].options.body), { session: { authenticationLimit: 25 } });
    assert.equal(calls[1].options.method, "PUT");
    assert.equal(calls[1].url, `${calls[0].url}/${sessionID}`);
    const updateBody = JSON.parse(calls[1].options.body);
    assert.equal(updateBody.order.amount, "12.800");
    assert.equal(updateBody.order.currency, "BHD");
    assert.equal(updateBody.authentication.acceptVersions, "3DS2");
    assert.equal(updateBody.authentication.channel, "PAYER_APP");
    assert.equal(updateBody.authentication.purpose, "PAYMENT_TRANSACTION");
    assert.equal(result.payment.sessionVersion, "0000000002");
    assert.equal(persisted.status, "Pending");
});

test("missing Mastercard credentials fail safely", async () => {
    await assert.rejects(
        mpgsGateway.initializeMpgsPayment({
            configuration: { ...configuration, apiPassword: "" },
            order: order(),
            customerEmail,
            persistPayment: async (payment) => payment
        }),
        (error) => error.code === "MPGS_NOT_CONFIGURED" && error.statusCode === 503
    );
});

test("unknown local order is rejected before contacting Mastercard", async () => {
    let called = false;
    await assert.rejects(
        mpgsGateway.initializeMpgsPayment({
            configuration,
            order: null,
            customerEmail,
            persistPayment: async (payment) => payment,
            fetchImpl: async () => {
                called = true;
            }
        }),
        (error) => error.code === "MPGS_ORDER_NOT_FOUND" && error.statusCode === 404
    );
    assert.equal(called, false);
});

test("wrong customer cannot create or inspect another customer's order", async () => {
    await assert.rejects(
        mpgsGateway.initializeMpgsPayment({
            configuration,
            order: order(),
            customerEmail: "other@example.com",
            persistPayment: async (payment) => payment
        }),
        (error) => error.code === "MPGS_ORDER_FORBIDDEN" && error.statusCode === 403
    );
    assert.throws(
        () => mpgsGateway.verifyMpgsOrderPayment(
            {
                localOrderID: "checkout_card_test",
                email: customerEmail,
                amount: "12.800",
                currency: "BHD"
            },
            order(),
            "other@example.com"
        ),
        (error) => error.code === "MPGS_ORDER_FORBIDDEN"
    );
});

test("invalid backend-stored amount is rejected", async () => {
    await assert.rejects(
        mpgsGateway.initializeMpgsPayment({
            configuration,
            order: order({ total: "BHD invalid", totalNumber: Number.NaN }),
            customerEmail,
            persistPayment: async (payment) => payment
        }),
        (error) => error.code === "MPGS_AMOUNT_INVALID"
    );
});

test("Mastercard create-session failure is normalized without credentials", async () => {
    let upstreamError;
    try {
        await mpgsGateway.initializeMpgsPayment({
            configuration,
            order: order(),
            customerEmail,
            persistPayment: async (payment) => payment,
            fetchImpl: async () => jsonResponse({
                result: "ERROR",
                error: {
                    cause: "REQUEST_REJECTED",
                    explanation: configuration.apiPassword
                }
            }, 401)
        });
        assert.fail("Expected Mastercard session creation to fail");
    } catch (error) {
        upstreamError = error;
    }
    assert.equal(upstreamError.code, "MPGS_UPSTREAM_REJECTED");
    const normalized = mpgsGateway.normalizeMpgsError(upstreamError);
    assert.equal(normalized.statusCode, 502);
    assert.doesNotMatch(JSON.stringify(normalized), /super-secret-api-password/);
});

test("Mastercard update-session failure does not persist a pending payment", async () => {
    let requestCount = 0;
    let persisted = false;
    await assert.rejects(
        mpgsGateway.initializeMpgsPayment({
            configuration,
            order: order(),
            customerEmail,
            persistPayment: async (payment) => {
                persisted = true;
                return payment;
            },
            fetchImpl: async () => {
                requestCount += 1;
                if (requestCount === 1) {
                    return jsonResponse({
                        result: "SUCCESS",
                        session: { id: sessionID, version: "0000000001", updateStatus: "NO_UPDATE" }
                    });
                }
                return jsonResponse({
                    result: "SUCCESS",
                    session: { id: sessionID, version: "0000000001", updateStatus: "FAILURE" }
                });
            }
        }),
        (error) => error.code === "MPGS_SESSION_UPDATE_FAILED"
    );
    assert.equal(requestCount, 2);
    assert.equal(persisted, false);
});

test("API password appears only in the outbound authorization header", async () => {
    const calls = [];
    const result = await mpgsGateway.initializeMpgsPayment({
        configuration,
        order: order(),
        customerEmail,
        persistPayment: async (payment) => payment,
        fetchImpl: successfulFetch(calls)
    });
    assert.match(calls[0].options.headers.Authorization, /^Basic /);
    assert.doesNotMatch(JSON.stringify(result), /super-secret-api-password/);
    assert.doesNotMatch(JSON.stringify(calls.map(({ url, options }) => ({ url, body: options.body }))), /super-secret-api-password/);
    const serverSource = fs.readFileSync(path.join(__dirname, "..", "server.js"), "utf8");
    assert.doesNotMatch(serverSource, /console\.[a-z]+\([^\n]*(?:mpgsAPIPassword|mpgsConfiguration\.apiPassword)/i);
});

test("retrieve session uses GET and returns the current gateway version", async () => {
    const calls = [];
    const payload = await mpgsGateway.retrieveMpgsSession(
        configuration,
        sessionID,
        async (url, options) => {
            calls.push({ url: String(url), options });
            return jsonResponse({
                result: "SUCCESS",
                order: { id: "TALLAEXISTING", amount: "12.800", currency: "BHD" },
                session: { id: sessionID, version: "0000000003", updateStatus: "SUCCESS" },
                sourceOfFunds: { provided: { card: { number: "512345xxxxxx0008" } } }
            });
        }
    );
    assert.equal(calls[0].options.method, "GET");
    assert.equal(
        calls[0].url,
        `https://eazypay.gateway.mastercard.com/api/rest/version/100/merchant/TESTMERCHANT/session/${sessionID}`
    );
    assert.equal(payload.session.version, "0000000003");
});

test("BHD is enforced and a client-supplied amount is ignored", async () => {
    const calls = [];
    await mpgsGateway.initializeMpgsPayment({
        configuration,
        order: order({ clientAmount: "999.999" }),
        customerEmail,
        persistPayment: async (payment) => payment,
        fetchImpl: successfulFetch(calls)
    });
    const updateBody = JSON.parse(calls[1].options.body);
    assert.equal(updateBody.order.amount, "12.800");
    assert.equal(updateBody.order.currency, "BHD");
    assert.doesNotMatch(calls[1].options.body, /999\.999/);
});

test("duplicate session creation reuses the pending record without another gateway call", async () => {
    const existingPayment = {
        paymentID: "cardpay_existing",
        localOrderID: "checkout_card_test",
        mpgsOrderID: "TALLAEXISTING",
        sessionID,
        sessionVersion: "0000000002",
        amount: "12.800",
        currency: "BHD",
        email: customerEmail,
        status: "Pending"
    };
    let fetchCalled = false;
    let persistCalled = false;
    const result = await mpgsGateway.initializeMpgsPayment({
        configuration,
        order: order(),
        customerEmail,
        existingPayment,
        persistPayment: async () => {
            persistCalled = true;
        },
        fetchImpl: async () => {
            fetchCalled = true;
        }
    });
    assert.equal(result.reused, true);
    assert.equal(result.payment, existingPayment);
    assert.equal(fetchCalled, false);
    assert.equal(persistCalled, false);
});

test("3DS initiation and payer authentication use API version 100 transaction operations", async () => {
    const calls = [];
    const fetchImpl = async (url, options) => {
        calls.push({ url: String(url), options });
        return jsonResponse({
            result: "SUCCESS",
            authentication: { "3ds2": { transactionStatus: "Y" } },
            response: { gatewayRecommendation: "PROCEED" }
        });
    };
    await mpgsGateway.initiateMpgsAuthentication(configuration, {
        orderId: "TALLAORDER1",
        transactionId: "AUTH1",
        sessionId: sessionID
    }, fetchImpl);
    await mpgsGateway.authenticateMpgsPayer(configuration, {
        orderId: "TALLAORDER1",
        transactionId: "AUTH1",
        sessionId: sessionID,
        amount: "12.800"
    }, fetchImpl);
    assert.equal(calls.length, 2);
    assert.match(calls[0].url, /\/version\/100\/merchant\/TESTMERCHANT\/order\/TALLAORDER1\/transaction\/AUTH1$/);
    assert.equal(JSON.parse(calls[0].options.body).apiOperation, "INITIATE_AUTHENTICATION");
    assert.equal(JSON.parse(calls[1].options.body).apiOperation, "AUTHENTICATE_PAYER");
    assert.equal(JSON.parse(calls[1].options.body).order.currency, "BHD");
});

test("3DS challenge, failure, and cancellation outcomes are explicit", () => {
    const challenge = mpgsGateway.normalizeMpgsAuthenticationOutcome({
        result: "PENDING",
        authentication: { redirect: { html: "<form>challenge</form>" } }
    });
    assert.equal(challenge.challengeRequired, true);
    assert.equal(challenge.successful, false);

    const failure = mpgsGateway.normalizeMpgsAuthenticationOutcome({
        result: "FAILURE",
        authentication: { "3ds2": { transactionStatus: "N" } }
    });
    assert.equal(failure.successful, false);
    assert.equal(failure.challengeRequired, false);

    const cancellation = mpgsGateway.normalizeMpgsAuthenticationOutcome({
        result: "CANCELLED",
        response: { gatewayRecommendation: "CANCELLED" }
    });
    assert.equal(cancellation.cancelled, true);
});

test("card and Apple Pay PURCHASE use the stored session without payment tokens", async () => {
    const calls = [];
    const fetchImpl = async (url, options) => {
        calls.push({ url: String(url), options });
        return jsonResponse({ result: "SUCCESS", response: { gatewayCode: "APPROVED" } });
    };
    await mpgsGateway.executeMpgsPurchase(configuration, {
        orderId: "TALLAORDER1",
        transactionId: "PAY1",
        authenticationTransactionId: "AUTH1",
        sessionId: sessionID,
        amount: "12.800"
    }, fetchImpl);
    await mpgsGateway.executeMpgsPurchase(configuration, {
        orderId: "TALLAORDER2",
        transactionId: "APAY1",
        sessionId: sessionID,
        amount: "12.800"
    }, fetchImpl);
    const cardBody = JSON.parse(calls[0].options.body);
    const appleBody = JSON.parse(calls[1].options.body);
    assert.equal(cardBody.apiOperation, "PAY");
    assert.equal(cardBody.authentication.transactionId, "AUTH1");
    assert.equal(appleBody.apiOperation, "PAY");
    assert.equal(appleBody.authentication, undefined);
    assert.doesNotMatch(JSON.stringify(calls), /paymentToken|cardNumber|cvv/i);
});

test("Click to Pay initiates Hosted Checkout with PURCHASE and backend BHD amount", async () => {
    const calls = [];
    await mpgsGateway.initiateMpgsCheckout(configuration, {
        orderId: "TALLACLICK1",
        amount: "12.800",
        returnUrl: "https://merchant.test/api/payments/click-to-pay/return?payment=token",
        cancelUrl: "https://merchant.test/api/payments/click-to-pay/return?payment=token&cancelled=1"
    }, async (url, options) => {
        calls.push({ url: String(url), options });
        return jsonResponse({
            result: "SUCCESS",
            session: { id: sessionID, version: "0000000004", updateStatus: "SUCCESS" }
        });
    });
    const body = JSON.parse(calls[0].options.body);
    assert.equal(body.apiOperation, "INITIATE_CHECKOUT");
    assert.equal(body.interaction.operation, "PURCHASE");
    assert.equal(body.order.amount, "12.800");
    assert.equal(body.order.currency, "BHD");
});

test("gateway timeout is normalized without leaking configuration", async () => {
    const timeout = new Error("timed out");
    timeout.name = "TimeoutError";
    let caught;
    try {
        await mpgsGateway.retrieveMpgsOrder(configuration, "TALLAORDER1", async () => {
            throw timeout;
        });
    } catch (error) {
        caught = error;
    }
    assert.equal(caught.code, "MPGS_TIMEOUT");
    const normalized = mpgsGateway.normalizeMpgsError(caught);
    assert.equal(normalized.statusCode, 504);
    assert.doesNotMatch(JSON.stringify(normalized), /super-secret-api-password|TESTMERCHANT/);
});
