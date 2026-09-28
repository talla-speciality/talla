const crypto = require("crypto");

function text(value, limit) {
    return String(value || "").trim().slice(0, limit);
}

function number(value, fallback, minimum, maximum) {
    const parsed = Number(value);
    if (!Number.isFinite(parsed)) return fallback;
    return Math.min(maximum, Math.max(minimum, parsed));
}

function list(value, limit, itemLimit) {
    return Array.isArray(value) ? value.map((item) => text(item, itemLimit)).filter(Boolean).slice(0, limit) : [];
}

function newID(prefix) {
    return `${prefix}_${Date.now()}_${crypto.randomBytes(5).toString("hex")}`;
}

function normalizeProfile(body, ownerEmail) {
    const title = text(body.title, 120);
    const machine = text(body.machine, 120);
    if (!title || !machine) return null;
    return {
        id: text(body.id, 160) || newID("espresso_profile"),
        title,
        machine,
        doseGrams: number(body.doseGrams, 18, 1, 60),
        yieldGrams: number(body.yieldGrams, 36, 1, 150),
        temperatureC: number(body.temperatureC, 93, 80, 105),
        pressureBar: body.pressureBar == null ? null : number(body.pressureBar, 9, 0, 20),
        grindSetting: text(body.grindSetting, 120),
        notes: text(body.notes, 1_000),
        author: text(body.author, 80) || ownerEmail.split("@")[0],
        equipmentTags: list(body.equipmentTags, 12, 60),
        ownerEmail,
        status: "pending",
        createdAt: new Date().toISOString()
    };
}

function normalizeRoasterRecipe(body, publisherEmail) {
    const title = text(body.title, 120);
    const roaster = text(body.roaster, 120);
    const coffeeName = text(body.coffeeName, 160);
    if (!title || !roaster || !coffeeName) return null;
    return {
        id: text(body.id, 160) || newID("roaster_recipe"),
        title,
        roaster,
        coffeeName,
        doseGrams: number(body.doseGrams, 18, 1, 60),
        yieldGrams: number(body.yieldGrams, 36, 1, 150),
        temperatureC: number(body.temperatureC, 93, 80, 105),
        grindSetting: text(body.grindSetting, 120),
        sourceURL: text(body.sourceURL, 500),
        publisherEmail,
        status: "pending",
        publishedAt: new Date().toISOString()
    };
}

function visibleCommunity(store, ownerEmail, equipment) {
    const matchesEquipment = (item) => !equipment
        || item.machine === equipment
        || item.equipment === equipment
        || item.profile?.machine === equipment
        || (item.equipmentTags || []).includes(equipment)
        || (item.profile?.equipmentTags || []).includes(equipment);
    return {
        profiles: (Array.isArray(store.profiles) ? store.profiles : [])
            .filter((item) => (item.status === "approved" && matchesEquipment(item)) || item.ownerEmail === ownerEmail),
        roasterRecipes: (Array.isArray(store.roasterRecipes) ? store.roasterRecipes : [])
            .filter((item) => item.status === "approved"),
        startingPoints: (Array.isArray(store.startingPoints) ? store.startingPoints : [])
            .filter(matchesEquipment),
        videoAssessments: (Array.isArray(store.videoAssessments) ? store.videoAssessments : [])
            .filter((item) => item.ownerEmail === ownerEmail)
    };
}

module.exports = { normalizeProfile, normalizeRoasterRecipe, visibleCommunity };
