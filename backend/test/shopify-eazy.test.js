const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

const dataDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "talla-shopify-eazy-"));
process.env.DATA_DIRECTORY = dataDirectory;
process.env.SHOPIFY_ADMIN_SHOP_DOMAIN = "shop.test";
process.env.SHOPIFY_ADMIN_ACCESS_TOKEN = "shopify-admin-secret";
process.env.EAZY_APP_ID = "eazy-test-app";
process.env.EAZY_SECRET_KEY = "eazy-test-secret";
process.env.EAZY_API_BASE_URL = "https://eazy.test";
delete process.env.DATABASE_URL;

const eazyPay = require("../modules/commerce/eazypay");
const {
    confirmShopifyEazyPayment,
    ensureShopifyEazyInvoice,
    findShopifyEazyPayment,
    prepareShopifyEazyOrder,
    publicShopifyEazyPayment,
    verifyEazyTransactionForShopifyPayment
} = require("../server");

const paymentID = "TL-A84F90C21399";
let createInvoiceCalls = 0;
let markPaidCalls = 0;

function shopifyOrder(overrides = {}) {
    return {
        id: 12345,
        admin_graphql_api_id: "gid://shopify/Order/12345",
        name: "#1842",
        email: "customer@example.com",
        total_price: "12.800",
        currency: "BHD",
        financial_status: "pending",
        gateway: "Pay with EazyPay",
        payment_gateway_names: ["Pay with EazyPay"],
        note_attributes: [{ name: "talla_payment_id", value: paymentID }],
        line_items: [{ name: "Coffee", quantity: 1 }],
        ...overrides
    };
}

test.before(() => {
    fs.writeFileSync(path.join(dataDirectory, "accounts.json"), JSON.stringify({
        accounts: {
            "customer@example.com": {
                id: "acct_test",
                email: "customer@example.com",
                firstName: "Test",
                lastName: "Customer",
                createdAt: "2026-08-08T09:00:00.000Z"
            }
        }
    }));
    global.fetch = async (url, options = {}) => {
        if (String(url).endsWith("/merchant/checkout/createInvoice")) {
            createInvoiceCalls += 1;
            return new Response(JSON.stringify({ data: {
                globalTransactionsId: "global_shopify_123",
                paymentUrl: "https://checkout.eazy.test/pay/123"
            } }), { status: 200 });
        }
        if (String(url).endsWith("/merchant/checkout/query")) {
            return new Response(JSON.stringify({ data: {
                globalTransactionsId: "global_shopify_123",
                transactionsId: "paid_shopify_456",
                invoiceId: paymentID,
                currency: "BHD",
                amount: "12.800",
                isPaid: 1,
                paidOn: "2026-08-08T10:00:00.000Z",
                paymentMethod: "CREDITCARD",
                errorCode: "0"
            } }), { status: 200 });
        }
        if (String(url).includes("/graphql.json")) {
            assert.equal(options.headers["X-Shopify-Access-Token"], "shopify-admin-secret");
            markPaidCalls += 1;
            return new Response(JSON.stringify({ data: { orderMarkAsPaid: {
                order: { id: "gid://shopify/Order/12345", name: "#1842", displayFinancialStatus: "PAID" },
                userErrors: []
            } } }), { status: 200 });
        }
        throw new Error(`Unexpected fetch URL: ${url}`);
    };
});

test("EazyPay HMAC formulas remain compatible with the Checkout API", () => {
    assert.equal(
        eazyPay.createInvoiceSecretHash("2026-08-08T10:00:00.000Z", "BHD", "12.800", "eazy-test-app", "eazy-test-secret"),
        crypto.createHmac("sha256", "eazy-test-secret").update("2026-08-08T10:00:00.000ZBHD12.800eazy-test-app").digest("hex")
    );
    assert.equal(
        eazyPay.createQuerySecretHash("1786183200000", "eazy-test-app", "eazy-test-secret"),
        crypto.createHmac("sha256", "eazy-test-secret").update("1786183200000eazy-test-app").digest("hex")
    );
});

test("duplicate Shopify webhooks and invoice attempts stay idempotent", async () => {
    const first = await prepareShopifyEazyOrder(shopifyOrder());
    const duplicate = await prepareShopifyEazyOrder(shopifyOrder());
    assert.equal(first.tallaPaymentId, paymentID);
    assert.equal(duplicate.tallaPaymentId, paymentID);

    const invoice = await ensureShopifyEazyInvoice(paymentID);
    const duplicateInvoice = await ensureShopifyEazyInvoice(paymentID);
    assert.equal(invoice.eazyPaymentUrl, "https://checkout.eazy.test/pay/123");
    assert.equal(duplicateInvoice.eazyGlobalTransactionId, "global_shopify_123");
    assert.equal(createInvoiceCalls, 1);
});

test("paid status requires Eazy query verification and Shopify mark-as-paid", async () => {
    const paid = await confirmShopifyEazyPayment(paymentID);
    assert.equal(paid.status, "PAID");
    assert.equal(paid.eazyTransactionId, "paid_shopify_456");
    assert.equal(markPaidCalls, 1);

    const duplicate = await confirmShopifyEazyPayment(paymentID);
    assert.equal(duplicate.status, "PAID");
    assert.equal(markPaidCalls, 1);

    const publicPayload = publicShopifyEazyPayment(await findShopifyEazyPayment(paymentID));
    assert.equal(publicPayload.paid, true);
    assert.equal(publicPayload.shopifyOrderName, "#1842");
    assert.doesNotMatch(JSON.stringify(publicPayload), /eazy-test-secret|shopify-admin-secret/);
});

test("amount and currency mismatches are rejected before Shopify is marked paid", () => {
    const payment = {
        tallaPaymentId: paymentID,
        amount: "12.800",
        currency: "BHD",
        eazyGlobalTransactionId: "global_shopify_123"
    };
    assert.throws(
        () => verifyEazyTransactionForShopifyPayment(eazyPay.normalizeTransaction({
            globalTransactionsId: "global_shopify_123", transactionsId: "paid_1", invoiceId: paymentID,
            amount: "12.700", currency: "BHD", isPaid: 1
        }), payment),
        (error) => error.code === "EAZY_AMOUNT_MISMATCH"
    );
    assert.throws(
        () => verifyEazyTransactionForShopifyPayment(eazyPay.normalizeTransaction({
            globalTransactionsId: "global_shopify_123", transactionsId: "paid_1", invoiceId: paymentID,
            amount: "12.800", currency: "USD", isPaid: 1
        }), payment),
        (error) => error.code === "EAZY_CURRENCY_MISMATCH"
    );
});

test("non-Eazy Shopify orders and malformed Eazy notifications are ignored", async () => {
    assert.equal(await prepareShopifyEazyOrder(shopifyOrder({ gateway: "Cash on Delivery", payment_gateway_names: ["Cash on Delivery"] })), null);
    assert.equal(eazyPay.extractGlobalTransactionID({ status: "paid" }), "");
});
