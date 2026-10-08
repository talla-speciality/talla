const { orderItemOptions } = require("./order-item-options");
const { normalizeGulfMarkets } = require("./gulf-localization");

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
    return handles.some((handle) => ["ready-made-drinks", "summer-drinks"].includes(handle))
        || ["drinks", "summer drinks"].includes(productType);
}

function isLimitedLot(node) {
    return (Array.isArray(node?.product?.tags) ? node.product.tags : [])
        .some((tag) => String(tag || "").trim().toUpperCase() === "LIMITED");
}

function tierRank(tier) {
    return { Bronze: 0, Silver: 1, Gold: 2, Reserve: 3 }[String(tier || "Bronze")] ?? 0;
}

function isPickupOnly(node) {
    const handles = (node?.product?.collections?.nodes || [])
        .map((collection) => String(collection?.handle || "").trim().toLowerCase());
    const productType = String(node?.product?.productType || "").trim().toLowerCase();
    return isEligibleDrink(node)
        || handles.some((handle) => ["desserts", "crmb-tallas-speciality-bakery"].includes(handle))
        || ["dessert", "desserts", "crmb"].includes(productType);
}

function isCoffeeBag(node) {
    const handles = (node?.product?.collections?.nodes || [])
        .map((collection) => String(collection?.handle || "").trim().toLowerCase());
    const productType = String(node?.product?.productType || "").trim().toLowerCase();
    const title = String(node?.product?.title || "").trim().toLowerCase();
    const tags = Array.isArray(node?.product?.tags) ? node.product.tags : [];
    const source = [title, productType, ...tags]
        .map((value) => String(value || "").trim().toLowerCase())
        .join(" ");
    const isDripBag = handles.includes("drip-bags") || /drip[- ]bags?/.test(source);
    if (isDripBag) return true;
    const isAccessory = /(?:scale|server|spoon|doser|dripper|filter|grinder|kettle|equipment|accessor|mug|cup|water|gift|box|bundle)/.test(source);

    return !isAccessory && (handles.some((handle) => ["coffee-beans", "arabic-coffee-beans"].includes(handle))
        || ["coffee", "coffee beans", "arabic coffee", "arabic coffee beans", "beans"].includes(productType)
        || ["coffee", "coffee beans", "coffee-beans", "arabic coffee", "arabic coffee beans", "arabic-coffee-beans", "beans"]
            .some((value) => tags.some((tag) => String(tag).trim().toLowerCase() === value))
        || /(?:coffee|espresso|roast|roasted|single[- ]origin|decaf|qahwa|gahwa|shamali|northern coffee)/.test(source));
}

function isArabicCoffee(node) {
    const handles = (node?.product?.collections?.nodes || [])
        .map((collection) => String(collection?.handle || "").trim().toLowerCase());
    const source = [node?.product?.title, node?.product?.productType, ...(node?.product?.tags || [])]
        .map((value) => String(value || "").trim().toLowerCase()).join(" ");
    return handles.includes("arabic-coffee-beans")
        || /(?:arabic coffee|qahwa|gahwa|shamali|northern coffee|قهوة عربية|قهوة خليجية|قهوة شمالية)/.test(source);
}

function isCoffeeFilterPack(node) {
    const handles = (node?.product?.collections?.nodes || [])
        .map((collection) => String(collection?.handle || "").trim().toLowerCase());
    const source = [node?.product?.title, node?.product?.productType, ...(node?.product?.tags || [])]
        .map((value) => String(value || "").trim().toLowerCase())
        .join(" ");
    return (handles.includes("coffee-equipment") || /coffee equipment/.test(source))
        && /(?:v60|aeropress|kalita|chemex|coffee).{0,24}filters?|filters?.{0,24}(?:v60|aeropress|kalita|chemex|coffee)|(?:فلاتر|فلتر)/.test(source);
}

function isEquipmentConsumable(node) {
    const source = [node?.product?.title, node?.product?.productType, ...(node?.product?.tags || [])]
        .map((value) => String(value || "").trim().toLowerCase()).join(" ");
    const handles = (node?.product?.collections?.nodes || []).map((collection) => String(collection?.handle || "").trim().toLowerCase());
    const consumable = /(?:filter|paper refill|cleaning tablet|cleaner|descaler|descaling|backflush|water cartridge|فلاتر|فلتر|منظف|تنظيف)/.test(source);
    return (handles.includes("coffee-equipment") || /coffee equipment/.test(source)) && consumable;
}

