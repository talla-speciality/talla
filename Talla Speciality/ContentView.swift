import Foundation
import SwiftUI
import StoreKit
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

private enum TallaWidgetSharedState {
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

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static func reloadWidget() {
#if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
#endif
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    private enum Tab: String, CaseIterable {
        case home
        case shop
        case brewing
        case account

        var systemImage: String {
            switch self {
            case .home:
                return "house"
            case .shop:
                return "square.grid.2x2"
            case .brewing:
                return "drop"
            case .account:
                return "person"
            }
        }
    }

    private enum SettingsDetail: String, Identifiable {
        case language
        case notifications
        case aboutTalla
        case deleteAccount

        var id: String { rawValue }
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
        struct Variant: Identifiable, Hashable {
            let id: String
            let title: String
            let price: String
            let isAvailableForSale: Bool
        }

        let id: String
        let variantID: String?
        let variants: [Variant]
        let name: String
        let price: String
        let categoryKey: String
        let categoryLabel: String
        let imageURL: URL?
        let desc: String
        let tag: String?
        let isAvailableForSale: Bool

        var defaultVariant: Variant? {
            variants.first(where: \.isAvailableForSale) ?? variants.first
        }

        var hasVariantChoices: Bool {
            variants.count > 1
        }
    }

    struct HomeSettings: Decodable {
        let signatureRoastProductIDs: [String]
        let funPickProductID: String?
        let heroEyebrow: String?
        let heroTitle: String?
        let heroSubtitle: String?
        let heroBadge: String?
        let primaryButtonTitle: String?
        let secondaryButtonTitle: String?

        private enum CodingKeys: String, CodingKey {
            case signatureRoastProductIDs
            case funPickProductID
            case heroEyebrow
            case heroTitle
            case heroSubtitle
            case heroBadge
            case primaryButtonTitle
            case secondaryButtonTitle
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            signatureRoastProductIDs = try container.decodeIfPresent([String].self, forKey: .signatureRoastProductIDs) ?? []
            funPickProductID = try container.decodeIfPresent(String.self, forKey: .funPickProductID)
            heroEyebrow = try container.decodeIfPresent(String.self, forKey: .heroEyebrow)
            heroTitle = try container.decodeIfPresent(String.self, forKey: .heroTitle)
            heroSubtitle = try container.decodeIfPresent(String.self, forKey: .heroSubtitle)
            heroBadge = try container.decodeIfPresent(String.self, forKey: .heroBadge)
            primaryButtonTitle = try container.decodeIfPresent(String.self, forKey: .primaryButtonTitle)
            secondaryButtonTitle = try container.decodeIfPresent(String.self, forKey: .secondaryButtonTitle)
        }
    }

    struct PassportSettings: Decodable {
        struct Origin: Decodable {
            let id: String
            let title: String
            let emoji: String
            let keywords: [String]
            let rewardLabel: String?
        }

        let origins: [Origin]
        let completionRewardTitle: String?
        let completionRewardDetail: String?
    }

    struct BrewingMethod: Identifiable, Hashable {
        struct PublishedRecipe: Hashable {
            let coffeeGrams: Double?
            let ratio: Double?
            let waterGrams: Double?
            let iceGrams: Double?
        }

        let id: String
        let name: String
        let summary: String
        let detail: String
        let symbol: String
        let articleURL: URL?
        let categories: [String]
        let difficulty: String
        let brewTime: String
        let publishedRecipe: PublishedRecipe?
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
        let variant: Product.Variant
        var quantity: Int
    }

    private struct CheckoutSession: Identifiable {
        enum Kind: Equatable {
            case standard
            case shopifyEazy
            case eazyHosted
        }

        let id = UUID()
        let url: URL
        let kind: Kind

        init(url: URL, kind: Kind = .standard) {
            self.url = url
            self.kind = kind
        }
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
        let beansAwarded: Bool?
        let pointsAwarded: Int?
    }

    struct TasteMemoryRecord: Codable, Hashable {
        let id: String
        let orderID: String?
        let productName: String
        let reaction: String
        let tags: [String]
        let createdAt: String
        let updatedAt: String?
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
        let countryCode: String?
        let notes: String?
        let isPreferred: Bool

        var country: SupportedDeliveryCountry {
            SupportedDeliveryCountry(code: countryCode) ?? .bahrain
        }
    }

    enum SupportedDeliveryCountry: String, CaseIterable, Identifiable, Codable {
        case oman = "OM"
        case bahrain = "BH"
        case qatar = "QA"
        case kuwait = "KW"
        case uae = "AE"
        case saudiArabia = "SA"

        var id: String { rawValue }

        init?(code: String?) {
            guard let code else { return nil }
            self.init(rawValue: code.uppercased())
        }

        var name: String {
            switch self {
            case .oman: return AppLocalization.text("country_oman", fallback: "Oman")
            case .bahrain: return AppLocalization.text("country_bahrain", fallback: "Bahrain")
            case .qatar: return AppLocalization.text("country_qatar", fallback: "Qatar")
            case .kuwait: return AppLocalization.text("country_kuwait", fallback: "Kuwait")
            case .uae: return AppLocalization.text("country_uae", fallback: "UAE")
            case .saudiArabia: return AppLocalization.text("country_saudi_arabia", fallback: "Saudi Arabia")
            }
        }

        var flag: String {
            switch self {
            case .oman: return "OM"
            case .bahrain: return "BH"
            case .qatar: return "QA"
            case .kuwait: return "KW"
            case .uae: return "AE"
            case .saudiArabia: return "SA"
            }
        }

        var phonePrefix: String {
            switch self {
            case .oman: return "+968"
            case .bahrain: return "+973"
            case .qatar: return "+974"
            case .kuwait: return "+965"
            case .uae: return "+971"
            case .saudiArabia: return "+966"
            }
        }
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

    private struct BrewJournalEntry: Codable, Identifiable {
        let id: UUID
        let title: String
        let method: String
        let coffeeGrams: Double?
        let ratio: Double?
        let waterGrams: Double?
        let brewTimeSeconds: Int?
        let rating: Int
        let notes: String
        let createdAt: String
    }

    private struct ReorderPrompt {
        let order: AccountOrder
        let product: Product
        let daysAgo: Int
    }

    private struct CoffeePassportOrigin: Identifiable, Hashable {
        let id: String
        let title: String
        let detail: String
        let symbol: String
    }

    enum AccountAuthMode: String {
        case signIn
        case createAccount
        case changePassword
    }

    enum ShopSortMode: String, CaseIterable, Identifiable {
        case featured
        case priceLow
        case priceHigh
        case newest
        case available

        var id: String { rawValue }

        var title: String {
            switch self {
            case .featured:
                return AppLocalization.text("sort_featured", fallback: "Featured")
            case .priceLow:
                return AppLocalization.text("sort_price_low", fallback: "Price: Low to High")
            case .priceHigh:
                return AppLocalization.text("sort_price_high", fallback: "Price: High to Low")
            case .newest:
                return AppLocalization.text("sort_newest", fallback: "Newest")
            case .available:
                return AppLocalization.text("sort_available", fallback: "Availability")
            }
        }
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
                return "You don't have enough Beans for that reward yet."
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
    @State private var shopSearchQuery = ""
    @State private var surprisePickProductID = ""
    @State private var isSurprisePickExpanded = false
    @State private var isSurprisePickRevealed = false
    @State private var surpriseRevealID = 0
    @State private var shopSortMode: ShopSortMode = .featured
    @State private var conciergeRequest = ""
    @State private var conciergeResult: CoffeeConciergeResult?
    @State private var isRunningConcierge = false
#if canImport(PhotosUI)
    @State private var conciergeImageSelection: PhotosPickerItem?
#endif
    @State private var conciergeImageData: Data?
    @State private var isLoadingConciergeImage = false
    @State private var isCoffeeConciergePresented = false
    @State private var isCoffeeQuizExpanded = false
    @State private var quizBrewMethod = "v60"
    @State private var quizFlavor = "fruity"
    @State private var quizAdventure = "curious"
    @State private var products: [Product] = []
    @State private var cartItems: [CartItem] = []
    @State private var cartOpen = false
    @State private var toastMessage: String?
    @State private var cartCelebrationID = 0
    @State private var showingCartCelebration = false
    @State private var delightFeedbackTrigger = 0
    @State private var isLoadingProducts = false
    @State private var hasLoadedProducts = false
    @State private var lastProductsRefreshAt: Date?
    @State private var loadingError: String?
    @State private var brewingMethods: [BrewingMethod] = []
    @State private var isLoadingBrewingMethods = false
    @State private var hasLoadedBrewingMethods = false
    @State private var brewingMethodsError: String?
    @State private var activeBrewingCategory = "All"
    @State private var ratioCoffeeInput = "20"
    @State private var ratioValueInput = "16"
    @State private var brewRecipeName = ""
    @State private var selectedBrewTimerName = "Pour Over"
    @State private var selectedBrewTimerSeconds = 210
    @State private var brewTimerRemainingSeconds = 210
    @State private var isBrewTimerRunning = false
    @State private var brewTimerRunID = UUID()
    @State private var journalTitleInput = ""
    @State private var journalMethodInput = "Pour Over"
    @State private var journalNotesInput = ""
    @State private var journalCoffeeGrams: Double?
    @State private var journalRatio: Double?
    @State private var journalWaterGrams: Double?
    @State private var journalBrewTimeSeconds: Int?
    @State private var journalRating = 4
    @State private var cartSaveName = ""
    @State private var isCheckingOut = false
    @State private var checkoutError: String?
    @StateObject private var paymentFlow = PaymentFlowModel()
    @State private var isPaymentMethodSheetPresented = false
    @State private var pendingCartRemovalID: String?
    @State private var isConfirmingEmptyBag = false
    @State private var checkoutSession: CheckoutSession?
    @State private var eazyShopifyBrowserKind: CheckoutSession.Kind?
    @State private var benefitPaySession: BenefitPaySession?
    @State private var mastercardPaymentContext: MastercardPaymentContext?
    @State private var articleSession: CheckoutSession?
    @State private var selectedProduct: Product?
    @State private var isFavoriteShelfPresented = false
    @State private var voucherCodeInput = ""
    @State private var appliedVoucher: VoucherRecord?
    @State private var isApplyingVoucher = false
    @State private var voucherError: String?
    @State private var availableVouchers: [VoucherRecord] = []
    @State private var isLoadingAvailableVouchers = false
    @AppStorage("app.appearanceMode") private var savedAppearanceMode = AppearanceMode.system.rawValue
    @AppStorage("app.hasSeenWelcome") private var hasSeenWelcome = false
    @AppStorage("app.hasSeenFeatureTour") private var hasSeenFeatureTour = false
    @AppStorage("app.hasAskedInitialNotificationPermission") private var hasAskedInitialNotificationPermission = false
    @AppStorage("app.reviewLaunchCount") private var reviewLaunchCount = 0
    @AppStorage("app.reviewLastPromptAt") private var reviewLastPromptAt = 0.0
    @AppStorage("payment.activeEazyShopifyID") private var activeEazyShopifyPaymentID = ""
    @AppStorage("app.reviewPromptedVersion") private var reviewPromptedVersion = ""
    @AppStorage("local.customerEmail") private var savedCustomerEmail = ""
    @AppStorage("local.customerAccessToken") private var savedCustomerAccessToken = ""
    @AppStorage("local.pushDeviceToken") private var savedPushDeviceToken = ""
    @AppStorage("local.pushDeviceToken.email") private var savedRegisteredPushDeviceEmail = ""
    @AppStorage("local.pushDeviceToken.value") private var savedRegisteredPushDeviceToken = ""
    @AppStorage("loyalty.email") private var savedLoyaltyEmail = ""
    @AppStorage("favorites.productIDs") private var savedFavoriteProductIDs = ""
    @AppStorage("recentlyViewed.productIDs") private var savedRecentlyViewedProductIDs = ""
    @AppStorage("recentSearches.queries") private var savedRecentSearchQueries = ""
    @AppStorage("alerts.productIDs") private var savedAlertProductIDs = ""
    @AppStorage("brewRecipes.saved") private var savedBrewRecipes = ""
    @AppStorage("brewJournal.saved") private var savedBrewJournal = ""
    @AppStorage("tasteMemory.saved") private var savedTasteMemory = ""
    @AppStorage("carts.saved") private var savedCartsPayload = ""
    @AppStorage("app.language") private var savedAppLanguage = AppLanguage.system.rawValue
    @AppStorage("shortcut.destination") private var shortcutDestination = ""
    @AppStorage("shortcut.searchQuery") private var shortcutSearchQuery = ""
    @State private var notificationAuthorizationStatus: Int = 0
    @State private var showLaunchSplash = true
    @State private var featureTourIndex = 0
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
    @State private var isSigningInWithApple = false
    @State private var appleSignInNonce = ""
    @State private var customerProfile: ShopifyCustomerProfile?
    @State private var customerAuthError: String?
    @State private var isSigningIn = false
    @State private var isCreatingAccount = false
    @State private var isLoadingCustomer = false
    @State private var orderHistory: [AccountOrder] = []
    @State private var isLoadingOrders = false
    @State private var ordersError: String?
    @State private var backendStockAlerts: [StockAlertRecord] = []
    @State private var isLoadingBackendAlerts = false
    @State private var alertInbox: [AlertInboxRecord] = []
    @State private var addresses: [DeliveryAddress] = []
    @State private var addressLabel = ""
    @State private var addressFullName = ""
    @State private var addressPhone = ""
    @State private var addressLine1 = ""
    @State private var addressCity = ""
    @State private var addressCountry: SupportedDeliveryCountry = .bahrain
    @State private var addressNotes = ""
    @State private var isSavingAddress = false
    @State private var selectedVariantIDs: [String: String] = [:]
    @State private var remoteSignatureRoastProductIDs: [String] = []
    @State private var remoteHomeSettings: HomeSettings?
    @State private var remotePassportSettings: PassportSettings?
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
    @State private var isCustomerSectionExpanded = true
    @State private var isLoyaltySectionExpanded = true
    @State private var isLibrarySectionExpanded = true
    @State private var isShoppingSectionExpanded = false
    @State private var isBrewingSectionExpanded = false
    @State private var isSupportSectionExpanded = false
    @State private var isCheckoutNoteExpanded = false
    @State private var isVoucherCodeEntryExpanded = false
    @State private var isCartSaveEntryExpanded = false
    @State private var isDeliveryDetailsExpanded = false
    @State private var isTallaPassportExpanded = false
    @State private var selectedSettingsDetail: SettingsDetail?
    @State private var accountScrollTarget: String?
    @State private var tabScrollTarget: Tab?
    @State private var shopCatalogueScrollRequest = 0
    @State private var didRecordReviewLaunch = false

    private let categoryCatalog: [ShopCategory] = [
        ShopCategory(key: "all", title: "All", subtitle: "Full catalog", symbol: "square.grid.2x2.fill"),
        ShopCategory(key: "summer-drinks", title: "Summer", subtitle: "Cold seasonal drinks", symbol: "sun.max.fill"),
        ShopCategory(key: "coffee-beans", title: "Coffee Beans", subtitle: "Whole bean roasts", symbol: "leaf.fill"),
        ShopCategory(key: "arabic-coffee-beans", title: "Arabic Coffee", subtitle: "Traditional roasts", symbol: "leaf.circle.fill"),
        ShopCategory(key: "drip-bags", title: "Drip Bags", subtitle: "Single-serve brews", symbol: "drop.fill"),
        ShopCategory(key: "cups", title: "Cups", subtitle: "Mugs, tumblers, and drinkware", symbol: "cup.and.saucer.fill"),
        ShopCategory(key: "ready-made-drinks", title: "Drinks", subtitle: "Ready cups and bottled drinks", symbol: "takeoutbag.and.cup.and.straw.fill"),
        ShopCategory(key: "desserts", title: "CRMB", subtitle: "Sweet CRMB picks", symbol: "birthday.cake.fill"),
        ShopCategory(key: "spreads", title: "Spreads", subtitle: "Jams, butters, and jars", symbol: "takeoutbag.and.cup.and.straw.fill"),
        ShopCategory(key: "hot-chocolate", title: "Hot Chocolate", subtitle: "Cocoa and mixes", symbol: "mug.fill"),
        ShopCategory(key: "coffee-equipment", title: "Equipment", subtitle: "Brewers and tools", symbol: "flask.fill"),
        ShopCategory(key: "gifts", title: "Talla Boxes", subtitle: "Curated bundles", symbol: "gift.fill"),
    ]

    private let signatureRoastProductNames = [
        "Brazil",
        "Colombia",
        "Ethiopia",
        "Yemen"
    ]

    private let defaultCoffeePassportOrigins = [
        CoffeePassportOrigin(id: "ethiopia", title: "Ethiopia", detail: "Floral, bright, berry-like cups", symbol: "🇪🇹"),
        CoffeePassportOrigin(id: "yemen", title: "Yemen", detail: "Deep spice, cocoa, dried fruit", symbol: "🇾🇪"),
        CoffeePassportOrigin(id: "colombia", title: "Colombia", detail: "Balanced caramel and chocolate", symbol: "🇨🇴"),
        CoffeePassportOrigin(id: "brazil", title: "Brazil", detail: "Smooth nuts, cocoa, comfort", symbol: "🇧🇷")
    ]

    private var coffeePassportOrigins: [CoffeePassportOrigin] {
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

    private var cartCount: Int {
        cartItems.reduce(0) { $0 + $1.quantity }
    }

    private var isApplePayAvailable: Bool {
#if canImport(PassKit)
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex])
#else
        false
#endif
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

    private var surprisePickProducts: [Product] {
        products.filter { product in
            product.isAvailableForSale && selectedVariant(for: product)?.isAvailableForSale == true
        }
    }

    private var surprisePickProduct: Product? {
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

    private var isLightAppearance: Bool {
        appearanceMode == .light || (appearanceMode == .system && colorScheme == .light)
    }

    private var backgroundGradientColors: [Color] {
        if isLightAppearance {
            return [
                Color(hex: 0xFAF7F1),
                Color(hex: 0xF4EBDD),
                Color(hex: 0xECE0D0)
            ]
        }

        return [
            Color(hex: 0x080706),
            Color(hex: 0x12100D),
            Color(hex: 0x1A1511)
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
        isLightAppearance ? Color(hex: 0xFFFBF6).opacity(0.96) : Color(hex: 0x1A1511).opacity(0.9)
    }

    private var elevatedSurfaceColor: Color {
        isLightAppearance ? Color(hex: 0xFFFCF8) : Color(hex: 0x15110E)
    }

    private var headerOverlayColor: Color {
        isLightAppearance ? Color(hex: 0xFFFCF8).opacity(0.92) : Color(hex: 0x0F0C09).opacity(0.88)
    }

    private var footerOverlayColor: Color {
        isLightAppearance ? Color(hex: 0xFFFCF8).opacity(0.92) : Color(hex: 0x0F0C09).opacity(0.86)
    }

    private var scrimColor: Color {
        isLightAppearance ? Color.black.opacity(0.22) : Color.black.opacity(0.6)
    }

    private var isCompact: Bool {
        horizontalSizeClass != .regular
    }

    private var shouldShowHeaderCartButton: Bool {
        activeTab == .home || activeTab == .shop
    }

    private var contentMaxWidth: CGFloat {
        isCompact ? 400 : 980
    }

    private var homeQuickActionColumns: [GridItem] {
        let count = isCompact ? 2 : 4
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
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
        let count = isCompact ? 2 : 3
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
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

        return ordered.map(localizedCategory) + extras
    }

    private func localizedCategory(_ category: ShopCategory) -> ShopCategory {
        ShopCategory(
            key: category.key,
            title: categoryLabel(for: category.key),
            subtitle: categorySubtitle(for: category.key, fallback: category.subtitle),
            symbol: category.symbol
        )
    }

    private func categorySubtitle(for key: String, fallback: String) -> String {
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

    private var filteredProducts: [Product] {
        let categoryFilteredProducts = activeCategory == "all"
            ? products
            : products.filter { $0.categoryKey == activeCategory }
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

    private var favoriteProductIDs: Set<String> {
        Set(
            savedFavoriteProductIDs
                .split(separator: ",")
                .map { String($0) }
                .filter { !$0.isEmpty }
        )
    }

    private var conciergeProducts: [Product] {
        guard let conciergeResult else { return [] }
        let productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        return conciergeResult.productIDs.compactMap { productsByID[$0] }
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

    private var recentlyViewedUnboughtProducts: [Product] {
        let orderedProductIDs = Set(orderedProducts.map(\.id))
        return recentlyViewedProducts.filter { !orderedProductIDs.contains($0.id) }
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

    private var brewJournalEntries: [BrewJournalEntry] {
        guard let data = savedBrewJournal.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([BrewJournalEntry].self, from: data) else {
            return []
        }

        return decoded
    }

    private var stampedCoffeePassportOriginKeys: Set<String> {
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

    private var passportProgressFraction: Double {
        guard !coffeePassportOrigins.isEmpty else { return 0 }
        return min(Double(stampedCoffeePassportOriginKeys.count) / Double(coffeePassportOrigins.count), 1)
    }

    private var isCoffeePassportComplete: Bool {
        stampedCoffeePassportOriginKeys.count == coffeePassportOrigins.count
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

    private var notificationStatusMessage: String {
#if canImport(UserNotifications)
        switch UNAuthorizationStatus(rawValue: notificationAuthorizationStatus) {
        case .authorized, .provisional:
            return AppLocalization.text("alerts_notifications_enabled_detail", fallback: "Push alerts are enabled for watched products and account updates.")
        case .denied:
            return AppLocalization.text("alerts_notifications_denied_detail", fallback: "Notifications are off. Turn them on in Settings to receive product alerts.")
        default:
            return AppLocalization.text("alerts_notifications_disabled_detail", fallback: "Enable notifications to receive reminders for watched products and important account updates.")
        }
#else
        return AppLocalization.text("alerts_notifications_unavailable_detail", fallback: "Notifications are unavailable on this device.")
#endif
    }

    private var canRequestNotificationAccess: Bool {
#if canImport(UserNotifications)
        UNAuthorizationStatus(rawValue: notificationAuthorizationStatus) != .denied && !notificationsEnabled
#else
        false
#endif
    }

    private var pushRegistrationStatusMessage: String {
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
        let threshold = 50
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
        if points < 125 {
            let target = 125
            return (
                label: "Silver",
                current: points,
                target: target,
                remaining: target - points,
                fraction: min(max(Double(points) / Double(target), 0), 1)
            )
        }

        if points < 250 {
            let current = points - 125
            let span = 125
            return (
                label: "Gold",
                current: current,
                target: span,
                remaining: 250 - points,
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

    private var tasteMemoryRecords: [TasteMemoryRecord] {
        guard let data = savedTasteMemory.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([TasteMemoryRecord].self, from: data) else {
            return []
        }

        return decoded
    }

    private var tasteMemoryLookup: [String: TasteMemoryRecord] {
        Dictionary(uniqueKeysWithValues: tasteMemoryRecords.map { ($0.id, $0) })
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
                let lhsScore = categoryWeights[lhs.categoryKey, default: 0] + tastePreferenceScore(for: lhs)
                let rhsScore = categoryWeights[rhs.categoryKey, default: 0] + tastePreferenceScore(for: rhs)

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

    private var reorderPrompts: [ReorderPrompt] {
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

    private var reorderPrompt: ReorderPrompt? {
        reorderPrompts.first
    }

    private var orderBasedRecommendation: (source: Product, recommended: Product)? {
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

    private var displayedBrewingMethods: [BrewingMethod] {
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

    private var brewingCategories: [String] {
        let source = brewingMethods.isEmpty ? displayedBrewingMethods : brewingMethods
        let categories = Set(source.flatMap(\.categories))
        let preferredOrder = ["Pour Over", "Immersion", "Traditional", "Cold Brew"]
        return ["All"] + preferredOrder.filter { categories.contains($0) }
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

    private var brewAgainHistoryItems: [(title: String, detail: String, coffeeGrams: Double?, ratio: Double?)] {
        let journalItems = brewJournalEntries.compactMap { entry -> (title: String, detail: String, coffeeGrams: Double?, ratio: Double?)? in
            guard let coffeeGrams = entry.coffeeGrams,
                  let ratio = entry.ratio else {
                return nil
            }

            return (
                entry.title,
                "\(entry.method) - \(formattedRatioValue(coffeeGrams)) g - 1:\(formattedRatioValue(ratio)) - Rated \(entry.rating)/5",
                coffeeGrams,
                ratio
            )
        }

        let recipeItems = brewRecipes.map { recipe in
            (
                recipe.name,
                "\(recipe.category) - \(formattedRatioValue(recipe.coffeeGrams)) g - 1:\(formattedRatioValue(recipe.ratio))",
                recipe.coffeeGrams,
                recipe.ratio
            )
        }

        return Array((journalItems + recipeItems).prefix(3))
    }

    private var loyaltyPerks: [String] {
        loyaltyAccount?.perks ?? [
            "Collect Beans across coffees, beans, and accessories",
            "Unlock seasonal offers and complimentary extras"
        ]
    }

    private var checkoutReadinessTitle: String {
        preferredAddress == nil
            ? AppLocalization.text("almost_ready", fallback: "Almost ready")
            : AppLocalization.text("ready_to_checkout_checked", fallback: "Ready to checkout ✓")
    }

    private var checkoutReadinessSummary: String {
        let itemKey = cartCount == 1 ? "cart_item_count_singular" : "cart_item_count_plural"
        let itemFallback = cartCount == 1 ? "%d item" : "%d items"
        let itemText = String(format: AppLocalization.text(itemKey, fallback: itemFallback), cartCount)
        let addressText = preferredAddress == nil
            ? AppLocalization.text("delivery_address_needed_short", fallback: "Delivery address needed")
            : AppLocalization.text("address_saved", fallback: "Address saved")

        return "\(itemText) · \(addressText)"
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var shouldShowFeatureTour: Bool {
        hasSeenWelcome && !hasSeenFeatureTour && !showLaunchSplash
    }

    private var featureTourHighlights: [FeatureTourHighlight] {
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

    private func advanceFeatureTour() {
        if featureTourIndex >= featureTourHighlights.count - 1 {
            dismissFeatureTour()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                featureTourIndex += 1
            }
        }
    }

    private func dismissFeatureTour() {
        withAnimation(.easeInOut(duration: 0.22)) {
            hasSeenFeatureTour = true
            featureTourIndex = 0
        }
    }

    private var launchSplashView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: 0x100B07),
                    Color(hex: 0x1A120C),
                    Color(hex: 0x0A0804)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color(hex: 0xC8965A).opacity(0.12))
                .blur(radius: 90)
                .frame(width: 240, height: 240)
                .offset(x: 90, y: -160)

            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: isCompact ? 132 : 168, height: isCompact ? 132 : 168)
                .accessibilityLabel(AppLocalization.text("talla_logo", fallback: "Talla Speciality"))
        }
    }

    @MainActor
    private func runInitialLaunchSequence() async {
        let startTime = Date()

        await loadProductsIfNeeded()
        await refreshNotificationStatus()
        await syncRemotePushTokenIfPossible()

        let minimumSplashDuration: TimeInterval = 1.25
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < minimumSplashDuration {
            try? await Task.sleep(nanoseconds: UInt64((minimumSplashDuration - elapsed) * 1_000_000_000))
        }

        withAnimation(.easeInOut(duration: 0.28)) {
            showLaunchSplash = false
        }

        await requestInitialNotificationAccessIfNeeded()
        recordLaunchAndRequestReviewIfReady()
        handleShortcutDestination()
    }

    private func recordLaunchAndRequestReviewIfReady() {
        guard !didRecordReviewLaunch else { return }
        didRecordReviewLaunch = true
        reviewLaunchCount += 1

        guard hasSeenWelcome else { return }
        guard reviewLaunchCount >= 4 else { return }
        guard reviewPromptedVersion != currentAppVersion else { return }

        let now = Date().timeIntervalSince1970
        let minimumPromptInterval: TimeInterval = 60 * 60 * 24 * 60
        guard reviewLastPromptAt == 0 || now - reviewLastPromptAt > minimumPromptInterval else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard hasSeenWelcome,
                  !cartOpen,
                  checkoutSession == nil,
                  articleSession == nil,
                  selectedProduct == nil,
                  toastMessage == nil else {
                return
            }

            requestReview()
            reviewLastPromptAt = Date().timeIntervalSince1970
            reviewPromptedVersion = currentAppVersion
        }
    }

    private var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: savedAppearanceMode) ?? .system }
        set { savedAppearanceMode = newValue.rawValue }
    }

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: savedAppLanguage) ?? .system
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
                .ignoresSafeArea()

            appTabView

            if cartOpen {
                cartDrawer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if !hasSeenWelcome {
                WelcomeOverlayView(
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    cardFillColor: elevatedSurfaceColor,
                    accentColor: Color(hex: 0xC8965A),
                    scrimColor: scrimColor,
                    titleFont: displayFont(size: isCompact ? 34 : 42),
                    bodyFont: bodyFont(size: 14),
                    labelFont: labelFont(size: 10, weight: .bold),
                    startAction: {
                        startFirstRunAccountSetup()
                    },
                    choiceAction: { choice in
                        handleWelcomeChoice(choice)
                    },
                    skipAction: {
                        hasSeenWelcome = true
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(40)
            }

            if shouldShowFeatureTour {
                FeatureTourOverlayView(
                    highlights: featureTourHighlights,
                    currentIndex: featureTourIndex,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    cardFillColor: elevatedSurfaceColor,
                    accentColor: Color(hex: 0xC8965A),
                    scrimColor: scrimColor,
                    titleFont: displayFont(size: isCompact ? 30 : 36),
                    bodyFont: bodyFont(size: 14),
                    labelFont: labelFont(size: 10, weight: .bold),
                    nextAction: advanceFeatureTour,
                    skipAction: dismissFeatureTour
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                .zIndex(45)
            }

            if showLaunchSplash {
                launchSplashView
                    .transition(.opacity)
                    .zIndex(80)
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
        .animation(.easeInOut(duration: 0.28), value: showLaunchSplash)
        .sensoryFeedback(.success, trigger: delightFeedbackTrigger)
        .task {
            syncWidgetSharedState(reload: false)
            await runInitialLaunchSequence()
            syncWidgetSharedState(reload: true)
        }
        .onChange(of: activeTab) { _, newTab in
            guard newTab == .shop, hasLoadedProducts else { return }
            Task {
                await refreshProductsIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active, hasLoadedProducts else { return }
            Task {
                if activeTab == .shop {
                    await refreshProductsIfNeeded()
                }
                await refreshWalletPassPresence()
                await refreshNotificationStatus()
                await syncRemotePushTokenIfPossible()
                if customerProfile != nil {
                    await loadOrderHistory()
                    if !activeEazyShopifyPaymentID.isEmpty, checkoutSession == nil {
                        await refreshActiveEazyShopifyPayment(openHostedCheckout: false)
                    }
                    if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        await loadLoyaltyAccount()
                    }
                }
                recordLaunchAndRequestReviewIfReady()
            }
        }
        .onChange(of: savedPushDeviceToken) { _, _ in
            Task {
                await syncRemotePushTokenIfPossible()
            }
        }
        .onChange(of: savedCustomerAccessToken) { _, _ in
            Task {
                await syncRemotePushTokenIfPossible()
            }
        }
        .onChange(of: savedLoyaltyEmail) { _, _ in
            syncWidgetSharedState(reload: true)
        }
        .onChange(of: savedFavoriteProductIDs) { _, _ in
            syncWidgetSharedState(reload: true)
        }
        .onChange(of: savedRecentlyViewedProductIDs) { _, _ in
            syncWidgetSharedState(reload: true)
        }
        .onChange(of: savedCartsPayload) { _, _ in
            syncWidgetSharedState(reload: true)
        }
        .onChange(of: savedAppLanguage) { _, _ in
            syncWidgetSharedState(reload: true)
        }
        .onChange(of: shortcutDestination) { _, _ in
            handleShortcutDestination()
        }
#if canImport(PhotosUI)
        .onChange(of: conciergeImageSelection) { _, newSelection in
            Task {
                await loadConciergeImage(from: newSelection)
            }
        }
#endif
        .sheet(item: $checkoutSession, onDismiss: resetPaymentFlowAfterCheckoutDismiss) { session in
            CheckoutWebView(url: session.url)
        }
        .sheet(item: $benefitPaySession, onDismiss: resetPaymentFlowAfterBenefitPayDismiss) { session in
            BenefitPayCheckoutSheet(session: session) {
                benefitPaySession = nil
                paymentFlow.cancel()
            }
        }
#if canImport(Gateway) && canImport(uSDK) && canImport(UIKit)
        .sheet(item: $mastercardPaymentContext, onDismiss: resetPaymentFlowAfterMastercardDismiss) { context in
            MastercardPaymentSheet(context: context, flow: paymentFlow)
        }
#endif
        .sheet(item: $articleSession) { session in
            CheckoutWebView(url: session.url)
        }
        .sheet(item: $selectedProduct) { product in
            productDetailSheet(product: product)
        }
        .sheet(isPresented: $isFavoriteShelfPresented) {
            favoriteShelfSheet
        }
        .sheet(isPresented: $isPaymentMethodSheetPresented) {
            PaymentMethodSelectionSheet(
                selectedMethod: paymentFlow.selectedMethod,
                applePayAvailable: isApplePayAvailable,
                gatewaySDKAvailable: MastercardSDKAvailability.isAvailable,
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor,
                accentColor: Color(hex: 0xC8965A),
                surfaceColor: elevatedSurfaceColor
            ) { method in
                paymentFlow.select(method)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isCoffeeConciergePresented) {
            coffeeConciergeSheet
        }
        .alert(AppLocalization.text("empty_bag_confirmation_title", fallback: "Empty bag?"), isPresented: $isConfirmingEmptyBag) {
            Button(AppLocalization.text("cancel", fallback: "Cancel"), role: .cancel) {
                pendingCartRemovalID = nil
            }

            Button(AppLocalization.text("remove", fallback: "Remove"), role: .destructive) {
                if let pendingCartRemovalID {
                    removeFromCart(id: pendingCartRemovalID)
                }
                pendingCartRemovalID = nil
            }
        } message: {
            Text(AppLocalization.text("empty_bag_confirmation_message", fallback: "Remove the last item from your bag?"))
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
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
        .environment(\.layoutDirection, appLanguage.layoutDirection)
        .preferredColorScheme(appearanceMode.colorScheme)
    }

    private func resetPaymentFlowAfterCheckoutDismiss() {
        if let eazyShopifyBrowserKind {
            self.eazyShopifyBrowserKind = nil
            paymentFlow.transition(to: .processing)
            Task {
                await waitForEazyShopifyProgress(openHostedCheckout: eazyShopifyBrowserKind == .shopifyEazy)
            }
            return
        }
        if paymentFlow.state == .awaitingCustomer {
            paymentFlow.reset()
        }
    }

    @MainActor
    private func waitForEazyShopifyProgress(openHostedCheckout: Bool) async {
        for attempt in 0 ..< 20 {
            let completed = await refreshActiveEazyShopifyPayment(openHostedCheckout: openHostedCheckout)
            if completed || checkoutSession != nil { return }
            if attempt < 19 {
                try? await Task.sleep(for: .seconds(1.5))
            }
        }
        paymentFlow.transition(to: .processing)
        showToast(message: AppLocalization.text("payment_verifying", fallback: "Payment is still being verified. You can safely return later."))
    }

    @MainActor
    @discardableResult
    private func refreshActiveEazyShopifyPayment(openHostedCheckout: Bool) async -> Bool {
        let paymentID = activeEazyShopifyPaymentID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !paymentID.isEmpty else { return true }
        do {
            let status = try await AccountService.fetchEazyShopifyPaymentStatus(tallaPaymentID: paymentID)
            if status.paid || status.status == "PAID" {
                activeEazyShopifyPaymentID = ""
                cartItems.removeAll()
                appliedVoucher = nil
                voucherCodeInput = ""
                voucherError = nil
                paymentFlow.transition(to: .succeeded)
                await loadOrderHistory()
                showToast(message: status.shopifyOrderName.map { "Payment successful · \($0)" } ?? "Payment successful")
                return true
            }
            if ["FAILED", "CANCELLED"].contains(status.status) {
                paymentFlow.transition(to: status.status == "CANCELLED" ? .cancelled : .failed, error: status.message)
                return true
            }
            if openHostedCheckout, let paymentURL = status.paymentUrl {
                paymentFlow.transition(to: .awaitingCustomer)
                eazyShopifyBrowserKind = .eazyHosted
                checkoutSession = CheckoutSession(url: paymentURL, kind: .eazyHosted)
                return true
            }
            paymentFlow.transition(to: .processing)
            return false
        } catch {
            checkoutError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("payment_verification_unavailable", fallback: "Payment verification is temporarily unavailable.")
            )
            return false
        }
    }

    private func resetPaymentFlowAfterBenefitPayDismiss() {
        if paymentFlow.state == .awaitingCustomer {
            paymentFlow.cancel()
        }
    }

    private func resetPaymentFlowAfterMastercardDismiss() {
        if paymentFlow.state == .succeeded {
            cartItems.removeAll()
            appliedVoucher = nil
            voucherCodeInput = ""
            voucherError = nil
            showToast(message: AppLocalization.text("payment_complete", fallback: "Payment completed successfully."))
        }
        paymentFlow.reset()
    }

    @ViewBuilder
    private var appTabView: some View {
        if #available(iOS 18.0, *) {
            baseTabView
                .tabViewStyle(.sidebarAdaptable)
        } else {
            baseTabView
        }
    }

    private var baseTabView: some View {
        TabView(selection: $activeTab) {
            tabScreen(homeView, tab: .home)
                .tag(Tab.home)
                .tabItem {
                    Label(AppLocalization.text("home", fallback: "Home"), systemImage: Tab.home.systemImage)
                }

            tabScreen(shopView, tab: .shop)
                .tag(Tab.shop)
                .tabItem {
                    Label(AppLocalization.text("shop", fallback: "Shop"), systemImage: Tab.shop.systemImage)
                }

            tabScreen(brewingView, tab: .brewing)
                .tag(Tab.brewing)
                .tabItem {
                    Label(AppLocalization.text("brewing", fallback: "Brewing"), systemImage: Tab.brewing.systemImage)
                }

            tabScreen(accountView, tab: .account)
                .tag(Tab.account)
                .tabItem {
                    Label(AppLocalization.text("account", fallback: "Account"), systemImage: Tab.account.systemImage)
                }
        }
        .toolbar(.visible, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(tabBarBackgroundColor, for: .tabBar)
    }

    private func tabScreen<Content: View>(_ content: Content, tab: Tab) -> some View {
        VStack(spacing: 0) {
            header
                .frame(maxWidth: .infinity)
                .zIndex(10)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 0)
                            .id("tab-top")
                        content
                        footer
                        Color.clear
                            .frame(height: bottomScrollPadding(for: tab))
                    }
                    .padding(.top, topScrollPadding(for: tab))
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: accountScrollTarget) { _, target in
                    guard activeTab == .account, let target else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(target, anchor: .top)
                        }
                        accountScrollTarget = nil
                    }
                }
                .onChange(of: tabScrollTarget) { _, target in
                    guard activeTab == tab, target == tab else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            proxy.scrollTo("tab-top", anchor: .top)
                        }
                        tabScrollTarget = nil
                    }
                }
                .onChange(of: shopCatalogueScrollRequest) { _, _ in
                    guard activeTab == .shop, tab == .shop else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            proxy.scrollTo("shop-catalogue", anchor: .top)
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity)
    }

    private var tabBarBackgroundColor: Color {
        isLightAppearance
            ? Color(hex: 0xFFFCF8).opacity(0.98)
            : Color(hex: 0x100D0A).opacity(0.98)
    }

    private func topScrollPadding(for tab: Tab) -> CGFloat {
        tab == .account ? 8 : 0
    }

    private func bottomScrollPadding(for tab: Tab) -> CGFloat {
        tab == .account ? 56 : 28
    }

    private func dismissKeyboard() {
#if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }

    private func openTab(_ tab: Tab) {
        activeTab = tab
        tabScrollTarget = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            tabScrollTarget = tab
        }
    }

    private func openShop(category: String = "all", searchQuery: String = "") {
        activeCategory = category
        shopSearchQuery = searchQuery
        openTab(.shop)
    }

    private func openBrewing(category: String = "All") {
        activeBrewingCategory = category
        openTab(.brewing)
    }

    private func openAccountSection(_ target: String, authMode: AccountAuthMode? = nil) {
        if let authMode {
            switchAccountAuthMode(authMode)
        }

        switch target {
        case AccountSectionView.ScrollTarget.customer:
            isCustomerSectionExpanded = true
        case AccountSectionView.ScrollTarget.loyalty:
            isLoyaltySectionExpanded = true
            savedLoyaltyEmail = savedCustomerEmail.isEmpty ? savedLoyaltyEmail : savedCustomerEmail
        case AccountSectionView.ScrollTarget.library:
            isLibrarySectionExpanded = true
        case AccountSectionView.ScrollTarget.shopping:
            isShoppingSectionExpanded = true
        case AccountSectionView.ScrollTarget.brewing:
            isBrewingSectionExpanded = true
        case AccountSectionView.ScrollTarget.support:
            isSupportSectionExpanded = true
        default:
            break
        }

        activeTab = .account
        accountScrollTarget = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            accountScrollTarget = target
        }
    }

    private func handleShortcutDestination() {
        guard !shortcutDestination.isEmpty else { return }

        hasSeenWelcome = true
        let destination = shortcutDestination
        let searchQuery = shortcutSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        shortcutDestination = ""
        shortcutSearchQuery = ""

        switch destination {
        case "shop":
            openShop(searchQuery: searchQuery)
        case "concierge":
            if !searchQuery.isEmpty {
                conciergeRequest = searchQuery
            }
            openCoffeeConcierge()
        case "brewing":
            openBrewing()
        case "shelf", "favorites":
            openTab(.home)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isFavoriteShelfPresented = true
            }
        case "rewards":
            openAccountSection(AccountSectionView.ScrollTarget.loyalty)
        case "orders", "order-history", "checkout-return":
            openAccountSection(AccountSectionView.ScrollTarget.customer)
            Task {
                await loadOrderHistory()
                if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await loadLoyaltyAccount()
                }
            }
            showToast(message: AppLocalization.text("order_history_opened", fallback: "Order history opened"))
        default:
            break
        }
    }

    private func handleWelcomeChoice(_ choice: WelcomeChoice) {
        hasSeenWelcome = true

        switch choice {
        case .beans:
            openShop(category: "coffee-beans")
        case .drinks:
            openDrinksSection()
        case .gifts:
            openShop(category: "gifts")
        case .concierge:
            openCoffeeConcierge()
        }
    }

    private func openCoffeeConcierge() {
        isCoffeeConciergePresented = true
        showToast(message: AppLocalization.text("concierge_opened", fallback: "Coffee Concierge opened"))
    }

    private func openDrinksSection() {
        openShop(category: "ready-made-drinks")
        showToast(message: AppLocalization.text("drinks_opened", fallback: "Drinks opened"))
    }

    private func handleDeepLink(_ url: URL) {
        if url.scheme?.lowercased() == BenefitPaySDKConfiguration.callbackScheme {
            handleBenefitPayReturn(url)
            return
        }
        guard url.scheme?.lowercased() == "talla" else { return }

        let rawDestination = url.host?.isEmpty == false ? url.host : url.pathComponents.dropFirst().first
        let destination = rawDestination?.lowercased() ?? ""
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let pathTokens = url.pathComponents.dropFirst().map { $0.lowercased() }

        if isPaymentReturnDestination(destination: destination, pathTokens: pathTokens) {
            handlePaymentReturn(queryItems: queryItems)
            return
        }

        let searchQuery = queryItems.first(where: { $0.name == "q" || $0.name == "search" })?.value ?? ""

        shortcutSearchQuery = searchQuery
        shortcutDestination = destination
        handleShortcutDestination()
    }

    private func isPaymentReturnDestination(destination: String, pathTokens: [String]) -> Bool {
        if destination == "checkout-return" || destination == "payment-return" {
            return true
        }

        guard destination == "checkout" || destination == "payment" else {
            return false
        }

        return pathTokens.contains("return") || pathTokens.contains("complete")
    }

    private func handlePaymentReturn(queryItems: [URLQueryItem]) {
        if !activeEazyShopifyPaymentID.isEmpty {
            checkoutSession = nil
            paymentFlow.transition(to: .processing)
            Task {
                await waitForEazyShopifyProgress(openHostedCheckout: false)
            }
            return
        }
        let status = queryItems.first {
            ["status", "result", "paymentStatus"].contains($0.name)
        }?.value?.lowercased().replacingOccurrences(of: " ", with: "_") ?? ""
        let message = queryItems.first {
            ["message", "error", "reason"].contains($0.name)
        }?.value

        checkoutSession = nil
        openAccountSection(AccountSectionView.ScrollTarget.customer)

        switch status {
        case "success", "succeeded", "paid", "captured", "approved":
            cartItems.removeAll()
            appliedVoucher = nil
            voucherCodeInput = ""
            voucherError = nil
            paymentFlow.transition(to: .succeeded)
            showToast(message: AppLocalization.text("payment_complete", fallback: "Payment completed successfully."))
        case "cancelled", "canceled", "cancel":
            paymentFlow.transition(to: .cancelled)
            showToast(message: AppLocalization.text("payment_cancelled_title", fallback: "Payment cancelled"))
        case "failed", "failure", "declined", "error", "not_captured":
            paymentFlow.transition(
                to: .failed,
                error: message ?? AppLocalization.text("payment_failed_detail", fallback: "Please check your details or try another payment method.")
            )
            showToast(message: AppLocalization.text("payment_failed_title", fallback: "We couldn’t complete the payment."))
        default:
            paymentFlow.transition(to: .processing)
            showToast(message: AppLocalization.text("payment_processing", fallback: "Completing your order…"))
        }

        Task {
            await loadOrderHistory()
            if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await loadLoyaltyAccount()
            }
        }
    }

    private func handleBenefitPayReturn(_ url: URL) {
        guard let session = benefitPaySession,
              BenefitPayCallbackParser.referenceID(from: url) == session.referenceId else {
            benefitPaySession = nil
            paymentFlow.transition(to: .failed, error: "BenefitPay returned an invalid payment reference.")
            return
        }
        benefitPaySession = nil
        paymentFlow.transition(to: .processing)
        showToast(message: AppLocalization.text("payment_processing", fallback: "Completing your order…"))
        Task {
            do {
                let confirmation = try await BenefitPayService.confirm(session: session)
                guard confirmation.status == "succeeded" else {
                    paymentFlow.transition(to: .failed, error: "BenefitPay did not confirm this payment.")
                    return
                }
                cartItems.removeAll()
                appliedVoucher = nil
                voucherCodeInput = ""
                voucherError = nil
                paymentFlow.transition(to: .succeeded)
                await loadOrderHistory()
                if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await loadLoyaltyAccount()
                }
                showToast(message: AppLocalization.text("payment_complete", fallback: "Payment completed successfully."))
            } catch {
                paymentFlow.transition(to: .failed, error: error.localizedDescription)
                showToast(message: AppLocalization.text("payment_failed_title", fallback: "We couldn’t complete the payment."))
            }
        }
    }

    private func homeSettingText(_ value: String?, localizationKey: String, fallback: String) -> String {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedValue.isEmpty ? AppLocalization.text(localizationKey, fallback: fallback) : trimmedValue
    }

    private var homeHeroSubtitleText: String {
        let subtitle = homeSettingText(
            remoteHomeSettings?.heroSubtitle,
            localizationKey: "hero_subtitle",
            fallback: "Discover fresh roasts, brewing essentials, and rewarding coffee rituals."
        )

        if subtitle.localizedCaseInsensitiveContains("without digging through the app") {
            return AppLocalization.text("hero_subtitle_refined", fallback: "Discover fresh roasts, brewing essentials, and rewarding coffee rituals.")
        }

        return subtitle
    }

    private var header: some View {
        VStack(spacing: 14) {
            HStack {
                Button {
                    openTab(.home)
                } label: {
                    HStack(spacing: 12) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: customerProfile == nil ? 52 : 44, height: customerProfile == nil ? 52 : 44)

                        if let customerProfile {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AppLocalization.text("welcome_back", fallback: "Welcome back,"))
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(1.5)
                                    .textCase(.uppercase)
                                    .foregroundColor(Color(hex: 0xC8965A))

                                Text(customerFirstName(for: customerProfile))
                                    .font(displayFont(size: isCompact ? 25 : 26))
                                    .foregroundColor(primaryTextColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        } else {
                            Text("TALLA")
                                .font(displayFont(size: isCompact ? 32 : 28))
                                .tracking(isCompact ? 2 : 3)
                                .foregroundColor(primaryTextColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if !showLaunchSplash && shouldShowHeaderCartButton {
                    headerCartButton
                }

                Menu {
                    Section(AppLocalization.text("appearance", fallback: "Appearance")) {
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
                    Section(AppLocalization.text("language", fallback: "Language")) {
                        ForEach(AppLanguage.allCases) { language in
                            Button {
                                savedAppLanguage = language.rawValue
                            } label: {
                                HStack {
                                    Text(language.title)
                                    if (AppLanguage(rawValue: savedAppLanguage) ?? .system) == language {
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
                        .overlay(
                            Circle()
                                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.14), lineWidth: 1)
                        )
                }
                .menuStyle(.button)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(headerOverlayColor)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.14))
                .frame(height: 1)
        }
        .shadow(color: Color.black.opacity(isLightAppearance ? 0.035 : 0.18), radius: 16, y: 8)
    }

    private var headerCartButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                cartOpen = true
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                if showingCartCelebration {
                    Circle()
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.32 : 0.42), lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .scaleEffect(1.42)
                        .opacity(0.55)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                Image(systemName: cartCount > 0 ? "bag.fill" : "bag")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(cartCount > 0 ? Color(hex: 0x0A0804) : Color(hex: 0xC8965A))
                    .symbolEffect(.bounce, value: cartCelebrationID)
                    .frame(width: 40, height: 40)
                    .background(cartCount > 0 ? Color(hex: 0xC8965A) : cardFillColor)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.20 : 0.14), lineWidth: 1)
                    )

                if cartCount > 0 {
                    Text(cartCount > 99 ? "99+" : "\(cartCount)")
                        .font(.system(size: cartCount > 99 ? 8 : 9, weight: .black))
                        .foregroundColor(Color(hex: 0x1A1208))
                        .padding(.horizontal, cartCount > 99 ? 6 : 0)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Color(hex: 0xF7E1B7))
                        .contentTransition(.numericText())
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: 0x8A5E30).opacity(0.35), lineWidth: 1.2)
                        )
                        .shadow(color: Color.black.opacity(isLightAppearance ? 0.12 : 0.22), radius: 5, y: 2)
                        .offset(x: 5, y: -4)
                }
            }
            .frame(width: 44, height: 44, alignment: .center)
            .scaleEffect(showingCartCelebration ? 1.16 : 1)
            .rotationEffect(.degrees(showingCartCelebration ? -4 : 0))
            .animation(.spring(response: 0.26, dampingFraction: 0.48), value: showingCartCelebration)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppLocalization.text("open_bag", fallback: "Open bag"))
        .accessibilityValue(
            cartCount > 0
                ? String(format: AppLocalization.text("items_in_bag", fallback: "%d items in bag"), cartCount)
                : AppLocalization.text("empty_bag", fallback: "Empty bag")
        )
    }

    private var homeView: some View {
        VStack(spacing: 0) {
            heroSection
            homeSurprisePick
            homeFavoritesShelf
            featuredProducts
            tallaPassportSection
            homeRecentlyViewedShelf
        }
    }

    private var homeSurprisePick: some View {
        VStack(alignment: .leading, spacing: 14) {
            surprisePickHeader

            if isSurprisePickExpanded {
                surprisePickExpandedContent
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(isSurprisePickExpanded ? 16 : 12)
        .background(
            LinearGradient(
                colors: isLightAppearance
                    ? [Color(hex: 0xFFF8EF), Color(hex: 0xF0DEC5)]
                    : [Color(hex: 0x21170F), Color(hex: 0x120D08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.2 : 0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: isSurprisePickExpanded)
    }

    private var surprisePickHeader: some View {
        Button {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                isSurprisePickExpanded.toggle()
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image("Logo")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(10)
                    .frame(width: isSurprisePickExpanded ? 42 : 36, height: isSurprisePickExpanded ? 42 : 36)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: isSurprisePickExpanded ? 4 : 2) {
                    Text(AppLocalization.text("daily_surprise_title", fallback: "Today's Hot Pick"))
                        .font(labelFont(size: isSurprisePickExpanded ? 10 : 9, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Text(AppLocalization.text("daily_surprise_detail", fallback: "Not sure what to choose? Let Talla decide."))
                        .font(bodyFont(size: isSurprisePickExpanded ? 13 : 12))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: isSurprisePickExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(primaryTextColor)
                    .frame(width: 30, height: 30)
                    .background(elevatedSurfaceColor.opacity(0.8))
                    .clipShape(Circle())
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppLocalization.text("daily_surprise_title", fallback: "Today's Hot Pick"))
        .accessibilityValue(isSurprisePickExpanded ? "Expanded" : "Collapsed")
    }

    private var surprisePickExpandedContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Spacer(minLength: 0)

                Button {
                    refreshSurprisePick()
                } label: {
                    Text(AppLocalization.text("surprise_me_refresh", fallback: "Surprise me ↻"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(Color(hex: 0xC8965A))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("surprise_me_refresh", fallback: "Surprise me ↻"))
            }

            if isLoadingProducts && products.isEmpty {
                homeSurprisePickSkeleton
            } else if let product = surprisePickProduct {
                if isSurprisePickRevealed {
                    revealedSurprisePick(product)
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                } else {
                    surpriseRevealCup
                        .transition(.scale(scale: 0.96).combined(with: .opacity))
                }
            } else {
                actionEmptyState(
                    message: AppLocalization.text("surprise_pick_empty", fallback: "Load the shop once and Talla will pick something fun for you."),
                    actionTitle: AppLocalization.text("browse_shop", fallback: "Browse Shop"),
                    systemImage: "sparkles"
                ) {
                    openShop()
                }
            }
        }
    }

    private var surpriseRevealCup: some View {
        Button {
            revealSurprisePick()
        } label: {
            ZStack {
                CoffeeBeansBurstView(accentColor: Color(hex: 0xC8965A), id: surpriseRevealID)
                    .opacity(surpriseRevealID == 0 ? 0 : 1)
                    .offset(y: -12)

                VStack(spacing: 12) {
                    Image("Logo")
                        .resizable()
                        .renderingMode(.template)
                        .scaledToFit()
                        .foregroundColor(Color(hex: 0x0A0804))
                        .padding(24)
                        .frame(width: 104, height: 104)
                        .background(Color(hex: 0xC8965A))
                        .clipShape(Circle())
                        .rotationEffect(.degrees(surpriseRevealID.isMultiple(of: 2) ? -4 : 4))
                        .animation(.spring(response: 0.22, dampingFraction: 0.42), value: surpriseRevealID)

                    Text(AppLocalization.text("tap_cup_reveal_pick", fallback: "Tap the cup to reveal today's pick"))
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.4)
                        .textCase(.uppercase)
                        .foregroundColor(primaryTextColor)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(AppLocalization.text("limited_daily_reward", fallback: "Limited daily reward inside"))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppLocalization.text("tap_cup_reveal_pick", fallback: "Tap the cup to reveal today's pick"))
    }

    private func revealedSurprisePick(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ProductThumbnail(imageURL: product.imageURL, size: isCompact ? 92 : 108, cornerRadius: 18)
                    .scaleEffect(surpriseRevealID.isMultiple(of: 2) ? 1 : 1.045)
                    .rotationEffect(.degrees(surpriseRevealID.isMultiple(of: 2) ? -1.5 : 1.5))
                    .animation(.spring(response: 0.32, dampingFraction: 0.58), value: surpriseRevealID)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(AppLocalization.text("surprise_revealed", fallback: "Revealed"))
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.4)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0xC8965A))

                        Text(AppLocalization.text("limited_daily_reward", fallback: "Limited daily reward inside"))
                            .font(labelFont(size: 8, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(hex: 0xC8965A).opacity(0.9))
                            .clipShape(Capsule())
                    }

                    Text(product.name)
                        .font(titleFont(size: isCompact ? 18 : 21))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(product.price)
                        .font(labelFont(size: 12, weight: .bold))
                        .foregroundColor(secondaryTextColor)
                }
            }

            surprisePickInfoRow(
                title: AppLocalization.text("why_selected", fallback: "Why it was selected"),
                detail: surprisePickReason(for: product),
                systemImage: "sparkles"
            )

            surprisePickInfoRow(
                title: AppLocalization.text("best_brewing_method", fallback: "Best brewing method"),
                detail: surprisePickBrewMethod(for: product),
                systemImage: "drop.fill"
            )

            HStack(spacing: 8) {
                Button {
                    addToCart(product: product)
                } label: {
                    Label(AppLocalization.text("add_pick_to_bag", fallback: "Add"), systemImage: "bag.badge.plus")
                        .font(labelFont(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color(hex: 0xC8965A))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!product.isAvailableForSale || selectedVariant(for: product) == nil)

                Button {
                    refreshSurprisePick()
                } label: {
                    Label(AppLocalization.text("surprise_me", fallback: "Surprise me"), systemImage: "shuffle")
                        .font(labelFont(size: 10, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(elevatedSurfaceColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(elevatedSurfaceColor.opacity(isLightAppearance ? 0.78 : 0.62))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(alignment: .topTrailing) {
            CoffeeBeansBurstView(accentColor: Color(hex: 0xC8965A), id: surpriseRevealID)
                .offset(x: 18, y: -34)
                .allowsHitTesting(false)
        }
    }

    private func surprisePickInfoRow(title: String, detail: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(hex: 0xC8965A))
                .frame(width: 24, height: 24)
                .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(labelFont(size: 9, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))

                Text(detail)
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func refreshSurprisePick() {
        let availableProducts = surprisePickProducts
        guard !availableProducts.isEmpty else {
            openShop()
            showToast(message: AppLocalization.text("loading_shop", fallback: "Loading the shop"))
            return
        }

        if availableProducts.count == 1 {
            surprisePickProductID = availableProducts[0].id
        } else {
            let currentID = surprisePickProduct?.id
            let nextProduct = availableProducts.filter { $0.id != currentID }.randomElement() ?? availableProducts[0]
            surprisePickProductID = nextProduct.id
        }

        isSurprisePickRevealed = true
        surpriseRevealID += 1
        delightFeedbackTrigger += 1
        showToast(message: AppLocalization.text("surprise_pick_ready", fallback: "New pick ready"))
    }

    private func revealSurprisePick() {
        guard surprisePickProduct != nil else {
            openShop()
            showToast(message: AppLocalization.text("loading_shop", fallback: "Loading the shop"))
            return
        }

        withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
            isSurprisePickRevealed = true
            surpriseRevealID += 1
        }
        delightFeedbackTrigger += 1
    }

    private func surprisePickReason(for product: Product) -> String {
        let source = "\(product.name) \(product.desc) \(product.categoryLabel)".lowercased()

        if source.contains("ethiopia") || source.contains("guji") || source.contains("floral") || source.contains("berry") {
            return AppLocalization.text("surprise_reason_floral", fallback: "It brings a bright, expressive cup with floral and berry-like energy.")
        }

        if source.contains("arabic") || source.contains("shamali") || source.contains("qahwa") || source.contains("cardamom") {
            return AppLocalization.text("surprise_reason_arabic", fallback: "It fits the Talla ritual: warm, aromatic and made for sharing.")
        }

        if source.contains("brazil") || source.contains("chocolate") || source.contains("caramel") {
            return AppLocalization.text("surprise_reason_comfort", fallback: "It is an easy crowd-pleaser with a sweet, comforting profile.")
        }

        if source.contains("gift") || source.contains("box") {
            return AppLocalization.text("surprise_reason_gift", fallback: "It is a ready-to-share pick for hosting, gifting or a small treat.")
        }

        return AppLocalization.text("surprise_reason_default", fallback: "It stood out as a useful daily pick from the Talla shelf.")
    }

    private func surprisePickBrewMethod(for product: Product) -> String {
        let source = "\(product.name) \(product.desc) \(product.categoryLabel)".lowercased()

        if source.contains("arabic") || source.contains("shamali") || source.contains("qahwa") || source.contains("cardamom") {
            return AppLocalization.text("brew_method_arabic", fallback: "Arabic coffee")
        }

        if source.contains("espresso") || source.contains("brazil") || source.contains("chocolate") {
            return AppLocalization.text("brew_method_espresso", fallback: "Espresso")
        }

        if source.contains("aeropress") || source.contains("balanced") {
            return "AeroPress"
        }

        if source.contains("coffee") || source.contains("bean") || source.contains("ethiopia") || source.contains("guji") || source.contains("colombia") {
            return "V60"
        }

        return AppLocalization.text("brew_method_any", fallback: "Enjoy as-is")
    }

    @ViewBuilder
    private var homeFavoritesShelf: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("favorites_shelf", fallback: "Your shelf"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Text(AppLocalization.text("shelf_functional_detail", fallback: "Your favourites, previous orders, and recent discoveries."))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Button {
                    isFavoriteShelfPresented = true
                } label: {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(width: 38, height: 38)
                        .background(Color(hex: 0xC8965A))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("open_favorites_shelf", fallback: "Open favorites shelf"))
            }

            if customerProfile == nil {
                signedOutShelfPrompt
            }

            if !reorderPrompts.isEmpty {
                personalizedShelfSection(
                    title: AppLocalization.text("order_again_home", fallback: "Order Again"),
                    detail: AppLocalization.text("order_again_detail", fallback: "Products you previously purchased."),
                    systemImage: "clock.arrow.circlepath"
                ) {
                    VStack(spacing: 10) {
                        ForEach(reorderPrompts.prefix(3), id: \.product.id) { prompt in
                            reorderPromptCard(prompt)
                        }

                        if let recommendation = orderBasedRecommendation {
                            orderRecommendationCard(source: recommendation.source, recommended: recommendation.recommended)
                        }
                    }
                }
            }

            if customerProfile != nil && reorderPrompts.isEmpty && recentlyViewedUnboughtProducts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("your_shelf_empty", fallback: "Your shelf will fill with reorders and recently viewed products. Saved favourites stay inside the shelf button."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "books.vertical.fill"
                ) {
                    openShop()
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
    }

    @ViewBuilder
    private var homeRecentlyViewedShelf: some View {
        recentlyViewedShelfSection
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
    }

    @ViewBuilder
    private var recentlyViewedShelfSection: some View {
        personalizedShelfSection(
            title: AppLocalization.text("recently_viewed", fallback: "Recently Viewed"),
            detail: AppLocalization.text("recently_viewed_home_detail", fallback: "Products you explored but did not buy."),
            systemImage: "eye.fill",
            trailingHeader: recentlyViewedSectionMenu
        ) {
            let products = Array(recentlyViewedUnboughtProducts.prefix(6))

            if products.isEmpty {
                Text(AppLocalization.text("home_recently_viewed_empty", fallback: "Open products in the shop and they will appear here."))
                    .font(bodyFont(size: 12))
                    .foregroundColor(tertiaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(elevatedSurfaceColor.opacity(isLightAppearance ? 0.72 : 0.54))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                if !isCompact && products.count <= 3 {
                    HStack(spacing: 12) {
                        ForEach(products) { product in
                            shelfProductCard(product, width: 150)
                        }
                    }
                    .padding(.vertical, 2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    GeometryReader { proxy in
                        let cardWidth = max(132, min(162, (proxy.size.width - 24) / 2.15))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(products) { product in
                                    shelfProductCard(product, width: cardWidth)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .frame(height: 172)
                }
            }
        }
    }

    @ViewBuilder
    private func personalizedProductShelfSection(title: String, detail: String, systemImage: String, products: [Product], emptyMessage: String) -> some View {
        personalizedShelfSection(title: title, detail: detail, systemImage: systemImage) {
            if products.isEmpty {
                Text(emptyMessage)
                    .font(bodyFont(size: 12))
                    .foregroundColor(tertiaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(elevatedSurfaceColor.opacity(isLightAppearance ? 0.72 : 0.54))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(products) { product in
                            shelfProductCard(product)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var recentlyViewedSectionMenu: AnyView {
        AnyView(
            Menu {
                Button(role: .destructive) {
                    savedRecentlyViewedProductIDs = ""
                } label: {
                    Label(AppLocalization.text("clear_history", fallback: "Clear history"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0xC8965A))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.14))
                    .clipShape(Circle())
            }
            .menuStyle(.button)
            .disabled(recentlyViewedProductIDs.isEmpty)
        )
    }

    private func personalizedShelfSection<Content: View>(title: String, detail: String, systemImage: String, trailingHeader: AnyView = AnyView(EmptyView()), @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(hex: 0xC8965A))
                    .frame(width: 28, height: 28)
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.4)
                        .textCase(.uppercase)
                        .foregroundColor(primaryTextColor)

                    Text(detail)
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                }

                Spacer(minLength: 8)

                trailingHeader
            }

            content()
        }
        .padding(12)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var shelfGreetingText: String {
        if customerProfile != nil {
            return AppLocalization.text("shelf_summary_signed_in", fallback: "Your favourites, previous orders, and recent discoveries.")
        }

        return AppLocalization.text("shelf_signed_out_prompt", fallback: "Sign in to save favourites and quickly reorder.")
    }

    private func customerFirstName(for profile: ShopifyCustomerProfile) -> String {
        let candidates = [
            profile.firstName,
            profile.displayName.components(separatedBy: .whitespacesAndNewlines).first,
            profile.email.components(separatedBy: "@").first
        ]

        for candidate in candidates {
            let name = (candidate ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let normalized = name.lowercased()

            if !name.isEmpty && normalized != "talla" && normalized != "admin" && normalized != "customer" {
                return name
            }
        }

        return AppLocalization.text("customer_fallback_name", fallback: "there")
    }

    private var signedOutShelfPrompt: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Color(hex: 0xC8965A))
                .frame(width: 34, height: 34)
                .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.14))
                .clipShape(Circle())

            Text(AppLocalization.text("shelf_sign_in_detail", fallback: "Sign in to save favourites and quickly reorder."))
                .font(bodyFont(size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            Button {
                openAccountSection(AccountSectionView.ScrollTarget.customer, authMode: .signIn)
            } label: {
                Text(AppLocalization.text("sign_in", fallback: "Sign In"))
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(elevatedSurfaceColor.opacity(isLightAppearance ? 0.72 : 0.54))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func shelfProductCard(_ product: Product, width: CGFloat = 140) -> some View {
        Button {
            recordRecentlyViewed(product)
            selectedProduct = product
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ProductThumbnail(imageURL: product.imageURL, size: 76, cornerRadius: 16)

                Text(customerFacingProductName(for: product))
                    .font(titleFont(size: 15))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .frame(width: width - 24, alignment: .leading)

                Text(product.price)
                    .font(labelFont(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: 0xC8965A))
            }
            .padding(12)
            .frame(width: width, alignment: .topLeading)
            .frame(maxHeight: .infinity, alignment: .topLeading)
            .background(elevatedSurfaceColor.opacity(isLightAppearance ? 0.72 : 0.54))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func reorderPromptCard(_ prompt: ReorderPrompt) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ProductThumbnail(imageURL: prompt.product.imageURL, size: isCompact ? 82 : 96, cornerRadius: 18)

            VStack(alignment: .leading, spacing: 6) {
                Text(String(format: AppLocalization.text("running_low_on_product", fallback: "Running low on %@?"), customerFacingProductName(for: prompt.product)))
                    .font(titleFont(size: isCompact ? 21 : 23))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(String(format: AppLocalization.text("last_ordered_days_ago", fallback: "Last ordered %d days ago"), prompt.daysAgo))
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
            }

            Spacer(minLength: 0)

            Button {
                buyAgain(order: prompt.order)
            } label: {
                Text(AppLocalization.text("reorder", fallback: "Reorder"))
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .glassEffect(.regular.tint(Color(hex: 0xC8965A)).interactive(), in: .capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func orderRecommendationCard(source: Product, recommended: Product) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(hex: 0xC8965A))
                .frame(width: 34, height: 34)
                .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: AppLocalization.text("loved_product_prompt", fallback: "Loved %@?"), customerFacingProductName(for: source)))
                    .font(titleFont(size: 15))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .fixedSize(horizontal: false, vertical: true)

                Text(String(format: AppLocalization.text("try_product_gathering", fallback: "Try %@ for your next gathering."), customerFacingProductName(for: recommended)))
                    .font(bodyFont(size: 12))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(3)
                    .minimumScaleFactor(0.86)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button {
                if recommended.hasVariantChoices {
                    recordRecentlyViewed(recommended)
                    selectedProduct = recommended
                } else {
                    addToCart(product: recommended)
                }
            } label: {
                Image(systemName: recommended.hasVariantChoices ? "slider.horizontal.3" : "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(!recommended.isAvailableForSale || selectedVariant(for: recommended) == nil)
            .accessibilityLabel(AppLocalization.text("add_recommended_product", fallback: "Add recommended product"))
        }
        .padding(12)
        .background(elevatedSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var favoriteShelfSheet: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(AppLocalization.text("favorites_shelf", fallback: "Your shelf"))
                                .font(displayFont(size: isCompact ? 30 : 34))
                                .tracking(1.4)
                                .foregroundColor(primaryTextColor)

                            Text(AppLocalization.text("favorites_shelf_stand_detail", fallback: "A stand for the coffees and goods you heart."))
                                .font(bodyFont(size: 14))
                                .foregroundColor(secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 12)

                        Button {
                            isFavoriteShelfPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(primaryTextColor)
                                .frame(width: 36, height: 36)
                                .background(cardFillColor)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))
                    }

                    favoriteShelfStand
                }
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 34)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var favoriteShelfStand: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppLocalization.text("favorites_stand", fallback: "Favorites stand"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Text(String(format: AppLocalization.text("favorites_count", fallback: "%d saved picks"), favoriteProducts.count))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                }
            }
            .padding(.bottom, 16)

            if favoriteProducts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("favorites_empty", fallback: "Tap the heart on any coffee or gift to save it here."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "heart.fill"
                ) {
                    isFavoriteShelfPresented = false
                    openShop()
                }
            } else {
                ForEach(Array(favoriteProducts.enumerated()), id: \.element.id) { index, product in
                    favoriteShelfProductRow(product: product, index: index)

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.34 : 0.24))
                        .frame(height: 8)
                        .overlay(alignment: .top) {
                            Rectangle()
                                .fill(Color.white.opacity(isLightAppearance ? 0.35 : 0.08))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.bottom, 14)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(elevatedSurfaceColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isLightAppearance ? 0.08 : 0.24), radius: 18, x: 0, y: 10)
    }

    private func favoriteShelfProductRow(product: Product, index: Int) -> some View {
        Button {
            isFavoriteShelfPresented = false
            recordRecentlyViewed(product)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                selectedProduct = product
            }
        } label: {
            HStack(alignment: .center, spacing: 14) {
                ProductThumbnail(imageURL: product.imageURL, size: 78, cornerRadius: 14)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? -2 : 2))
                    .shadow(color: Color.black.opacity(isLightAppearance ? 0.08 : 0.24), radius: 8, x: 0, y: 5)

                VStack(alignment: .leading, spacing: 6) {
                    Text(product.categoryLabel)
                        .font(labelFont(size: 9, weight: .bold))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Text(product.name)
                        .font(titleFont(size: 18))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(product.price)
                        .font(labelFont(size: 11, weight: .bold))
                        .foregroundColor(secondaryTextColor)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tertiaryTextColor)
            }
            .padding(12)
            .background(cardFillColor)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var tallaPassportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                passportLogoIcon

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(AppLocalization.text("talla_passport", fallback: "Talla Passport"))
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(2.2)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0xC8965A))

                        Text("\(stampedCoffeePassportOriginKeys.count) / \(coffeePassportOrigins.count) \(AppLocalization.text("passport_origins", fallback: "origins"))")
                            .font(labelFont(size: 10, weight: .bold))
                            .foregroundColor(secondaryTextColor)
                    }

                    Text(coffeePassportOrigins.map(\.title).joined(separator: " · "))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 0)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.10))

                    Capsule(style: .continuous)
                        .fill(LinearGradient(colors: [Color(hex: 0xC8965A), Color(hex: 0x6F8B55)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(proxy.size.width * passportProgressFraction, stampedCoffeePassportOriginKeys.isEmpty ? 0 : 12))
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: stampedCoffeePassportOriginKeys.count)
                }
            }
            .frame(height: 10)

            Text(String(format: AppLocalization.text("passport_completed_count", fallback: "%d of %d completed"), stampedCoffeePassportOriginKeys.count, coffeePassportOrigins.count))
                .font(labelFont(size: 9, weight: .bold))
                .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)

            Text(isCoffeePassportComplete
                ? AppLocalization.text("talla_passport_complete_short", fallback: "Passport complete. Your reward is ready in Rewards.")
                : AppLocalization.text("talla_passport_reward_hint_short", fallback: "Complete your passport to unlock a reward."))
                .font(bodyFont(size: 12))
                .foregroundColor(isCoffeePassportComplete ? Color(hex: 0x6F8B55) : secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    isTallaPassportExpanded.toggle()
                }
            } label: {
                Label(
                    isTallaPassportExpanded
                        ? AppLocalization.text("hide_passport", fallback: "Hide Passport")
                        : AppLocalization.text("view_passport", fallback: "View Passport"),
                    systemImage: isTallaPassportExpanded ? "chevron.up" : "arrow.right"
                )
                .font(labelFont(size: 10, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))
            }
            .buttonStyle(.plain)

            if isTallaPassportExpanded {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                    ForEach(coffeePassportOrigins) { origin in
                        passportStampButton(for: origin)
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 18)
        .padding(.bottom, 20)
    }

    private var passportLogoIcon: some View {
        ZStack {
            Circle()
                .fill(Color(hex: 0xC8965A))

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(hex: 0x0A0804))
                .frame(width: 16, height: 20)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color(hex: 0xF7E1B7).opacity(0.85), lineWidth: 1)
                )

            Image(systemName: "seal.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(Color(hex: 0xF7E1B7))
                .offset(y: 1)
        }
        .frame(width: 38, height: 38)
        .accessibilityHidden(true)
    }

    private func passportStampButton(for origin: CoffeePassportOrigin) -> some View {
        let isStamped = stampedCoffeePassportOriginKeys.contains(origin.id)

        return Button {
            openShop(category: "coffee-beans", searchQuery: origin.title)
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(origin.symbol)
                        .font(.system(size: 17, weight: .bold))
                        .frame(width: 20, height: 20)

                    Text(origin.title)
                        .font(labelFont(size: 10, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Text(isStamped
                    ? AppLocalization.text("passport_origin_stamped", fallback: "Stamped")
                    : origin.detail)
                    .font(bodyFont(size: 11))
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .foregroundColor(isStamped ? Color(hex: 0x0A0804) : primaryTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isStamped ? Color(hex: 0xC8965A) : elevatedSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(hex: 0xC8965A).opacity(isStamped ? 0 : 0.18), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if isStamped {
                    Text(AppLocalization.text("passport_stamp_mark", fallback: "STAMPED"))
                        .font(labelFont(size: 7, weight: .black))
                        .tracking(0.8)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Color(hex: 0xF7E1B7).opacity(0.9))
                        .clipShape(Capsule())
                        .rotationEffect(.degrees(-8))
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var homeQuickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("start_here", fallback: "Start here"))
                .font(labelFont(size: 10, weight: .bold))
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))

            LazyVGrid(columns: homeQuickActionColumns, spacing: 10) {
                ActionTileView(
                    title: AppLocalization.text("shop_bestsellers", fallback: "Shop Bestsellers"),
                    detail: AppLocalization.text("shop_bestsellers_detail", fallback: "Go straight to coffees, tools, and gifts."),
                    systemImage: "bag.fill",
                    titleFont: labelFont(size: 10, weight: .bold),
                    detailFont: bodyFont(size: 12),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: Color(hex: 0xC8965A),
                    backgroundColor: cardFillColor,
                    strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08),
                    minHeight: 106
                ) {
                    openShop()
                }

                ActionTileView(
                    title: AppLocalization.text("check_rewards_home", fallback: "Check Rewards"),
                    detail: AppLocalization.text("check_rewards_home_detail", fallback: "See Beans, rewards, and your member status."),
                    systemImage: "sparkles.rectangle.stack.fill",
                    titleFont: labelFont(size: 10, weight: .bold),
                    detailFont: bodyFont(size: 12),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: Color(hex: 0xC8965A),
                    backgroundColor: cardFillColor,
                    strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08),
                    minHeight: 106
                ) {
                    openAccountSection(AccountSectionView.ScrollTarget.loyalty)
                }

                ActionTileView(
                    title: AppLocalization.text("reorder_faster", fallback: "Reorder Faster"),
                    detail: AppLocalization.text("reorder_faster_detail", fallback: "Open saved bags, addresses, and recent orders."),
                    systemImage: "arrow.clockwise.circle.fill",
                    titleFont: labelFont(size: 10, weight: .bold),
                    detailFont: bodyFont(size: 12),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: Color(hex: 0xC8965A),
                    backgroundColor: cardFillColor,
                    strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08),
                    minHeight: 106
                ) {
                    isLibrarySectionExpanded = true
                    isDeliveryDetailsExpanded = false
                    openAccountSection(AccountSectionView.ScrollTarget.library)
                }

                ActionTileView(
                    title: AppLocalization.text("brew_better", fallback: "Brew Better"),
                    detail: AppLocalization.text("brew_better_detail", fallback: "Use guides and saved recipes for your next cup."),
                    systemImage: "drop.fill",
                    titleFont: labelFont(size: 10, weight: .bold),
                    detailFont: bodyFont(size: 12),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: Color(hex: 0xC8965A),
                    backgroundColor: cardFillColor,
                    strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08),
                    minHeight: 106
                ) {
                    openBrewing()
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
    }

    private var homeLoyaltyTeaser: some View {
        Group {
            if let loyaltyAccount, !savedLoyaltyEmail.isEmpty {
                let rewardProgressState = rewardProgress(for: loyaltyAccount.pointsBalance)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("The Talla Club")
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(2.2)
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: 0xC8965A))

                            Text(expiringVouchers.isEmpty ? loyaltyAccount.nextReward : String(format: AppLocalization.text("rewards_active_count", fallback: "%d rewards active"), expiringVouchers.count))
                                .font(titleFont(size: 20))
                                .foregroundColor(primaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 12)

                        Button {
                            openAccountSection(AccountSectionView.ScrollTarget.loyalty)
                        } label: {
                            Text(AppLocalization.text("rewards_button", fallback: "Rewards"))
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
                            Text(AppLocalization.text("reward_progress_home", fallback: "Reward Progress"))
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
                                    .animation(.spring(response: 0.48, dampingFraction: 0.78), value: rewardProgressState.fraction)
                            }
                        }
                        .frame(height: 8)
                    }

                    if let voucher = expiringVouchers.first {
                        Text("\(AppLocalization.text("expires_soon", fallback: "Expires soon")): \(voucher.reward) • \(voucherExpiryLabel(for: voucher))")
                            .font(bodyFont(size: 13))
                            .foregroundColor(voucherExpiresSoon(voucher) ? Color.red.opacity(0.85) : secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(String(format: AppLocalization.text("beans_until_reward_unlock", fallback: "%d Beans until your next reward unlock."), rewardProgressState.remaining))
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
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(homeSettingText(remoteHomeSettings?.heroEyebrow, localizationKey: "roastery", fallback: "Roastery"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(3)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Text(AppLocalization.text("coffee_daily_rituals", fallback: "Coffee for daily rituals"))
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                }

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                    Text(homeSettingText(remoteHomeSettings?.heroBadge, localizationKey: "fresh_roast", fallback: "Fresh Roast"))
                        .font(labelFont(size: 9, weight: .bold))
                        .tracking(1.5)
                        .textCase(.uppercase)
                }
                .foregroundColor(Color(hex: 0x8B5B2A))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(hex: 0xF3DFC2).opacity(isLightAppearance ? 0.95 : 0.12))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.22 : 0.08), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(homeSettingText(remoteHomeSettings?.heroTitle, localizationKey: "hero_title", fallback: "Specialty coffee,\nroasted with intention"))
                    .font(displayFont(size: isCompact ? 24 : 30))
                    .lineSpacing(1)
                    .foregroundColor(primaryTextColor)

                Text(homeHeroSubtitleText)
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 10) {
                Button {
                    openShop()
                } label: {
                    Text(homeSettingText(remoteHomeSettings?.primaryButtonTitle, localizationKey: "explore_coffees", fallback: "EXPLORE COFFEES").uppercased())
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Color(hex: 0xC8965A))
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)

                Button {
                    openBrewing()
                } label: {
                    Text(homeSettingText(remoteHomeSettings?.secondaryButtonTitle, localizationKey: "brewing_guide", fallback: "BREWING GUIDE").uppercased())
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(2)
                        .foregroundColor(primaryTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.18 : 0.08), lineWidth: 1)
                        )
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
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
            RoundedRectangle(cornerRadius: 24, style: .continuous)
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
        .padding(.top, 4)
        .padding(.bottom, 8)
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
            isCustomerSignedIn: customerProfile != nil,
            savedLoyaltyEmail: savedLoyaltyEmail,
            loyaltyEmail: $loyaltyEmail,
            loyaltyError: loyaltyError,
            isLoadingLoyalty: isLoadingLoyalty,
            loyaltyAccount: loyaltyAccount,
            loyaltyPerks: loyaltyPerks,
            rewardProgress: loyaltyAccount.map { rewardProgress(for: $0.pointsBalance) },
            tierProgress: loyaltyAccount.map { tierProgress(for: $0.pointsBalance) },
            stampProductImageURL: loyaltyStampProductImageURL,
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

    private var loyaltyStampProductImageURL: URL? {
        products.first {
            ($0.categoryKey == "coffee-beans" || $0.categoryKey == "arabic-coffee-beans")
                && $0.imageURL != nil
        }?.imageURL ?? products.first(where: { $0.imageURL != nil })?.imageURL
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
            isSigningInWithApple: isSigningInWithApple,
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
            configureAppleSignInRequest: configureAppleSignInRequest(_:),
            handleAppleSignInResult: handleAppleSignInResult(_:),
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
            return isCreatingAccount
                ? AppLocalization.text("creating_account", fallback: "CREATING ACCOUNT...")
                : AppLocalization.text("create_account", fallback: "CREATE ACCOUNT")
        }

        if accountAuthMode == .changePassword {
            return isResettingPassword
                ? AppLocalization.text("updating_password", fallback: "UPDATING PASSWORD...")
                : AppLocalization.text("change_password", fallback: "CHANGE PASSWORD")
        }

        return isSigningIn || isSigningInWithApple || isLoadingCustomer
            ? AppLocalization.text("signing_in", fallback: "SIGNING IN...")
            : AppLocalization.text("sign_in", fallback: "SIGN IN")
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
            ordersError: ordersError,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            tasteMemoryLookup: tasteMemoryLookup,
            buyAgainAction: { order in
                buyAgain(order: order)
            },
            saveTasteMemoryAction: { order, item, reaction, tags in
                saveTasteMemory(order: order, item: item, reaction: reaction, tags: tags)
            },
            browseProductsAction: {
                openShop()
            }
        )
    }

    private var featuredProducts: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppLocalization.text("roastery_selection", fallback: "Roastery Selection"))
                        .font(labelFont(size: 10, weight: .semibold))
                        .tracking(3)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Text(AppLocalization.text("signature_roasts", fallback: "Signature Roasts"))
                        .font(displayFont(size: 24))
                        .tracking(0.5)
                        .foregroundColor(primaryTextColor)
                }

                Spacer(minLength: 12)

                Button {
                    openShop()
                } label: {
                    Label(AppLocalization.text("browse_shop", fallback: "Browse Shop"), systemImage: "arrow.right")
                        .font(labelFont(size: 11, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))
                }
                .buttonStyle(.plain)
            }

            if isLoadingProducts && products.isEmpty {
                productSkeletonGrid(count: isCompact ? 2 : 4)
            } else if let loadingError, products.isEmpty {
                errorSection(message: loadingError)
            } else {
                let roasts = Array(signatureRoastProducts.prefix(6))

                if isCompact {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(roasts) { product in
                                signatureRoastCard(product)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } else {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: min(4, max(roasts.count, 1))),
                        alignment: .leading,
                        spacing: 12
                    ) {
                        ForEach(roasts) { product in
                            signatureRoastCard(product)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .padding(.bottom, 28)
    }

    private var collections: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("")
                    .font(labelFont(size: 10, weight: .semibold))
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))

                Text(AppLocalization.text("from_the_roastery", fallback: "FROM THE ROASTERY"))
                    .font(displayFont(size: 28))
                    .tracking(1)
                    .foregroundColor(primaryTextColor)

                Text(AppLocalization.text("from_the_roastery_detail", fallback: "A tighter selection of coffees, tools, and gifts shaped around the daily ritual of the roastery."))
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
            activeCategoryTitle: activeCategory == "all" ? AppLocalization.text("full_catalog", fallback: "Full catalog") : categoryLabel(for: activeCategory),
            availableCategories: availableCategories,
            filteredProducts: filteredProducts,
            allProductsAreEmpty: products.isEmpty,
            isLoadingProducts: isLoadingProducts,
            loadingError: loadingError,
            activeCategory: $activeCategory,
            searchQuery: $shopSearchQuery,
            sortMode: $shopSortMode,
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
            recentSearches: recentSearchQueries,
            quickSearches: quickSearches,
            guidancePanel: AnyView(shopGuidancePanel),
            renderProductCard: { product, showDescription in
                AnyView(productCard(product: product, showDescription: showDescription))
            },
            submitSearch: { query in
                recordRecentSearch(query)
            },
            selectQuickSearch: { query, categoryKey in
                activeCategory = categoryKey
                shopSearchQuery = query
                recordRecentSearch(query)
                shopCatalogueScrollRequest += 1
            },
            clearRecentSearches: {
                savedRecentSearchQueries = ""
            },
            retryLoad: {
                Task {
                    await loadProducts(force: true)
                }
            },
            categorySelected: {
                shopCatalogueScrollRequest += 1
            }
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 28)
    }

    private var recentSearchQueries: [String] {
        savedRecentSearchQueries
            .split(separator: "|")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var quickSearches: [(title: String, query: String, categoryKey: String)] {
        [
            (AppLocalization.text("beans", fallback: "Beans"), "beans", "coffee-beans"),
            (AppLocalization.text("cold_drinks", fallback: "Cold Drinks"), "cold", "summer-drinks"),
            (AppLocalization.text("gifts", fallback: "Gifts"), "gift", "gifts"),
            (AppLocalization.text("crmb", fallback: "CRMB"), "crmb", "desserts"),
            (AppLocalization.text("equipment", fallback: "Equipment"), "brew", "coffee-equipment")
        ]
    }

    private func recordRecentSearch(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        var queries = recentSearchQueries.filter { $0.localizedCaseInsensitiveCompare(trimmedQuery) != .orderedSame }
        queries.insert(trimmedQuery, at: 0)
        savedRecentSearchQueries = queries.prefix(6).joined(separator: "|")
    }

    private var shopGuidancePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            coffeeQuizPanel
        }
    }

    private var coffeeQuizPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("coffee_quiz_title", fallback: "Find Your Talla"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.6)
                        .textCase(.uppercase)
                        .foregroundColor(primaryTextColor)

                    Text(AppLocalization.text("coffee_quiz_detail", fallback: "Answer three quick questions and discover your ideal coffee."))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        isCoffeeQuizExpanded.toggle()
                    }
                    delightFeedbackTrigger += 1
                } label: {
                    HStack(spacing: 6) {
                        Text(isCoffeeQuizExpanded
                            ? AppLocalization.text("collapse", fallback: "Close")
                            : AppLocalization.text("start_quiz", fallback: "Start"))
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                            .textCase(.uppercase)

                        Image(systemName: isCoffeeQuizExpanded ? "chevron.up" : "arrow.forward")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if isCoffeeQuizExpanded {
                quizOptionRow(
                    title: AppLocalization.text("coffee_quiz_brew_question", fallback: "How do you brew?"),
                    options: [
                        ("v60", "V60"),
                        ("espresso", "Espresso"),
                        ("aeropress", "AeroPress"),
                        ("arabic", "Arabic coffee")
                    ],
                    selection: $quizBrewMethod
                )
                .transition(.move(edge: .top).combined(with: .opacity))

                quizOptionRow(
                    title: AppLocalization.text("coffee_quiz_flavor_question", fallback: "What flavours do you enjoy?"),
                    options: [
                        ("chocolate", "Chocolate"),
                        ("fruity", "Fruity"),
                        ("floral", "Floral"),
                        ("caramel", "Caramel")
                    ],
                    selection: $quizFlavor
                )
                .transition(.move(edge: .top).combined(with: .opacity))

                quizOptionRow(
                    title: AppLocalization.text("coffee_quiz_adventure_question", fallback: "How adventurous are you?"),
                    options: [
                        ("comfort", "Keep it familiar"),
                        ("curious", "Curious"),
                        ("wild", "Surprise me")
                    ],
                    selection: $quizAdventure
                )
                .transition(.move(edge: .top).combined(with: .opacity))

                if let match = quizMatchedProduct {
                    quizResultCard(match)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Text(AppLocalization.text("coffee_quiz_loading", fallback: "Load the shop once and Talla will match you with a real coffee."))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
        }
        .padding(isCoffeeQuizExpanded ? 16 : 14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func quizOptionRow(
        title: String,
        options: [(id: String, title: String)],
        selection: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(labelFont(size: 9, weight: .bold))
                .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], spacing: 8) {
                ForEach(options.indices, id: \.self) { index in
                    let option = options[index]
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selection.wrappedValue = option.id
                        }
                    } label: {
                        Text(option.title)
                            .font(bodyFont(size: 13))
                            .foregroundColor(selection.wrappedValue == option.id ? Color(hex: 0x0A0804) : primaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(selection.wrappedValue == option.id ? Color(hex: 0xC8965A) : cardFillColor)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color(hex: 0xC8965A).opacity(selection.wrappedValue == option.id ? 0 : 0.18), lineWidth: 1)
                            )
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func quizResultCard(_ product: Product) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 12)
                .frame(width: 82, height: 98)

            VStack(alignment: .leading, spacing: 9) {
                Text(AppLocalization.text("coffee_quiz_match_label", fallback: "Your Talla Match"))
                    .font(labelFont(size: 9, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.3)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))

                Text(product.name)
                    .font(titleFont(size: 20))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(quizResultDescription(for: product))
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], spacing: 8) {
                    Button {
                        addToCart(product: product)
                    } label: {
                        Text(AppLocalization.text("add_to_bag", fallback: "Add to Bag"))
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(Color(hex: 0xC8965A))
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!product.isAvailableForSale || selectedVariant(for: product) == nil)

                    Button {
                        openShop(category: product.categoryKey)
                    } label: {
                        Text(AppLocalization.text("see_alternatives", fallback: "See Alternatives"))
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                            .textCase(.uppercase)
                            .foregroundColor(primaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(cardFillColor)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                            )
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        openBrewing()
                    } label: {
                        Text(AppLocalization.text("start_brewing", fallback: "Start Brew"))
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                            .textCase(.uppercase)
                            .foregroundColor(primaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(cardFillColor)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                            )
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.09 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var quizMatchedProduct: Product? {
        quizCandidateProducts.max { lhs, rhs in
            quizScore(for: lhs) < quizScore(for: rhs)
        }
    }

    private var quizCandidateProducts: [Product] {
        let candidates = products.filter {
            $0.categoryKey == "coffee-beans" || $0.categoryKey == "arabic-coffee-beans"
        }

        return candidates.isEmpty ? signatureRoastProducts : candidates
    }

    private func quizScore(for product: Product) -> Int {
        let text = "\(product.name) \(product.desc) \(product.categoryLabel)".lowercased()
        var score = 0

        switch quizBrewMethod {
        case "v60":
            score += quizTextScore(text, keywords: ["v60", "filter", "pour", "ethiopia", "guji", "washed", "floral", "berry"])
        case "espresso":
            score += quizTextScore(text, keywords: ["espresso", "brazil", "colombia", "chocolate", "caramel", "nut", "body"])
        case "aeropress":
            score += quizTextScore(text, keywords: ["aeropress", "filter", "balanced", "colombia", "sweet", "clean"])
        case "arabic":
            score += quizTextScore(text, keywords: ["arabic", "shamali", "qahwa", "gahwa", "cardamom", "yemen"])
        default:
            break
        }

        switch quizFlavor {
        case "chocolate":
            score += quizTextScore(text, keywords: ["chocolate", "cocoa", "nut", "brazil", "espresso"])
        case "fruity":
            score += quizTextScore(text, keywords: ["fruit", "fruity", "berry", "citrus", "ethiopia", "guji"])
        case "floral":
            score += quizTextScore(text, keywords: ["floral", "jasmine", "tea", "washed", "ethiopia", "guji"])
        case "caramel":
            score += quizTextScore(text, keywords: ["caramel", "toffee", "brown sugar", "sweet", "colombia"])
        default:
            break
        }

        switch quizAdventure {
        case "comfort":
            score += quizTextScore(text, keywords: ["brazil", "colombia", "classic", "balanced", "chocolate"])
        case "curious":
            score += quizTextScore(text, keywords: ["ethiopia", "colombia", "washed", "single-origin", "sweet"])
        case "wild":
            score += quizTextScore(text, keywords: ["guji", "ethiopia", "natural", "anaerobic", "floral", "berry"])
        default:
            break
        }

        if product.isAvailableForSale {
            score += 3
        }

        return score
    }

    private func quizTextScore(_ text: String, keywords: [String]) -> Int {
        keywords.reduce(0) { partialResult, keyword in
            partialResult + (text.contains(keyword) ? 4 : 0)
        }
    }

    private func quizResultDescription(for product: Product) -> String {
        let flavorText: String
        switch quizFlavor {
        case "chocolate":
            flavorText = "Chocolate-led, rounded and easy to love"
        case "floral":
            flavorText = "Floral, aromatic and elegant"
        case "caramel":
            flavorText = "Sweet, caramel-like and comforting"
        default:
            flavorText = "Fruity, bright and expressive"
        }

        let brewText: String
        switch quizBrewMethod {
        case "espresso":
            brewText = "espresso"
        case "aeropress":
            brewText = "AeroPress"
        case "arabic":
            brewText = "Arabic coffee"
        default:
            brewText = "V60"
        }

        return "\(flavorText), and a strong fit for \(brewText)."
    }

    private var coffeeConciergeSheet: some View {
        ScrollView {
            coffeeConciergePanel
                .padding(18)
        }
        .background(
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .presentationDetents([.medium, .large])
    }

    private var coffeeConciergePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(AppLocalization.text("coffee_concierge_title", fallback: "Coffee Concierge"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.5)
                        .textCase(.uppercase)
                        .foregroundColor(primaryTextColor)

                    Text(AppLocalization.text("coffee_concierge_detail", fallback: "Ask for a roast, gift, mood, budget, or brew style and get focused Talla picks."))
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                TextField(AppLocalization.text("coffee_concierge_placeholder", fallback: "Example: gift under 20 BHD"), text: $conciergeRequest)
                    .font(bodyFont(size: 13))
                    .foregroundColor(primaryTextColor)
                    .textInputAutocapitalization(.sentences)
                    .submitLabel(.done)
                    .onSubmit {
                        Task { await runCoffeeConcierge() }
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 8)
                    .background(cardFillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    Task { await runCoffeeConcierge() }
                } label: {
                    Image(systemName: isRunningConcierge ? "hourglass" : "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(width: 38, height: 38)
                        .background(Color(hex: 0xC8965A))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isRunningConcierge || products.isEmpty)
            }

#if canImport(PhotosUI)
            HStack(alignment: .center, spacing: 10) {
                PhotosPicker(selection: $conciergeImageSelection, matching: .images, photoLibrary: .shared()) {
                    Label(
                        conciergeImageData == nil
                            ? AppLocalization.text("add_image", fallback: "Add Image")
                            : AppLocalization.text("change_image", fallback: "Change Image"),
                        systemImage: "photo.badge.plus"
                    )
                    .font(labelFont(size: 9, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(cardFillColor)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)

                if isLoadingConciergeImage {
                    ProgressView()
                        .tint(Color(hex: 0xC8965A))
                } else if conciergeImageData != nil {
                    conciergeImagePreview

                    Button {
                        conciergeImageSelection = nil
                        conciergeImageData = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(secondaryTextColor)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("remove_image", fallback: "Remove image"))
                }

                Spacer(minLength: 0)
            }
#endif

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    conciergePromptChip(AppLocalization.text("concierge_prompt_gift", fallback: "Gift box"))
                    conciergePromptChip(AppLocalization.text("concierge_prompt_arabic", fallback: "Arabic coffee"))
                    conciergePromptChip(AppLocalization.text("concierge_prompt_chocolate", fallback: "Chocolate pairing"))
                    conciergePromptChip(AppLocalization.text("concierge_prompt_tools", fallback: "Brew tools"))
                }
            }

            if let conciergeResult {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Text(conciergeResult.usedAppleIntelligence
                            ? AppLocalization.text("apple_intelligence_used", fallback: "Apple Intelligence")
                            : AppLocalization.text("smart_fallback_used", fallback: "Smart picks"))
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.4)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0xC8965A))

                        Spacer(minLength: 0)
                    }

                    Text(conciergeResult.message)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    if !conciergeProducts.isEmpty {
                        LazyVGrid(columns: productGridColumns, spacing: 14) {
                            ForEach(conciergeProducts) { product in
                                productCard(product: product, showDescription: false)
                            }
                        }
                    }
                }
                .padding(14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(elevatedSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

#if canImport(PhotosUI)
    @ViewBuilder
    private var conciergeImagePreview: some View {
#if canImport(UIKit)
        if let conciergeImageData, let image = UIImage(data: conciergeImageData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.22 : 0.12), lineWidth: 1)
                )
                .accessibilityLabel(AppLocalization.text("selected_image", fallback: "Selected image"))
        }
