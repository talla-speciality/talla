const crypto = require("crypto");

const DEFAULT_API_VERSION = "100";
const DEFAULT_BASE_URL = "https://eazypay.gateway.mastercard.com";
const MAX_RESPONSE_BYTES = 262_144;
const REQUEST_TIMEOUT_MS = 15_000;

function mpgsError(code, statusCode, message, details = {}) {
    const error = new Error(message);
    error.code = code;
    error.statusCode = statusCode;
    Object.assign(error, details);
    return error;
}

function normalizedConfiguration(configuration = {}) {
    return {
        merchantId: String(configuration.merchantId || "").trim(),
        apiPassword: String(configuration.apiPassword || ""),
        apiVersion: String(configuration.apiVersion || DEFAULT_API_VERSION).trim(),
        baseURL: String(configuration.baseURL || DEFAULT_BASE_URL).trim()
    };
}

function mpgsConfigurationIsValid(configuration = {}) {
    const normalized = normalizedConfiguration(configuration);
    if (!/^[A-Za-z0-9_-]{1,40}$/.test(normalized.merchantId)
        || !normalized.apiPassword
        || !/^\d{1,3}$/.test(normalized.apiVersion)) {
        return false;
    }
    try {
        const url = new URL(normalized.baseURL);
        return url.protocol === "https:" && !url.username && !url.password;
    } catch (error) {
        return false;
    }
}

function mpgsAuthorizationHeader(configuration = {}) {
    const normalized = normalizedConfiguration(configuration);
    if (!mpgsConfigurationIsValid(normalized)) {
        throw mpgsError("MPGS_NOT_CONFIGURED", 503, "Card payments are not configured.");
    }
    return `Basic ${Buffer.from(`merchant.${normalized.merchantId}:${normalized.apiPassword}`, "utf8").toString("base64")}`;
}

function mpgsEndpoint(configuration, suffix = "") {
    const normalized = normalizedConfiguration(configuration);
    if (!mpgsConfigurationIsValid(normalized)) {
        throw mpgsError("MPGS_NOT_CONFIGURED", 503, "Card payments are not configured.");
    }
    const baseURL = new URL(normalized.baseURL);
    baseURL.pathname = `${baseURL.pathname.replace(/\/$/, "")}/api/rest/version/${encodeURIComponent(normalized.apiVersion)}/merchant/${encodeURIComponent(normalized.merchantId)}${suffix}`;
    baseURL.search = "";
    baseURL.hash = "";
    return baseURL;
}

function normalizeMpgsError(error) {
    if (error?.code === "MPGS_NOT_CONFIGURED") {
        return { statusCode: 503, code: error.code, message: "Card payments are not configured." };
    }
    if (error?.code === "REQUEST_BODY_TOO_LARGE") {
        return { statusCode: 413, code: error.code, message: "Request body is too large." };
    }
    if (error?.code?.startsWith("MPGS_") && Number(error.statusCode) < 500) {
        return { statusCode: error.statusCode, code: error.code, message: error.message };
    }
    return {
        statusCode: Number(error?.statusCode) === 504 ? 504 : 502,
        code: error?.code || "MPGS_UPSTREAM_FAILED",
        message: "Card payment service is temporarily unavailable."
    };
}

async function mpgsRequest(
    configuration,
    method,
    endpoint,
    body,
    fetchImpl = globalThis.fetch,
    allowGatewayFailure = false
) {
    if (typeof fetchImpl !== "function") {
        throw mpgsError("MPGS_FETCH_UNAVAILABLE", 502, "Card payment service is unavailable.");
    }
    let response;
    try {
        response = await fetchImpl(endpoint, {
            method,
            headers: {
                Authorization: mpgsAuthorizationHeader(configuration),
                Accept: "application/json",
                "Content-Type": "application/json; charset=utf-8"
            },
            ...(body === undefined ? {} : { body: JSON.stringify(body) }),
            signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS)
        });
    } catch (error) {
        const timedOut = error?.name === "TimeoutError" || error?.name === "AbortError";
        throw mpgsError(
            timedOut ? "MPGS_TIMEOUT" : "MPGS_NETWORK_FAILED",
            timedOut ? 504 : 502,
            "Card payment service request failed."
        );
    }

    const responseText = await response.text();
    if (Buffer.byteLength(responseText) > MAX_RESPONSE_BYTES) {
        throw mpgsError("MPGS_RESPONSE_TOO_LARGE", 502, "Card payment service returned an invalid response.");
    }
    let payload = {};
    if (responseText) {
        try {
            payload = JSON.parse(responseText);
        } catch (error) {
            throw mpgsError("MPGS_RESPONSE_INVALID", 502, "Card payment service returned an invalid response.");
        }
    }
    if (!response.ok || (!allowGatewayFailure && (payload.result === "ERROR" || payload.result === "FAILURE"))) {
        throw mpgsError("MPGS_UPSTREAM_REJECTED", 502, "Card payment service rejected the request.", {
            gatewayCause: String(payload.error?.cause || payload.result || "UNKNOWN").slice(0, 80),
            gatewaySupportCode: String(payload.error?.supportCode || "").slice(0, 100)
        });
    }
    return payload;
}

