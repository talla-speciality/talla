import Foundation
import SwiftUI
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    private enum Tab: String, CaseIterable {
        case home
        case shop
        case brewing
        case account

        var systemImage: String {
            switch self {
            case .home:
                return "house.fill"
            case .shop:
                return "square.grid.2x2.fill"
            case .brewing:
                return "drop.fill"
            case .account:
                return "person.fill"
            }
        }
    }

    private enum AppearanceMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system:
                return "System"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system:
                return nil
            case .light:
                return .light
            case .dark:
                return .dark
            }
        }
    }

    struct Product: Identifiable, Hashable {
        let id: String
        let variantID: String?
        let name: String
        let price: String
        let categoryKey: String
        let categoryLabel: String
        let imageURL: URL?
        let desc: String
        let tag: String?
        let isAvailableForSale: Bool
    }

    struct BrewingMethod: Identifiable, Hashable {
        let id: String
        let name: String
        let summary: String
        let detail: String
        let symbol: String
        let articleURL: URL?
        let categories: [String]
        let difficulty: String
        let brewTime: String
    }

    struct ShopCategory: Identifiable, Hashable {
        let key: String
        let title: String
        let subtitle: String
        let symbol: String

        var id: String { key }
    }

    private struct CartItem: Identifiable, Hashable {
        let id: String
        let product: Product
        var quantity: Int
    }

    private struct CheckoutSession: Identifiable {
        let id = UUID()
        let url: URL
    }

    struct LoyaltyAccount: Codable {
        struct Transaction: Codable, Identifiable {
            let id: String
            let type: String
            let points: Int
            let note: String
            let voucherCode: String?
            let voucherDetail: String?
            let voucherExpiresAt: String?
            let voucherSingleUse: Bool?
            let voucherStatus: String?
            let createdAt: String
        }

        let memberID: String
        let pointsBalance: Int
        let tier: String
        let nextReward: String
        let perks: [String]
        let transactions: [Transaction]
    }

    struct ShopifyCustomerProfile {
        let id: String
        let firstName: String?
        let lastName: String?
        let email: String

        var displayName: String {
            let fullName = [firstName, lastName]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            return fullName.isEmpty ? email : fullName
        }
    }

    struct AccountOrder: Decodable, Identifiable {
        struct Item: Decodable, Identifiable {
            var id: String { "\(name)-\(quantity)" }

            let name: String
            let quantity: Int
        }

        let id: String
        let title: String
        let total: String
        let status: String
        let items: [Item]?
        let createdAt: String
    }

    struct VoucherRecord: Codable, Identifiable {
        var id: String { code }

        let code: String
        let email: String
        let reward: String
        let points: Int
        let detail: String
        let singleUse: Bool
        let status: String
        let createdAt: String
        let expiresAt: String
    }

    private struct SavedCart: Codable, Identifiable {
        struct Item: Codable, Identifiable {
            var id: String { productID }

            let productID: String
            let productName: String
            let quantity: Int
        }

        let id: UUID
        let name: String
        let items: [Item]
        let createdAt: String
    }

    struct StockAlertRecord: Codable, Identifiable {
        var id: String { productID }

        let productID: String
        let productName: String
        let tag: String?
        let isAvailableForSale: Bool
        let status: String
        let updatedAt: String
    }

    struct DeliveryAddress: Codable, Identifiable {
        let id: String
        let label: String
        let fullName: String
        let phone: String
        let line1: String
        let city: String
        let notes: String?
        let isPreferred: Bool
    }

    struct AlertInboxRecord: Codable, Identifiable {
        let id: String
        let title: String
        let detail: String
        let createdAt: String
        let productID: String?
    }

    private struct BrewRecipe: Codable, Identifiable {
        let id: UUID
        let name: String
        let coffeeGrams: Double
        let ratio: Double
        let waterGrams: Double
        let category: String
        let createdAt: String
    }

    enum AccountAuthMode: String {
        case signIn
        case createAccount
        case changePassword
    }

    enum LoyaltyServiceError: LocalizedError {
        case missingAccount
        case insufficientPoints
        case operationFailed(String)

        var errorDescription: String? {
            switch self {
            case .missingAccount:
                return "We couldn't find a rewards account for that email."
            case .insufficientPoints:
                return "You don't have enough points for that reward yet."
            case .operationFailed(let message):
                return message
            }
        }
    }

#if canImport(PassKit)
    private struct WalletPassItem: Identifiable {
        let id = UUID()
        let pass: PKPass
    }
#endif

    @State private var activeTab: Tab = .home
    @State private var activeCategory = "all"
    @State private var products: [Product] = []
    @State private var cartItems: [CartItem] = []
    @State private var cartOpen = false
    @State private var toastMessage: String?
    @State private var isLoadingProducts = false
    @State private var hasLoadedProducts = false
    @State private var loadingError: String?
    @State private var brewingMethods: [BrewingMethod] = []
    @State private var isLoadingBrewingMethods = false
    @State private var hasLoadedBrewingMethods = false
    @State private var brewingMethodsError: String?
    @State private var activeBrewingCategory = "All"
    @State private var ratioCoffeeInput = "20"
    @State private var ratioValueInput = "16"
    @State private var brewRecipeName = ""
    @State private var cartSaveName = ""
    @State private var isCheckingOut = false
    @State private var checkoutError: String?
    @State private var checkoutSession: CheckoutSession?
    @State private var articleSession: CheckoutSession?
    @State private var selectedProduct: Product?
    @State private var voucherCodeInput = ""
    @State private var appliedVoucher: VoucherRecord?
    @State private var isApplyingVoucher = false
    @State private var voucherError: String?
    @State private var availableVouchers: [VoucherRecord] = []
    @State private var isLoadingAvailableVouchers = false
    @AppStorage("app.appearanceMode") private var savedAppearanceMode = AppearanceMode.system.rawValue
    @AppStorage("local.customerEmail") private var savedCustomerEmail = ""
    @AppStorage("local.customerAccessToken") private var savedCustomerAccessToken = ""
    @AppStorage("loyalty.email") private var savedLoyaltyEmail = ""
    @AppStorage("favorites.productIDs") private var savedFavoriteProductIDs = ""
    @AppStorage("recentlyViewed.productIDs") private var savedRecentlyViewedProductIDs = ""
    @AppStorage("alerts.productIDs") private var savedAlertProductIDs = ""
    @AppStorage("brewRecipes.saved") private var savedBrewRecipes = ""
    @AppStorage("carts.saved") private var savedCartsPayload = ""
    @State private var notificationAuthorizationStatus: Int = 0
    @State private var accountAuthMode: AccountAuthMode = .signIn
    @State private var accountFirstName = ""
    @State private var accountLastName = ""
    @State private var accountEmail = ""
    @State private var accountPassword = ""
    @State private var accountConfirmPassword = ""
    @State private var profileFirstName = ""
    @State private var profileLastName = ""
    @State private var isSavingProfile = false
    @State private var currentPasswordInput = ""
    @State private var newPasswordInput = ""
    @State private var confirmNewPasswordInput = ""
    @State private var isResettingPassword = false
    @State private var isRequestingPasswordResetLink = false
    @State private var customerProfile: ShopifyCustomerProfile?
    @State private var customerAuthError: String?
    @State private var isSigningIn = false
    @State private var isCreatingAccount = false
    @State private var isLoadingCustomer = false
    @State private var orderHistory: [AccountOrder] = []
    @State private var isLoadingOrders = false
    @State private var ordersError: String?
    @State private var isRecordingSampleOrder = false
    @State private var backendStockAlerts: [StockAlertRecord] = []
    @State private var isLoadingBackendAlerts = false
    @State private var alertInbox: [AlertInboxRecord] = []
    @State private var addresses: [DeliveryAddress] = []
    @State private var addressLabel = ""
    @State private var addressFullName = ""
    @State private var addressPhone = ""
    @State private var addressLine1 = ""
    @State private var addressCity = ""
    @State private var addressNotes = ""
    @State private var isSavingAddress = false
    @State private var loyaltyEmail = ""
    @State private var loyaltyAccount: LoyaltyAccount?
    @State private var loyaltyError: String?
    @State private var isLoadingLoyalty = false
    @State private var isRedeemingReward = false
    @State private var isEarningPoints = false
    @State private var isLoadingWalletPass = false
    @State private var isLoyaltyPassInWallet = false
#if canImport(PassKit)
    @State private var loyaltyWalletPass: WalletPassItem?
