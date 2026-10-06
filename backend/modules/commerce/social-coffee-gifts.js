const crypto = require("node:crypto");

function giftTokenForOrder(orderID, secret) {
    if (!orderID || !secret) return null;
    return crypto.createHmac("sha256", secret).update(`social-coffee-gift:${orderID}`).digest("hex");
}

function validGiftToken(orderID, token, secret) {
    if (!/^[a-f0-9]{64}$/i.test(String(token || ""))) return false;
    const expected = giftTokenForOrder(orderID, secret);
    if (!expected) return false;
    return crypto.timingSafeEqual(Buffer.from(expected, "hex"), Buffer.from(token, "hex"));
}

function giftPassFields(order, cafePass, secret) {
    const giftToken = cafePass?.giftedCoffee ? giftTokenForOrder(order.id, secret) : null;
    return {
        details: giftToken ? { ...order.details, cafePass: { ...order.details?.cafePass, giftToken } } : order.details,
        cafePass: giftToken ? { ...cafePass, giftToken } : cafePass
    };
}

module.exports = { giftTokenForOrder, validGiftToken, giftPassFields };
