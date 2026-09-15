const assert = require("node:assert/strict");
const test = require("node:test");
const { createCoffeeClubShipmentService } = require("../modules/commerce/coffee-club-shipments");

function serviceFor(store, order) {
    const normalizeCoffeeClub = (coffeeClub) => coffeeClub ? {
        ...coffeeClub,
        deliveredShipments: coffeeClub.deliveredShipments || 0,
        remainingShipments: coffeeClub.shipmentCount - (coffeeClub.deliveredShipments || 0),
        shipments: coffeeClub.shipments || []
    } : null;
    return createCoffeeClubShipmentService({
        adminOrderDetailPayload: async (value) => ({ ...value, coffeeClub: value.details.coffeeClub }),
        database: { isEnabled: () => false },
        findOrderByID: async () => order,
        normalizeEmail: (value) => value,
        normalizeOrderDetails: (details) => ({ coffeeClub: normalizeCoffeeClub(details.coffeeClub) }),
        orderRowToRecord: (row) => row,
        ordersStorePath: "orders.json",
        readJSON: () => store,
        updateCoffeeClubProgress: (coffeeClub, action, adminUser) => {
            if (action !== "deliver" || coffeeClub.deliveredShipments >= coffeeClub.shipmentCount) return null;
            const deliveredShipments = coffeeClub.deliveredShipments + 1;
            return {
                ...coffeeClub,
                deliveredShipments,
                remainingShipments: coffeeClub.shipmentCount - deliveredShipments,
                shipments: [{ number: deliveredShipments, deliveredAt: "2026-09-15T10:00:00.000Z", deliveredBy: adminUser }]
            };
        },
        writeJSON: (_path, value) => Object.assign(store, value)
    });
}

test("Coffee Club shipment service persists progress in file-backed orders", async () => {
    const order = {
        id: "club-1",
        email: "member@example.com",
        status: "Confirmed",
        details: { coffeeClub: { shipmentCount: 3, intervalWeeks: 4, discountPercent: 10 } }
    };
    const store = { orders: { [order.email]: [order] } };
    const result = await serviceFor(store, order)(order.id, "deliver", "manager");

    assert.equal(result.order.coffeeClub.deliveredShipments, 1);
    assert.equal(result.order.coffeeClub.remainingShipments, 2);
    assert.equal(store.orders[order.email][0].details.coffeeClub.shipments[0].deliveredBy, "manager");
    assert.equal(store.orders[order.email][0].status, "Confirmed");
});

test("Coffee Club shipment service rejects ordinary orders", async () => {
    const order = { id: "regular-1", email: "member@example.com", details: {} };
    const result = await serviceFor({ orders: { [order.email]: [order] } }, order)(order.id, "deliver", "manager");
    assert.equal(result.reason, "not_coffee_club");
});