#endif
    @State private var isLibrarySectionExpanded = true
    @State private var isShoppingSectionExpanded = false
    @State private var isBrewingSectionExpanded = false
    @State private var isSupportSectionExpanded = false
    @State private var isDeliveryDetailsExpanded = false

    private let categoryCatalog: [ShopCategory] = [
        ShopCategory(key: "all", title: "All", subtitle: "Full catalog", symbol: "square.grid.2x2.fill"),
        ShopCategory(key: "coffee-beans", title: "Coffee Beans", subtitle: "Single-origin whole beans", symbol: "leaf.fill"),
        ShopCategory(key: "arabic-coffee-beans", title: "Arabic Coffee", subtitle: "Traditional roasts", symbol: "leaf.circle.fill"),
        ShopCategory(key: "drip-bags", title: "Drip Bags", subtitle: "Single-serve brews", symbol: "drop.fill"),
        ShopCategory(key: "coffee-equipment", title: "Equipment", subtitle: "Brewers and tools", symbol: "flask.fill"),
        ShopCategory(key: "ready-made-drinks", title: "Ready-Made Drinks", subtitle: "Bottled drinks, Drink Cups", symbol: "takeoutbag.and.cup.and.straw.fill"),
        ShopCategory(key: "crmb-tallas-speciality-bakery", title: "CRMB", subtitle: "Fresh bakery items", symbol: "birthday.cake.fill"),
        ShopCategory(key: "hot-chocolate", title: "Hot Chocolate", subtitle: "Cocoa and mixes", symbol: "mug.fill"),
        ShopCategory(key: "gifts", title: "Talla Boxes", subtitle: "Curated bundles", symbol: "gift.fill"),
    ]

    private let signatureRoastProductNames = [
        "Brazil",
        "Colombia",
        "Ethiopia",
        "Yemen"
    ]

    private var cartCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    private var cartSubtotal: Double {
        cartItems.reduce(0) { partialResult, item in
            partialResult + (priceValue(from: item.product.price) * Double(item.quantity))
        }
    }

    private var cartDiscount: Double {
        guard let appliedVoucher else { return 0 }

        switch appliedVoucher.reward.lowercased() {
        case "free drink":
            return min(cartSubtotal, 2.500)
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

    private var cartTotal: Double {
        max(cartSubtotal - cartDiscount, 0)
    }

    private var signatureRoastProducts: [Product] {
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

    private var isLightAppearance: Bool {
        appearanceMode == .light || (appearanceMode == .system && colorScheme == .light)
    }

    private var backgroundGradientColors: [Color] {
        if isLightAppearance {
            return [
                Color(hex: 0xF7F1E8),
                Color(hex: 0xEFE4D5),
                Color(hex: 0xE7D7C2)
            ]
        }

        return [
            Color(hex: 0x090705),
            Color(hex: 0x120D08),
            Color(hex: 0x1B1410)
        ]
    }

    private var primaryTextColor: Color {
        isLightAppearance ? Color(hex: 0x20150D) : Color(hex: 0xF5EDE0)
    }

    private var secondaryTextColor: Color {
        primaryTextColor.opacity(isLightAppearance ? 0.72 : 0.72)
    }

    private var tertiaryTextColor: Color {
        primaryTextColor.opacity(isLightAppearance ? 0.56 : 0.55)
    }

    private var cardFillColor: Color {
        isLightAppearance ? Color(hex: 0xFFF9F2).opacity(0.9) : Color.white.opacity(0.04)
    }

    private var elevatedSurfaceColor: Color {
        isLightAppearance ? Color(hex: 0xFFF8EF) : Color(hex: 0x120D08)
    }

    private var headerOverlayColor: Color {
        isLightAppearance ? Color.white.opacity(0.5) : Color.black.opacity(0.32)
    }

    private var footerOverlayColor: Color {
        isLightAppearance ? Color.white.opacity(0.44) : Color.black.opacity(0.28)
    }

    private var scrimColor: Color {
        isLightAppearance ? Color.black.opacity(0.22) : Color.black.opacity(0.6)
    }

    private var isCompact: Bool {
        horizontalSizeClass != .regular
    }

    private var productGridColumns: [GridItem] {
        if isCompact {
            [GridItem(.flexible(), spacing: 0)]
        } else {
            [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        }
    }

    private var shopProductGridColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
    }

    private var collectionGridColumns: [GridItem] {
        if isCompact {
            [GridItem(.flexible(), spacing: 0)]
        } else {
            [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
        }
    }

    private var brewingGridColumns: [GridItem] {
        if isCompact {
            [GridItem(.flexible(), spacing: 0)]
        } else {
            [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        }
    }

    private var availableCategories: [ShopCategory] {
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

        return ordered + extras
    }

    private var filteredProducts: [Product] {
        guard activeCategory != "all" else { return products }
        return products.filter { $0.categoryKey == activeCategory }
    }

    private var favoriteProductIDs: Set<String> {
        Set(
            savedFavoriteProductIDs
                .split(separator: ",")
                .map { String($0) }
                .filter { !$0.isEmpty }
        )
    }

    private var favoriteProducts: [Product] {
        products.filter { favoriteProductIDs.contains($0.id) }
    }

    private var recentlyViewedProductIDs: [String] {
        savedRecentlyViewedProductIDs
            .split(separator: ",")
            .map { String($0) }
            .filter { !$0.isEmpty }
    }

    private var recentlyViewedProducts: [Product] {
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        return recentlyViewedProductIDs.compactMap { productsByID[$0] }
    }

    private var alertProductIDs: Set<String> {
        Set(
            savedAlertProductIDs
                .split(separator: ",")
                .map { String($0) }
                .filter { !$0.isEmpty }
        )
    }

    private var alertProducts: [Product] {
        products
            .filter { alertProductIDs.contains($0.id) }
            .sorted { lhs, rhs in
                if lhs.isAvailableForSale != rhs.isAvailableForSale {
                    return !lhs.isAvailableForSale && rhs.isAvailableForSale
                }

                return lhs.name < rhs.name
            }
    }

    private var brewRecipes: [BrewRecipe] {
        guard let data = savedBrewRecipes.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([BrewRecipe].self, from: data) else {
            return []
        }

        return decoded
    }

    private var savedCarts: [SavedCart] {
        guard let data = savedCartsPayload.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([SavedCart].self, from: data) else {
            return []
        }

        return decoded
    }

    private var notificationsEnabled: Bool {
#if canImport(UserNotifications)
        notificationAuthorizationStatus == UNAuthorizationStatus.authorized.rawValue
            || notificationAuthorizationStatus == UNAuthorizationStatus.provisional.rawValue
#else
        false
#endif
    }

    private var backendStockAlertLookup: [String: StockAlertRecord] {
        Dictionary(uniqueKeysWithValues: backendStockAlerts.map { ($0.productID, $0) })
    }

    private var preferredAddress: DeliveryAddress? {
        addresses.first(where: \.isPreferred) ?? addresses.first
    }

    private var expiringVouchers: [VoucherRecord] {
        availableVouchers
            .sorted {
                (ISO8601DateFormatter().date(from: $0.expiresAt) ?? .distantFuture)
                < (ISO8601DateFormatter().date(from: $1.expiresAt) ?? .distantFuture)
            }
    }

    private func rewardProgress(for points: Int) -> (current: Int, target: Int, remaining: Int, fraction: Double) {
        let threshold = 100
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

    private func tierProgress(for points: Int) -> (label: String, current: Int, target: Int, remaining: Int, fraction: Double) {
        if points < 250 {
            let target = 250
            return (
                label: "Roastery Silver",
                current: points,
                target: target,
                remaining: target - points,
                fraction: min(max(Double(points) / Double(target), 0), 1)
            )
        }

        if points < 500 {
            let current = points - 250
            let span = 250
            return (
                label: "Roastery Gold",
                current: current,
                target: span,
                remaining: 500 - points,
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

    private var orderedProducts: [Product] {
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

    private var recommendedProducts: [Product] {
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
                let lhsScore = categoryWeights[lhs.categoryKey, default: 0]
                let rhsScore = categoryWeights[rhs.categoryKey, default: 0]

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

    private var displayedBrewingMethods: [BrewingMethod] {
        let source: [BrewingMethod]

        if brewingMethods.isEmpty {
            source = [
                BrewingMethod(
                    id: "fallback-pour-over",
                    name: "Pour Over",
                    summary: "Clean, articulate cups with a steady pour and a paper filter.",
                    detail: "Curated fallback guide",
                    symbol: "drop.fill",
                    articleURL: nil,
                    categories: ["Pour Over", "Filter"],
                    difficulty: "Intermediate",
                    brewTime: "3-4 min"
                ),
                BrewingMethod(
                    id: "fallback-french-press",
                    name: "French Press",
                    summary: "A fuller-bodied brew with a deeper texture and round finish.",
                    detail: "Curated fallback guide",
                    symbol: "cup.and.saucer.fill",
                    articleURL: nil,
                    categories: ["Immersion"],
                    difficulty: "Easy",
                    brewTime: "4 min"
                ),
                BrewingMethod(
                    id: "fallback-chemex",
                    name: "Chemex",
                    summary: "Bright clarity and delicate texture for clean specialty cups.",
                    detail: "Curated fallback guide",
                    symbol: "flask.fill",
                    articleURL: nil,
                    categories: ["Pour Over", "Filter"],
                    difficulty: "Intermediate",
                    brewTime: "4-5 min"
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

    private var brewingCategories: [String] {
        let source = brewingMethods.isEmpty ? displayedBrewingMethods : brewingMethods
        let categories = Set(source.flatMap(\.categories))
        return ["All"] + categories.sorted()
    }

    private var ratioCoffeeAmount: Double {
        Double(ratioCoffeeInput.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var ratioValue: Double {
        Double(ratioValueInput.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var calculatedWaterAmount: Double {
        ratioCoffeeAmount * ratioValue
    }

    private var loyaltyPerks: [String] {
        loyaltyAccount?.perks ?? [
            "Collect points across coffees, beans, and accessories",
            "Unlock seasonal offers and complimentary extras"
        ]
    }

    private var cartPurchasableItemsCount: Int {
        cartItems.filter { $0.product.variantID != nil && $0.product.isAvailableForSale }.count
    }

    private var checkoutReadinessMessage: String {
        if preferredAddress == nil {
            return "Add a delivery address before checkout for a smoother handoff."
        }

        if cartPurchasableItemsCount != cartItems.count {
            return "Some items may not be available for checkout right now."
        }

        if appliedVoucher != nil {
            return "Your voucher is applied and ready for checkout."
        }

        return "Your bag is ready. Review details, then continue to secure checkout."
    }

    private var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: savedAppearanceMode) ?? .system }
        set { savedAppearanceMode = newValue.rawValue }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
                .ignoresSafeArea()

            Circle()
                .fill(Color(hex: 0xC8965A).opacity(0.12))
                .blur(radius: 120)
                .frame(width: 240, height: 240)
                .offset(x: 140, y: -320)

            Circle()
                .fill(Color(hex: 0x8A5E30).opacity(0.12))
                .blur(radius: 160)
                .frame(width: 300, height: 300)
                .offset(x: -120, y: 420)

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        switch activeTab {
                        case .home:
                            homeView
                        case .shop:
                            shopView
                        case .brewing:
                            brewingView
                        case .account:
                            accountView
                        }

                        footer
                    }
                }
            }
            .frame(maxWidth: 400)

            if cartOpen {
                cartDrawer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if let toastMessage {
                ToastBannerView(
                    message: toastMessage,
                    font: .system(size: 11, weight: .medium),
                    backgroundColor: Color(hex: 0xC8965A),
                    foregroundColor: Color(hex: 0x0A0804)
                )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: cartOpen)
        .task {
            await loadProductsIfNeeded()
            await refreshNotificationStatus()
        }
        .onChange(of: activeTab) { _, newTab in
            guard newTab == .shop, hasLoadedProducts else { return }
            Task {
                await loadProducts(force: true)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, hasLoadedProducts else { return }
            Task {
                await loadProducts(force: true)
                await refreshWalletPassPresence()
            }
        }
        .sheet(item: $checkoutSession) { session in
            CheckoutWebView(url: session.url)
        }
        .sheet(item: $articleSession) { session in
            CheckoutWebView(url: session.url)
        }
        .sheet(item: $selectedProduct) { product in
            productDetailSheet(product: product)
        }
#if canImport(PassKit)
        .sheet(item: $loyaltyWalletPass, onDismiss: {
            Task {
                await refreshWalletPassPresence()
            }
        }) { item in
            WalletPassView(pass: item.pass)
        }
#endif
        .safeAreaInset(edge: .bottom) {
            bottomTabBar
                .zIndex(20)
        }
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    activeTab = .home
                } label: {
                    HStack(spacing: 12) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 52, height: 52)

                        Text("TALLA")
                            .font(displayFont(size: isCompact ? 32 : 28))
                            .tracking(isCompact ? 2 : 3)
                            .foregroundColor(primaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Menu {
                    Section("Appearance") {
                        ForEach(AppearanceMode.allCases) { mode in
                            Button {
                                savedAppearanceMode = mode.rawValue
                            } label: {
                                HStack {
                                    Text(mode.title)
                                    if appearanceMode == mode {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(hex: 0xC8965A))
                        .frame(width: 40, height: 40)
                        .background(cardFillColor)
                        .clipShape(Circle())
                }
                .menuStyle(.button)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [headerOverlayColor, Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var bottomTabBar: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 10) {
                navigationTabButton(.home)
                navigationTabButton(.shop)
                cartTabButton
                navigationTabButton(.brewing)
                navigationTabButton(.account)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.clear)
                    .glassEffect(
                        .regular
                            .tint(Color(hex: isLightAppearance ? 0xFFF6EC : 0x20150D).opacity(isLightAppearance ? 0.52 : 0.34)),
                        in: .capsule
                    )
                    .allowsHitTesting(false)
            )
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .padding(.horizontal, 10)
    }

    private func navigationTabButton(_ tab: Tab) -> some View {
        Button {
            activeTab = tab
        } label: {
            Image(systemName: tab.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(activeTab == tab ? Color(hex: 0xC8965A) : secondaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .padding(.vertical, 12)
                .glassEffect(
                    activeTab == tab
                        ? .regular.tint(Color(hex: 0xC8965A).opacity(0.8)).interactive()
                        : .regular.tint(Color.white.opacity(isLightAppearance ? 0.16 : 0.08)).interactive(),
                    in: .circle
                )
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel(tab.rawValue.capitalized)
    }

    private var cartTabButton: some View {
        Button {
            cartOpen = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bag.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(primaryTextColor.opacity(isLightAppearance ? 0.88 : 0.9))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .padding(.vertical, 12)
                    .glassEffect(
                        .regular
                            .tint((cartCount > 0 ? Color(hex: 0xC8965A) : Color.white).opacity(cartCount > 0 ? 0.8 : (isLightAppearance ? 0.16 : 0.08)))
                            .interactive(),
                        in: .circle
                    )

                if cartCount > 0 {
                    Text("\(cartCount)")
                        .font(labelFont(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(minWidth: 22, minHeight: 22)
                        .background(primaryTextColor)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(hex: 0x8A5E30).opacity(0.18), lineWidth: 1)
                        )
                        .offset(x: 8, y: 2)
                }
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityLabel("Open cart")
    }

    private var homeView: some View {
        VStack(spacing: 0) {
            heroSection
            homeQuickActions
            homeLoyaltyTeaser
            featuredProducts
        }
    }

    private var homeQuickActions: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Start here")
                .font(labelFont(size: 10, weight: .bold))
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ActionTileView(
                    title: "Shop Bestsellers",
                    detail: "Go straight to coffees, tools, and gifts.",
                    systemImage: "bag.fill",
                    titleFont: labelFont(size: 11, weight: .bold),
                    detailFont: bodyFont(size: 13),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: Color(hex: 0xC8965A),
                    backgroundColor: cardFillColor,
                    strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08),
                    minHeight: 126
                ) {
                    activeTab = .shop
                }

                ActionTileView(
                    title: "Check Rewards",
                    detail: "See points, rewards, and your member status.",
                    systemImage: "sparkles.rectangle.stack.fill",
                    titleFont: labelFont(size: 11, weight: .bold),
                    detailFont: bodyFont(size: 13),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: Color(hex: 0xC8965A),
                    backgroundColor: cardFillColor,
                    strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08),
                    minHeight: 126
                ) {
                    activeTab = .account
                }

                ActionTileView(
                    title: "Reorder Faster",
                    detail: "Open saved carts, addresses, and recent orders.",
                    systemImage: "arrow.clockwise.circle.fill",
                    titleFont: labelFont(size: 11, weight: .bold),
                    detailFont: bodyFont(size: 13),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: Color(hex: 0xC8965A),
                    backgroundColor: cardFillColor,
                    strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08),
                    minHeight: 126
                ) {
                    isLibrarySectionExpanded = true
                    isDeliveryDetailsExpanded = false
                    activeTab = .account
                }

                ActionTileView(
                    title: "Brew Better",
                    detail: "Use guides and saved recipes for your next cup.",
                    systemImage: "drop.fill",
                    titleFont: labelFont(size: 11, weight: .bold),
                    detailFont: bodyFont(size: 13),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: Color(hex: 0xC8965A),
                    backgroundColor: cardFillColor,
                    strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08),
                    minHeight: 126
                ) {
                    activeTab = .brewing
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
    }

    private var homeLoyaltyTeaser: some View {
        Group {
            if let loyaltyAccount, !savedLoyaltyEmail.isEmpty {
                let rewardProgressState = rewardProgress(for: loyaltyAccount.pointsBalance)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Talla Reserve")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(2.2)
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: 0xC8965A))

                            Text(expiringVouchers.isEmpty ? loyaltyAccount.nextReward : "\(expiringVouchers.count) rewards active")
                                .font(titleFont(size: 20))
                                .foregroundColor(primaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 12)

                        Button {
                            activeTab = .account
                        } label: {
                            Text("Rewards")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.8)
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: 0x0A0804))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(Color(hex: 0xC8965A))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Reward Progress")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.8)
                                .textCase(.uppercase)
                                .foregroundColor(tertiaryTextColor)
                            Spacer()
                            Text("\(rewardProgressState.current)/\(rewardProgressState.target)")
                                .font(bodyFont(size: 12))
                                .foregroundColor(secondaryTextColor)
                        }

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule(style: .continuous)
                                    .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.10))

                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: 0xC8965A), Color(hex: 0x8A5E30)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(proxy.size.width * rewardProgressState.fraction, 10))
                            }
                        }
                        .frame(height: 8)
                    }

                    if let voucher = expiringVouchers.first {
                        Text("Expires soon: \(voucher.reward) • \(voucherExpiryLabel(for: voucher))")
                            .font(bodyFont(size: 13))
                            .foregroundColor(voucherExpiresSoon(voucher) ? Color.red.opacity(0.85) : secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("\(rewardProgressState.remaining) points until your next reward unlock.")
                            .font(bodyFont(size: 13))
                            .foregroundColor(secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(18)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Roastery")
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(4)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Text("Coffee for daily rituals")
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                }

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Fresh Roast")
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(1.8)
                        .textCase(.uppercase)
                }
                .foregroundColor(Color(hex: 0x8B5B2A))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(hex: 0xF3DFC2).opacity(isLightAppearance ? 0.95 : 0.12))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.22 : 0.08), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Specialty coffee,\nroasted with intention")
                    .font(displayFont(size: isCompact ? 34 : 46))
                    .lineSpacing(4)
                    .foregroundColor(primaryTextColor)

                Text("Shop roasted coffee, brewing essentials, and rewards without digging through the app.")
                    .font(bodyFont(size: 16))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    heroStat(value: "Bahrain", label: "Roasted for the local table")
                    heroStat(value: "Seasonal", label: "Selections for every ritual")
                }
                heroStat(value: "Single-Origin", label: "Clean, expressive profiles")
            }

            VStack(spacing: 12) {
                Button {
                    activeTab = .shop
                } label: {
                    Text("EXPLORE COFFEES")
                        .font(labelFont(size: 13, weight: .bold))
                        .tracking(3)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(hex: 0xC8965A))
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)

                Button {
                    activeTab = .brewing
                } label: {
                    Text("BREWING GUIDE")
                        .font(labelFont(size: 12, weight: .bold))
                        .tracking(2.5)
                        .foregroundColor(primaryTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.18 : 0.08), lineWidth: 1)
                        )
                        .cornerRadius(16)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            isLightAppearance ? Color(hex: 0xFFF7ED) : Color(hex: 0x22170F).opacity(0.95),
                            isLightAppearance ? Color(hex: 0xEAD9C3) : elevatedSurfaceColor.opacity(0.96)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: 0xC8965A).opacity(0.14))
                .frame(width: 140, height: 140)
                .blur(radius: 24)
                .offset(x: 26, y: -26)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(Color(hex: 0x7C4E24).opacity(isLightAppearance ? 0.08 : 0.12))
                .frame(width: 120, height: 120)
                .blur(radius: 26)
                .offset(x: -24, y: 30)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 24)
    }

    private var featureStrip: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            featureItem(
                symbol: "flame.fill",
                eyebrow: "",
                title: "Small-Batch Roasting",
                detail: "Carefully profiled batches roasted for sweetness, balance, and clarity."
            )
            featureItem(
                symbol: "leaf.fill",
                eyebrow: "",
                title: "Origin-Driven Coffees",
                detail: "Single-origin selections chosen for distinctive character in every cup."
            )
            featureItem(
                symbol: "cup.and.saucer.fill",
                eyebrow: "",
                title: "Cafe-Inspired Rituals",
                detail: "Thoughtful brews and daily pours shaped around a calm coffee ritual."
            )
            featureItem(
                symbol: "gift.fill",
                eyebrow: "",
                title: "Gifts & Brewing Essentials",
                detail: "Tools, boxes, and thoughtful extras assembled for home or gifting."
            )
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
    }

    private var loyaltySection: some View {
        LoyaltySectionView(
            isCompact: isCompact,
            isLightAppearance: isLightAppearance,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            elevatedSurfaceColor: elevatedSurfaceColor,
            accentColor: Color(hex: 0xC8965A),
            labelFont: labelFont(size: 10, weight: .semibold),
            titleFont: displayFont(size: isCompact ? 28 : 32),
            bodyFont: bodyFont(size: 15),
            sectionTitleFont: labelFont(size: 11, weight: .bold),
            savedLoyaltyEmail: savedLoyaltyEmail,
            loyaltyEmail: $loyaltyEmail,
            loyaltyError: loyaltyError,
            isLoadingLoyalty: isLoadingLoyalty,
            loyaltyAccount: loyaltyAccount,
            loyaltyPerks: loyaltyPerks,
            rewardProgress: loyaltyAccount.map { rewardProgress(for: $0.pointsBalance) },
            tierProgress: loyaltyAccount.map { tierProgress(for: $0.pointsBalance) },
            checkRewardsAction: {
                Task {
                    await loadLoyaltyAccount()
                }
            },
            signOutAction: {
                savedLoyaltyEmail = ""
                loyaltyEmail = ""
                loyaltyAccount = nil
                loyaltyError = nil
            },
            expiringRewardsSection: AnyView(expiringRewardsSection),
            rewardsActionsSection: AnyView(Group {
                if let loyaltyAccount {
                    loyaltyBenefit(title: "Member ID", detail: loyaltyAccount.memberID)
                    loyaltyRewardsActions(account: loyaltyAccount)
                }
            }),
            transactionsSection: AnyView(Group {
                if let loyaltyAccount {
                    loyaltyTransactionsSection(account: loyaltyAccount)
                }
            }),
            walletCallToAction: AnyView(walletCallToAction)
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    private var customerAccountSection: some View {
        CustomerAccountSectionView(
            isCompact: isCompact,
            isLightAppearance: isLightAppearance,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            cardFillColor: cardFillColor,
            elevatedSurfaceColor: elevatedSurfaceColor,
            accentColor: Color(hex: 0xC8965A),
            labelFont: labelFont(size: 10, weight: .semibold),
            titleFont: displayFont(size: isCompact ? 28 : 32),
            bodyFont: bodyFont(size: 15),
            sectionTitleFont: labelFont(size: 11, weight: .bold),
            accountAuthMode: $accountAuthMode,
            accountFirstName: $accountFirstName,
            accountLastName: $accountLastName,
            accountEmail: $accountEmail,
            accountPassword: $accountPassword,
            accountConfirmPassword: $accountConfirmPassword,
            isSigningIn: isSigningIn,
            isCreatingAccount: isCreatingAccount,
            isResettingPassword: isResettingPassword,
            isRequestingPasswordResetLink: isRequestingPasswordResetLink,
            isLoadingCustomer: isLoadingCustomer,
            customerAuthError: customerAuthError,
            customerProfile: customerProfile,
            primaryActionTitle: primaryAccountActionTitle,
            toggleModeAction: { mode in
                switchAccountAuthMode(mode)
            },
            submitAction: {
                Task {
                    if accountAuthMode == .createAccount {
                        await createCustomerAccount()
                    } else if accountAuthMode == .changePassword {
                        await changePasswordWithoutSignIn()
                    } else {
                        await signInCustomer()
                    }
                }
            },
            requestPasswordResetLinkAction: {
                Task {
                    await requestPasswordResetLink()
                }
            },
            signedInContent: AnyView(
                Group {
                    if let customerProfile {
                        signedInCustomerCard(customerProfile)
                    }
                }
            )
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    private var primaryAccountActionTitle: String {
        if accountAuthMode == .createAccount {
            return isCreatingAccount ? "CREATING ACCOUNT..." : "CREATE ACCOUNT"
        }

        if accountAuthMode == .changePassword {
            return isResettingPassword ? "UPDATING PASSWORD..." : "CHANGE PASSWORD"
        }

        return isSigningIn || isLoadingCustomer ? "SIGNING IN..." : "SIGN IN"
    }

    private func signedInCustomerCard(_ profile: ShopifyCustomerProfile) -> some View {
        SignedInCustomerSectionView(
            profile: profile,
            addressesCount: addresses.count,
            orderCount: orderHistory.count,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            titleFont: titleFont(size: 24),
            bodyFont: bodyFont(size: 14),
            labelFont: labelFont(size: 11, weight: .bold),
            workspaceColumns: accountWorkspaceColumns,
            signOutAction: {
                signOutCustomer()
            },
            profileSection: AnyView(profileManagementSection),
            passwordSection: AnyView(passwordResetSection),
            orderHistorySection: AnyView(orderHistorySection)
        )
    }

    private var profileManagementSection: some View {
        ProfileManagementSectionView(
            primaryTextColor: primaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            firstName: $profileFirstName,
            lastName: $profileLastName,
            isSaving: isSavingProfile,
            saveAction: {
                Task {
                    await saveProfile()
                }
            }
        )
    }

    private var passwordResetSection: some View {
        PasswordResetSectionView(
            primaryTextColor: primaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            currentPassword: $currentPasswordInput,
            newPassword: $newPasswordInput,
            confirmPassword: $confirmNewPasswordInput,
            isResetting: isResettingPassword,
            resetAction: {
                Task {
                    await resetPassword()
                }
            }
        )
    }

    private var orderHistorySection: some View {
        OrderHistorySectionView(
            orders: orderHistory,
            isLoadingOrders: isLoadingOrders,
            isRecordingSampleOrder: isRecordingSampleOrder,
            ordersError: ordersError,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            addSampleAction: {
                Task {
                    await recordSampleOrder()
                }
            },
            buyAgainAction: { order in
                buyAgain(order: order)
            }
        )
    }

    private var featuredProducts: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Roastery Selection")
                    .font(labelFont(size: 10, weight: .semibold))
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))
                Text("SIGNATURE ROASTS")
                    .font(displayFont(size: 30))
                    .tracking(1)
                    .foregroundColor(primaryTextColor)
                Button {
                    activeTab = .shop
                } label: {
                    Text("Browse Shop")
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))
                }
                .buttonStyle(.plain)
            }

            if isLoadingProducts && products.isEmpty {
                loadingSection
            } else if let loadingError, products.isEmpty {
                errorSection(message: loadingError)
            } else {
                LazyVGrid(columns: productGridColumns, spacing: 16) {
                    ForEach(signatureRoastProducts) { product in
                        productCard(product: product, showDescription: false)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 28)
    }

    private var collections: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("")
                    .font(labelFont(size: 10, weight: .semibold))
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))

                Text("FROM THE ROASTERY")
                    .font(displayFont(size: 28))
                    .tracking(1)
                    .foregroundColor(primaryTextColor)

                Text("A tighter selection of coffees, tools, and gifts shaped around the daily ritual of the roastery.")
                    .font(bodyFont(size: 15))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: collectionGridColumns, spacing: 12) {
                collectionTile(
                    eyebrow: "Signature",
                    name: "Roasted Beans",
                    desc: "Single-origin coffees and house profiles selected for clarity, sweetness, and everyday brewing range.",
                    accent: "Explore the beans that define the Talla cup.",
                    systemImage: "leaf.fill",
                    color: Color(hex: 0x8A5A28),
                    categoryKey: "coffee-beans"
                )
                collectionTile(
                    eyebrow: "Precision",
                    name: "Brewing Tools",
                    desc: "Professional brewers, scales, and tools for a more refined home coffee setup.",
                    accent: "Built for repeatable, cafe-level brewing.",
                    systemImage: "flask.fill",
                    color: Color(hex: 0x315C72),
                    categoryKey: "coffee-equipment"
                )
                collectionTile(
                    eyebrow: "Gifting",
                    name: "Talla Boxes",
                    desc: "Curated gift boxes and roastery bundles prepared for hosting, gifting, and seasonal moments.",
                    accent: "Elegant selections ready to share.",
                    systemImage: "gift.fill",
                    color: Color(hex: 0x6D5C24),
                    categoryKey: "gifts"
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 40)
    }

    private var shopView: some View {
        ShopSectionView(
            activeCategoryTitle: activeCategory == "all" ? "Full catalog" : categoryLabel(for: activeCategory),
            availableCategories: availableCategories,
            filteredProducts: filteredProducts,
            allProductsAreEmpty: products.isEmpty,
            isLoadingProducts: isLoadingProducts,
            loadingError: loadingError,
            activeCategory: $activeCategory,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: Color(hex: 0xC8965A),
            isLightAppearance: isLightAppearance,
            titleFont: displayFont(size: 32),
            sectionTitleFont: displayFont(size: 22),
            bodyFont: bodyFont(size: 15),
            labelFont: labelFont(size: 10, weight: .semibold),
            categoryLabelFont: labelFont(size: 11, weight: .bold),
            categoryBodyFont: bodyFont(size: 13),
            gridColumns: shopProductGridColumns,
            renderProductCard: { product, showDescription in
                AnyView(productCard(product: product, showDescription: showDescription))
            },
            retryLoad: {
                Task {
                    await loadProducts(force: true)
                }
            }
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 28)
    }

    private var brewingView: some View {
        BrewingSectionView(
            isCompact: isCompact,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: Color(hex: 0xC8965A),
            displayedMethods: displayedBrewingMethods,
            brewingCategories: brewingCategories,
            gridColumns: brewingGridColumns,
            isLoadingMethods: isLoadingBrewingMethods,
            methodsAreEmpty: brewingMethods.isEmpty,
            methodsError: brewingMethodsError,
            activeCategory: $activeBrewingCategory,
            ratioCoffeeInput: $ratioCoffeeInput,
            ratioValueInput: $ratioValueInput,
            brewRecipeName: $brewRecipeName,
            calculatedWaterAmount: calculatedWaterAmount,
            ratioCoffeeAmount: ratioCoffeeAmount,
            ratioValue: ratioValue,
            titleFont: displayFont(size: 32),
            sectionTitleFont: labelFont(size: 11, weight: .bold),
            bodyFont: bodyFont(size: 13),
            labelFont: labelFont(size: 10, weight: .semibold),
            saveRecipeAction: {
                saveCurrentBrewRecipe()
            },
            openArticleAction: { url in
                articleSession = CheckoutSession(url: url)
            },
            loadingView: AnyView(loadingSection)
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 28)
    }

    private var accountView: some View {
        AccountSectionView(
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: Color(hex: 0xC8965A),
            isLightAppearance: isLightAppearance,
            titleFont: displayFont(size: 32),
            introFont: bodyFont(size: 17),
            bodyFont: bodyFont(size: 14),
            labelFont: labelFont(size: 10, weight: .semibold),
            sectionTitleFont: displayFont(size: 22),
            sectionBodyFont: bodyFont(size: 14),
            quickActionTitleFont: labelFont(size: 11, weight: .bold),
            quickActionBodyFont: bodyFont(size: 13),
            addressesCount: addresses.count,
            favoriteCount: favoriteProducts.count,
            brewRecipeCount: brewRecipes.count,
            isLibrarySectionExpanded: $isLibrarySectionExpanded,
            isShoppingSectionExpanded: $isShoppingSectionExpanded,
            isBrewingSectionExpanded: $isBrewingSectionExpanded,
            isSupportSectionExpanded: $isSupportSectionExpanded,
            openRewardsAction: {
                savedLoyaltyEmail = savedCustomerEmail.isEmpty ? savedLoyaltyEmail : savedCustomerEmail
            },
            openDeliveryAction: {
                isLibrarySectionExpanded = true
                isDeliveryDetailsExpanded = true
            },
            openSavedPicksAction: {
                isShoppingSectionExpanded = true
            },
            openBrewArchiveAction: {
                isBrewingSectionExpanded = true
            },
            customerAccountSection: AnyView(customerAccountSection),
            loyaltySection: AnyView(loyaltySection),
            librarySection: AnyView(
                Group {
                    addressesSection
                    alertsSection
                    savedCartsSection
                }
            ),
            shoppingSection: AnyView(
                Group {
                    favoritesSection
                    recentlyViewedSection
                    recommendedSection
                }
            ),
            brewingSection: AnyView(brewRecipesSection),
            supportSection: AnyView(
                VStack(alignment: .leading, spacing: 14) {
                    Text("ACCOUNT TOOLS")
                        .font(displayFont(size: 22))
                        .tracking(2)
                        .foregroundColor(primaryTextColor)

                    LazyVGrid(columns: collectionGridColumns, spacing: 12) {
                        accountStatusTile(
                            title: "Talla Account",
                            detail: "Your Talla account connects checkout, rewards, and saved details in one place."
                        )
                        accountStatusTile(
                            title: "Rewards Ready",
                            detail: "Your account email is used to keep rewards and loyalty in sync across the app."
                        )
                        infoTile(
                            title: "Support",
                            detail: "Need help with orders or rewards? Reach the roastery team directly.",
                            actionTitle: "WhatsApp Us",
                            destination: URL(string: "https://wa.me/97339392414")!
                        )
                    }
                }
            )
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 28)
    }

    private var accountWorkspaceColumns: [GridItem] {
        if isCompact {
            [GridItem(.flexible(), spacing: 0)]
        } else {
            [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ]
        }
    }

    private func accountWorkspaceCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        SectionCardView(
            backgroundColor: cardFillColor,
            strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08)
        ) {
            content()
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("FAVORITES")
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if favoriteProducts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Save coffees, tools, and gifts you want to come back to.")
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        activeTab = .shop
                    } label: {
                        Text("Browse Products")
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(1.8)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0xC8965A))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                LazyVGrid(columns: productGridColumns, spacing: 16) {
                    ForEach(favoriteProducts.prefix(4)) { product in
                        productCard(product: product, showDescription: false)
                    }
                }
            }
        }
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECOMMENDED FOR YOU")
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if recommendedProducts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Recommendations will appear here once products are loaded.")
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Picked from the coffees, tools, and categories you keep coming back to.")
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVGrid(columns: productGridColumns, spacing: 16) {
                        ForEach(recommendedProducts) { product in
                            productCard(product: product, showDescription: false)
                        }
                    }
                }
            }
        }
    }

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ALERTS")
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if alertProducts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Tap the bell on a product to keep it on your back in stock or new roast watchlist.")
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Track upcoming drops and get back to the coffees you do not want to miss.")
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    if !alertInbox.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Alert Updates")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.6)
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: 0xC8965A))

                            ForEach(alertInbox.prefix(2)) { update in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(update.title)
                                        .font(titleFont(size: 16))
                                        .foregroundColor(primaryTextColor)
                                    Text(update.detail)
                                        .font(bodyFont(size: 13))
                                        .foregroundColor(secondaryTextColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(cardFillColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        Image(systemName: notificationsEnabled ? "bell.badge.fill" : "bell.slash")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: 0xC8965A))

                        Text(
                            notificationsEnabled
                                ? "Local reminders are enabled for watched products."
                                : "Enable notifications to get local reminders for watched products."
                        )
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)

                        Spacer(minLength: 0)

                        if !notificationsEnabled {
                            Button {
                                Task {
                                    await requestNotificationAccess()
                                }
                            } label: {
                                Text("Enable")
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(1.6)
                                    .textCase(.uppercase)
                                    .foregroundColor(Color(hex: 0x0A0804))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 9)
                                    .background(Color(hex: 0xC8965A))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    ForEach(alertProducts.prefix(6)) { product in
                        HStack(alignment: .center, spacing: 12) {
                            ProductThumbnail(imageURL: product.imageURL, size: 68, cornerRadius: 14)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(product.name)
                                    .font(titleFont(size: 18))
                                    .foregroundColor(primaryTextColor)
                                    .lineLimit(2)

                                Text(stockAlertLabel(for: product))
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(1.6)
                                    .textCase(.uppercase)
                                    .foregroundColor(Color(hex: 0xC8965A))
                            }

                            Spacer(minLength: 0)

                            Button {
                                Task {
                                    await toggleAlert(product: product)
                                }
                            } label: {
                                Image(systemName: "bell.slash")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(primaryTextColor)
                                    .frame(width: 36, height: 36)
                                    .background(cardFillColor)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    private var addressesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isDeliveryDetailsExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("DELIVERY DETAILS")
                            .font(displayFont(size: 22))
                            .tracking(2)
                            .foregroundColor(primaryTextColor)

                        Text(addresses.isEmpty ? "Add an address for faster checkout." : "\(addresses.count) saved address\(addresses.count == 1 ? "" : "es") ready.")
                            .font(bodyFont(size: 14))
                            .foregroundColor(secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: isDeliveryDetailsExpanded ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex: 0xC8965A))
                }
            }
            .buttonStyle(.plain)

            if isDeliveryDetailsExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Save your preferred address here so checkout feels faster, even when Shopify opens on the web.")
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField("Label", text: $addressLabel)
                        .textInputAutocapitalization(.words)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(cardFillColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    TextField("Full name", text: $addressFullName)
                        .textInputAutocapitalization(.words)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(cardFillColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    TextField("Phone", text: $addressPhone)
                        .keyboardType(.phonePad)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(cardFillColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    TextField("Address line", text: $addressLine1)
                        .textInputAutocapitalization(.words)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(cardFillColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    HStack(spacing: 10) {
                        TextField("City", text: $addressCity)
                            .textInputAutocapitalization(.words)
                            .font(bodyFont(size: 14))
                            .foregroundColor(primaryTextColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(cardFillColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        TextField("Notes", text: $addressNotes)
                            .textInputAutocapitalization(.sentences)
                            .font(bodyFont(size: 14))
                            .foregroundColor(primaryTextColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(cardFillColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Button {
                        Task {
                            await saveAddress()
                        }
                    } label: {
                        Text(isSavingAddress ? "Saving..." : "Save Address")
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(1.8)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(hex: 0xC8965A))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSavingAddress)
                }
                .transition(.move(edge: .top).combined(with: .opacity))

                if addresses.isEmpty {
                    Text("No saved addresses yet.")
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                } else {
                    ForEach(addresses) { address in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(address.label)
                                    .font(titleFont(size: 18))
                                    .foregroundColor(primaryTextColor)
                                Text("\(address.fullName) • \(address.phone)")
                                    .font(bodyFont(size: 13))
                                    .foregroundColor(secondaryTextColor)
                                Text("\(address.line1), \(address.city)")
                                    .font(bodyFont(size: 13))
                                    .foregroundColor(secondaryTextColor)
                                if let notes = address.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(bodyFont(size: 12))
                                        .foregroundColor(tertiaryTextColor)
                                }
                                if address.isPreferred {
                                    Text("Preferred")
                                        .font(labelFont(size: 10, weight: .bold))
                                        .tracking(1.6)
                                        .textCase(.uppercase)
                                        .foregroundColor(Color(hex: 0xC8965A))
                                }
                            }

                            Spacer(minLength: 0)

                            Button {
                                Task {
                                    await deleteAddress(address)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(primaryTextColor)
                                    .frame(width: 34, height: 34)
                                    .background(cardFillColor)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    private var brewRecipesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SAVED BREW RECIPES")
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if brewRecipes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Save your favorite coffee-to-water ratios from the brew tab and they will appear here.")
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(brewRecipes) { recipe in
                        HStack(alignment: .center, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(recipe.name)
                                    .font(titleFont(size: 18))
                                    .foregroundColor(primaryTextColor)

                                Text("\(formattedRatioValue(recipe.coffeeGrams)) g coffee • 1:\(formattedRatioValue(recipe.ratio)) • \(formattedRatioValue(recipe.waterGrams)) g water")
                                    .font(bodyFont(size: 13))
                                    .foregroundColor(secondaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(recipe.category)
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(1.4)
                                    .textCase(.uppercase)
                                    .foregroundColor(Color(hex: 0xC8965A))
                            }

                            Spacer(minLength: 0)

                            VStack(spacing: 8) {
                                Button {
                                    applyBrewRecipe(recipe)
                                } label: {
                                    Text("Apply")
                                        .font(labelFont(size: 10, weight: .bold))
                                        .tracking(1.8)
                                        .textCase(.uppercase)
                                        .foregroundColor(Color(hex: 0x0A0804))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: 0xC8965A))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    deleteBrewRecipe(recipe)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(primaryTextColor)
                                        .frame(width: 34, height: 34)
                                        .background(cardFillColor)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    private var savedCartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SAVED CARTS")
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if savedCarts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Save a filled cart from the bag and come back to it whenever you are ready to check out.")
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(spacing: 12) {
                    ForEach(savedCarts) { savedCart in
                        HStack(alignment: .center, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(savedCart.name)
                                    .font(titleFont(size: 18))
                                    .foregroundColor(primaryTextColor)

                                Text(savedCart.items.map { "\($0.productName) x\($0.quantity)" }.joined(separator: " • "))
                                    .font(bodyFont(size: 13))
                                    .foregroundColor(secondaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)

                            VStack(spacing: 8) {
                                Button {
                                    applySavedCart(savedCart)
                                } label: {
                                    Text("Load")
                                        .font(labelFont(size: 10, weight: .bold))
                                        .tracking(1.8)
                                        .textCase(.uppercase)
                                        .foregroundColor(Color(hex: 0x0A0804))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: 0xC8965A))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    deleteSavedCart(savedCart)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(primaryTextColor)
                                        .frame(width: 34, height: 34)
                                        .background(cardFillColor)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    private var recentlyViewedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RECENTLY VIEWED")
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if recentlyViewedProducts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Products you open, save, or add to bag will appear here for quick return visits.")
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                LazyVGrid(columns: productGridColumns, spacing: 16) {
                    ForEach(recentlyViewedProducts.prefix(4)) { product in
                        productCard(product: product, showDescription: false)
                    }
                }
            }
        }
    }

    private func accountStatusTile(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(titleFont(size: 20))
                .foregroundColor(primaryTextColor)

            Text(detail)
                .font(bodyFont(size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Text("TALLA")
                .font(displayFont(size: 24))
                .tracking(4)
                .foregroundColor(Color(hex: 0xC8965A))

            Text("By Chef Ahmad")
                .font(.system(size: 9, weight: .light))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .overlay(
            Rectangle()
                .fill(Color(hex: 0xC8965A).opacity(0.1))
                .frame(height: 1),
            alignment: .top
        )
    }

    private var cartDrawer: some View {
        CartDrawerView(
            scrimColor: scrimColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            elevatedSurfaceColor: elevatedSurfaceColor,
            accentColor: Color(hex: 0xC8965A),
            hasItems: !cartItems.isEmpty,
            emptyState: AnyView(cartEmptyState),
            reviewContent: AnyView(cartReviewContent),
            footerContent: AnyView(cartFooterContent),
            closeAction: {
                cartOpen = false
            }
        )
    }

    private var cartEmptyState: some View {
        Text("Your bag is empty.")
            .font(.system(size: 12, weight: .light))
            .foregroundColor(tertiaryTextColor)
    }

    private var cartReviewContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Checkout Ready")
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))

                Text(checkoutReadinessMessage)
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    DetailStatusCardView(
                        title: "Items",
                        detail: "\(cartCount) in bag • \(cartPurchasableItemsCount) ready",
                        titleFont: labelFont(size: 10, weight: .bold),
                        detailFont: bodyFont(size: 13),
                        accentColor: Color(hex: 0xC8965A),
                        primaryTextColor: primaryTextColor,
                        backgroundColor: cardFillColor,
                        strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08)
                    )
                    DetailStatusCardView(
                        title: "Voucher",
                        detail: appliedVoucher == nil ? "None applied yet" : appliedVoucher?.code ?? "Applied",
                        titleFont: labelFont(size: 10, weight: .bold),
                        detailFont: bodyFont(size: 13),
                        accentColor: Color(hex: 0xC8965A),
                        primaryTextColor: primaryTextColor,
                        backgroundColor: cardFillColor,
                        strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08)
                    )
                }
            }

            cartDeliverySection
            cartItemsListSection
            cartRewardsSection
            cartSaveSection
        }
    }

    private var cartFooterContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Order Summary")
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))

                SummaryValueRow(
                    title: "Subtotal",
                    value: formattedBHD(cartSubtotal),
                    emphasized: false,
                    regularFont: bodyFont(size: 13),
                    emphasizedFont: labelFont(size: 11, weight: .bold),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: Color(hex: 0xC8965A)
                )

                if appliedVoucher != nil {
                    SummaryValueRow(
                        title: "Voucher",
                        value: "-\(formattedBHD(cartDiscount))",
                        emphasized: false,
                        regularFont: bodyFont(size: 13),
                        emphasizedFont: labelFont(size: 11, weight: .bold),
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        accentColor: Color(hex: 0xC8965A)
                    )
                }

                SummaryValueRow(
                    title: "Total",
                    value: formattedBHD(cartTotal),
                    emphasized: true,
                    regularFont: bodyFont(size: 13),
                    emphasizedFont: labelFont(size: 11, weight: .bold),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: Color(hex: 0xC8965A)
                )
            }
            .padding(.top, 4)

            if let checkoutError {
                Text(checkoutError)
                    .font(bodyFont(size: 13))
                    .foregroundColor(Color.red.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task {
                    await beginCheckout()
                }
            } label: {
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        if isCheckingOut {
                            ProgressView()
                                .tint(Color(hex: 0x0A0804))
                        }

                        Text(isCheckingOut ? "OPENING..." : "CONTINUE TO CHECKOUT")
                    }
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .tracking(2)

                    Text("You’ll review and pay securely in the checkout page.")
                        .font(bodyFont(size: 11))
                        .foregroundColor(Color(hex: 0x0A0804).opacity(0.82))
                }
                .foregroundColor(Color(hex: 0x0A0804))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: 0xC8965A))
                .cornerRadius(2)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .disabled(isCheckingOut)
        }
    }

    private var cartDeliverySection: some View {
        Group {
            if let preferredAddress {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Preferred Delivery")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.6)
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: 0xC8965A))
                            Text("\(preferredAddress.fullName) • \(preferredAddress.phone)")
                                .font(bodyFont(size: 13))
                                .foregroundColor(primaryTextColor)
                            Text("\(preferredAddress.line1), \(preferredAddress.city)")
                                .font(bodyFont(size: 13))
                                .foregroundColor(secondaryTextColor)
                        }

                        Spacer(minLength: 12)

                        Button {
                            cartOpen = false
                            isLibrarySectionExpanded = true
                            isDeliveryDetailsExpanded = true
                            activeTab = .account
                        } label: {
                            Text("Edit")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.5)
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: 0xC8965A))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Button {
                    cartOpen = false
                    isLibrarySectionExpanded = true
                    isDeliveryDetailsExpanded = true
                    activeTab = .account
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Delivery Address Needed")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.6)
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: 0xC8965A))
                            Text("Add your preferred address before checkout.")
                                .font(bodyFont(size: 13))
                                .foregroundColor(secondaryTextColor)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(hex: 0xC8965A))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var cartItemsListSection: some View {
        ForEach(cartItems) { item in
            HStack(spacing: 10) {
                ProductThumbnail(imageURL: item.product.imageURL, size: 44, cornerRadius: 8)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.product.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(primaryTextColor)

                    Text("\(item.product.price) x \(item.quantity)")
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(Color(hex: 0xC8965A))
                }

                Spacer()

                Button {
                    removeFromCart(id: item.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: 0xC8965A).opacity(0.2), lineWidth: 1)
                        )
                        .foregroundColor(Color(hex: 0xC8965A).opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
            .overlay(
                Rectangle()
                    .fill(Color(hex: 0xC8965A).opacity(0.08))
                    .frame(height: 1),
                alignment: .bottom
            )
        }
    }

    private var cartRewardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rewards & Voucher")
                .font(labelFont(size: 11, weight: .bold))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))

            Text("Apply a reward before opening checkout, or continue without one.")
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                TextField("Enter voucher code", text: $voucherCodeInput)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .font(bodyFont(size: 14))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(cardFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    Task {
                        await applyVoucher()
                    }
                } label: {
                    Text(isApplyingVoucher ? "..." : "Apply")
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(hex: 0xC8965A))
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isApplyingVoucher || voucherCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if let appliedVoucher {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(appliedVoucher.code)
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(Color(hex: 0xC8965A))

                        Spacer()

                        Button("Remove") {
                            removeAppliedVoucher()
                        }
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .buttonStyle(.plain)
                    }

                    Text(appliedVoucher.detail)
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Discount: \(formattedBHD(cartDiscount)) • Expires \(appliedVoucher.expiresAt.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: ""))")
                        .font(bodyFont(size: 12))
                        .foregroundColor(tertiaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            if let voucherError {
                Text(voucherError)
                    .font(bodyFont(size: 12))
                    .foregroundColor(Color.red.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let profile = customerProfile {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Your Active Vouchers")
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0xC8965A))

                        Spacer()

                        if isLoadingAvailableVouchers {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(Color(hex: 0xC8965A))
                        }
                    }

                    if availableVouchers.isEmpty {
                        Text("Redeem a reward in Account to see your active vouchers here.")
                            .font(bodyFont(size: 12))
                            .foregroundColor(secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        ForEach(availableVouchers.prefix(3)) { voucher in
                            Button {
                                voucherCodeInput = voucher.code
                                Task {
                                    await applyVoucher()
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(voucher.code)
                                            .font(labelFont(size: 10, weight: .bold))
                                            .tracking(1.2)
                                            .foregroundColor(Color(hex: 0xC8965A))

                                        Spacer()

                                        Text(formattedDiscountLabel(for: voucher))
                                            .font(bodyFont(size: 11))
                                            .foregroundColor(primaryTextColor)
                                    }

                                    Text(voucher.detail)
                                        .font(bodyFont(size: 12))
                                        .foregroundColor(secondaryTextColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(cardFillColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .task(id: profile.email + String(cartOpen)) {
                    guard cartOpen else { return }
                    await loadAvailableVouchers(for: profile.email)
                }
            }
        }
    }

    private var cartSaveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save Cart")
                .font(labelFont(size: 11, weight: .bold))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))

            HStack(spacing: 10) {
                TextField("Weekend beans, gifting run, office order...", text: $cartSaveName)
                    .font(bodyFont(size: 14))
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 14)
                    .background(cardFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button {
                    saveCurrentCart()
                } label: {
                    Text("Save")
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color(hex: 0xC8965A))
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color(hex: 0xC8965A))

            Text("Loading the shop")
                .font(.system(size: 12, weight: .medium))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var emptySection: some View {
        VStack(spacing: 12) {
            Text("No products match this category right now.")
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(secondaryTextColor)

            Button {
                activeCategory = "all"
            } label: {
                Text("Show All Products")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(3)
                    .textCase(.uppercase)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(hex: 0xC8965A))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .cornerRadius(2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func errorSection(message: String) -> some View {
        VStack(spacing: 14) {
            Text("We couldn’t load the shop.")
                .font(.system(size: 16, weight: .semibold, design: .serif))
                .foregroundColor(primaryTextColor)

            Text(message)
                .font(.system(size: 12, weight: .light))
                .multilineTextAlignment(.center)
                .foregroundColor(secondaryTextColor)

            Button {
                Task {
                    await loadProducts(force: true)
                }
            } label: {
                Text("Retry")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(3)
                    .textCase(.uppercase)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(Color(hex: 0xC8965A))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .cornerRadius(2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func productCard(product: Product, showDescription: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 10)
                    .frame(height: 184)

                VStack(alignment: .trailing, spacing: 8) {
                    Button {
                        toggleFavorite(product: product)
                    } label: {
                        Image(systemName: isFavorite(product) ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isFavorite(product) ? Color(hex: 0xC8965A) : primaryTextColor)
                            .frame(width: 34, height: 34)
                            .background(cardFillColor.opacity(0.92))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task {
                            await toggleAlert(product: product)
                        }
                    } label: {
                        Image(systemName: isAlertEnabled(product) ? "bell.fill" : "bell")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isAlertEnabled(product) ? Color(hex: 0xC8965A) : primaryTextColor)
                            .frame(width: 34, height: 34)
                            .background(cardFillColor.opacity(0.92))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    if let tag = product.tag {
                        Text(tag)
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(2)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(Color(hex: 0xC8965A))
                            .foregroundColor(Color(hex: 0x0A0804))
                            .cornerRadius(2)
                    }
                }
                .padding(10)
            }

            Text(product.categoryLabel)
                .font(labelFont(size: 10, weight: .semibold))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)

            Text(product.name)
                .font(titleFont(size: 20))
                .foregroundColor(primaryTextColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            if showDescription {
                Text(product.desc)
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Text(product.price)
                .font(labelFont(size: 13, weight: .bold))
                .foregroundColor(product.isAvailableForSale ? Color(hex: 0xC8965A) : tertiaryTextColor)

            Button {
                recordRecentlyViewed(product)
                selectedProduct = product
            } label: {
                Text("View Details")
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(cardFillColor)
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                    )
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                addToCart(product: product)
            } label: {
                Text(product.isAvailableForSale ? "Add to Bag" : "Sold Out")
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundColor(product.isAvailableForSale ? Color(hex: 0x0A0804) : tertiaryTextColor)
                    .glassEffect(
                        product.isAvailableForSale
                            ? .regular.tint(Color(hex: 0xC8965A)).interactive()
                            : .clear,
                        in: .capsule
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            .disabled(!product.isAvailableForSale || product.variantID == nil)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardFillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .simultaneousGesture(
            TapGesture().onEnded {
                recordRecentlyViewed(product)
            }
        )
    }

    private func productDetailSheet(product: Product) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 22)
                    .frame(height: 280)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.categoryLabel)
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0xC8965A))

                        Text(product.name)
                            .font(titleFont(size: 28))
                            .foregroundColor(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if let tag = product.tag {
                        Text(tag)
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(1.8)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(hex: 0xC8965A))
                            .clipShape(Capsule())
                    }
                }

                Text(product.price)
                    .font(displayFont(size: 24))
                    .foregroundColor(product.isAvailableForSale ? Color(hex: 0xC8965A) : tertiaryTextColor)

                Text(product.desc)
                    .font(bodyFont(size: 15))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    DetailStatusCardView(
                        title: "Availability",
                        detail: product.isAvailableForSale ? "Ready to order now" : "Currently sold out",
                        titleFont: labelFont(size: 10, weight: .bold),
                        detailFont: bodyFont(size: 13),
                        accentColor: Color(hex: 0xC8965A),
                        primaryTextColor: primaryTextColor,
                        backgroundColor: cardFillColor,
                        strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08)
                    )
                    DetailStatusCardView(
                        title: "Category",
                        detail: product.categoryLabel,
                        titleFont: labelFont(size: 10, weight: .bold),
                        detailFont: bodyFont(size: 13),
                        accentColor: Color(hex: 0xC8965A),
                        primaryTextColor: primaryTextColor,
                        backgroundColor: cardFillColor,
                        strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08)
                    )
                }

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Button {
                            toggleFavorite(product: product)
                        } label: {
                            Label(isFavorite(product) ? "Saved" : "Save", systemImage: isFavorite(product) ? "heart.fill" : "heart")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.4)
                                .textCase(.uppercase)
                                .foregroundColor(primaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(cardFillColor)
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Button {
                            Task {
                                await toggleAlert(product: product)
                            }
                        } label: {
                            Label(isAlertEnabled(product) ? "Watching" : "Watch", systemImage: isAlertEnabled(product) ? "bell.fill" : "bell")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.4)
                                .textCase(.uppercase)
                                .foregroundColor(primaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(cardFillColor)
                                .overlay(
                                    Capsule()
                                        .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        addToCart(product: product)
                        selectedProduct = nil
                    } label: {
                        Text(product.isAvailableForSale ? "Add to Bag" : "Sold Out")
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundColor(product.isAvailableForSale ? Color(hex: 0x0A0804) : tertiaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .glassEffect(
                                product.isAvailableForSale
                                    ? .regular.tint(Color(hex: 0xC8965A)).interactive()
                                    : .clear,
                                in: .capsule
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!product.isAvailableForSale || product.variantID == nil)
                }
            }
            .padding(20)
        }
        .background(backgroundGradientColors[0].ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    private func collectionTile(eyebrow: String, name: String, desc: String, accent: String, systemImage: String, color: Color, categoryKey: String) -> some View {
        Button {
            activeTab = .shop
            activeCategory = categoryKey
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(eyebrow)
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(2.4)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0xC8965A))

                        Text(name)
                            .font(titleFont(size: 22))
                            .foregroundColor(primaryTextColor)
                    }

                    Spacer()

                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(Color(hex: 0xC8965A))
                }

                Text(desc)
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                HStack(alignment: .center) {
                    Text(accent)
                        .font(bodyFont(size: 12))
                        .foregroundColor(tertiaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 10)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: 0xC8965A).opacity(0.72))
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [color.opacity(0.78), color.opacity(0.56)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func featureItem(symbol: String, eyebrow: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: eyebrow.isEmpty ? 0 : 8) {
                    if !eyebrow.isEmpty {
                        Text(eyebrow)
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(2.4)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0xA46A31))
                    }

                    Text(title)
                        .font(titleFont(size: 17))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: 0xF4E6D2).opacity(isLightAppearance ? 0.95 : 0.12))
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: 0xA46A31))
                }
                .frame(width: 38, height: 38)
            }

            Text(detail)
                .font(bodyFont(size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 154, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isLightAppearance
                            ? [
                                Color(hex: 0xFFF9F1),
                                Color(hex: 0xF2E0C7)
                            ]
                            : [
                                Color(hex: 0x241A12).opacity(0.94),
                                elevatedSurfaceColor.opacity(0.96)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.18 : 0.08), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: 0xD8AE72).opacity(isLightAppearance ? 0.16 : 0.08))
                .frame(width: 68, height: 68)
                .blur(radius: 10)
                .offset(x: 14, y: -10)
        }
    }

    private func heroStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(value)
                .font(titleFont(size: 22))
                .foregroundColor(primaryTextColor)

            Text(label)
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Capsule(style: .continuous)
                .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.22 : 0.14))
                .frame(width: 34, height: 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: isLightAppearance
                            ? [
                                Color.white.opacity(0.88),
                                Color(hex: 0xF3E3CC).opacity(0.94)
                            ]
                            : [
                                Color.white.opacity(0.03),
                                Color(hex: 0x2A1D14).opacity(0.82)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.18 : 0.09), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: 0xD6A667).opacity(isLightAppearance ? 0.16 : 0.08))
                .frame(width: 42, height: 42)
                .blur(radius: 8)
                .offset(x: 6, y: -6)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func loyaltyBenefit(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(labelFont(size: 11, weight: .bold))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))

            Text(detail)
                .font(bodyFont(size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func loyaltyRewardsActions(account: LoyaltyAccount) -> some View {
        LoyaltyRewardsActionsView(
            account: account,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: Color(hex: 0xC8965A),
            isLightAppearance: isLightAppearance,
            isRedeemingReward: isRedeemingReward,
            redeemAction: { points, reward in
                Task {
                    await redeemReward(points: points, reward: reward)
                }
            }
        )
    }

    private func loyaltyProgressCard(title: String, accent: String, current: Int, target: Int, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))

                Spacer()

                Text("\(current)/\(target)")
                    .font(bodyFont(size: 12))
                    .foregroundColor(secondaryTextColor)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.10))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xC8965A), Color(hex: 0x8A5E30)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(proxy.size.width * fraction, 10))
                }
            }
            .frame(height: 10)

            Text(accent)
                .font(bodyFont(size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var expiringRewardsSection: some View {
        ExpiringRewardsSectionView(
            vouchers: expiringVouchers,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            expiryLabel: { voucher in
                voucherExpiryLabel(for: voucher)
            },
            expiresSoon: { voucher in
                voucherExpiresSoon(voucher)
            }
        )
    }

    private func loyaltyTransactionsSection(account: LoyaltyAccount) -> some View {
        LoyaltyTransactionsSectionView(
            account: account,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance
        )
    }

    private var walletCallToAction: some View {
        LoyaltyWalletCallToActionView(
            isLoadingWalletPass: isLoadingWalletPass,
            isWalletPassAdded: isLoyaltyPassInWallet,
            tertiaryTextColor: tertiaryTextColor,
            action: {
                Task {
                    await addLoyaltyPassToWallet()
                }
            }
        )
    }

    private func infoChip(symbol: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundColor(Color(hex: 0xC8965A))

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(secondaryTextColor)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(hex: 0xC8965A).opacity(0.15), lineWidth: 1)
        )
    }

    private func infoTile(title: String, detail: String, actionTitle: String, destination: URL) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(titleFont(size: 20))
                    .foregroundColor(primaryTextColor)

                Text(detail)
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Link(actionTitle, destination: destination)
                .font(labelFont(size: 11, weight: .bold))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))
        }
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func socialChip(label: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(label)
        }
        .font(.system(size: 10, weight: .medium))
        .tracking(2)
        .textCase(.uppercase)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color(hex: 0xC8965A).opacity(0.2), lineWidth: 1)
        )
        .foregroundColor(primaryTextColor)
    }

    private func formattedRatioValue(_ value: Double) -> String {
        if value == 0 {
            return "0"
        }

        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value)
    }

    private func displayFont(size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size, relativeTo: .largeTitle)
    }

    private func titleFont(size: CGFloat) -> Font {
        .custom("Georgia-Bold", size: size, relativeTo: .title3)
    }

    private func bodyFont(size: CGFloat) -> Font {
        .custom("AvenirNext-Regular", size: size, relativeTo: .body)
    }

    private func labelFont(size: CGFloat, weight: Font.Weight) -> Font {
        switch weight {
        case .bold:
            return .custom("AvenirNext-Bold", size: size, relativeTo: .caption)
        case .semibold:
            return .custom("AvenirNext-DemiBold", size: size, relativeTo: .caption)
        default:
            return .custom("AvenirNext-Medium", size: size, relativeTo: .caption)
        }
    }

    @MainActor
    private func loadProductsIfNeeded() async {
        guard !hasLoadedProducts else { return }
        await loadProducts()
        await loadBrewingMethodsIfNeeded()

        if !savedCustomerEmail.isEmpty, customerProfile == nil {
            await loadCustomerProfile()
        }

        if !savedLoyaltyEmail.isEmpty, loyaltyEmail.isEmpty {
            loyaltyEmail = savedLoyaltyEmail
            await loadLoyaltyAccount()
        }
    }

    @MainActor
    private func signInCustomer() async {
        let trimmedEmail = normalizedAccountEmail
        guard !trimmedEmail.isEmpty, !accountPassword.isEmpty else {
            customerAuthError = "Enter your customer email and password."
            return
        }

        isSigningIn = true
        customerAuthError = nil

        do {
            let session = try await AccountService.signIn(email: trimmedEmail, password: accountPassword)
            applySignedInSession(session)
            accountPassword = ""
            showToast(message: "Signed in")
        } catch {
            customerProfile = nil
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isSigningIn = false
    }

    private func switchAccountAuthMode(_ mode: AccountAuthMode) {
        accountAuthMode = mode
        customerAuthError = nil
        accountPassword = ""
        accountConfirmPassword = ""
    }

    @MainActor
    private func createCustomerAccount() async {
        let trimmedFirstName = accountFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = accountLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = normalizedAccountEmail

        guard !trimmedFirstName.isEmpty, !trimmedLastName.isEmpty, !trimmedEmail.isEmpty, !accountPassword.isEmpty else {
            customerAuthError = "Complete your name, email, and password to create an account."
            return
        }

        guard accountPassword == accountConfirmPassword else {
            customerAuthError = "Your password confirmation does not match."
            return
        }

        guard accountPassword.count >= 5 else {
            customerAuthError = "Use a password with at least 5 characters."
            return
        }

        isCreatingAccount = true
        customerAuthError = nil

        do {
            let session = try await AccountService.register(
                firstName: trimmedFirstName,
                lastName: trimmedLastName,
                email: trimmedEmail,
                password: accountPassword
            )

            applySignedInSession(session)
            accountPassword = ""
            accountConfirmPassword = ""
            accountAuthMode = .signIn
            showToast(message: "Account created")
        } catch {
            customerProfile = nil
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isCreatingAccount = false
    }

    @MainActor
    private func requestPasswordResetLink() async {
        let trimmedEmail = normalizedAccountEmail
        guard !trimmedEmail.isEmpty else {
            customerAuthError = "Enter your email address first."
            return
        }

        isRequestingPasswordResetLink = true
        customerAuthError = nil

        do {
            try await AccountService.requestPasswordResetLink(email: trimmedEmail)
            accountPassword = ""
            showToast(message: "If an account exists for that email, a reset link has been sent.")
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(
                for: error,
                fallback: "Password reset email is unavailable right now."
            )
        }

        isRequestingPasswordResetLink = false
    }

    @MainActor
    private func loadCustomerProfile() async {
        guard !savedCustomerAccessToken.isEmpty, !isLoadingCustomer else { return }

        isLoadingCustomer = true
        customerAuthError = nil

        do {
            let profile = try await AccountService.fetchProfile()
            applySignedInProfile(profile, loadLoyalty: loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } catch {
            signOutCustomer(clearError: false)
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isLoadingCustomer = false
    }

    private func signOutCustomer(clearError: Bool = true) {
        savedCustomerEmail = ""
        savedCustomerAccessToken = ""
        customerProfile = nil
        accountAuthMode = .signIn
        accountFirstName = ""
        accountLastName = ""
        accountPassword = ""
        accountConfirmPassword = ""
        profileFirstName = ""
        profileLastName = ""
        currentPasswordInput = ""
        newPasswordInput = ""
        confirmNewPasswordInput = ""
        orderHistory = []
        ordersError = nil
        backendStockAlerts = []
        availableVouchers = []
        appliedVoucher = nil
        voucherCodeInput = ""
        voucherError = nil

        if clearError {
            customerAuthError = nil
        }
    }

    @MainActor
    private func applySignedInProfile(_ profile: ShopifyCustomerProfile, loadLoyalty: Bool = true) {
        savedCustomerEmail = profile.email
        customerProfile = profile
        accountEmail = profile.email
        profileFirstName = profile.firstName ?? ""
        profileLastName = profile.lastName ?? ""

        if loadLoyalty && loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            loyaltyEmail = profile.email
        }

        Task {
            await refreshWalletPassPresence()
            if loadLoyalty && loyaltyEmail == profile.email {
                await loadLoyaltyAccount()
            }
            await loadOrderHistory()
            await syncBackendStockAlerts()
            await loadBackendStockAlerts()
            await loadAddresses()
            await loadAlertInbox()
        }
    }

    @MainActor
    private func applySignedInSession(_ session: AccountService.CustomerSession, loadLoyalty: Bool = true) {
        savedCustomerAccessToken = session.accessToken
        applySignedInProfile(session.profile, loadLoyalty: loadLoyalty)
    }

    @MainActor
    private func saveProfile() async {
        guard let profile = customerProfile else { return }
        let firstName = profileFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = profileLastName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !firstName.isEmpty, !lastName.isEmpty else {
            customerAuthError = "Enter both first and last name before saving."
            return
        }

        isSavingProfile = true
        customerAuthError = nil

        do {
            let updated = try await AccountService.updateProfile(email: profile.email, firstName: firstName, lastName: lastName)
            customerProfile = updated
            profileFirstName = updated.firstName ?? ""
            profileLastName = updated.lastName ?? ""
            showToast(message: "Profile updated")
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isSavingProfile = false
    }

    @MainActor
    private func resetPassword() async {
        guard let profile = customerProfile else { return }

        guard newPasswordInput == confirmNewPasswordInput else {
            customerAuthError = "The new password confirmation does not match."
            return
        }

        guard newPasswordInput.count >= 5 else {
            customerAuthError = "Use a password with at least 5 characters."
            return
        }

        isResettingPassword = true
        customerAuthError = nil

        do {
            try await AccountService.resetPassword(
                email: profile.email,
                currentPassword: currentPasswordInput,
                newPassword: newPasswordInput
            )
            currentPasswordInput = ""
            newPasswordInput = ""
            confirmNewPasswordInput = ""
            showToast(message: "Password updated")
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isResettingPassword = false
    }

    @MainActor
    private func refreshWalletPassPresence() async {
#if canImport(PassKit)
        guard PKPassLibrary.isPassLibraryAvailable() else {
            isLoyaltyPassInWallet = false
            return
        }

        guard let email = customerProfile?.email ?? (!savedLoyaltyEmail.isEmpty ? savedLoyaltyEmail : nil) else {
            isLoyaltyPassInWallet = false
            return
        }

        do {
            let pass = try await AccountService.fetchWalletPass(email: email)
            isLoyaltyPassInWallet = PKPassLibrary().containsPass(pass)
        } catch {
            isLoyaltyPassInWallet = false
        }
#else
        isLoyaltyPassInWallet = false
#endif
    }

    @MainActor
    private func changePasswordWithoutSignIn() async {
        let trimmedEmail = normalizedAccountEmail

        guard !trimmedEmail.isEmpty, !accountPassword.isEmpty, !accountConfirmPassword.isEmpty else {
            customerAuthError = "Enter your email, current password, and new password."
            return
        }

        guard accountConfirmPassword.count >= 5 else {
            customerAuthError = "Use a password with at least 5 characters."
            return
        }

        isResettingPassword = true
        customerAuthError = nil

        do {
            try await AccountService.changePasswordWithoutSignIn(
                email: trimmedEmail,
                currentPassword: accountPassword,
                newPassword: accountConfirmPassword
            )
            accountAuthMode = .signIn
            accountPassword = ""
            accountConfirmPassword = ""
            showToast(message: "Password updated")
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isResettingPassword = false
    }

    @MainActor
    private func loadOrderHistory() async {
        guard let profile = customerProfile, !isLoadingOrders else { return }

        isLoadingOrders = true
        ordersError = nil

        do {
            orderHistory = try await AccountService.fetchOrders(email: profile.email)
        } catch {
            orderHistory = []
            ordersError = error.localizedDescription
        }

        isLoadingOrders = false
    }

    @MainActor
    private func loadBackendStockAlerts() async {
        guard let profile = customerProfile, !isLoadingBackendAlerts else { return }

        isLoadingBackendAlerts = true
        do {
            backendStockAlerts = try await AccountService.fetchStockAlerts(email: profile.email)
        } catch {
            backendStockAlerts = []
        }
        isLoadingBackendAlerts = false
    }

    @MainActor
    private func loadAddresses() async {
        guard let profile = customerProfile else { return }
        if let loaded = try? await AccountService.fetchAddresses(email: profile.email) {
            addresses = loaded
        }
    }

    @MainActor
    private func loadAlertInbox() async {
        guard let profile = customerProfile else { return }
        if let loaded = try? await AccountService.fetchAlertInbox(email: profile.email) {
            alertInbox = loaded
        }
    }

    @MainActor
    private func syncBackendStockAlerts() async {
        guard let profile = customerProfile, !alertProducts.isEmpty else { return }

        let records = alertProducts.map {
            StockAlertRecord(
                productID: $0.id,
                productName: $0.name,
                tag: $0.tag,
                isAvailableForSale: $0.isAvailableForSale,
                status: $0.isAvailableForSale ? "Roast watch" : "Waiting for restock",
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
        }

        if let synced = try? await AccountService.syncStockAlerts(email: profile.email, alerts: records) {
            backendStockAlerts = synced
        }
    }

    @MainActor
    private func saveAddress() async {
        guard let profile = customerProfile else { return }
        let label = addressLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullName = addressFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = addressPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let line1 = addressLine1.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = addressCity.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = addressNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !label.isEmpty, !fullName.isEmpty, !phone.isEmpty, !line1.isEmpty, !city.isEmpty else {
            showToast(message: "Complete the address details first")
            return
        }

        isSavingAddress = true
        defer { isSavingAddress = false }

        do {
            addresses = try await AccountService.saveAddress(
                email: profile.email,
                label: label,
                fullName: fullName,
                phone: phone,
                line1: line1,
                city: city,
                notes: notes.isEmpty ? nil : notes
            )
            addressLabel = ""
            addressFullName = ""
            addressPhone = ""
            addressLine1 = ""
            addressCity = ""
            addressNotes = ""
            showToast(message: "Address saved")
        } catch {
            showToast(message: error.localizedDescription)
        }
    }

    @MainActor
    private func deleteAddress(_ address: DeliveryAddress) async {
        guard let profile = customerProfile else { return }

        do {
            addresses = try await AccountService.deleteAddress(email: profile.email, addressID: address.id)
            showToast(message: "Address removed")
        } catch {
            showToast(message: error.localizedDescription)
        }
    }

    @MainActor
    private func recordSampleOrder() async {
        guard let profile = customerProfile else { return }

        isRecordingSampleOrder = true
        ordersError = nil

        do {
            orderHistory = try await AccountService.createSampleOrder(email: profile.email)
            loyaltyEmail = profile.email
            loyaltyAccount = try await LoyaltyService.fetchAccount(email: profile.email)
            savedLoyaltyEmail = profile.email
            showToast(message: "Sample order added • 85 points earned")
        } catch {
            ordersError = error.localizedDescription
        }

        isRecordingSampleOrder = false
    }

    private func friendlyCustomerAuthMessage(for error: Error, fallback: String? = nil) -> String {
        if let urlError = error as? URLError,
           [.cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost, .notConnectedToInternet].contains(urlError.code) {
            return BackendConfiguration.connectionMessage(for: "account service")
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = message.lowercased()

        if normalized.contains("backendbaseurl") || normalized.contains("127.0.0.1") || normalized.contains("localhost") {
            return fallback ?? message
        }

        if normalized.contains("invalid email or password") {
            return fallback ?? "The email or password is incorrect."
        }

        if normalized.contains("account already exists") {
            return fallback ?? "An account with this email already exists."
        }

        if normalized.contains("account not found") {
            return fallback ?? "No account was found for that email."
        }

        if normalized.contains("password reset email is not configured") || normalized.contains("password reset email could not be sent") {
            return fallback ?? "Password reset email is unavailable right now."
        }

        if normalized.contains("unidentified customer") {
            return fallback ?? "This account could not be recognized yet. Check that the email and password are correct and try again."
        }

        return fallback ?? message
    }

    private var normalizedAccountEmail: String {
        accountEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    @MainActor
    private func loadProducts(force: Bool = false) async {
        guard !isLoadingProducts else { return }
        guard force || !hasLoadedProducts else { return }

        isLoadingProducts = true
        loadingError = nil

        do {
            let fetchedProducts = try await ShopifyStorefrontClient.fetchAllProducts()
            products = fetchedProducts
            hasLoadedProducts = true

            if !availableCategories.contains(where: { $0.key == activeCategory }) {
                activeCategory = "all"
            }

            if customerProfile != nil {
                await syncBackendStockAlerts()
                await loadBackendStockAlerts()
            }
        } catch {
            loadingError = error.localizedDescription
        }

        isLoadingProducts = false
    }

    @MainActor
    private func loadBrewingMethodsIfNeeded() async {
        guard !hasLoadedBrewingMethods else { return }
        await loadBrewingMethods()
    }

    @MainActor
    private func loadBrewingMethods(force: Bool = false) async {
        guard !isLoadingBrewingMethods else { return }
        guard force || !hasLoadedBrewingMethods else { return }

        isLoadingBrewingMethods = true
        brewingMethodsError = nil

        do {
            brewingMethods = try await ShopifyStorefrontClient.fetchBrewingMethods()
            hasLoadedBrewingMethods = true
        } catch {
            brewingMethods = []
            brewingMethodsError = "Brewing articles couldn't be loaded from Shopify. Showing curated fallback methods."
        }

        isLoadingBrewingMethods = false
    }

    @MainActor
    private func loadLoyaltyAccount() async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = "Enter the email you use for your coffee orders."
            return
        }

        isLoadingLoyalty = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.fetchAccount(email: trimmedEmail)
            savedLoyaltyEmail = trimmedEmail
            await loadAvailableVouchers(for: trimmedEmail)
            showToast(message: "Rewards loaded")
        } catch {
            loyaltyAccount = nil
            loyaltyError = error.localizedDescription
        }

        isLoadingLoyalty = false
    }

    @MainActor
    private func redeemReward(points: Int, reward: String) async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = "Enter the email tied to your rewards account first."
            return
        }

        isRedeemingReward = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.redeemReward(email: trimmedEmail, points: points, reward: reward)
            let voucherCode = loyaltyAccount?.transactions.first(where: { $0.type == "redeem" })?.voucherCode
            if let voucherCode, !voucherCode.isEmpty {
                showToast(message: "\(reward) redeemed • \(voucherCode)")
            } else {
                showToast(message: "\(reward) redeemed")
            }
        } catch {
            loyaltyError = error.localizedDescription
        }

        isRedeemingReward = false
    }

    @MainActor
    private func earnPoints(points: Int, note: String) async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = "Enter the email tied to your rewards account first."
            return
        }

        isEarningPoints = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.earnPoints(email: trimmedEmail, points: points, note: note)
            showToast(message: "\(points) points added")
        } catch {
            loyaltyError = error.localizedDescription
        }

        isEarningPoints = false
    }

    private func addToCart(product: Product) {
        guard product.isAvailableForSale, product.variantID != nil else {
            showToast(message: "\(product.name) is unavailable")
            return
        }

        recordRecentlyViewed(product)

        if let index = cartItems.firstIndex(where: { $0.id == product.id }) {
            cartItems[index].quantity += 1
        } else {
            cartItems.append(CartItem(id: product.id, product: product, quantity: 1))
        }

        checkoutError = nil
        showToast(message: "\(product.name) added to cart")
    }

    private func removeFromCart(id: String) {
        cartItems.removeAll { $0.id == id }
    }

    private func isFavorite(_ product: Product) -> Bool {
        favoriteProductIDs.contains(product.id)
    }

    private func isAlertEnabled(_ product: Product) -> Bool {
        alertProductIDs.contains(product.id)
    }

    private func persistBrewRecipes(_ recipes: [BrewRecipe]) {
        guard let data = try? JSONEncoder().encode(recipes),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        savedBrewRecipes = json
    }

    private func saveCurrentBrewRecipe() {
        guard ratioCoffeeAmount > 0, ratioValue > 0 else {
            showToast(message: "Enter a valid brew recipe first")
            return
        }

        let trimmedName = brewRecipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        let recipe = BrewRecipe(
            id: UUID(),
            name: trimmedName.isEmpty ? defaultBrewRecipeName() : trimmedName,
            coffeeGrams: ratioCoffeeAmount,
            ratio: ratioValue,
            waterGrams: calculatedWaterAmount,
            category: activeBrewingCategory == "All" ? "Custom Brew" : activeBrewingCategory,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        persistBrewRecipes([recipe] + brewRecipes)
        brewRecipeName = ""
        showToast(message: "Brew recipe saved")
    }

    private func applyBrewRecipe(_ recipe: BrewRecipe) {
        ratioCoffeeInput = formattedRatioValue(recipe.coffeeGrams)
        ratioValueInput = formattedRatioValue(recipe.ratio)
        activeTab = .brewing
        showToast(message: "\(recipe.name) loaded")
    }

    private func deleteBrewRecipe(_ recipe: BrewRecipe) {
        persistBrewRecipes(brewRecipes.filter { $0.id != recipe.id })
        showToast(message: "Brew recipe deleted")
    }

    private func defaultBrewRecipeName() -> String {
        let category = activeBrewingCategory == "All" ? "House Ratio" : activeBrewingCategory
        return "\(category) \(formattedRatioValue(ratioCoffeeAmount))g"
    }

    private func persistSavedCarts(_ carts: [SavedCart]) {
        guard let data = try? JSONEncoder().encode(carts),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        savedCartsPayload = json
    }

    private func saveCurrentCart() {
        guard !cartItems.isEmpty else {
            showToast(message: "Add items before saving a cart")
            return
        }

        let trimmedName = cartSaveName.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedCart = SavedCart(
            id: UUID(),
            name: trimmedName.isEmpty ? defaultSavedCartName() : trimmedName,
            items: cartItems.map {
                SavedCart.Item(productID: $0.product.id, productName: $0.product.name, quantity: $0.quantity)
            },
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        persistSavedCarts([savedCart] + savedCarts)
        cartSaveName = ""
        showToast(message: "Cart saved")
    }

    private func applySavedCart(_ savedCart: SavedCart) {
        let matchedItems = savedCart.items.compactMap { item -> (Product, Int)? in
            if let product = products.first(where: { $0.id == item.productID }) ?? matchingProduct(for: item.productName) {
                return (product, item.quantity)
            }

            return nil
        }

        guard !matchedItems.isEmpty else {
            showToast(message: "Saved cart items are unavailable right now")
            return
        }

        cartItems = []
        for (product, quantity) in matchedItems {
            cartItems.append(CartItem(id: product.id, product: product, quantity: quantity))
        }

        cartOpen = true
        showToast(message: "\(savedCart.name) loaded")
    }

    private func deleteSavedCart(_ savedCart: SavedCart) {
        persistSavedCarts(savedCarts.filter { $0.id != savedCart.id })
        showToast(message: "Saved cart deleted")
    }

    private func defaultSavedCartName() -> String {
        let itemCount = cartItems.reduce(0) { $0 + $1.quantity }
        return "Cart \(itemCount) items"
    }

    private func toggleFavorite(product: Product) {
        var updatedFavorites = favoriteProductIDs
        recordRecentlyViewed(product)

        if updatedFavorites.contains(product.id) {
            updatedFavorites.remove(product.id)
            showToast(message: "Removed from favorites")
        } else {
            updatedFavorites.insert(product.id)
            showToast(message: "Saved to favorites")
        }

        savedFavoriteProductIDs = updatedFavorites.sorted().joined(separator: ",")
    }

    @MainActor
    private func toggleAlert(product: Product) async {
        var updatedAlerts = alertProductIDs

        if updatedAlerts.contains(product.id) {
            updatedAlerts.remove(product.id)
            if let email = customerProfile?.email {
                try? await AccountService.removeStockAlert(email: email, productID: product.id)
                backendStockAlerts.removeAll { $0.productID == product.id }
            }
            await ProductAlertNotificationService.removeReminder(for: product.id)
            showToast(message: "Removed from alerts")
        } else {
            updatedAlerts.insert(product.id)
            recordRecentlyViewed(product)
            if let email = customerProfile?.email {
                let record = StockAlertRecord(
                    productID: product.id,
                    productName: product.name,
                    tag: product.tag,
                    isAvailableForSale: product.isAvailableForSale,
                    status: product.isAvailableForSale ? "Roast watch" : "Waiting for restock",
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                )
                if let stored = try? await AccountService.watchStockAlert(email: email, alert: record) {
                    backendStockAlerts.removeAll { $0.productID == stored.productID }
                    backendStockAlerts.insert(stored, at: 0)
                }
            }
            let granted = await requestNotificationAccessIfNeeded()
            if granted {
                await ProductAlertNotificationService.scheduleReminder(
                    for: product.id,
                    title: notificationTitle(for: product),
                    body: notificationBody(for: product)
                )
            }
            showToast(message: "Added to alerts")
        }

        savedAlertProductIDs = updatedAlerts.sorted().joined(separator: ",")
    }

    private func recordRecentlyViewed(_ product: Product) {
        var updated = recentlyViewedProductIDs.filter { $0 != product.id }
        updated.insert(product.id, at: 0)
        updated = Array(updated.prefix(12))
        savedRecentlyViewedProductIDs = updated.joined(separator: ",")
    }

    private func productAlertLabel(for product: Product) -> String {
        if !product.isAvailableForSale {
            return "Back in stock watch"
        }

        if let tag = product.tag, !tag.isEmpty {
            return "\(tag) watch"
        }

        return "New roast watch"
    }

    private func stockAlertLabel(for product: Product) -> String {
        backendStockAlertLookup[product.id]?.status ?? productAlertLabel(for: product)
    }

    private func notificationTitle(for product: Product) -> String {
        if !product.isAvailableForSale {
            return "\(product.name) watchlist reminder"
        }

        return "\(product.name) roast reminder"
    }

    private func notificationBody(for product: Product) -> String {
        if !product.isAvailableForSale {
            return "You asked to hear about \(product.name). Check Talla for availability updates."
        }

        return "Still thinking about \(product.name)? Your watched roast is waiting in the app."
    }

    @MainActor
    private func refreshNotificationStatus() async {
#if canImport(UserNotifications)
        let status = await ProductAlertNotificationService.authorizationStatus()
        notificationAuthorizationStatus = status.rawValue
#endif
    }

    @MainActor
    private func requestNotificationAccess() async {
        let granted = await ProductAlertNotificationService.requestAuthorization()
        await refreshNotificationStatus()

        if granted {
            showToast(message: "Notifications enabled")
        } else {
            showToast(message: "Notifications not enabled")
        }
    }

    @MainActor
    private func requestNotificationAccessIfNeeded() async -> Bool {
#if canImport(UserNotifications)
        let status = await ProductAlertNotificationService.authorizationStatus()
        notificationAuthorizationStatus = status.rawValue

        switch status {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            let granted = await ProductAlertNotificationService.requestAuthorization()
            await refreshNotificationStatus()
            return granted
        default:
            return false
        }
#else
        return false
#endif
    }

    private func buyAgain(order: AccountOrder) {
        guard let items = order.items, !items.isEmpty else { return }

        let matchedProducts = items.compactMap { item -> (Product, Int)? in
            guard let product = matchingProduct(for: item.name) else { return nil }
            return (product, item.quantity)
        }

        guard !matchedProducts.isEmpty else {
            showToast(message: "Those items are currently unavailable")
            return
        }

        for (product, quantity) in matchedProducts {
            if let index = cartItems.firstIndex(where: { $0.id == product.id }) {
                cartItems[index].quantity += quantity
            } else {
                cartItems.append(CartItem(id: product.id, product: product, quantity: quantity))
            }
        }

        checkoutError = nil
        cartOpen = true

        if matchedProducts.count == items.count {
            showToast(message: "Order added to cart")
        } else {
            showToast(message: "Available items from that order were added")
        }
    }

    private func matchingProduct(for orderItemName: String) -> Product? {
        let normalizedOrderName = normalizedProductName(orderItemName)

        return products.first { normalizedProductName($0.name) == normalizedOrderName }
            ?? products.first {
                let normalizedProduct = normalizedProductName($0.name)
                return normalizedProduct.contains(normalizedOrderName) || normalizedOrderName.contains(normalizedProduct)
            }
    }

    private func normalizedProductName(_ name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    @MainActor
    private func applyVoucher() async {
        guard let profile = customerProfile else {
            voucherError = "Sign in to apply a loyalty voucher."
            return
        }

        let trimmedCode = voucherCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedCode.isEmpty else {
            voucherError = "Enter a voucher code first."
            return
        }

        isApplyingVoucher = true
        voucherError = nil

        do {
            appliedVoucher = try await AccountService.previewVoucher(code: trimmedCode, email: profile.email)
            voucherCodeInput = trimmedCode
            await loadAvailableVouchers(for: profile.email)
            showToast(message: "Voucher applied")
        } catch {
            appliedVoucher = nil
            voucherError = error.localizedDescription
        }

        isApplyingVoucher = false
    }

    private func removeAppliedVoucher() {
        appliedVoucher = nil
        voucherError = nil
        voucherCodeInput = ""
    }

    @MainActor
    private func loadAvailableVouchers(for email: String) async {
        guard !email.isEmpty else { return }

        isLoadingAvailableVouchers = true

        do {
            availableVouchers = try await AccountService.fetchVouchers(email: email)
        } catch {
            availableVouchers = []
        }

        isLoadingAvailableVouchers = false
    }

    @MainActor
    private func beginCheckout() async {
        guard !isCheckingOut else { return }

        let lines = cartItems.compactMap { item -> ShopifyCheckoutLine? in
            guard let variantID = item.product.variantID else { return nil }
            return ShopifyCheckoutLine(merchandiseId: variantID, quantity: item.quantity)
        }

        guard !lines.isEmpty else {
            checkoutError = "Your cart has no purchasable items."
            return
        }

        let checkoutAddress = preferredAddress.flatMap { address -> ShopifyCheckoutAddress? in
            guard let profile = customerProfile else { return nil }
            return ShopifyCheckoutAddress(
                email: profile.email,
                fullName: address.fullName,
                phone: address.phone,
                address1: address.line1,
                city: address.city
            )
        }

        isCheckingOut = true
        checkoutError = nil

        do {
            if let appliedVoucher, let profile = customerProfile {
                _ = try await AccountService.consumeVoucher(code: appliedVoucher.code, email: profile.email)
                await loadAvailableVouchers(for: profile.email)
            }
            let checkoutURL = try await ShopifyStorefrontClient.createCheckoutURL(
                lines: lines,
                checkoutAddress: checkoutAddress
            )
            checkoutSession = CheckoutSession(url: checkoutURL)
            appliedVoucher = nil
            voucherCodeInput = ""
            voucherError = nil
            showToast(message: "Checkout opened")
        } catch {
            checkoutError = error.localizedDescription
        }

        isCheckingOut = false
    }

    @MainActor
    private func addLoyaltyPassToWallet() async {
#if canImport(PassKit)
        guard PKPassLibrary.isPassLibraryAvailable() else {
            showToast(message: "Apple Wallet is unavailable on this device")
            return
        }

        guard let email = customerProfile?.email ?? (!savedLoyaltyEmail.isEmpty ? savedLoyaltyEmail : nil) else {
            showToast(message: "Sign in before adding your Wallet pass")
            return
        }

        isLoadingWalletPass = true

        do {
            let pass = try await AccountService.fetchWalletPass(email: email)
            let library = PKPassLibrary()
            if library.containsPass(pass) {
                isLoyaltyPassInWallet = true
                showToast(message: "Loyalty card is already in Apple Wallet")
            } else {
                loyaltyWalletPass = WalletPassItem(pass: pass)
            }
        } catch {
            showToast(message: error.localizedDescription)
        }

        isLoadingWalletPass = false
#else
        showToast(message: "Apple Wallet is unavailable on this device")
#endif
    }

    private func showToast(message: String) {
        toastMessage = message

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            if toastMessage == message {
                toastMessage = nil
            }
        }
    }

    private func categoryDefinition(for key: String) -> ShopCategory {
        if key == "tea" {
            return categoryDefinition(for: "ready-made-drinks")
        }

        if key == "northern-coffee" {
            return categoryDefinition(for: "arabic-coffee-beans")
        }

        if key == "desserts" || key == "spreads" || key == "bread" {
            return categoryDefinition(for: "crmb-tallas-speciality-bakery")
        }

        if key == "other" {
            return categoryDefinition(for: "arabic-coffee-beans")
        }

        if let category = categoryCatalog.first(where: { $0.key == key }) {
            return category
        }

        let normalizedKey = key.replacingOccurrences(of: "_", with: "-")

        return ShopCategory(
            key: key,
            title: categoryLabel(for: key),
            subtitle: normalizedKey.contains("drink") ? "Live Shopify category" : "Shopify product type",
            symbol: categorySymbol(for: normalizedKey)
        )
    }

    private func categoryLabel(for key: String) -> String {
        guard key != "all" else { return "All" }
        if key == "tea" {
            return "Ready-Made Drinks"
        }
        if key == "northern-coffee" {
            return "Arabic & Shamali Coffee"
        }
        if key == "desserts" || key == "spreads" || key == "bread" {
            return "CRMB Talla's Speciality Bakery"
        }
        if key == "other" {
            return "Arabic & Shamali Coffee"
        }
        return key
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private func categorySymbol(for key: String) -> String {
        if key.contains("bean") || key.contains("coffee") {
            return "leaf.fill"
        }

        if key.contains("drip") {
            return "drop.fill"
        }

        if key.contains("equipment") {
            return "flask.fill"
        }

        if key.contains("drink") {
            return "takeoutbag.and.cup.and.straw.fill"
        }

        if key.contains("tea") {
            return "teapot.fill"
        }

        if key.contains("dessert") || key.contains("bread") {
            return "fork.knife"
        }

        if key.contains("chocolate") {
            return "mug.fill"
        }

        if key.contains("gift") {
            return "gift.fill"
        }

        return "shippingbox.fill"
    }

#if canImport(PassKit)
    private func bundledLoyaltyPass() -> PKPass? {
        guard let passURL = Bundle.main.url(forResource: "TallaLoyalty", withExtension: "pkpass"),
              let data = try? Data(contentsOf: passURL),
              let pass = try? PKPass(data: data) else {
            return nil
        }

        return pass
    }
#endif

    private func priceValue(from price: String) -> Double {
        let sanitized = price
            .replacingOccurrences(of: "BHD", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(sanitized) ?? 0
    }

    private func formattedBHD(_ value: Double) -> String {
        String(format: "BHD %.3f", value)
    }

    private func voucherExpiresSoon(_ voucher: VoucherRecord) -> Bool {
        guard let expiryDate = ISO8601DateFormatter().date(from: voucher.expiresAt) else { return false }
        return expiryDate.timeIntervalSinceNow <= 3 * 24 * 60 * 60
    }

    private func voucherExpiryLabel(for voucher: VoucherRecord) -> String {
        guard let expiryDate = ISO8601DateFormatter().date(from: voucher.expiresAt) else {
            return "Active"
        }

        let days = max(Int(ceil(expiryDate.timeIntervalSinceNow / (24 * 60 * 60))), 0)
        if days <= 0 {
            return "Expires today"
        }
        if days == 1 {
            return "1 day left"
        }
        return "\(days) days left"
    }

    private func formattedDiscountLabel(for voucher: VoucherRecord) -> String {
        switch voucher.reward.lowercased() {
        case "free drink":
            return "BHD 2.500"
        case "pastry pairing":
            return "BHD 2.000"
        case "bag discount":
            return "10% off"
        case "brew bar credit":
            return "BHD 3.000"
        case "talla box reward":
            return "15% off"
        case "roastery gold reward":
            return "20% off"
        default:
            return voucher.detail
        }
    }

}

private struct ProductThumbnail: View {
    @Environment(\.colorScheme) private var colorScheme

    let imageURL: URL?
    let size: CGFloat?
    let cornerRadius: CGFloat

    private var isLightAppearance: Bool {
        colorScheme == .light
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: isLightAppearance
                            ? [Color(hex: 0xFFF9F2), Color(hex: 0xF2E2CD)]
                            : [Color(hex: 0x1A1612), Color(hex: 0x100D08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08),
                            lineWidth: 1
                        )
                )

            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(Color(hex: 0xC8965A))

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(size == nil ? 12 : 4)

                    case .failure:
                        placeholder

                    @unknown default:
                        placeholder
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipped()
    }

    private var placeholder: some View {
        Image(systemName: "cup.and.saucer.fill")
            .font(.system(size: 28))
            .foregroundColor(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.66 : 0.8))
    }
}

#if canImport(UserNotifications)
private enum ProductAlertNotificationService {
    private static let center = UNUserNotificationCenter.current()

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    static func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    static func scheduleReminder(for productID: String, title: String, body: String) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: reminderIdentifier(for: productID),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 86_400, repeats: false)
        )

        do {
            try await center.add(request)
        } catch {
            return
        }
    }

    static func removeReminder(for productID: String) async {
        center.removePendingNotificationRequests(withIdentifiers: [reminderIdentifier(for: productID)])
    }

    private static func reminderIdentifier(for productID: String) -> String {
        "product-alert-\(productID)"
    }
}
#endif

