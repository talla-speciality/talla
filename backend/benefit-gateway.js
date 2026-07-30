const crypto = require("crypto");

const BENEFIT_IV = Buffer.from("PGKEYENCDECIVSPC", "utf8");

function validateResourceKey(resourceKey) {
    const key = Buffer.from(String(resourceKey || ""), "utf8");
    if (![16, 24, 32].includes(key.length)) {
        throw new Error("BENEFIT_RESOURCE_KEY_INVALID");
    }
    return key;
}

function pythonQuote(value) {
    return encodeURIComponent(String(value))
        .replace(/[!'()*]/g, (character) => `%${character.charCodeAt(0).toString(16).toUpperCase()}`)
        .replace(/%2F/gi, "/");
}

function pythonUnquotePlus(value) {
    return decodeURIComponent(String(value).replace(/\+/g, " "));
}

function serializePythonStringMapArray(fields) {
    const entries = Object.entries(fields).map(([key, value]) => (
        `${JSON.stringify(key)}: ${JSON.stringify(String(value ?? ""))}`
    ));
    return `[{${entries.join(", ")}}]`;
}

function encryptBenefitPayload(plainText, resourceKey) {
    const key = validateResourceKey(resourceKey);
    const cipher = crypto.createCipheriv(`aes-${key.length * 8}-cbc`, key, BENEFIT_IV);
    const encrypted = Buffer.concat([
        cipher.update(Buffer.from(pythonQuote(plainText), "utf8")),
        cipher.final()
    ]);
    return encrypted.toString("hex").toUpperCase();
}

function decryptBenefitPayload(encryptedHex, resourceKey) {
    const normalizedHex = String(encryptedHex || "").trim();
    if (!normalizedHex
        || normalizedHex.length > 131_072
        || normalizedHex.length % 2 !== 0
        || !/^[0-9A-Fa-f]+$/.test(normalizedHex)) {
        throw new Error("BENEFIT_TRANDATA_INVALID");
    }

    const key = validateResourceKey(resourceKey);
    try {
        const decipher = crypto.createDecipheriv(`aes-${key.length * 8}-cbc`, key, BENEFIT_IV);
        const decrypted = Buffer.concat([
            decipher.update(Buffer.from(normalizedHex, "hex")),
            decipher.final()
        ]).toString("utf8");
        return pythonUnquotePlus(decrypted);
    } catch (error) {
        throw new Error("BENEFIT_DECRYPTION_FAILED");
    }
}

function buildBenefitRequestPlaintext({
    amount,
    tranportalID,
    tranportalPassword,
    resourceKey,
    trackID,
    responseURL,
    errorURL,
    orderID,
    resultToken
}) {
    return serializePythonStringMapArray({
        action: "1",
        currencycode: "048",
        cardType: "D",
        amt: amount,
        password: tranportalPassword,
        id: tranportalID,
        resourceKey,
        trackId: trackID,
        responseURL,
        errorURL,
        udf1: orderID,
        udf2: resultToken,
        udf3: "",
        udf4: "",
        udf5: ""
    });
}

function buildBenefitAPIRequestBody(tranportalID, encryptedTransactionData) {
    return serializePythonStringMapArray({
        id: tranportalID,
        trandata: encryptedTransactionData
    });
}

function parseBenefitNotificationPlaintext(plainText) {
    const normalized = String(plainText || "").trim();
    if (!normalized) {
        throw new Error("BENEFIT_NOTIFICATION_EMPTY");
    }

    try {
        const parsed = JSON.parse(normalized);
        const record = Array.isArray(parsed) ? parsed[0] : parsed;
        if (record && typeof record === "object" && !Array.isArray(record)) {
            return record;
        }
    } catch (error) {
        const parameters = new URLSearchParams(normalized);
        if ([...parameters.keys()].length > 0) {
            return Object.fromEntries(parameters.entries());
        }
    }

    throw new Error("BENEFIT_NOTIFICATION_INVALID");
}

function field(record, names) {
    for (const name of names) {
        const value = record?.[name];
        if (value !== undefined && value !== null) {
            return String(value).trim();
        }
    }
    return "";
}

function limited(value, maxLength = 255) {
    return String(value || "").trim().slice(0, maxLength);
}

function normalizeBenefitNotification(record) {
    return {
        paymentID: limited(field(record, ["paymentId", "paymentID", "paymentid"]), 100),
        result: limited(field(record, ["result"]), 40).toUpperCase(),
        transactionID: limited(field(record, ["transId", "transactionId", "tranid", "transid"]), 100),
        referenceID: limited(field(record, ["ref", "referenceId", "referenceID"]), 100),
        trackID: limited(field(record, ["trackId", "trackID", "trackid"]), 255),
        amount: limited(field(record, ["amt", "amount"]), 30),
        currency: limited(field(record, ["currencycode", "currencyCode", "currency"]), 10).toUpperCase(),
        authCode: limited(field(record, ["authCode", "auth"]), 100),
        authResponseCode: limited(field(record, ["authRespCode", "authResponseCode", "responseCode"]), 20),
        postDate: limited(field(record, ["postDate", "postdate", "date"]), 40),
        errorCode: limited(field(record, ["Error", "error", "errorCode"]), 100),
        errorText: limited(field(record, ["ErrorText", "errorText", "errorMessage"]), 300),
        orderID: limited(field(record, ["udf1"]), 255),
        resultToken: limited(field(record, ["udf2"]), 200)
    };
}

module.exports = {
    BENEFIT_IV,
    buildBenefitAPIRequestBody,
    buildBenefitRequestPlaintext,
    decryptBenefitPayload,
    encryptBenefitPayload,
    normalizeBenefitNotification,
    parseBenefitNotificationPlaintext,
    pythonQuote,
    pythonUnquotePlus,
    serializePythonStringMapArray
};
