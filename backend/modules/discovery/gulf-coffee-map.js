const crypto = require("crypto");

const ALLOWED_RATINGS = new Set([1, 2, 3, 4, 5]);

function text(value, limit = 500) {
    return String(value || "").trim().slice(0, limit);
}

function localized(value, limit = 500) {
    if (!value || typeof value !== "object" || Array.isArray(value)) return { en: "", ar: "" };
    return { en: text(value.en, limit), ar: text(value.ar, limit) };
}

function normalizeOffering(offering, index) {
    if (!offering || typeof offering !== "object") return null;
    const id = text(offering.id, 140) || `offering-${index + 1}`;
    const kind = ["drink", "bean", "workshop"].includes(String(offering.kind || "").toLowerCase())
        ? String(offering.kind).toLowerCase()
        : "drink";
    return {
        ...offering,
        id,
        name: text(offering.name, 160),
        detail: text(offering.detail, 300),
        detailAR: text(offering.detailAR, 300),
        kind,
        brewMethod: text(offering.brewMethod, 120),
        brewRatio: text(offering.brewRatio, 160),
        brewTemperature: text(offering.brewTemperature, 80),
        brewTip: text(offering.brewTip, 300)
    };
}

function normalizeEvent(event, index) {
    if (!event || typeof event !== "object") return null;
    const id = text(event.id, 120) || `event-${index + 1}`;
    const title = localized(event.title, 160);
    return {
        ...event,
        id,
        title,
        kind: text(event.kind, 80),
        startsAt: text(event.startsAt, 50),
        url: text(event.url, 500),
        status: ["published", "cancelled", "draft"].includes(event.status) ? event.status : "published"
    };
}

const defaultDirectory = [
    { id: "bhr-seef", name: "Talla Speciality", city: "Riffa", country: "Bahrain", neighborhood: "Riffa 913", websiteURL: "https://maps.app.goo.gl/PaaVd6sz66JGk4KS9?g_st=ic", address: "Villa 336, Street 1307, Riffa 913", categories: ["Cafés", "Roasters", "Work-friendly"], tags: ["pour over", "quiet", "single origin"], offerings: [{ id: "bhr-seef-v60", name: "Ethiopia V60", kind: "drink" }, { id: "bhr-seef-bean", name: "House seasonal lot", kind: "bean" }] },
    { id: "ksa-riyadh", name: "Origin Room", city: "Riyadh", country: "Saudi Arabia", neighborhood: "Al Olaya", categories: ["Cafés", "Cuppings & workshops", "Work-friendly"], tags: ["cupping", "espresso", "work tables"], offerings: [{ id: "ksa-riyadh-espresso", name: "House espresso", kind: "drink" }, { id: "ksa-riyadh-cupping", name: "Friday cupping", kind: "workshop" }] },
    { id: "uae-dubai", name: "Night Shift Roasters", city: "Dubai", country: "UAE", neighborhood: "Al Quoz", categories: ["Roasters", "Green beans", "Equipment"], tags: ["green coffee", "gear", "training"], offerings: [{ id: "uae-dubai-natural", name: "Colombia natural", kind: "bean" }, { id: "uae-dubai-grinder", name: "Hand grinder clinic", kind: "workshop" }] },
    { id: "kwt-kuwait", name: "Grounds & Co.", city: "Kuwait City", country: "Kuwait", neighborhood: "Sharq", categories: ["Cafés", "Drive-through", "Family-friendly"], tags: ["drive through", "family", "iced latte"], offerings: [{ id: "kwt-kuwait-spanish", name: "Spanish latte", kind: "drink" }, { id: "kwt-kuwait-beans", name: "Weekend blend", kind: "bean" }] },
    { id: "qat-doha", name: "Saddleback Coffee Truck", city: "Doha", country: "Qatar", neighborhood: "Msheireb", categories: ["Trucks", "Cafés", "Cuppings & workshops"], tags: ["truck", "pop-up", "throwdown"], offerings: [{ id: "qat-doha-aeropress", name: "AeroPress special", kind: "drink" }, { id: "qat-doha-throwdown", name: "Open throwdown", kind: "workshop" }] },
    { id: "omn-muscat", name: "Wadi Coffee Supply", city: "Muscat", country: "Oman", neighborhood: "Al Khuwair", categories: ["Equipment", "Green beans", "Work-friendly"], tags: ["equipment", "beans", "brew bar"], offerings: [{ id: "omn-muscat-kenya", name: "Kenya AA", kind: "bean" }, { id: "omn-muscat-brew", name: "Brew setup consult", kind: "workshop" }] },
    { id: "not-just-beans", name: "Not Just Beans", city: "Online", country: "GCC", neighborhood: "Online store", websiteURL: "https://notjustbeans.shop/collections/talla-speciality-roasters", logoURL: "https://notjustbeans.shop/favicon.ico", categories: ["Green beans"], tags: ["online store", "Talla beans", "delivery"], offerings: [{ id: "not-just-beans-talla", name: "Talla beans", kind: "bean" }] },
    { id: "hambella-riffa", name: "Hambella", city: "Riffa", country: "Bahrain", neighborhood: "Riffa", websiteURL: "https://maps.app.goo.gl/DU2Gy8kmZ1rGYVLy6?g_st=ic", logoURL: "https://www.hambella-bh.com/favicon.ico", address: "Shop No. 523G, Block 913 Road 1311, Riffa 913", phone: "3332 2609", hours: "See Google Maps for current hours", verificationStatus: "link-verified", categories: ["Green beans"], tags: ["Talla beans", "partner seller"], offerings: [{ id: "hambella-riffa-talla", name: "Talla beans", kind: "bean" }] },
    { id: "tumma-roast-zinj", name: "Tumma Roast", city: "Manama", country: "Bahrain", neighborhood: "Zinj", websiteURL: "https://maps.app.goo.gl/Kd7Fwxq9afe4nirt8?g_st=ic", logoURL: "https://tummaroast.com/favicon.ico", address: "Building 308 Road 58, Zinj 358", phone: "3201 6614", hours: "See Google Maps for current hours", verificationStatus: "link-verified", categories: ["Green beans"], tags: ["Talla beans", "partner seller"], offerings: [{ id: "tumma-roast-zinj-talla", name: "Talla beans", kind: "bean" }] }
];

