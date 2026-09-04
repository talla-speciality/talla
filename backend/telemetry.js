const crypto = require("crypto");
const fs = require("fs");

const EVENT_NAME = /^[a-z][a-z0-9_]{1,63}$/;
const SAFE_KEY = /^[a-zA-Z][a-zA-Z0-9_]{0,63}$/;
const PLATFORMS = new Set(["ios", "android", "watchos", "widget", "backend"]);
const CATEGORIES = new Set(["analytics", "crash", "performance"]);
const SENSITIVE_KEY = /(authorization|card|email|password|secret|token)/i;

function safeText(value, maximum = 200) {
    return String(value || "").trim().slice(0, maximum);
}

function safeProperties(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) return {};
    const result = {};
    for (const [key, raw] of Object.entries(value).slice(0, 30)) {
        if (!SAFE_KEY.test(key) || SENSITIVE_KEY.test(key)) continue;
        if (typeof raw === "boolean") result[key] = raw;
        else if (typeof raw === "number" && Number.isFinite(raw)) result[key] = raw;
        else if (typeof raw === "string") result[key] = safeText(raw, 300);
    }
    return result;
}

function normalizeTelemetryEvent(value = {}, now = new Date()) {
    const eventName = safeText(value.eventName, 64).toLowerCase();
    const platform = safeText(value.platform, 20).toLowerCase();
    const category = safeText(value.category || "analytics", 20).toLowerCase();
    const anonymousID = safeText(value.anonymousId, 128);
    const sessionID = safeText(value.sessionId, 128);
    const occurredAt = new Date(value.occurredAt || now);
    const oldest = now.getTime() - (31 * 24 * 60 * 60 * 1000);
    const newest = now.getTime() + (10 * 60 * 1000);

    if (!EVENT_NAME.test(eventName) || !PLATFORMS.has(platform) || !CATEGORIES.has(category)) return null;
    if (!anonymousID || !sessionID || !Number.isFinite(occurredAt.getTime())) return null;
    if (occurredAt.getTime() < oldest || occurredAt.getTime() > newest) return null;

    return {
        id: safeText(value.id, 128) || crypto.randomUUID(),
        eventName,
        category,
        platform,
        anonymousID,
        sessionID,
        appVersion: safeText(value.appVersion, 40) || "unknown",
        occurredAt: occurredAt.toISOString(),
        properties: safeProperties(value.properties)
    };
}

function normalizeTelemetryBatch(value, maximum = 50) {
    const entries = Array.isArray(value?.events) ? value.events : [value];
    return entries.slice(0, maximum).map((entry) => normalizeTelemetryEvent(entry)).filter(Boolean);
}

async function persistTelemetryEvent(event, { database, fallbackPath, accountEmail = null }) {
    if (database.isEnabled()) {
        await database.query(
            `INSERT INTO telemetry_events
             (id, event_name, category, platform, anonymous_id, session_id, account_email,
              app_version, occurred_at, properties, received_at)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::jsonb, NOW())
             ON CONFLICT (id) DO NOTHING`,
            [event.id, event.eventName, event.category, event.platform, event.anonymousID,
                event.sessionID, accountEmail, event.appVersion, event.occurredAt, JSON.stringify(event.properties)]
        );
        return;
    }

    const store = JSON.parse(fs.readFileSync(fallbackPath, "utf8"));
    store.events = Array.isArray(store.events) ? store.events : [];
    if (!store.events.some((candidate) => candidate.id === event.id)) {
        store.events.push({ ...event, accountEmail, receivedAt: new Date().toISOString() });
        store.events = store.events.slice(-10_000);
        fs.writeFileSync(fallbackPath, JSON.stringify(store, null, 2));
    }
}

module.exports = {
    normalizeTelemetryBatch,
    normalizeTelemetryEvent,
    persistTelemetryEvent,
    safeProperties
};
