class CheckoutPricingError extends Error {
    constructor(code, statusCode, message) {
        super(message);
        this.name = "CheckoutPricingError";
        this.code = code;
        this.statusCode = statusCode;
    }
}

const shopifyVariantPrefix = "gid://shopify/ProductVariant/";
const khaleejiCountries = new Set(["SA", "KW", "AE", "QA", "OM"]);

function fail(code, statusCode, message) {
    throw new CheckoutPricingError(code, statusCode, message);
}

function toFils(value, code = "CHECKOUT_PRICE_INVALID") {
    const normalized = typeof value === "number" ? value.toFixed(3) : String(value || "").trim();
    const match = normalized.match(/^(\d+)(?:\.(\d{1,3}))?$/);
    if (!match) fail(code, 409, "A checkout price is invalid. Refresh your bag and try again.");
    const fils = Number(match[1]) * 1000 + Number((match[2] || "").padEnd(3, "0"));
    if (!Number.isSafeInteger(fils)) fail(code, 409, "A checkout price is invalid. Refresh your bag and try again.");
    return fils;
}

function configuredFils(value, code) {
    const number = Number(value);
    if (!Number.isFinite(number) || number < 0) {
        fail(code, 503, "Checkout pricing is temporarily unavailable.");
    }
    return Math.round(number * 1000);
}

function weightInGrams(weight) {
    const value = Number(weight?.value);
    if (!Number.isFinite(value) || value <= 0) return null;
    switch (String(weight?.unit || "").toUpperCase()) {
    case "GRAMS": return value;
    case "KILOGRAMS": return value * 1000;
    case "OUNCES": return value * 28.349523125;
    case "POUNDS": return value * 453.59237;
    default: return null;
    }
}

function normalizeSubmittedItems(items) {
    if (!Array.isArray(items) || items.length === 0 || items.length > 30) {
        fail("CHECKOUT_ITEMS_INVALID", 400, "Your bag has no valid items.");
    }
    const lines = new Map();
    for (const item of items) {
        const variantId = String(item?.variantId || item?.variantID || "").trim();
        const quantity = Number(item?.quantity);
        if (!variantId.startsWith(shopifyVariantPrefix)
            || !Number.isSafeInteger(quantity)
            || quantity < 1
            || quantity > 99) {
            fail("CHECKOUT_ITEMS_INVALID", 400, "An item in your bag is invalid. Refresh your bag and try again.");
        }
        const current = lines.get(variantId) || 0;
        if (current + quantity > 99) {
            fail("CHECKOUT_QUANTITY_INVALID", 400, "An item quantity is too large.");
        }
        lines.set(variantId, current + quantity);
    }
    return Array.from(lines, ([variantId, quantity]) => ({ variantId, quantity }));
}

function isEligibleDrink(node) {
    const handles = (node?.product?.collections?.nodes || [])
        .map((collection) => String(collection?.handle || "").trim().toLowerCase());
    const productType = String(node?.product?.productType || "").trim().toLowerCase();
    return handles.includes("ready-made-drinks") || ["drinks", "summer drinks"].includes(productType);
}

function voucherDiscountFils(voucher, lines, subtotalFils) {
    const reward = String(voucher?.reward || "").trim().toLowerCase();
    switch (reward) {
    case "free drink":
        return Math.max(0, ...lines.filter((line) => line.eligibleDrink).map((line) => line.unitPriceFils));
    case "pastry pairing":
        return Math.min(subtotalFils, 2000);
    case "bag discount":
        return Math.round(subtotalFils * 0.10);
    case "brew bar credit":
        return Math.min(subtotalFils, 3000);
    case "talla box reward":
        return Math.round(subtotalFils * 0.15);
    case "roastery gold reward":
        return Math.round(subtotalFils * 0.20);
    default:
        return 0;
    }
}

function shippingFils({ lines, fulfillmentMethod, countryCode, paymentMethod, settings }) {
    if (fulfillmentMethod === "pickup") return 0;
    if (fulfillmentMethod !== "delivery" || !countryCode) {
        fail("CHECKOUT_FULFILLMENT_INVALID", 400, "Choose a valid delivery or pickup option.");
    }
    const fulfillment = settings?.fulfillment || {};
    if (countryCode === "BH") return configuredFils(fulfillment.bahrainRate, "CHECKOUT_SHIPPING_INVALID");
    if (!khaleejiCountries.has(countryCode)) {
        fail("CHECKOUT_COUNTRY_UNSUPPORTED", 400, "Use Shopify Checkout for delivery outside the GCC.");
    }
    const weightGrams = lines.reduce((total, line) => {
        if (!line.requiresShipping) return total;
        if (!line.weightGrams) fail("CHECKOUT_WEIGHT_MISSING", 409, "A product has no shipping weight. Please contact Talla.");
        return total + line.weightGrams * line.quantity;
    }, 0);
    const maximum = Number(fulfillment.maximumKhaleejiWeightGrams);
    if (!Number.isFinite(maximum) || maximum <= 0 || weightGrams > maximum) {
        fail("CHECKOUT_WEIGHT_UNSUPPORTED", 409, "GCC delivery is available for shipments up to 4 kg.");
    }
    const tiers = (Array.isArray(fulfillment.khaleejiTiers) ? fulfillment.khaleejiTiers : [])
        .map((tier) => ({ maximum: Number(tier.maximumWeightGrams), rate: Number(tier.rate) }))
        .filter((tier) => Number.isFinite(tier.maximum) && Number.isFinite(tier.rate) && tier.maximum > 0 && tier.rate >= 0)
        .sort((left, right) => left.maximum - right.maximum);
    const tier = tiers.find((candidate) => weightGrams <= candidate.maximum);
    if (!tier) fail("CHECKOUT_SHIPPING_INVALID", 503, "Checkout shipping is temporarily unavailable.");
    const surcharge = String(paymentMethod || "").toLowerCase() === "cashondelivery"
        ? configuredFils(fulfillment.khaleejiCashOnDeliverySurcharge, "CHECKOUT_SHIPPING_INVALID")
        : 0;
    return configuredFils(tier.rate, "CHECKOUT_SHIPPING_INVALID") + surcharge;
}