function validSessionID(value) {
    return /^[A-Za-z0-9_-]{31,80}$/.test(String(value || ""));
}

function validGatewayIdentifier(value, maxLength = 80) {
    return new RegExp(`^[A-Za-z0-9_-]{1,${maxLength}}$`).test(String(value || ""));
}

function sessionResult(payload, requireUpdated = false) {
    const session = payload?.session;
    if (!session || !validSessionID(session.id) || !String(session.version || "").trim()) {
        throw mpgsError("MPGS_SESSION_INVALID", 502, "Card payment service returned an invalid session.");
    }
    if (requireUpdated && session.updateStatus !== "SUCCESS") {
        throw mpgsError("MPGS_SESSION_UPDATE_FAILED", 502, "Card payment session could not be prepared.");
    }
    return payload;
}

async function createMpgsSession(configuration, fetchImpl = globalThis.fetch) {
    const endpoint = mpgsEndpoint(configuration, "/session");
    const payload = await mpgsRequest(
        configuration,
        "POST",
        endpoint,
        { session: { authenticationLimit: 25 } },
        fetchImpl
    );
    return sessionResult(payload);
}

async function updateMpgsSession(configuration, sessionId, fields, fetchImpl = globalThis.fetch) {
    if (!validSessionID(sessionId)) {
        throw mpgsError("MPGS_SESSION_ID_INVALID", 400, "Invalid card payment session ID.");
    }
    const endpoint = mpgsEndpoint(configuration, `/session/${encodeURIComponent(sessionId)}`);
    const payload = await mpgsRequest(configuration, "PUT", endpoint, fields, fetchImpl);
    return sessionResult(payload, true);
}

async function retrieveMpgsSession(configuration, sessionId, fetchImpl = globalThis.fetch) {
    if (!validSessionID(sessionId)) {
        throw mpgsError("MPGS_SESSION_ID_INVALID", 400, "Invalid card payment session ID.");
    }
    const endpoint = mpgsEndpoint(configuration, `/session/${encodeURIComponent(sessionId)}`);
    const payload = await mpgsRequest(configuration, "GET", endpoint, undefined, fetchImpl);
    return sessionResult(payload);
}

async function performMpgsTransaction(
    configuration,
    orderId,
    transactionId,
    fields,
    fetchImpl = globalThis.fetch
) {
    if (!validGatewayIdentifier(orderId, 40) || !validGatewayIdentifier(transactionId, 40)) {
        throw mpgsError("MPGS_TRANSACTION_ID_INVALID", 400, "Invalid gateway transaction identifier.");
    }
    const endpoint = mpgsEndpoint(
        configuration,
        `/order/${encodeURIComponent(orderId)}/transaction/${encodeURIComponent(transactionId)}`
    );
    return mpgsRequest(configuration, "PUT", endpoint, fields, fetchImpl, true);
}

async function initiateMpgsAuthentication(
    configuration,
    { orderId, transactionId, sessionId },
    fetchImpl = globalThis.fetch
) {
    if (!validSessionID(sessionId)) {
        throw mpgsError("MPGS_SESSION_ID_INVALID", 400, "Invalid card payment session ID.");
    }
    return performMpgsTransaction(configuration, orderId, transactionId, {
        apiOperation: "INITIATE_AUTHENTICATION",
        authentication: {
            acceptVersions: "3DS2",
            channel: "PAYER_APP",
            purpose: "PAYMENT_TRANSACTION"
        },
        order: { currency: "BHD" },
        session: { id: sessionId }
    }, fetchImpl);
}

async function authenticateMpgsPayer(
    configuration,
    { orderId, transactionId, sessionId, amount },
    fetchImpl = globalThis.fetch
) {
    if (!validSessionID(sessionId) || !/^\d+\.\d{3}$/.test(String(amount || ""))) {
        throw mpgsError("MPGS_AUTHENTICATION_INVALID", 400, "Invalid payer authentication request.");
    }
    return performMpgsTransaction(configuration, orderId, transactionId, {
        apiOperation: "AUTHENTICATE_PAYER",
        authentication: {
            acceptVersions: "3DS2",
            channel: "PAYER_APP",
            purpose: "PAYMENT_TRANSACTION"
        },
        order: { amount, currency: "BHD" },
        session: { id: sessionId }
    }, fetchImpl);
}

