function createAdminOrderDetailService(dependencies) {
    const {
        addressesFor,
        completedOrderStatuses,
        database,
        findBenefitPaymentByOrderID,
        findCardPayment,
        getAccountByEmail,
        normalizeCountryCode,
        numericOrderTotal,
        orderCurrency,
        orderPayloadWithRewardState,
        readJSON,
        shopifyEazyPaymentRowToRecord,
        shopifyEazyPaymentsStorePath
    } = dependencies;

    const trimText = (value, maximumLength) => String(value || "").trim().slice(0, maximumLength);

    function normalizeOrderDetails(value = {}) {
        const details = value && typeof value === "object" ? value : {};
        const customer = details.customer && typeof details.customer === "object" ? details.customer : {};
        const fulfillment = details.fulfillment && typeof details.fulfillment === "object" ? details.fulfillment : {};
        const payment = details.payment && typeof details.payment === "object" ? details.payment : {};
        return {
            source: trimText(details.source, 60),
            customer: {
                fullName: trimText(customer.fullName, 160),
                phone: trimText(customer.phone, 32)
            },
            fulfillment: {
                method: trimText(fulfillment.method, 40).toLowerCase(),
                fullName: trimText(fulfillment.fullName, 160),
                phone: trimText(fulfillment.phone, 32),
                line1: trimText(fulfillment.line1, 240),
                city: trimText(fulfillment.city, 100),
                countryCode: normalizeCountryCode(fulfillment.countryCode, ""),
                notes: trimText(fulfillment.notes, 500)
            },
            payment: { method: trimText(payment.method, 80) }
        };
    }

    function displayPaymentMethod(value) {
        const method = String(value || "").trim().toLowerCase();
        if (method === "applepay" || method === "apple_pay") return "Apple Pay";
        if (method === "benefitpay" || method === "benefit_pay") return "BenefitPay";
        if (method === "benefit") return "BENEFIT";
        if (["card", "creditcard", "credit_card"].includes(method)) return "Credit or Debit Card";
        if (["cashondelivery", "cash_on_delivery", "cod"].includes(method)) return "Cash on Delivery";
        return trimText(value, 80);
    }

    async function findShopifyEazyPaymentForOrder(order) {
        const rawID = String(order.id || "").replace(/^shopify_/, "");
        if (!rawID) return null;
        if (database.isEnabled()) {
            const result = await database.query(
                `SELECT * FROM shopify_eazy_payments
                 WHERE shopify_order_id = $1 OR shopify_order_gid = $2 OR shopify_order_name = $3
                 ORDER BY updated_at DESC
                 LIMIT 1`,
                [rawID, `gid://shopify/Order/${rawID}`, order.title]
            );
            return result.rowCount > 0 ? shopifyEazyPaymentRowToRecord(result.rows[0]) : null;
        }
        return Object.values(readJSON(shopifyEazyPaymentsStorePath).payments || {})
            .filter((payment) => (
                String(payment.shopifyOrderId || "") === rawID
                || String(payment.shopifyOrderGid || "") === `gid://shopify/Order/${rawID}`
                || (payment.shopifyOrderName && payment.shopifyOrderName === order.title)
            ))
            .sort((left, right) => String(right.updatedAt || "").localeCompare(String(left.updatedAt || "")))[0]
            || null;
    }

    async function paymentForOrder(order, snapshot) {
        const card = await findCardPayment(order.id, order.email);
        if (card) {
            return {
                method: displayPaymentMethod(snapshot.payment.method || card.paymentMethod),
                provider: "Mastercard Payment Gateway",
                status: card.status,
                amount: String(card.amount || numericOrderTotal(order).toFixed(3)),
                currency: String(card.currency || orderCurrency(order)),
                reference: card.purchaseTransactionID || card.paymentID || null,
                paidAt: card.completedAt || null
            };
        }

        const benefit = await findBenefitPaymentByOrderID(order.id);
        if (benefit) {
            return {
                method: displayPaymentMethod(snapshot.payment.method || "BENEFIT"),
                provider: snapshot.payment.method?.toLowerCase() === "benefitpay" ? "BenefitPay" : "BENEFIT Payment Gateway",
                status: benefit.status,
                amount: String(benefit.amount || numericOrderTotal(order).toFixed(3)),
                currency: String(benefit.currency || orderCurrency(order)),
                reference: benefit.referenceID || benefit.transactionID || benefit.paymentID || benefit.trackID || null,
                paidAt: benefit.processedAt || benefit.effectsAppliedAt || null
            };
        }

        const eazy = await findShopifyEazyPaymentForOrder(order);
        if (eazy) {
            return {
                method: displayPaymentMethod(eazy.eazyPaymentMethod || eazy.paymentGateway || snapshot.payment.method),
                provider: "EazyPay / Shopify",
                status: eazy.status,
                amount: eazy.amount ? String(eazy.amount) : numericOrderTotal(order).toFixed(3),
                currency: String(eazy.currency || orderCurrency(order)),
                reference: eazy.eazyTransactionId || eazy.eazyGlobalTransactionId || eazy.tallaPaymentId,
                paidAt: eazy.paidAt || eazy.eazyConfirmedAt || null
            };
        }

        const method = displayPaymentMethod(snapshot.payment.method);
        if (!method) return null;
        return {
            method,
            provider: method === "Cash on Delivery" ? "Collected on fulfilment" : null,
            status: method === "Cash on Delivery" && !completedOrderStatuses().has(order.status)
                ? "Awaiting payment"
                : "Not recorded",
            amount: numericOrderTotal(order).toFixed(3),
            currency: orderCurrency(order),
            reference: null,
            paidAt: null
        };
    }

    async function adminOrderDetailPayload(order) {
        const snapshot = normalizeOrderDetails(order.details);
        const [account, addresses, payment] = await Promise.all([
            getAccountByEmail(order.email),
            addressesFor(order.email),
            paymentForOrder(order, snapshot)
        ]);
        const preferredAddress = addresses.find((address) => address.isPreferred) || addresses[0] || {};
        const fulfillment = snapshot.fulfillment;
        const fullName = snapshot.customer.fullName
            || fulfillment.fullName
            || `${account?.firstName || ""} ${account?.lastName || ""}`.trim();
        const phone = snapshot.customer.phone || fulfillment.phone || preferredAddress.phone || "";
        const inferredMethod = order.title.toLowerCase().includes("pickup") ? "pickup"
            : order.title.toLowerCase().includes("delivery") ? "delivery"
                : "";
        return orderPayloadWithRewardState(order.email, {
            ...order,
            customer: { fullName: fullName || null, email: order.email, phone: phone || null },
            fulfillment: {
                method: fulfillment.method || inferredMethod,
                fullName: fulfillment.fullName || preferredAddress.fullName || fullName,
                phone: fulfillment.phone || preferredAddress.phone || phone,
                line1: fulfillment.line1 || preferredAddress.line1 || "",
                city: fulfillment.city || preferredAddress.city || "",
                countryCode: fulfillment.countryCode || preferredAddress.countryCode || "",
                notes: fulfillment.notes || preferredAddress.notes || ""
            },
            payment,
            source: snapshot.source || (String(order.id).startsWith("shopify_") ? "Shopify" : "Talla app")
        });
    }

    function shopifyOrderDetails(order) {
        const address = order.shipping_address || order.billing_address || {};
        const customer = order.customer || {};
        const fullName = String(address.name || `${customer.first_name || ""} ${customer.last_name || ""}`).trim();
        const gatewayNames = Array.isArray(order.payment_gateway_names)
            ? order.payment_gateway_names.join(", ")
            : order.gateway;
        return normalizeOrderDetails({
            source: "Shopify",
            customer: { fullName, phone: address.phone || customer.phone },
            fulfillment: {
                method: order.shipping_lines?.length ? "delivery" : "pickup",
                fullName,
                phone: address.phone || customer.phone,
                line1: address.address1,
                city: address.city,
                countryCode: address.country_code,
                notes: order.note
            },
            payment: { method: gatewayNames }
        });
    }

    function shopifyAdminOrderDetails(order) {
        const address = order.shippingAddress || {};
        const customer = order.customer || {};
        const fullName = String(address.name || `${customer.firstName || ""} ${customer.lastName || ""}`).trim();
        return normalizeOrderDetails({
            source: "Shopify",
            customer: { fullName, phone: address.phone || customer.phone },
            fulfillment: {
                method: order.shippingAddress ? "delivery" : "pickup",
                fullName,
                phone: address.phone || customer.phone,
                line1: address.address1,
                city: address.city,
                countryCode: address.countryCodeV2
            },
            payment: { method: Array.isArray(order.paymentGatewayNames) ? order.paymentGatewayNames.join(", ") : order.paymentGatewayNames }
        });
    }

    return { adminOrderDetailPayload, normalizeOrderDetails, shopifyAdminOrderDetails, shopifyOrderDetails };
}

module.exports = { createAdminOrderDetailService };