function voucherError(error) {
    switch (error?.message) {
    case "VOUCHER_NOT_FOUND": return new CheckoutPricingError("VOUCHER_NOT_FOUND", 404, "Voucher not found.");
    case "VOUCHER_EMAIL_MISMATCH": return new CheckoutPricingError("VOUCHER_EMAIL_MISMATCH", 403, "This voucher belongs to another account.");
    case "VOUCHER_ALREADY_USED": return new CheckoutPricingError("VOUCHER_ALREADY_USED", 409, "This voucher has already been used.");
    case "VOUCHER_EXPIRED": return new CheckoutPricingError("VOUCHER_EXPIRED", 410, "This voucher has expired.");
    default: return error;
    }
}

function createCheckoutPricingService({ shopifyAdminGraphQLRequest, appSettings, previewVoucher, consumeVoucher }) {
    return async function verifyCheckoutPricing(body, email) {
        const submitted = normalizeSubmittedItems(body?.items);
        let data;
        try {
            data = await shopifyAdminGraphQLRequest(
                `query CheckoutVariants($ids: [ID!]!) {
                    nodes(ids: $ids) {
                        ... on ProductVariant {
                            id displayName price availableForSale inventoryPolicy inventoryQuantity
                            inventoryItem { requiresShipping measurement { weight { value unit } } }
                            product { productType collections(first: 20) { nodes { handle } } }
                        }
                    }
                }`,
                { ids: submitted.map((line) => line.variantId) }
            );
        } catch (error) {
            const wrapped = new CheckoutPricingError("CHECKOUT_CATALOG_UNAVAILABLE", 503, "Current prices could not be verified. Please try again.");
            wrapped.cause = error;
            throw wrapped;
        }
        const nodes = new Map((data.nodes || []).filter(Boolean).map((node) => [node.id, node]));
        const lines = submitted.map((line) => {
            const node = nodes.get(line.variantId);
            if (!node) fail("CHECKOUT_PRODUCT_NOT_FOUND", 409, "A product in your bag is no longer available.");
            if (node.availableForSale === false
                || (String(node.inventoryPolicy).toUpperCase() === "DENY"
                    && Number.isFinite(Number(node.inventoryQuantity))
                    && Number(node.inventoryQuantity) < line.quantity)) {
                fail("CHECKOUT_PRODUCT_UNAVAILABLE", 409, `${node.displayName || "A product"} is no longer available in that quantity.`);
            }
            return {
                ...line,
                name: String(node.displayName || "Item").trim().slice(0, 180) || "Item",
                unitPriceFils: toFils(node.price),
                requiresShipping: node.inventoryItem?.requiresShipping !== false,
                weightGrams: weightInGrams(node.inventoryItem?.measurement?.weight),
                eligibleDrink: isEligibleDrink(node)
            };
        });
        let voucher = null;
        const voucherCode = String(body?.voucherCode || "").trim().toUpperCase();
        if (voucherCode) {
            try {
                voucher = await previewVoucher(voucherCode, email);
            } catch (error) {
                throw voucherError(error);
            }
        }
        const subtotalFils = lines.reduce((total, line) => total + line.unitPriceFils * line.quantity, 0);
        const discountFils = voucherDiscountFils(voucher, lines, subtotalFils);
        const fulfillmentMethod = String(body?.fulfillmentMethod || body?.fulfillment?.method || "").trim().toLowerCase();
        const countryCode = String(body?.fulfillment?.countryCode || "").trim().toUpperCase();
        const deliveryFils = shippingFils({
            lines,
            fulfillmentMethod,
            countryCode,
            paymentMethod: body?.paymentMethod,
            settings: appSettings()
        });
        const totalFils = Math.max(subtotalFils - discountFils, 0) + deliveryFils;
        if (toFils(body?.total, "CHECKOUT_TOTAL_INVALID") !== totalFils) {
            fail("CHECKOUT_TOTAL_CHANGED", 409, "Your price changed. Refresh your bag and review the total before paying.");
        }
        if (voucher) {
            try {
                voucher = await consumeVoucher(voucher.code, email);
            } catch (error) {
                throw voucherError(error);
            }
        }
        return {
            pricingVersion: 2,
            items: lines.map((line) => ({
                name: line.name,
                quantity: line.quantity,
                variantId: line.variantId,
                unitPrice: `BHD ${(line.unitPriceFils / 1000).toFixed(3)}`
            })),
            subtotal: subtotalFils / 1000,
            discount: discountFils / 1000,
            shipping: deliveryFils / 1000,
            total: totalFils / 1000,
            voucherCode: voucher?.code || null
        };
    };
}

module.exports = {
    CheckoutPricingError,
    createCheckoutPricingService,
    normalizeSubmittedItems,
    toFils,
    voucherDiscountFils,
    weightInGrams
};