private enum AccountService {
    private static let baseURL = BackendConfiguration.serviceBaseURL
    private static let sessionTokenKey = "local.customerAccessToken"

    struct CustomerSession {
        let profile: ContentView.ShopifyCustomerProfile
        let accessToken: String
        let expiresAt: String
    }

    private static var accessToken: String {
        UserDefaults.standard.string(forKey: sessionTokenKey) ?? ""
    }

    fileprivate static func authorize(_ request: inout URLRequest) throws {
        let token = accessToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            throw ContentView.LoyaltyServiceError.operationFailed("Sign in again to continue.")
        }

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    static func register(firstName: String, lastName: String, email: String, password: String) async throws -> CustomerSession {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Account service"))
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/register"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "firstName": firstName,
            "lastName": lastName,
            "email": email,
            "password": password
        ])

        return try await performCustomerSessionRequest(request)
    }

    static func signIn(email: String, password: String) async throws -> CustomerSession {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])

        return try await performCustomerSessionRequest(request)
    }

    static func fetchProfile() async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/session"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        return try await performProfileRequest(request)
    }

    static func updateProfile(email: String, firstName: String, lastName: String) async throws -> ContentView.ShopifyCustomerProfile {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/profile/update"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "firstName": firstName,
            "lastName": lastName
        ])

        return try await performProfileRequest(request)
    }

    static func resetPassword(email: String, currentPassword: String, newPassword: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/password/reset"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ])

        _ = try await performEmptyRequest(request)
    }

    static func changePasswordWithoutSignIn(email: String, currentPassword: String, newPassword: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/password/change"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "currentPassword": currentPassword,
            "newPassword": newPassword
        ])

        _ = try await performEmptyRequest(request)
    }

    static func requestPasswordResetLink(email: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/password/request-reset"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email
        ])

        _ = try await performEmptyRequest(request)
    }

    static func fetchOrders(email: String) async throws -> [ContentView.AccountOrder] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/orders"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        return try await performOrdersRequest(request)
    }

    static func createSampleOrder(email: String) async throws -> [ContentView.AccountOrder] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/orders/sample"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email
        ])

        return try await performOrdersRequest(request)
    }

    static func fetchStockAlerts(email: String) async throws -> [ContentView.StockAlertRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/alerts"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        return try await performStockAlertsRequest(request)
    }

    static func fetchAlertInbox(email: String) async throws -> [ContentView.AlertInboxRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/alerts/inbox"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts inbox URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        return try await performAlertInboxRequest(request)
    }

    static func watchStockAlert(email: String, alert: ContentView.StockAlertRecord) async throws -> ContentView.StockAlertRecord {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var payload = [
            "email": email,
            "productID": alert.productID,
            "productName": alert.productName,
            "isAvailableForSale": alert.isAvailableForSale
        ] as [String : Any]
        if let tag = alert.tag {
            payload["tag"] = tag
        }

        var request = URLRequest(url: baseURL.appending(path: "/alerts/watch"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await performStockAlertRequest(request)
    }

    static func removeStockAlert(email: String, productID: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/alerts/unwatch"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "productID": productID
        ])

        _ = try await performEmptyRequest(request)
    }

    static func syncStockAlerts(email: String, alerts: [ContentView.StockAlertRecord]) async throws -> [ContentView.StockAlertRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service is unavailable.")
        }

        let payloadAlerts = alerts.map { alert -> [String: Any] in
            var payload: [String: Any] = [
                "productID": alert.productID,
                "productName": alert.productName,
                "isAvailableForSale": alert.isAvailableForSale
            ]
            if let tag = alert.tag {
                payload["tag"] = tag
            }
            return payload
        }

        var request = URLRequest(url: baseURL.appending(path: "/alerts/sync"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "alerts": payloadAlerts
        ])

        return try await performStockAlertsRequest(request)
    }

    static func fetchAddresses(email: String) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/addresses"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        return try await performAddressesRequest(request)
    }

    static func saveAddress(email: String, label: String, fullName: String, phone: String, line1: String, city: String, notes: String?) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var payload: [String: Any] = [
            "email": email,
            "label": label,
            "fullName": fullName,
            "phone": phone,
            "line1": line1,
            "city": city
        ]
        if let notes {
            payload["notes"] = notes
        }

        var request = URLRequest(url: baseURL.appending(path: "/addresses/save"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return try await performAddressesRequest(request)
    }

    static func deleteAddress(email: String, addressID: String) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/addresses/delete"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "addressID": addressID
        ])

        return try await performAddressesRequest(request)
    }

    static func fetchVouchers(email: String) async throws -> [ContentView.VoucherRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/vouchers"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        return try await performVouchersRequest(request)
    }

    static func previewVoucher(code: String, email: String) async throws -> ContentView.VoucherRecord {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/vouchers/preview"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": code,
            "email": email
        ])

        return try await performVoucherRequest(request)
    }

    static func consumeVoucher(code: String, email: String) async throws -> ContentView.VoucherRecord {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/vouchers/consume"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "code": code,
            "email": email
        ])

        return try await performVoucherRequest(request)
    }

