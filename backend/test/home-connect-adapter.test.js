const test = require("node:test");
const assert = require("node:assert/strict");

const { authorizationURL, createHomeConnectAdapter, normalizeTokenResponse, openSecret, randomState, sealSecret, tokenForm } = require("../modules/brewing/home-connect-adapter");

test("Home Connect authorization uses the documented OAuth scopes and state", () => {
    const state = randomState();
    const url = new URL(authorizationURL({ clientID: "client", redirectURI: "https://example.test/callback", state }));
    assert.equal(url.hostname, "api.home-connect.com");
    assert.equal(url.searchParams.get("client_id"), "client");
    assert.equal(url.searchParams.get("state"), state);
    assert.ok(url.searchParams.get("scope").includes("CoffeeMaker"));
});

test("Home Connect token normalization never exposes client secrets", () => {
    const token = normalizeTokenResponse({ access_token: "access", refresh_token: "refresh", expires_in: 3600, scope: "CoffeeMaker" }, () => 1_000);
    assert.equal(token.accessToken, "access");
    assert.equal(token.refreshToken, "refresh");
    assert.equal(token.expiresAt, "1970-01-01T01:00:01.000Z");
    assert.deepEqual([...tokenForm({ client_id: "client", client_secret: "secret", grant_type: "refresh_token" }).keys()], ["client_id", "client_secret", "grant_type"]);
});

test("Home Connect adapter exchanges codes and lists appliances through injected transport", async () => {
    const calls = [];
    const adapter = createHomeConnectAdapter({ clientID: "client", clientSecret: "secret", redirectURI: "https://example.test/callback", fetchFn: async (url, options) => {
        calls.push({ url, options });
        return { ok: true, status: 200, async json() { return url.endsWith("/token") ? { access_token: "a", refresh_token: "r", expires_in: 3600 } : { data: { homeAppliances: [] } }; } };
    }, now: () => 1_000 });
    const token = await adapter.exchangeCode("code");
    const appliances = await adapter.listAppliances(token.accessToken);
    assert.equal(appliances.data.homeAppliances.length, 0);
    assert.equal(calls.length, 2);
    assert.equal(calls[0].options.body.get("grant_type"), "authorization_code");
});

test("Home Connect adapter uses documented coffee-maker control payloads", async () => {
    const requests = [];
    const adapter = createHomeConnectAdapter({ clientID: "client", clientSecret: "secret", redirectURI: "https://example.test/callback", fetchFn: async (url, options) => {
        requests.push({ url, options });
        return new Response(null, { status: 204 });
    }});
    await adapter.setPowerState("access", "machine/1", "BSH.Common.EnumType.PowerState.On");
    await adapter.startEspresso("access", "machine/1", { fillQuantity: 40, beanAmount: "Strong" });
    assert.equal(requests[0].options.method, "PUT");
    assert.match(requests[0].url, /settings%2FBSH|settings\/BSH/);
    assert.match(requests[1].options.body, /CoffeeMaker.Program.Beverage.Espresso/);
    assert.match(requests[1].options.body, /40/);
});

test("Home Connect credentials are encrypted at rest", () => {
    const sealed = sealSecret("refresh-token", "server-secret", () => Buffer.alloc(12, 7));
    assert.notEqual(sealed, "refresh-token");
    assert.equal(openSecret(sealed, "server-secret"), "refresh-token");
    assert.throws(() => openSecret(sealed, "wrong-secret"));
});