function ratingID(email, offeringID) {
    return `gcmr_${crypto.createHash("sha256").update(`${email}|${offeringID}`).digest("hex").slice(0, 20)}`;
}

function normalizeRatingInput(email, body) {
    const normalizedEmail = String(email || "").trim().toLowerCase();
    const spotID = String(body.spotID || body.spotId || "").trim().slice(0, 100);
    const offeringID = String(body.offeringID || body.offeringId || "").trim().slice(0, 140);
    const rating = Number(body.rating);
    const note = String(body.note || "").trim().slice(0, 1_000);
    if (!normalizedEmail || !spotID || !offeringID || !ALLOWED_RATINGS.has(rating)) return null;
    return { id: ratingID(normalizedEmail, offeringID), spotID, offeringID, rating, note, updatedAt: new Date().toISOString() };
}

function normalizeStore(store) {
    const ratings = store && typeof store.ratings === "object" && !Array.isArray(store.ratings) ? store.ratings : {};
    // An explicitly saved empty directory is intentional: admin removals must persist.
    const directory = Array.isArray(store?.directory) ? store.directory : defaultDirectory;
    const rsvps = store && typeof store.rsvps === "object" && !Array.isArray(store.rsvps) ? store.rsvps : {};
    return { version: 1, directory, ratings, rsvps };
}

function directoryFor(store) {
    return normalizeStore(store).directory;
}

function replaceDirectory(store, directory) {
    const normalized = normalizeStore(store);
    if (!Array.isArray(directory) || directory.length > 500) return null;
    const next = directory.map((place) => ({
        ...place,
        id: String(place.id || "").trim().slice(0, 100),
        name: String(place.name || "").trim().slice(0, 160),
        city: String(place.city || "").trim().slice(0, 100),
        country: String(place.country || "").trim().slice(0, 100),
        categories: Array.isArray(place.categories) ? place.categories.map((value) => String(value).trim()).filter(Boolean).slice(0, 12) : [],
        tags: Array.isArray(place.tags) ? place.tags.map((value) => String(value).trim()).filter(Boolean).slice(0, 20) : [],
        neighborhood: String(place.neighborhood || "").trim().slice(0, 160),
        websiteURL: String(place.websiteURL || "").trim().slice(0, 500),
        logoURL: String(place.logoURL || "").trim().slice(0, 500),
        address: String(place.address || "").trim().slice(0, 300),
        phone: String(place.phone || "").trim().slice(0, 80),
        hours: String(place.hours || "").trim().slice(0, 300),
        verificationStatus: text(place.verificationStatus || "unverified", 40),
        verifiedAt: text(place.verifiedAt, 50),
        verifiedBy: text(place.verifiedBy, 160),
        lastCheckedAt: text(place.lastCheckedAt, 50),
        sourceURL: text(place.sourceURL, 500),
        description: localized(place.description, 700),
        tastingNotes: localized(place.tastingNotes, 500),
        offerings: Array.isArray(place.offerings) ? place.offerings.slice(0, 30).map(normalizeOffering).filter(Boolean) : [],
        events: Array.isArray(place.events) ? place.events.slice(0, 30).map(normalizeEvent).filter(Boolean) : []
    }));
    if (next.some((place) => !place.id || !place.name || !place.city || !place.country)) return null;
    normalized.directory = next;
    return normalized;
}

function ratingsFor(store, email) {
    const normalized = normalizeStore(store);
    const rows = Array.isArray(normalized.ratings[email]) ? normalized.ratings[email] : [];
    return rows.slice().sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime());
}