#if canImport(PassKit)
    static func fetchWalletPass(email: String) async throws -> PKPass {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The wallet service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/wallet/pass"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The wallet service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        try authorize(&request)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The wallet service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            guard let pass = try? PKPass(data: data) else {
                throw ContentView.LoyaltyServiceError.operationFailed("The Wallet pass could not be loaded.")
            }
            return pass
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The wallet service could not complete your request.")
    }
#endif

    private static func performCustomerSessionRequest(_ request: URLRequest) async throws -> CustomerSession {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            let decoded = try JSONDecoder().decode(AccountSessionResponse.self, from: data)
            return CustomerSession(
                profile: ContentView.ShopifyCustomerProfile(
                    id: decoded.profile.id,
                    firstName: decoded.profile.firstName,
                    lastName: decoded.profile.lastName,
                    email: decoded.profile.email
                ),
                accessToken: decoded.accessToken,
                expiresAt: decoded.expiresAt
            )
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The account service could not complete your request.")
    }

    private static func performProfileRequest(_ request: URLRequest) async throws -> ContentView.ShopifyCustomerProfile {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            let decoded = try JSONDecoder().decode(AccountProfileResponse.self, from: data)
            return ContentView.ShopifyCustomerProfile(
                id: decoded.id,
                firstName: decoded.firstName,
                lastName: decoded.lastName,
                email: decoded.email
            )
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The account service could not complete your request.")
    }

    private static func performOrdersRequest(_ request: URLRequest) async throws -> [ContentView.AccountOrder] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.AccountOrder].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The orders service could not complete your request.")
    }

    private static func performVouchersRequest(_ request: URLRequest) async throws -> [ContentView.VoucherRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.VoucherRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The voucher service could not complete your request.")
    }

    private static func performStockAlertsRequest(_ request: URLRequest) async throws -> [ContentView.StockAlertRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.StockAlertRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The alerts service could not complete your request.")
    }

    private static func performStockAlertRequest(_ request: URLRequest) async throws -> ContentView.StockAlertRecord {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(ContentView.StockAlertRecord.self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The alerts service could not complete your request.")
    }

    private static func performAlertInboxRequest(_ request: URLRequest) async throws -> [ContentView.AlertInboxRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The alerts inbox returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.AlertInboxRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The alerts inbox could not complete your request.")
    }

    private static func performAddressesRequest(_ request: URLRequest) async throws -> [ContentView.DeliveryAddress] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.DeliveryAddress].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The address service could not complete your request.")
    }

    private static func performVoucherRequest(_ request: URLRequest) async throws -> ContentView.VoucherRecord {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The voucher service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(ContentView.VoucherRecord.self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The voucher service could not complete your request.")
    }

    private static func performEmptyRequest(_ request: URLRequest) async throws -> Bool {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return true
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The account service could not complete your request.")
    }
}

