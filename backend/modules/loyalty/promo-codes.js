function createAdminPromoCodeService({ storeVoucherRecord }) {
    return async function createAdminPromoCode({ code, discountType, discountValue, detail, expiresInDays, singleUse = true }) {
        const normalizedCode = String(code || "").trim().toUpperCase().replace(/[^A-Z0-9_-]/g, "").slice(0, 40);
        const normalizedType = String(discountType || "").trim().toLowerCase();
        const value = Number(discountValue);
        const expiryDays = Number(expiresInDays);
        if (!normalizedCode || !["percentage", "fixed"].includes(normalizedType) || !Number.isFinite(value) || value <= 0
            || (normalizedType === "percentage" && value > 100) || !Number.isFinite(expiryDays) || expiryDays <= 0) {
            throw new Error("Provide a valid code, percentage or fixed discount, positive value, and expiry days.");
        }
        const promo = {
            code: normalizedCode, email: null, reward: "promo discount", points: 0,
            detail: detail || (normalizedType === "percentage" ? `${value}% off` : `BHD ${value.toFixed(3)} off`),
            singleUse: singleUse !== false, status: "active", discountType: normalizedType, discountValue: value,
            createdAt: new Date().toISOString(),
            expiresAt: new Date(Date.now() + expiryDays * 24 * 60 * 60 * 1000).toISOString()
        };
        await storeVoucherRecord(promo);
        return promo;
    };
}

module.exports = { createAdminPromoCodeService };

function createPromoCodeListService({ database, readJSON, vouchersStorePath, voucherRowToRecord }) {
    return async function allPromoCodes() {
        if (database.isEnabled()) {
            const result = await database.query(`SELECT code, email, reward, points, detail, single_use, status, created_at, expires_at, used_at, discount_type, discount_value FROM vouchers WHERE email IS NULL ORDER BY created_at DESC`);
            return result.rows.map(voucherRowToRecord);
        }
        const store = readJSON(vouchersStorePath);
        const now = Date.now();
        return Object.values(store.vouchers).filter((voucher) => !voucher.email && voucher.discountType).map((voucher) => {
            if (voucher.status === "active" && new Date(voucher.expiresAt).getTime() < now) voucher.status = "expired";
            return voucher;
        }).sort((lhs, rhs) => new Date(rhs.createdAt).getTime() - new Date(lhs.createdAt).getTime());
    };
}

module.exports.createPromoCodeListService = createPromoCodeListService;
