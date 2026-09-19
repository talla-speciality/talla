function createCoffeeClubShipmentService(dependencies) {
    const {
        adminOrderDetailPayload,
        database,
        findOrderByID,
        normalizeEmail,
        normalizeOrderDetails,
        orderRowToRecord,
        ordersStorePath,
        readJSON,
        updateCoffeeClubProgress,
        writeJSON
    } = dependencies;

    return async function updateCoffeeClubShipmentByID(orderID, action, actor, changes = {}, expectedEmail = "") {
        const order = await findOrderByID(orderID);
        if (!order) return { reason: "not_found" };
        if (expectedEmail && normalizeEmail(order.email) !== normalizeEmail(expectedEmail)) {
            return { reason: "not_found" };
        }
        const currentCoffeeClub = normalizeOrderDetails(order.details).coffeeClub;
        if (!currentCoffeeClub) return { reason: "not_coffee_club" };
        const coffeeClub = updateCoffeeClubProgress(currentCoffeeClub, action, actor, new Date().toISOString(), changes);
        if (!coffeeClub) {
            if (action === "deliver" || action === "prepare") return { reason: "all_delivered" };
            if (action === "undo") return { reason: "none_delivered" };
            return { reason: "invalid_transition" };
        }

        const details = {
            ...(order.details && typeof order.details === "object" ? order.details : {}),
            coffeeClub
        };
        let updatedOrder;
        if (database.isEnabled()) {
            const result = await database.query(
                `UPDATE orders
                 SET details = $2::jsonb, updated_at = NOW()
                 WHERE id = $1
                 RETURNING id, email, title, total, status, items, details, created_at, updated_at`,
                [order.id, JSON.stringify(details)]
            );
            updatedOrder = result.rowCount > 0 ? {
                ...orderRowToRecord(result.rows[0]),
                email: normalizeEmail(result.rows[0].email)
            } : null;
        } else {
            const store = readJSON(ordersStorePath);
            const orders = store.orders[order.email] || [];
            const index = orders.findIndex((entry) => entry.id === order.id);
            if (index >= 0) {
                orders[index] = { ...orders[index], details, updatedAt: new Date().toISOString() };
                store.orders[order.email] = orders;
                writeJSON(ordersStorePath, store);
                updatedOrder = { ...orders[index], email: order.email };
            }
        }
        return updatedOrder ? { order: await adminOrderDetailPayload(updatedOrder) } : { reason: "not_found" };
    };
}

module.exports = { createCoffeeClubShipmentService };