private enum LoyaltyService {
    private static let baseURL = BackendConfiguration.serviceBaseURL

    static func fetchAccount(email: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Loyalty service"))
        }

        var components = URLComponents(url: baseURL.appending(path: "/loyalty/account"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try AccountService.authorize(&request)

        return try await performLoyaltyRequest(request)
    }

    static func redeemReward(email: String, points: Int, reward: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/loyalty/transactions/redeem"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try AccountService.authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "points": points,
            "reward": reward
        ])

        return try await performLoyaltyRequest(request)
    }

    static func earnPoints(email: String, points: Int, note: String) async throws -> ContentView.LoyaltyAccount {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/loyalty/transactions/earn"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try AccountService.authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "points": points,
            "note": note
        ])

        return try await performLoyaltyRequest(request)
    }

    private static func performLoyaltyRequest(_ request: URLRequest) async throws -> ContentView.LoyaltyAccount {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service returned an invalid response.")
        }

        if httpResponse.statusCode == 404 {
            throw ContentView.LoyaltyServiceError.missingAccount
        }

        if httpResponse.statusCode == 409 {
            throw ContentView.LoyaltyServiceError.insufficientPoints
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            do {
                return try JSONDecoder().decode(ContentView.LoyaltyAccount.self, from: data)
            } catch {
                throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service returned an invalid response.")
            }
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The loyalty service could not complete your request.")
    }
}

