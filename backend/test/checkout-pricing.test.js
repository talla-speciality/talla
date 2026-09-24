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

function service({ nodes, voucher = null, onConsume = () => {}, configuredSettings = settings() }) {
    return createCheckoutPricingService({
        shopifyAdminGraphQLRequest: async (query, variables) => {
            assert.match(query, /CheckoutVariants/);
            assert.deepEqual(variables.ids, nodes.map((entry) => entry.id));
            return { nodes };
        },
        appSettings: () => configuredSettings,
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

test("prepaid Coffee Club prices three shipments with a 10 percent saving and paid delivery each time", async () => {
    const verify = service({ nodes: [node(coffeeID, "4.000")] });
    const result = await verify(body(
        [{ variantId: coffeeID, quantity: 1 }],
        16.8,
        { coffeeClub: { shipmentCount: 3, intervalWeeks: 4, termsAccepted: true } }
    ), "customer@example.com");

    assert.equal(result.subtotal, 12);
    assert.equal(result.discount, 1.2);
    assert.equal(result.shipping, 6);
    assert.equal(result.total, 16.8);
    assert.deepEqual(result.coffeeClub, { shipmentCount: 3, intervalWeeks: 4, discountPercent: 10 });
    assert.equal(result.items[0].quantity, 3);
});

test("Coffee Club accepts coffee products identified by the catalog title or tags", async () => {
    const titleIdentifiedCoffee = node(coffeeID, "4.000", {
        displayName: "Ethiopia Hambela",
        product: {
            title: "Ethiopia Hambela",
            productType: "Coffee",
            tags: ["single-origin"],
            collections: { nodes: [] }
        }
    });
    const verify = service({ nodes: [titleIdentifiedCoffee] });
    const result = await verify(body(
        [{ variantId: coffeeID, quantity: 1 }],
        16.8,
        { coffeeClub: { shipmentCount: 3, intervalWeeks: 4, termsAccepted: true } }
    ), "customer@example.com");

    assert.equal(result.coffeeClub.shipmentCount, 3);
});

test("Coffee Club accepts coffee capsules while excluding coffee equipment", async () => {
    const capsules = node(coffeeID, "4.000", {
        displayName: "Coffee Capsules",
        product: {
            title: "Coffee Capsules",
            productType: "Coffee capsules",
            collections: { nodes: [{ handle: "coffee-capsules" }] }
        }
    });
    const verify = service({ nodes: [capsules] });
    const result = await verify(body(
        [{ variantId: coffeeID, quantity: 1 }],
        16.8,
        { coffeeClub: { shipmentCount: 3, intervalWeeks: 4, termsAccepted: true } }
    ), "customer@example.com");

    assert.equal(result.coffeeClub.shipmentCount, 3);

    const equipment = node(coffeeID, "4.000", {
        displayName: "Coffee Scale",
        product: {
            title: "Coffee Scale",
            productType: "Coffee Equipment",
            collections: { nodes: [{ handle: "coffee-equipment" }] }
        }
    });
    await assert.rejects(
        service({ nodes: [equipment] })(body(
            [{ variantId: coffeeID, quantity: 1 }],
            16.8,
            { coffeeClub: { shipmentCount: 3, intervalWeeks: 4, termsAccepted: true } }
        ), "customer@example.com"),
        (error) => error.code === "COFFEE_CLUB_ITEMS_INVALID"
    );
});

test("Coffee Club checkout requires explicit prepaid terms acceptance", async () => {
    const verify = service({ nodes: [node(coffeeID, "4.000")] });
    await assert.rejects(
        verify(body(
            [{ variantId: coffeeID, quantity: 1 }],
            16.8,
            { coffeeClub: { shipmentCount: 3, intervalWeeks: 4 } }
        ), "customer@example.com"),
        (error) => error.code === "COFFEE_CLUB_TERMS_REQUIRED"
    );
});

test("Coffee Club uses admin-controlled plan values and can be switched off", async () => {
    const configuredSettings = {
        ...settings(),
        coffeeClub: { enabled: true, shipmentCount: 4, intervalWeeks: 3, discountPercent: 15 }
    };
    const result = await service({ nodes: [node(coffeeID, "4.000")], configuredSettings })(body(
        [{ variantId: coffeeID, quantity: 1 }],
        21.6,
        { coffeeClub: { shipmentCount: 4, intervalWeeks: 3, termsAccepted: true } }
    ), "customer@example.com");
    assert.deepEqual(result.coffeeClub, { shipmentCount: 4, intervalWeeks: 3, discountPercent: 15 });
    assert.equal(result.shipping, 8);
    assert.equal(result.total, 21.6);

    configuredSettings.coffeeClub.enabled = false;
    await assert.rejects(
        service({ nodes: [node(coffeeID, "4.000")], configuredSettings })(body(
            [{ variantId: coffeeID, quantity: 1 }],
            21.6,
            { coffeeClub: { shipmentCount: 4, intervalWeeks: 3, termsAccepted: true } }
        ), "customer@example.com"),
        (error) => error.code === "COFFEE_CLUB_UNAVAILABLE"
    );
});

test("Coffee Club rejects non-coffee products, vouchers, cash on delivery, and insufficient inventory", async () => {
    const coffee = node(coffeeID, "4.000");
    const drink = node(drinkID, "2.200");
    const coffeeClub = { shipmentCount: 3, intervalWeeks: 4, termsAccepted: true };

    await assert.rejects(
        service({ nodes: [drink] })(body([{ variantId: drinkID, quantity: 1 }], 11.94, { coffeeClub }), "customer@example.com"),
        (error) => error.code === "COFFEE_CLUB_ITEMS_INVALID"
    );
    await assert.rejects(
        service({ nodes: [coffee], voucher: { code: "BAG", reward: "Bag Discount" } })(body(
            [{ variantId: coffeeID, quantity: 1 }],
            16.8,
            { coffeeClub, voucherCode: "BAG" }
        ), "customer@example.com"),
        (error) => error.code === "COFFEE_CLUB_VOUCHER_UNSUPPORTED"
    );
    await assert.rejects(
        service({ nodes: [coffee] })(body(
            [{ variantId: coffeeID, quantity: 1 }],
            16.8,
            { coffeeClub, paymentMethod: "cashOnDelivery" }
        ), "customer@example.com"),
        (error) => error.code === "COFFEE_CLUB_PREPAYMENT_REQUIRED"
    );
    await assert.rejects(
        service({ nodes: [node(coffeeID, "4.000", { inventoryQuantity: 2 })] })(body(
            [{ variantId: coffeeID, quantity: 1 }],
            16.8,
            { coffeeClub }
        ), "customer@example.com"),
        (error) => error.code === "CHECKOUT_PRODUCT_UNAVAILABLE"
    );
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
    ], 6.7, { voucherCode: voucher.code, fulfillmentMethod: "pickup", fulfillment: {} }), "customer@example.com");

    assert.equal(result.subtotal, 8.9);
    assert.equal(result.discount, 2.2);
    assert.equal(result.shipping, 0);
    assert.equal(result.total, 6.7);
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

test("checkout records authoritative purchased options instead of client-supplied labels", async () => {
    const verify = service({ nodes: [node(coffeeID, "4.500", {
        title: "250g / Whole Bean",
        selectedOptions: [{ name: "Weight", value: "250g" }, { name: "Grind", value: "Whole Bean" }],
        product: { title: "Ethiopia Guji", productType: "Coffee Beans" }
    })] });
    const result = await verify(body([{ variantId: coffeeID, quantity: 1, variantTitle: "Fake size" }], 6.5), "customer@example.com");
    assert.equal(result.items[0].productTitle, "Ethiopia Guji");
    assert.equal(result.items[0].variantTitle, "250g / Whole Bean");
    assert.deepEqual(result.items[0].selectedOptions, [{ name: "Weight", value: "250g" }, { name: "Grind", value: "Whole Bean" }]);
    assert.equal(result.items[0].unitPrice, "BHD 4.500");
});


test("ineligible free-drink vouchers are rejected without consuming the reward", async () => {
    let consumed = false;
    const verify = service({
        nodes: [node(coffeeID, "4.500")],
        voucher: { code: "FREE-DRINK", reward: "Free Drink" },
        onConsume: () => { consumed = true; }
    });
    await assert.rejects(
        verify(body([{ variantId: coffeeID, quantity: 1 }], 6.5, { voucherCode: "FREE-DRINK" }), "customer@example.com"),
        (error) => error.code === "VOUCHER_NOT_APPLICABLE" && error.statusCode === 409
    );
    assert.equal(consumed, false);
});
