const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const test = require("node:test");
const createServer = require("../modules/application/create-server");
const { giftTokenForOrder, validGiftToken, giftPassFields } = require("../modules/commerce/social-coffee-gifts");

function handlerWithStore(overrides = {}) {
    let store = { customers: {}, groups: {} };
    const handler = createServer({
        URL,
        host: "127.0.0.1",
        port: 0,
        http: { createServer: (callback) => callback },
        crypto,
        customerTokenSecret: "social-coffee-test-secret",
        socialCoffeeStorePath: "unused-in-memory-store",
        applyRateLimit: () => true,
        appAttest: { protectedPaths: new Set(), verifyRequest: async () => ({ allowed: true }) },
        benefitPathMatches: () => false,
        isBenefitBrowserReturnPath: () => false,
        logRequest: async () => {},
        parseAuthenticatedCustomer: (request, response) => {
            const email = request.headers["x-test-customer"];
            if (email) return { email };
            response.status = 401;
            response.body = { error: "Sign in required" };
            return null;
        },
        resolveCustomerSession: async (session) => ({ email: session.email }),
        readBody: async (request) => request.testBody,
        readJSON: () => structuredClone(store),
        writeJSON: (_path, value) => { store = structuredClone(value); },
        sendJSON: (response, status, value) => {
            response.status = status;
            response.body = value;
        },
        ...overrides
    });
    return handler;
}

async function send(handler, method, path, body, email) {
    const request = { method, url: path, headers: email ? { "x-test-customer": email } : {}, testBody: body };
    const response = { on() {}, setHeader() {} };
    await handler(request, response);
    return { status: response.status, body: response.body };
}

test("social coffee keeps private notes private and publishes only opted-in notes", async () => {
    const handler = handlerWithStore();
    const profile = {
        displayName: "A Talla guest",
        role: "Barista",
        wishList: ["product:talla-coffee-beans", "Custom brew kit"],
        wishListEnabled: true,
        followedPeople: [{ name: "A friend", role: "Friend", profileID: "not-a-profile-id" }],
        tastingNote: "Date sweetness and cocoa",
        tastingNoteVisibility: "Private"
    };
    const saved = await send(handler, "PUT", "/social-coffee/profile", profile, "guest@example.com");
    assert.equal(saved.status, 200);
    assert.deepEqual(saved.body.state.wishList, profile.wishList);
    assert.equal(saved.body.state.followedPeople[0].profileID, null);

    const anonymousPrivateFeed = await send(handler, "GET", "/social-coffee/notes");
    assert.equal(anonymousPrivateFeed.status, 200);
    assert.deepEqual(anonymousPrivateFeed.body.notes, []);
    const anonymousProfile = await send(handler, "GET", "/social-coffee/profile");
    assert.equal(anonymousProfile.status, 401);

    profile.tastingNoteVisibility = "Public";
    assert.equal((await send(handler, "PUT", "/social-coffee/profile", profile, "guest@example.com")).status, 200);
    const publicFeed = await send(handler, "GET", "/social-coffee/notes");
    assert.equal(publicFeed.body.notes.length, 1);
    assert.equal(publicFeed.body.notes[0].note, profile.tastingNote);
    assert.equal(publicFeed.body.notes[0].role, "Barista");
    assert.match(publicFeed.body.notes[0].profileID, /^[a-f0-9]{24}$/);
    assert.equal(JSON.stringify(publicFeed.body).includes("guest@example.com"), false);
    assert.equal(JSON.stringify(publicFeed.body).includes("wishList"), false);
});