#if canImport(PassKit) && canImport(UIKit)
private struct WalletPassView: UIViewControllerRepresentable {
    let pass: PKPass

    func makeUIViewController(context: Context) -> UIViewController {
        guard let controller = PKAddPassesViewController(pass: pass) else {
            return UIViewController()
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    }
}
#endif

#if canImport(SafariServices) && canImport(UIKit)
private struct CheckoutWebView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.entersReaderIfAvailable = false

        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.dismissButtonStyle = .close
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}
#else
private struct CheckoutWebView: View {
    let url: URL

    var body: some View {
        VStack(spacing: 16) {
            Text("Checkout is only available on iPhone.")
                .font(.headline)
            Text(url.absoluteString)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(24)
    }
}
#endif

private enum ShopifyStorefrontClient {
    private static let endpoint = URL(string: "https://\(ShopifyConfiguration.shopDomain)/api/2025-10/graphql.json")!

    static func fetchAllProducts() async throws -> [ContentView.Product] {
        var products: [ContentView.Product] = []
        var cursor: String?
        var hasNextPage = true

        while hasNextPage {
            let response = try await fetchPage(after: cursor)

            products.append(contentsOf: response.products.edges.compactMap { edge in
                guard ContentView.Product.shouldInclude(shopifyNode: edge.node) else {
                    return nil
                }
                return ContentView.Product(shopifyNode: edge.node)
            })

            hasNextPage = response.products.pageInfo.hasNextPage
            cursor = response.products.pageInfo.endCursor
        }

        return products
    }

