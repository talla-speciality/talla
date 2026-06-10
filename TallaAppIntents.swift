#if canImport(AppIntents)
import AppIntents
import Foundation

private enum TallaShortcutDestination {
    static let destinationKey = "shortcut.destination"
    static let searchQueryKey = "shortcut.searchQuery"

    static func open(_ destination: String, searchQuery: String = "") {
        let defaults = UserDefaults.standard
        defaults.set(searchQuery, forKey: searchQueryKey)
        defaults.set(destination, forKey: destinationKey)
    }
}

struct OpenTallaShopIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Talla Shop"
    static let description = IntentDescription("Opens Talla Speciality to the shop.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        TallaShortcutDestination.open("shop")
        return .result()
    }
}

struct SearchTallaProductsIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Talla Products"
    static let description = IntentDescription("Opens Talla Speciality and searches the product catalog.")
    static let openAppWhenRun = true

    @Parameter(title: "Search")
    var searchQuery: String

    @MainActor
    func perform() async throws -> some IntentResult {
        TallaShortcutDestination.open("shop", searchQuery: searchQuery)
        return .result()
    }
}

struct OpenTallaConciergeIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Coffee Concierge"
    static let description = IntentDescription("Opens the Coffee Concierge in Talla Speciality.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        TallaShortcutDestination.open("concierge")
        return .result()
    }
}

struct OpenTallaBrewingIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Brewing Guide"
    static let description = IntentDescription("Opens Talla Speciality to brewing guides and recipes.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        TallaShortcutDestination.open("brewing")
        return .result()
    }
}

struct OpenTallaRewardsIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Talla Rewards"
    static let description = IntentDescription("Opens Talla Speciality to account rewards.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        TallaShortcutDestination.open("rewards")
        return .result()
    }
}

struct TallaAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTallaShopIntent(),
            phrases: [
                "Open Talla shop in \(.applicationName)",
                "Shop Talla coffee in \(.applicationName)"
            ],
            shortTitle: "Open Shop",
            systemImageName: "bag.fill"
        )

        AppShortcut(
            intent: OpenTallaConciergeIntent(),
            phrases: [
                "Ask Coffee Concierge in \(.applicationName)",
                "Open coffee concierge in \(.applicationName)"
            ],
            shortTitle: "Coffee Concierge",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: OpenTallaBrewingIntent(),
            phrases: [
                "Open brewing guide in \(.applicationName)",
                "Show Talla brewing in \(.applicationName)"
            ],
            shortTitle: "Brewing Guide",
            systemImageName: "drop.fill"
        )

        AppShortcut(
            intent: OpenTallaRewardsIntent(),
            phrases: [
                "Open Talla rewards in \(.applicationName)",
                "Show my Talla rewards in \(.applicationName)"
            ],
            shortTitle: "Rewards",
            systemImageName: "star.circle.fill"
        )
    }
}
#endif
