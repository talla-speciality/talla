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

    const validISODate = (value) => {
        const text = trimText(value, 40);
        return text && Number.isFinite(Date.parse(text)) ? new Date(text).toISOString() : "";
    };

    const shiftedISODate = (value, days) => {
        const timestamp = Date.parse(value);
        return Number.isFinite(timestamp) ? new Date(timestamp + days * 86_400_000).toISOString() : "";
    };

    function normalizeCoffeeClub(value) {
        if (!value || typeof value !== "object") return null;
        const shipmentCount = Math.max(1, Math.min(12, Math.round(Number(value.shipmentCount) || 1)));
        const rawShipments = Array.isArray(value.shipments) ? value.shipments : [];
        const startedAt = validISODate(value.startedAt || value.termsAcceptedAt) || new Date().toISOString();
        const intervalWeeks = Math.max(1, Math.min(52, Math.round(Number(value.intervalWeeks) || 4)));
        const shipments = rawShipments.slice(0, shipmentCount).map((shipment, index) => {
            const number = Math.max(1, Math.min(shipmentCount, Math.round(Number(shipment?.number) || index + 1)));
            return {
                number,
                scheduledAt: validISODate(shipment?.scheduledAt) || shiftedISODate(startedAt, (number - 1) * intervalWeeks * 7),
                preparedAt: validISODate(shipment?.preparedAt),
                preparedBy: trimText(shipment?.preparedBy, 120),
                deliveredAt: validISODate(shipment?.deliveredAt),
                deliveredBy: trimText(shipment?.deliveredBy, 120)
            };
        }).filter((shipment) => shipment.preparedAt || shipment.deliveredAt);
        const deliveredShipments = Math.max(0, Math.min(
            shipmentCount,
            Math.round(Number(value.deliveredShipments) || shipments.filter((shipment) => shipment.deliveredAt).length)
        ));
        const statusValues = new Set(["active", "paused", "cancel_requested", "cancelled", "completed"]);
        const inferredStatus = deliveredShipments >= shipmentCount ? "completed" : "active";
        const status = statusValues.has(String(value.status || "").toLowerCase())
            ? String(value.status).toLowerCase()
            : inferredStatus;
        const nextShipmentNumber = deliveredShipments < shipmentCount ? deliveredShipments + 1 : null;
        const rawChangesEffectiveFromShipment = Math.round(Number(value.changesEffectiveFromShipment));
        const changesEffectiveFromShipment = Number.isFinite(rawChangesEffectiveFromShipment)
            ? Math.max(1, Math.min(shipmentCount, rawChangesEffectiveFromShipment))
            : null;
        const nextShipmentAt = nextShipmentNumber
            ? shiftedISODate(startedAt, (nextShipmentNumber - 1) * intervalWeeks * 7)
            : "";
        const pausedAt = validISODate(value.pausedAt);
        const cancelledAt = validISODate(value.cancelledAt);
        const activeForSchedule = status === "active" || status === "cancel_requested";
        return {
            shipmentCount,
            intervalWeeks,
            discountPercent: Math.max(0, Math.min(100, Math.round(Number(value.discountPercent) || 0))),
            deliveredShipments,
            remainingShipments: shipmentCount - deliveredShipments,
            shipments,
            status: deliveredShipments >= shipmentCount ? "completed" : status,
            startedAt,
            nextShipmentAt,
            nextShipmentNumber,
            changesEffectiveFromShipment,
            isOverdue: Boolean(activeForSchedule && nextShipmentAt && Date.now() > Date.parse(nextShipmentAt) + 86_400_000),
            pausedAt: pausedAt || null,
            cancelledAt: cancelledAt || null,
            cancellationRequestedAt: validISODate(value.cancellationRequestedAt) || null,
            cancellationReason: trimText(value.cancellationReason, 500) || null,
            refundStatus: ["none", "requested", "pending", "recorded"].includes(String(value.refundStatus || "").toLowerCase())
                ? String(value.refundStatus).toLowerCase()
                : "none",
            refundAmount: Math.max(0, Number(value.refundAmount) || 0),
            refundNote: trimText(value.refundNote, 500) || null,
            refundedAt: validISODate(value.refundedAt) || null,
            termsAcceptedAt: validISODate(value.termsAcceptedAt) || null,
            lastReminderAt: validISODate(value.lastReminderAt) || null,
            lastSkippedAt: validISODate(value.lastSkippedAt) || null,
            preference: {
                coffeeName: trimText(value.preference?.coffeeName, 180) || null,
                variantId: trimText(value.preference?.variantId, 180) || null
            },
            fulfillmentOverride: value.fulfillmentOverride && typeof value.fulfillmentOverride === "object" ? {
                fullName: trimText(value.fulfillmentOverride.fullName, 160),
                phone: trimText(value.fulfillmentOverride.phone, 32),
                line1: trimText(value.fulfillmentOverride.line1, 240),
                city: trimText(value.fulfillmentOverride.city, 100),
                countryCode: normalizeCountryCode(value.fulfillmentOverride.countryCode, ""),
                notes: trimText(value.fulfillmentOverride.notes, 500)
            } : null
        };
    }

    function updateCoffeeClubProgress(value, action, deliveredBy, deliveredAt = new Date().toISOString(), changes = {}) {
        const coffeeClub = normalizeCoffeeClub(value);
        if (!coffeeClub) return null;
        const now = validISODate(deliveredAt) || new Date().toISOString();
        const shipments = [...coffeeClub.shipments];
        let deliveredShipments = coffeeClub.deliveredShipments;
        if (action === "prepare" || action === "deliver") {
            if (!["active", "cancel_requested"].includes(coffeeClub.status)) return null;
            if (deliveredShipments >= coffeeClub.shipmentCount) return null;
            const number = deliveredShipments + 1;
            const existingIndex = shipments.findIndex((shipment) => shipment.number === number);
            const shipment = existingIndex >= 0 ? shipments[existingIndex] : {
                number,
                scheduledAt: shiftedISODate(coffeeClub.startedAt, (number - 1) * coffeeClub.intervalWeeks * 7),
                preparedAt: "",
                preparedBy: "",
                deliveredAt: "",
                deliveredBy: ""
            };
            shipment.preparedAt = shipment.preparedAt || now;
            shipment.preparedBy = shipment.preparedBy || trimText(deliveredBy, 120);
            if (action === "deliver") {
                shipment.deliveredAt = now;
                shipment.deliveredBy = trimText(deliveredBy, 120);
                deliveredShipments += 1;
            }
            if (existingIndex >= 0) shipments[existingIndex] = shipment;
            else shipments.push(shipment);
        } else if (action === "undo") {
            if (deliveredShipments <= 0) return null;
            const shipment = shipments.find((entry) => entry.number === deliveredShipments);
            if (shipment) {
                shipment.deliveredAt = "";
                shipment.deliveredBy = "";
            }
            deliveredShipments -= 1;
        } else if (action === "pause") {
            if (coffeeClub.status !== "active") return null;
            return normalizeCoffeeClub({ ...coffeeClub, status: "paused", pausedAt: now });
        } else if (action === "resume") {
            if (coffeeClub.status !== "paused") return null;
            const pausedForDays = Math.max(0, (Date.parse(now) - Date.parse(coffeeClub.pausedAt || now)) / 86_400_000);
            return normalizeCoffeeClub({
                ...coffeeClub,
                status: "active",
                startedAt: shiftedISODate(coffeeClub.startedAt, pausedForDays),
                pausedAt: null
            });
        } else if (action === "skip_next") {
            if (coffeeClub.status !== "active" || !coffeeClub.nextShipmentAt) return null;
            const nextShipment = coffeeClub.shipments.find((shipment) => shipment.number === coffeeClub.nextShipmentNumber);
            if (nextShipment?.preparedAt) return null;
            return normalizeCoffeeClub({
                ...coffeeClub,
                startedAt: shiftedISODate(coffeeClub.startedAt, coffeeClub.intervalWeeks * 7),
                lastSkippedAt: now
            });
        } else if (action === "request_cancel") {
            if (["cancelled", "completed"].includes(coffeeClub.status)) return null;
            return normalizeCoffeeClub({
                ...coffeeClub,
                status: "cancel_requested",
                cancellationRequestedAt: now,
                cancellationReason: changes.reason
            });
        } else if (action === "cancel") {
            if (coffeeClub.status === "completed") return null;
            return normalizeCoffeeClub({
                ...coffeeClub,
                status: "cancelled",
                cancelledAt: now,
                cancellationReason: changes.reason || coffeeClub.cancellationReason
            });
        } else if (action === "request_refund") {
            if (coffeeClub.refundStatus === "recorded") return null;
            return normalizeCoffeeClub({ ...coffeeClub, refundStatus: "requested", refundNote: changes.note });
        } else if (action === "refund_pending") {
            return normalizeCoffeeClub({ ...coffeeClub, refundStatus: "pending", refundNote: changes.note });
        } else if (action === "record_refund") {
            const amount = Number(changes.amount);
            if (!Number.isFinite(amount) || amount < 0) return null;
            return normalizeCoffeeClub({
                ...coffeeClub,
                refundStatus: "recorded",
                refundAmount: amount,
                refundNote: changes.note,
                refundedAt: now
            });
        } else if (action === "update_preferences") {
            if (["cancelled", "completed"].includes(coffeeClub.status)) return null;
            const currentShipment = coffeeClub.shipments.find((shipment) => (
                shipment.number === coffeeClub.nextShipmentNumber && shipment.preparedAt && !shipment.deliveredAt
            ));
            const changesEffectiveFromShipment = Math.min(
                coffeeClub.shipmentCount,
                coffeeClub.deliveredShipments + (currentShipment ? 2 : 1)
            );
            return normalizeCoffeeClub({
                ...coffeeClub,
                changesEffectiveFromShipment,
                preference: {
                    coffeeName: changes.coffeeName,
                    variantId: changes.variantId
                },
                fulfillmentOverride: changes.fulfillment
            });
        } else if (action === "reminded") {
            return normalizeCoffeeClub({ ...coffeeClub, lastReminderAt: now });
        } else {
            return null;
        }
        return normalizeCoffeeClub({
            ...coffeeClub,
            deliveredShipments,
            remainingShipments: coffeeClub.shipmentCount - deliveredShipments,
            shipments,
            status: deliveredShipments >= coffeeClub.shipmentCount ? "completed" : coffeeClub.status
        });
    }

    function normalizeOrderDetails(value = {}) {
        const details = value && typeof value === "object" ? value : {};
        const customer = details.customer && typeof details.customer === "object" ? details.customer : {};
        const fulfillment = details.fulfillment && typeof details.fulfillment === "object" ? details.fulfillment : {};
        const payment = details.payment && typeof details.payment === "object" ? details.payment : {};
        const tracking = details.tracking && typeof details.tracking === "object" ? details.tracking : {};
        const coffeeClub = normalizeCoffeeClub(details.coffeeClub);
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
                notes: trimText(fulfillment.notes, 500),
                pickupSlot: trimText(fulfillment.pickupSlot, 80)
            },
            payment: { method: trimText(payment.method, 80) },
            tracking: {
                company: trimText(tracking.company, 100),
                number: trimText(tracking.number, 120),
                url: /^https:\/\//i.test(String(tracking.url || "")) ? trimText(tracking.url, 500) : ""
            },
            coffeeClub
        };
    }

    function displayPaymentMethod(value) {
        const method = String(value || "").trim().toLowerCase();
        if (method === "applepay" || method === "apple_pay") return "Apple Pay";
        if (method === "benefitpay" || method === "benefit_pay") return "BenefitPay";
        if (method === "benefit") return "BENEFIT";
        if (["card", "creditcard", "credit_card"].includes(method)) return "Credit or Debit Card";
        if (["clicktopay", "click_to_pay"].includes(method)) return "Click to Pay";
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
            coffeeClub: snapshot.coffeeClub,
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
            payment: { method: gatewayNames },
            tracking: {
                company: order.fulfillments?.[0]?.tracking_company,
                number: order.fulfillments?.[0]?.tracking_number,
                url: order.fulfillments?.[0]?.tracking_url
            }
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
            payment: { method: Array.isArray(order.paymentGatewayNames) ? order.paymentGatewayNames.join(", ") : order.paymentGatewayNames },
            tracking: {
                company: order.fulfillments?.[0]?.trackingInfo?.[0]?.company,
                number: order.fulfillments?.[0]?.trackingInfo?.[0]?.number,
                url: order.fulfillments?.[0]?.trackingInfo?.[0]?.url
            }
        });
    }

    return {
        adminOrderDetailPayload,
        normalizeOrderDetails,
        shopifyAdminOrderDetails,
        shopifyOrderDetails,
        updateCoffeeClubProgress
    };
}

module.exports = { createAdminOrderDetailService };