function saveRating(store, email, input) {
    const normalized = normalizeStore(store);
    const next = normalizeRatingInput(email, input);
    if (!next) return null;
    const current = ratingsFor(normalized, email).filter((entry) => entry.offeringID !== next.offeringID);
    normalized.ratings[email] = [next, ...current].slice(0, 500);
    return next;
}

function saveEventRSVP(store, email, input) {
    const normalized = normalizeStore(store);
    const eventID = text(input?.eventID || input?.eventId, 120);
    const spotID = text(input?.spotID || input?.spotId, 100);
    if (!email || !eventID || !spotID) return null;
    const place = normalized.directory.find((entry) => entry.id === spotID);
    const event = place?.events?.find((entry) => entry.id === eventID && entry.status === "published");
    if (!event) return null;
    const current = Array.isArray(normalized.rsvps[email]) ? normalized.rsvps[email] : [];
    const existing = current.find((entry) => entry.eventID === eventID);
    if (existing) return existing;
    const record = { id: `gcmrsvp_${crypto.randomUUID()}`, eventID, spotID, startsAt: event.startsAt, createdAt: new Date().toISOString() };
    normalized.rsvps[email] = [record, ...current].slice(0, 200);
    return record;
}

function eventRSVPsFor(store, email) {
    const normalized = normalizeStore(store);
    return (Array.isArray(normalized.rsvps[email]) ? normalized.rsvps[email] : []).slice(0, 200);
}

function eventRSVPSummary(store) {
    const normalized = normalizeStore(store);
    const counts = {};
    for (const entries of Object.values(normalized.rsvps)) {
        for (const entry of Array.isArray(entries) ? entries : []) {
            if (!entry?.eventID) continue;
            counts[entry.eventID] = (counts[entry.eventID] || 0) + 1;
        }
    }
    return normalized.directory.flatMap((place) => (Array.isArray(place.events) ? place.events : []).map((event) => ({
        eventID: event.id,
        spotID: place.id,
        spotName: place.name,
        title: event.title,
        startsAt: event.startsAt,
        status: event.status,
        rsvpCount: counts[event.id] || 0
    })));
}

function aggregateRatings(store) {
    const normalized = normalizeStore(store);
    const aggregates = {};
    for (const entries of Object.values(normalized.ratings)) {
        for (const entry of Array.isArray(entries) ? entries : []) {
            if (!entry?.offeringID) continue;
            const current = aggregates[entry.offeringID] || { offeringID: entry.offeringID, count: 0, total: 0 };
            current.count += 1;
            current.total += Number(entry.rating) || 0;
            if (String(entry.note || "").trim()) current.reviewCount = (current.reviewCount || 0) + 1;
            aggregates[entry.offeringID] = current;
        }
    }
    return Object.values(aggregates).map((entry) => ({
        offeringID: entry.offeringID,
        count: entry.count,
        average: entry.count ? Math.round((entry.total / entry.count) * 10) / 10 : null,
        reviewCount: entry.reviewCount || 0
    }));
}

function publicReviews(store) {
    const normalized = normalizeStore(store);
    return Object.values(normalized.ratings).flatMap((entries) => (Array.isArray(entries) ? entries : []))
        .filter((entry) => entry?.offeringID && entry.moderationStatus !== "hidden" && String(entry.note || "").trim())
        .map((entry) => ({
            id: entry.id,
            offeringID: entry.offeringID,
            rating: entry.rating,
            note: String(entry.note).trim(),
            updatedAt: entry.updatedAt
        }))
        .sort((a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime())
        .slice(0, 500);
}

function adminRatings(store) {
    const normalized = normalizeStore(store);
    return Object.entries(normalized.ratings).flatMap(([email, entries]) =>
        (Array.isArray(entries) ? entries : []).map((entry) => ({
            ...entry,
            email,
            moderationStatus: entry.moderationStatus === "hidden" ? "hidden" : "visible"
        }))
    ).sort((left, right) => new Date(right.updatedAt).getTime() - new Date(left.updatedAt).getTime());
}

function moderateRating(store, ratingID, status, adminUsername) {
    const normalized = normalizeStore(store);
    for (const entries of Object.values(normalized.ratings)) {
        const rating = (Array.isArray(entries) ? entries : []).find((entry) => entry.id === ratingID);
        if (!rating) continue;
        rating.moderationStatus = status === "hidden" ? "hidden" : "visible";
        rating.moderatedBy = String(adminUsername || "").trim().slice(0, 160);
        rating.moderatedAt = new Date().toISOString();
        return normalized;
    }
    return null;
}

module.exports = { adminRatings, aggregateRatings, defaultDirectory, directoryFor, eventRSVPsFor, eventRSVPSummary, moderateRating, normalizeRatingInput, normalizeStore, publicReviews, ratingsFor, replaceDirectory, saveEventRSVP, saveRating };
