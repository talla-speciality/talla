const managedFields = Object.freeze({
    origin: "Talla Origin:", region: "Talla Region:", producer: "Talla Producer:",
    variety: "Talla Variety:", process: "Talla Process:", roastLevel: "Talla Roast:",
    tastingNotes: "Talla Notes:", roastDate: "Talla Roast Date:", bagWeightGrams: "Talla Bag Grams:",
    replacementProductID: "Talla Replacement:"
});
const defaultCoffeeMemorySettings = Object.freeze({ enabled: true, automaticPurchaseImport: true, roastDateOCR: true, replacementRecommendations: true });

function normalizeCoffeeMemorySettings(value = {}) {
    return Object.fromEntries(Object.entries(defaultCoffeeMemorySettings).map(([key, fallback]) => [key, value[key] === undefined ? fallback : Boolean(value[key])]));
}

function clean(value, maximum = 180) {
    return String(value ?? "").trim().replace(/\s+/g, " ").slice(0, maximum);
}

function coffeeMetadataFromTags(tags = []) {
    const result = {};
    for (const tag of Array.isArray(tags) ? tags : []) {
        const text = String(tag || "").trim();
        for (const [field, prefix] of Object.entries(managedFields)) {
            if (text.toLowerCase().startsWith(prefix.toLowerCase())) result[field] = clean(text.slice(prefix.length));
        }
        if (text.toLowerCase() === "talla replacement excluded") result.excludeFromReplacements = true;
    }
    return result;
}

function nextCoffeeTags(existingTags = [], metadata = {}) {
    const prefixes = Object.values(managedFields).map((value) => value.toLowerCase());
    const tags = (Array.isArray(existingTags) ? existingTags : []).map((tag) => clean(tag)).filter(Boolean).filter((tag) => {
        const lower = tag.toLowerCase();
        return lower !== "talla replacement excluded" && !prefixes.some((prefix) => lower.startsWith(prefix));
    });
    for (const [field, prefix] of Object.entries(managedFields)) {
        const value = clean(metadata[field]);
        if (value) tags.push(`${prefix} ${value}`.slice(0, 255));
    }
    if (metadata.excludeFromReplacements === true) tags.push("Talla Replacement Excluded");
    return [...new Set(tags)];
}

function createCoffeeAdminService(database, normalizeEmail = (value) => String(value || "").trim().toLowerCase()) {
    async function summary() {
        if (!database.isEnabled()) return { configured: false, totals: {}, recentRecords: [] };
        const [counts, recent] = await Promise.all([
            database.query(`SELECT COUNT(DISTINCT email)::int AS customers,
                COUNT(*) FILTER (WHERE deleted_at IS NULL)::int AS records,
                COUNT(*) FILTER (WHERE entity_type = 'coffeeLot' AND deleted_at IS NULL)::int AS lots,
                COUNT(*) FILTER (WHERE entity_type = 'purchasedCoffee' AND deleted_at IS NULL)::int AS purchased_bags,
                COUNT(*) FILTER (WHERE entity_type = 'brewSession' AND deleted_at IS NULL)::int AS brew_sessions,
                COUNT(*) FILTER (WHERE entity_type = 'doseUsage' AND deleted_at IS NULL)::int AS dose_records,
                COUNT(*) FILTER (WHERE updated_by_device = 'shopify' AND deleted_at IS NULL)::int AS shopify_imports,
                COUNT(*) FILTER (WHERE entity_type = 'coffeeLot' AND deleted_at IS NULL AND
                    COALESCE(payload->>'origin','') = '' AND COALESCE(payload->>'process','') = '' AND COALESCE(payload->>'roastLevel','') = '')::int AS lots_missing_metadata,
                MAX(updated_at) AS last_sync_at FROM coffee_records`),
            database.query(`SELECT email, entity_type, record_id, payload, revision, updated_at, updated_by_device
                FROM coffee_records WHERE deleted_at IS NULL ORDER BY updated_at DESC LIMIT 100`)
        ]);
        const row = counts.rows[0] || {};
        return { configured: true, totals: {
            customers: Number(row.customers || 0), records: Number(row.records || 0), lots: Number(row.lots || 0),
            purchasedBags: Number(row.purchased_bags || 0), brewSessions: Number(row.brew_sessions || 0),
            doseRecords: Number(row.dose_records || 0), shopifyImports: Number(row.shopify_imports || 0),
            lotsMissingMetadata: Number(row.lots_missing_metadata || 0), lastSyncAt: row.last_sync_at || null
        }, recentRecords: recent.rows.map((entry) => ({
            id: entry.record_id, email: entry.email, entityType: entry.entity_type, recordID: entry.record_id,
            title: entry.payload?.name || entry.payload?.productName || entry.payload?.title || entry.entity_type,
            revision: entry.revision, updatedAt: entry.updated_at, source: entry.updated_by_device
        })) };
    }
    async function deleteRecord(email, entityType, recordID) {
        if (!database.isEnabled()) return false;
        const result = await database.query(
            `DELETE FROM coffee_records WHERE email = $1 AND entity_type = $2 AND record_id = $3 RETURNING record_id`,
            [normalizeEmail(email), String(entityType || ""), String(recordID || "")]
        );
        return result.rows.length > 0;
    }
    return { deleteRecord, summary };
}

module.exports = { coffeeMetadataFromTags, createCoffeeAdminService, defaultCoffeeMemorySettings, nextCoffeeTags, normalizeCoffeeMemorySettings };
