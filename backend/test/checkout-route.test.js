const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const http = require("node:http");
const test = require("node:test");
const { URL } = require("node:url");

const createServer = require("../modules/application/create-server");

function readBody(request) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        request.on("data", (chunk) => chunks.push(chunk));
        request.on("end", () => {
            try {
                resolve(JSON.parse(Buffer.concat(chunks).toString("utf8")));
            } catch (error) {
                reject(error);
            }
        });
        request.on("error", reject);
    });
}

function sendJSON(response, statusCode, payload) {
    response.writeHead(statusCode, { "Connection": "close", "Content-Type": "application/json" });
    response.end(JSON.stringify(payload));
}

async function request(server, body) {
    await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
    const address = server.address();
    try {
        const payload = JSON.stringify(body);
        return await new Promise((resolve, reject) => {
            const outgoing = http.request({
                agent: false,
                hostname: "127.0.0.1",
                port: address.port,
                path: "/orders/checkout-started",
                method: "POST",
                headers: {
                    "Connection": "close",
                    "Content-Length": Buffer.byteLength(payload),
                    "Content-Type": "application/json"
                }
            }, (response) => {
                const chunks = [];
                response.on("data", (chunk) => chunks.push(chunk));
                response.on("end", () => {
                    try {
                        resolve({
                            status: response.statusCode,
                            body: JSON.parse(Buffer.concat(chunks).toString("utf8"))
                        });
                    } catch (error) {
                        reject(error);
                    }
                });
            });
            outgoing.on("error", reject);
            outgoing.end(payload);
        });
    } finally {
        server.closeAllConnections?.();
        await new Promise((resolve) => server.close(resolve));
    }
}

test("verified checkout creates an order after sanitizing its source", async () => {
    let savedOrder = null;
    const server = createServer({
        URL,
        applyRateLimit: () => true,
        appAttest: {
            protectedPaths: new Set(),
            verifyRequest: async () => ({ allowed: true })
        },
        benefitPathMatches: () => false,
        crypto,
        getAccountByEmail: async () => ({ email: "customer@example.com" }),
        host: "127.0.0.1",
        http,
        isBenefitBrowserReturnPath: () => false,
        logRequest: async () => {},
        normalizeEmail: (email) => String(email || "").trim().toLowerCase(),
        normalizeOrderDetails: (details) => details,
        ordersPayload: async () => [{ id: savedOrder.id }],
        parseAuthenticatedCustomer: () => ({ email: "customer@example.com" }),
        port: 0,
        readBody,
        recordTelemetry: async () => true,
        resolveCustomerSession: async () => ({ email: "customer@example.com" }),
        sendJSON,
        upsertOrderRecord: async (order) => { savedOrder = order; },
        verifyCheckoutPricing: async () => ({
            pricingVersion: 2,
            items: [{
                name: "Coffee Bag",
                quantity: 1,
                variantId: "gid://shopify/ProductVariant/101",
                unitPrice: "BHD 4.000"
            }],
            total: 4
        })
    });

    const result = await request(server, {
        email: "customer@example.com",
        title: "Pickup order",
        total: 4,
        fulfillmentMethod: "pickup",
        paymentMethod: "applePay",
        pricingVersion: 2,
        source: "  Talla iOS app  ",
        items: [{ variantId: "gid://shopify/ProductVariant/101", quantity: 1 }]
    });

    assert.equal(result.status, 200, JSON.stringify(result.body));
    assert.equal(result.body.pricingVersion, 2);
    assert.equal(savedOrder.details.source, "Talla iOS app");
    assert.equal(savedOrder.total, "BHD 4.000");
});
