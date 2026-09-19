const assert = require("node:assert/strict");
const test = require("node:test");
const { createCoffeeClubNotificationService } = require("../modules/commerce/coffee-club-notifications");

function service(overrides = {}) {
    return createCoffeeClubNotificationService({
        adminNativePushDevices: async () => [{ deviceToken: "admin-token", environment: "sandbox" }],
        allOrdersPayload: async () => [],
        apnsAdminBundleID: "com.talla.admin",
        googleMobileServices: { fcmConfigured: () => false },
        pushDevicesForEmail: async () => [{ deviceToken: "customer-token", platform: "ios" }],
        remotePushConfigured: () => true,
        sendRemotePushToDevice: async () => true,
        updateCoffeeClubShipmentByID: async () => ({}),
        ...overrides
    });
}

test("Coffee Club preparation and delivery notifications target customer devices", async () => {
    const notifications = [];
    const subject = service({
        sendRemotePushToDevice: async (_device, notification) => {
            notifications.push(notification);
            return true;
        }
    });
    const order = { id: "club-1", coffeeClub: { shipmentCount: 3, remainingShipments: 2 } };
    const prepared = await subject.sendStatusPush("member@example.com", order, "prepared", 1);
    const delivered = await subject.sendStatusPush("member@example.com", order, "delivered", 1);
    assert.equal(prepared.sentCount, 1);
    assert.equal(delivered.sentCount, 1);
    assert.deepEqual(notifications.map((entry) => entry.type), ["coffee_club_prepared", "coffee_club_delivered"]);
});

test("due reminder scan notifies admins once and persists the reminder timestamp", async () => {
    const updated = [];
    const subject = service({
        allOrdersPayload: async () => [{
            id: "club-due",
            title: "Talla Coffee Club",
            coffeeClub: {
                status: "active",
                shipmentCount: 3,
                nextShipmentNumber: 2,
                nextShipmentAt: new Date(Date.now() - 1_000).toISOString(),
                lastReminderAt: null,
                isOverdue: true
            }
        }],
        updateCoffeeClubShipmentByID: async (...args) => updated.push(args)
    });
    await subject.scanReminders();
    assert.deepEqual(updated, [["club-due", "reminded", "system"]]);
});
