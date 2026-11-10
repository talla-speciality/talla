const fs = require("fs");
const path = require("path");
const { Pool } = require("pg");

let pool = null;
const migrationsDirectory = path.join(__dirname, "migrations");

function isEnabled() {
    return Boolean(process.env.DATABASE_URL);
}

async function initializeDatabase() {
    if (!isEnabled()) {
        return false;
    }

    if (!pool) {
        pool = new Pool({
            connectionString: process.env.DATABASE_URL,
            ssl: process.env.PGSSLMODE === "disable"
                ? false
                : { rejectUnauthorized: false }
        });
    }

    const client = await pool.connect();
    try {
        // A session lock also protects the initial schema_migrations creation when
        // multiple application instances start against a new database together.
        await client.query("SELECT pg_advisory_lock(772441123)");
        try {
            await client.query(`
                CREATE TABLE IF NOT EXISTS schema_migrations (
                    version TEXT PRIMARY KEY,
                    applied_at TIMESTAMPTZ NOT NULL
                );
            `);

            const migrationFiles = fs.existsSync(migrationsDirectory)
                ? fs.readdirSync(migrationsDirectory)
                    .filter((fileName) => fileName.endsWith(".sql"))
                    .sort()
                : [];

            for (const fileName of migrationFiles) {
                const version = fileName.replace(/\.sql$/, "");
                const alreadyApplied = await client.query(
                    `SELECT 1
                     FROM schema_migrations
                     WHERE version = $1`,
                    [version]
                );
                if (alreadyApplied.rowCount > 0) continue;

                const sql = fs.readFileSync(path.join(migrationsDirectory, fileName), "utf8");
                await client.query("BEGIN");
                try {
                    await client.query(sql);
                    await client.query(
                        `INSERT INTO schema_migrations (version, applied_at)
                         VALUES ($1, NOW())`,
                        [version]
                    );
                    await client.query("COMMIT");
                } catch (error) {
                    await client.query("ROLLBACK");
                    throw error;
                }
            }
        } finally {
            await client.query("SELECT pg_advisory_unlock(772441123)");
        }
    } finally {
        client.release();
    }

    return true;
}

async function query(text, params = []) {
    if (!pool) {
        throw new Error("DATABASE_NOT_INITIALIZED");
    }

    return pool.query(text, params);
}

async function connect() {
    if (!pool) {
        throw new Error("DATABASE_NOT_INITIALIZED");
    }

    return pool.connect();
}

module.exports = {
    connect,
    initializeDatabase,
    isEnabled,
    query
};
