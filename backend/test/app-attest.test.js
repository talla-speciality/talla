const test = require("node:test");
const assert = require("node:assert/strict");
process.env.APP_ATTEST_ENFORCE = "false";
const appAttest = require("../app-attest");

test("App Attest issues 256-bit single-purpose challenges", () => {
    const challenge = appAttest.issueChallenge({
        purpose: "attestation",
        method: "POST",
        path: ""
    });
    assert.equal(Buffer.from(challenge, "base64").length, 32);
    assert.throws(
        () => appAttest.issueChallenge({ purpose: "assertion", path: "/not-protected" }),
        /UNPROTECTED_ASSERTION_PATH/
    );
    assert.doesNotThrow(() => appAttest.issueChallenge({
        purpose: "assertion",
        method: "POST",
        path: "/addresses/preferred"
    }));
    assert.doesNotThrow(() => appAttest.issueChallenge({
        purpose: "assertion",
        method: "POST",
        path: "/api/payments/benefit/status"
    }));
    assert.doesNotThrow(() => appAttest.issueChallenge({
        purpose: "assertion",
        method: "POST",
        path: "/customer-library"
    }));
});

test("rollout mode permits unsigned calls but rejects invalid signed calls", async () => {
    const unsigned = await appAttest.verifyRequest({ headers: {}, method: "POST" }, "/addresses/save");
    assert.equal(unsigned.allowed, true);
    assert.equal(unsigned.rolloutBypass, true);

    const challenge = appAttest.issueChallenge({
        purpose: "assertion",
        method: "POST",
        path: "/addresses/save"
    });
    const invalid = await appAttest.verifyRequest({
        method: "GET",
        headers: {
            "x-talla-app-attest-key-id": "unknown",
            "x-talla-app-attest-challenge": challenge,
            "x-talla-app-attest-assertion": Buffer.from("invalid").toString("base64")
        }
    }, "/addresses/save");
    assert.equal(invalid.allowed, false);
    assert.equal(invalid.error, "INVALID_OR_EXPIRED_CHALLENGE");
});
