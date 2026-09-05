const assert = require("node:assert/strict");
const test = require("node:test");
const { createAdminOrderDetailService } = require("../modules/commerce/admin-order-detail");

function service(overrides = {}) {
    return createAdminOrderDetailService({
        addressesFor: async () => [],
        completedOrderStatuses: () => new Set(["Completed", "Fulfilled", "Delivered"]),
        database: { isEnabled: () => false },
        findBenefitPaymentByOrderID: async () => null,
        findCardPayment: async () => null,
        getAccountByEmail: async () => null,
        normalizeCountryCode: (value) => String(value || "").toUpperCase(),
        numericOrderTotal: () => 12.8,
        orderCurrency: () => "BHD",
        orderPayloadWithRewardState: async (_email, order) => order,
        readJSON: () => ({ payments: {} }),
        shopifyEazyPaymentRowToRecord: (row) => row,
        shopifyEazyPaymentsStorePath: "unused",
        ...overrides
    });
}

test("admin order detail includes customer, fulfilment, and card payment facts", async () => {
    const detailService = service({
        findCardPayment: async () => ({
            paymentMethod: "APPLE_PAY",
            status: "Captured",
            amount: "12.800",
            currency: "BHD",
            purchaseTransactionID: "PAY-123",
            completedAt: "2026-09-05T10:00:00.000Z"
        })
    });
    const order = await detailService.adminOrderDetailPayload({
        id: "checkout_1",
        email: "customer@example.com",
        title: "Delivery order",
        status: "Confirmed",
        details: {
            source: "Talla iOS app",
            customer: { fullName: "A Customer", phone: "+97312345678" },
            fulfillment: { method: "delivery", line1: "Road 1", city: "Manama", countryCode: "bh" },
            payment: { method: "applePay" }
        }
    });

    assert.equal(order.customer.fullName, "A Customer");
    assert.equal(order.fulfillment.line1, "Road 1");
    assert.equal(order.fulfillment.countryCode, "BH");
    assert.equal(order.payment.method, "Apple Pay");
    assert.equal(order.payment.status, "Captured");
    assert.equal(order.payment.reference, "PAY-123");
    assert.equal(order.status, "Confirmed");
});

test("Shopify order snapshots retain operational customer and delivery data", () => {
    const details = service().shopifyOrderDetails({
        customer: { first_name: "Sara", last_name: "Ali", phone: "+97311111111" },
        shipping_address: { address1: "Road 20", city: "Riffa", country_code: "BH" },
        shipping_lines: [{}],
        payment_gateway_names: ["Cash on Delivery"],
        note: "Call on arrival"
    });

    assert.equal(details.customer.fullName, "Sara Ali");
    assert.equal(details.fulfillment.method, "delivery");
    assert.equal(details.fulfillment.notes, "Call on arrival");
    assert.equal(details.payment.method, "Cash on Delivery");
});
