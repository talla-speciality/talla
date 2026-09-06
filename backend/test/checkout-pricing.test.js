const assert = require("node:assert/strict");
const test = require("node:test");

const {
    CheckoutPricingError,
    createCheckoutPricingService,
    weightInGrams
} = require("../modules/commerce/checkout-pricing");

const coffeeID = "gid://shopify/ProductVariant/101";
const drinkID = "gid://shopify/ProductVariant/202";

function settings() {
    return {
        fulfillment: {
            bahrainRate: 2,
            khaleejiCashOnDeliverySurcharge: 2,
            maximumKhaleejiWeightGrams: 4000,
            khaleejiTiers: [
                { maximumWeightGrams: 500, rate: 5.5 },
                { maximumWeightGrams: 1000, rate: 6.5 }
            ]
        }
    };
}

function node(id, price, overrides = {}) {
    return {
        id,
        displayName: id === drinkID ? "Iced Talla" : "Coffee Bag",
        price,
        availableForSale: true,
        inventoryPolicy: "DENY",
        inventoryQuantity: 20,
        inventoryItem: {
            requiresShipping: true,
            measurement: { weight: { value: id === drinkID ? 250 : 0.25, unit: id === drinkID ? "GRAMS" : "KILOGRAMS" } }
        },
        product: {
            productType: id === drinkID ? "Drinks" : "Coffee Beans",
            collections: { nodes: id === drinkID ? [{ handle: "ready-made-drinks" }] : [] }
        },
        ...overrides
    };
}

function service({ nodes, voucher = null, onConsume = () => {} }) {
    return createCheckoutPricingService({
        shopifyAdminGraphQLRequest: async (query, variables) => {
            assert.match(query, /CheckoutVariants/);
            assert.deepEqual(variables.ids, nodes.map((entry) => entry.id));
            return { nodes };
        },
        appSettings: settings,
        previewVoucher: async () => voucher,
        consumeVoucher: async (code) => {
            onConsume(code);
            return voucher;
        }
    });
}

function body(items, total, overrides = {}) {
    return {
        pricingVersion: 2,
        items,
        total,
        fulfillmentMethod: "delivery",
        fulfillment: { countryCode: "BH" },
        paymentMethod: "card",
        ...overrides
    };
}

test("verified checkout uses Shopify prices and backend Bahrain delivery", async () => {
    const verify = service({ nodes: [node(coffeeID, "4.500")] });
    const result = await verify(body([{ variantId: coffeeID, quantity: 2 }], 11), "customer@example.com");

    assert.equal(result.subtotal, 9);
    assert.equal(result.shipping, 2);
    assert.equal(result.total, 11);
    assert.deepEqual(result.items, [{
        name: "Coffee Bag",
        quantity: 2,
        variantId: coffeeID,
        unitPrice: "BHD 4.500"
    }]);
});

test("tampered or stale client totals are rejected before payment", async () => {
    const verify = service({ nodes: [node(coffeeID, "4.500")] });
    await assert.rejects(
        verify(body([{ variantId: coffeeID, quantity: 2 }], 0.1), "customer@example.com"),
        (error) => error instanceof CheckoutPricingError
            && error.code === "CHECKOUT_TOTAL_CHANGED"
            && error.statusCode === 409
    );
});

test("a free-drink voucher discounts one eligible drink and is consumed after validation", async () => {
    let consumedCode = null;
    const voucher = { code: "FREE-DRINK", reward: "Free Drink" };
    const verify = service({
        nodes: [node(coffeeID, "4.500"), node(drinkID, "2.200")],
        voucher,
        onConsume: (code) => { consumedCode = code; }
    });
    const result = await verify(body([
        { variantId: coffeeID, quantity: 1 },
        { variantId: drinkID, quantity: 2 }
    ], 8.7, { voucherCode: voucher.code }), "customer@example.com");

    assert.equal(result.subtotal, 8.9);
    assert.equal(result.discount, 2.2);
    assert.equal(result.shipping, 2);
    assert.equal(result.total, 8.7);
    assert.equal(consumedCode, voucher.code);
});

test("GCC delivery uses verified Shopify weights and the configured tier", async () => {
    const verify = service({ nodes: [node(coffeeID, "4.500")] });
    const result = await verify(body(
        [{ variantId: coffeeID, quantity: 3 }],
        20,
        { fulfillment: { countryCode: "SA" } }
    ), "customer@example.com");

    assert.equal(result.subtotal, 13.5);
    assert.equal(result.shipping, 6.5);
    assert.equal(result.total, 20);
});

test("unavailable inventory is rejected", async () => {
    const verify = service({
        nodes: [node(coffeeID, "4.500", { inventoryQuantity: 1 })]
    });
    await assert.rejects(
        verify(body([{ variantId: coffeeID, quantity: 2 }], 11), "customer@example.com"),
        (error) => error.code === "CHECKOUT_PRODUCT_UNAVAILABLE" && error.statusCode === 409
    );
});

test("Shopify weight units are normalized to grams", () => {
    assert.equal(weightInGrams({ value: 0.5, unit: "KILOGRAMS" }), 500);
    assert.equal(Math.round(weightInGrams({ value: 1, unit: "POUNDS" })), 454);
    assert.equal(weightInGrams(null), null);
});