async function executeMpgsPurchase(
    configuration,
    { orderId, transactionId, authenticationTransactionId, sessionId, amount },
    fetchImpl = globalThis.fetch
) {
    if (!validSessionID(sessionId) || !/^\d+\.\d{3}$/.test(String(amount || ""))) {
        throw mpgsError("MPGS_PURCHASE_INVALID", 400, "Invalid purchase request.");
    }
    const authentication = validGatewayIdentifier(authenticationTransactionId, 40)
        ? { transactionId: authenticationTransactionId }
        : undefined;
    return performMpgsTransaction(configuration, orderId, transactionId, {
        apiOperation: "PAY",
        ...(authentication ? { authentication } : {}),
        order: { amount, currency: "BHD" },
        session: { id: sessionId }
    }, fetchImpl);
}

async function retrieveMpgsOrder(configuration, orderId, fetchImpl = globalThis.fetch) {
    if (!validGatewayIdentifier(orderId, 40)) {
        throw mpgsError("MPGS_ORDER_ID_INVALID", 400, "Invalid gateway order identifier.");
    }
    const endpoint = mpgsEndpoint(configuration, `/order/${encodeURIComponent(orderId)}`);
    return mpgsRequest(configuration, "GET", endpoint, undefined, fetchImpl);
}

async function initiateMpgsCheckout(
    configuration,
    { orderId, amount, returnUrl, cancelUrl },
    fetchImpl = globalThis.fetch
) {
    if (!validGatewayIdentifier(orderId, 40)
        || !/^\d+\.\d{3}$/.test(String(amount || ""))
        || !/^https:\/\//.test(String(returnUrl || ""))
        || !/^https:\/\//.test(String(cancelUrl || ""))) {
        throw mpgsError("MPGS_CHECKOUT_INVALID", 400, "Invalid hosted checkout request.");
    }
    const endpoint = mpgsEndpoint(configuration, "/session");
    const payload = await mpgsRequest(configuration, "POST", endpoint, {
        apiOperation: "INITIATE_CHECKOUT",
        checkoutMode: "WEBSITE",
        interaction: {
            operation: "PURCHASE",
            returnUrl,
            cancelUrl,
            merchant: { name: "Talla Speciality" }
        },
        order: { id: orderId, amount, currency: "BHD" }
    }, fetchImpl);
    return sessionResult(payload);
}

function normalizeMpgsAuthenticationOutcome(payload) {
    const result = String(payload?.result || "UNKNOWN").toUpperCase();
    const transactionStatus = String(
        payload?.authentication?.["3ds2"]?.transactionStatus
        || payload?.authentication?.transactionStatus
        || "UNKNOWN"
    ).toUpperCase();
    const redirectHTML = String(payload?.authentication?.redirect?.html || "").slice(0, 131_072);
    const successful = result === "SUCCESS" && ["Y", "A"].includes(transactionStatus);
    const challengeRequired = result === "PENDING" && Boolean(redirectHTML);
    const cancelled = ["CANCELLED", "CANCELED"].includes(result)
        || String(payload?.response?.gatewayRecommendation || "").toUpperCase() === "CANCELLED";
    return { result, transactionStatus, redirectHTML, successful, challengeRequired, cancelled };
}

function orderAmount(order) {
    const storedCurrency = String(order?.total || "").trim().match(/^([A-Za-z]{3})\b/)?.[1]?.toUpperCase();
    if (storedCurrency && storedCurrency !== "BHD") {
        throw mpgsError("MPGS_CURRENCY_INVALID", 409, "The stored order currency is not BHD.");
    }
    const value = Number.isFinite(order?.totalNumber)
        ? order.totalNumber
        : Number(String(order?.total || "").match(/-?\d+(?:\.\d+)?/)?.[0]);
    if (!Number.isFinite(value) || value <= 0) {
        throw mpgsError("MPGS_AMOUNT_INVALID", 409, "The stored order does not have a valid payable total.");
    }
    const amount = value.toFixed(3);
    if (!/^\d+\.\d{3}$/.test(amount) || Number(amount) !== value) {
        throw mpgsError("MPGS_AMOUNT_INVALID", 409, "The stored order does not have a valid payable total.");
    }
    return amount;
}

