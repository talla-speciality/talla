const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const dataDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-shopify-order-export-"));
process.env.DATA_DIRECTORY = dataDirectory;
process.env.SHOPIFY_ADMIN_SHOP_DOMAIN = "shop.test";
process.env.SHOPIFY_ADMIN_ACCESS_TOKEN = "shopify-admin-secret";
delete process.env.DATABASE_URL;

const {
    exportCompletedOrderToShopify,
    findShopifyOrderExport,
    shopifyOrderCreateInput
} = require("../server");

const completedOrderID = "checkout_1786200000000";
const pendingOrderID = "checkout_1786200000001";
let orderCreateCalls = 0;
let lastCreateVariables = null;

test.before(() => {
    fs.writeFileSync(path.join(dataDirectory, "addresses.json"), JSON.stringify({
        addresses: {
            "customer@example.com": [
                { id: "address_1", phone: "+973 3900 1234", isPreferred: true }
            ]
        }
    }));
    fs.writeFileSync(path.join(dataDirectory, "orders.json"), JSON.stringify({
        orders: {
            "customer@example.com": [
                {
                    id: completedOrderID,
                    title: "Talla app checkout",
                    total: "BHD 12.800",
                    status: "Completed",
                    items: [
                        { name: "Coffee", quantity: 2, variantId: "gid://shopify/ProductVariant/111" }
                    ],
                    createdAt: "2026-08-08T10:00:00.000Z"
                },
                {
                    id: pendingOrderID,
                    title: "Talla app checkout",
                    total: "BHD 6.400",
                    status: "Pending",
                    items: [
                        { name: "Coffee", quantity: 1, variantId: "gid://shopify/ProductVariant/111" }
                    ],
                    createdAt: "2026-08-08T10:01:00.000Z"
                }
            ]
        }
    }));

    global.fetch = async (url, options = {}) => {
        assert.match(String(url), /shop\.test\/admin\/api\/.*\/graphql\.json$/);
        assert.equal(options.headers["X-Shopify-Access-Token"], "shopify-admin-secret");
        const request = JSON.parse(options.body);
        if (request.query.includes("TallaExportedOrder")) {
            return new Response(JSON.stringify({ data: { orders: { nodes: [] } } }), { status: 200 });
        }
        if (request.query.includes("CreateTallaAppOrder")) {
            orderCreateCalls += 1;
            lastCreateVariables = request.variables;
            return new Response(JSON.stringify({ data: { orderCreate: {
                order: { id: "gid://shopify/Order/9001", name: "#9001", displayFinancialStatus: "PENDING" },
                userErrors: []
            } } }), { status: 200 });
        }
        throw new Error("Unexpected Shopify GraphQL operation");
    };
});

test("completed app orders are exported once without payment-provider details", async () => {
    const first = await exportCompletedOrderToShopify(completedOrderID);
    const duplicate = await exportCompletedOrderToShopify(completedOrderID);

    assert.equal(first.status, "Synced");
    assert.equal(duplicate.shopifyOrderGID, "gid://shopify/Order/9001");
    assert.equal(orderCreateCalls, 1);
    assert.deepEqual(lastCreateVariables.options, { inventoryBehaviour: "BYPASS", sendReceipt: false });
    assert.equal(lastCreateVariables.order.financialStatus, "PENDING");
    assert.equal(lastCreateVariables.order.currency, "BHD");
    assert.equal(lastCreateVariables.order.phone, "+97339001234");
    assert.deepEqual(lastCreateVariables.order.lineItems, [
        { variantId: "gid://shopify/ProductVariant/111", quantity: 2 }
    ]);
    assert.doesNotMatch(JSON.stringify(lastCreateVariables), /eazy|mpgs|benefit|gateway|transaction|secret|password/i);
    assert.equal((await findShopifyOrderExport(completedOrderID)).status, "Synced");
});

test("pending and Shopify-originated orders are not exported", async () => {
    assert.equal(await exportCompletedOrderToShopify(pendingOrderID), null);
    assert.equal(await exportCompletedOrderToShopify("shopify_123"), null);
    assert.equal(orderCreateCalls, 1);
});

test("historical app orders without variant identifiers retain their backend total", () => {
    const input = shopifyOrderCreateInput({
        id: "checkout_historical",
        email: "customer@example.com",
        status: "Completed",
        total: "BHD 6.400",
        items: [{ name: "Coffee", quantity: 2 }]
    });

    assert.deepEqual(input.lineItems, [{
        title: "Talla app order — Coffee ×2",
        quantity: 1,
        requiresShipping: true,
        taxable: false,
        priceSet: {
            shopMoney: { amount: "6.400", currencyCode: "BHD" }
        }
    }]);
    assert.match(input.note, /Historical item details: Coffee ×2/);
});

test("invalid customer phone never blocks Shopify order creation", () => {
    const input = shopifyOrderCreateInput({
        id: "checkout_phone_fallback",
        email: "customer@example.com",
        status: "Completed",
        items: [{ name: "Coffee", quantity: 1, variantId: "gid://shopify/ProductVariant/111" }]
    }, "not-a-phone");

    assert.equal(input.phone, undefined);
});
