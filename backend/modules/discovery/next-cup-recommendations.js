const DEFAULT_MAX_RESULTS = 3;

function text(value, limit = 500) {
    return String(value || "").trim().slice(0, limit);
}

function terms(value) {
    return new Set(text(value, 2_000).toLowerCase().split(/[^\p{L}\p{N}]+/u).filter((term) => term.length > 2));
}

function list(value) {
    return Array.isArray(value) ? value.map((entry) => text(entry, 120).toLowerCase()).filter(Boolean) : [];
}

function productText(product) {
    return [product?.title, product?.name, product?.description, product?.descriptionHtml, product?.productType, product?.vendor, product?.origin, product?.region, product?.producer, product?.process, product?.variety, product?.roastLevel, product?.tastingNotes, ...(Array.isArray(product?.tags) ? product.tags : [])].map((value) => text(value, 500)).filter(Boolean).join(" ");
}

function productID(product) {
    return text(product?.id || product?.productID || product?.productId, 240);
}

function isAvailable(product) {
    return product?.availableForSale !== false && product?.status !== "ARCHIVED" && product?.status !== "DRAFT";
}

function freshnessState(purchase, now = new Date()) {
    const roastDate = purchase?.roastDate ? new Date(purchase.roastDate) : null;
    if (!roastDate || !Number.isFinite(roastDate.getTime())) return { state: "unknown", days: null };
    const days = Math.max(0, Math.floor((now.getTime() - roastDate.getTime()) / 86_400_000));
    return { state: days > 45 ? "stale-risk" : days > 30 ? "use-soon" : "fresh", days };
}

function tasteSignals(tasteMemory = [], journal = []) {
    const loved = new Map();
    const disliked = new Map();
    for (const record of Array.isArray(tasteMemory) ? tasteMemory : []) {
        const target = record?.reaction === "loved" ? loved : record?.reaction === "not-for-me" ? disliked : null;
        if (!target) continue;
        for (const tag of list(record.tags)) target.set(tag, (target.get(tag) || 0) + 3);
        for (const tag of terms(record.productName)) target.set(tag, (target.get(tag) || 0) + 1);
    }
    for (const entry of Array.isArray(journal) ? journal : []) {
        const target = Number(entry?.rating) >= 4 ? loved : Number(entry?.rating) <= 2 ? disliked : null;
        if (!target) continue;
        for (const tag of terms(`${entry.title} ${entry.notes}`)) target.set(tag, (target.get(tag) || 0) + 1);
        const method = text(entry.method, 120).toLowerCase();
        if (method) target.set(method, (target.get(method) || 0) + 1);
    }
    return { loved, disliked };
}

function purchaseSignals(orders = []) {
    const names = new Set();
    const purchasedAt = [];
    for (const order of Array.isArray(orders) ? orders : []) {
        const date = new Date(order?.createdAt || order?.updatedAt || "");
        if (Number.isFinite(date.getTime())) purchasedAt.push(date);
        for (const item of Array.isArray(order?.items) ? order.items : []) {
            const name = text(item?.name || item?.title || item?.productTitle, 160).toLowerCase();
            if (name) names.add(name);
        }
    }
    purchasedAt.sort((a, b) => b - a);
    return { names, purchasedAt };
}

function explanation(score, reasons) {
    const unique = [...new Set(reasons.filter(Boolean))].slice(0, 3);
    return { score, reasons: unique, summary: unique.length ? unique.join(" ") : "Available from Talla and ready to try." };
}

function normalizeRecommendation(product, score, reasons) {
    const id = productID(product);
    return { productID: id, title: text(product?.title || product?.name || "Coffee", 180), price: product?.price || null, availableForSale: isAvailable(product), imageURL: text(product?.imageURL || product?.imageUrl, 500) || null, recommendation: explanation(score, reasons), actions: [{ kind: "brew", productID: id }, { kind: "buy", productID: id }, { kind: "save", productID: id }] };
}

function recommendNextCup({ products = [], tasteMemory = [], brewJournal = [], orders = [], coffeeInsights = null, query = "", now = new Date(), maxResults = DEFAULT_MAX_RESULTS } = {}) {
    const signals = tasteSignals(tasteMemory, brewJournal);
    const purchases = purchaseSignals(orders);
    const requested = terms(query);
    const candidates = (Array.isArray(products) ? products : []).filter(isAvailable).map((product) => {
        const haystack = terms(productText(product));
        let score = 0;
        const reasons = [];
        for (const [term, weight] of signals.loved) if (haystack.has(term)) { score += weight; reasons.push(`Matches what you have enjoyed before (${term}).`); }
        for (const [term, weight] of signals.disliked) if (haystack.has(term)) { score -= weight; reasons.push(`Avoids a taste profile you marked as not for you (${term}).`); }
        for (const term of requested) if (haystack.has(term)) { score += 4; reasons.push(`Matches your current request (${term}).`); }
        const name = text(product?.title || product?.name, 180).toLowerCase();
        if (name && purchases.names.has(name)) { score += 3; reasons.push("You have bought this before, so it is an easy reorder."); }
        const inventoryItem = coffeeInsights?.inventory?.find((item) => item.productID && item.productID === productID(product));
        const reorderItem = coffeeInsights?.reorder?.find((item) => item.productID === productID(product) || item.replacementProductID === productID(product));
        if (reorderItem) { score += 6; reasons.push(`${reorderItem.productName} is nearly finished, so this is a timely reorder.`); }
        if (inventoryItem?.freshness?.state === "stale-risk") reasons.push("Your current bag is past its best window, so a fresher bag may taste better.");
        if (product?.availableForSale === true) { score += 1; reasons.push("Available now."); }
        return { product, score, reasons };
    }).sort((a, b) => b.score - a.score || text(a.product?.title || a.product?.name).localeCompare(text(b.product?.title || b.product?.name)));
    const recommendations = candidates.slice(0, Math.max(1, Math.min(10, Number(maxResults) || DEFAULT_MAX_RESULTS))).map(({ product, score, reasons }) => normalizeRecommendation(product, score, reasons));
    const latestPurchase = purchases.purchasedAt[0];
    const reorderDue = latestPurchase ? Math.floor((now.getTime() - latestPurchase.getTime()) / 86_400_000) >= 14 : false;
    const latestFreshness = coffeeInsights?.inventory?.[0]?.freshness || freshnessState(orders.find((order) => order?.roastDate), now);
    return { action: recommendations[0] ? (reorderDue || coffeeInsights?.reorder?.length ? "reorder-or-discover" : "brew-next") : "complete-taste-profile", headline: recommendations[0] ? (reorderDue || coffeeInsights?.reorder?.length ? "Your next cup is ready." : "Try this next.") : "Tell Talla what you like to improve your next cup.", recommendations, profile: { lovedSignals: [...signals.loved.keys()].slice(0, 12), avoidedSignals: [...signals.disliked.keys()].slice(0, 12) }, freshness: latestFreshness, coffeeInsights };
}

module.exports = { freshnessState, recommendNextCup, tasteSignals };