    static func fetchBrewingMethods() async throws -> [ContentView.BrewingMethod] {
        let body = ShopifyGraphQLRequest(
            query: """
            query BrewingArticles($handle: String!, $query: String!) {
              blog(handle: $handle) {
                articles(first: 12) {
                  edges {
                    node {
                      id
                      handle
                      title
                      excerpt
                      content(truncateAt: 180)
                      tags
                      onlineStoreUrl
                      blog {
                        handle
                        title
                      }
                    }
                  }
                }
              }
              articles(first: 12, sortKey: PUBLISHED_AT, reverse: true, query: $query) {
                edges {
                  node {
                    id
                    handle
                    title
                    excerpt
                    content(truncateAt: 180)
                    tags
                    onlineStoreUrl
                    blog {
                      handle
                      title
                    }
                  }
                }
              }
            }
            """,
            variables: [
                "handle": ShopifyConfiguration.brewingBlogHandle,
                "query": ShopifyConfiguration.brewingArticlesQuery
            ]
        )

        let decoded: ShopifyBrewingArticlesResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        let nodesFromBlog = decoded.data?.blog?.articles.edges.map(\.node) ?? []
        let fallbackNodes = decoded.data?.articles.edges.map(\.node) ?? []
        let selectedNodes = nodesFromBlog.isEmpty ? fallbackNodes : nodesFromBlog

        guard !selectedNodes.isEmpty else {
            throw ShopifyError.api("No brewing articles are available in Shopify yet.")
        }

        return selectedNodes.map(ContentView.BrewingMethod.init(article:))
    }

