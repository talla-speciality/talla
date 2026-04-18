const database = require("./database");

async function main() {
    const applied = await database.initializeDatabase();
    if (!applied) {
        console.log("DATABASE_URL is not set. Skipping migrations.");
        return;
    }

    console.log("Database migrations are up to date.");
}

main().catch((error) => {
    console.error("Migration failed.");
    console.error(error);
    process.exit(1);
});