test("gift status requires a share token and never exposes customer details", async () => {
    const orderID = "checkout_1234";
    const secret = "social-coffee-test-secret";
    const token = giftTokenForOrder(orderID, secret);
    assert.equal(validGiftToken(orderID, token, secret), true);
    assert.equal(validGiftToken(orderID, "0".repeat(64), secret), false);
    const orderFields = giftPassFields({ id: orderID, details: { customer: { fullName: "Private" }, cafePass: { giftedCoffee: true } } }, { giftedCoffee: true, status: "active" }, secret);
    assert.equal(orderFields.details.cafePass.giftToken, token);
    assert.equal(orderFields.cafePass.giftToken, token);
    assert.equal(orderFields.details.customer.fullName, "Private");
    let order = {
        id: orderID,
        email: "private@example.com",
        status: "Pending",
        details: { cafePass: {
            giftedCoffee: true,
            suspendedCoffee: true,
            creditCount: 1,
            redeemedCredits: 0,
            status: "pending_payment",
            drinkName: "Iced Karak",
            expiresAt: null
        } }
    };
    const handler = handlerWithStore({ findOrderByID: async () => order });
    const path = `/social-coffee/gifts/${orderID}/status`;
    const check = async (giftToken) => {
        const request = { method: "GET", url: path, headers: giftToken ? { "x-talla-gift-token": giftToken } : {} };
        const response = { on() {}, setHeader() {} };
        await handler(request, response);
        return response;
    };
    assert.equal((await check(null)).status, 404);
    assert.equal((await check("0".repeat(64))).status, 404);
    assert.equal((await check(token)).body.gift.status, "pending");

    order = { ...order, status: "Confirmed", details: { cafePass: { ...order.details.cafePass,
        status: "active", expiresAt: new Date(Date.now() + 86_400_000).toISOString()
    } } };
    const ready = await check(token);
    assert.equal(ready.status, 200);
    assert.equal(ready.body.gift.status, "ready");
    assert.equal(ready.body.gift.remainingCredits, 1);
    assert.equal(JSON.stringify(ready.body).includes("private@example.com"), false);
    order.details.cafePass.expiresAt = "not-a-date";
    assert.equal((await check(token)).body.gift.status, "expired");
    order.details.cafePass.expiresAt = new Date(Date.now() + 86_400_000).toISOString();
    order.details.cafePass.redeemedCredits = 1;
    order.details.cafePass.status = "exhausted";
    assert.equal((await check(token)).body.gift.status, "redeemed");
});

test("members can recover open and closed group orders without exposing invite codes", async () => {
    const handler = handlerWithStore();
    const host = "host@example.com";
    const guest = "guest@example.com";
    const created = await send(handler, "POST", "/social-coffee/groups", { name: "Friday majlis", hostName: "Host" }, host);
    assert.equal(created.status, 201);
    const { id, inviteCode } = created.body.group;
    assert.equal((await send(handler, "GET", "/social-coffee/groups", null, guest)).body.groups.length, 0);
    assert.equal((await send(handler, "POST", `/social-coffee/groups/${id}/join`, { inviteCode, name: "Guest" }, guest)).status, 200);
    const hostList = await send(handler, "GET", "/social-coffee/groups", null, host);
    const guestList = await send(handler, "GET", "/social-coffee/groups", null, guest);
    assert.equal(hostList.body.groups[0].isHost, true);
    assert.equal(guestList.body.groups[0].isHost, false);
    assert.equal(JSON.stringify(guestList.body).includes(inviteCode), false);
    assert.equal(JSON.stringify(guestList.body).includes(host), false);
    assert.equal((await send(handler, "POST", `/social-coffee/groups/${id}/close`, {}, host)).status, 200);
    const recovered = await send(handler, "GET", "/social-coffee/groups", null, host);
    assert.equal(recovered.body.groups[0].status, "closed");
    assert.equal((await send(handler, "GET", `/social-coffee/groups/${id}`, null, host)).body.group.status, "closed");
    assert.equal((await send(handler, "POST", `/social-coffee/groups/${id}/join`, { inviteCode: "", name: "" }, host)).body.group.status, "closed");
    assert.equal((await send(handler, "POST", `/social-coffee/groups/${id}/join`, { inviteCode: "", name: "" }, "stranger@example.com")).status, 404);
});

test("Social Coffee reports temporary storage failure without publishing a partial profile", async () => {
    const handler = handlerWithStore({ readJSON: () => { throw new Error("STORE_UNAVAILABLE"); } });
    assert.equal((await send(handler, "GET", "/social-coffee/notes")).status, 503);
    assert.equal((await send(handler, "GET", "/social-coffee/profile", null, "guest@example.com")).status, 503);
    assert.equal((await send(handler, "PUT", "/social-coffee/profile", { tastingNote: "Private" }, "guest@example.com")).status, 503);
});
