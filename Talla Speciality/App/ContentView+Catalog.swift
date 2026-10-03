import Foundation
import SwiftUI
import StoreKit
#if canImport(Security)
import Security
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

extension ContentView {
    var coffeePassportOrigins: [CoffeePassportOrigin] {
        guard let origins = remotePassportSettings?.origins, !origins.isEmpty else {
            return defaultCoffeePassportOrigins
        }

        return origins.map { origin in
            let detail = origin.rewardLabel?.trimmingCharacters(in: .whitespacesAndNewlines)
            return CoffeePassportOrigin(
                id: origin.id,
                title: origin.title,
                detail: (detail?.isEmpty == false ? detail : nil) ?? origin.keywords.prefix(3).joined(separator: ", "),
                symbol: origin.emoji
            )
        }
    }

    var isApplePayAvailable: Bool {
#if canImport(PassKit)
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex])
#else
        false
#endif
    }

    var isApplePaySupported: Bool {
#if canImport(PassKit)
        PKPaymentAuthorizationController.canMakePayments()
#else
        false
#endif
    }

    var cartDiscount: Double {
        if isCafePassActive { return 0 }
        if isCoffeeClubActive { return coffeeClubDiscount }
        guard let appliedVoucher else { return 0 }

        switch appliedVoucher.reward.lowercased() {
        case "free drink":
            return LoyaltyVoucherRules.freeDrinkDiscount(
                lines: cartItems.map {
                    (
                        categoryKey: $0.product.categoryKey,
                        unitPrice: customerPriceValue(from: $0.variant.price),
                        quantity: $0.quantity
                    )
                }
            )
        case "pastry pairing":
            return min(cartSubtotal, 2.000)
        case "bag discount":
            return cartSubtotal * 0.10
        case "brew bar credit":
            return min(cartSubtotal, 3.000)
        case "talla box reward":
            return cartSubtotal * 0.15
        case "roastery gold reward":
            return cartSubtotal * 0.20
        default:
            return 0
        }
    }

    var cartTotal: Double {
        max(cartSubtotal - cartDiscount, 0) + (cartShippingCost ?? 0)
    }

    var cartShipmentWeightGrams: Double? {
        cartItems.reduce(Optional(0.0)) { partialResult, item in
            guard let runningTotal = partialResult else { return nil }
            guard item.variant.requiresShipping else { return runningTotal }
            guard let weightGrams = item.variant.weightGrams, weightGrams > 0 else { return nil }
            return runningTotal + (weightGrams * Double(item.quantity))
        }
    }

    var cartShippingCost: Double? {
        if fulfillmentMethod == .pickup {
            return 0
        }
        guard let countryCode = preferredAddress?.country.rawValue else { return nil }
        if countryCode == SupportedDeliveryCountry.bahrain.rawValue {
            return shippingConfiguration.bahrainRate * Double(coffeeClubShipmentCount)
        }
        guard let weightGrams = cartShipmentWeightGrams else { return nil }
        return TallaShippingRates.rate(
            countryCode: countryCode,
            weightGrams: weightGrams,
            cashOnDelivery: paymentFlow.selectedMethod == .cashOnDelivery,
            configuration: shippingConfiguration
        ).map { $0 * Double(coffeeClubShipmentCount) }
    }

    var usesShopifyCalculatedShipping: Bool {
        fulfillmentMethod == .delivery
            && preferredAddress.map { !$0.country.isKhaleeji } == true
    }

    var canStartCheckoutWithShipping: Bool {
        if fulfillmentMethod == .pickup { return true }
        guard preferredAddress != nil else { return false }
        if usesShopifyCalculatedShipping {
            return paymentFlow.selectedMethod?.route == .shopifyCashOnDelivery
        }
        return cartShippingCost != nil
    }

    var cartCheckoutAmountText: String {
        usesShopifyCalculatedShipping
            ? AppLocalization.text("calculated_at_checkout", fallback: "Calculated at checkout")
            : formattedCustomerCurrency(cartTotal)
    }

    var cartShippingLabel: String {
        if fulfillmentMethod == .pickup {
            return AppLocalization.text("free", fallback: "Free")
        }
        guard preferredAddress != nil else {
            return AppLocalization.text("calculated_at_checkout", fallback: "Calculated at checkout")
        }
        if usesShopifyCalculatedShipping {
            return AppLocalization.text("calculated_at_shopify_checkout", fallback: "Calculated at Shopify checkout")
        }
        if let cartShippingCost {
            return formattedCustomerCurrency(cartShippingCost)
        }
        if cartShipmentWeightGrams == nil {
            return AppLocalization.text("shipping_weight_missing", fallback: "Product weight required")
        }
        return AppLocalization.text("shipping_weight_over_limit", fallback: "Over 4 kg — contact us")
    }

    var signatureRoastProducts: [Product] {
        let remoteProducts = remoteSignatureRoastProductIDs.compactMap { productID in
            products.first { $0.id == productID }
        }

        if !remoteProducts.isEmpty {
            let remoteIDs = Set(remoteProducts.map(\.id))
            let fallbackProducts = products.filter { !remoteIDs.contains($0.id) }
            return Array((remoteProducts + fallbackProducts).prefix(4))
        }

        let preferredProducts = signatureRoastProductNames.compactMap { preferredName in
            products.first { product in
                product.name.localizedCaseInsensitiveContains(preferredName)
            }
        }

        if preferredProducts.count == signatureRoastProductNames.count {
            return preferredProducts
        }

        let preferredIDs = Set(preferredProducts.map(\.id))
        let fallbackProducts = products.filter { !preferredIDs.contains($0.id) }
        return Array((preferredProducts + fallbackProducts).prefix(4))
    }

    var quickDrinkProducts: [Product] {
        let eligibleProducts = products.filter { product in
            product.categoryKey == "ready-made-drinks"
                && product.isAvailableForSale
                && selectedVariant(for: product)?.isAvailableForSale == true
        }

        guard let selectedProductIDs = remoteHomeSettings?.quickDrinkProductIDs else {
            return Array(eligibleProducts.prefix(6))
        }

        return selectedProductIDs.compactMap { productID in
            eligibleProducts.first { $0.id == productID }
        }
    }

    var surprisePickProducts: [Product] {
        products.filter { product in
            product.isAvailableForSale && selectedVariant(for: product)?.isAvailableForSale == true
        }
    }

    var surprisePickProduct: Product? {
        if let remoteFunPickID = remoteHomeSettings?.funPickProductID?.trimmingCharacters(in: .whitespacesAndNewlines),
           !remoteFunPickID.isEmpty,
           let remoteProduct = products.first(where: { $0.id == remoteFunPickID }) {
            return remoteProduct
        }

        let availableProducts = surprisePickProducts
        guard !availableProducts.isEmpty else { return nil }

        if let selectedProduct = availableProducts.first(where: { $0.id == surprisePickProductID }) {
            return selectedProduct
        }

        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return availableProducts[day % availableProducts.count]
    }

    var isLightAppearance: Bool {
        appearanceMode == .light || (appearanceMode == .system && colorScheme == .light)
    }

    var isOLEDAppearance: Bool {
        appearanceMode == .oled
    }

    var backgroundGradientColors: [Color] {
        if isLightAppearance {
            return [
                Color(hex: 0xFAF7F1),
                Color(hex: 0xF4EBDD),
                Color(hex: 0xECE0D0)
            ]
        }

        return isOLEDAppearance
            ? [.black, .black, .black]
            : [
                Color(hex: 0x080706),
                Color(hex: 0x12100D),
                Color(hex: 0x1A1511)
            ]
    }

    var primaryTextColor: Color {
        isLightAppearance ? Color(hex: 0x20150D) : Color(hex: 0xF5EDE0)
    }

    var readableBrandGoldColor: Color {
        isLightAppearance ? TallaTheme.Colors.readableAccentLight : TallaTheme.Colors.readableAccentDark
    }

    var secondaryTextColor: Color {
        primaryTextColor.opacity(isLightAppearance ? 0.72 : 0.72)
    }

    var tertiaryTextColor: Color {
        primaryTextColor.opacity(isLightAppearance ? 0.56 : 0.55)
    }

    var cardFillColor: Color {
        if isLightAppearance {
            return TallaTheme.Colors.lightSurface.opacity(0.96)
        }
        return isOLEDAppearance ? .black : TallaTheme.Colors.darkSurface.opacity(0.9)
    }

    var elevatedSurfaceColor: Color {
        if isLightAppearance {
            return TallaTheme.Colors.lightElevatedSurface
        }
        return isOLEDAppearance ? .black : TallaTheme.Colors.darkElevatedSurface
    }

    var pageBackgroundColor: Color {
        if isLightAppearance {
            return TallaTheme.Colors.lightBackground
        }
        return isOLEDAppearance ? .black : TallaTheme.Colors.darkBackground
    }

    var scrimColor: Color {
        isLightAppearance ? Color.black.opacity(0.22) : Color.black.opacity(0.6)
    }

    var isCompact: Bool {
        horizontalSizeClass != .regular
    }

    var isShortHeight: Bool {
        verticalSizeClass == .compact
    }

    var shouldShowHeaderCartButton: Bool {
        activeTab == .home || activeTab == .shop
    }

    var contentMaxWidth: CGFloat {
        isCompact ? 600 : 1120
    }

    var homeQuickActionColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? (isCompact ? 1 : 2) : (isCompact ? 2 : 4)
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    var productGridColumns: [GridItem] {
        if isCompact {
            [GridItem(.flexible(), spacing: 0)]
        } else {
            [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 300 : 200), spacing: 16)]
        }
    }

    var shopProductGridColumns: [GridItem] {
        if isCompact {
            return Array(repeating: GridItem(.flexible(), spacing: 16), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2)
        }
        return [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 300 : 200), spacing: 16)]
    }

    var collectionGridColumns: [GridItem] {
        if isCompact {
            [GridItem(.flexible(), spacing: 0)]
        } else {
            [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 300 : 200), spacing: 12)]
        }
    }

    var brewingGridColumns: [GridItem] {
        if isCompact {
            [GridItem(.flexible(), spacing: 0)]
        } else {
            [GridItem(.adaptive(minimum: dynamicTypeSize.isAccessibilitySize ? 300 : 200), spacing: 16)]
        }
    }

    var availableCategories: [ShopCategory] {
        let dynamic = Set(products.map(\.categoryKey))
        let ordered = categoryCatalog.filter { $0.key == "all" || dynamic.contains($0.key) }
        let knownKeys = Set(categoryCatalog.map(\.key))
        let extras = dynamic
            .subtracting(knownKeys)
            .sorted()
            .map(categoryDefinition(for:))

        if dynamic.isEmpty {
            return categoryCatalog.filter { $0.key == "all" }
        }

        let allCategory = ordered.filter { $0.key == "all" }.map(localizedCategory)
        let standardCategories = ordered.filter { $0.key != "all" }.map(localizedCategory) + extras
        return allCategory + seasonalEventCategories + standardCategories
    }

    var activeSeasonalEvents: [EventSettings.SeasonalEvent] {
        let now = Date()
        return (remoteEventSettings?.events ?? [])
            .filter { event in
                guard event.enabled, !event.titleEN.isEmpty else { return false }
                let startsInTime = event.startAt.flatMap(eventDate).map { $0 <= now } ?? true
                let hasNotEnded = event.endAt.flatMap(eventDate).map { $0 > now } ?? true
                return startsInTime && hasNotEnded
            }
            .sorted { left, right in
                left.priority == right.priority ? left.name < right.name : left.priority > right.priority
            }
    }

    var seasonalEventCategories: [ShopCategory] {
        let availableProductIDs = Set(products.map(\.id))
        return activeSeasonalEvents.compactMap { event in
            guard event.productIDs.contains(where: availableProductIDs.contains) else { return nil }
            return ShopCategory(
                key: eventCategoryKey(event),
                title: eventCategoryTitle(event),
                subtitle: eventCategorySubtitle(event),
                symbol: event.symbol.isEmpty ? "sparkles" : event.symbol
            )
        }
    }

    func eventCategoryKey(_ event: EventSettings.SeasonalEvent) -> String {
        "event-\(event.id)"
    }

    func eventForCategory(_ key: String) -> EventSettings.SeasonalEvent? {
        activeSeasonalEvents.first { eventCategoryKey($0) == key }
    }

    func eventText(english: String, arabic: String, fallback: String = "") -> String {
        if appLanguage.effectiveLanguageCode == "ar", !arabic.isEmpty {
            return arabic
        }
        return english.isEmpty ? fallback : english
    }

    func eventCategoryTitle(_ event: EventSettings.SeasonalEvent) -> String {
        eventText(
            english: event.categoryTitleEN.isEmpty ? event.titleEN : event.categoryTitleEN,
            arabic: event.categoryTitleAR.isEmpty ? event.titleAR : event.categoryTitleAR,
            fallback: event.name
        )
    }

    func eventCategorySubtitle(_ event: EventSettings.SeasonalEvent) -> String {
        eventText(
            english: event.categorySubtitleEN.isEmpty ? event.subtitleEN : event.categorySubtitleEN,
            arabic: event.categorySubtitleAR.isEmpty ? event.subtitleAR : event.categorySubtitleAR
        )
    }

    func eventDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    func localizedCategory(_ category: ShopCategory) -> ShopCategory {
        ShopCategory(
            key: category.key,
            title: categoryLabel(for: category.key),
            subtitle: categorySubtitle(for: category.key, fallback: category.subtitle),
            symbol: category.symbol
        )
    }

    func categorySubtitle(for key: String, fallback: String) -> String {
        switch key {
        case "all":
            return AppLocalization.text("category_all_subtitle", fallback: fallback)
        case "summer-drinks":
            return AppLocalization.text("category_summer_drinks_subtitle", fallback: fallback)
        case "coffee-beans":
            return AppLocalization.text("category_coffee_beans_subtitle", fallback: fallback)
        case "arabic-coffee-beans":
            return AppLocalization.text("category_arabic_coffee_subtitle", fallback: fallback)
        case "drip-bags":
            return AppLocalization.text("category_drip_bags_subtitle", fallback: fallback)
        case "coffee-equipment":
            return AppLocalization.text("category_equipment_subtitle", fallback: fallback)
        case "ready-made-drinks":
            return AppLocalization.text("category_ready_drinks_subtitle", fallback: fallback)
        case "cups":
            return AppLocalization.text("category_cups_subtitle", fallback: fallback)
        case "crmb-tallas-speciality-bakery", "desserts":
            return AppLocalization.text("category_desserts_subtitle", fallback: fallback)
        case "spreads":
            return AppLocalization.text("category_spreads_subtitle", fallback: fallback)
        case "hot-chocolate":
            return AppLocalization.text("category_hot_chocolate_subtitle", fallback: fallback)
        case "gifts":
            return AppLocalization.text("category_gifts_subtitle", fallback: fallback)
        default:
            return fallback
        }
    }

    var filteredProducts: [Product] {
        let categoryFilteredProducts: [Product]
        if activeCategory == "all" {
            categoryFilteredProducts = products
        } else if let event = eventForCategory(activeCategory) {
            let eventProductIDs = Set(event.productIDs)
            categoryFilteredProducts = products.filter { eventProductIDs.contains($0.id) }
        } else {
            categoryFilteredProducts = products.filter { $0.categoryKey == activeCategory }
        }
        let normalizedQuery = shopSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let searchedProducts: [Product]
        if normalizedQuery.isEmpty {
            searchedProducts = categoryFilteredProducts
        } else {
            searchedProducts = categoryFilteredProducts.filter { product in
            let variantText = product.variants
                .map { "\($0.title) \($0.price)" }
                .joined(separator: " ")
            let searchableText = [
                product.name,
                product.categoryLabel,
                product.categoryKey,
                product.desc,
                product.tag ?? "",
                variantText
            ]
            .joined(separator: " ")
            .lowercased()

            if ["available", "in stock", "ready"].contains(normalizedQuery) {
                return product.isAvailableForSale
            }
            if ["decaf", "low caffeine", "caffeine free"].contains(normalizedQuery) {
                return searchableText.contains("decaf") || searchableText.contains("caffeine free")
            }
            if normalizedQuery == "under 5" || normalizedQuery == "budget" {
                return priceValue(from: product.price) <= 5
            }
            return searchableText.contains(normalizedQuery)
            }
        }

        switch shopSortMode {
        case .featured:
            return searchedProducts
        case .priceLow:
            return searchedProducts.sorted {
                priceValue(from: $0.price) == priceValue(from: $1.price)
                    ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    : priceValue(from: $0.price) < priceValue(from: $1.price)
            }
        case .priceHigh:
            return searchedProducts.sorted {
                priceValue(from: $0.price) == priceValue(from: $1.price)
                    ? $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                    : priceValue(from: $0.price) > priceValue(from: $1.price)
            }
        case .newest:
            return searchedProducts
        case .available:
            return searchedProducts.sorted {
                if $0.isAvailableForSale != $1.isAvailableForSale {
                    return $0.isAvailableForSale && !$1.isAvailableForSale
                }

                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }
    }

    var favoriteProductIDs: Set<String> {
        Set(
            savedFavoriteProductIDs
                .split(separator: ",")
                .map { String($0) }
                .filter { !$0.isEmpty }
        )
    }

    var conciergeProducts: [Product] {
        guard let conciergeResult else { return [] }
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        return conciergeResult.productIDs.compactMap { productsByID[$0] }
    }

    var favoriteProducts: [Product] {
        products.filter { favoriteProductIDs.contains($0.id) }
    }

    var recentlyViewedProductIDs: [String] {
        savedRecentlyViewedProductIDs
            .split(separator: ",")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }

    var recentlyViewedProducts: [Product] {
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        return recentlyViewedProductIDs.compactMap { productsByID[$0] }
    }

    var recentlyViewedUnboughtProducts: [Product] {
        let orderedProductIDs = Set(orderedProducts.map(\.id))
        return recentlyViewedProducts.filter { !orderedProductIDs.contains($0.id) }
    }

    var alertProductIDs: Set<String> {
        Set(
            savedAlertProductIDs
                .split(separator: ",")
                .map { String($0) }
                .filter { !$0.isEmpty }
        )
    }

    var alertProducts: [Product] {
        products
            .filter { alertProductIDs.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.isAvailableForSale != rhs.isAvailableForSale {
                    return !lhs.isAvailableForSale && rhs.isAvailableForSale
                }

                return lhs.name < rhs.name
            }
    }

    var brewRecipes: [BrewRecipe] {
        _ = coffeeData.changeToken
        guard let data = try? JSONSerialization.data(withJSONObject: coffeeData.legacyObjects(entityType: "recipe")),
              let decoded = try? JSONDecoder().decode([BrewRecipe].self, from: data) else {
            return []
        }

        return decoded.filter { !deletedBrewRecipeIDs.contains($0.id.uuidString.lowercased()) }
    }

    var deletedBrewRecipeIDs: Set<String> {
        Set(deletedBrewRecipeIDsPayload.split(separator: ",").map { String($0).lowercased() })
    }

    var brewJournalEntries: [BrewJournalEntry] {
        _ = coffeeData.changeToken
        guard let data = try? JSONSerialization.data(withJSONObject: coffeeData.legacyObjects(entityType: "brewSession")),
              let decoded = try? JSONDecoder().decode([BrewJournalEntry].self, from: data) else {
            return []
        }

        return decoded
    }

    var stampedCoffeePassportOriginKeys: Set<String> {
        var stamps = Set<String>()

        for order in orderHistory {
            guard let items = order.items else { continue }

            for item in items {
                let product = matchingProduct(for: item.name)
                let searchableText = [
                    item.name,
                    product.map { normalizedSearchText(for: $0) } ?? ""
                ].joined(separator: " ")

                if let originKey = coffeePassportOriginKey(in: searchableText) {
                    stamps.insert(originKey)
                }
            }
        }

        return stamps
    }

    var passportProgressFraction: Double {
        guard !coffeePassportOrigins.isEmpty else { return 0 }
        return min(Double(stampedCoffeePassportOriginKeys.count) / Double(coffeePassportOrigins.count), 1)
    }

    var isCoffeePassportComplete: Bool {
        stampedCoffeePassportOriginKeys.count == coffeePassportOrigins.count
    }

    var savedCarts: [SavedCart] {
        guard let data = savedCartsPayload.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SavedCart].self, from: data) else {
            return []
        }

        return decoded
    }

    var notificationsEnabled: Bool {
#if canImport(UserNotifications)
        notificationAuthorizationStatus == UNAuthorizationStatus.authorized.rawValue
            || notificationAuthorizationStatus == UNAuthorizationStatus.provisional.rawValue
            || notificationAuthorizationStatus == UNAuthorizationStatus.ephemeral.rawValue
#else
        false
#endif
    }

    var notificationAccessDenied: Bool {
#if canImport(UserNotifications)
        notificationAuthorizationStatus == UNAuthorizationStatus.denied.rawValue
#else
        false
#endif
    }

    var notificationStatusMessage: String {
#if canImport(UserNotifications)
        switch UNAuthorizationStatus(rawValue: notificationAuthorizationStatus) {
        case .authorized, .provisional, .ephemeral:
            return AppLocalization.text("alerts_notifications_enabled_detail", fallback: "Notifications are enabled for brew timers, pickup updates, availability alerts, and important account activity.")
        case .denied:
            return AppLocalization.text("alerts_notifications_denied_detail", fallback: "Notifications are off. Open Settings to restore brew-timer, pickup, and product alerts.")
        default:
            return AppLocalization.text("alerts_notifications_disabled_detail", fallback: "Enable notifications to receive availability alerts and important account updates.")
        }
#else
        return AppLocalization.text("alerts_notifications_unavailable_detail", fallback: "Notifications are unavailable on this device.")
#endif
    }

    var canManageNotificationAccess: Bool {
#if canImport(UserNotifications)
        !notificationsEnabled
#else
        false
#endif
    }

    var pushRegistrationStatusMessage: String {
        let token = savedPushDeviceToken.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !token.isEmpty else {
            return AppLocalization.text("push_token_waiting", fallback: "No APNs device token yet. Enable notifications on a real device to create one.")
        }

        if savedRegisteredPushDeviceToken == token, !savedRegisteredPushDeviceEmail.isEmpty {
            return String(
                format: AppLocalization.text("push_token_synced", fallback: "Device token synced for %@."),
                savedRegisteredPushDeviceEmail
            )
        }

        return AppLocalization.text("push_token_local_only", fallback: "Device token is saved on this device. Sign in to sync it with the notification service.")
    }

    var backendStockAlertLookup: [String: StockAlertRecord] {
        Dictionary(uniqueKeysWithValues: backendStockAlerts.map { ($0.productID, $0) })
    }

    var preferredAddress: DeliveryAddress? {
        addresses.first(where: \.isPreferred) ?? addresses.first
    }

    var expiringVouchers: [VoucherRecord] {
        availableVouchers
            .sorted {
                (ISO8601DateFormatter().date(from: $0.expiresAt) ?? .distantFuture)
                < (ISO8601DateFormatter().date(from: $1.expiresAt) ?? .distantFuture)
            }
    }

    func rewardProgress(for points: Int) -> (current: Int, target: Int, remaining: Int, fraction: Double) {
        let threshold = max(remoteAppSettings?.loyalty?.rewardStep ?? 50, 1)
        let progress = points % threshold
        let current = progress == 0 && points > 0 ? threshold : progress
        let remaining = progress == 0 ? threshold : threshold - progress
        return (
            current: min(current, threshold),
            target: threshold,
            remaining: remaining,
            fraction: min(max(Double(current) / Double(threshold), 0), 1)
        )
    }

    func tierProgress(for points: Int) -> (label: String, current: Int, target: Int, remaining: Int, fraction: Double) {
        let silver = max(remoteAppSettings?.loyalty?.silverThreshold ?? 150, 1)
        let gold = max(remoteAppSettings?.loyalty?.goldThreshold ?? 300, silver + 1)
        if points < silver {
            let target = silver
            return (
                label: "Silver",
                current: points,
                target: target,
                remaining: target - points,
                fraction: min(max(Double(points) / Double(target), 0), 1)
            )
        }

        if points < gold {
            let current = points - silver
            let span = gold - silver
            return (
                label: "Gold",
                current: current,
                target: span,
                remaining: gold - points,
                fraction: min(max(Double(current) / Double(span), 0), 1)
            )
        }

        return (
            label: "Top Tier Unlocked",
            current: 1,
            target: 1,
            remaining: 0,
            fraction: 1
        )
    }

    var orderedProducts: [Product] {
        let orderedNames = orderHistory
            .flatMap { $0.items ?? [] }
            .map(\.name)

        var seen = Set<String>()
        return orderedNames.compactMap { itemName in
            guard let product = matchingProduct(for: itemName), !seen.contains(product.id) else { return nil }
            seen.insert(product.id)
            return product
        }
    }

    var tasteMemoryRecords: [TasteMemoryRecord] {
        guard let data = savedTasteMemory.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([TasteMemoryRecord].self, from: data) else {
            return []
        }

        return decoded
    }

    var tasteMemoryLookup: [String: TasteMemoryRecord] {
        Dictionary(uniqueKeysWithValues: tasteMemoryRecords.map { ($0.id, $0) })
    }

    var recommendedProducts: [Product] {
        let sourceProducts = favoriteProducts + recentlyViewedProducts + orderedProducts

        guard !products.isEmpty else { return [] }

        if sourceProducts.isEmpty {
            return Array(signatureRoastProducts.prefix(4))
        }

        let excludedIDs = Set(sourceProducts.map(\.id))
        let categoryWeights = sourceProducts.reduce(into: [String: Int]()) { partialResult, product in
            partialResult[product.categoryKey, default: 0] += 1
        }

        let ranked = products
            .filter { !excludedIDs.contains($0.id) }
            .sorted { lhs, rhs in
                let usePersonalization = !UserDefaults.standard.bool(forKey: "privacy.personalization.optOut")
                let lhsScore = categoryWeights[lhs.categoryKey, default: 0] + (usePersonalization ? tastePreferenceScore(for: lhs) : 0)
                let rhsScore = categoryWeights[rhs.categoryKey, default: 0] + (usePersonalization ? tastePreferenceScore(for: rhs) : 0)

                if lhsScore != rhsScore {
                    return lhsScore > rhsScore
                }

                if lhs.isAvailableForSale != rhs.isAvailableForSale {
                    return lhs.isAvailableForSale && !rhs.isAvailableForSale
                }

                return lhs.name < rhs.name
            }

        if ranked.isEmpty {
            return Array(products.prefix(4))
        }

        return Array(ranked.prefix(4))
    }

    var reorderPrompts: [ReorderPrompt] {
        let sortedOrders = orderHistory.sorted { lhs, rhs in
            orderDate(from: lhs.createdAt) > orderDate(from: rhs.createdAt)
        }
        var prompts: [ReorderPrompt] = []
        var seenProductIDs = Set<String>()

        for order in sortedOrders {
            guard let items = order.items else { continue }

            for item in items {
                if let product = matchingProduct(for: item.name), !seenProductIDs.contains(product.id) {
                    seenProductIDs.insert(product.id)
                    prompts.append(ReorderPrompt(
                        order: order,
                        product: product,
                        daysAgo: daysSinceOrder(order)
                    ))
                }
            }
        }

        return prompts
    }

    var coffeeLotRecommendations: [CoffeeLotRecommendation] {
        guard remoteAppSettings?.coffeeMemory?.enabled != false,
              remoteAppSettings?.coffeeMemory?.replacementRecommendations != false else { return [] }
        return coffeeData.beanLots().compactMap { lot in
            coffeeData.recommendation(for: lot, in: products).map {
                CoffeeLotRecommendation(lot: lot, product: $0.product, exact: $0.exact, reason: $0.reason)
            }
        }
    }

    var reorderPrompt: ReorderPrompt? {
        reorderPrompts.first
    }

    var orderBasedRecommendation: (source: Product, recommended: Product)? {
        guard let source = orderedProducts.first else { return nil }

        let sourceNotes = Set(productTasteSummary(for: source).components(separatedBy: " - "))
        let candidates = products.filter {
            $0.id != source.id &&
            !$0.name.isEmpty &&
            $0.isAvailableForSale &&
            ($0.categoryKey == source.categoryKey || $0.categoryKey == "coffee-beans" || $0.categoryKey == "arabic-coffee-beans")
        }

        let ranked = candidates.sorted { lhs, rhs in
            let lhsNotes = Set(productTasteSummary(for: lhs).components(separatedBy: " - "))
            let rhsNotes = Set(productTasteSummary(for: rhs).components(separatedBy: " - "))
            let lhsScore = sourceNotes.intersection(lhsNotes).count + (lhs.categoryKey == source.categoryKey ? 2 : 0)
            let rhsScore = sourceNotes.intersection(rhsNotes).count + (rhs.categoryKey == source.categoryKey ? 2 : 0)

            if lhsScore != rhsScore {
                return lhsScore > rhsScore
            }

            return lhs.name < rhs.name
        }

        guard let recommended = ranked.first else { return nil }
        return (source, recommended)
    }

    var displayedBrewingMethods: [BrewingMethod] {
        let source: [BrewingMethod]

        if brewingMethods.isEmpty {
            source = [
                BrewingMethod(
                    id: "fallback-pour-over",
                    name: "Pour Over",
                    summary: "Clean, articulate cups with a steady pour and a paper filter.",
                    detail: "Step-by-step brew guide",
                    symbol: "drop.fill",
                    articleURL: nil,
                    categories: ["Pour Over", "Filter"],
                    difficulty: "Intermediate",
                    brewTime: "3-4 min",
                    publishedRecipe: nil
                ),
                BrewingMethod(
                    id: "fallback-french-press",
                    name: "French Press",
                    summary: "A fuller-bodied brew with a deeper texture and round finish.",
                    detail: "Step-by-step brew guide",
                    symbol: "cup.and.saucer.fill",
                    articleURL: nil,
                    categories: ["Immersion"],
                    difficulty: "Easy",
                    brewTime: "4 min",
                    publishedRecipe: nil
                ),
                BrewingMethod(
                    id: "fallback-chemex",
                    name: "Chemex",
                    summary: "Bright clarity and delicate texture for clean specialty cups.",
                    detail: "Step-by-step brew guide",
                    symbol: "flask.fill",
                    articleURL: nil,
                    categories: ["Pour Over", "Filter"],
                    difficulty: "Intermediate",
                    brewTime: "4-5 min",
                    publishedRecipe: nil
                ),
                BrewingMethod(
                    id: "fallback-arabic-coffee",
                    name: "Arabic Coffee",
                    summary: "A fragrant traditional brew with spice, depth, and a long finish.",
                    detail: "Step-by-step brew guide",
                    symbol: "flame.fill",
                    articleURL: nil,
                    categories: ["Traditional"],
                    difficulty: "Intermediate",
                    brewTime: "8 min",
                    publishedRecipe: nil
                ),
                BrewingMethod(
                    id: "fallback-cold-brew",
                    name: "Cold Brew",
                    summary: "Slow extraction for a smooth, chilled cup with low acidity.",
                    detail: "Step-by-step brew guide",
                    symbol: "snowflake",
                    articleURL: nil,
                    categories: ["Cold Brew"],
                    difficulty: "Easy",
                    brewTime: "12 hr",
                    publishedRecipe: nil
                )
            ]
        } else {
            source = brewingMethods
        }

        guard activeBrewingCategory != "All" else {
            return source
        }

        return source.filter { $0.categories.contains(activeBrewingCategory) }
    }

    var brewingCategories: [String] {
        let source = brewingMethods.isEmpty ? displayedBrewingMethods : brewingMethods
        let categories = Set(source.flatMap(\.categories))
        let preferredOrder = ["Pour Over", "Immersion", "Traditional", "Cold Brew"]
        return ["All"] + preferredOrder.filter { categories.contains($0) }
    }

    var ratioCoffeeAmount: Double {
        Double(ratioCoffeeInput.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var ratioValue: Double {
        Double(ratioValueInput.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var calculatedWaterAmount: Double {
        ratioCoffeeAmount * ratioValue
    }

    var brewAgainHistoryItems: [BrewRecipeRecord] {
        let journalItems = brewJournalEntries.compactMap { entry -> BrewRecipeRecord? in
            guard let coffeeGrams = entry.coffeeGrams,
                  let ratio = entry.ratio else {
                return nil
            }

            return BrewRecipeRecord(
                id: entry.id,
                title: entry.title,
                detail: "\(entry.method) - \(formattedRatioValue(coffeeGrams)) g - 1:\(formattedRatioValue(ratio)) - Rated \(entry.rating)/5",
                coffeeGrams: coffeeGrams,
                ratio: ratio,
                totalWaterGrams: entry.waterGrams,
                brewingWaterGrams: entry.waterGrams,
                iceGrams: nil,
                methodID: nil,
                brewerID: nil,
                brewMode: nil,
                bloomRatio: nil,
                pourCount: nil,
                grind: nil,
                temperatureC: nil,
                controlMode: nil
            )
        }

        let recipeItems = brewRecipes.map { recipe in
            BrewRecipeRecord(
                id: recipe.id,
                title: recipe.name,
                detail: "\(recipe.category) - \(formattedRatioValue(recipe.coffeeGrams)) g - 1:\(formattedRatioValue(recipe.ratio))",
                coffeeGrams: recipe.coffeeGrams,
                ratio: recipe.ratio,
                totalWaterGrams: recipe.waterGrams,
                brewingWaterGrams: recipe.brewingWaterGrams,
                iceGrams: recipe.iceGrams,
                methodID: recipe.methodID,
                brewerID: recipe.brewerID,
                brewMode: recipe.brewMode,
                bloomRatio: recipe.bloomRatio,
                pourCount: recipe.pourCount,
                grind: recipe.grind,
                temperatureC: recipe.temperatureC,
                controlMode: recipe.controlMode,
                process: recipe.process,
                roast: recipe.roast,
                grinder: recipe.grinder,
                filter: recipe.filter,
                altitudeMeters: recipe.altitudeMeters,
                tastingNotes: recipe.tastingNotes,
                targetTimeRange: recipe.targetTimeRange,
                temperatureReason: recipe.temperatureReason,
                expectedCup: recipe.expectedCup,
                approach: recipe.approach,
                steps: recipe.steps
            )
        }

        return Array((recipeItems + journalItems).prefix(6))
    }

    var loyaltyPerks: [String] {
        loyaltyAccount?.perks ?? [
            "Collect Beans across coffees, beans, and accessories",
            "Unlock seasonal offers and complimentary extras"
        ]
    }

    var checkoutReadinessTitle: String {
        fulfillmentMethod == .delivery && preferredAddress == nil
            ? AppLocalization.text("almost_ready", fallback: "Almost ready")
            : AppLocalization.text("ready_to_checkout_checked", fallback: "Ready to checkout ✓")
    }

    var checkoutReadinessSummary: String {
        let itemKey = cartCount == 1 ? "cart_item_count_singular" : "cart_item_count_plural"
        let itemFallback = cartCount == 1 ? "%d item" : "%d items"
        let itemText = String(format: AppLocalization.text(itemKey, fallback: itemFallback), cartCount)
        let addressText: String
        if fulfillmentMethod == .pickup {
            addressText = AppLocalization.text("pickup_at_talla", fallback: "Pickup at Talla")
        } else {
            addressText = preferredAddress == nil
                ? AppLocalization.text("delivery_address_needed_short", fallback: "Delivery address needed")
                : AppLocalization.text("address_saved", fallback: "Address saved")
        }

        return "\(itemText) · \(addressText)"
    }

    var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var shouldShowFeatureTour: Bool {
        hasSeenWelcome && !hasSeenFeatureTour && !showLaunchSplash
    }

    var featureTourHighlights: [FeatureTourHighlight] {
        [
            FeatureTourHighlight(
                id: "find-your-talla",
                icon: "sparkles",
                title: AppLocalization.text("tour_find_talla_title", fallback: "Find Your Talla"),
                detail: AppLocalization.text("tour_find_talla_detail", fallback: "Discover a coffee through three quick questions.")
            ),
            FeatureTourHighlight(
                id: "guided-brew",
                icon: "drop.fill",
                title: AppLocalization.text("tour_guided_brew_title", fallback: "Guided Brew"),
                detail: AppLocalization.text("tour_guided_brew_detail", fallback: "Follow each pour with live targets and a focused timer.")
            ),
            FeatureTourHighlight(
                id: "talla-passport",
                icon: "book.closed.fill",
                title: AppLocalization.text("tour_passport_title", fallback: "Talla Passport"),
                detail: AppLocalization.text("tour_passport_detail", fallback: "Collect origins and unlock rewards as you explore.")
            )
        ]
    }
}
