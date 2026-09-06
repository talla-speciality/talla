const { URL } = require("url");

function defaultCampaignSettings() {
    return { eidModeEnabled: true, eidOfferEndsAt: null, updatedAt: null };
}

function normalizeCampaignSettings(value = {}) {
    const fallback = defaultCampaignSettings();
    const offerEndDate = value.eidOfferEndsAt ? new Date(value.eidOfferEndsAt) : null;
    const eidOfferEndsAt = offerEndDate && Number.isFinite(offerEndDate.getTime()) ? offerEndDate.toISOString() : null;
    return {
        eidModeEnabled: value.eidModeEnabled === undefined ? fallback.eidModeEnabled : Boolean(value.eidModeEnabled),
        eidOfferEndsAt,
        updatedAt: value.updatedAt || fallback.updatedAt,
    };
}

function defaultEventSettings() {
    return { events: [], updatedAt: null };
}

function normalizeEventSettings(value = {}) {
    const trimText = (text, maxLength) => String(text || "").trim().slice(0, maxLength);
    const eventID = (candidate, fallback) => {
        const normalized = trimText(candidate || fallback, 60).toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
        return normalized || fallback;
    };
    const isoDate = (candidate) => {
        if (!candidate) return null;
        const date = new Date(candidate);
        return Number.isFinite(date.getTime()) ? date.toISOString() : null;
    };
    const httpsURL = (candidate) => {
        const value = trimText(candidate, 500);
        if (!value) return "";
        try {
            const parsed = new URL(value);
            return parsed.protocol === "https:" ? parsed.toString() : "";
        } catch {
            return "";
        }
    };
    const hexColor = (candidate, fallback) => {
        const value = trimText(candidate, 7).toUpperCase();
        return /^#[0-9A-F]{6}$/.test(value) ? value : fallback;
    };
    const seenIDs = new Set();
    const sourceEvents = Array.isArray(value.events) ? value.events : [];
    const events = sourceEvents.slice(0, 30).map((event, index) => {
        let id = eventID(event?.id, `event-${index + 1}`);
        if (seenIDs.has(id)) id = `${id}-${index + 1}`;
        seenIDs.add(id);
        const seenProductIDs = new Set();
        const productIDs = (Array.isArray(event?.productIDs) ? event.productIDs : [])
            .map((productID) => trimText(productID, 180))
            .filter((productID) => {
                if (!productID || seenProductIDs.has(productID)) return false;
                seenProductIDs.add(productID);
                return true;
            }).slice(0, 40);
        const priority = Number(event?.priority);
        return {
            id, enabled: Boolean(event?.enabled), name: trimText(event?.name || event?.titleEN || id, 80),
            titleEN: trimText(event?.titleEN, 80), titleAR: trimText(event?.titleAR, 80),
            subtitleEN: trimText(event?.subtitleEN, 220), subtitleAR: trimText(event?.subtitleAR, 220),
            badgeEN: trimText(event?.badgeEN, 40), badgeAR: trimText(event?.badgeAR, 40),
            ctaEN: trimText(event?.ctaEN, 32), ctaAR: trimText(event?.ctaAR, 32),
            categoryTitleEN: trimText(event?.categoryTitleEN, 60), categoryTitleAR: trimText(event?.categoryTitleAR, 60),
            categorySubtitleEN: trimText(event?.categorySubtitleEN, 100), categorySubtitleAR: trimText(event?.categorySubtitleAR, 100),
            startAt: isoDate(event?.startAt), endAt: isoDate(event?.endAt), imageURL: httpsURL(event?.imageURL),
            accentHex: hexColor(event?.accentHex, "#C8965A"), secondaryHex: hexColor(event?.secondaryHex, "#2A1D14"),
            symbol: trimText(event?.symbol || "sparkles", 60), productIDs,
            priority: Number.isFinite(priority) ? Math.max(-1000, Math.min(1000, Math.round(priority))) : 0,
        };
    });
    return { events, updatedAt: value.updatedAt || null };
}

function activeEventSettings(settings, now = new Date()) {
    const nowTime = now.getTime();
    return {
        ...settings,
        events: settings.events.filter((event) => {
            if (!event.enabled || !event.titleEN) return false;
            const startTime = event.startAt ? new Date(event.startAt).getTime() : null;
            const endTime = event.endAt ? new Date(event.endAt).getTime() : null;
            return (startTime === null || startTime <= nowTime) && (endTime === null || endTime > nowTime);
        }).sort((left, right) => right.priority - left.priority || left.name.localeCompare(right.name)),
    };
}

function defaultHomeSettings() {
    return {
        signatureRoastProductIDs: [], quickDrinkProductIDs: [], funPickProductID: "", heroEyebrow: "", heroTitle: "",
        heroSubtitle: "", heroBadge: "", primaryButtonTitle: "", secondaryButtonTitle: "", updatedAt: null,
    };
}

function normalizeHomeSettings(value = {}) {
    const fallback = defaultHomeSettings();
    const normalizeProductIDs = (productIDs, limit) => {
        const seen = new Set();
        return Array.isArray(productIDs) ? productIDs.map((productID) => String(productID || "").trim()).filter((productID) => {
            if (!productID || seen.has(productID)) return false;
            seen.add(productID);
            return true;
        }).slice(0, limit) : [];
    };
    const signatureRoastProductIDs = Array.isArray(value.signatureRoastProductIDs) ? normalizeProductIDs(value.signatureRoastProductIDs, 4) : fallback.signatureRoastProductIDs;
    const quickDrinkProductIDs = Array.isArray(value.quickDrinkProductIDs) ? normalizeProductIDs(value.quickDrinkProductIDs, 6) : fallback.quickDrinkProductIDs;
    const trimText = (text, maxLength) => String(text || "").trim().slice(0, maxLength);
    return {
        signatureRoastProductIDs, quickDrinkProductIDs, funPickProductID: trimText(value.funPickProductID, 180),
        heroEyebrow: trimText(value.heroEyebrow, 40), heroTitle: trimText(value.heroTitle, 80), heroSubtitle: trimText(value.heroSubtitle, 180),
        heroBadge: trimText(value.heroBadge, 40), primaryButtonTitle: trimText(value.primaryButtonTitle, 28), secondaryButtonTitle: trimText(value.secondaryButtonTitle, 28),
        updatedAt: value.updatedAt || fallback.updatedAt,
    };
}

module.exports = {
    defaultCampaignSettings,
    normalizeCampaignSettings,
    defaultEventSettings,
    normalizeEventSettings,
    activeEventSettings,
    defaultHomeSettings,
    normalizeHomeSettings,
};
