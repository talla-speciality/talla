const clean = (value, limit = 180) => typeof value === "string" ? value.trim().slice(0, limit) : "";

// Only purchase-time data belongs here. Never enrich historical orders from today's catalog.
function orderItemOptions({ productTitle, variantTitle, selectedOptions } = {}) {
    const product = clean(productTitle);
    const variant = clean(variantTitle);
    const options = (Array.isArray(selectedOptions) ? selectedOptions : [])
        .map((option) => ({ name: clean(option?.name, 80), value: clean(option?.value) }))
        .filter((option) => option.name && option.value
            && !(option.name.toLowerCase() === "title" && option.value.toLowerCase() === "default title"))
        .slice(0, 10);
    return {
        ...(product ? { productTitle: product } : {}),
        ...(variant && variant.toLowerCase() !== "default title" ? { variantTitle: variant } : {}),
        ...(options.length ? { selectedOptions: options } : {})
    };
}

async function snapshotCheckoutOptions(items, request) {
    const ids = [...new Set(items.map((item) => item.variantId).filter(Boolean))];
    if (!ids.length) return items;
    try {
        const data = await request(`query CheckoutItemOptions($ids: [ID!]!) {
            nodes(ids: $ids) { ... on ProductVariant {
                id title selectedOptions { name value } product { title }
            } }
        }`, { ids });
        const variants = new Map((data.nodes || []).filter(Boolean).map((node) => [node.id, node]));
        return items.map((item) => {
            const variant = variants.get(item.variantId);
            return variant ? { ...item, ...orderItemOptions({
                productTitle: variant.product?.title,
                variantTitle: variant.title,
                selectedOptions: variant.selectedOptions
            }) } : item;
        });
    } catch {
        // Optional metadata must not prevent legacy clients from placing an order.
        return items;
    }
}

module.exports = { orderItemOptions, snapshotCheckoutOptions };
