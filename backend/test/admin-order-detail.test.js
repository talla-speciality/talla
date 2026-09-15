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
            payment: { method: "applePay" },
            coffeeClub: { shipmentCount: 3, intervalWeeks: 4, discountPercent: 10 }
        }
    });

    assert.equal(order.customer.fullName, "A Customer");
    assert.equal(order.fulfillment.line1, "Road 1");
    assert.equal(order.fulfillment.countryCode, "BH");
    assert.equal(order.payment.method, "Apple Pay");
    assert.equal(order.payment.status, "Captured");
    assert.equal(order.payment.reference, "PAY-123");
    assert.deepEqual(order.coffeeClub, {
        shipmentCount: 3,
        intervalWeeks: 4,
        discountPercent: 10,
        deliveredShipments: 0,
        remainingShipments: 3,
        shipments: []
    });
    assert.equal(order.status, "Confirmed");
});

test("Coffee Club progress records deliveries, remaining shipments, and supports undo", () => {
    const detailService = service();
    const first = detailService.updateCoffeeClubProgress(
        { shipmentCount: 3, intervalWeeks: 4, discountPercent: 10 },
        "deliver",
        "manager",
        "2026-09-15T10:00:00.000Z"
    );
    assert.equal(first.deliveredShipments, 1);
    assert.equal(first.remainingShipments, 2);
    assert.deepEqual(first.shipments, [{
        number: 1,
        deliveredAt: "2026-09-15T10:00:00.000Z",
        deliveredBy: "manager"
    }]);

    const second = detailService.updateCoffeeClubProgress(
        first,
        "deliver",
        "manager",
        "2026-10-13T10:00:00.000Z"
    );
    assert.equal(second.deliveredShipments, 2);
    assert.equal(second.remainingShipments, 1);

    const undone = detailService.updateCoffeeClubProgress(second, "undo", "manager");
    assert.equal(undone.deliveredShipments, 1);
    assert.equal(undone.remainingShipments, 2);
    assert.equal(undone.shipments.length, 1);
});

test("Coffee Club progress refuses delivery beyond plan bounds", () => {
    const detailService = service();
    const complete = {
        shipmentCount: 2,
        intervalWeeks: 4,
        discountPercent: 10,
        deliveredShipments: 2,
        shipments: []
    };
    assert.equal(detailService.updateCoffeeClubProgress(complete, "deliver", "manager"), null);
    assert.equal(detailService.updateCoffeeClubProgress({ ...complete, deliveredShipments: 0 }, "undo", "manager"), null);
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
