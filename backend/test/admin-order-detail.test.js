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
            coffeeClub: {
                shipmentCount: 3,
                intervalWeeks: 4,
                discountPercent: 10,
                coffeeItems: [
                    { coffeeName: "Colombia", variantId: "variant-250", quantity: 2 },
                    { coffeeName: "Ethiopia", variantId: "variant-1000", quantity: 1 }
                ],
                fulfillmentOverride: { method: "pickup", countryCode: "BH", pickupSlot: "10:00–12:00" }
            }
        }
    });

    assert.equal(order.customer.fullName, "A Customer");
    assert.equal(order.fulfillment.line1, "Road 1");
    assert.equal(order.fulfillment.countryCode, "BH");
    assert.equal(order.payment.method, "Apple Pay");
    assert.equal(order.payment.status, "Captured");
    assert.equal(order.payment.reference, "PAY-123");
    assert.equal(order.coffeeClub.shipmentCount, 3);
    assert.equal(order.coffeeClub.intervalWeeks, 4);
    assert.equal(order.coffeeClub.discountPercent, 10);
    assert.equal(order.coffeeClub.deliveredShipments, 0);
    assert.equal(order.coffeeClub.remainingShipments, 3);
    assert.equal(order.coffeeClub.status, "active");
    assert.equal(order.coffeeClub.coffeeItems.length, 2);
    assert.equal(order.coffeeClub.coffeeItems[0].quantity, 2);
    assert.equal(order.coffeeClub.fulfillmentOverride.method, "pickup");
    assert.equal(order.coffeeClub.fulfillmentOverride.pickupSlot, "10:00–12:00");
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
    assert.equal(first.shipments[0].number, 1);
    assert.equal(first.shipments[0].preparedAt, "2026-09-15T10:00:00.000Z");
    assert.equal(first.shipments[0].deliveredAt, "2026-09-15T10:00:00.000Z");
    assert.equal(first.shipments[0].deliveredBy, "manager");

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
    assert.equal(undone.shipments.filter((shipment) => shipment.deliveredAt).length, 1);
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

test("Coffee Club lifecycle supports preparing, pause/resume, cancellation, preferences, and refunds", () => {
    const detailService = service();
    const plan = {
        shipmentCount: 3,
        intervalWeeks: 4,
        discountPercent: 10,
        startedAt: "2026-09-01T10:00:00.000Z"
    };
    const prepared = detailService.updateCoffeeClubProgress(plan, "prepare", "manager", "2026-09-01T12:00:00.000Z");
    assert.equal(prepared.shipments[0].preparedBy, "manager");
    assert.equal(prepared.deliveredShipments, 0);

    const paused = detailService.updateCoffeeClubProgress(prepared, "pause", "member", "2026-09-15T10:00:00.000Z");
    assert.equal(paused.status, "paused");
    const resumed = detailService.updateCoffeeClubProgress(paused, "resume", "member", "2026-09-22T10:00:00.000Z");
    assert.equal(resumed.status, "active");
    assert.equal(resumed.startedAt, "2026-09-08T10:00:00.000Z");

    const preferences = detailService.updateCoffeeClubProgress(resumed, "update_preferences", "member", undefined, {
        coffeeItems: [
            { coffeeName: "Colombia", variantId: "gid://shopify/ProductVariant/101", quantity: 2 },
            { coffeeName: "Ethiopia", variantId: "gid://shopify/ProductVariant/202", quantity: 1 }
        ],
        fulfillment: { method: "delivery", line1: "Road 10", city: "Riffa", countryCode: "BH" }
    });
    assert.equal(preferences.preference.coffeeName, "Colombia");
    assert.equal(preferences.coffeeItems.length, 2);
    assert.equal(preferences.coffeeItems[0].quantity, 2);
    assert.equal(preferences.fulfillmentOverride.city, "Riffa");
    assert.equal(preferences.changesEffectiveFromShipment, 2);

    const requested = detailService.updateCoffeeClubProgress(preferences, "request_cancel", "member", undefined, { reason: "Travelling" });
    assert.equal(requested.status, "cancel_requested");
    const cancelled = detailService.updateCoffeeClubProgress(requested, "cancel", "manager");
    assert.equal(cancelled.status, "cancelled");

    const refunded = detailService.updateCoffeeClubProgress(cancelled, "record_refund", "manager", undefined, {
        amount: 8.4,
        note: "Confirmed in gateway"
    });
    assert.equal(refunded.refundStatus, "recorded");
    assert.equal(refunded.refundAmount, 8.4);
});

test("Coffee Club can skip the next unprepared shipment", () => {
    const detailService = service();
    const updated = detailService.updateCoffeeClubProgress({
        shipmentCount: 3,
        intervalWeeks: 4,
        startedAt: "2026-01-01T00:00:00.000Z",
        status: "active"
    }, "skip_next", "customer", "2026-01-02T00:00:00.000Z");
    assert.equal(updated.nextShipmentAt, "2026-01-29T00:00:00.000Z");
    assert.equal(updated.lastSkippedAt, "2026-01-02T00:00:00.000Z");
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
