function normalizeState(value) {
    const state = value && typeof value === "object" ? value : {};
    return {
        ...state,
        customers: state.customers && typeof state.customers === "object" ? state.customers : {},
        groups: state.groups && typeof state.groups === "object" ? state.groups : {}
    };
}

function createSocialCoffeeStore({ database, path, readJSON, writeJSON }) {
    const databaseEnabled = () => database?.isEnabled?.() === true;

    async function read() {
        if (!databaseEnabled()) return normalizeState(readJSON(path));
        const result = await database.query("SELECT state FROM social_coffee_state WHERE id = 1");
        return normalizeState(result.rows[0]?.state);
    }

    async function mutate(change) {
        if (!databaseEnabled()) {
            const state = normalizeState(readJSON(path));
            const outcome = change(state);
            if (outcome.changed) writeJSON(path, state);
            return outcome.result;
        }

        const client = await database.connect();
        try {
            await client.query("BEGIN");
            const result = await client.query("SELECT state FROM social_coffee_state WHERE id = 1 FOR UPDATE");
            if (!result.rows.length) throw new Error("SOCIAL_COFFEE_MIGRATION_MISSING");
            const state = normalizeState(result.rows[0].state);
            const outcome = change(state);
            if (outcome.changed) {
                await client.query(
                    "UPDATE social_coffee_state SET state = $1::jsonb, updated_at = NOW() WHERE id = 1",
                    [JSON.stringify(state)]
                );
            }
            await client.query("COMMIT");
            return outcome.result;
        } catch (error) {
            await client.query("ROLLBACK");
            throw error;
        } finally {
            client.release();
        }
    }

    return { read, mutate };
}

module.exports = { createSocialCoffeeStore };