    static func createCustomerAccessToken(email: String, password: String) async throws -> ShopifyCustomerSession {
        let body = ShopifyGraphQLRequest(
            query: """
            mutation CustomerAccessTokenCreate($input: CustomerAccessTokenCreateInput!) {
              customerAccessTokenCreate(input: $input) {
                customerAccessToken {
                  accessToken
                  expiresAt
                }
                customerUserErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": [
                    "email": email,
                    "password": password
                ]
            ]
        )

        let decoded: ShopifyCustomerAccessTokenCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.customerAccessTokenCreate.customerUserErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let session = decoded.data?.customerAccessTokenCreate.customerAccessToken else {
            throw ShopifyError.invalidResponse
        }

        return session
    }

    static func createCustomer(firstName: String, lastName: String, email: String, password: String) async throws -> ShopifyCustomerCreateResponse.CreatedCustomer {
        let body = ShopifyGraphQLRequest(
            query: """
            mutation CustomerCreate($input: CustomerCreateInput!) {
              customerCreate(input: $input) {
                customer {
                  id
                }
                customerUserErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": [
                    "firstName": firstName,
                    "lastName": lastName,
                    "email": email,
                    "password": password
                ]
            ]
        )

        let decoded: ShopifyCustomerCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.customerCreate.customerUserErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let customer = decoded.data?.customerCreate.customer else {
            throw ShopifyError.invalidResponse
        }

        return customer
    }

    static func fetchCustomer(accessToken: String) async throws -> ContentView.ShopifyCustomerProfile {
        let body = ShopifyGraphQLRequest(
            query: """
            query Customer($customerAccessToken: String!) {
              customer(customerAccessToken: $customerAccessToken) {
                id
                firstName
                lastName
                email
              }
            }
            """,
            variables: [
                "customerAccessToken": accessToken
            ]
        )

        let decoded: ShopifyCustomerQueryResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        guard let customer = decoded.data?.customer else {
            throw ShopifyError.api("Your account session has expired. Please sign in again.")
        }

        return ContentView.ShopifyCustomerProfile(
            id: customer.id,
            firstName: customer.firstName,
            lastName: customer.lastName,
            email: customer.email
        )
    }

    private static func fetchPage(after cursor: String?) async throws -> ShopifyProductsResponse.DataPayload {
        let body = ShopifyGraphQLRequest(
            query: """
            query Products($cursor: String) {
              products(first: 50, after: $cursor, sortKey: TITLE) {
                pageInfo {
                  hasNextPage
                  endCursor
                }
                edges {
                  node {
                    id
                    title
                    description
                    tags
                    productType
                    featuredImage {
                      url
                    }
                    variants(first: 1) {
                      edges {
                        node {
                          id
                          availableForSale
                        }
                      }
                    }
                    priceRange {
                      minVariantPrice {
                        amount
                        currencyCode
                      }
                    }
                  }
                }
              }
            }
            """,
            variables: ["cursor": cursor as Any]
        )

        let decoded: ShopifyProductsResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        guard let payload = decoded.data else {
            throw ShopifyError.invalidResponse
        }

        return payload
    }

    static func createCheckoutURL(lines: [ShopifyCheckoutLine], checkoutAddress: ShopifyCheckoutAddress? = nil) async throws -> URL {
        let lineInputs = lines.map { line in
            [
                "merchandiseId": line.merchandiseId,
                "quantity": line.quantity
            ] as [String: Any]
        }

        let input: [String: Any]
        if let checkoutAddress {
            let nameParts = checkoutAddress.fullName
                .split(separator: " ", omittingEmptySubsequences: true)
                .map(String.init)
            let firstName = nameParts.first ?? checkoutAddress.fullName
            let lastName = nameParts.dropFirst().joined(separator: " ")
            let deliveryAddress: [String: Any] = [
                "address1": checkoutAddress.address1,
                "city": checkoutAddress.city,
                "country": "Bahrain",
                "firstName": firstName,
                "lastName": lastName,
                "phone": checkoutAddress.phone
            ]
            let deliveryAddressPreference: [String: Any] = [
                "deliveryAddress": deliveryAddress
            ]
            let buyerIdentity: [String: Any] = [
                "email": checkoutAddress.email,
                "phone": checkoutAddress.phone,
                "deliveryAddressPreferences": [deliveryAddressPreference]
            ]

            input = [
                "lines": lineInputs,
                "buyerIdentity": buyerIdentity
            ]
        } else {
            input = [
                "lines": lineInputs
            ]
        }

        let body = ShopifyGraphQLRequest(
            query: """
            mutation CreateCart($input: CartInput) {
              cartCreate(input: $input) {
                cart {
                  checkoutUrl
                }
                userErrors {
                  message
                }
              }
            }
            """,
            variables: [
                "input": input
            ]
        )

        let decoded: ShopifyCartCreateResponse = try await performRequest(body)

        if let errors = decoded.errors, let first = errors.first {
            throw ShopifyError.api(first.message)
        }

        if let userError = decoded.data?.cartCreate.userErrors.first {
            throw ShopifyError.api(userError.message)
        }

        guard let checkoutURL = decoded.data?.cartCreate.cart?.checkoutUrl else {
            throw ShopifyError.invalidResponse
        }

        return checkoutURL
    }

    private static func performRequest<Response: Decodable>(_ body: ShopifyGraphQLRequest) async throws -> Response {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ShopifyConfiguration.storefrontToken, forHTTPHeaderField: "X-Shopify-Storefront-Access-Token")
        request.httpBody = try JSONSerialization.data(withJSONObject: body.dictionary, options: [])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw ShopifyError.invalidResponse
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private struct ShopifyConfiguration {
    static let shopDomain = "duneroastery.myshopify.com"
    static let storefrontToken = "0b8e38878678cd9b9db8325f88f95141"
    static let accountLoginURL = URL(string: "https://\(shopDomain)/account/login")!
    static let accountRegisterURL = URL(string: "https://\(shopDomain)/account/register")!
    static let brewingBlogHandle = "brewing-methods"
    static let brewingArticlesQuery = "blog_title:\"Brewing Methods\" OR tag:brewing OR tag:brew"
}

private struct ShopifyGraphQLRequest {
    let query: String
    let variables: [String: Any]

    var dictionary: [String: Any] {
        [
            "query": query,
            "variables": variables
        ]
    }
}

private struct ShopifyProductsResponse: Decodable {
    let data: DataPayload?
    let errors: [GraphQLError]?

    struct DataPayload: Decodable {
        let products: ProductConnection
    }

    struct ProductConnection: Decodable {
        let pageInfo: PageInfo
        let edges: [ProductEdge]
    }

    struct PageInfo: Decodable {
        let hasNextPage: Bool
        let endCursor: String?
    }

    struct ProductEdge: Decodable {
        let node: ShopifyProductNode
    }

    struct GraphQLError: Decodable {
        let message: String
    }
}

private struct ShopifyProductNode: Decodable {
    let id: String
    let title: String
    let description: String
    let tags: [String]
    let productType: String
    let featuredImage: FeaturedImage?
    let variants: VariantConnection
    let priceRange: PriceRange

    struct FeaturedImage: Decodable {
        let url: URL
    }

    struct PriceRange: Decodable {
        let minVariantPrice: Money
    }

    struct VariantConnection: Decodable {
        let edges: [VariantEdge]
    }

    struct VariantEdge: Decodable {
        let node: ProductVariant
    }

    struct ProductVariant: Decodable {
        let id: String
        let availableForSale: Bool
    }

    struct Money: Decodable {
        let amount: String
        let currencyCode: String
    }
}

private enum ShopifyError: LocalizedError {
    case invalidResponse
    case api(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The Shopify response was invalid."
        case .api(let message):
            return message
        }
    }
}

private struct ShopifyCheckoutLine {
    let merchandiseId: String
    let quantity: Int
}

private struct ShopifyCheckoutAddress {
    let email: String
    let fullName: String
    let phone: String
    let address1: String
    let city: String
}

private struct ShopifyCartCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let cartCreate: CartCreatePayload
    }

    struct CartCreatePayload: Decodable {
        let cart: Cart?
        let userErrors: [UserError]
    }

    struct Cart: Decodable {
        let checkoutUrl: URL
    }

    struct UserError: Decodable {
        let message: String
    }
}

private struct ShopifyCustomerSession: Decodable {
    let accessToken: String
    let expiresAt: String
}

private struct ShopifyCustomerAccessTokenCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customerAccessTokenCreate: CustomerAccessTokenCreatePayload
    }

    struct CustomerAccessTokenCreatePayload: Decodable {
        let customerAccessToken: ShopifyCustomerSession?
        let customerUserErrors: [ShopifyCustomerUserError]
    }

    struct ShopifyCustomerUserError: Decodable {
        let message: String
    }
}

private struct ShopifyCustomerQueryResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customer: Customer?
    }

    struct Customer: Decodable {
        let id: String
        let firstName: String?
        let lastName: String?
        let email: String
    }
}

private struct ShopifyCustomerCreateResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let customerCreate: CustomerCreatePayload
    }

    struct CustomerCreatePayload: Decodable {
        let customer: CreatedCustomer?
        let customerUserErrors: [ShopifyCustomerAccessTokenCreateResponse.ShopifyCustomerUserError]
    }

    struct CreatedCustomer: Decodable {
        let id: String
    }
}

private struct ShopifyBrewingArticlesResponse: Decodable {
    let data: DataPayload?
    let errors: [ShopifyProductsResponse.GraphQLError]?

    struct DataPayload: Decodable {
        let blog: Blog?
        let articles: ArticleConnection
    }

    struct Blog: Decodable {
        let articles: ArticleConnection
    }

    struct ArticleConnection: Decodable {
        let edges: [ArticleEdge]
    }

    struct ArticleEdge: Decodable {
        let node: ArticleNode
    }

    struct ArticleNode: Decodable {
        let id: String
        let handle: String
        let title: String
        let excerpt: String?
        let content: String
        let tags: [String]
        let onlineStoreUrl: URL?
        let blog: BlogSummary
    }

    struct BlogSummary: Decodable {
        let handle: String
        let title: String
    }
}

private struct AccountProfileResponse: Decodable {
    let id: String
    let firstName: String?
    let lastName: String?
    let email: String
}

private struct AccountSessionResponse: Decodable {
    let profile: AccountProfileResponse
    let accessToken: String
    let expiresAt: String
}

private struct ServiceErrorResponse: Decodable {
    let error: String
}

enum ProductCatalogRules {
    static func shouldInclude(title: String, productType: String, tags: [String]) -> Bool {
        let source = ([title, productType] + tags)
            .joined(separator: " ")
            .lowercased()

        return !source.contains("gift card") && !source.contains("giftcard")
    }

    static func categoryKey(productType: String, tags: [String], title: String) -> String {
        let source = ([title, productType] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("talla box")
            || source.contains("mini talla box")
            || source.contains("mini coffee box")
            || source.contains("mini arabic coffee box") {
            return "gifts"
        }

        if source.contains("shamali coffee") {
            return "arabic-coffee-beans"
        }

        let trimmedType = productType.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedType.isEmpty {
            let sluggedType = slug(from: trimmedType)
            if sluggedType == "northern-coffee" {
                return "arabic-coffee-beans"
            }
            if sluggedType == "tea" {
                return "ready-made-drinks"
            }
            if sluggedType == "desserts" || sluggedType == "spreads" || sluggedType == "bread" {
                return "crmb-tallas-speciality-bakery"
            }
            return sluggedType
        }

        if source.contains("tea") {
            return "ready-made-drinks"
        }

        if source.contains("dessert")
            || source.contains("bread")
            || source.contains("jam")
            || source.contains("spread")
            || source.contains("butter")
            || source.contains("cookie")
            || source.contains("cake") {
            return "crmb-tallas-speciality-bakery"
        }

        return "arabic-coffee-beans"
    }

    static func categoryLabel(productType: String, fallbackKey: String) -> String {
        let trimmedType = productType.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedType.isEmpty, slug(from: trimmedType) != "tea", fallbackKey != "gifts" {
            return trimmedType
        }

        if fallbackKey == "ready-made-drinks" {
            return "Ready-Made Drinks"
        }

        if fallbackKey == "crmb-tallas-speciality-bakery" {
            return "CRMB Talla's Speciality Bakery"
        }

        if fallbackKey == "gifts" {
            return "Talla Boxes"
        }

        if fallbackKey == "other" || fallbackKey == "arabic-coffee-beans" || fallbackKey == "arabic-coffee" {
            return "Arabic & Shamali Coffee"
        }

        return fallbackKey
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    static func productTag(from tags: [String]) -> String? {
        let preferred = ["BESTSELLER", "NEW", "LOCAL", "PREMIUM", "GIFT"]
        let uppercased = tags.map { $0.uppercased() }
        return preferred.first(where: uppercased.contains)
    }

    private static func slug(from value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
    }
}

private extension ContentView.Product {
    static func shouldInclude(shopifyNode: ShopifyProductNode) -> Bool {
        ProductCatalogRules.shouldInclude(
            title: shopifyNode.title,
            productType: shopifyNode.productType,
            tags: shopifyNode.tags
        )
    }

    init(shopifyNode: ShopifyProductNode) {
        let categoryKey = ProductCatalogRules.categoryKey(
            productType: shopifyNode.productType,
            tags: shopifyNode.tags,
            title: shopifyNode.title
        )
        let firstVariant = shopifyNode.variants.edges.first?.node

        self.init(
            id: shopifyNode.id,
            variantID: firstVariant?.id,
            name: shopifyNode.title,
            price: Self.formattedPrice(from: shopifyNode.priceRange.minVariantPrice),
            categoryKey: categoryKey,
            categoryLabel: ProductCatalogRules.categoryLabel(productType: shopifyNode.productType, fallbackKey: categoryKey),
            imageURL: shopifyNode.featuredImage?.url,
            desc: shopifyNode.description.isEmpty ? "Freshly synced from Shopify." : shopifyNode.description,
            tag: ProductCatalogRules.productTag(from: shopifyNode.tags),
            isAvailableForSale: firstVariant?.availableForSale ?? false
        )
    }

    private static func formattedPrice(from money: ShopifyProductNode.Money) -> String {
        guard let decimal = Decimal(string: money.amount) else {
            return "\(money.amount) \(money.currencyCode)"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = money.currencyCode == "BHD" ? 3 : 2

        return formatter.string(from: decimal as NSDecimalNumber) ?? "\(money.amount) \(money.currencyCode)"
    }
}

private extension ContentView.BrewingMethod {
    init(article: ShopifyBrewingArticlesResponse.ArticleNode) {
        let summarySource = [article.excerpt, article.content]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "Brew guide from Shopify."

        self.init(
            id: article.id,
            name: article.title,
            summary: summarySource,
            detail: article.blog.title,
            symbol: Self.symbol(title: article.title, tags: article.tags),
            articleURL: article.onlineStoreUrl ?? Self.articleURL(blogHandle: article.blog.handle, articleHandle: article.handle),
            categories: Self.categories(title: article.title, tags: article.tags),
            difficulty: Self.difficulty(title: article.title, tags: article.tags),
            brewTime: Self.brewTime(title: article.title, tags: article.tags)
        )
    }

    private static func symbol(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("press") {
            return "cup.and.saucer.fill"
        }

        if source.contains("chemex") || source.contains("filter") {
            return "flask.fill"
        }

        if source.contains("espresso") {
            return "bolt.fill"
        }

        if source.contains("cold") {
            return "snowflake"
        }

        return "drop.fill"
    }

    private static func categories(title: String, tags: [String]) -> [String] {
        let cleanedTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if !cleanedTags.isEmpty {
            return Array(Set(cleanedTags)).sorted()
        }
 
        let source = title.lowercased()
        if source.contains("press") {
            return ["Immersion"]
        }

        if source.contains("chemex") || source.contains("pour") {
            return ["Pour Over"]
        }

        if source.contains("espresso") {
            return ["Espresso"]
        }

        if source.contains("cold") {
            return ["Cold Brew"]
        }

        return ["Guide"]
    }

    private static func difficulty(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("espresso") || source.contains("v60") {
            return "Advanced"
        }

        if source.contains("chemex") || source.contains("pour") || source.contains("aeropress") {
            return "Intermediate"
        }

        return "Easy"
    }

    private static func brewTime(title: String, tags: [String]) -> String {
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("cold") {
            return "8-12 hr"
        }

        if source.contains("espresso") {
            return "30 sec"
        }

        if source.contains("press") {
            return "4 min"
        }

        if source.contains("chemex") {
            return "4-5 min"
        }

        if source.contains("pour") || source.contains("v60") || source.contains("filter") {
            return "3-4 min"
        }

        return "3-5 min"
    }

    private static func articleURL(blogHandle: String, articleHandle: String) -> URL? {
        URL(string: "https://\(ShopifyConfiguration.shopDomain)/blogs/\(blogHandle)/\(articleHandle)")
    }
}

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

#Preview {
    ContentView()
}