function verifyMpgsOrderPayment(payment, order, customerEmail, gatewaySession = null) {
    if (!payment || !order) {
        throw mpgsError("MPGS_PAYMENT_NOT_FOUND", 404, "Card payment session was not found.");
    }
    const email = String(customerEmail || "").trim().toLowerCase();
    if (!email
        || String(payment.email || "").trim().toLowerCase() !== email
        || String(order.email || "").trim().toLowerCase() !== email) {
        throw mpgsError("MPGS_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
    }
    if (String(payment.localOrderID) !== String(order.id)) {
        throw mpgsError("MPGS_ORDER_MISMATCH", 409, "Card payment order does not match.");
    }
    const amount = orderAmount(order);
    if (payment.currency !== "BHD" || payment.amount !== amount) {
        throw mpgsError("MPGS_AMOUNT_MISMATCH", 409, "Card payment amount does not match the stored order.");
    }
    if (gatewaySession) {
        if (gatewaySession.session?.id !== payment.sessionID
            || String(gatewaySession.order?.id || "") !== payment.mpgsOrderID
            || String(gatewaySession.order?.currency || "").toUpperCase() !== "BHD"
            || Number(gatewaySession.order?.amount).toFixed(3) !== amount) {
            throw mpgsError("MPGS_SESSION_MISMATCH", 409, "Card payment session does not match the stored order.");
        }
    }
    return { amount, currency: "BHD" };
}

function createMpgsIdentifiers() {
    return {
        paymentID: `cardpay_${Date.now()}_${crypto.randomBytes(8).toString("hex")}`,
        mpgsOrderID: `TALLA${Date.now()}${crypto.randomBytes(6).toString("hex")}`
    };
}

async function initializeMpgsPayment({
    configuration,
    order,
    customerEmail,
    existingPayment = null,
    paymentMethod = "CARD",
    resultTokenHash = null,
    persistPayment,
    fetchImpl = globalThis.fetch
}) {
    if (!mpgsConfigurationIsValid(configuration)) {
        throw mpgsError("MPGS_NOT_CONFIGURED", 503, "Card payments are not configured.");
    }
    const email = String(customerEmail || "").trim().toLowerCase();
    if (!order) {
        throw mpgsError("MPGS_ORDER_NOT_FOUND", 404, "Order not found.");
    }
    if (!email || String(order.email || "").trim().toLowerCase() !== email) {
        throw mpgsError("MPGS_ORDER_FORBIDDEN", 403, "This order does not belong to the authenticated customer.");
    }
    const amount = orderAmount(order);
    if (existingPayment) {
        verifyMpgsOrderPayment(existingPayment, order, email);
        return { payment: existingPayment, reused: true };
    }

    const identifiers = createMpgsIdentifiers();
    const created = await createMpgsSession(configuration, fetchImpl);
    const updated = await updateMpgsSession(configuration, created.session.id, {
        session: { version: created.session.version },
        order: {
            id: identifiers.mpgsOrderID,
            amount,
            currency: "BHD"
        },
        authentication: {
            acceptVersions: "3DS2",
            channel: "PAYER_APP",
            purpose: "PAYMENT_TRANSACTION"
        }
    }, fetchImpl);
    const timestamp = new Date().toISOString();
    const payment = {
        paymentID: identifiers.paymentID,
        localOrderID: String(order.id),
        mpgsOrderID: identifiers.mpgsOrderID,
        sessionID: updated.session.id,
        sessionVersion: String(updated.session.version),
        amount,
        currency: "BHD",
        email,
        paymentMethod: String(paymentMethod || "CARD").toUpperCase(),
        resultTokenHash,
        status: "Pending",
        createdAt: timestamp,
        updatedAt: timestamp
    };
    if (typeof persistPayment !== "function") {
        throw mpgsError("MPGS_STORAGE_UNAVAILABLE", 500, "Card payment storage is unavailable.");
    }
    const persisted = await persistPayment(payment);
    return { payment: persisted || payment, reused: false };
}

module.exports = {
    DEFAULT_API_VERSION,
    DEFAULT_BASE_URL,
    authenticateMpgsPayer,
    createMpgsSession,
    createMpgsIdentifiers,
    executeMpgsPurchase,
    initializeMpgsPayment,
    initiateMpgsAuthentication,
    initiateMpgsCheckout,
    mpgsAuthorizationHeader,
    mpgsConfigurationIsValid,
    normalizeMpgsAuthenticationOutcome,
    normalizeMpgsError,
    orderAmount,
    performMpgsTransaction,
    retrieveMpgsOrder,
    retrieveMpgsSession,
    updateMpgsSession,
    verifyMpgsOrderPayment
};