function isSeasonalDiscoveryBox(node) {
    const handles = (node?.product?.collections?.nodes || [])
        .map((collection) => String(collection?.handle || "").trim().toLowerCase());
    const source = [node?.product?.title, node?.product?.productType, ...(node?.product?.tags || [])]
        .map((value) => String(value || "").trim().toLowerCase())
        .join(" ");
    return handles.includes("gifts")
        && /(?:box|discovery|seasonal|صندوق|علبة)/.test(source);
}

function normalizeCoffeeClub(value, settings = {}) {
    if (value === undefined || value === null) return null;
    const configured = settings?.coffeeClub || {};
    if (configured.enabled === false) {
        fail("COFFEE_CLUB_UNAVAILABLE", 409, "Coffee Club is temporarily unavailable.");
    }
    const shipmentCount = Number(value?.shipmentCount);
    const intervalWeeks = Number(value?.intervalWeeks);
    const planType = String(value?.planType || "beans").trim().toLowerCase();
    const configuredShipmentCount = Number(configured.shipmentCount) || 3;
    const configuredIntervalWeeks = Number(configured.intervalWeeks) || 4;
    const discountPercent = Number(configured.discountPercent);
    const expectedIntervalWeeks = planType === "drip-bags" ? 1
        : ["filters", "equipment"].includes(planType) ? 12
            : planType === "seasonal-box" ? 13 : configuredIntervalWeeks;
    if (!["beans", "office", "arabic-coffee", "drip-bags", "filters", "equipment", "seasonal-box"].includes(planType)
        || shipmentCount !== configuredShipmentCount
        || intervalWeeks !== expectedIntervalWeeks) {
        fail("COFFEE_CLUB_INVALID", 400, "The Coffee Club plan changed. Refresh your bag and review it again.");
    }
    if (value?.termsAccepted !== true) {
        fail("COFFEE_CLUB_TERMS_REQUIRED", 409, "Accept the Coffee Club prepaid plan terms before checkout.");
    }
    let officeDetails = null;
    if (planType === "office") {
        const details = value?.officeDetails && typeof value.officeDetails === "object" ? value.officeDetails : {};
        const clean = (field, max) => String(details[field] || "").replace(/[\u0000-\u001f\u007f]/g, " ").replace(/\s+/g, " ").trim().slice(0, max);
        officeDetails = {
            companyName: clean("companyName", 160),
            vatRegistrationNumber: clean("vatRegistrationNumber", 80),
            commercialRegistrationNumber: clean("commercialRegistrationNumber", 80),
            purchaseOrderReference: clean("purchaseOrderReference", 100)
        };
        if (!officeDetails.companyName) {
            fail("COFFEE_CLUB_OFFICE_DETAILS_REQUIRED", 400, "Add the company name for an office coffee order.");
        }
    }
    return {
        ...(planType !== "beans" ? { planType } : {}),
        ...(officeDetails ? { officeDetails } : {}),
        shipmentCount,
        intervalWeeks,
        discountPercent: Number.isFinite(discountPercent) ? Math.max(0, Math.min(30, discountPercent)) : 10
    };
}

function voucherDiscountFils(voucher, lines, subtotalFils) {
    const reward = String(voucher?.reward || "").trim().toLowerCase();
    switch (reward) {
    case "free drink":
        return Math.max(0, ...lines.filter((line) => line.eligibleDrink).map((line) => line.unitPriceFils));
    default:
        return 0;
    }
}