#else
        Image(systemName: "photo.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Color(hex: 0xC8965A))
            .frame(width: 42, height: 42)
            .background(cardFillColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
#endif
    }
#endif

    private func conciergePromptChip(_ title: String) -> some View {
        Button {
            conciergeRequest = title
            Task { await runCoffeeConcierge(requestOverride: title) }
        } label: {
            Text(title)
                .font(labelFont(size: 9, weight: .bold))
                .lineLimit(1)
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(cardFillColor)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRunningConcierge || products.isEmpty)
    }

#if canImport(PhotosUI)
    @MainActor
    private func loadConciergeImage(from selection: PhotosPickerItem?) async {
        guard let selection else {
            conciergeImageData = nil
            isLoadingConciergeImage = false
            return
        }

        isLoadingConciergeImage = true
        defer { isLoadingConciergeImage = false }

        do {
            conciergeImageData = try await selection.loadTransferable(type: Data.self)
        } catch {
            conciergeImageData = nil
            showToast(message: AppLocalization.text("image_load_failed", fallback: "Could not load that image"))
        }
    }
#endif

    @MainActor
    private func runCoffeeConcierge(requestOverride: String? = nil) async {
        guard !isRunningConcierge else { return }
        guard !products.isEmpty else {
            showToast(message: AppLocalization.text("loading_shop", fallback: "Loading the shop"))
            return
        }

        isRunningConcierge = true
        let request = requestOverride ?? conciergeRequest
        let result = await CoffeeConciergeService.recommend(
            request: request,
            products: products,
            localeIdentifier: appLanguage.localeIdentifier,
            imageData: conciergeImageData
        )
        conciergeRequest = request
        conciergeResult = result
        delightFeedbackTrigger += 1
        isRunningConcierge = false
    }

    private var brewingView: some View {
        BrewingSectionView(
            isCompact: isCompact,
            isCustomerSignedIn: customerProfile != nil,
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
            brewHistoryItems: brewAgainHistoryItems,
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
            guidedBrewCompletedAction: { method, coffeeAmount, ratio, waterAmount, brewTime in
                prepareJournalEntryFromGuidedBrew(
                    method: method,
                    coffeeAmount: coffeeAmount,
                    ratio: ratio,
                    waterAmount: waterAmount,
                    brewTime: brewTime
                )
            },
            brewTimerSection: AnyView(brewTimerSection),
            coffeeJournalSection: AnyView(coffeeJournalSection),
            loadingView: AnyView(loadingSection)
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 28)
    }

    private var brewTimerPresets: [(name: String, seconds: Int, symbol: String)] {
        [
            ("Pour Over", 210, "drop.fill"),
            ("French Press", 240, "cup.and.saucer.fill"),
            ("Arabic Coffee", 480, "flame.fill"),
            ("Cold Brew", 43_200, "snowflake")
        ]
    }

    private var brewTimerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(AppLocalization.text("brew_timer", fallback: "Brew Timer"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Text(AppLocalization.text("brew_timer_detail", fallback: "Start a focused timer for the brew you are making now."))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(alignment: .center, spacing: 12) {
                Text(formattedTimerTime(brewTimerRemainingSeconds))
                    .font(displayFont(size: isCompact ? 42 : 52))
                    .monospacedDigit()
                    .foregroundColor(primaryTextColor)
                    .contentTransition(.numericText())

                Spacer(minLength: 0)

                Button {
                    resetBrewTimer()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 44, height: 44)
                        .background(cardFillColor)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("reset_timer", fallback: "Reset timer"))
            }

            Text(brewTimerCueText)
                .font(labelFont(size: 11, weight: .bold))
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .contentTransition(.opacity)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.10))

                    Capsule(style: .continuous)
                        .fill(Color(hex: 0xC8965A))
                        .frame(width: max(proxy.size.width * brewTimerFraction, isBrewTimerRunning ? 10 : 0))
                        .animation(.linear(duration: 0.2), value: brewTimerRemainingSeconds)
                }
            }
            .frame(height: 9)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], spacing: 8) {
                ForEach(brewTimerPresets, id: \.name) { preset in
                    brewTimerPresetButton(preset)
                }
            }

            HStack(spacing: 10) {
                Button {
                    if isBrewTimerRunning {
                        isBrewTimerRunning = false
                    } else {
                        startBrewTimer()
                    }
                } label: {
                    Label(brewTimerPrimaryActionTitle, systemImage: isBrewTimerRunning ? "pause.fill" : "play.fill")
                        .font(labelFont(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: 0xC8965A))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var coffeeJournalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "book.pages.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0xC8965A))
                    .frame(width: 38, height: 38)
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(AppLocalization.text("coffee_journal", fallback: "Coffee Journal"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Text(AppLocalization.text("coffee_journal_detail", fallback: "Save what worked: method, rating, and a note for your next cup."))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            TextField(AppLocalization.text("journal_title", fallback: "Coffee or recipe name"), text: $journalTitleInput)
                .textInputAutocapitalization(.words)
                .font(bodyFont(size: 14))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(elevatedSurfaceColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            TextField(AppLocalization.text("method", fallback: "Method"), text: $journalMethodInput)
                .textInputAutocapitalization(.words)
                .font(bodyFont(size: 14))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(elevatedSurfaceColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if let journalBrewDetailLine {
                Text(journalBrewDetailLine)
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { rating in
                    Button {
                        journalRating = rating
                        delightFeedbackTrigger += 1
                    } label: {
                        Image(systemName: rating <= journalRating ? "star.fill" : "star")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(Color(hex: 0xC8965A))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(rating) \(AppLocalization.text("stars", fallback: "stars"))")
                }

                Spacer(minLength: 0)
            }

            TextField(AppLocalization.text("tasting_notes", fallback: "Tasting notes"), text: $journalNotesInput, axis: .vertical)
                .lineLimit(2...4)
                .textInputAutocapitalization(.sentences)
                .font(bodyFont(size: 14))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(elevatedSurfaceColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Button {
                saveCoffeeJournalEntry()
            } label: {
                Text(AppLocalization.text("save_journal_entry", fallback: "Save Journal Entry"))
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

            if !brewJournalEntries.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalization.text("recent_notes", fallback: "Recent Notes"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    ForEach(brewJournalEntries.prefix(3)) { entry in
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(entry.title)
                                    .font(titleFont(size: 17))
                                    .foregroundColor(primaryTextColor)

                                Text("\(entry.method) • \(entry.rating)/5")
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(1.2)
                                    .textCase(.uppercase)
                                    .foregroundColor(Color(hex: 0xC8965A))

                                if let detail = brewJournalDetailLine(for: entry) {
                                    Text(detail)
                                        .font(labelFont(size: 9, weight: .bold))
                                        .tracking(0.9)
                                        .textCase(.uppercase)
                                        .foregroundColor(tertiaryTextColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                if !entry.notes.isEmpty {
                                    Text(entry.notes)
                                        .font(bodyFont(size: 13))
                                        .foregroundColor(secondaryTextColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }

                            Spacer(minLength: 0)

                            Button {
                                deleteCoffeeJournalEntry(entry)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(primaryTextColor)
                                    .frame(width: 32, height: 32)
                                    .background(cardFillColor)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .background(elevatedSurfaceColor)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func brewTimerPresetButton(_ preset: (name: String, seconds: Int, symbol: String)) -> some View {
        let isSelected = selectedBrewTimerName == preset.name

        return Button {
            selectedBrewTimerName = preset.name
            selectedBrewTimerSeconds = preset.seconds
            brewTimerRemainingSeconds = preset.seconds
            isBrewTimerRunning = false
            journalMethodInput = preset.name
        } label: {
            Label(preset.name, systemImage: preset.symbol)
                .font(labelFont(size: 10, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(isSelected ? Color(hex: 0xC8965A) : elevatedSurfaceColor)
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var latestAccountOrderSummary: (title: String, detail: String)? {
        guard let order = orderHistory.max(by: { orderDate(from: $0.createdAt) < orderDate(from: $1.createdAt) }) else {
            return nil
        }

        let digits = [order.title, order.id]
            .map { $0.filter(\.isNumber) }
            .first(where: { !$0.isEmpty }) ?? String(order.id.prefix(6))
        let orderNumber = String(format: AppLocalization.text("order_number_format", fallback: "Order #%@"), String(digits.suffix(6)))
        let daysAgo = daysSinceOrder(order)
        let timing = daysAgo == 0
            ? AppLocalization.text("ordered_today", fallback: "Ordered today")
            : String(format: AppLocalization.text("last_ordered_days_ago", fallback: "Last ordered %d days ago"), daysAgo)

        return (orderNumber, "\(order.total) · \(timing)")
    }

    private var recentlySavedAccountSummary: (title: String, detail: String)? {
        guard let product = favoriteProducts.first else {
            return nil
        }

        return (customerFacingProductName(for: product), product.price)
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
            isCustomerSignedIn: customerProfile != nil,
            accountDisplayName: customerProfile?.displayName ?? AppLocalization.text("guest_account_name", fallback: "Talla Speciality"),
            accountEmail: customerProfile?.email ?? savedCustomerEmail,
            membershipTier: loyaltyAccount?.tier ?? AppLocalization.text("bronze", fallback: "Bronze"),
            beansBalance: loyaltyAccount?.pointsBalance ?? 0,
            beansUntilNextReward: loyaltyAccount.map { rewardProgress(for: $0.pointsBalance).remaining } ?? 50,
            orderCount: orderHistory.count,
            addressesCount: addresses.count,
            favoriteCount: favoriteProducts.count,
            brewRecipeCount: brewRecipes.count,
            journalEntryCount: brewJournalEntries.count,
            latestOrderTitle: latestAccountOrderSummary?.title,
            latestOrderDetail: latestAccountOrderSummary?.detail,
            recentlySavedTitle: recentlySavedAccountSummary?.title,
            recentlySavedDetail: recentlySavedAccountSummary?.detail,
            isCustomerSectionExpanded: $isCustomerSectionExpanded,
            isLoyaltySectionExpanded: $isLoyaltySectionExpanded,
            isLibrarySectionExpanded: $isLibrarySectionExpanded,
            isShoppingSectionExpanded: $isShoppingSectionExpanded,
            isBrewingSectionExpanded: $isBrewingSectionExpanded,
            isSupportSectionExpanded: $isSupportSectionExpanded,
            openOrdersAction: {
                openAccountSection(AccountSectionView.ScrollTarget.customer)
                Task {
                    await loadOrderHistory()
                }
                showToast(message: AppLocalization.text("orders_opened", fallback: "Orders opened"))
            },
            openRewardsAction: {
                openAccountSection(AccountSectionView.ScrollTarget.loyalty)
                showToast(message: AppLocalization.text("rewards_opened", fallback: "Rewards opened"))
            },
            openDeliveryAction: {
                isDeliveryDetailsExpanded = true
                openAccountSection(AccountSectionView.ScrollTarget.library)
                showToast(message: AppLocalization.text("delivery_opened", fallback: "Delivery opened"))
            },
            openSavedPicksAction: {
                openAccountSection(AccountSectionView.ScrollTarget.shopping)
                showToast(message: AppLocalization.text("saved_opened", fallback: "Saved picks opened"))
            },
            openBrewArchiveAction: {
                openBrewing()
                showToast(message: AppLocalization.text("brewing_archive_opened", fallback: "Brewing archive opened"))
            },
            openSupportAction: {
                openAccountSection(AccountSectionView.ScrollTarget.support)
                showToast(message: AppLocalization.text("support_opened", fallback: "Support opened"))
            },
            signOutAction: {
                signOutCustomer()
            },
            customerAccountSection: AnyView(customerAccountSection),
            personalDetailsSection: AnyView(profileManagementSection),
            passwordSection: AnyView(passwordResetSection),
            ordersSection: AnyView(orderHistorySection),
            loyaltySection: AnyView(loyaltySection),
            addressesSection: AnyView(addressesSection),
            savedCartsSection: AnyView(savedCartsSection),
            alertsSection: AnyView(alertsSection),
            favoritesSection: AnyView(favoritesSection),
            recentlyViewedSection: AnyView(recentlyViewedSection),
            savedRecipesSection: AnyView(brewRecipesSection),
            journalSection: AnyView(coffeeJournalSection),
            supportSection: AnyView(settingsAndHelpSection)
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 28)
    }

    private var languagePreferenceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0xC8965A))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("language", fallback: "Language"))
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(primaryTextColor)

                    Text(AppLocalization.text("language_preference_detail", fallback: "Choose how the app labels and layout appear."))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                ForEach(AppLanguage.allCases) { language in
                    languageOptionButton(language)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var settingsAndHelpSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalization.text("settings_and_help", fallback: "SETTINGS & HELP"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            VStack(spacing: 0) {
                settingsRow(
                    title: AppLocalization.text("language", fallback: "Language"),
                    value: currentLanguageTitle,
                    systemImage: "globe"
                ) {
                    selectedSettingsDetail = .language
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("notifications", fallback: "Notifications"),
                    value: notificationsEnabled
                        ? AppLocalization.text("on", fallback: "On")
                        : AppLocalization.text("off", fallback: "Off"),
                    systemImage: "bell.fill"
                ) {
                    selectedSettingsDetail = .notifications
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("whatsapp_support", fallback: "WhatsApp Support"),
                    systemImage: "message.fill"
                ) {
                    openURL(URL(string: "https://wa.me/97339392414")!)
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("about_talla", fallback: "About Talla"),
                    systemImage: "info.circle.fill"
                ) {
                    selectedSettingsDetail = .aboutTalla
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("privacy_policy", fallback: "Privacy Policy"),
                    systemImage: "hand.raised.fill"
                ) {
                    openURL(URL(string: "https://duneroastery.myshopify.com/policies/privacy-policy")!)
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("terms_and_conditions", fallback: "Terms and Conditions"),
                    systemImage: "doc.text.fill"
                ) {
                    openURL(URL(string: "https://duneroastery.myshopify.com/policies/terms-of-service")!)
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("delete_account", fallback: "Delete Account"),
                    systemImage: "trash.fill",
                    isDestructive: true
                ) {
                    selectedSettingsDetail = .deleteAccount
                }
            }
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .sheet(item: $selectedSettingsDetail) { detail in
            settingsDetailScreen(detail)
        }
    }

    private var currentLanguageTitle: String {
        (AppLanguage(rawValue: savedAppLanguage) ?? .system).title
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.06))
            .frame(height: 1)
            .padding(.leading, 54)
    }

    private func settingsRow(
        title: String,
        value: String? = nil,
        systemImage: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isDestructive ? .red : Color(hex: 0xC8965A))
                    .frame(width: 34, height: 34)
                    .background((isDestructive ? Color.red : Color(hex: 0xC8965A)).opacity(isLightAppearance ? 0.10 : 0.14))
                    .clipShape(Circle())

                Text(title)
                    .font(labelFont(size: 12, weight: .bold))
                    .foregroundColor(isDestructive ? .red : primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 8)

                if let value {
                    Text(value)
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tertiaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func settingsDetailScreen(_ detail: SettingsDetail) -> some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                settingsDetailContent(detail)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(isLightAppearance ? Color(hex: 0xFFFDF9) : Color(hex: 0x181411))
            .navigationTitle(settingsDetailTitle(detail))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedSettingsDetail = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 32, height: 32)
                            .background(cardFillColor)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))
                }
            }
        }
    }

    private func settingsDetailTitle(_ detail: SettingsDetail) -> String {
        switch detail {
        case .language:
            return AppLocalization.text("language", fallback: "Language")
        case .notifications:
            return AppLocalization.text("notifications", fallback: "Notifications")
        case .aboutTalla:
            return AppLocalization.text("about_talla", fallback: "About Talla")
        case .deleteAccount:
            return AppLocalization.text("delete_account", fallback: "Delete Account")
        }
    }

    @ViewBuilder
    private func settingsDetailContent(_ detail: SettingsDetail) -> some View {
        switch detail {
        case .language:
            languagePreferenceCard
        case .notifications:
            notificationSettingsCard
        case .aboutTalla:
            accountStatusTile(
                title: AppLocalization.text("about_talla", fallback: "About Talla"),
                detail: AppLocalization.text("about_talla_detail", fallback: "Speciality coffee, rewards, and roastery essentials built around daily rituals in Bahrain.")
            )
        case .deleteAccount:
            deleteAccountSettingsCard
        }
    }

    private var notificationSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(notificationStatusMessage)
                .font(bodyFont(size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Task {
                    await requestNotificationAccess()
                }
            } label: {
                Text(notificationsEnabled
                    ? AppLocalization.text("notifications_enabled", fallback: "Notifications enabled")
                    : AppLocalization.text("enable_notifications", fallback: "Enable Notifications"))
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canRequestNotificationAccess)
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var deleteAccountSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalization.text("delete_account_detail", fallback: "To delete your Talla account and associated app data, contact support and we will help complete the request."))
                .font(bodyFont(size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                openURL(URL(string: "https://wa.me/97339392414")!)
            } label: {
                Text(AppLocalization.text("contact_support", fallback: "Contact Support"))
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.86))
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.red.opacity(isLightAppearance ? 0.18 : 0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func languageOptionButton(_ language: AppLanguage) -> some View {
        let isSelected = (AppLanguage(rawValue: savedAppLanguage) ?? .system) == language

        return Button {
            savedAppLanguage = language.rawValue
        } label: {
            Text(language.title)
                .font(labelFont(size: 10, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: 0xC8965A) : cardFillColor)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isSelected ? 0 : 0.18), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
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

    private func actionEmptyState(
        message: String,
        actionTitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0xC8965A))
                    .frame(width: 34, height: 34)
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                Text(message)
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: action) {
                Text(actionTitle)
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule())
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
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("favorites", fallback: "FAVORITES"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if favoriteProducts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("favorites_empty", fallback: "Tap the heart on any coffee or gift to save it here."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "heart.fill"
                ) {
                    openShop()
                }
            } else {
                accountCompactProductSection(
                    products: Array(favoriteProducts.prefix(3)),
                    viewAllTitle: AppLocalization.text("view_all_saved_products", fallback: "View all saved products")
                )
            }
        }
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("recommended_for_you", fallback: "RECOMMENDED FOR YOU"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if recommendedProducts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("recommendations_empty", fallback: "Recommendations will appear here once products are loaded."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "sparkles"
                ) {
                    openShop()
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalization.text("recommendations_detail", fallback: "Picked from the coffees, tools, and categories you keep coming back to."))
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
            Text(AppLocalization.text("back_in_stock_reminders", fallback: "BACK IN STOCK REMINDERS"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if alertProducts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("alerts_empty", fallback: "Tap the bell on sold-out or watched items to know when they return."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "bell.fill"
                ) {
                    openShop()
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(AppLocalization.text("alerts_detail", fallback: "Track upcoming drops and get back to the coffees you do not want to miss."))
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    if !alertInbox.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(AppLocalization.text("recent_alert_updates", fallback: "Recent Alert Updates"))
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

    private var deliveryCountrySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("delivery_country", fallback: "Delivery country"))
                .font(labelFont(size: 10, weight: .bold))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SupportedDeliveryCountry.allCases) { country in
                        let isSelected = country == addressCountry

                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                addressCountry = country
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(country.flag)
                                    .font(labelFont(size: 10, weight: .bold))
                                    .foregroundColor(isSelected ? Color(hex: 0x0A0804) : Color(hex: 0xC8965A))
                                    .frame(width: 28, height: 28)
                                    .background(isSelected ? Color(hex: 0xF7E4C2) : Color(hex: 0xC8965A).opacity(0.12))
                                    .clipShape(Circle())

                                Text(country.name)
                                    .font(labelFont(size: 11, weight: .bold))
                                    .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(isSelected ? Color(hex: 0xC8965A) : cardFillColor)
                            .overlay(
                                Capsule()
                                    .stroke(Color(hex: 0xC8965A).opacity(isSelected ? 0 : 0.18), lineWidth: 1)
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
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
                        Text(AppLocalization.text("delivery_details", fallback: "DELIVERY DETAILS"))
                            .font(displayFont(size: 22))
                            .tracking(2)
                            .foregroundColor(primaryTextColor)

                        Text(addresses.isEmpty
                            ? AppLocalization.text("delivery_details_empty", fallback: "Add an address for faster checkout.")
                            : (addresses.count == 1
                                ? AppLocalization.text("delivery_details_ready_one", fallback: "1 saved address ready.")
                                : String(format: AppLocalization.text("delivery_details_ready_many", fallback: "%d saved addresses ready."), addresses.count)))
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
                    Text(AppLocalization.text("delivery_details_hint", fallback: "Save your preferred address here so checkout feels faster, even when Shopify opens on the web."))
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    TextField(AppLocalization.text("label", fallback: "Label"), text: $addressLabel)
                        .textInputAutocapitalization(.words)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(cardFillColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    TextField(AppLocalization.text("full_name", fallback: "Full name"), text: $addressFullName)
                        .textInputAutocapitalization(.words)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(cardFillColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    HStack(spacing: 8) {
                        Text(addressCountry.phonePrefix)
                            .font(labelFont(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: 0xC8965A))
                            .frame(minWidth: 42, alignment: .leading)

                        TextField(AppLocalization.text("phone", fallback: "Phone"), text: $addressPhone)
                            .keyboardType(.phonePad)
                            .font(bodyFont(size: 14))
                            .foregroundColor(primaryTextColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(cardFillColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    TextField(AppLocalization.text("address_line", fallback: "Address line"), text: $addressLine1)
                        .textInputAutocapitalization(.words)
                        .font(bodyFont(size: 14))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(cardFillColor)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    deliveryCountrySelector

                    HStack(spacing: 10) {
                        TextField(AppLocalization.text("city", fallback: "City"), text: $addressCity)
                            .textInputAutocapitalization(.words)
                            .font(bodyFont(size: 14))
                            .foregroundColor(primaryTextColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(cardFillColor)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                        TextField(AppLocalization.text("notes", fallback: "Notes"), text: $addressNotes)
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
                        Text(isSavingAddress
                            ? AppLocalization.text("saving", fallback: "Saving...")
                            : AppLocalization.text("save_address", fallback: "Save Address"))
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
                    actionEmptyState(
                        message: AppLocalization.text("no_saved_addresses", fallback: "No saved addresses yet."),
                        actionTitle: AppLocalization.text("add_address", fallback: "Add Address"),
                        systemImage: "location.fill"
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDeliveryDetailsExpanded = true
                        }
                    }
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
                                Text("\(address.line1), \(address.city), \(address.country.name)")
                                    .font(bodyFont(size: 13))
                                    .foregroundColor(secondaryTextColor)
                                if let notes = address.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(bodyFont(size: 12))
                                        .foregroundColor(tertiaryTextColor)
                                }
                                if address.isPreferred {
                                    Text(AppLocalization.text("preferred", fallback: "Preferred"))
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
            Text(AppLocalization.text("saved_brew_recipes", fallback: "SAVED BREW RECIPES"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if brewRecipes.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("saved_brew_recipes_empty", fallback: "Save your favorite coffee-to-water ratios from the brew tab and they will appear here."),
                    actionTitle: AppLocalization.text("open_brewing", fallback: "Open Brewing"),
                    systemImage: "book.closed.fill"
                ) {
                    openBrewing()
                }
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
                                    Text(AppLocalization.text("apply", fallback: "Apply"))
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
            Text(AppLocalization.text("saved_carts", fallback: "SAVED BAGS"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if savedCarts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("saved_carts_empty", fallback: "Save a filled bag and come back to it whenever you are ready to check out."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "cart.fill"
                ) {
                    openShop()
                }
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
                                    Text(AppLocalization.text("load", fallback: "Load"))
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
            Text(AppLocalization.text("recently_viewed", fallback: "RECENTLY VIEWED"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if recentlyViewedProducts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("recently_viewed_empty", fallback: "Products you open, save, or add to bag will appear here for quick return visits."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "clock.fill"
                ) {
                    openShop()
                }
            } else {
                accountCompactProductSection(
                    products: Array(recentlyViewedProducts.prefix(3)),
                    viewAllTitle: AppLocalization.text("view_all_recent_products", fallback: "View all recent products")
                )
            }
        }
    }

    private func accountCompactProductSection(products: [Product], viewAllTitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(products) { product in
                        accountCompactProductCard(product)
                    }
                }
                .padding(.vertical, 2)
            }

            Button {
                openShop()
            } label: {
                HStack(spacing: 8) {
                    Text(viewAllTitle)
                    Image(systemName: "arrow.right")
                }
                .font(labelFont(size: 11, weight: .bold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    private func accountCompactProductCard(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                recordRecentlyViewed(product)
                selectedProduct = product
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    ProductThumbnail(imageURL: product.imageURL, size: 58, cornerRadius: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(customerFacingProductName(for: product))
                            .font(titleFont(size: 17))
                            .foregroundColor(primaryTextColor)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)

                        Text(accountCompactProductMeta(for: product))
                            .font(bodyFont(size: 12))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                if product.hasVariantChoices {
                    recordRecentlyViewed(product)
                    selectedProduct = product
                } else {
                    addToCart(product: product)
                }
            } label: {
                Text(product.hasVariantChoices
                    ? AppLocalization.text("options", fallback: "Options")
                    : AppLocalization.text("add", fallback: "Add"))
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 230, alignment: .topLeading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func accountCompactProductMeta(for product: Product) -> String {
        let variant = accountCompactVariantLabel(for: product)
        guard !variant.isEmpty else {
            return product.price
        }

        return "\(product.price) · \(variant)"
    }

    private func accountCompactVariantLabel(for product: Product) -> String {
        guard let title = product.defaultVariant?.title.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty,
              title.lowercased() != "default title",
              title.lowercased() != "default" else {
            return ""
        }

        return title
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
        VStack(spacing: 7) {
            Text("Talla Speciality")
                .font(.custom("ChalkboardSE-Bold", size: isCompact ? 27 : 30, relativeTo: .title2))
                .tracking(1.1)
                .foregroundColor(Color(hex: 0xB98243))
                .lineLimit(1)

            HStack(spacing: 7) {
                Text("🇧🇭")
                    .font(.system(size: 12))
                    .accessibilityHidden(true)

                Text(AppLocalization.text("made_in_bahrain", fallback: "Made in Bahrain"))
                    .font(.custom("ChalkboardSE-Regular", size: 10, relativeTo: .caption))
                    .tracking(1.3)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xA67236))
            }
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(
            Rectangle()
                .fill(Color(hex: 0xC8965A).opacity(0.12))
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
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalization.text("your_bag_is_empty", fallback: "Your bag is empty."))
                .font(titleFont(size: 22))
                .foregroundColor(primaryTextColor)

            Text(AppLocalization.text("cart_empty_guidance", fallback: "Start with coffee, tools, or gifts. Your selected items will appear here before checkout."))
                .font(bodyFont(size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                cartOpen = false
                openShop()
            } label: {
                Text(AppLocalization.text("browse_products", fallback: "Browse Products"))
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var cartReviewContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            cartItemsListSection
            cartPaymentMethodsSection

            VStack(alignment: .leading, spacing: 10) {
                Text(checkoutReadinessTitle)
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))

                Text(checkoutReadinessSummary)
                    .font(bodyFont(size: 14))
                    .foregroundColor(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                if let appliedVoucher {
                    Text(String(format: AppLocalization.text("voucher_applied_summary", fallback: "Voucher %@ applied"), appliedVoucher.code))
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                if preferredAddress == nil {
                    Button {
                        cartOpen = false
                        isDeliveryDetailsExpanded = true
                        openAccountSection(AccountSectionView.ScrollTarget.library)
                    } label: {
                        Label(AppLocalization.text("add_delivery_address", fallback: "Add Delivery Address"), systemImage: appLanguage.layoutDirection == .rightToLeft ? "arrow.left" : "arrow.right")
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(1.3)
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

            cartRewardsSection
            cartOrderSummarySection
            cartSaveSection
            cartOrderingGuideSection
        }
    }

    private var cartOrderingGuideSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isCheckoutNoteExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text(AppLocalization.text("how_checkout_works", fallback: "How checkout works"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Spacer()

                    Image(systemName: isCheckoutNoteExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0xC8965A))
                }
            }
            .buttonStyle(.plain)

            if isCheckoutNoteExpanded {
                Text(AppLocalization.text("checkout_note_detail", fallback: "Payment is completed securely through Shopify. Return to Talla afterwards to track your order and receive Beans."))
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
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
    }

    private var cartFooterContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let checkoutError {
                Text(checkoutError)
                    .font(bodyFont(size: 13))
                    .foregroundColor(Color.red.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if preferredAddress == nil {
                Button {
                    checkoutError = nil
                    cartOpen = false
                    isDeliveryDetailsExpanded = true
                    openAccountSection(AccountSectionView.ScrollTarget.library)
                } label: {
                    HStack {
                        Text(AppLocalization.text("add_address_to_continue", fallback: "Add address to continue"))
                            .font(.headline)
                        Spacer()
                        Image(systemName: appLanguage.layoutDirection == .rightToLeft ? "arrow.left" : "arrow.right")
                    }
                    .foregroundStyle(Color(hex: 0x0A0804))
                    .padding(.horizontal, 17)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color(hex: 0xC8965A), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("add_address_to_continue", fallback: "Add address to continue"))
            } else {
                CheckoutActionBar(
                    method: paymentFlow.selectedMethod,
                    amountText: formattedBHD(cartTotal),
                    state: paymentFlow.state,
                    enabled: !cartItems.isEmpty && !isCheckingOut && paymentFlow.canStart,
                    applePayAvailable: isApplePayAvailable,
                    accentColor: Color(hex: 0xC8965A)
                ) {
                    checkoutError = nil
                    Task {
                        await beginCheckout()
                    }
                }
            }
        }
    }

    private var cartOrderSummarySection: some View {
        let itemKey = cartCount == 1 ? "cart_item_count_singular" : "cart_item_count_plural"
        let itemFallback = cartCount == 1 ? "%d item" : "%d items"
        let thumbnail: AnyView = {
            if let firstItem = cartItems.first {
                return AnyView(ProductThumbnail(imageURL: firstItem.product.imageURL, size: 44, cornerRadius: 10))
            }
            return AnyView(
                Image(systemName: "bag.fill")
                    .foregroundStyle(Color(hex: 0xC8965A))
                    .frame(width: 44, height: 44)
                    .background(Color(hex: 0xC8965A).opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            )
        }()
        return CompactOrderSummary(
            thumbnail: thumbnail,
            itemCountText: String(format: AppLocalization.text(itemKey, fallback: itemFallback), cartCount),
            rows: [
                (AppLocalization.text("subtotal", fallback: "Subtotal"), formattedBHD(cartSubtotal), false),
                (AppLocalization.text("delivery", fallback: "Delivery"), AppLocalization.text("calculated_at_checkout", fallback: "Calculated at checkout"), false),
                (AppLocalization.text("discount", fallback: "Discount"), cartDiscount > 0 ? "-\(formattedBHD(cartDiscount))" : AppLocalization.text("none_dash", fallback: "—"), false),
                (AppLocalization.text("total", fallback: "Total"), formattedBHD(cartTotal), true)
            ],
            primaryColor: primaryTextColor,
            secondaryColor: secondaryTextColor,
            accentColor: Color(hex: 0xC8965A),
            surfaceColor: cardFillColor
        )
    }

    private var cartPaymentMethodsSection: some View {
        VStack(spacing: 10) {
            CompactPaymentMethodRow(
                selectedMethod: paymentFlow.selectedMethod,
                enabled: paymentFlow.canChangeMethod,
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor,
                accentColor: Color(hex: 0xC8965A),
                surfaceColor: cardFillColor
            ) {
                isPaymentMethodSheetPresented = true
            }

            PaymentStatusView(
                state: paymentFlow.state,
                accentColor: Color(hex: 0xC8965A),
                primaryColor: primaryTextColor,
                secondaryColor: secondaryTextColor
            )
        }
    }

    private func paymentMethodChip(title: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))

            Text(title)
                .font(labelFont(size: 9, weight: .bold))
                .tracking(1)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .foregroundColor(primaryTextColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(elevatedSurfaceColor)
        .overlay(
            Capsule(style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
        )
        .clipShape(Capsule(style: .continuous))
        .accessibilityValue(AppLocalization.text("available_in_secure_checkout", fallback: "Available in secure checkout"))
    }

    private var cartItemsListSection: some View {
        ForEach($cartItems) { $item in
            HStack(alignment: .center, spacing: 10) {
                ProductThumbnail(imageURL: item.product.imageURL, size: 44, cornerRadius: 8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.product.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.86)

                    if let variantTitle = cartVariantDisplayTitle(for: item) {
                        Text(variantTitle)
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }

                    Text(item.variant.price)
                        .font(.system(size: 10, weight: .light))
                        .foregroundColor(Color(hex: 0xC8965A))
                }

                Spacer()

                HStack(spacing: 0) {
                    Button {
                        if item.quantity > 1 {
                            item.quantity -= 1
                            checkoutError = nil
                        } else {
                            requestRemoveFromCart(id: item.id)
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("decrease_quantity", fallback: "Decrease quantity"))

                    Text("\(item.quantity)")
                        .font(labelFont(size: 10, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 28, height: 36)
                        .accessibilityLabel("\(AppLocalization.text("quantity", fallback: "Quantity")) \(item.quantity)")

                    Button {
                        item.quantity += 1
                        checkoutError = nil
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("increase_quantity", fallback: "Increase quantity"))
                }
                .foregroundColor(Color(hex: 0xC8965A))
                .background(cardFillColor)
                .overlay(
                    Capsule()
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.18 : 0.1), lineWidth: 1)
                )
                .clipShape(Capsule())

                Button {
                    requestRemoveFromCart(id: item.id)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 32, height: 32)
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
            Text(AppLocalization.text("rewards_voucher", fallback: "Rewards & Vouchers"))
                .font(labelFont(size: 11, weight: .bold))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))

            Text(AppLocalization.text("rewards_voucher_detail", fallback: "Apply a reward before opening checkout, or continue without one."))
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isVoucherCodeEntryExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Text(AppLocalization.text("add_voucher_discount_code", fallback: "Add voucher or discount code"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0xC8965A))

                    Spacer()

                    Image(systemName: isVoucherCodeEntryExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0xC8965A))
                }
                .padding(14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            if isVoucherCodeEntryExpanded {
                HStack(spacing: 10) {
                    TextField(AppLocalization.text("enter_voucher_code", fallback: "Enter voucher code"), text: $voucherCodeInput)
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
                        Text(isApplyingVoucher ? "..." : AppLocalization.text("apply", fallback: "Apply"))
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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let appliedVoucher {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(appliedVoucher.code)
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(1.2)
                            .foregroundColor(Color(hex: 0xC8965A))

                        Spacer()

                        Button(AppLocalization.text("remove", fallback: "Remove")) {
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

                    Text(String(format: AppLocalization.text("discount_expires", fallback: "Discount: %@ • Expires %@"), formattedBHD(cartDiscount), appliedVoucher.expiresAt.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: "")))
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
                    if availableVouchers.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "ticket")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: 0xC8965A))
                                .frame(width: 20, height: 20)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Text(AppLocalization.text("no_active_vouchers", fallback: "No active vouchers"))
                                        .font(labelFont(size: 10, weight: .bold))
                                        .tracking(1.2)
                                        .textCase(.uppercase)
                                        .foregroundColor(primaryTextColor)

                                    if isLoadingAvailableVouchers {
                                        ProgressView()
                                            .scaleEffect(0.75)
                                            .tint(Color(hex: 0xC8965A))
                                    }
                                }

                                Text(AppLocalization.text("active_vouchers_empty", fallback: "Redeem Beans in The Talla Club to unlock one."))
                                    .font(bodyFont(size: 12))
                                    .foregroundColor(secondaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)

                                Button {
                                    cartOpen = false
                                    openAccountSection(AccountSectionView.ScrollTarget.loyalty)
                                } label: {
                                    Label(AppLocalization.text("view_rewards", fallback: "View Rewards"), systemImage: appLanguage.layoutDirection == .rightToLeft ? "arrow.left" : "arrow.right")
                                        .font(labelFont(size: 10, weight: .bold))
                                        .tracking(1.3)
                                        .textCase(.uppercase)
                                        .foregroundColor(Color(hex: 0xC8965A))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(14)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    } else {
                        HStack {
                            Text(AppLocalization.text("your_active_vouchers", fallback: "Your Active Vouchers"))
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
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isCartSaveEntryExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    Label(AppLocalization.text("save_cart_later", fallback: "Save this bag for later"), systemImage: "bookmark")
                        .font(labelFont(size: 12, weight: .semibold))
                        .foregroundColor(primaryTextColor)

                    Spacer()

                    Image(systemName: isCartSaveEntryExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: 0xC8965A))
                }
                .padding(14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            if isCartSaveEntryExpanded {
                HStack(spacing: 10) {
                    TextField(AppLocalization.text("save_cart_placeholder", fallback: "Weekend beans, gifting run, office order..."), text: $cartSaveName)
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
                        Text(AppLocalization.text("save", fallback: "Save"))
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
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(Color(hex: 0xC8965A))

            Text(AppLocalization.text("loading_shop", fallback: "Loading the shop"))
                .font(.system(size: 12, weight: .medium))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private var homeSurprisePickSkeleton: some View {
        HStack(alignment: .center, spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(skeletonFillColor)
                .frame(width: isCompact ? 82 : 96, height: isCompact ? 82 : 96)

            VStack(alignment: .leading, spacing: 9) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(skeletonFillColor)
                    .frame(width: 92, height: 10)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(skeletonFillColor)
                    .frame(height: 20)

                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(skeletonFillColor)
                    .frame(width: 130, height: 20)

                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(skeletonFillColor)
                        .frame(width: 72, height: 34)

                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                        .fill(skeletonFillColor)
                        .frame(width: 94, height: 34)
                }
            }
        }
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
        .accessibilityLabel(AppLocalization.text("loading_shop", fallback: "Loading the shop"))
    }

    private func productSkeletonGrid(count: Int) -> some View {
        LazyVGrid(columns: productGridColumns, spacing: 16) {
            ForEach(0..<count, id: \.self) { _ in
                productSkeletonCard
            }
        }
        .accessibilityLabel(AppLocalization.text("loading_shop", fallback: "Loading the shop"))
    }

    private var productSkeletonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(skeletonFillColor)
                .frame(height: 184)

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(skeletonFillColor)
                .frame(width: 92, height: 10)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(skeletonFillColor)
                .frame(height: 22)

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(skeletonFillColor)
                .frame(width: 150, height: 22)

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(skeletonFillColor)
                .frame(width: 78, height: 14)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(skeletonFillColor)
                .frame(height: 38)
        }
        .padding(14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .redacted(reason: .placeholder)
        .allowsHitTesting(false)
    }

    private var skeletonFillColor: Color {
        isLightAppearance ? Color(hex: 0xC8965A).opacity(0.13) : Color.white.opacity(0.08)
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
        let tasteSummary = productTasteSummary(for: product)
        let brewRecommendation = productBrewRecommendation(for: product)
        let metadataChips = productMetadataChips(for: product)
        let cardMinimumHeight: CGFloat = showDescription ? (isCompact ? 468 : 488) : (isCompact ? 396 : 416)
        let shouldShowAlertButton = !product.isAvailableForSale || isAlertEnabled(product)

        return VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .topTrailing) {
                ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 10)
                    .frame(height: isCompact ? 176 : 184)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(productBadges(for: product), id: \.self) { badge in
                        productBadge(badge)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(10)

                VStack(alignment: .trailing, spacing: 8) {
                    Button {
                        toggleFavorite(product: product)
                    } label: {
                        Image(systemName: isFavorite(product) ? "heart.fill" : "heart")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(isFavorite(product) ? Color(hex: 0xC8965A) : primaryTextColor)
                            .symbolEffect(.bounce, value: isFavorite(product))
                            .frame(width: 34, height: 34)
                            .background(cardFillColor.opacity(0.92))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    if shouldShowAlertButton {
                        Button {
                            Task {
                                await toggleAlert(product: product)
                            }
                        } label: {
                            Image(systemName: isAlertEnabled(product) ? "bell.fill" : "bell")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isAlertEnabled(product) ? Color(hex: 0xC8965A) : primaryTextColor)
                                .symbolEffect(.bounce, value: isAlertEnabled(product))
                                .frame(width: 34, height: 34)
                                .background(cardFillColor.opacity(0.92))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isAlertEnabled(product)
                            ? AppLocalization.text("remove_alert", fallback: "Remove alert")
                            : AppLocalization.text("notify_me", fallback: "Notify me"))
                    }

                    if let tag = product.tag {
                        Text(tag)
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(1.2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(Color(hex: 0xC8965A))
                            .foregroundColor(Color(hex: 0x0A0804))
                            .cornerRadius(2)
                            .frame(maxWidth: 86, alignment: .trailing)
                    }
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(product.categoryLabel)
                    .font(labelFont(size: 10, weight: .semibold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(tertiaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .frame(height: 13, alignment: .leading)

                Text(product.name)
                    .font(titleFont(size: isCompact ? 18 : 20))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .lineSpacing(1)
                    .minimumScaleFactor(0.78)
                    .frame(height: 48, alignment: .topLeading)

                if showDescription {
                    Text(tasteSummary)
                        .font(labelFont(size: isCompact ? 12 : 13, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity, minHeight: 18, alignment: .leading)

                    Label(brewRecommendation, systemImage: "drop.fill")
                        .font(bodyFont(size: isCompact ? 13 : 14))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .frame(maxWidth: .infinity, minHeight: isCompact ? 34 : 38, alignment: .leading)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 74 : 84), spacing: 6)], spacing: 6) {
                        ForEach(metadataChips.indices, id: \.self) { index in
                            productMetadataChip(icon: metadataChips[index].icon, title: metadataChips[index].title)
                        }
                    }
                    .frame(height: isCompact ? 72 : 76, alignment: .topLeading)
                }
            }

            Spacer(minLength: 0)

            if product.hasVariantChoices, let variant = selectedVariant(for: product) {
                Text("\(AppLocalization.text("selected_variant", fallback: "Variant:")) \(variant.title)")
                    .font(bodyFont(size: 12))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity, minHeight: 20, alignment: .leading)
            } else {
                Text(" ")
                    .font(bodyFont(size: 12))
                    .lineLimit(1)
                    .frame(height: 20)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(product.price)
                    .font(labelFont(size: isCompact ? 14 : 15, weight: .bold))
                    .foregroundColor(product.isAvailableForSale ? Color(hex: 0xC8965A) : tertiaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 18, alignment: .leading)

                Button {
                    if product.hasVariantChoices {
                        recordRecentlyViewed(product)
                        selectedProduct = product
                    } else {
                        addToCart(product: product)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: product.hasVariantChoices ? "slider.horizontal.3" : "plus")
                            .font(.system(size: 11, weight: .bold))

                        Text(product.isAvailableForSale ? (product.hasVariantChoices ? AppLocalization.text("options", fallback: "Options") : AppLocalization.text("add", fallback: "Add")) : AppLocalization.text("sold_out", fallback: "Sold Out"))
                            .font(labelFont(size: isCompact ? 9 : 10, weight: .bold))
                            .tracking(isCompact ? 0.4 : 0.8)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity, minHeight: 18)
                    .foregroundColor(product.isAvailableForSale ? Color(hex: 0x0A0804) : tertiaryTextColor)
                    .padding(.horizontal, isCompact ? 10 : 12)
                    .padding(.vertical, 10)
                    .glassEffect(
                        product.isAvailableForSale
                            ? .regular.tint(Color(hex: 0xC8965A)).interactive()
                            : .clear,
                        in: .capsule
                    )
                }
                .buttonStyle(.plain)
                .disabled(!product.isAvailableForSale || selectedVariant(for: product) == nil)
            }
            .frame(maxWidth: .infinity, minHeight: 74, alignment: .bottom)
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
        .frame(maxWidth: .infinity, minHeight: cardMinimumHeight, alignment: .topLeading)
        .hoverEffect(.lift)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture {
            recordRecentlyViewed(product)
            selectedProduct = product
        }
    }

    private func signatureRoastCard(_ product: Product) -> some View {
        let notes = productTasteNotes(for: product)
        let cardWidth: CGFloat = isCompact ? 176 : 194

        return VStack(alignment: .leading, spacing: 7) {
            ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 14)
                .frame(width: cardWidth - 20, height: isCompact ? 122 : 134)

            VStack(alignment: .leading, spacing: 4) {
                Text(productOriginLabel(for: product))
                    .font(labelFont(size: 8, weight: .bold))
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0xC8965A))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(customerFacingProductName(for: product))
                    .font(titleFont(size: isCompact ? 15 : 16))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .lineSpacing(1)
                    .minimumScaleFactor(0.78)
                    .frame(height: 38, alignment: .topLeading)

                HStack(spacing: 5) {
                    ForEach(notes.prefix(2), id: \.self) { note in
                        Text(note)
                            .font(labelFont(size: 8, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .foregroundColor(primaryTextColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.16))
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 22, alignment: .leading)
            }

            HStack(spacing: 8) {
                Text(product.price)
                    .font(labelFont(size: 11, weight: .bold))
                    .foregroundColor(product.isAvailableForSale ? Color(hex: 0xC8965A) : tertiaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 0)

                Button {
                    if product.hasVariantChoices {
                        recordRecentlyViewed(product)
                        selectedProduct = product
                    } else {
                        addToCart(product: product)
                    }
                } label: {
                    Text(signatureRoastActionTitle(for: product))
                        .font(labelFont(size: 8, weight: .bold))
                        .tracking(0.6)
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .foregroundColor(product.isAvailableForSale ? Color(hex: 0x0A0804) : tertiaryTextColor)
                        .frame(width: 82)
                        .padding(.vertical, 7)
                        .glassEffect(
                            product.isAvailableForSale
                                ? .regular.tint(Color(hex: 0xC8965A)).interactive()
                                : .clear,
                            in: .capsule
                        )
                }
                .buttonStyle(.plain)
                .disabled(!product.isAvailableForSale || selectedVariant(for: product) == nil)
            }
            .frame(height: 30, alignment: .center)
        }
        .padding(10)
        .frame(width: cardWidth, height: isCompact ? 258 : 276, alignment: .topLeading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            recordRecentlyViewed(product)
            selectedProduct = product
        }
        .hoverEffect(.lift)
    }

    private func signatureRoastActionTitle(for product: Product) -> String {
        if !product.isAvailableForSale {
            return AppLocalization.text("sold_out", fallback: "Sold Out")
        }

        return product.hasVariantChoices
            ? AppLocalization.text("options", fallback: "Options")
            : AppLocalization.text("add", fallback: "Add")
    }

    private func productPreviewDescription(for product: Product) -> String {
        let plainDescription = product.desc
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let fallback = product.categoryLabel.isEmpty
            ? AppLocalization.text("shop_product_preview_fallback", fallback: "Tap for full details.")
            : product.categoryLabel
        let cleanedDescription = customerFacingText(plainDescription)
        let description = cleanedDescription.isEmpty ? fallback : cleanedDescription
        let maxLength = isCompact ? 74 : 112

        guard description.count > maxLength else { return description }

        let endIndex = description.index(description.startIndex, offsetBy: maxLength)
        return description[..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private func customerFacingProductName(for product: Product) -> String {
        let cleanedName = customerFacingText(product.name)
        return cleanedName.isEmpty ? AppLocalization.text("this_product", fallback: "this product") : cleanedName
    }

    private func customerFacingText(_ text: String) -> String {
        var cleaned = text
            .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        let prefixes = [
            "Product Description:",
            "Description:",
            "Product Details:",
            "Product Experience:",
            "Product Quality:"
        ]

        var removedPrefix = true
        while removedPrefix {
            removedPrefix = false
            for prefix in prefixes where cleaned.range(of: prefix, options: [.caseInsensitive, .anchored]) != nil {
                cleaned = String(cleaned.dropFirst(prefix.count))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                removedPrefix = true
            }
        }

        return cleaned
    }

    private func recommendationCopy(source: Product, recommended: Product) -> String {
        let sourceName = customerFacingProductName(for: source)
        let recommendedName = customerFacingProductName(for: recommended)
        return String(format: AppLocalization.text("similar_order_recommendation_plain", fallback: "Loved %@? Try %@ for your next gathering."), sourceName, recommendedName)
    }

    private func productOriginLabel(for product: Product) -> String {
        let searchableText = normalizedSearchText(for: product)

        if let origin = firstMatchedValue(in: searchableText, matches: [
            ("ethiopia", "Ethiopia"),
            ("colombia", "Colombia"),
            ("brazil", "Brazil"),
            ("yemen", "Yemen"),
            ("kenya", "Kenya"),
            ("guatemala", "Guatemala"),
            ("costa rica", "Costa Rica"),
            ("arabic", "Arabic Coffee")
        ]) {
            return origin
        }

        return product.categoryLabel.isEmpty
            ? AppLocalization.text("signature_roast_origin_fallback", fallback: "Signature Roast")
            : product.categoryLabel
    }

    private func productTasteNotes(for product: Product) -> [String] {
        let notes = productTasteSummary(for: product)
            .components(separatedBy: " - ")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if notes.isEmpty {
            return [
                AppLocalization.text("taste_note_balanced", fallback: "Balanced"),
                AppLocalization.text("taste_note_sweet", fallback: "Sweet")
            ]
        }

        if notes.count == 1 {
            return notes + [AppLocalization.text("taste_note_clean", fallback: "Clean")]
        }

        return Array(notes.prefix(2))
    }

    private func productTasteSummary(for product: Product) -> String {
        let searchableText = normalizedSearchText(for: product)
        let matchedNotes = orderedUniqueValues(tasteNoteMatches(in: searchableText))

        if !matchedNotes.isEmpty {
            return matchedNotes.prefix(3).joined(separator: " - ")
        }

        if product.categoryKey == "coffee-beans" || product.categoryKey == "drip-bags" {
            return AppLocalization.text("coffee_card_default_taste", fallback: "Balanced - Sweet - Clean")
        }

        switch product.categoryKey {
        case "ready-made-drinks", "summer-drinks":
            return AppLocalization.text("ready_drink_card_summary", fallback: "Ready to drink")
        case "cups":
            return AppLocalization.text("cups_card_summary", fallback: "Reusable cup")
        case "coffee-equipment":
            return AppLocalization.text("equipment_card_summary", fallback: "Brewing gear")
        case "gifts":
            return AppLocalization.text("gifts_card_summary", fallback: "Gift box")
        case "arabic-coffee":
            return AppLocalization.text("arabic_card_summary", fallback: "Arabic coffee")
        default:
            return product.categoryLabel.isEmpty
                ? AppLocalization.text("product_card_summary_fallback", fallback: "Talla pick")
                : product.categoryLabel
        }
    }

    private func tasteNoteMatches(in searchableText: String) -> [String] {
        let notes: [(keyword: String, note: String)] = [
            (keyword: "berry", note: "Berries"),
            (keyword: "berries", note: "Berries"),
            (keyword: "floral", note: "Floral"),
            (keyword: "jasmine", note: "Floral"),
            (keyword: "chocolate", note: "Chocolate"),
            (keyword: "cocoa", note: "Chocolate"),
            (keyword: "caramel", note: "Caramel"),
            (keyword: "citrus", note: "Citrus"),
            (keyword: "orange", note: "Citrus"),
            (keyword: "fruit", note: "Fruity"),
            (keyword: "nut", note: "Nutty"),
            (keyword: "honey", note: "Honey"),
            (keyword: "vanilla", note: "Vanilla")
        ]

        return notes.compactMap { pair in
            searchableText.contains(pair.keyword) ? pair.note : nil
        }
    }

    private func productBrewRecommendation(for product: Product) -> String {
        let searchableText = normalizedSearchText(for: product)

        if product.categoryKey == "ready-made-drinks" || product.categoryKey == "summer-drinks" {
            return AppLocalization.text("best_ready_to_drink", fallback: "Best served chilled and ready to drink.")
        }

        if product.categoryKey == "cups" {
            return AppLocalization.text("best_for_cups", fallback: "Best for serving hot and cold drinks.")
        }

        if product.categoryKey == "coffee-equipment" {
            return AppLocalization.text("best_for_home_brewing", fallback: "Best for your home brewing setup.")
        }

        if searchableText.contains("arabic") {
            return AppLocalization.text("best_for_arabic_coffee", fallback: "Best for Arabic coffee and sharing.")
        }

        if searchableText.contains("espresso") {
            return AppLocalization.text("best_for_espresso", fallback: "Best for espresso and milk drinks.")
        }

        if searchableText.contains("iced") || searchableText.contains("cold") {
            return AppLocalization.text("best_for_iced_v60", fallback: "Best for V60 and iced coffee.")
        }

        if searchableText.contains("drip") {
            return AppLocalization.text("best_for_drip_bags", fallback: "Best for easy travel brewing.")
        }

        return AppLocalization.text("best_for_v60", fallback: "Best for V60 and filter brewing.")
    }

    private func productMetadataChips(for product: Product) -> [(icon: String, title: String)] {
        let searchableText = normalizedSearchText(for: product)
        var chips: [(icon: String, title: String)] = []

        if let roast = firstMatchedValue(in: searchableText, matches: [
            ("light roast", "Light"),
            ("medium roast", "Medium"),
            ("dark roast", "Dark"),
            ("light", "Light"),
            ("medium", "Medium"),
            ("dark", "Dark")
        ]) {
            chips.append(("flame.fill", roast))
        }

        if let process = firstMatchedValue(in: searchableText, matches: [
            ("anaerobic", "Anaerobic"),
            ("natural", "Natural"),
            ("washed", "Washed"),
            ("honey", "Honey")
        ]) {
            chips.append(("sparkles", process))
        }

        if let origin = firstMatchedValue(in: searchableText, matches: [
            ("ethiopia", "Ethiopia"),
            ("colombia", "Colombia"),
            ("brazil", "Brazil"),
            ("yemen", "Yemen"),
            ("kenya", "Kenya"),
            ("guatemala", "Guatemala"),
            ("costa rica", "Costa Rica"),
            ("arabic", "Arabic")
        ]) {
            chips.append(("globe.europe.africa.fill", origin))
        }

        chips.append(("drop.fill", productBrewChipTitle(for: product)))

        if chips.count < 4 {
            chips.append(("tag.fill", product.categoryLabel))
        }

        return Array(chips.prefix(4))
    }

    private func productMetadataChip(icon: String, title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))

            Text(title)
                .font(labelFont(size: 9, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundColor(Color(hex: 0xC8965A))
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.14))
        .clipShape(Capsule())
    }

    private func productBrewChipTitle(for product: Product) -> String {
        let searchableText = normalizedSearchText(for: product)

        if product.categoryKey == "ready-made-drinks" || product.categoryKey == "summer-drinks" { return "Chilled" }
        if product.categoryKey == "cups" { return "Serve" }
        if product.categoryKey == "coffee-equipment" { return "Gear" }
        if searchableText.contains("espresso") { return "Espresso" }
        if searchableText.contains("arabic") { return "Arabic" }
        if searchableText.contains("drip") { return "Drip" }
        return "V60"
    }

    private func normalizedSearchText(for product: Product) -> String {
        "\(product.name) \(product.categoryLabel) \(product.tag ?? "") \(productPreviewDescription(for: product))"
            .lowercased()
    }

    private func coffeePassportOriginKey(in text: String) -> String? {
        let normalizedText = text.lowercased()
        if let origin = remotePassportSettings?.origins.first(where: { origin in
            origin.keywords.contains { keyword in
                normalizedText.contains(keyword.lowercased())
            }
        }) {
            return origin.id
        }

        return defaultCoffeePassportOrigins.first { origin in
            normalizedText.contains(origin.id) || normalizedText.contains(origin.title.lowercased())
        }?.id
    }

    private func firstMatchedValue(in text: String, matches: [(needle: String, value: String)]) -> String? {
        matches.first { text.contains($0.needle) }?.value
    }

    private func orderedUniqueValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    private func productBadges(for product: Product) -> [String] {
        var badges: [String] = []
        let normalizedTag = product.tag?.lowercased() ?? ""
        let normalizedName = product.name.lowercased()

        if !product.isAvailableForSale {
            badges.append(AppLocalization.text("back_soon", fallback: "Back soon"))
        } else if normalizedTag.contains("new") {
            badges.append(AppLocalization.text("new", fallback: "New"))
        } else if normalizedTag.contains("limited") {
            badges.append(AppLocalization.text("limited", fallback: "Limited"))
        } else if normalizedTag.contains("staff") {
            badges.append(AppLocalization.text("staff_pick", fallback: "Staff Pick"))
        } else if normalizedTag.contains("popular") || normalizedTag.contains("best") {
            badges.append(AppLocalization.text("popular", fallback: "Popular"))
        }

        if product.categoryKey == "gifts" {
            badges.append(AppLocalization.text("gift_ready", fallback: "Gift ready"))
        }

        if product.categoryKey.contains("coffee") && product.isAvailableForSale {
            badges.append(AppLocalization.text("reward_eligible", fallback: "Reward eligible"))
        }

        if normalizedName.contains("cold") || normalizedName.contains("iced") || product.categoryKey == "summer-drinks" {
            badges.append(AppLocalization.text("cold_pick", fallback: "Cold pick"))
        }

        return Array(badges.prefix(2))
    }

    private func productBadge(_ title: String) -> some View {
        Text(title)
            .font(labelFont(size: 8, weight: .bold))
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundColor(Color(hex: 0x0A0804))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color(hex: 0xC8965A))
            .clipShape(Capsule(style: .continuous))
    }

    private func productDetailSheet(product: Product) -> some View {
        let selectedVariant = selectedVariant(for: product)

        return ScrollView(showsIndicators: false) {
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

                Text(selectedVariant?.price ?? product.price)
                    .font(displayFont(size: 24))
                    .foregroundColor((selectedVariant?.isAvailableForSale ?? product.isAvailableForSale) ? Color(hex: 0xC8965A) : tertiaryTextColor)

                Text(product.desc)
                    .font(bodyFont(size: 15))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                if product.hasVariantChoices {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppLocalization.text("variants", fallback: "VARIANTS"))
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0xC8965A))

                        ForEach(product.variants) { variant in
                            Button {
                                selectedVariantIDs[product.id] = variant.id
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(variant.title)
                                            .font(bodyFont(size: 14))
                                            .foregroundColor(primaryTextColor)
                                        Text(variant.price)
                                            .font(labelFont(size: 10, weight: .bold))
                                            .tracking(1.4)
                                            .foregroundColor(Color(hex: 0xC8965A))
                                    }

                                    Spacer()

                                    Text(variant.isAvailableForSale ? AppLocalization.text("available", fallback: "Available") : AppLocalization.text("sold_out", fallback: "Sold Out"))
                                        .font(labelFont(size: 9, weight: .bold))
                                        .tracking(1.4)
                                        .textCase(.uppercase)
                                        .foregroundColor(variant.isAvailableForSale ? primaryTextColor : tertiaryTextColor)

                                    Image(systemName: selectedVariant?.id == variant.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedVariant?.id == variant.id ? Color(hex: 0xC8965A) : tertiaryTextColor)
                                }
                                .padding(14)
                                .background(cardFillColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            (selectedVariant?.id == variant.id ? Color(hex: 0xC8965A) : Color(hex: 0xC8965A).opacity(0.14)),
                                            lineWidth: 1
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    DetailStatusCardView(
                        title: AppLocalization.text("availability", fallback: "Availability"),
                        detail: product.isAvailableForSale ? AppLocalization.text("ready_to_order", fallback: "Ready to order now") : AppLocalization.text("currently_sold_out", fallback: "Currently sold out"),
                        titleFont: labelFont(size: 10, weight: .bold),
                        detailFont: bodyFont(size: 13),
                        accentColor: Color(hex: 0xC8965A),
                        primaryTextColor: primaryTextColor,
                        backgroundColor: cardFillColor,
                        strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08)
                    )
                    DetailStatusCardView(
                        title: AppLocalization.text("category", fallback: "Category"),
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
                        Text((selectedVariant?.isAvailableForSale ?? product.isAvailableForSale) ? AppLocalization.text("add_to_bag", fallback: "Add to Bag") : AppLocalization.text("sold_out", fallback: "Sold Out"))
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundColor((selectedVariant?.isAvailableForSale ?? product.isAvailableForSale) ? Color(hex: 0x0A0804) : tertiaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .glassEffect(
                                (selectedVariant?.isAvailableForSale ?? product.isAvailableForSale)
                                    ? .regular.tint(Color(hex: 0xC8965A)).interactive()
                                    : .clear,
                                in: .capsule
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!(selectedVariant?.isAvailableForSale ?? false))
                }
            }
            .padding(20)
        }
        .background(backgroundGradientColors[0].ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }

    private func collectionTile(eyebrow: String, name: String, desc: String, accent: String, systemImage: String, color: Color, categoryKey: String) -> some View {
        Button {
            openShop(category: categoryKey)
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

            Button {
                openURL(destination)
            } label: {
                HStack(spacing: 6) {
                    Text(actionTitle)
                    Image(systemName: "arrow.up.right")
                }
                .font(labelFont(size: 11, weight: .bold))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0xC8965A))
            }
            .buttonStyle(.plain)
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
            customerAuthError = AppLocalization.text("enter_email_password", fallback: "Enter your customer email and password.")
            return
        }

        isSigningIn = true
        customerAuthError = nil

        do {
            let session = try await AccountService.signIn(email: trimmedEmail, password: accountPassword)
            applySignedInSession(session)
            accountPassword = ""
            showToast(message: AppLocalization.text("signed_in_toast", fallback: "Signed in"))
        } catch {
            customerProfile = nil
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isSigningIn = false
    }

#if canImport(AuthenticationServices)
    private func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomAppleNonce()
        appleSignInNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    private func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        Task {
            await handleAppleSignInResultAsync(result)
        }
    }

    @MainActor
    private func handleAppleSignInResultAsync(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            appleSignInNonce = ""

            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                customerAuthError = nil
                isSigningInWithApple = false
                return
            }

            customerAuthError = friendlyCustomerAuthMessage(
                for: error,
                fallback: AppLocalization.text("apple_sign_in_unavailable", fallback: "Sign in with Apple is unavailable right now.")
            )
            isSigningInWithApple = false
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                customerAuthError = AppLocalization.text("apple_sign_in_invalid_credential", fallback: "Apple sign-in did not return a valid account credential.")
                isSigningInWithApple = false
                return
            }

            guard let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8),
                  !identityToken.isEmpty else {
                customerAuthError = AppLocalization.text("apple_sign_in_missing_token", fallback: "Apple sign-in did not return an identity token.")
                isSigningInWithApple = false
                return
            }

            let nonce = appleSignInNonce
            guard !nonce.isEmpty else {
                customerAuthError = AppLocalization.text("apple_sign_in_not_verified", fallback: "Apple sign-in could not be verified.")
                isSigningInWithApple = false
                return
            }

            isSigningInWithApple = true
            customerAuthError = nil

            do {
                let session = try await AccountService.signInWithApple(
                    identityToken: identityToken,
                    userIdentifier: credential.user,
                    email: credential.email,
                    firstName: credential.fullName?.givenName,
                    lastName: credential.fullName?.familyName,
                    nonce: nonce
                )
                applySignedInSession(session)
                accountPassword = ""
                accountConfirmPassword = ""
                showToast(message: AppLocalization.text("signed_in_with_apple_toast", fallback: "Signed in with Apple"))
            } catch {
                customerProfile = nil
                customerAuthError = friendlyCustomerAuthMessage(
                    for: error,
                    fallback: AppLocalization.text("apple_sign_in_unavailable", fallback: "Sign in with Apple is unavailable right now.")
                )
            }

            appleSignInNonce = ""
            isSigningInWithApple = false
        }
    }
#endif

    private func switchAccountAuthMode(_ mode: AccountAuthMode) {
        accountAuthMode = mode
        customerAuthError = nil
        accountPassword = ""
        accountConfirmPassword = ""
        appleSignInNonce = ""
    }

    private func startFirstRunAccountSetup() {
        hasSeenWelcome = true
        cartOpen = false
        openAccountSection(AccountSectionView.ScrollTarget.customer, authMode: .createAccount)
        showToast(message: AppLocalization.text("onboarding_account_started", fallback: "Create your account first. Delivery details come next."))
    }

    @MainActor
    private func prepareNewCustomerAddressSetup(firstName: String, lastName: String) {
        if addressLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressLabel = AppLocalization.text("home_address_label", fallback: "Home")
        }

        if addressFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressFullName = [firstName, lastName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        isDeliveryDetailsExpanded = true
        openAccountSection(AccountSectionView.ScrollTarget.library)
        showToast(message: AppLocalization.text("account_created_add_address_toast", fallback: "Account created. Add delivery details next."))
    }

    @MainActor
    private func createCustomerAccount() async {
        let trimmedFirstName = accountFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = accountLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = normalizedAccountEmail

        guard !trimmedFirstName.isEmpty, !trimmedLastName.isEmpty, !trimmedEmail.isEmpty, !accountPassword.isEmpty else {
            customerAuthError = AppLocalization.text("complete_account_fields", fallback: "Complete your name, email, and password to create an account.")
            return
        }

        guard accountPassword == accountConfirmPassword else {
            customerAuthError = AppLocalization.text("password_confirmation_mismatch", fallback: "Your password confirmation does not match.")
            return
        }

        guard accountPassword.count >= 5 else {
            customerAuthError = AppLocalization.text("password_min_length", fallback: "Use a password with at least 5 characters.")
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
            prepareNewCustomerAddressSetup(firstName: trimmedFirstName, lastName: trimmedLastName)
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
            customerAuthError = AppLocalization.text("enter_email_first", fallback: "Enter your email address first.")
            return
        }

        isRequestingPasswordResetLink = true
        customerAuthError = nil

        do {
            try await AccountService.requestPasswordResetLink(email: trimmedEmail)
            accountPassword = ""
            showToast(message: AppLocalization.text("reset_link_sent", fallback: "If an account exists for that email, a reset link has been sent."))
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(
                for: error,
                fallback: AppLocalization.text("email_reset_link", fallback: "Password reset email is unavailable right now.")
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
        let emailToUnregister = customerProfile?.email ?? (!savedCustomerEmail.isEmpty ? savedCustomerEmail : nil)
        let accessTokenToUnregister = savedCustomerAccessToken
        unregisterRemotePushToken(email: emailToUnregister, accessToken: accessTokenToUnregister)
        unregisterRemoteNotifications()
        savedRegisteredPushDeviceEmail = ""
        savedRegisteredPushDeviceToken = ""
        savedCustomerEmail = ""
        savedCustomerAccessToken = ""
        customerProfile = nil
        accountAuthMode = .signIn
        accountFirstName = ""
        accountLastName = ""
        accountPassword = ""
        accountConfirmPassword = ""
        appleSignInNonce = ""
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
        savedLoyaltyEmail = profile.email
        customerProfile = profile
        accountEmail = profile.email
        profileFirstName = profile.firstName ?? ""
        profileLastName = profile.lastName ?? ""

        if loadLoyalty {
            loyaltyEmail = profile.email
        }

        registerForRemoteNotifications()
        Task {
            await refreshWalletPassPresence()
            await syncRemotePushTokenIfPossible()
            if loadLoyalty {
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
            customerAuthError = AppLocalization.text("enter_full_name_before_saving", fallback: "Enter both first and last name before saving.")
            return
        }

        isSavingProfile = true
        customerAuthError = nil

        do {
            let updated = try await AccountService.updateProfile(email: profile.email, firstName: firstName, lastName: lastName)
            customerProfile = updated
            profileFirstName = updated.firstName ?? ""
            profileLastName = updated.lastName ?? ""
            showToast(message: AppLocalization.text("profile_updated_toast", fallback: "Profile updated"))
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isSavingProfile = false
    }

    @MainActor
    private func resetPassword() async {
        guard let profile = customerProfile else { return }

        guard newPasswordInput == confirmNewPasswordInput else {
            customerAuthError = AppLocalization.text("new_password_confirmation_mismatch", fallback: "The new password confirmation does not match.")
            return
        }

        guard newPasswordInput.count >= 5 else {
            customerAuthError = AppLocalization.text("password_min_length", fallback: "Use a password with at least 5 characters.")
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
            showToast(message: AppLocalization.text("update_password", fallback: "Password updated"))
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
            let isPassInWallet = await Task.detached(priority: .userInitiated) {
                PKPassLibrary().containsPass(pass)
            }.value
            isLoyaltyPassInWallet = isPassInWallet
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
            customerAuthError = AppLocalization.text("enter_email_current_new_password", fallback: "Enter your email, current password, and new password.")
            return
        }

        guard accountConfirmPassword.count >= 5 else {
            customerAuthError = AppLocalization.text("password_min_length", fallback: "Use a password with at least 5 characters.")
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
            showToast(message: AppLocalization.text("update_password", fallback: "Password updated"))
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
            if let remoteTasteMemory = try? await AccountService.fetchTasteMemory(email: profile.email) {
                persistTasteMemoryRecords(remoteTasteMemory)
            }
        } catch {
            orderHistory = []
            ordersError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("orders_refresh_failed", fallback: "Orders could not be refreshed right now.")
            )
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
        let phone = normalizedPhoneNumber(addressPhone)
        let line1 = addressLine1.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = addressCity.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = addressNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !label.isEmpty, !fullName.isEmpty, !phone.isEmpty, !line1.isEmpty, !city.isEmpty else {
            showToast(message: AppLocalization.text("complete_address_details", fallback: "Complete the address details first"))
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
                countryCode: addressCountry.rawValue,
                notes: notes.isEmpty ? nil : notes
            )
            addressLabel = ""
            addressFullName = ""
            addressPhone = ""
            addressLine1 = ""
            addressCity = ""
            addressCountry = .bahrain
            addressNotes = ""
            showToast(message: AppLocalization.text("address_saved_toast", fallback: "Address saved"))
        } catch {
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("address_save_failed", fallback: "Address could not be saved right now.")
            ))
        }
    }

    private func normalizedPhoneNumber(_ rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        return trimmed.hasPrefix("+") ? trimmed : "+\(trimmed)"
    }

    @MainActor
    private func deleteAddress(_ address: DeliveryAddress) async {
        guard let profile = customerProfile else { return }

        do {
            addresses = try await AccountService.deleteAddress(email: profile.email, addressID: address.id)
            showToast(message: AppLocalization.text("address_removed_toast", fallback: "Address removed"))
        } catch {
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("address_remove_failed", fallback: "Address could not be removed right now.")
            ))
        }
    }

    private func friendlyCustomerAuthMessage(for error: Error, fallback: String? = nil) -> String {
        if let urlError = error as? URLError,
           [.cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost, .notConnectedToInternet].contains(urlError.code) {
            return BackendConfiguration.connectionMessage(for: "account service")
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = message.lowercased()

        if normalized.contains("backendbaseurl") || normalized.contains("127.0.0.1") || normalized.contains("localhost") {
            return fallback ?? AppLocalization.text("connection_issue_try_again", fallback: "Talla is having trouble connecting. Check your internet connection and try again.")
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

    private func customerFacingServiceMessage(for error: Error, fallback: String) -> String {
        if let urlError = error as? URLError,
           [.cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost, .notConnectedToInternet].contains(urlError.code) {
            return AppLocalization.text("connection_issue_try_again", fallback: "Talla is having trouble connecting. Check your internet connection and try again.")
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = message.lowercased()

        if message.isEmpty ||
            normalized.contains("backendbaseurl") ||
            normalized.contains("127.0.0.1") ||
            normalized.contains("localhost") ||
            normalized.contains("url is invalid") ||
            normalized.contains("invalid response") ||
            normalized.contains("service is unavailable") ||
            normalized.contains("could not complete your request") {
            return fallback
        }

        return message
    }

    private func isExpiredCustomerSessionError(_ error: Error) -> Bool {
        let message = error.localizedDescription
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return message.contains("sign in again")
            || message.contains("invalid customer token")
            || message.contains("customer authorization required")
            || message.contains("customer access token")
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
            lastProductsRefreshAt = Date()
            await loadHomeSettings()
            await loadPassportSettings()

            if !availableCategories.contains(where: { $0.key == activeCategory }) {
                activeCategory = "all"
            }

            if customerProfile != nil {
                await syncBackendStockAlerts()
                await loadBackendStockAlerts()
            }
        } catch {
            loadingError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("shop_retry_later", fallback: "Products could not be loaded right now. Please try again.")
            )
        }

        isLoadingProducts = false
    }

    @MainActor
    private func loadHomeSettings() async {
        do {
            let settings = try await HomeSettingsService.fetchHomeSettings()
            remoteHomeSettings = settings
            remoteSignatureRoastProductIDs = settings.signatureRoastProductIDs
        } catch {
            remoteHomeSettings = nil
            remoteSignatureRoastProductIDs = []
        }
    }

    @MainActor
    private func loadPassportSettings() async {
        do {
            remotePassportSettings = try await HomeSettingsService.fetchPassportSettings()
        } catch {
            remotePassportSettings = nil
        }
    }

    @MainActor
    private func refreshProductsIfNeeded() async {
        let now = Date()
        if let lastProductsRefreshAt,
           now.timeIntervalSince(lastProductsRefreshAt) < 45 {
            return
        }

        await loadProducts(force: true)
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
            brewingMethodsError = AppLocalization.text("brewing_articles_fallback", fallback: "Brewing articles couldn't be loaded from Shopify. Showing curated fallback methods.")
        }

        isLoadingBrewingMethods = false
    }

    @MainActor
    private func loadLoyaltyAccount() async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = AppLocalization.text("enter_order_email_loyalty", fallback: "Enter the email you use for your coffee orders.")
            return
        }

        isLoadingLoyalty = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.fetchAccount(email: trimmedEmail)
            savedLoyaltyEmail = trimmedEmail
            syncWidgetSharedState(reload: true)
            await loadAvailableVouchers(for: trimmedEmail)
            showToast(message: AppLocalization.text("rewards_loaded_toast", fallback: "Rewards loaded"))
        } catch {
            loyaltyAccount = nil
            loyaltyError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("rewards_refresh_failed", fallback: "Rewards could not be refreshed right now.")
            )
        }

        isLoadingLoyalty = false
    }

    @MainActor
    private func redeemReward(points: Int, reward: String) async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = AppLocalization.text("enter_rewards_email_first", fallback: "Enter the email tied to your rewards account first.")
            return
        }

        isRedeemingReward = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.redeemReward(email: trimmedEmail, points: points, reward: reward)
            syncWidgetSharedState(reload: true)
            let voucherCode = loyaltyAccount?.transactions.first(where: { $0.type == "redeem" })?.voucherCode
            if let voucherCode, !voucherCode.isEmpty {
                showToast(message: String(format: AppLocalization.text("reward_redeemed_with_code", fallback: "%@ redeemed • %@"), reward, voucherCode))
            } else {
                showToast(message: String(format: AppLocalization.text("reward_redeemed", fallback: "%@ redeemed"), reward))
            }
        } catch {
            loyaltyError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("reward_redeem_failed", fallback: "This reward could not be redeemed right now.")
            )
        }

        isRedeemingReward = false
    }

    @MainActor
    private func earnPoints(points: Int, note: String) async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = AppLocalization.text("enter_rewards_email_first", fallback: "Enter the email tied to your rewards account first.")
            return
        }

        isEarningPoints = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.earnPoints(email: trimmedEmail, points: points, note: note)
            syncWidgetSharedState(reload: true)
            showToast(message: String(format: AppLocalization.text("beans_added_toast", fallback: "%d Beans added"), points))
        } catch {
            loyaltyError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("beans_update_failed", fallback: "Beans could not be updated right now.")
            )
        }

        isEarningPoints = false
    }

    private func addToCart(product: Product) {
        guard let variant = selectedVariant(for: product), variant.isAvailableForSale else {
            showToast(message: String(format: AppLocalization.text("product_unavailable_toast", fallback: "%@ is unavailable"), product.name))
            return
        }

        recordRecentlyViewed(product)

        let cartItemID = cartItemIdentifier(productID: product.id, variantID: variant.id)

        if let index = cartItems.firstIndex(where: { $0.id == cartItemID }) {
            updateCartItemQuantity(at: index, quantity: cartItems[index].quantity + 1)
        } else {
            cartItems.append(CartItem(id: cartItemID, product: product, variant: variant, quantity: 1))
        }

        checkoutError = nil
        triggerCartCelebration()
        let variantSuffix = product.hasVariantChoices ? " (\(variant.title))" : ""
        showToast(message: String(format: AppLocalization.text("product_added_to_cart", fallback: "%@%@ added to bag"), product.name, variantSuffix))
    }

    private func triggerCartCelebration() {
        cartCelebrationID += 1
        delightFeedbackTrigger += 1

        withAnimation(.spring(response: 0.26, dampingFraction: 0.48)) {
            showingCartCelebration = true
        }

        let celebrationID = cartCelebrationID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard cartCelebrationID == celebrationID else { return }

            withAnimation(.easeOut(duration: 0.18)) {
                showingCartCelebration = false
            }
        }
    }

    private func removeFromCart(id: String) {
        cartItems.removeAll { $0.id == id }
        checkoutError = nil
    }

    private func requestRemoveFromCart(id: String) {
        if cartItems.count == 1 {
            pendingCartRemovalID = id
            isConfirmingEmptyBag = true
        } else {
            removeFromCart(id: id)
        }
    }

    private func updateCartItemQuantity(at index: Int, quantity: Int) {
        guard cartItems.indices.contains(index) else { return }
        var updatedItem = cartItems[index]
        updatedItem.quantity = max(quantity, 1)
        cartItems[index] = updatedItem
    }

    private func cartItemIdentifier(productID: String, variantID: String) -> String {
        "\(productID)::\(variantID)"
    }

    private func selectedVariant(for product: Product) -> Product.Variant? {
        if let selectedVariantID = selectedVariantIDs[product.id],
           let variant = product.variants.first(where: { $0.id == selectedVariantID }) {
            return variant
        }

        return product.defaultVariant
    }

    private func cartVariantDisplayTitle(for item: CartItem) -> String? {
        let title = item.variant.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard item.product.hasVariantChoices,
              !title.isEmpty,
              title.localizedCaseInsensitiveCompare("Default") != .orderedSame,
              title.localizedCaseInsensitiveCompare("Default Title") != .orderedSame else {
            return nil
        }

        return title
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

    private var brewTimerFraction: Double {
        guard selectedBrewTimerSeconds > 0 else { return 0 }
        return min(max(Double(brewTimerRemainingSeconds) / Double(selectedBrewTimerSeconds), 0), 1)
    }

    private var brewTimerElapsedSeconds: Int {
        max(selectedBrewTimerSeconds - brewTimerRemainingSeconds, 0)
    }

    private var brewTimerPrimaryActionTitle: String {
        if isBrewTimerRunning {
            return AppLocalization.text("pause", fallback: "Pause")
        }

        if brewTimerRemainingSeconds == selectedBrewTimerSeconds {
            return AppLocalization.text("start", fallback: "Start")
        }

        if brewTimerRemainingSeconds == 0 {
            return AppLocalization.text("brew_again", fallback: "Brew Again")
        }

        return AppLocalization.text("resume", fallback: "Resume")
    }

    private var brewTimerCueText: String {
        let elapsed = brewTimerElapsedSeconds
        let method = selectedBrewTimerName.lowercased()

        if brewTimerRemainingSeconds == 0 {
            return AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly.")
        }

        if method.contains("cold") {
            if elapsed < 60 {
                return AppLocalization.text("cold_timer_cue_saturate", fallback: "Saturate the grounds")
            }
            if elapsed < 43_000 {
                return AppLocalization.text("cold_timer_cue_steep", fallback: "Steep slowly")
            }
            return AppLocalization.text("cold_timer_cue_filter", fallback: "Filter and serve chilled")
        }

        if method.contains("arabic") {
            if elapsed < 90 {
                return AppLocalization.text("arabic_timer_cue_heat", fallback: "Heat the water")
            }
            if elapsed < 180 {
                return AppLocalization.text("arabic_timer_cue_add", fallback: "Add coffee and spices")
            }
            if elapsed < 360 {
                return AppLocalization.text("arabic_timer_cue_simmer", fallback: "Simmer gently")
            }
            return AppLocalization.text("arabic_timer_cue_settle", fallback: "Let it settle")
        }

        if method.contains("press") {
            if elapsed < 30 {
                return AppLocalization.text("press_timer_cue_pour", fallback: "Pour and saturate")
            }
            if elapsed < 210 {
                return AppLocalization.text("press_timer_cue_steep", fallback: "Let it steep")
            }
            return AppLocalization.text("press_timer_cue_plunge", fallback: "Press slowly")
        }

        if elapsed < 30 {
            return AppLocalization.text("pour_timer_cue_bloom", fallback: "Blooming")
        }
        if elapsed < 45 {
            return AppLocalization.text("pour_timer_cue_bloom_done", fallback: "Bloom complete")
        }
        if elapsed < 90 {
            return AppLocalization.text("pour_timer_cue_second_pour", fallback: "Begin second pour")
        }
        if elapsed < 165 {
            return AppLocalization.text("pour_timer_cue_drawdown", fallback: "Drawdown should start now")
        }
        return AppLocalization.text("pour_timer_cue_finish", fallback: "Let it finish")
    }

    private func tickBrewTimer() {
        guard isBrewTimerRunning else { return }
        guard brewTimerRemainingSeconds > 0 else {
            isBrewTimerRunning = false
            return
        }

        brewTimerRemainingSeconds -= 1

        if brewTimerRemainingSeconds == 0 {
            isBrewTimerRunning = false
            delightFeedbackTrigger += 1
            showToast(message: AppLocalization.text("brew_timer_done", fallback: "Brew timer done"))
        }
    }

    private func startBrewTimer() {
        if brewTimerRemainingSeconds == 0 {
            brewTimerRemainingSeconds = selectedBrewTimerSeconds
        }

        let runID = UUID()
        brewTimerRunID = runID
        isBrewTimerRunning = true
        delightFeedbackTrigger += 1

        Task { @MainActor in
            while isBrewTimerRunning && brewTimerRunID == runID && brewTimerRemainingSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard isBrewTimerRunning, brewTimerRunID == runID else { return }
                tickBrewTimer()
            }
        }
    }

    private func resetBrewTimer() {
        brewTimerRunID = UUID()
        brewTimerRemainingSeconds = selectedBrewTimerSeconds
        isBrewTimerRunning = false
    }

    private func formattedTimerTime(_ seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60
        let remainingSeconds = seconds % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        }

        return String(format: "%d:%02d", minutes, remainingSeconds)
    }

    private func persistCoffeeJournalEntries(_ entries: [BrewJournalEntry]) {
        guard let data = try? JSONEncoder().encode(entries),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        savedBrewJournal = json
    }

    private func saveCoffeeJournalEntry() {
        let title = journalTitleInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let method = journalMethodInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = journalNotesInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty || !notes.isEmpty else {
            showToast(message: AppLocalization.text("journal_needs_note", fallback: "Add a coffee name or note first"))
            return
        }

        let entry = BrewJournalEntry(
            id: UUID(),
            title: title.isEmpty ? defaultBrewRecipeName() : title,
            method: method.isEmpty ? selectedBrewTimerName : method,
            coffeeGrams: journalCoffeeGrams,
            ratio: journalRatio,
            waterGrams: journalWaterGrams,
            brewTimeSeconds: journalBrewTimeSeconds,
            rating: journalRating,
            notes: notes,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        persistCoffeeJournalEntries(Array(([entry] + brewJournalEntries).prefix(20)))
        journalTitleInput = ""
        journalNotesInput = ""
        clearJournalBrewDetails()
        showToast(message: AppLocalization.text("journal_saved_toast", fallback: "Coffee note saved"))
    }

    private func prepareJournalEntryFromGuidedBrew(method: BrewingMethod?, coffeeAmount: Double, ratio: Double, waterAmount: Double, brewTime: Int) {
        let methodName = method?.name ?? (activeBrewingCategory == "All" ? selectedBrewTimerName : activeBrewingCategory)
        let recipeName = methodName.isEmpty ? defaultBrewRecipeName() : methodName

        journalTitleInput = recipeName
        journalMethodInput = methodName
        journalCoffeeGrams = coffeeAmount
        journalRatio = ratio
        journalWaterGrams = waterAmount
        journalBrewTimeSeconds = brewTime
        journalNotesInput = ""
        brewRecipeName = recipeName
        showToast(message: AppLocalization.text("guided_brew_journal_ready", fallback: "Journal entry prepared"))
    }

    private var journalBrewDetailLine: String? {
        guard let coffeeGrams = journalCoffeeGrams,
              let ratio = journalRatio,
              let waterGrams = journalWaterGrams,
              let brewTimeSeconds = journalBrewTimeSeconds else {
            return nil
        }

        return brewJournalDetailLine(
            coffeeGrams: coffeeGrams,
            ratio: ratio,
            waterGrams: waterGrams,
            brewTimeSeconds: brewTimeSeconds
        )
    }

    private func brewJournalDetailLine(for entry: BrewJournalEntry) -> String? {
        guard let coffeeGrams = entry.coffeeGrams,
              let ratio = entry.ratio,
              let waterGrams = entry.waterGrams,
              let brewTimeSeconds = entry.brewTimeSeconds else {
            return nil
        }

        return brewJournalDetailLine(
            coffeeGrams: coffeeGrams,
            ratio: ratio,
            waterGrams: waterGrams,
            brewTimeSeconds: brewTimeSeconds
        )
    }

    private func brewJournalDetailLine(coffeeGrams: Double, ratio: Double, waterGrams: Double, brewTimeSeconds: Int) -> String {
        [
            "\(formattedRatioValue(coffeeGrams)) g coffee",
            "1:\(formattedRatioValue(ratio))",
            "\(formattedRatioValue(waterGrams)) g water",
            formattedTimerTime(brewTimeSeconds)
        ].joined(separator: " - ")
    }

    private func clearJournalBrewDetails() {
        journalCoffeeGrams = nil
        journalRatio = nil
        journalWaterGrams = nil
        journalBrewTimeSeconds = nil
    }

    private func deleteCoffeeJournalEntry(_ entry: BrewJournalEntry) {
        persistCoffeeJournalEntries(brewJournalEntries.filter { $0.id != entry.id })
        showToast(message: AppLocalization.text("journal_deleted_toast", fallback: "Coffee note deleted"))
    }

    private func saveCurrentBrewRecipe() {
        guard ratioCoffeeAmount > 0, ratioValue > 0 else {
            showToast(message: AppLocalization.text("enter_valid_brew_recipe", fallback: "Enter a valid brew recipe first"))
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
        showToast(message: AppLocalization.text("brew_recipe_saved_toast", fallback: "Brew recipe saved"))
    }

    private func applyBrewRecipe(_ recipe: BrewRecipe) {
        ratioCoffeeInput = formattedRatioValue(recipe.coffeeGrams)
        ratioValueInput = formattedRatioValue(recipe.ratio)
        openBrewing()
        showToast(message: String(format: AppLocalization.text("recipe_loaded_toast", fallback: "%@ loaded"), recipe.name))
    }

    private func deleteBrewRecipe(_ recipe: BrewRecipe) {
        persistBrewRecipes(brewRecipes.filter { $0.id != recipe.id })
        showToast(message: AppLocalization.text("brew_recipe_deleted_toast", fallback: "Brew recipe deleted"))
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
            showToast(message: AppLocalization.text("add_items_before_saving_cart", fallback: "Add items before saving a bag"))
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
        isCartSaveEntryExpanded = false
        showToast(message: AppLocalization.text("cart_saved_toast", fallback: "Bag saved"))
    }

    private func applySavedCart(_ savedCart: SavedCart) {
        let matchedItems = savedCart.items.compactMap { item -> (Product, Int)? in
            if let product = products.first(where: { $0.id == item.productID }) ?? matchingProduct(for: item.productName) {
                return (product, item.quantity)
            }

            return nil
        }

        guard !matchedItems.isEmpty else {
            showToast(message: AppLocalization.text("saved_cart_unavailable", fallback: "Saved bag items are unavailable right now"))
            return
        }

        cartItems = []
        for (product, quantity) in matchedItems {
            guard let variant = selectedVariant(for: product) else { continue }
            cartItems.append(
                CartItem(
                    id: cartItemIdentifier(productID: product.id, variantID: variant.id),
                    product: product,
                    variant: variant,
                    quantity: quantity
                )
            )
        }

        cartOpen = true
        showToast(message: String(format: AppLocalization.text("saved_cart_loaded_toast", fallback: "%@ loaded"), savedCart.name))
    }

    private func deleteSavedCart(_ savedCart: SavedCart) {
        persistSavedCarts(savedCarts.filter { $0.id != savedCart.id })
        showToast(message: AppLocalization.text("saved_cart_deleted_toast", fallback: "Saved bag deleted"))
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
            showToast(message: AppLocalization.text("removed_from_favorites", fallback: "Removed from favorites"))
        } else {
            updatedFavorites.insert(product.id)
            showToast(message: AppLocalization.text("saved_to_favorites", fallback: "Saved to favorites"))
        }

        delightFeedbackTrigger += 1
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
            showToast(message: AppLocalization.text("removed_from_alerts", fallback: "Removed from alerts"))
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
                showToast(message: AppLocalization.text("alert_notification_scheduled", fallback: "Alert saved. Notification reminder scheduled."))
            } else {
                showToast(message: AppLocalization.text("added_to_alerts_notifications_off", fallback: "Alert saved. Notifications are not enabled."))
            }
        }

        delightFeedbackTrigger += 1
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
            return AppLocalization.text("alert_label_back_in_stock", fallback: "Back in stock watch")
        }

        if let tag = product.tag, !tag.isEmpty {
            return String(format: AppLocalization.text("alert_label_tag_watch", fallback: "%@ watch"), tag)
        }

        return AppLocalization.text("alert_label_new_roast", fallback: "New roast watch")
    }

    private func stockAlertLabel(for product: Product) -> String {
        backendStockAlertLookup[product.id]?.status ?? productAlertLabel(for: product)
    }

    private func notificationTitle(for product: Product) -> String {
        if !product.isAvailableForSale {
            return String(format: AppLocalization.text("notification_title_watchlist", fallback: "%@ watchlist reminder"), product.name)
        }

        return String(format: AppLocalization.text("notification_title_roast", fallback: "%@ roast reminder"), product.name)
    }

    private func notificationBody(for product: Product) -> String {
        if !product.isAvailableForSale {
            return String(format: AppLocalization.text("notification_body_unavailable", fallback: "You asked to hear about %@. Check Talla for availability updates."), product.name)
        }

        return String(format: AppLocalization.text("notification_body_available", fallback: "Still thinking about %@? Your watched roast is waiting in the app."), product.name)
    }

    @MainActor
    private func refreshNotificationStatus() async {
#if canImport(UserNotifications)
        let status = await ProductAlertNotificationService.authorizationStatus()
        notificationAuthorizationStatus = status.rawValue
        if status == .authorized || status == .provisional {
            registerForRemoteNotifications()
        }
#endif
    }

    @MainActor
    private func requestNotificationAccess() async {
        let granted = await ProductAlertNotificationService.requestAuthorization()
        await refreshNotificationStatus()

        if granted {
            registerForRemoteNotifications()
            await syncRemotePushTokenIfPossible()
            showToast(message: AppLocalization.text("notifications_enabled", fallback: "Notifications enabled"))
        } else {
            showToast(message: AppLocalization.text("notifications_not_enabled", fallback: "Notifications not enabled"))
        }
    }

    @MainActor
    private func requestInitialNotificationAccessIfNeeded() async {
#if canImport(UserNotifications)
        guard !hasAskedInitialNotificationPermission else { return }

        let status = await ProductAlertNotificationService.authorizationStatus()
        notificationAuthorizationStatus = status.rawValue
        guard status == .notDetermined else {
            hasAskedInitialNotificationPermission = true
            return
        }

        hasAskedInitialNotificationPermission = true
        let granted = await ProductAlertNotificationService.requestAuthorization()
        await refreshNotificationStatus()

        if granted {
            registerForRemoteNotifications()
            await syncRemotePushTokenIfPossible()
        }
#endif
    }

    @MainActor
    private func requestNotificationAccessIfNeeded() async -> Bool {
#if canImport(UserNotifications)
        let status = await ProductAlertNotificationService.authorizationStatus()
        notificationAuthorizationStatus = status.rawValue

        switch status {
        case .authorized, .provisional:
            registerForRemoteNotifications()
            await syncRemotePushTokenIfPossible()
            return true
        case .notDetermined:
            let granted = await ProductAlertNotificationService.requestAuthorization()
            await refreshNotificationStatus()
            if granted {
                registerForRemoteNotifications()
                await syncRemotePushTokenIfPossible()
            }
            return granted
        default:
            return false
        }
#else
        return false
#endif
    }

    @MainActor
    private func registerForRemoteNotifications() {
#if canImport(UIKit)
        UIApplication.shared.registerForRemoteNotifications()
#endif
    }

    @MainActor
    private func unregisterRemoteNotifications() {
#if canImport(UIKit)
        UIApplication.shared.unregisterForRemoteNotifications()
#endif
    }

    private func copyPushDeviceToken() {
        let token = savedPushDeviceToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            showToast(message: AppLocalization.text("push_token_waiting", fallback: "No APNs device token yet. Enable notifications on a real device to create one."))
            return
        }

