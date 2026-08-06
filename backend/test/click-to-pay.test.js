const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const test = require("node:test");

process.env.DATA_DIRECTORY = fs.mkdtempSync(path.join(os.tmpdir(), "talla-click-to-pay-"));
process.env.APP_URL = "https://merchant.test";
process.env.MPGS_MERCHANT_ID = "TESTMERCHANT";
process.env.MPGS_API_PASSWORD = "test-password-never-log";
process.env.MPGS_API_VERSION = "100";
process.env.MPGS_BASE_URL = "https://eazypay.gateway.mastercard.com";
delete process.env.DATABASE_URL;

const { renderClickToPayLaunch, renderMpgsResultPage } = require("../server");

test("Click to Pay launch follows the Mastercard Hosted Checkout SDK pattern", () => {
    const html = renderClickToPayLaunch({
        sessionID: "SESSION1234567890123456789012345"
    }, "opaque-result-token");

    assert.match(html, /\/static\/checkout\/checkout\.min\.js/);
    assert.match(html, /data-complete="paymentComplete"/);
    assert.match(html, /data-error="paymentError"/);
    assert.match(html, /data-cancel="paymentCancelled"/);
    assert.match(html, /data-timeout="paymentTimeout"/);
    assert.match(html, /Checkout\.configure\(\{session:\{id:/);
    assert.match(html, /Checkout\.showPaymentPage\(\)/);
    assert.match(html, /Content-Security-Policy/);
    assert.doesNotMatch(html, /interaction:\{returnUrl/);
    assert.doesNotMatch(html, /test-password-never-log/);
});

test("verified Click to Pay result pages return an explicit app status", () => {
    assert.match(renderMpgsResultPage("success"), /talla:\/\/checkout-return\?status=success/);
    assert.match(renderMpgsResultPage("cancelled"), /talla:\/\/checkout-return\?status=cancelled/);
    assert.match(renderMpgsResultPage("failure"), /talla:\/\/checkout-return\?status=failed/);
    assert.match(renderMpgsResultPage("pending"), /talla:\/\/checkout-return\?status=pending/);
});
