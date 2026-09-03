const allowedEntityTypes = new Set([
    "coffeeLot", "purchasedCoffee", "equipment", "calibration", "recipe",
    "recipeVersion", "brewSession", "sample", "tasteFeedback", "maintenance"
]);

function normalizeCoffeeChange(value) {
    if (!value || typeof value !== "object" || Array.isArray(value)) return null;
    const entityType = String(value.entityType || "").trim();
    const id = String(value.id || "").trim().toLowerCase();
    const payload = value.payload && typeof value.payload === "object" && !Array.isArray(value.payload) ? value.payload : {};
    const baseRevision = Number(value.baseRevision || 0);
    const deletedAt = value.deletedAt ? new Date(value.deletedAt) : null;
    if (!allowedEntityTypes.has(entityType) || !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/.test(id)) return null;
    if (!Number.isSafeInteger(baseRevision) || baseRevision < 0) return null;
    if (deletedAt && !Number.isFinite(deletedAt.getTime())) return null;
    if (Buffer.byteLength(JSON.stringify(payload), "utf8") > 512_000) return null;
    return { entityType, id, payload, baseRevision, deletedAt: deletedAt?.toISOString() || null };
}

function hasRevisionConflict(currentRevision, baseRevision) {
    return currentRevision !== null && Number(currentRevision) !== Number(baseRevision);
}

module.exports = { allowedEntityTypes, hasRevisionConflict, normalizeCoffeeChange };