#if canImport(UIKit)
        UIPasteboard.general.string = token
        showToast(message: AppLocalization.text("device_token_copied", fallback: "Device token copied"))
#else
        showToast(message: token)
#endif
    }

    @MainActor
    private func syncRemotePushTokenIfPossible() async {
        let normalizedToken = savedPushDeviceToken
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalizedToken.isEmpty else { return }

        let status = notificationAuthorizationStatus
        let notificationsEnabled = status == UNAuthorizationStatus.authorized.rawValue
            || status == UNAuthorizationStatus.provisional.rawValue
        guard notificationsEnabled else { return }

        let email = (customerProfile?.email ?? savedCustomerEmail)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !email.isEmpty else { return }

        if savedRegisteredPushDeviceEmail == email && savedRegisteredPushDeviceToken == normalizedToken {
            return
        }

        do {
            try await AccountService.registerPushDeviceToken(email: email, deviceToken: normalizedToken)
            savedRegisteredPushDeviceEmail = email
            savedRegisteredPushDeviceToken = normalizedToken
        } catch {
            return
        }
    }

    private func unregisterRemotePushToken(email: String?, accessToken: String) {
        let normalizedToken = savedPushDeviceToken
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let normalizedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !normalizedToken.isEmpty, !normalizedEmail.isEmpty, !accessToken.isEmpty else { return }

        Task {
            try? await AccountService.unregisterPushDeviceToken(
                email: normalizedEmail,
                deviceToken: normalizedToken,
                accessTokenOverride: accessToken
            )
        }
    }

    private func buyAgain(order: AccountOrder) {
        guard let items = order.items, !items.isEmpty else { return }

        let matchedProducts = items.compactMap { item -> (Product, Int)? in
            guard let product = matchingProduct(for: item.name) else { return nil }
            return (product, item.quantity)
        }

        guard !matchedProducts.isEmpty else {
            showToast(message: AppLocalization.text("items_unavailable_currently", fallback: "Those items are currently unavailable"))
            return
        }

        for (product, quantity) in matchedProducts {
            guard let variant = selectedVariant(for: product) else { continue }
            let cartItemID = cartItemIdentifier(productID: product.id, variantID: variant.id)
            if let index = cartItems.firstIndex(where: { $0.id == cartItemID }) {
                updateCartItemQuantity(at: index, quantity: cartItems[index].quantity + quantity)
            } else {
                cartItems.append(CartItem(id: cartItemID, product: product, variant: variant, quantity: quantity))
            }
        }

        checkoutError = nil
        cartOpen = true

        if matchedProducts.count == items.count {
            showToast(message: AppLocalization.text("order_added_to_cart", fallback: "Order added to bag"))
        } else {
            showToast(message: AppLocalization.text("available_items_added_from_order", fallback: "Available items from that order were added"))
        }
    }

    private func saveTasteMemory(order: AccountOrder, item: AccountOrder.Item, reaction: String, tags: [String]) {
        let record = TasteMemoryRecord(
            id: tasteMemoryKey(order: order, item: item),
            orderID: order.id,
            productName: item.name,
            reaction: reaction,
            tags: tags,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: nil
        )
        let existing = tasteMemoryRecords.filter { $0.id != record.id }
        let updated = Array(([record] + existing).prefix(80))

        persistTasteMemoryRecords(updated)
        delightFeedbackTrigger += 1
        showToast(message: AppLocalization.text("taste_memory_saved", fallback: "Taste memory saved"))

        if let profile = customerProfile {
            Task {
                do {
                    _ = try await AccountService.saveTasteMemory(
                        email: profile.email,
                        orderID: order.id,
                        productName: item.name,
                        reaction: reaction,
                        tags: tags
                    )
                    let remoteTasteMemory = try await AccountService.fetchTasteMemory(email: profile.email)
                    await MainActor.run {
                        persistTasteMemoryRecords(remoteTasteMemory)
                    }
                } catch {
                    return
                }
            }
        }
    }

    private func persistTasteMemoryRecords(_ records: [TasteMemoryRecord]) {
        let sortedRecords = records
            .sorted {
                let lhsDate = ISO8601DateFormatter().date(from: $0.updatedAt ?? $0.createdAt) ?? .distantPast
                let rhsDate = ISO8601DateFormatter().date(from: $1.updatedAt ?? $1.createdAt) ?? .distantPast
                return lhsDate > rhsDate
            }
        var seenRecordIDs = Set<String>()
        let uniqueRecords = Array(sortedRecords.filter { record in
            guard !seenRecordIDs.contains(record.id) else { return false }
            seenRecordIDs.insert(record.id)
            return true
        }.prefix(80))

        guard let data = try? JSONEncoder().encode(uniqueRecords),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        savedTasteMemory = json
    }

    private func matchingProduct(for orderItemName: String) -> Product? {
        let normalizedOrderName = normalizedProductName(orderItemName)

        return products.first { normalizedProductName($0.name) == normalizedOrderName }
            ?? products.first {
                let normalizedProduct = normalizedProductName($0.name)
                return normalizedProduct.contains(normalizedOrderName) || normalizedOrderName.contains(normalizedProduct)
            }
    }

    private func tasteMemoryKey(order: AccountOrder, item: AccountOrder.Item) -> String {
        "\(order.id)-\(normalizedProductName(item.name))"
    }

    private func tastePreferenceScore(for product: Product) -> Int {
        let productText = normalizedSearchText(for: product)

        return tasteMemoryRecords.reduce(0) { score, record in
            let tagScore = record.tags.reduce(0) { partialResult, tag in
                partialResult + (productText.contains(tag.lowercased()) ? 3 : 0)
            }
            let reactionScore = record.reaction == "loved" ? tagScore : -tagScore
            let productPenalty = record.reaction == "not-for-me" && normalizedProductName(record.productName) == normalizedProductName(product.name) ? -8 : 0
            return score + reactionScore + productPenalty
        }
    }

    private func daysSinceOrder(_ order: AccountOrder) -> Int {
        let startOfOrderDay = Calendar.current.startOfDay(for: orderDate(from: order.createdAt))
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return max(Calendar.current.dateComponents([.day], from: startOfOrderDay, to: startOfToday).day ?? 0, 0)
    }

    private func orderDate(from value: String) -> Date {
        if let date = ISO8601DateFormatter().date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        if let date = formatter.date(from: value) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? .distantPast
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
            voucherError = AppLocalization.text("sign_in_to_apply_voucher", fallback: "Sign in to apply a loyalty voucher.")
            return
        }

        let trimmedCode = voucherCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedCode.isEmpty else {
            voucherError = AppLocalization.text("enter_voucher_code_first", fallback: "Enter a voucher code first.")
            return
        }

        isApplyingVoucher = true
        voucherError = nil

        do {
            appliedVoucher = try await AccountService.previewVoucher(code: trimmedCode, email: profile.email)
            voucherCodeInput = trimmedCode
            await loadAvailableVouchers(for: profile.email)
            showToast(message: AppLocalization.text("voucher_applied_toast", fallback: "Voucher applied"))
        } catch {
            appliedVoucher = nil
            voucherError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("voucher_apply_failed", fallback: "This voucher could not be applied right now.")
            )
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
        guard let selectedPaymentMethod = paymentFlow.selectedMethod else {
            isPaymentMethodSheetPresented = true
            return
        }
        guard !isCheckingOut, paymentFlow.begin() else { return }

        guard !cartItems.isEmpty else {
            paymentFlow.transition(to: .failed)
            checkoutError = AppLocalization.text("cart_no_purchasable_items", fallback: "Your bag has no purchasable items.")
            return
        }

        guard let profile = customerProfile else {
            paymentFlow.transition(to: .failed)
            checkoutError = AppLocalization.text("sign_in_before_checkout", fallback: "Sign in before checkout.")
            return
        }

        isCheckingOut = true
        checkoutError = nil

        do {
            if selectedPaymentMethod.route == .shopifyCashOnDelivery {
                guard appliedVoucher == nil else {
                    throw LoyaltyServiceError.operationFailed("Remove the Talla voucher before using Shopify Checkout so the verified totals stay identical.")
                }
                let lines = cartItems.map { ShopifyCheckoutLine(merchandiseId: $0.variant.id, quantity: $0.quantity) }
                let checkoutAddress = preferredAddress.map { address in
                    ShopifyCheckoutAddress(
                        email: profile.email,
                        fullName: address.fullName,
                        phone: address.phone,
                        address1: address.line1,
                        city: address.city,
                        country: address.country.rawValue
                    )
                }
                let checkoutURL = try await ShopifyStorefrontClient.createCheckoutURL(
                    lines: lines,
                    customerEmail: profile.email,
                    checkoutAddress: checkoutAddress
                )
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                checkoutSession = CheckoutSession(url: checkoutURL)
                showToast(message: "Choose Cash on Delivery in Shopify Checkout to place your order.")
                isCheckingOut = false
                return
            }

            if let appliedVoucher {
                _ = try await AccountService.consumeVoucher(code: appliedVoucher.code, email: profile.email)
                await loadAvailableVouchers(for: profile.email)
            }

            let checkoutItems = cartItems.map { item in
                (
                    name: item.product.name,
                    quantity: item.quantity,
                    variantID: item.variant.id
                )
            }
            let checkoutStart = try await AccountService.recordCheckoutStarted(
                email: profile.email,
                items: checkoutItems,
                total: cartTotal
            )
            orderHistory = checkoutStart.orders

            switch selectedPaymentMethod.route {
            case .benefitHosted:
                let paymentURL = try await AccountService.createBenefitPayment(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                checkoutSession = CheckoutSession(url: paymentURL)
            case .benefitPaySDK:
                guard BenefitPaySDKConfiguration.isAvailable else {
                    throw PaymentServiceError.gateway("BenefitPay is not configured in this build.")
                }
                let session = try await BenefitPayService.createSession(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                benefitPaySession = session
            case .cardGateway:
                guard MastercardSDKAvailability.isAvailable else {
                    throw PaymentServiceError.gateway("Gateway.xcframework and uSDK.xcframework are required for card entry and 3-D Secure.")
                }
                let session = try await TallaPaymentService.createCardSession(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                mastercardPaymentContext = MastercardPaymentContext(
                    localOrderID: checkoutStart.orderID,
                    session: session,
                    kind: .card
                )
            case .applePayGateway:
                guard isApplePayAvailable else {
                    throw PaymentServiceError.gateway("Apple Pay is unavailable on this device.")
                }
                guard MastercardSDKAvailability.isAvailable else {
                    throw PaymentServiceError.gateway("Gateway.xcframework and uSDK.xcframework are required for Apple Pay gateway tokenization.")
                }
                let session = try await TallaPaymentService.createApplePaySession(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                mastercardPaymentContext = MastercardPaymentContext(
                    localOrderID: checkoutStart.orderID,
                    session: session,
                    kind: .applePay
                )
            case .shopifyCashOnDelivery:
                break
            }
            appliedVoucher = nil
            voucherCodeInput = ""
            voucherError = nil
            showToast(message: AppLocalization.text("checkout_opened_toast", fallback: "Checkout opened. Return to Talla after payment."))
        } catch {
            paymentFlow.transition(to: .failed, error: error.localizedDescription)
            if isExpiredCustomerSessionError(error) {
                signOutCustomer(clearError: false)
                checkoutError = AppLocalization.text(
                    "checkout_session_expired",
                    fallback: "Your session expired. Sign in again to continue checkout."
                )
            } else {
                checkoutError = customerFacingServiceMessage(
                    for: error,
                    fallback: AppLocalization.text("checkout_start_failed", fallback: "Checkout could not be started right now. Your bag is still saved.")
                )
            }
        }

        isCheckingOut = false
    }

    @MainActor
    private func addLoyaltyPassToWallet() async {
#if canImport(PassKit)
        guard PKPassLibrary.isPassLibraryAvailable() else {
            showToast(message: AppLocalization.text("apple_wallet_unavailable", fallback: "Apple Wallet is unavailable on this device"))
            return
        }

        guard let email = customerProfile?.email ?? (!savedLoyaltyEmail.isEmpty ? savedLoyaltyEmail : nil) else {
            showToast(message: AppLocalization.text("sign_in_before_wallet_pass", fallback: "Sign in before adding your Wallet pass"))
            return
        }

        isLoadingWalletPass = true

        do {
            let pass = try await AccountService.fetchWalletPass(email: email)
            let library = PKPassLibrary()
            if library.containsPass(pass) {
                isLoyaltyPassInWallet = true
                showToast(message: AppLocalization.text("wallet_pass_already_added", fallback: "Loyalty card is already in Apple Wallet"))
            } else {
                loyaltyWalletPass = WalletPassItem(pass: pass)
            }
        } catch {
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("wallet_pass_failed", fallback: "Wallet pass could not be loaded right now.")
            ))
        }

        isLoadingWalletPass = false
#else
        showToast(message: AppLocalization.text("apple_wallet_unavailable", fallback: "Apple Wallet is unavailable on this device"))
#endif
    }

    private func syncWidgetSharedState(reload: Bool) {
        let defaults = TallaWidgetSharedState.defaults
        defaults.set(savedLoyaltyEmail, forKey: TallaWidgetSharedState.loyaltyEmailKey)
        defaults.set(savedFavoriteProductIDs, forKey: TallaWidgetSharedState.favoriteProductIDsKey)
        defaults.set(savedRecentlyViewedProductIDs, forKey: TallaWidgetSharedState.recentlyViewedProductIDsKey)
        defaults.set(savedCartsPayload, forKey: TallaWidgetSharedState.savedCartsKey)
        defaults.set(favoriteProductIDs.count, forKey: TallaWidgetSharedState.favoriteCountKey)
        defaults.set(recentlyViewedProductIDs.count, forKey: TallaWidgetSharedState.recentCountKey)
        defaults.set(savedCarts.count, forKey: TallaWidgetSharedState.savedCartCountKey)
        defaults.set(appLanguage.effectiveLanguageCode, forKey: TallaWidgetSharedState.languageKey)
        defaults.set(loyaltyAccount?.pointsBalance ?? 0, forKey: TallaWidgetSharedState.loyaltyPointsKey)
        defaults.set(loyaltyAccount?.tier ?? "Reserve", forKey: TallaWidgetSharedState.loyaltyTierKey)
        defaults.set(loyaltyAccount?.nextReward ?? "Check rewards in app", forKey: TallaWidgetSharedState.loyaltyNextRewardKey)
        defaults.set(loyaltyAccount?.memberID ?? "", forKey: TallaWidgetSharedState.loyaltyMemberIDKey)
        defaults.set(Date().timeIntervalSince1970, forKey: TallaWidgetSharedState.lastUpdatedKey)

        if reload {
            TallaWidgetSharedState.reloadWidget()
        }
    }

    private func showToast(message: String) {
        toastMessage = nil
    }

    private func categoryDefinition(for key: String) -> ShopCategory {
        if key == "tea" || key == "drinks" {
            return categoryDefinition(for: "ready-made-drinks")
        }

        if key == "drink-cups" || key == "mugs" || key == "drinkware" {
            return categoryDefinition(for: "cups")
        }

        if key == "northern-coffee" {
            return categoryDefinition(for: "arabic-coffee-beans")
        }

        if key == "bread" || key == "crmb-tallas-speciality-bakery" {
            return categoryDefinition(for: "desserts")
        }

        if key == "other" {
            return categoryDefinition(for: "arabic-coffee-beans")
        }

        if let category = categoryCatalog.first(where: { $0.key == key }) {
            return localizedCategory(category)
        }

        let normalizedKey = key.replacingOccurrences(of: "_", with: "-")

        return ShopCategory(
            key: key,
            title: categoryLabel(for: key),
            subtitle: normalizedKey.contains("drink") ? "Ready-to-enjoy picks" : "Curated Talla selection",
            symbol: categorySymbol(for: normalizedKey)
        )
    }

    private func categoryLabel(for key: String) -> String {
        guard key != "all" else { return AppLocalization.text("category_all", fallback: "All") }
        if key == "summer-drinks" {
            return AppLocalization.text("category_summer_drinks", fallback: "Summer Drinks")
        }
        if key == "coffee-beans" {
            return AppLocalization.text("category_coffee_beans", fallback: "Coffee Beans")
        }
        if key == "arabic-coffee-beans" || key == "northern-coffee" || key == "other" {
            return AppLocalization.text("category_arabic_coffee", fallback: "Arabic & Shamali Coffee")
        }
        if key == "drip-bags" {
            return AppLocalization.text("category_drip_bags", fallback: "Drip Bags")
        }
        if key == "coffee-equipment" {
            return AppLocalization.text("category_equipment", fallback: "Equipment")
        }
        if key == "ready-made-drinks" || key == "tea" || key == "drinks" {
            return AppLocalization.text("category_ready_drinks", fallback: "Drinks")
        }
        if key == "cups" || key == "drink-cups" || key == "mugs" || key == "drinkware" {
            return AppLocalization.text("category_cups", fallback: "Cups")
        }
        if key == "crmb-tallas-speciality-bakery" || key == "desserts" || key == "bread" {
            return AppLocalization.text("category_desserts", fallback: "CRMB")
        }
        if key == "spreads" {
            return AppLocalization.text("category_spreads", fallback: "Spreads")
        }
        if key == "hot-chocolate" {
            return AppLocalization.text("category_hot_chocolate", fallback: "Hot Chocolate")
        }
        if key == "gifts" {
            return AppLocalization.text("category_gifts", fallback: "Talla Boxes")
        }
        return key
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    private func categorySymbol(for key: String) -> String {
        if key.contains("summer") {
            return "sun.max.fill"
        }

        if key.contains("bean") || key.contains("coffee") {
            return "leaf.fill"
        }

        if key.contains("drip") {
            return "drop.fill"
        }

        if key.contains("equipment") {
            return "flask.fill"
        }

        if key.contains("cup") {
            return "mug.fill"
        }

        if key.contains("drink") {
            return "takeoutbag.and.cup.and.straw.fill"
        }

        if key.contains("tea") {
            return "teapot.fill"
        }

        if key.contains("dessert") || key.contains("bread") {
            return "birthday.cake.fill"
        }

        if key.contains("spread") || key.contains("jam") || key.contains("butter") {
            return "takeoutbag.and.cup.and.straw.fill"
        }

        if key.contains("chocolate") {
            return "takeoutbag.and.cup.and.straw.fill"
        }

        if key.contains("gift") {
            return "gift.fill"
        }

        return "shippingbox.fill"
    }

    private func bundledLoyaltyPass() -> PKPass? {
        guard let passURL = Bundle.main.url(forResource: "TallaLoyalty", withExtension: "pkpass"),
              let data = try? Data(contentsOf: passURL),
              let pass = try? PKPass(data: data) else {
            return nil
        }

        return pass
    }

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

private enum HomeSettingsService {
    private static let baseURL = BackendConfiguration.serviceBaseURL

    static func fetchHomeSettings() async throws -> ContentView.HomeSettings {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Home settings service"))
        }

        var request = URLRequest(url: baseURL.appending(path: "/app/home-settings"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The home settings service returned an invalid response.")
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            throw ContentView.LoyaltyServiceError.operationFailed("The home settings service could not complete your request.")
        }

        return try JSONDecoder().decode(ContentView.HomeSettings.self, from: data)
    }

    static func fetchPassportSettings() async throws -> ContentView.PassportSettings {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed(BackendConfiguration.unavailableMessage(for: "Passport settings service"))
        }

        var request = URLRequest(url: baseURL.appending(path: "/app/passport-settings"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The passport settings service returned an invalid response.")
        }

        guard 200 ..< 300 ~= httpResponse.statusCode else {
            throw ContentView.LoyaltyServiceError.operationFailed("The passport settings service could not complete your request.")
        }

        return try JSONDecoder().decode(ContentView.PassportSettings.self, from: data)
    }
}

private enum AccountService {
    private static let baseURL = BackendConfiguration.serviceBaseURL
    private static let sessionTokenKey = "local.customerAccessToken"

    struct CustomerSession {
        let profile: ContentView.ShopifyCustomerProfile
        let accessToken: String
        let expiresAt: String
    }

    struct CheckoutStartResult {
        let orderID: String
        let orders: [ContentView.AccountOrder]
    }

    private static var accessToken: String {
        UserDefaults.standard.string(forKey: sessionTokenKey) ?? ""
    }

    fileprivate static func authorize(_ request: inout URLRequest, accessTokenOverride: String? = nil) throws {
        let token = (accessTokenOverride ?? accessToken).trimmingCharacters(in: .whitespacesAndNewlines)
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

    static func signInWithApple(
        identityToken: String,
        userIdentifier: String,
        email: String?,
        firstName: String?,
        lastName: String?,
        nonce: String
    ) async throws -> CustomerSession {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var payload: [String: Any] = [
            "identityToken": identityToken,
            "userIdentifier": userIdentifier,
            "nonce": nonce
        ]

        if let email, !email.isEmpty {
            payload["email"] = email
        }

        if let firstName, !firstName.isEmpty {
            payload["firstName"] = firstName
        }

        if let lastName, !lastName.isEmpty {
            payload["lastName"] = lastName
        }

        var request = URLRequest(url: baseURL.appending(path: "/accounts/apple"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

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

    static func fetchTasteMemory(email: String) async throws -> [ContentView.TasteMemoryRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var components = URLComponents(url: baseURL.appending(path: "/taste-memory"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "email", value: email)]

        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The taste memory service URL is invalid.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)

        return try await performTasteMemoryRequest(request)
    }

    static func saveTasteMemory(email: String, orderID: String, productName: String, reaction: String, tags: [String]) async throws -> [ContentView.TasteMemoryRecord] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The account service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/taste-memory/save"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "orderID": orderID,
            "productName": productName,
            "reaction": reaction,
            "tags": tags
        ])

        return try await performTasteMemoryEnvelopeRequest(request)
    }

    static func recordCheckoutStarted(
        email: String,
        items: [(name: String, quantity: Int, variantID: String)],
        total: Double
    ) async throws -> CheckoutStartResult {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service is unavailable.")
        }

        let orderItems = items.map { item in
            [
                "name": item.name,
                "quantity": item.quantity,
                "variantId": item.variantID
            ] as [String: Any]
        }

        var request = URLRequest(url: baseURL.appending(path: "/orders/checkout-started"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "title": "Checkout started",
            "total": total,
            "items": orderItems
        ])

        return try await performCheckoutStartRequest(request)
    }

    static func createBenefitPayment(orderID: String) async throws -> URL {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/api/payments/benefit/create"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "orderID": orderID
        ])

        return try await performBenefitPaymentRequest(request)
    }

    static func createEazyShopifyPaymentSession(tallaPaymentID: String) async throws -> EazyShopifyPaymentResponse {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service is unavailable.")
        }
        var request = URLRequest(url: baseURL.appending(path: "/api/payments/eazy/shopify/session"))
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: ["tallaPaymentId": tallaPaymentID])
        return try await performEazyShopifyPaymentRequest(request)
    }

    static func fetchEazyShopifyPaymentStatus(tallaPaymentID: String) async throws -> EazyShopifyPaymentResponse {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service is unavailable.")
        }
        var components = URLComponents(url: baseURL.appending(path: "/api/payments/eazy/shopify/status"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "tallaPaymentId", value: tallaPaymentID)]
        guard let url = components?.url else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment status URL is invalid.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        try authorize(&request)
        return try await performEazyShopifyPaymentRequest(request)
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

    static func registerPushDeviceToken(email: String, deviceToken: String) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The notifications service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/notifications/push/register"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "deviceToken": deviceToken,
            "platform": "ios"
        ])

        _ = try await performEmptyRequest(request)
    }

    static func unregisterPushDeviceToken(
        email: String,
        deviceToken: String,
        accessTokenOverride: String? = nil
    ) async throws {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The notifications service is unavailable.")
        }

        var request = URLRequest(url: baseURL.appending(path: "/notifications/push/unregister"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        try authorize(&request, accessTokenOverride: accessTokenOverride)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "deviceToken": deviceToken
        ])

        _ = try await performEmptyRequest(request)
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

    static func saveAddress(email: String, label: String, fullName: String, phone: String, line1: String, city: String, countryCode: String, notes: String?) async throws -> [ContentView.DeliveryAddress] {
        guard let baseURL else {
            throw ContentView.LoyaltyServiceError.operationFailed("The address service is unavailable.")
        }

        var payload: [String: Any] = [
            "email": email,
            "label": label,
            "fullName": fullName,
            "phone": phone,
            "line1": line1,
            "city": city,
            "countryCode": countryCode
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
            return try await Task.detached(priority: .userInitiated) {
                guard let pass = try? PKPass(data: data) else {
                    throw ContentView.LoyaltyServiceError.operationFailed("The Wallet pass could not be loaded.")
                }
                return pass
            }.value
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

    private static func performCheckoutStartRequest(_ request: URLRequest) async throws -> CheckoutStartResult {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The orders service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            let decoded = try JSONDecoder().decode(CheckoutStartResponse.self, from: data)
            return CheckoutStartResult(orderID: decoded.orderID, orders: decoded.orders)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The orders service could not complete your request.")
    }

    private static func performBenefitPaymentRequest(_ request: URLRequest) async throws -> URL {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            let decoded = try JSONDecoder().decode(BenefitPaymentResponse.self, from: data)
            return decoded.paymentUrl
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The payment service could not complete your request.")
    }

    private static func performEazyShopifyPaymentRequest(_ request: URLRequest) async throws -> EazyShopifyPaymentResponse {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The payment service returned an invalid response.")
        }
        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(EazyShopifyPaymentResponse.self, from: data)
        }
        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }
        throw ContentView.LoyaltyServiceError.operationFailed("The payment service could not complete your request.")
    }

    private static func performTasteMemoryRequest(_ request: URLRequest) async throws -> [ContentView.TasteMemoryRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The taste memory service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode([ContentView.TasteMemoryRecord].self, from: data)
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The taste memory service could not complete your request.")
    }

    private static func performTasteMemoryEnvelopeRequest(_ request: URLRequest) async throws -> [ContentView.TasteMemoryRecord] {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ContentView.LoyaltyServiceError.operationFailed("The taste memory service returned an invalid response.")
        }

        if 200 ..< 300 ~= httpResponse.statusCode {
            return try JSONDecoder().decode(TasteMemoryResponse.self, from: data).tasteMemory
        }

        if let errorPayload = try? JSONDecoder().decode(ServiceErrorResponse.self, from: data) {
            throw ContentView.LoyaltyServiceError.operationFailed(errorPayload.error)
        }

        throw ContentView.LoyaltyServiceError.operationFailed("The taste memory service could not complete your request.")
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
            Text(AppLocalization.text("checkout_only_iphone", fallback: "Checkout is only available on iPhone."))
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
    private static let brewingArticlePageSize = 50

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
        let nodesFromBlog = try await fetchBrewingBlogArticleNodes()
        let fallbackNodes = nodesFromBlog.isEmpty ? try await fetchBrewingSearchArticleNodes() : []
        let selectedNodes = uniqueArticleNodes(nodesFromBlog.isEmpty ? fallbackNodes : nodesFromBlog)

        guard !selectedNodes.isEmpty else {
            throw ShopifyError.api("No brewing articles are available in Shopify yet.")
        }

        return selectedNodes.map(ContentView.BrewingMethod.init(article:))
    }

    private static func fetchBrewingBlogArticleNodes() async throws -> [ShopifyBrewingArticlesResponse.ArticleNode] {
        var nodes: [ShopifyBrewingArticlesResponse.ArticleNode] = []
        var cursor: String?
        var hasNextPage = true

        while hasNextPage {
            var variables: [String: Any] = [
                "handle": ShopifyConfiguration.brewingBlogHandle,
                "first": brewingArticlePageSize
            ]
            if let cursor {
                variables["cursor"] = cursor
            }

            let body = ShopifyGraphQLRequest(
                query: """
                query BrewingBlogArticles($handle: String!, $first: Int!, $cursor: String) {
                  blog(handle: $handle) {
                    articles(first: $first, after: $cursor) {
                      pageInfo {
                        hasNextPage
                        endCursor
                      }
                      edges {
                        node {
                          id
                          handle
                          title
                          excerpt
                          content
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
                }
                """,
                variables: variables
            )

            let decoded: ShopifyBrewingArticlesResponse = try await performRequest(body)

            if let errors = decoded.errors, let first = errors.first {
                throw ShopifyError.api(first.message)
            }

            guard let connection = decoded.data?.blog?.articles else {
                return nodes
            }

            nodes.append(contentsOf: connection.edges.map(\.node))
            hasNextPage = connection.pageInfo.hasNextPage
            cursor = connection.pageInfo.endCursor
        }

        return nodes
    }

    private static func fetchBrewingSearchArticleNodes() async throws -> [ShopifyBrewingArticlesResponse.ArticleNode] {
        var nodes: [ShopifyBrewingArticlesResponse.ArticleNode] = []
        var cursor: String?
        var hasNextPage = true

        while hasNextPage {
            var variables: [String: Any] = [
                "query": ShopifyConfiguration.brewingArticlesQuery,
                "first": brewingArticlePageSize
            ]
            if let cursor {
                variables["cursor"] = cursor
            }

            let body = ShopifyGraphQLRequest(
                query: """
                query BrewingSearchArticles($query: String!, $first: Int!, $cursor: String) {
                  articles(first: $first, after: $cursor, sortKey: PUBLISHED_AT, reverse: true, query: $query) {
                    pageInfo {
                      hasNextPage
                      endCursor
                    }
                    edges {
                      node {
                        id
                        handle
                        title
                        excerpt
                          content
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
                variables: variables
            )

            let decoded: ShopifyBrewingArticlesResponse = try await performRequest(body)

            if let errors = decoded.errors, let first = errors.first {
                throw ShopifyError.api(first.message)
            }

            guard let connection = decoded.data?.articles else {
                return nodes
            }

            nodes.append(contentsOf: connection.edges.map(\.node))
            hasNextPage = connection.pageInfo.hasNextPage
            cursor = connection.pageInfo.endCursor
        }

        return nodes
    }

    private static func uniqueArticleNodes(_ nodes: [ShopifyBrewingArticlesResponse.ArticleNode]) -> [ShopifyBrewingArticlesResponse.ArticleNode] {
        var seenIDs: Set<String> = []
        return nodes.filter { node in
            seenIDs.insert(node.id).inserted
        }
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
                    variants(first: 12) {
                      edges {
                        node {
                          id
                          title
                          availableForSale
                          price {
                            amount
                            currencyCode
                          }
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

    static func createCheckoutURL(
        lines: [ShopifyCheckoutLine],
        customerEmail: String? = nil,
        checkoutAddress: ShopifyCheckoutAddress? = nil,
        tallaPaymentID: String? = nil
    ) async throws -> URL {
        let lineInputs = lines.map { line in
            [
                "merchandiseId": line.merchandiseId,
                "quantity": line.quantity
            ] as [String: Any]
        }

        var input: [String: Any] = [
            "lines": lineInputs
        ]
        if let tallaPaymentID = tallaPaymentID?.trimmingCharacters(in: .whitespacesAndNewlines), !tallaPaymentID.isEmpty {
            input["attributes"] = [["key": "talla_payment_id", "value": tallaPaymentID]]
        }
        var buyerIdentity: [String: Any] = [:]

        if let customerEmail = customerEmail?.trimmingCharacters(in: .whitespacesAndNewlines), !customerEmail.isEmpty {
            buyerIdentity["email"] = customerEmail
        }

        if let checkoutAddress {
            let nameParts = checkoutAddress.fullName
                .split(separator: " ", omittingEmptySubsequences: true)
                .map(String.init)
            let firstName = nameParts.first ?? checkoutAddress.fullName
            let lastName = nameParts.dropFirst().joined(separator: " ")
            let deliveryAddress: [String: Any] = [
                "address1": checkoutAddress.address1,
                "city": checkoutAddress.city,
                "country": checkoutAddress.country,
                "firstName": firstName,
                "lastName": lastName,
                "phone": checkoutAddress.phone
            ]
            let deliveryAddressPreference: [String: Any] = [
                "deliveryAddress": deliveryAddress
            ]
            buyerIdentity["email"] = checkoutAddress.email
            buyerIdentity["phone"] = checkoutAddress.phone
            buyerIdentity["deliveryAddressPreferences"] = [deliveryAddressPreference]
        }

        if !buyerIdentity.isEmpty {
            input["buyerIdentity"] = buyerIdentity
        }

        let firstResponse = try await createCart(input: input)
        if let checkoutURL = firstResponse.data?.cartCreate.cart?.checkoutUrl {
            return checkoutURL
        }

        if input.removeValue(forKey: "buyerIdentity") != nil {
            let fallbackResponse = try await createCart(input: input)
            if let checkoutURL = fallbackResponse.data?.cartCreate.cart?.checkoutUrl {
                return checkoutURL
            }
            if let userError = fallbackResponse.data?.cartCreate.userErrors.first {
                throw ShopifyError.api(userError.message)
            }
            if let error = fallbackResponse.errors?.first {
                throw ShopifyError.api(error.message)
            }
        }

        if let userError = firstResponse.data?.cartCreate.userErrors.first {
            throw ShopifyError.api(userError.message)
        }
        if let error = firstResponse.errors?.first {
            throw ShopifyError.api(error.message)
        }
        throw ShopifyError.invalidResponse
    }

    private static func createCart(input: [String: Any]) async throws -> ShopifyCartCreateResponse {
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
        return try await performRequest(body)
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
        let title: String
        let availableForSale: Bool
        let price: Money
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
    let country: String
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
        let articles: ArticleConnection?
    }

    struct Blog: Decodable {
        let articles: ArticleConnection
    }

    struct ArticleConnection: Decodable {
        let pageInfo: PageInfo
        let edges: [ArticleEdge]
    }

    struct PageInfo: Decodable {
        let hasNextPage: Bool
        let endCursor: String?
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

private struct TasteMemoryResponse: Decodable {
    let tasteMemory: [ContentView.TasteMemoryRecord]
}

private struct CheckoutStartResponse: Decodable {
    let orderID: String
    let orders: [ContentView.AccountOrder]
}

private struct BenefitPaymentResponse: Decodable {
    let paymentUrl: URL
    let trackId: String
}

private struct EazyShopifyPaymentResponse: Decodable {
    let tallaPaymentId: String
    let shopifyOrderName: String?
    let status: String
    let paymentUrl: URL?
    let paid: Bool
    let pending: Bool
    let message: String?
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
        if let appCategory = appCategoryOverride(from: tags) {
            return appCategory
        }

        let parts = [title, productType] + tags
        let source = parts.joined(separator: " ").lowercased()
        let sourceSlug = slug(from: parts.joined(separator: " "))
        let typeSlug = slug(from: productType)

        if containsAny(sourceSlug, [
            "summer", "summertime", "iced", "ice", "cold", "cold-brew", "refresher", "refreshers",
            "lemonade", "sparkling", "cooler", "coolers", "frappe", "frappé", "milkshake"
        ]) || ["summer", "summer-drinks", "cold-drinks"].contains(typeSlug) {
            return "summer-drinks"
        }

        if containsAny(sourceSlug, [
            "hot-chocolate", "hot-cocoa", "cocoa-mix", "cacao", "chocolate-powder"
        ]) || typeSlug == "hot-chocolate" {
            return "hot-chocolate"
        }

        if containsAny(sourceSlug, [
            "jam", "jams", "spread", "spreads", "butter", "butters", "sauce", "sauces", "honey", "jar", "jars"
        ]) || ["spreads", "spread", "jams", "butters"].contains(typeSlug) {
            return "spreads"
        }

        if containsAny(sourceSlug, [
            "crmb", "bakery", "dessert", "desserts", "pastry", "pastries", "croissant",
            "cookie", "cookies", "cake", "cakes", "brownie", "brownies", "fudge",
            "creme-caramel", "crème-caramel", "cream-caramel", "caramel", "bread", "breads", "banana-bread"
        ]) || ["crmb", "desserts", "dessert", "bread", "bakery", "pastries"].contains(typeSlug) {
            return "desserts"
        }

        if containsAny(sourceSlug, [
            "bottle", "bottled", "ready-made", "ready-made-drink", "ready-made-drinks",
            "tea", "karak", "matcha", "juice", "beverage", "beverages"
        ]) || ["tea", "ready-made-drinks", "drinks", "ready-made"].contains(typeSlug) {
            return "ready-made-drinks"
        }

        if containsAny(sourceSlug, [
            "cup", "cups", "latte-cup", "drink-cup", "talla-cup", "mug", "mugs", "tumbler", "tumblers", "drinkware"
        ]) || ["drink-cups", "cups", "mugs", "drinkware"].contains(typeSlug) {
            return "cups"
        }

        if containsAny(sourceSlug, [
            "drip-bag", "drip-bags", "drip-coffee-bag", "single-serve", "coffee-bag"
        ]) || typeSlug == "drip-bags" {
            return "drip-bags"
        }

        if containsAny(sourceSlug, [
            "equipment", "brewer", "brewers", "tool", "tools", "accessory", "accessories",
            "v60", "filter", "filters", "scale", "grinder", "kettle", "server", "dripper",
            "aeropress", "chemex", "french-press"
        ]) || ["coffee-equipment", "equipment", "accessories"].contains(typeSlug) {
            return "coffee-equipment"
        }

        if containsAny(sourceSlug, [
            "talla-box", "mini-talla-box", "mini-coffee-box", "mini-arabic-coffee-box",
            "gift-box", "gift-set", "gift-bundle", "seasonal-gift", "bundle", "majlis", "eid"
        ]) || source.contains("عيد") || ["gifts", "gift", "eid-gifts"].contains(typeSlug) {
            return "gifts"
        }

        if containsAny(sourceSlug, [
            "arabic-coffee", "shamali", "northern-coffee", "turkish", "qahwa", "gahwa",
            "dallah", "cardamom"
        ]) || ["arabic-coffee", "arabic-coffee-beans", "northern-coffee"].contains(typeSlug) {
            return "arabic-coffee-beans"
        }

        if containsAny(sourceSlug, [
            "coffee-bean", "coffee-beans", "beans", "espresso", "roast", "roasted", "single-origin",
            "brazil", "colombia", "ethiopia", "yemen", "decaf"
        ]) || ["coffee", "coffee-beans", "beans"].contains(typeSlug) {
            return "coffee-beans"
        }

        return "coffee-beans"
    }

    static func categoryLabel(productType: String, fallbackKey: String) -> String {
        switch fallbackKey {
        case "summer-drinks":
            return "Summer Drinks"
        case "coffee-beans":
            return "Coffee Beans"
        case "arabic-coffee-beans", "arabic-coffee", "northern-coffee", "other":
            return "Arabic & Shamali Coffee"
        case "drip-bags":
            return "Drip Bags"
        case "coffee-equipment":
            return "Equipment"
        case "ready-made-drinks", "tea", "drinks":
            return "Drinks"
        case "drink-cups", "cups", "mugs", "drinkware":
            return "Cups"
        case "crmb-tallas-speciality-bakery", "desserts", "bread", "bakery":
            return "CRMB"
        case "spreads":
            return "Spreads"
        case "hot-chocolate":
            return "Hot Chocolate"
        case "gifts", "eid-gifts":
            return "Talla Boxes"
        default:
            return fallbackKey
                .split(separator: "-")
                .map { $0.capitalized }
                .joined(separator: " ")
        }
    }

    static func productTag(from tags: [String]) -> String? {
        let preferred = ["STAFF PICK", "BESTSELLER", "LIMITED", "NEW", "LOCAL", "PREMIUM", "GIFT"]
        let uppercased = tags.map { $0.uppercased() }
        guard let tag = preferred.first(where: uppercased.contains) else { return nil }
        return tag == "BESTSELLER" ? "BEST SELLER" : tag
    }

    private static func containsAny(_ source: String, _ needles: [String]) -> Bool {
        needles.contains { source.contains($0) }
    }

    private static func appCategoryOverride(from tags: [String]) -> String? {
        for tag in tags {
            let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowercasedTag = trimmedTag.lowercased()
            let prefixes = ["app-category:", "app-category=", "app_category:", "app_category="]

            guard let prefix = prefixes.first(where: { lowercasedTag.hasPrefix($0) }) else {
                continue
            }

            let rawValue = String(trimmedTag.dropFirst(prefix.count))
            if let categoryKey = canonicalAppCategoryKey(from: rawValue) {
                return categoryKey
            }
        }

        for tag in tags {
            switch slug(from: tag) {
            case "cups", "cup", "drink-cups", "mugs", "mug", "drinkware", "tumblers", "tumbler":
                return "cups"
            case "ready-made-drinks", "ready-made", "drinks", "drink":
                return "ready-made-drinks"
            default:
                continue
            }
        }

        return nil
    }

    private static func canonicalAppCategoryKey(from value: String) -> String? {
        switch slug(from: value) {
        case "summer", "summer-drinks", "cold-drinks":
            return "summer-drinks"
        case "coffee", "coffee-beans", "beans":
            return "coffee-beans"
        case "arabic-coffee", "arabic-coffee-beans", "northern-coffee", "shamali":
            return "arabic-coffee-beans"
        case "drip-bags", "drip-bag":
            return "drip-bags"
        case "cups", "cup", "drink-cups", "mugs", "mug", "drinkware", "tumblers", "tumbler":
            return "cups"
        case "ready-made-drinks", "ready-made", "drinks", "drink", "tea", "karak", "matcha", "cups-and-drinks":
            return "ready-made-drinks"
        case "desserts", "dessert", "crmb", "bakery", "bread":
            return "desserts"
        case "spreads", "spread", "jams", "butters":
            return "spreads"
        case "hot-chocolate", "hot-cocoa", "cocoa":
            return "hot-chocolate"
        case "equipment", "coffee-equipment", "accessories", "tools":
            return "coffee-equipment"
        case "gifts", "gift", "talla-boxes", "boxes", "eid-gifts":
            return "gifts"
        default:
            return nil
        }
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
        let variants = shopifyNode.variants.edges.map { edge in
            Variant(
                id: edge.node.id,
                title: edge.node.title.isEmpty ? "Default" : edge.node.title,
                price: Self.formattedPrice(from: edge.node.price),
                isAvailableForSale: edge.node.availableForSale
            )
        }
        let defaultVariant = variants.first(where: \.isAvailableForSale) ?? variants.first

        self.init(
            id: shopifyNode.id,
            variantID: defaultVariant?.id,
            variants: variants,
            name: shopifyNode.title,
            price: defaultVariant?.price ?? Self.formattedPrice(from: shopifyNode.priceRange.minVariantPrice),
            categoryKey: categoryKey,
            categoryLabel: ProductCatalogRules.categoryLabel(productType: shopifyNode.productType, fallbackKey: categoryKey),
            imageURL: shopifyNode.featuredImage?.url,
            desc: shopifyNode.description,
            tag: ProductCatalogRules.productTag(from: shopifyNode.tags),
            isAvailableForSale: defaultVariant?.isAvailableForSale ?? false
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
            brewTime: Self.brewTime(title: article.title, tags: article.tags),
            publishedRecipe: Self.publishedRecipe(from: article.content)
        )
    }

    private static func publishedRecipe(from content: String) -> PublishedRecipe? {
        let coffee = firstNumber(in: content, pattern: #"([0-9]+(?:\.[0-9]+)?)\s*g\s+(?:[A-Za-z-]+\s+){0,3}coffee"#)
        let ratio = firstNumber(in: content, pattern: #"Brew\s*Ratio\s*:\s*1\s*:\s*([0-9]+(?:\.[0-9]+)?)"#)
        let water = firstNumber(in: content, pattern: #"([0-9]+(?:\.[0-9]+)?)\s*(?:ml|g)\s+(?:[A-Za-z-]+\s+){0,3}water"#)
        let ice = firstNumber(in: content, pattern: #"([0-9]+(?:\.[0-9]+)?)\s*g\s+ice"#)

        guard coffee != nil || ratio != nil || water != nil || ice != nil else {
            return nil
        }

        return PublishedRecipe(coffeeGrams: coffee, ratio: ratio, waterGrams: water, iceGrams: ice)
    }

    private static func firstNumber(in text: String, pattern: String) -> Double? {
        guard let expression = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = expression.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let numberRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return Double(text[numberRange])
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
        let source = ([title] + tags)
            .joined(separator: " ")
            .lowercased()

        if source.contains("cold") {
            return ["Cold Brew"]
        }

        if source.contains("arabic") || source.contains("dallah") || source.contains("traditional") {
            return ["Traditional"]
        }

        if source.contains("press") || source.contains("immersion") {
            return ["Immersion"]
        }

        if source.contains("chemex") || source.contains("v60") || source.contains("pour") || source.contains("filter") {
            return ["Pour Over"]
        }

        return ["Pour Over"]
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

        return "3–5 min"
    }

    private static func articleURL(blogHandle: String, articleHandle: String) -> URL? {
        URL(string: "https://\(ShopifyConfiguration.shopDomain)/blogs/\(blogHandle)/\(articleHandle)")
    }
}

private extension ContentView {
    static func randomAppleNonce(length: Int = 32) -> String {
        let characters = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var nonce = ""
        nonce.reserveCapacity(length)

        while nonce.count < length {
            let randomValue = Int.random(in: 0 ..< characters.count)
            nonce.append(characters[randomValue])
        }

        return nonce
    }

    static func sha256(_ input: String) -> String {
#if canImport(CryptoKit)
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
#else
        return input
#endif
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

private extension Array where Element: Identifiable {
    func uniquedByID() -> [Element] where Element.ID: Hashable {
        var seenIDs = Set<Element.ID>()
        return filter { element in
            seenIDs.insert(element.id).inserted
        }
    }
}

#Preview("Content Overview") {
    VStack(alignment: .leading, spacing: 18) {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color(hex: 0x0A0804))
                .frame(width: 42, height: 42)
                .background(Color(hex: 0xC8965A))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text("Talla Speciality")
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: 0xF6EFE2))

                Text("Run the app to preview the full shop, account, checkout, and brewing flow.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: 0xD7C7AD))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        HStack(spacing: 8) {
            Label("Shop", systemImage: "square.grid.2x2")
            Label("Brew", systemImage: "drop.fill")
            Label("Account", systemImage: "person.fill")
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(Color(hex: 0xC8965A))
    }
    .padding(22)
    .frame(width: 380, alignment: .leading)
    .background(Color(hex: 0x17120C))
}
