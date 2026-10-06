const assert = require("node:assert/strict");
const test = require("node:test");
const { createSocialCoffeeStore } = require("../modules/commerce/social-coffee-store");

test("Social Coffee persists profile and group changes in Postgres across repository instances", async () => {
    let committed = { customers: {}, groups: {} };
    const statements = [];
    const database = {
        isEnabled: () => true,
        query: async (sql) => {
            statements.push(sql);
            return { rows: [{ state: structuredClone(committed) }] };
        },
        connect: async () => {
            let pending = null;
            return {
                query: async (sql, parameters = []) => {
                    statements.push(sql);
                    if (sql.includes("FOR UPDATE")) return { rows: [{ state: structuredClone(committed) }] };
                    if (sql.startsWith("UPDATE social_coffee_state")) pending = JSON.parse(parameters[0]);
                    if (sql === "COMMIT" && pending) committed = pending;
                    return { rows: [] };
                },
                release() {}
            };
        }
    };
    const options = {
        database,
        path: "unused-json-fallback",
        readJSON: () => { throw new Error("Postgres must not read a local JSON file"); },
        writeJSON: () => { throw new Error("Postgres must not write a local JSON file"); }
    };
    const first = createSocialCoffeeStore(options);
    await first.mutate((state) => {
        state.customers["guest@example.com"] = { tastingNote: "Cardamom" };
        state.groups.group1 = { id: "group1", status: "open" };
        return { changed: true, result: true };
    });
    const afterRestart = createSocialCoffeeStore(options);
    assert.equal((await afterRestart.read()).customers["guest@example.com"].tastingNote, "Cardamom");
    assert.equal((await afterRestart.read()).groups.group1.status, "open");
    assert.ok(statements.some((sql) => sql.includes("FOR UPDATE")));

    await afterRestart.mutate((state) => {
        state.groups.group1.status = "closed";
        return { changed: true, result: null };
    });
    assert.equal((await first.read()).groups.group1.status, "closed");
});

test("Social Coffee JSON fallback remains available for local development", async () => {
    let stored = { customers: {}, groups: {} };
    const store = createSocialCoffeeStore({
        database: { isEnabled: () => false },
        path: "local-store",
        readJSON: () => structuredClone(stored),
        writeJSON: (_path, value) => { stored = structuredClone(value); }
    });
    await store.mutate((state) => {
        state.customers["local@example.com"] = { displayName: "Local" };
        return { changed: true, result: null };
    });
    assert.equal((await store.read()).customers["local@example.com"].displayName, "Local");
});

test("a failed Postgres update rolls back Social Coffee changes", async () => {
    let rolledBack = false;
    let released = false;
    const store = createSocialCoffeeStore({
        database: {
            isEnabled: () => true,
            connect: async () => ({
                query: async (sql) => {
                    if (sql.includes("FOR UPDATE")) return { rows: [{ state: { customers: {}, groups: {} } }] };
                    if (sql.startsWith("UPDATE social_coffee_state")) throw new Error("DATABASE_UNAVAILABLE");
                    if (sql === "ROLLBACK") rolledBack = true;
                    return { rows: [] };
                },
                release: () => { released = true; }
            })
        },
        path: "unused",
        readJSON: () => { throw new Error("JSON_FALLBACK_NOT_ALLOWED"); },
        writeJSON: () => { throw new Error("JSON_FALLBACK_NOT_ALLOWED"); }
    });
    await assert.rejects(store.mutate((state) => {
        state.customers["guest@example.com"] = { tastingNote: "Unsaved" };
        return { changed: true, result: null };
    }), /DATABASE_UNAVAILABLE/);
    assert.equal(rolledBack, true);
    assert.equal(released, true);
});
