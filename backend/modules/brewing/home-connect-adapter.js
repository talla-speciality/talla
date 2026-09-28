const crypto = require("crypto");

const authorizationEndpoint = "https://api.home-connect.com/security/oauth/authorize";
const tokenEndpoint = "https://api.home-connect.com/security/oauth/token";

function randomState() {
    return crypto.randomBytes(32).toString("base64url");
}

function authorizationURL({ clientID, redirectURI, state, scope = "IdentifyAppliance CoffeeMaker Monitor" }) {
    if (!clientID || !state) throw new Error("HOME_CONNECT_CLIENT_ID_AND_STATE_REQUIRED");
    const url = new URL(authorizationEndpoint);
    url.searchParams.set("response_type", "code");
    url.searchParams.set("client_id", clientID);
    url.searchParams.set("scope", scope);
    url.searchParams.set("state", state);
    if (redirectURI) url.searchParams.set("redirect_uri", redirectURI);
    return url.toString();
}

function tokenForm(values) {
    const form = new URLSearchParams();
    for (const [key, value] of Object.entries(values)) if (value != null && value !== "") form.set(key, String(value));
    return form;
}

function sealSecret(value, secret, randomBytes = crypto.randomBytes) {
    if (!secret) throw new Error("ENCRYPTION_SECRET_REQUIRED");
    const key = crypto.createHash("sha256").update(String(secret)).digest();
    const iv = randomBytes(12);
    const cipher = crypto.createCipheriv("aes-256-gcm", key, iv);
    const encrypted = Buffer.concat([cipher.update(String(value), "utf8"), cipher.final()]);
    return `${iv.toString("base64url")}.${cipher.getAuthTag().toString("base64url")}.${encrypted.toString("base64url")}`;
}

function openSecret(value, secret) {
    if (!secret || !value) throw new Error("ENCRYPTED_SECRET_INVALID");
    const [ivText, tagText, encryptedText] = String(value).split(".");
    const key = crypto.createHash("sha256").update(String(secret)).digest();
    const decipher = crypto.createDecipheriv("aes-256-gcm", key, Buffer.from(ivText, "base64url"));
    decipher.setAuthTag(Buffer.from(tagText, "base64url"));
    return Buffer.concat([decipher.update(Buffer.from(encryptedText, "base64url")), decipher.final()]).toString("utf8");
}

function normalizeTokenResponse(payload, now = Date.now) {
    if (!payload?.access_token || !payload?.refresh_token) throw new Error("HOME_CONNECT_TOKEN_RESPONSE_INVALID");
    const expiresIn = Math.max(60, Number(payload.expires_in) || 86_400);
    return {
        accessToken: String(payload.access_token),
        refreshToken: String(payload.refresh_token),
        tokenType: String(payload.token_type || "Bearer"),
        scope: String(payload.scope || ""),
        expiresAt: new Date(Number(now()) + expiresIn * 1000).toISOString()
    };
}

function createHomeConnectAdapter({ clientID, clientSecret, redirectURI, fetchFn = fetch, now = Date.now }) {
    async function requestJSON(url, options = {}) {
        const response = await fetchFn(url, {
            ...options,
            headers: {
                Accept: "application/vnd.home-connect.api+json",
                ...(options.body ? { "Content-Type": "application/vnd.bsh.sdk.v1+json" } : {}),
                ...(options.headers || {})
            }
        });
        const payload = response.status === 204 ? null : await response.json();
        if (!response.ok) throw Object.assign(new Error("HOME_CONNECT_API_REQUEST_FAILED"), { statusCode: response.status, payload });
        return payload;
    }

    async function postToken(values) {
        const response = await fetchFn(tokenEndpoint, {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: tokenForm(values)
        });
        const payload = await response.json();
        if (!response.ok) throw Object.assign(new Error("HOME_CONNECT_TOKEN_REQUEST_FAILED"), { statusCode: response.status, payload });
        return normalizeTokenResponse(payload, now);
    }

    return {
        authorizationURL: (state) => authorizationURL({ clientID, redirectURI, state }),
        exchangeCode: (code) => postToken({ grant_type: "authorization_code", code, client_id: clientID, client_secret: clientSecret, redirect_uri: redirectURI }),
        refresh: (refreshToken) => postToken({ grant_type: "refresh_token", refresh_token: refreshToken, client_id: clientID, client_secret: clientSecret }),
        async listAppliances(accessToken) {
            return requestJSON("https://api.home-connect.com/api/homeappliances", { headers: { Authorization: `Bearer ${accessToken}` } });
        },
        getStatus(accessToken, applianceID) {
            return requestJSON(`https://api.home-connect.com/api/homeappliances/${encodeURIComponent(applianceID)}/status`, { headers: { Authorization: `Bearer ${accessToken}` } });
        },
        setPowerState(accessToken, applianceID, value) {
            return requestJSON(`https://api.home-connect.com/api/homeappliances/${encodeURIComponent(applianceID)}/settings/BSH.Common.Setting.PowerState`, {
                method: "PUT",
                headers: { Authorization: `Bearer ${accessToken}` },
                body: JSON.stringify({ data: { key: "BSH.Common.Setting.PowerState", value } })
            });
        },
        startEspresso(accessToken, applianceID, { fillQuantity = 35, beanAmount = "Strong" } = {}) {
            const quantity = Math.max(1, Math.min(500, Math.round(Number(fillQuantity) || 35)));
            const strength = ["Mild", "Normal", "Strong", "VeryStrong"].includes(beanAmount) ? beanAmount : "Strong";
            return requestJSON(`https://api.home-connect.com/api/homeappliances/${encodeURIComponent(applianceID)}/programs/active`, {
                method: "PUT",
                headers: { Authorization: `Bearer ${accessToken}` },
                body: JSON.stringify({ data: {
                    key: "ConsumerProducts.CoffeeMaker.Program.Beverage.Espresso",
                    options: [
                        { key: "ConsumerProducts.CoffeeMaker.Option.BeanAmount", value: `ConsumerProducts.CoffeeMaker.EnumType.BeanAmount.${strength}` },
                        { key: "ConsumerProducts.CoffeeMaker.Option.FillQuantity", value: quantity }
                    ]
                } })
            });
        }
    };
}

module.exports = { authorizationURL, createHomeConnectAdapter, normalizeTokenResponse, openSecret, randomState, sealSecret, tokenForm };
