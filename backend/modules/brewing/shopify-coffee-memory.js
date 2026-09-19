const crypto = require("crypto");
const { coffeeMetadataFromTags } = require("./coffee-admin");

function stableUUID(value) {
    const bytes = Buffer.from(crypto.createHash("sha256").update(String(value)).digest().subarray(0, 16));
    bytes[6] = (bytes[6] & 0x0f) | 0x50;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    const hex = bytes.toString("hex");
    return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

function isCoffeeItem(item) {
    const source = [item.productType, ...(Array.isArray(item.tags) ? item.tags : []), item.productTitle, item.name]
        .filter(Boolean).join(" ").toLowerCase();
    const excluded = /grinder|filter|brewer|dripper|kettle|scale|mug|cup|server|paper|equipment|gift card/.test(source);
    return !excluded && /coffee|beans?|قهوة|بن|microlot|single origin|espresso roast|filter roast/.test(source);
}

function gramsForItem(item) {
    const direct = Number(item.grams || item.weightGrams || 0);
    if (Number.isFinite(direct) && direct > 0) return direct;
    const match = `${item.variantTitle || ""} ${item.name || ""}`.match(/(\d+(?:\.\d+)?)\s*(kg|g)\b/i);
    if (!match) return 250;
    return Number(match[1]) * (match[2].toLowerCase() === "kg" ? 1000 : 1);
}

async function importShopifyCoffeePurchases(database, order) {
    if (!database?.isEnabled?.() || !order?.email || !order?.id) return 0;
    let imported = 0;
    for (const [index, item] of (order.items || []).entries()) {
        if (!isCoffeeItem(item)) continue;
        const metadata = coffeeMetadataFromTags(item.tags);
        const productID = String(item.productId || item.productID || "");
        const variantID = String(item.variantId || item.variantID || "");
        const lotID = stableUUID(`shopify-lot:${productID}:${variantID || item.name}`);
        const purchaseID = stableUUID(`shopify-purchase:${order.id}:${variantID}:${index}`);
        const quantity = Math.max(1, Number(item.quantity || 1));
        const grams = gramsForItem({ ...item, grams: item.grams || metadata.bagWeightGrams }) * quantity;
        const lot = {
            id: lotID, name: String(item.productTitle || item.name || "Coffee"), roaster: String(item.vendor || ""),
            productID, variantID, origin: String(item.origin || metadata.origin || ""),
            region: String(item.region || metadata.region || ""), producer: String(item.producer || metadata.producer || ""),
            variety: String(item.variety || metadata.variety || ""), process: String(item.process || metadata.process || ""),
            roastLevel: String(item.roastLevel || metadata.roastLevel || ""), tastingNotes: String(item.tastingNotes || metadata.tastingNotes || ""),
            replacementProductID: String(metadata.replacementProductID || ""), excludeFromReplacements: metadata.excludeFromReplacements === true
        };
        const purchase = {
            id: purchaseID, lotID, productID, variantID, productName: lot.name,
            purchasedAt: order.createdAt || new Date().toISOString(),
            initialQuantityGrams: grams, remainingQuantityGrams: grams, roastDate: metadata.roastDate || null
        };
        for (const [entityType, id, payload] of [["coffeeLot", lotID, lot], ["purchasedCoffee", purchaseID, purchase]]) {
            await database.query(
                `INSERT INTO coffee_records
                    (email, entity_type, record_id, payload, revision, updated_at, updated_by_device, sync_cursor)
                 VALUES ($1,$2,$3,$4::jsonb,1,NOW(),'shopify',nextval('coffee_sync_cursor_seq'))
                 ON CONFLICT (email, entity_type, record_id) DO NOTHING`,
                [order.email, entityType, id, JSON.stringify(payload)]
            );
        }
        imported += 1;
    }
    return imported;
}

module.exports = { gramsForItem, importShopifyCoffeePurchases, isCoffeeItem, stableUUID };
