const DAY_MS = 86_400_000;

function text(value, limit = 240) {
    return String(value || "").trim().slice(0, limit);
}

function date(value) {
    const parsed = value ? new Date(value) : null;
    return parsed && Number.isFinite(parsed.getTime()) ? parsed : null;
}

function grams(item) {
    const direct = Number(item?.remainingQuantityGrams ?? item?.remainingGrams ?? item?.grams ?? item?.weightGrams);
    if (Number.isFinite(direct) && direct >= 0) return direct;
    const match = `${item?.variantTitle || ""} ${item?.name || item?.productName || ""}`.match(/(\d+(?:\.\d+)?)\s*(kg|g)\b/i);
    return match ? Number(match[1]) * (match[2].toLowerCase() === "kg" ? 1000 : 1) : 250;
}

function recordPayload(record) {
    return record?.payload && typeof record.payload === "object" ? record.payload : record;
}

function normalizeRecord(record) {
    const value = recordPayload(record);
    const remaining = grams(value);
    const initial = Number(value.initialQuantityGrams || value.initialGrams || remaining);
    return {
        id: text(value.id || record?.recordId, 120),
        productID: text(value.productID || value.productId, 240),
        productName: text(value.productName || value.name || "Coffee", 180),
        remainingQuantityGrams: remaining,
        initialQuantityGrams: Number.isFinite(initial) && initial > 0 ? initial : remaining,
        roastDate: value.roastDate || null,
        purchasedAt: value.purchasedAt || value.openedAt || null,
        replacementProductID: text(value.replacementProductID || value.replacementProductId, 240),
        excludeFromReplacements: value.excludeFromReplacements === true
    };
}

function freshnessFor(item, now = new Date()) {
    const roastDate = date(item?.roastDate);
    if (!roastDate) return { state: "unknown", days: null };
    const days = Math.max(0, Math.floor((now.getTime() - roastDate.getTime()) / DAY_MS));
    return { state: days > 45 ? "stale-risk" : days > 30 ? "use-soon" : "fresh", days };
}

function fallbackRecordsFromOrders(orders = []) {
    return (Array.isArray(orders) ? orders : []).flatMap((order) => (
        Array.isArray(order?.items) ? order.items.map((item, index) => ({
            entityType: "purchasedCoffee",
            recordId: `${order.id || "order"}-${index}`,
            payload: {
                productID: item.productId || item.productID || item.variantId || "",
                productName: item.productTitle || item.name || item.title || "Coffee",
                initialQuantityGrams: grams(item) * Math.max(1, Number(item.quantity || 1)),
                remainingQuantityGrams: grams(item) * Math.max(1, Number(item.quantity || 1)),
                purchasedAt: order.createdAt,
                roastDate: item.roastDate || item.tags?.roastDate || null,
                replacementProductID: item.replacementProductID || ""
            }
        })) : []
    ));
}

function buildCoffeeInsights({ records = [], orders = [], now = new Date(), doseGrams = 18 } = {}) {
    const source = Array.isArray(records) && records.length ? records : fallbackRecordsFromOrders(orders);
    const lots = new Map();
    for (const record of source) {
        if (record?.entityType && record.entityType !== "purchasedCoffee") continue;
        const item = normalizeRecord(record);
        if (!item.productName || item.remainingQuantityGrams <= 0) continue;
        const key = item.id || `${item.productID}:${item.productName}`;
        lots.set(key, item);
    }
    const inventory = [...lots.values()].map((item) => {
        const freshness = freshnessFor(item, now);
        const estimatedBrews = Math.floor(item.remainingQuantityGrams / Math.max(1, doseGrams));
        const reorderDue = estimatedBrews <= 3;
        return {
            ...item,
            estimatedBrews,
            reorderDue,
            freshness,
            reason: reorderDue ? `${estimatedBrews} brews left at a ${doseGrams}g dose.` : freshness.state === "stale-risk" ? "Roast date suggests using this coffee soon." : "Enough coffee remains for now."
        };
    }).sort((a, b) => Number(b.reorderDue) - Number(a.reorderDue) || a.remainingQuantityGrams - b.remainingQuantityGrams);
    const reorder = inventory.filter((item) => item.reorderDue).map((item) => ({
        productID: item.productID || null,
        productName: item.productName,
        replacementProductID: item.excludeFromReplacements ? null : item.replacementProductID || item.productID || null,
        estimatedBrews: item.estimatedBrews,
        reason: item.reason
    }));
    const freshness = inventory.reduce((summary, item) => {
        summary[item.freshness.state] = (summary[item.freshness.state] || 0) + 1;
        return summary;
    }, {});
    return { inventory, reorder, freshness, doseGrams };
}

module.exports = { buildCoffeeInsights, fallbackRecordsFromOrders, freshnessFor, normalizeRecord };
