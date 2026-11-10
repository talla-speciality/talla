const assert = require("node:assert/strict");
const test = require("node:test");
const createServer = require("../modules/application/create-server");
const { applyOrderBeanReversal } = require("../modules/loyalty/order-refund");
const { refundAmountForOrder, refundSettled } = require("../modules/commerce/order-refund");

const money = {
    numericOrderTotal: (order) => order.total,
    bhdFils: (amount) => {
        const value = typeof amount === "number" ? amount.toFixed(3) : String(amount);
        return /^\d+\.\d{3}$/.test(value) ? Math.round(Number(value) * 1_000) : null;
    }
};

test("refund amount distinguishes partial and full amounts using fils", () => {
    const order = { total: 12.8 };
    assert.deepEqual(refundAmountForOrder(order, 3.2, money), {
        amountFils: 3_200, totalFils: 12_800, fullRefund: false
    });
    assert.deepEqual(refundAmountForOrder(order, 12.8, money), {
        amountFils: 12_800, totalFils: 12_800, fullRefund: true
    });
});

test("refund amount rejects zero, negative, and amounts above the order total", () => {
    for (const amount of [0, -1, 12.801, Number.NaN]) {
        assert.throws(() => refundAmountForOrder({ total: 12.8 }, amount, money),
            { message: "REFUND_AMOUNT_OUT_OF_RANGE" });
    }
    assert.throws(() => refundAmountForOrder({ total: 0 }, 1, money),
        { message: "REFUND_AMOUNT_OUT_OF_RANGE" });
});

test("refund is settled only when provider transactions succeed for the requested BHD amount", () => {
    const transaction = (status, amount) => ({
        kind: "REFUND", status, amountSet: { shopMoney: { amount, currencyCode: "BHD" } }
    });
    assert.equal(refundSettled({ transactions: { nodes: [transaction("SUCCESS", "3.200")] } }, 3_200, money.bhdFils), true);
    assert.equal(refundSettled({ transactions: { nodes: [transaction("PENDING", "3.200")] } }, 3_200, money.bhdFils), false);
    assert.equal(refundSettled({ transactions: { nodes: [transaction("SUCCESS", "2.000")] } }, 3_200, money.bhdFils), false);
    assert.equal(refundSettled({ id: "refund_1" }, 3_200, money.bhdFils), false);
});

test("full refund reverses an order award once and never creates a negative balance", () => {
    const account = {
        pointsBalance: 25,
        transactions: [{ id: "txn_shopify_123", type: "earn", points: 25 }]
    };
    const input = { awardID: "txn_shopify_123", reversalID: "txn_shopify_123:refund", points: 25, createdAt: "2026-11-07T00:00:00Z" };
    assert.deepEqual(applyOrderBeanReversal(account, input), { reversed: true, reason: "REVERSED" });
    assert.equal(account.pointsBalance, 0);
    assert.equal(account.transactions[0].type, "reversal");
    assert.deepEqual(applyOrderBeanReversal(account, input), { reversed: true, reason: "ALREADY_REVERSED" });

    const spent = { pointsBalance: 10, transactions: [{ id: "txn_shopify_456", type: "earn", points: 25 }] };
    assert.deepEqual(applyOrderBeanReversal(spent, { ...input, awardID: "txn_shopify_456", reversalID: "txn_shopify_456:refund" }),
        { reversed: false, reason: "INSUFFICIENT_BALANCE" });
    assert.equal(spent.pointsBalance, 10);
});

test("admin refund route keeps a partially refunded order open and rejects an over-refund", async () => {
    const responses = [];
    const refunds = [];
    const statusUpdates = [];
    const loyaltyReversals = [];
    let body = {};
    let order = { id: "shopify_123", email: "customer@example.com", title: "Coffee", total: 12.8, status: "Delivered" };
    let providerStatus = "SUCCESS";
    const handler = createServer({
        URL, host: "localhost", port: 0,
        http: { createServer: (callback) => callback },
        applyRateLimit: () => true,
        benefitPathMatches: () => false,
        isBenefitBrowserReturnPath: () => false,
        appAttest: { protectedPaths: new Set(), verifyRequest: async () => ({ allowed: true }) },
        database: { isEnabled: () => false },
        ensureAdminAccess: () => ({ username: "manager" }),
        permissionForAdminRequest: () => "orders:write",
        hasPermission: () => true,
        normalizeEmail: (value) => String(value || "").toLowerCase(),
        numericOrderTotal: money.numericOrderTotal,
        bhdFils: money.bhdFils,
        readBody: async () => body,
        findOrderByID: async () => order,
        executeShopifyOrderRefund: async (_orderID, amount) => {
            refunds.push(amount);
            return {
                id: `refund_${refunds.length}`,
                transactions: { nodes: [{ kind: "REFUND", status: providerStatus, amountSet: {
                    shopMoney: { amount: amount.toFixed(3), currencyCode: "BHD" }
                } }] }
            };
        },
        updateOrderStatusAndAward: async (_email, _orderID, status) => {
            statusUpdates.push(status);
            return { ...order, status };
        },
        reverseOrderBeans: async () => {
            loyaltyReversals.push(true);
            return { reversed: true, points: 25, reason: "REVERSED" };
        },
        orderPayloadWithRewardState: async (_email, value) => value,
        createAdminAuditLog: async () => {},
        sendJSON: (_response, status, payload) => responses.push({ status, payload })
    });
    const call = async (amount) => {
        body = { email: order.email, id: order.id, amount };
        await handler({ method: "POST", url: "/admin/api/orders/refund", headers: {} }, { on() {} });
        return responses.at(-1);
    };
    const partial = await call(3.2);
    assert.equal(partial.status, 200);
    assert.equal(partial.payload.fullRefund, false);
    assert.equal(partial.payload.settled, true);
    assert.equal(partial.payload.order.status, "Delivered");
    assert.deepEqual(statusUpdates, []);
    assert.deepEqual(refunds, [3.2]);

    const excessive = await call(12.801);
    assert.equal(excessive.status, 400);
    assert.deepEqual(refunds, [3.2]);

    order = { ...order, id: "shopify_456" };
    providerStatus = "PENDING";
    const pending = await call(12.8);
    assert.equal(pending.status, 200);
    assert.equal(pending.payload.fullRefund, true);
    assert.equal(pending.payload.settled, false);
    assert.equal(pending.payload.order.status, "Delivered");
    assert.deepEqual(statusUpdates, []);

    order = { ...order, id: "shopify_789" };
    providerStatus = "SUCCESS";
    const full = await call(12.8);
    assert.equal(full.status, 200);
    assert.equal(full.payload.fullRefund, true);
    assert.equal(full.payload.loyaltyReversal.reversed, true);
    assert.equal(full.payload.order.status, "Cancelled");
    assert.deepEqual(statusUpdates, ["Cancelled"]);
    assert.deepEqual(loyaltyReversals, [true]);
});
