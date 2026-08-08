const crypto = require("crypto");

function paymentError(code, statusCode, message) {
    const error = new Error(message);
    error.code = code;
    error.statusCode = statusCode;
    return error;
}

function normalizeIdentifier(value, maxLength = 200) {
    const normalized = String(value || "").trim();
    if (!normalized || normalized.length > maxLength || !/^[A-Za-z0-9][A-Za-z0-9._:/#-]*$/.test(normalized)) {
        return "";
    }
    return normalized;
}

function responsePayload(payload) {
    if (!payload || typeof payload !== "object") {
        return {};
    }
    return payload.data && typeof payload.data === "object" ? payload.data : payload;
}

function safeProviderMessage(payload) {
    const result = responsePayload(payload);
    return String(result.errorMessage || result.message || result.error || "Upstream request failed.")
        .replace(/[\r\n]+/g, " ")
        .slice(0, 240);
}

function configurationIsValid(configuration) {
    return Boolean(configuration?.appId && configuration?.secretKey && configuration?.apiBaseURL);
}

function createInvoiceSecretHash(timestamp, currency, amount, appId, secretKey) {
    return crypto.createHmac("sha256", secretKey).update(`${timestamp}${currency}${amount}${appId}`).digest("hex");
}

function createQuerySecretHash(timestamp, appId, secretKey) {
    return crypto.createHmac("sha256", secretKey).update(`${timestamp}${appId}`).digest("hex");
}

function normalizeTransaction(payload) {
    const result = responsePayload(payload);
    const paidValue = result.isPaid ?? result.is_paid ?? 0;
    return {
        globalTransactionsId: normalizeIdentifier(result.globalTransactionsId || result.globalTransactionId || result.global_transactions_id || result.global_transaction_id),
        transactionsId: normalizeIdentifier(result.transactionsId || result.transactionId || result.transactionsID || result.transaction_id),
        invoiceId: normalizeIdentifier(result.invoiceId || result.invoiceID || result.orderID || result.orderId || result.invoice_id),
        currency: String(result.currency || result.currencyCode || "").trim().toUpperCase(),
        amount: String(result.amount ?? result.amt ?? "").trim(),
        isPaid: paidValue === true || Number(paidValue) === 1 ? 1 : 0,
        paidOn: String(result.paidOn || result.paidAt || result.paid_on || "").trim() || null,
        paymentMethod: String(result.paymentMethod || result.payment_method || "").trim().slice(0, 80),
        errorCode: String(result.errorCode ?? result.error_code ?? "").trim(),
        errorMessage: String(result.errorMessage || result.error_message || result.message || "").trim().slice(0, 300)
    };
}

function extractGlobalTransactionID(payload) {
    for (const candidate of [payload, payload?.data, payload?.payload, payload?.transaction, payload?.result]) {
        if (!candidate || typeof candidate !== "object") continue;
        const identifier = normalizeIdentifier(candidate.globalTransactionsId || candidate.globalTransactionId || candidate.global_transactions_id || candidate.global_transaction_id || candidate.id);
        if (identifier) return identifier;
    }
    return "";
}

async function parseJSONResponse(response, invalidCode) {
    const text = await response.text();
    if (text.length > 262_144) {
        throw paymentError(invalidCode, 502, "EazyPay returned an invalid response.");
    }
    if (!text) return {};
    try {
        return JSON.parse(text);
    } catch {
        throw paymentError(invalidCode, 502, "EazyPay returned an invalid response.");
    }
}

async function createInvoice(input, configuration, options = {}) {
    if (!configurationIsValid(configuration)) {
        throw paymentError("EAZY_NOT_CONFIGURED", 503, "EazyPay checkout is not configured.");
    }
    const invoiceId = normalizeIdentifier(input.invoiceId);
    const amount = String(input.amount || "").trim();
    const currency = String(input.currency || "").trim().toUpperCase();
    if (!invoiceId || !/^\d+\.\d{3}$/.test(amount) || currency !== "BHD") {
        throw paymentError("EAZY_INVALID_INVOICE", 400, "The EazyPay invoice is invalid.");
    }
    const timestamp = String(options.timestamp ?? new Date().toISOString());
    const endpoint = `${String(configuration.apiBaseURL).replace(/\/+$/, "")}/merchant/checkout/createInvoice`;
    let response;
    try {
        response = await (options.fetchImpl || fetch)(endpoint, {
            method: "POST",
            headers: {
                "Content-Type": "application/json; charset=utf-8",
                Timestamp: timestamp,
                "Secret-Hash": createInvoiceSecretHash(timestamp, currency, amount, configuration.appId, configuration.secretKey)
            },
            body: JSON.stringify({
                appId: configuration.appId,
                invoiceId,
                amount,
                currency,
                paymentMethod: configuration.paymentMethods
            }),
            signal: options.signal || AbortSignal.timeout(options.timeoutMs || 10_000)
        });
    } catch {
        throw paymentError("EAZY_CREATE_UNREACHABLE", 502, "Could not reach EazyPay.");
    }
    const payload = await parseJSONResponse(response, "EAZY_CREATE_INVALID_RESPONSE");
    if (!response.ok) {
        const error = paymentError("EAZY_CREATE_FAILED", 502, "EazyPay could not create the payment invoice.");
        error.upstreamStatus = response.status;
        error.providerMessage = safeProviderMessage(payload);
        throw error;
    }
    const result = responsePayload(payload);
    const globalTransactionsId = normalizeIdentifier(result.globalTransactionsId || result.globalTransactionId);
    const paymentUrl = String(result.paymentUrl || result.paymentURL || "").trim();
    let parsedURL;
    try {
        parsedURL = new URL(paymentUrl);
    } catch {
        parsedURL = null;
    }
    if (!globalTransactionsId || !parsedURL || parsedURL.protocol !== "https:") {
        throw paymentError("EAZY_CREATE_INVALID_RESPONSE", 502, "EazyPay returned an incomplete invoice response.");
    }
    return { invoiceId, globalTransactionsId, paymentUrl: parsedURL.toString() };
}

async function queryTransaction(globalTransactionsId, configuration, options = {}) {
    const normalizedID = normalizeIdentifier(globalTransactionsId);
    if (!normalizedID) {
        throw paymentError("EAZY_INVALID_TRANSACTION_ID", 400, "A valid EazyPay transaction ID is required.");
    }
    if (!configurationIsValid(configuration)) {
        throw paymentError("EAZY_NOT_CONFIGURED", 503, "EazyPay checkout is not configured.");
    }
    const timestamp = String(options.timestamp ?? Date.now());
    const endpoint = `${String(configuration.apiBaseURL).replace(/\/+$/, "")}/merchant/checkout/query`;
    let response;
    try {
        response = await (options.fetchImpl || fetch)(endpoint, {
            method: "POST",
            headers: {
                "Content-Type": "application/json; charset=utf-8",
                Timestamp: timestamp,
                "Secret-Hash": createQuerySecretHash(timestamp, configuration.appId, configuration.secretKey)
            },
            body: JSON.stringify({ appId: configuration.appId, globalTransactionsId: normalizedID }),
            signal: options.signal || AbortSignal.timeout(options.timeoutMs || 10_000)
        });
    } catch {
        throw paymentError("EAZY_QUERY_UNREACHABLE", 502, "Could not reach EazyPay.");
    }
    const payload = await parseJSONResponse(response, "EAZY_QUERY_INVALID_RESPONSE");
    if (!response.ok) {
        const error = paymentError("EAZY_QUERY_FAILED", 502, "EazyPay could not confirm the transaction.");
        error.upstreamStatus = response.status;
        error.providerMessage = safeProviderMessage(payload);
        throw error;
    }
    const transaction = normalizeTransaction(payload);
    if (!transaction.globalTransactionsId || transaction.globalTransactionsId !== normalizedID || !transaction.invoiceId) {
        throw paymentError("EAZY_QUERY_INVALID_RESPONSE", 502, "EazyPay returned an invalid transaction response.");
    }
    if (transaction.errorCode && !/^0+$/.test(transaction.errorCode)) {
        const error = paymentError("EAZY_QUERY_REJECTED", 502, "EazyPay rejected the transaction query.");
        error.providerErrorCode = transaction.errorCode;
        throw error;
    }
    return transaction;
}

module.exports = {
    configurationIsValid,
    createInvoice,
    createInvoiceSecretHash,
    createQuerySecretHash,
    extractGlobalTransactionID,
    normalizeIdentifier,
    normalizeTransaction,
    paymentError,
    queryTransaction
};
