function createCoffeeClubNotificationService(dependencies) {
    const {
        adminNativePushDevices,
        allOrdersPayload,
        apnsAdminBundleID,
        googleMobileServices,
        pushDevicesForEmail,
        remotePushConfigured,
        sendRemotePushToDevice,
        updateCoffeeClubShipmentByID
    } = dependencies;

    async function sendStatusPush(email, order, status, shipmentNumber) {
        if (!remotePushConfigured() && !googleMobileServices.fcmConfigured()) {
            return { configured: false, targetCount: 0, sentCount: 0 };
        }
        const messages = {
            prepared: {
                title: "Your Coffee Club shipment is being prepared",
                body: `Shipment ${shipmentNumber} of ${order.coffeeClub?.shipmentCount || "your plan"} is being prepared by Talla.`
            },
            delivered: {
                title: "Coffee Club shipment delivered",
                body: `Shipment ${shipmentNumber} has been marked delivered. ${order.coffeeClub?.remainingShipments || 0} shipment(s) remain.`
            }
        };
        const message = messages[status];
        if (!message) return { configured: true, targetCount: 0, sentCount: 0 };
        const devices = await pushDevicesForEmail(email);
        let sentCount = 0;
        for (const device of devices) {
            const didSend = await sendRemotePushToDevice(device, {
                ...message,
                type: `coffee_club_${status}`,
                productID: order.id || null,
                url: "talla://account/orders"
            });
            if (didSend) sentCount += 1;
        }
        return { configured: true, targetCount: devices.length, sentCount };
    }

    async function sendAdminReminderPush(order) {
        if (!remotePushConfigured(apnsAdminBundleID)) {
            return { configured: false, targetCount: 0, sentCount: 0 };
        }
        const devices = await adminNativePushDevices();
        const club = order.coffeeClub || {};
        let sentCount = 0;
        for (const device of devices) {
            const didSend = await sendRemotePushToDevice(device, {
                title: "Coffee Club shipment due",
                body: `${order.title || order.id} • shipment ${club.nextShipmentNumber || "next"} of ${club.shipmentCount || "plan"} is due${club.isOverdue ? " or overdue" : " soon"}.`,
                type: "admin_coffee_club_due",
                orderID: order.id,
                url: "talla-admin://orders"
            }, {
                topic: apnsAdminBundleID,
                adminDevice: true,
                sandbox: device.environment === "sandbox"
            });
            if (didSend) sentCount += 1;
        }
        return { configured: true, targetCount: devices.length, sentCount };
    }

    let scanRunning = false;
    async function scanReminders() {
        if (scanRunning) return;
        scanRunning = true;
        try {
            const orders = await allOrdersPayload();
            const now = Date.now();
            for (const order of orders) {
                const club = order.coffeeClub;
                const nextAt = Date.parse(club?.nextShipmentAt || "");
                const lastReminderAt = Date.parse(club?.lastReminderAt || "");
                const dueWithinDay = Number.isFinite(nextAt) && nextAt <= now + 86_400_000;
                const remindedRecently = Number.isFinite(lastReminderAt) && now - lastReminderAt < 86_400_000;
                if (!club || club.status !== "active" || !dueWithinDay || remindedRecently) continue;
                const result = await sendAdminReminderPush(order);
                if (result.sentCount > 0) await updateCoffeeClubShipmentByID(order.id, "reminded", "system");
            }
        } catch (error) {
            console.error("Coffee Club reminder scan failed:", error.code || error.message || "REMINDER_SCAN_FAILED");
        } finally {
            scanRunning = false;
        }
    }

    let reminderTimer = null;
    function startReminderMonitor() {
        if (reminderTimer) return;
        void scanReminders();
        reminderTimer = setInterval(() => void scanReminders(), 15 * 60 * 1000);
        reminderTimer.unref?.();
    }

    return { sendStatusPush, startReminderMonitor, scanReminders };
}

module.exports = { createCoffeeClubNotificationService };
