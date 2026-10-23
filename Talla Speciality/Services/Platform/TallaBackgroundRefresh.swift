import Foundation
#if canImport(BackgroundTasks)
import BackgroundTasks
#endif

/// Schedules lightweight catalog/config refreshes while the app is not active.
/// iOS decides the actual execution time; this is an opportunity, not a guarantee.
enum TallaBackgroundRefresh {
    static let taskIdentifier = "Talla-Speciality.catalog-refresh"
    private static let lastRefreshKey = "background.catalogRefreshAt"

    static func register() {
#if canImport(BackgroundTasks) && os(iOS)
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }

            schedule()
            let refresh = Task {
                await performRefresh()
            }

            refreshTask.expirationHandler = {
                refresh.cancel()
            }

            Task {
                let success = await refresh.value
                refreshTask.setTaskCompleted(success: success)
            }
        }
#endif
    }

    static func schedule() {
#if canImport(BackgroundTasks) && os(iOS)
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
#if DEBUG
            print("Background refresh scheduling failed: \(error.localizedDescription)")
#endif
        }
#endif
    }

    private static func performRefresh() async -> Bool {
        do {
            // Keep this lightweight: the app already owns the full catalog lifecycle.
            let languageCode = AppLocalization.currentLanguage.effectiveLanguageCode
            let products = try await ShopifyStorefrontClient.fetchAllProducts(languageCode: languageCode)
            try Task.checkCancellation()
            try TallaCatalogCache.save(products, languageCode: languageCode)
            let settingsData = try await HomeSettingsService.fetchAppSettingsData()
            try TallaRemoteSettingsCache.saveAppSettings(settingsData)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastRefreshKey)
            return true
        } catch {
#if DEBUG
            print("Background refresh failed: \(error.localizedDescription)")
#endif
            return false
        }
    }
}

enum TallaCatalogCache {
    static let appGroupID = "group.Talla-Speciality.Talla-Speciality"
    // The legacy untagged cache cannot be safely assigned to either language.
    private static func fileURL(languageCode: String, directory: URL?) -> URL? {
        let container = directory ?? FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        )
        let language = languageCode == "ar" ? "ar" : "en"
        return container?.appendingPathComponent("catalog-products-\(language).json")
    }

    static func save(_ products: [ContentView.Product], languageCode: String, directory: URL? = nil) throws {
        guard let url = fileURL(languageCode: languageCode, directory: directory) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let data = try JSONEncoder().encode(products)
        try data.write(to: url, options: .atomic)
    }

    static func load(languageCode: String, directory: URL? = nil) -> [ContentView.Product]? {
        guard let url = fileURL(languageCode: languageCode, directory: directory),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([ContentView.Product].self, from: data)
    }
}

enum TallaRemoteSettingsCache {
    static let appGroupID = "group.Talla-Speciality.Talla-Speciality"
    private static let appSettingsFileName = "app-settings.json"

    static func saveAppSettings(_ data: Data) throws {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }

        try data.write(to: containerURL.appendingPathComponent(appSettingsFileName), options: .atomic)
    }

    static func loadAppSettings() -> Data? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else { return nil }

        return try? Data(contentsOf: containerURL.appendingPathComponent(appSettingsFileName))
    }
}
