const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");

const { requestHash } = require("../modules/account/google-mobile-services");

test("Play Integrity request hashes bind the method, path, and exact body", () => {
    const rawBody = '{"email":"member@example.com","platform":"android"}';
    const expected = crypto.createHash("sha256")
        .update(`POST\n/notifications/push/register\n${rawBody}`)
        .digest("base64url");

    assert.equal(requestHash("post", "/notifications/push/register", rawBody), expected);
    assert.notEqual(requestHash("POST", "/notifications/push/register", `${rawBody} `), expected);
    assert.notEqual(requestHash("POST", "/notifications/push/unregister", rawBody), expected);
});
