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

function publicCoffeeRecord(row) {
    return {
        entityType: row.entity_type,
        id: String(row.record_id).toLowerCase(),
        payload: row.payload || {},
        revision: Number(row.revision),
        updatedAt: new Date(row.updated_at).toISOString(),
        deletedAt: row.deleted_at ? new Date(row.deleted_at).toISOString() : null
    };
}

function createCoffeeSyncService(database) {
    if (!database || typeof database.connect !== "function") {
        throw new TypeError("Coffee sync requires a database connection provider.");
    }

    return async function synchronizeCoffeeRecords(email, deviceID, requestedCursor, submittedChanges) {
        const cursor = /^\d+$/.test(String(requestedCursor || "")) ? Number(requestedCursor) : 0;
        const changes = (Array.isArray(submittedChanges) ? submittedChanges : []).map(normalizeCoffeeChange);
        if (changes.some((change) => !change) || changes.length > 2_000) {
            const error = new Error("INVALID_COFFEE_SYNC_PAYLOAD");
            error.statusCode = 400;
            throw error;
        }

        const client = await database.connect();
        const conflicts = [];
        const conflictRecords = new Map();
        try {
            await client.query("BEGIN");
            for (const change of changes) {
                const currentResult = await client.query(
                    `SELECT entity_type, record_id, payload, revision, updated_at, deleted_at
                     FROM coffee_records WHERE email=$1 AND entity_type=$2 AND record_id=$3 FOR UPDATE`,
                    [email, change.entityType, change.id]
                );
                const current = currentResult.rows[0] || null;
                if (hasRevisionConflict(current ? current.revision : null, change.baseRevision)) {
                    const key = `${change.entityType}:${change.id}`;
                    conflicts.push({ entityType: change.entityType, id: change.id, serverRevision: Number(current.revision) });
                    conflictRecords.set(key, publicCoffeeRecord(current));
                    continue;
                }
                await client.query(
                    `INSERT INTO coffee_records
                        (email, entity_type, record_id, payload, revision, updated_at, deleted_at, updated_by_device, sync_cursor)
                     VALUES ($1,$2,$3,$4::jsonb,1,NOW(),$5,$6,nextval('coffee_sync_cursor_seq'))
                     ON CONFLICT (email, entity_type, record_id) DO UPDATE SET
                        payload=EXCLUDED.payload, revision=coffee_records.revision+1, updated_at=NOW(),
                        deleted_at=EXCLUDED.deleted_at, updated_by_device=EXCLUDED.updated_by_device,
                        sync_cursor=nextval('coffee_sync_cursor_seq')`,
                    [email, change.entityType, change.id, JSON.stringify(change.payload), change.deletedAt, deviceID]
                );
            }
            const delta = await client.query(
                `SELECT entity_type, record_id, payload, revision, updated_at, deleted_at, sync_cursor
                 FROM coffee_records WHERE email=$1 AND sync_cursor>$2 ORDER BY sync_cursor ASC LIMIT 2000`,
                [email, cursor]
            );
            await client.query("COMMIT");
            const recordsByKey = new Map(delta.rows.map((row) => [
                `${row.entity_type}:${String(row.record_id).toLowerCase()}`,
                publicCoffeeRecord(row)
            ]));
            for (const [key, record] of conflictRecords) recordsByKey.set(key, record);
            const nextCursor = delta.rows.length
                ? String(delta.rows[delta.rows.length - 1].sync_cursor)
                : String(cursor);
            return {
                cursor: nextCursor,
                records: [...recordsByKey.values()],
                conflicts,
                hasMore: delta.rows.length === 2_000
            };
        } catch (error) {
            await client.query("ROLLBACK");
            throw error;
        } finally {
            client.release();
        }
    };
}

module.exports = {
    allowedEntityTypes,
    createCoffeeSyncService,
    hasRevisionConflict,
    normalizeCoffeeChange,
    publicCoffeeRecord
};
