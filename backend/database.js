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

    await pool.query(`
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
        const alreadyApplied = await pool.query(
            `SELECT 1
             FROM schema_migrations
             WHERE version = $1`,
            [version]
        );

        if (alreadyApplied.rowCount > 0) {
            continue;
        }

        const sql = fs.readFileSync(path.join(migrationsDirectory, fileName), "utf8");
        await pool.query("BEGIN");
        try {
            await pool.query(sql);
            await pool.query(
                `INSERT INTO schema_migrations (version, applied_at)
                 VALUES ($1, NOW())`,
                [version]
            );
            await pool.query("COMMIT");
        } catch (error) {
            await pool.query("ROLLBACK");
            throw error;
        }
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