function shippingFils({ lines, fulfillmentMethod, countryCode, paymentMethod, settings, freeDelivery }) {
    if (fulfillmentMethod === "pickup") return 0;
    if (fulfillmentMethod !== "delivery" || !countryCode) {
        fail("CHECKOUT_FULFILLMENT_INVALID", 400, "Choose a valid delivery or pickup option.");
    }
    if (freeDelivery) return 0;
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
    return async function verifyCheckoutPricing(body, email, loyaltyAccount = null) {
        const submitted = normalizeSubmittedItems(body?.items);
        const settings = appSettings();
        const submittedCountryCode = String(body?.fulfillment?.countryCode || "").trim().toUpperCase();
        const customerPriceMultiplier = submittedCountryCode && submittedCountryCode !== "BH" ? 1.10 : 1;
        const coffeeClub = normalizeCoffeeClub(body?.coffeeClub, settings);
        const cafePass = body?.cafePass == null ? null : body.cafePass;
        const cafePassCreditCount = cafePass ? Number(cafePass.creditCount) : 0;
        if (cafePass && (cafePass.termsAccepted !== true || !Number.isInteger(cafePassCreditCount) || cafePassCreditCount < 1 || cafePassCreditCount > 20 || coffeeClub)) {
            fail("CAFE_PASS_INVALID", 400, "The café pass terms changed. Refresh checkout and try again.");
        }
        const giftedCoffee = body?.suspendedCoffeePass === true && String(body?.gift?.recipientName || "").trim().length > 0;
        if (giftedCoffee && cafePassCreditCount !== 1) {
            fail("COFFEE_GIFT_INVALID", 400, "A coffee gift must contain exactly one prepaid drink.");
        }
        let data;
        try {
            data = await shopifyAdminGraphQLRequest(
                `query CheckoutVariants($ids: [ID!]!) {
                    nodes(ids: $ids) {
                        ... on ProductVariant {
                            id displayName title price availableForSale inventoryPolicy inventoryQuantity
                            selectedOptions { name value }
                            inventoryItem { requiresShipping measurement { weight { value unit } } }
                            product { title productType tags collections(first: 20) { nodes { handle } } }
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
            const requiredTier = settings?.loyalty?.earlyAccessMinimumTier || "Gold";
            if (settings?.loyalty?.earlyAccessEnabled !== false
                && isLimitedLot(node)
                && tierRank(loyaltyAccount?.tier) < tierRank(requiredTier)) {
                fail("LIMITED_LOT_EARLY_ACCESS", 409, `${requiredTier} members get early access to this limited lot.`);
            }
            const requiredQuantity = line.quantity * (coffeeClub?.shipmentCount || (cafePass ? cafePassCreditCount : 1));
            if (node.availableForSale === false
                || (String(node.inventoryPolicy).toUpperCase() === "DENY"
                    && Number.isFinite(Number(node.inventoryQuantity))
                    && Number(node.inventoryQuantity) < requiredQuantity)) {
                fail("CHECKOUT_PRODUCT_UNAVAILABLE", 409, `${node.displayName || "A product"} is no longer available in that quantity.`);
            }
            return {
                ...line,
                name: String(node.displayName || "Item").trim().slice(0, 180) || "Item",
                ...orderItemOptions({ productTitle: node.product?.title, variantTitle: node.title, selectedOptions: node.selectedOptions }),
                unitPriceFils: Math.round(toFils(node.price) * customerPriceMultiplier),
                requiresShipping: node.inventoryItem?.requiresShipping !== false,
                weightGrams: weightInGrams(node.inventoryItem?.measurement?.weight),
                eligibleDrink: isEligibleDrink(node),
                pickupOnly: isPickupOnly(node),
                coffeeBag: isCoffeeBag(node),
                arabicCoffee: isArabicCoffee(node),
                coffeeFilterPack: isCoffeeFilterPack(node),
                equipmentConsumable: isEquipmentConsumable(node),
                seasonalBox: isSeasonalDiscoveryBox(node),
                dripBag: /drip[- ]bags?/i.test([node.product?.title, node.product?.productType, ...(node.product?.tags || [])].join(" "))
                    || (node.product?.collections?.nodes || []).some((collection) => String(collection?.handle || "").trim().toLowerCase() === "drip-bags")
            };
        });
        const coffeeClubPlanType = coffeeClub?.planType || "beans";
        if ((coffeeClub && !lines.every((line) => line.coffeeBag || line.coffeeFilterPack || line.seasonalBox || line.equipmentConsumable))
            || coffeeClub && coffeeClubPlanType === "drip-bags" && !lines.every((line) => line.dripBag)
            || coffeeClub && coffeeClubPlanType === "beans" && lines.some((line) => line.dripBag || line.coffeeFilterPack || line.seasonalBox || line.arabicCoffee)
            || coffeeClub && coffeeClubPlanType === "arabic-coffee" && !lines.every((line) => line.coffeeBag && line.arabicCoffee && !line.dripBag)
            || coffeeClub && coffeeClubPlanType === "office" && (!lines.every((line) => line.coffeeBag) || lines.some((line) => line.dripBag || line.coffeeFilterPack || line.seasonalBox) || lines.reduce((quantity, line) => quantity + line.quantity, 0) < 2)
            || coffeeClub && coffeeClubPlanType === "equipment" && !lines.every((line) => line.equipmentConsumable)
            || coffeeClub && coffeeClubPlanType === "drip-bags" && lines.some((line) => line.coffeeFilterPack || line.seasonalBox)
            || coffeeClub && coffeeClubPlanType === "filters" && !lines.every((line) => line.coffeeFilterPack)
            || coffeeClub && coffeeClubPlanType === "seasonal-box" && !lines.every((line) => line.seasonalBox)) {
            fail("COFFEE_CLUB_ITEMS_INVALID", 409, "Choose only products that match this prepaid plan.");
        }
        if (cafePass && (lines.length !== 1 || lines[0].quantity !== 1 || !lines[0].eligibleDrink)) {
            fail("CAFE_PASS_ITEMS_INVALID", 409, "A café pass must contain exactly one eligible ready-made drink.");
        }
        let voucher = null;
        const voucherCode = String(body?.voucherCode || "").trim().toUpperCase();
        if ((coffeeClub || cafePass) && voucherCode) {
            fail("PREPAID_VOUCHER_UNSUPPORTED", 409, "Prepaid Coffee Club and café pass purchases cannot be combined with another voucher.");
        }
        if (voucherCode) {
            try {
                voucher = await previewVoucher(voucherCode, email);
            } catch (error) {
                throw voucherError(error);
            }
        }
        const shipmentCount = coffeeClub?.shipmentCount || (cafePass ? cafePassCreditCount : 1);
        const subtotalFils = lines.reduce((total, line) => total + line.unitPriceFils * line.quantity, 0) * shipmentCount;
        const discountFils = coffeeClub
            ? Math.round(subtotalFils * coffeeClub.discountPercent / 100)
            : voucherDiscountFils(voucher, lines, subtotalFils);
        if (voucher && discountFils <= 0) {
            fail("VOUCHER_NOT_APPLICABLE", 409, "This voucher does not apply to the items in your bag. Add an eligible item or remove the voucher.");
        }
        const fulfillmentMethod = String(body?.fulfillmentMethod || body?.fulfillment?.method || "").trim().toLowerCase();
        const countryCode = String(body?.fulfillment?.countryCode || "").trim().toUpperCase();
        if (fulfillmentMethod === "delivery" && lines.some((line) => line.pickupOnly)) {
            fail("CHECKOUT_PICKUP_ONLY_ITEMS", 409, "Drinks and desserts are available for pickup only.");
        }
        if (coffeeClub && String(body?.paymentMethod || "").trim().toLowerCase() === "cashondelivery") {
            fail("COFFEE_CLUB_PREPAYMENT_REQUIRED", 409, "Coffee Club must be paid in full before its first shipment.");
        }
        if (cafePass && String(body?.paymentMethod || "").trim().toLowerCase() === "cashondelivery") {
            fail("CAFE_PASS_PREPAYMENT_REQUIRED", 409, "The café pass must be paid in full before it can be used.");
        }
        if (cafePass && fulfillmentMethod !== "pickup") {
            fail("CAFE_PASS_PICKUP_ONLY", 409, "The café pass is for café pickup only.");
        }
        if (coffeeClub && fulfillmentMethod === "delivery" && countryCode !== "BH") {
            fail("COFFEE_CLUB_BAHRAIN_ONLY", 409, "Coffee Club delivery is currently available in Bahrain only.");
        }
        const tier = String(loyaltyAccount?.tier || "Bronze");
        const freeDeliveryThreshold = Number(settings?.loyalty?.freeDeliveryThresholds?.[tier]);
        const freeDelivery = fulfillmentMethod === "delivery"
            && Number.isFinite(freeDeliveryThreshold)
            && subtotalFils / 1000 >= freeDeliveryThreshold;
        const deliveryFils = shippingFils({
            lines,
            fulfillmentMethod,
            countryCode,
            paymentMethod: body?.paymentMethod,
            settings,
            freeDelivery
        }) * shipmentCount;
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
            regionalPolicy: fulfillmentMethod === "delivery"
                ? normalizeGulfMarkets(settings?.fulfillment?.gulfMarkets)[countryCode] || null : null,
            items: lines.map((line) => ({
                name: line.name,
                ...orderItemOptions(line),
                quantity: line.quantity * shipmentCount,
                variantId: line.variantId,
                unitPrice: `BHD ${(line.unitPriceFils / 1000).toFixed(3)}`
            })),
            subtotal: subtotalFils / 1000,
            discount: discountFils / 1000,
            shipping: deliveryFils / 1000,
            total: totalFils / 1000,
            voucherCode: voucher?.code || null,
            coffeeClub,
            cafePass: cafePass ? { creditCount: cafePassCreditCount, drinkName: lines[0].name, variantId: lines[0].variantId, unitPriceFils: lines[0].unitPriceFils, suspendedCoffee: body?.suspendedCoffeePass === true, giftedCoffee } : null,
            coffeeClubItems: coffeeClub ? lines.map((line) => ({
                    coffeeName: line.name,
                    variantId: line.variantId,
                    quantity: line.quantity
                })) : null
        };
    };
}

module.exports = {
    CheckoutPricingError,
    createCheckoutPricingService,
    isEligibleDrink,
    isPickupOnly,
    isCoffeeBag,
    isArabicCoffee,
    isCoffeeFilterPack,
    isEquipmentConsumable,
    isSeasonalDiscoveryBox,
    normalizeSubmittedItems,
    normalizeCoffeeClub,
    toFils,
    voucherDiscountFils,
    weightInGrams
};
