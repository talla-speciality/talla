import Foundation
#if canImport(Security)
import Security
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif

enum TallaAccountCredentialStore {
    static let tokenDefaultsKey = "local.customerAccessToken"
    static let keychainService = "Talla-Speciality.customer-session"
    static let keychainAccount = "current"
    static let refreshKeychainAccount = "refresh"

    static var accessToken: String {
        #if DEBUG
        if let testToken = ProcessInfo.processInfo.environment["TALLA_UI_TEST_ACCESS_TOKEN"]?.trimmingCharacters(in: .whitespacesAndNewlines), !testToken.isEmpty { return testToken }
        #endif
        if let keychainToken = readFromKeychain(account: keychainAccount)?.trimmingCharacters(in: .whitespacesAndNewlines), !keychainToken.isEmpty {
            if UserDefaults.standard.object(forKey: tokenDefaultsKey) != nil { UserDefaults.standard.removeObject(forKey: tokenDefaultsKey) }
            return keychainToken
        }
        let legacyToken = UserDefaults.standard.string(forKey: tokenDefaultsKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !legacyToken.isEmpty else { return "" }
        saveToKeychain(legacyToken, account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: tokenDefaultsKey)
        return legacyToken
    }

    static func save(_ token: String) {
        let normalizedToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedToken.isEmpty else { clear(); return }
        saveToKeychain(normalizedToken, account: keychainAccount)
        UserDefaults.standard.removeObject(forKey: tokenDefaultsKey)
    }

    static var refreshToken: String {
        #if DEBUG
        if let testToken = ProcessInfo.processInfo.environment["TALLA_UI_TEST_REFRESH_TOKEN"]?.trimmingCharacters(in: .whitespacesAndNewlines), !testToken.isEmpty { return testToken }
        #endif
        return readFromKeychain(account: refreshKeychainAccount)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    static func save(accessToken: String, refreshToken: String) {
        save(accessToken)
        let normalizedRefreshToken = refreshToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalizedRefreshToken.isEmpty { deleteFromKeychain(account: refreshKeychainAccount) } else { saveToKeychain(normalizedRefreshToken, account: refreshKeychainAccount) }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: tokenDefaultsKey)
        deleteFromKeychain(account: keychainAccount)
        deleteFromKeychain(account: refreshKeychainAccount)
    }

    static func deleteFromKeychain(account: String) {
        #if canImport(Security)
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: keychainService, kSecAttrAccount: account, kSecAttrSynchronizable: kSecAttrSynchronizableAny]
        SecItemDelete(query as CFDictionary)
        #endif
    }

    static func readFromKeychain(account: String) -> String? {
        #if canImport(Security)
        let query: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: keychainService, kSecAttrAccount: account, kSecAttrSynchronizable: kSecAttrSynchronizableAny, kSecMatchLimit: kSecMatchLimitOne, kSecReturnData: true]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
        #else
        return nil
        #endif
    }

    static func saveToKeychain(_ token: String, account: String) {
        #if canImport(Security)
        let lookup: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: keychainService, kSecAttrAccount: account, kSecAttrSynchronizable: kSecAttrSynchronizableAny]
        let attributes: [CFString: Any] = [kSecValueData: Data(token.utf8), kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock]
        let status = SecItemUpdate(lookup as CFDictionary, attributes as CFDictionary)
        guard status == errSecItemNotFound else { return }
        let item: [CFString: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: keychainService, kSecAttrAccount: account, kSecValueData: Data(token.utf8), kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock]
        SecItemAdd(item as CFDictionary, nil)
        #endif
    }
}

enum LoyaltyVoucherRules {
    static let freeDrinkCategoryKeys: Set<String> = ["ready-made-drinks"]
    static func isFreeDrink(_ reward: String) -> Bool { reward.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "free drink" }
    static func freeDrinkDiscount(lines: [(categoryKey: String, unitPrice: Double, quantity: Int)]) -> Double {
        lines.filter { $0.quantity > 0 && freeDrinkCategoryKeys.contains($0.categoryKey) }.map(\.unitPrice).max() ?? 0
    }
}

enum AppWidgetSharedState {
    static let appGroupID = "group.Talla-Speciality.Talla-Speciality"
    static let widgetKind = "com.talla.speciality.quick-actions"
    static let loyaltyEmailKey = "loyalty.email"
    static let favoriteProductIDsKey = "favorites.productIDs"
    static let recentlyViewedProductIDsKey = "recentlyViewed.productIDs"
    static let savedCartsKey = "carts.saved"
    static let favoriteCountKey = "widget.favoriteCount"
    static let recentCountKey = "widget.recentCount"
    static let savedCartCountKey = "widget.savedCartCount"
    static let languageKey = "app.language"
    static let loyaltyPointsKey = "watch.loyalty.points"
    static let loyaltyTierKey = "watch.loyalty.tier"
    static let loyaltyNextRewardKey = "watch.loyalty.nextReward"
    static let loyaltyMemberIDKey = "watch.loyalty.memberID"
    static let lastUpdatedKey = "widget.lastUpdated"
    static var defaults: UserDefaults { UserDefaults(suiteName: appGroupID) ?? .standard }
    static func reloadWidget() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        #endif
    }
}
