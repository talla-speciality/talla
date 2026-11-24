function createServerRuntime({
    config,
    database,
    getAppSettings,
    startOpsAlertMonitor,
    startCoffeeClubReminderMonitor,
    startBirthdayRewardMonitor,
    server,
    port,
    host
}) {
    return async function startServer() {
        if (!database.isEnabled()) {
            await getAppSettings();
            startCoffeeClubReminderMonitor();
            startBirthdayRewardMonitor();
            server.listen(port, host, () => {
                console.log(`Talla backend listening on ${config.appURL} (${host}:${port})`);
            });
            return;
        }

        try {
            await database.initializeDatabase();
            await getAppSettings();
            console.log("Postgres storage enabled for accounts, loyalty, and Social Coffee.");
            startOpsAlertMonitor();
            startCoffeeClubReminderMonitor();
            startBirthdayRewardMonitor();
            server.listen(port, host, () => {
                console.log(`Talla backend listening on ${config.appURL} (${host}:${port})`);
            });
        } catch (error) {
            console.error("Failed to initialize Postgres storage.", error);
            process.exit(1);
        }
    };
}

module.exports = { createServerRuntime };
