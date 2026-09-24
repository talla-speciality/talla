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

struct ContentView: View {
    @EnvironmentObject var coffeeData: CoffeeDataStore
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) var displayFontScale = 1.0
    @ScaledMetric(relativeTo: .title3) var titleFontScale = 1.0
    @ScaledMetric(relativeTo: .body) var bodyFontScale = 1.0
    @ScaledMetric(relativeTo: .caption) var labelFontScale = 1.0
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.requestReview) var requestReview
    @Environment(\.openURL) var openURL

    enum Tab: String, CaseIterable {
        case home
        case shop
        case club
        case brewing
        case account
        case search

        var systemImage: String {
            switch self {
            case .home:
                return "house"
            case .shop:
                return "square.grid.2x2"
            case .club:
                return "sparkles"
            case .brewing:
                return "drop"
            case .account:
                return "person"
            case .search:
                return "magnifyingglass"
            }
        }
    }

    enum SettingsDetail: String, Identifiable {
        case language
        case notifications
        case aboutTalla
        case deleteAccount

        var id: String { rawValue }
    }

    enum AppearanceMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark
        case oled

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system:
                return "System"
            case .light:
                return "Light"
            case .dark:
                return "Dark"
            case .oled:
                return AppLocalization.text("oled_dark", fallback: "OLED Dark")
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system:
                return nil
            case .light:
                return .light
            case .dark, .oled:
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
            let requiresShipping: Bool
            let weightGrams: Double?
        }

        let id: String
        let handle: String
        let variantID: String?
        let variants: [Variant]
        let name: String
        let price: String
        let categoryKey: String
        let categoryLabel: String
        let imageURL: URL?
        var additionalImageURLs: [URL] = []
        let desc: String
        let tag: String?
        let countryOfOrigin: String?
        let isAvailableForSale: Bool
        var catalogSourceText: String? = nil

        var catalogClassificationText: String {
            catalogSourceText ?? "\(name) \(desc) \(categoryLabel)"
        }

        var imageURLs: [URL] {
            ([imageURL].compactMap { $0 } + additionalImageURLs).reduce(into: []) { result, url in
                if !result.contains(url) { result.append(url) }
            }
        }

        var defaultVariant: Variant? {
            variants.first(where: \.isAvailableForSale) ?? variants.first
        }

        var hasVariantChoices: Bool {
            variants.count > 1
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

    struct AppSettings: Decodable {
        struct Announcement: Decodable {
            let enabled: Bool
            let title: String
            let message: String
            let actionLabel: String
            let actionURL: String
        }

        struct Support: Decodable {
            let whatsappURL: String
            let privacyURL: String
            let termsURL: String
        }

        struct HomeSections: Decodable {
            let showQuickDrinks: Bool
            let showFunPick: Bool
            let showSignatureRoasts: Bool
            let showPassport: Bool
        }

        struct Payments: Decodable {
            let applePayEnabled: Bool
            let benefitPayEnabled: Bool
            let benefitEnabled: Bool
            let cardEnabled: Bool
            let clickToPayEnabled: Bool?
            let cashOnDeliveryEnabled: Bool
            let noticeEN: String
            let noticeAR: String
        }

        struct CoffeeClub: Decodable {
            let enabled: Bool
            let shipmentCount: Int
            let intervalWeeks: Int
            let discountPercent: Int
        }

        struct CoffeeMemory: Decodable {
            let enabled: Bool
            let automaticPurchaseImport: Bool
            let roastDateOCR: Bool
            let replacementRecommendations: Bool
        }

        struct Fulfillment: Decodable {
            struct ShippingTier: Decodable {
                let maximumWeightGrams: Double
                let rate: Double
            }

            let deliveryEnabled: Bool
            let pickupEnabled: Bool
            let pickupNameEN: String
            let pickupNameAR: String
            let pickupAddressEN: String
            let pickupAddressAR: String
            let pickupMapsURL: String
            let openingHoursEN: String
            let openingHoursAR: String
            let bahrainRate: Double
            let khaleejiCashOnDeliverySurcharge: Double
            let maximumKhaleejiWeightGrams: Double
            let khaleejiTransitEN: String
            let khaleejiTransitAR: String
            let khaleejiTiers: [ShippingTier]
        }

        struct Release: Decodable {
            let maintenanceEnabled: Bool
            let checkoutMaintenanceEnabled: Bool
            let minimumSupportedVersion: String
            let latestVersion: String
            let appStoreURL: String
            let titleEN: String
            let titleAR: String
            let messageEN: String
            let messageAR: String
            let updateMessageEN: String
            let updateMessageAR: String
        }

        struct Loyalty: Decodable {
            struct Reward: Decodable, Identifiable {
                let id: String
                let enabled: Bool
                let titleEN: String
                let titleAR: String
                let detailEN: String
                let detailAR: String
                let points: Int
                let reward: String
            }

            let pointsPerBHD: Double
            let silverThreshold: Int
            let goldThreshold: Int
            let rewardStep: Int
            let rewards: [Reward]
        }

        let announcement: Announcement
        let support: Support
        let homeSections: HomeSections
        let payments: Payments?
        let coffeeClub: CoffeeClub?
        let coffeeMemory: CoffeeMemory?
        let fulfillment: Fulfillment?
        let release: Release?
        let loyalty: Loyalty?
    }

    struct EventSettings: Decodable {
        struct SeasonalEvent: Decodable, Identifiable, Hashable {
            let id: String
            let enabled: Bool
            let name: String
            let titleEN: String
            let titleAR: String
            let subtitleEN: String
            let subtitleAR: String
            let badgeEN: String
            let badgeAR: String
            let ctaEN: String
            let ctaAR: String
            let categoryTitleEN: String
            let categoryTitleAR: String
            let categorySubtitleEN: String
            let categorySubtitleAR: String
            let startAt: String?
            let endAt: String?
            let imageURL: String
            let accentHex: String
            let secondaryHex: String
            let symbol: String
            let productIDs: [String]
            let priority: Int
        }

        let events: [SeasonalEvent]
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

    struct CartItem: Identifiable, Hashable {
        let id: String
        let product: Product
        let variant: Product.Variant
        var quantity: Int
    }

    struct CheckoutSession: Identifiable {
        enum Kind: Equatable {
            case standard
            case clickToPay
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
            let productTitle: String?
            let variantTitle: String?
            let variantId: String?
        }

        let id: String
        let title: String
        let total: String
        let status: String
        let items: [Item]?
        let createdAt: String
        let beansAwarded: Bool?
        let pointsAwarded: Int?

        struct Details: Decodable {
            struct Fulfillment: Decodable {
                let method: String?
            }
            struct Tracking: Decodable {
                let company: String?
                let number: String?
                let url: String?
            }
            let fulfillment: Fulfillment?
            let tracking: Tracking?
            let coffeeClub: CustomerCoffeeClub?
        }

        var details: Details? = nil

        var isPickup: Bool {
            let clubMethod = details?.coffeeClub?.fulfillmentOverride?.method?
                .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if clubMethod == "pickup" { return true }
            if clubMethod == "delivery" { return false }
            let method = details?.fulfillment?.method?
                .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            if method == "pickup" { return true }
            if method == "delivery" { return false }
            // Older orders can predate the fulfillment snapshot.
            return title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "pickup order"
                || status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "ready"
        }

        var historyStatus: String {
            let normalized = status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard isPickup else { return normalized }
            switch normalized {
            case "completed", "fulfilled", "delivered": return "collected"
            case "shipped", "on its way", "out for delivery": return "packed"
            default: return normalized
            }
        }
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

    struct SupportedDeliveryCountry: RawRepresentable, CaseIterable, Identifiable, Hashable {
        let rawValue: String

        static let bahrain = Self(rawValue: "BH")!
        static let saudiArabia = Self(rawValue: "SA")!
        static let kuwait = Self(rawValue: "KW")!
        static let uae = Self(rawValue: "AE")!
        static let qatar = Self(rawValue: "QA")!
        static let oman = Self(rawValue: "OM")!

        nonisolated private static let khaleejiCodes: Set<String> = ["BH", "SA", "KW", "AE", "QA", "OM"]
        nonisolated private static let preferredCountries = [bahrain, saudiArabia, kuwait, uae, qatar, oman]
        nonisolated private static let isoCountryCodes = Set(
            Locale.Region.isoRegions
                .map(\.identifier)
                .filter { $0.count == 2 }
        ).subtracting(["EU", "EZ", "QO", "UN"])

        static let allCases: [Self] = {
            preferredCountries + isoCountryCodes
                .subtracting(preferredCountries.map(\.rawValue))
                .compactMap(Self.init(rawValue:))
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }()

        var id: String { rawValue }
        var isKhaleeji: Bool { Self.khaleejiCodes.contains(rawValue) }

        nonisolated init?(rawValue: String) {
            let code = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard code.count == 2, Self.isoCountryCodes.contains(code) else { return nil }
            self.rawValue = code
        }

        nonisolated init?(code: String?) {
            guard let code else { return nil }
            self.init(rawValue: code)
        }

        var name: String {
            Locale.current.localizedString(forRegionCode: rawValue) ?? rawValue
        }

        var flag: String {
            rawValue.unicodeScalars.compactMap { scalar in
                UnicodeScalar(127397 + scalar.value).map(String.init)
            }.joined()
        }

        var phonePrefix: String {
            switch self {
            case .oman: return "+968"
            case .bahrain: return "+973"
            case .qatar: return "+974"
            case .kuwait: return "+965"
            case .uae: return "+971"
            case .saudiArabia: return "+966"
            default: return ""
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

    struct BrewRecipe: Codable, Identifiable {
        let id: UUID
        let name: String
        let coffeeGrams: Double
        let ratio: Double
        let waterGrams: Double
        let category: String
        let createdAt: String
        let brewingWaterGrams: Double?
        let iceGrams: Double?
        let methodID: String?
        let brewerID: String?
        let brewMode: String?
        let bloomRatio: String?
        let pourCount: Int?
        let grind: String?
        let temperatureC: Int?
        let controlMode: String?
        let process: String?
        let roast: String?
        let grinder: String?
        let grinderID: UUID?
        let waterProfileID: UUID?
        let temperaturePresetID: UUID?
        let filter: String?
        let altitudeMeters: Int?
        let tastingNotes: String?
        let targetTimeRange: String?
        let temperatureReason: String?
        let expectedCup: String?
        let approach: String?
        let steps: [SmartBrewStep]?
    }

    struct BrewJournalEntry: Codable, Identifiable {
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

    struct CustomerLibraryPayload: Codable {
        let favorites: [String]
        let recentlyViewed: [String]
        let brewJournal: [BrewJournalEntry]
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
    struct WalletPassItem: Identifiable {
        let id = UUID()
        let pass: PKPass
    }
#endif

    @State var activeTab: Tab = .home
    @State var activeCategory = "all"
    @State var shopSearchQuery = ""
    @State var surprisePickProductID = ""
    @State var isSurprisePickExpanded = false
    @State var isSurprisePickRevealed = false
    @State var surpriseRevealID = 0
    @State var shopSortMode: ShopSortMode = .featured
    @State var conciergeRequest = ""
    @State var conciergeResult: CoffeeConciergeResult?
    @State var isRunningConcierge = false
#if canImport(PhotosUI)
    @State var conciergeImageSelection: PhotosPickerItem?
#endif
    @State var conciergeImageData: Data?
    @State var isLoadingConciergeImage = false
    @State var isCoffeeConciergePresented = false
    @State var isCoffeeQuizExpanded = false
    @State var quizBrewMethod = "v60"
    @State var quizFlavor = "fruity"
    @State var quizAdventure = "curious"
    @State var products: [Product] = []
    @State var pendingUniversalLinkProductHandle = ""
    @State var pendingBrewingCoffeeName = ""
    @State var pendingBrewingCoffeeOrigin = ""
    @State var pendingBrewingCoffeeNotes = ""
    @State var pendingRecommendedRecipe = false
    @State var cartItems: [CartItem] = []
    @State var isCoffeeClubPrepaid = false
    @State var coffeeClubTermsAccepted = false
    @State var cartOpen = false
    enum PaymentPresentation {
        case hosted(CheckoutSession)
        case benefitPay(BenefitPaySession)
        case mastercard(MastercardPaymentContext)
    }

    @State var pendingPaymentPresentation: PaymentPresentation?
    @State var isCheckoutPresented = false
    @State var isCheckoutAddressSheetPresented = false
    @State var isPostPaymentPresented = false
    @State var postPaymentOrderID = ""
    @State var postPaymentTotal = ""
    @State var postPaymentMethodTitle = ""
    @State var postPaymentFulfillmentTitle = ""
    @State var postPaymentDestination = ""
    @State var toastMessage: String?
    @State var cartCelebrationID = 0
    @State var showingCartCelebration = false
    @State var delightFeedbackTrigger = 0
    @State var isLoadingProducts = false
    @State var hasLoadedProducts = false
    @State var lastProductsRefreshAt: Date?
    @State var loadingError: String?
    @State var brewingMethods: [BrewingMethod] = []
    @State var isLoadingBrewingMethods = false
    @State var hasLoadedBrewingMethods = false
    @State var brewingMethodsError: String?
    @State var activeBrewingCategory = "All"
    @State var ratioCoffeeInput = "20"
    @State var ratioValueInput = "16"
    @State var brewRecipeName = ""
    @State var editingBrewRecipe: BrewRecipe?
    @State var selectedBrewTimerName = "Pour Over"
    @State var selectedBrewTimerSeconds = 210
    @State var brewTimerRemainingSeconds = 210
    @State var isBrewTimerRunning = false
    @State var brewTimerRunID = UUID()
    @State var brewTimerEndDate: Date?
    @State var journalTitleInput = ""
    @State var journalMethodInput = "Pour Over"
    @State var journalNotesInput = ""
    @State var journalCoffeeGrams: Double?
    @State var journalRatio: Double?
    @State var journalWaterGrams: Double?
    @State var journalBrewTimeSeconds: Int?
    @State var pendingBrewSamples: [CoffeeSampleInput] = []
    @State var journalRating = 4
    @State var cartSaveName = ""
    @State var isCheckingOut = false
    @State var checkoutError: String?
    @StateObject var paymentFlow = PaymentFlowModel()
    @State var isPaymentMethodSheetPresented = false
    @State var isCartRewardsPresented = false
    @State var pendingCartRemovalID: String?
    @State var isConfirmingEmptyBag = false
    @State var checkoutSession: CheckoutSession?
    @State var eazyShopifyBrowserKind: CheckoutSession.Kind?
    @State var benefitPaySession: BenefitPaySession?
    @State var mastercardPaymentContext: MastercardPaymentContext?
    @State var articleSession: CheckoutSession?
    @State var selectedProduct: Product?
    @State var isFavoriteShelfPresented = false
    @State var isHomeShelfExpanded = false
    @State var isHomeMoreExpanded = false
    @State var voucherCodeInput = ""
    @State var appliedVoucher: VoucherRecord?
    @State var isApplyingVoucher = false
    @State var voucherError: String?
    @State var availableVouchers: [VoucherRecord] = []
    @State var isLoadingAvailableVouchers = false
    @AppStorage("app.appearanceMode") var savedAppearanceMode = AppearanceMode.system.rawValue
    @AppStorage("app.hasSeenWelcome") var hasSeenWelcome = false
    @AppStorage("app.hasSeenFeatureTour") var hasSeenFeatureTour = false
    @AppStorage("app.reviewLaunchCount") var reviewLaunchCount = 0
    @AppStorage("app.reviewLastPromptAt") var reviewLastPromptAt = 0.0
    @AppStorage("payment.activeEazyShopifyID") var activeEazyShopifyPaymentID = ""
    @AppStorage("app.reviewPromptedVersion") var reviewPromptedVersion = ""
    @AppStorage("local.customerEmail") var savedCustomerEmail = ""
    @State var savedCustomerAccessToken = TallaAccountCredentialStore.accessToken
    @AppStorage("local.pushDeviceToken") var savedPushDeviceToken = ""
    @AppStorage("local.pushDeviceToken.email") var savedRegisteredPushDeviceEmail = ""
    @AppStorage("local.pushDeviceToken.value") var savedRegisteredPushDeviceToken = ""
    @AppStorage("loyalty.email") var savedLoyaltyEmail = ""
    @AppStorage("favorites.productIDs") var savedFavoriteProductIDs = ""
    @AppStorage("recentlyViewed.productIDs") var savedRecentlyViewedProductIDs = ""
    @AppStorage("recentSearches.queries") var savedRecentSearchQueries = ""
    @AppStorage("alerts.productIDs") var savedAlertProductIDs = ""
    @AppStorage("customerLibrary.migratedEmails") var customerLibraryMigratedEmails = ""
    @AppStorage("customerLibrary.cacheOwnerEmail") var customerLibraryCacheOwnerEmail = ""
    @AppStorage("tasteMemory.saved") var savedTasteMemory = ""
    @AppStorage("carts.saved") var savedCartsPayload = ""
    @AppStorage("brewing.deletedRecipeIDs") var deletedBrewRecipeIDsPayload = ""
    @State var selectedJournalCoffeeID: UUID?
    @AppStorage("app.language") var savedAppLanguage = AppLanguage.system.rawValue
    @AppStorage("shortcut.destination") var shortcutDestination = ""
    @AppStorage("shortcut.searchQuery") var shortcutSearchQuery = ""
    @State var notificationAuthorizationStatus: Int = 0
    @State var showLaunchSplash = true
    @State var didStartInitialLaunchSequence = false
    @State var featureTourIndex = 0
    @State var accountAuthMode: AccountAuthMode = .signIn
    @State var accountFirstName = ""
    @State var accountLastName = ""
    @State var accountEmail = ""
    @State var accountPassword = ""
    @State var accountConfirmPassword = ""
    @State var profileFirstName = ""
    @State var profileLastName = ""
    @State var isSavingProfile = false
    @State var currentPasswordInput = ""
    @State var newPasswordInput = ""
    @State var confirmNewPasswordInput = ""
    @State var isResettingPassword = false
    @State var isRequestingPasswordResetLink = false
    @State var isSigningInWithApple = false
    @State var isDeletingAccount = false
    @State var isDeleteConfirmationPresented = false
    @State var accountDeletionError: String?
    @State var appleSignInNonce = ""
    @State var customerProfile: ShopifyCustomerProfile?
    @State var customerAuthError: String?
    @State var isSigningIn = false
    @State var isCreatingAccount = false
    @State var isLoadingCustomer = false
    @State var orderHistory: [AccountOrder] = []
    @State var isLoadingOrders = false
    @State var ordersError: String?
    @State var backendStockAlerts: [StockAlertRecord] = []
    @State var isLoadingBackendAlerts = false
    @State var alertInbox: [AlertInboxRecord] = []
    @State var addresses: [DeliveryAddress] = []
    @State var fulfillmentMethod: TallaFulfillmentMethod = .delivery; @State var selectedPickupSlot = "10:00–12:00"
    @State var addressLabel = ""
    @State var addressFullName = ""
    @State var addressPhone = ""
    @State var addressLine1 = ""
    @State var addressCity = ""
    @State var addressCountry: SupportedDeliveryCountry = .bahrain
    @State var addressNotes = ""
    @State var isGiftOrder = false
    @State var giftRecipientName = ""
    @State var giftRecipientPhone = ""
    @State var giftMessage = ""
    @State var isSavingAddress = false
    @State var selectingAddressID: String?
    @State var isAccountOnboardingPresented = false
    @State var selectedVariantIDs: [String: String] = [:]
    @State var remoteSignatureRoastProductIDs: [String] = []
    @State var remoteHomeSettings: HomeSettings?
    @State var remotePassportSettings: PassportSettings?
    @State var remoteAppSettings: AppSettings?
    @State var remoteEventSettings: EventSettings?
    @State var loyaltyEmail = ""
    @State var loyaltyAccount: LoyaltyAccount?
    @State var loyaltyError: String?
    @State var isLoadingLoyalty = false
    @State var isRedeemingReward = false
    @State var isEarningPoints = false
    @State var isLoadingWalletPass = false
    @State var isLoyaltyPassInWallet = false
#if canImport(PassKit)
    @State var loyaltyWalletPass: WalletPassItem?
#endif
    @State var isCustomerSectionExpanded = true
    @State var isLoyaltySectionExpanded = true
    @State var isLibrarySectionExpanded = true
    @State var isShoppingSectionExpanded = false
    @State var isBrewingSectionExpanded = false
    @State var isSupportSectionExpanded = false
    @State var isCheckoutNoteExpanded = false
    @State var isVoucherCodeEntryExpanded = false
    @State var isCartSaveEntryExpanded = false
    @State var isTallaPassportExpanded = false
    @State var selectedSettingsDetail: SettingsDetail?
    @State var didConfigureReleaseUITest = false
    @State var accountScrollTarget: String?
    @State var tabScrollTarget: Tab?
    @State var accountOrdersPresentationRequest = 0
    @State var shopCatalogueScrollRequest = 0
    @State var didRecordReviewLaunch = false

    let categoryCatalog: [ShopCategory] = [
        ShopCategory(key: "all", title: "All", subtitle: "Full catalog", symbol: "square.grid.2x2.fill"),
        ShopCategory(key: "summer-drinks", title: "Summer Boxes", subtitle: "Four seasonal drink boxes", symbol: "shippingbox.fill"),
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

    let signatureRoastProductNames = [
        "Brazil",
        "Colombia",
        "Ethiopia",
        "Yemen"
    ]

    let defaultCoffeePassportOrigins = [
        CoffeePassportOrigin(id: "ethiopia", title: "Ethiopia", detail: "Floral, bright, berry-like cups", symbol: "🇪🇹"),
        CoffeePassportOrigin(id: "yemen", title: "Yemen", detail: "Deep spice, cocoa, dried fruit", symbol: "🇾🇪"),
        CoffeePassportOrigin(id: "colombia", title: "Colombia", detail: "Balanced caramel and chocolate", symbol: "🇨🇴"),
        CoffeePassportOrigin(id: "brazil", title: "Brazil", detail: "Smooth nuts, cocoa, comfort", symbol: "🇧🇷")
    ]

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
        if isCoffeeClubActive { return coffeeClubDiscount }
        guard let appliedVoucher else { return 0 }

        switch appliedVoucher.reward.lowercased() {
        case "free drink":
            return LoyaltyVoucherRules.freeDrinkDiscount(
                lines: cartItems.map {
                    (
                        categoryKey: $0.product.categoryKey,
                        unitPrice: priceValue(from: $0.product.price),
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
            : formattedBHD(cartTotal)
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
            return formattedBHD(cartShippingCost)
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

    var curatedBundleProducts: [Product] {
        products.filter { product in
            let text = product.catalogClassificationText.lowercased()
            return product.categoryKey == "gifts"
                || text.contains("bundle")
                || text.contains("gift box")
                || text.contains("talla box")
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
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

    func advanceFeatureTour() {
        if featureTourIndex >= featureTourHighlights.count - 1 {
            dismissFeatureTour()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                featureTourIndex += 1
            }
        }
    }

    func dismissFeatureTour() {
        withAnimation(.easeInOut(duration: 0.22)) {
            hasSeenFeatureTour = true
            featureTourIndex = 0
        }
    }

    var launchSplashView: some View {
        ZStack {
            Group {
                if isLightAppearance {
                    Color.white
                } else {
                    LinearGradient(
                        colors: isOLEDAppearance
                            ? [.black, .black, .black]
                            : [
                                Color(hex: 0x100B07),
                                Color(hex: 0x1A120C),
                                Color(hex: 0x0A0804)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .ignoresSafeArea()

            if !isLightAppearance {
                Circle()
                    .fill(TallaTheme.Colors.accent.opacity(0.12))
                    .blur(radius: 90)
                    .frame(width: 240, height: 240)
                    .offset(x: 90, y: -160)
            }

            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: isCompact ? 132 : 168, height: isCompact ? 132 : 168)
                .accessibilityLabel(AppLocalization.text("talla_logo", fallback: "Talla Speciality"))
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("launch.splash")
    }

    @MainActor
    func runInitialLaunchSequence() async {
        let startTime = Date()

        restoreSyncedCustomerCredential()

        let minimumSplashDuration: TimeInterval = 1.25
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < minimumSplashDuration {
            do {
                try await Task.sleep(nanoseconds: UInt64((minimumSplashDuration - elapsed) * 1_000_000_000))
            } catch {
                return
            }
        }
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.28)) {
            showLaunchSplash = false
        }

        recordLaunchAndRequestReviewIfReady()
        handleShortcutDestination()

        // Network bootstrap is deliberately performed after the splash is
        // dismissed. Storefront, notification, and account services are
        // optional at launch and must never prevent the local UI from opening.
        await loadAppSettings()
        guard !Task.isCancelled else { return }
        await loadProductsIfNeeded()
        guard !Task.isCancelled else { return }
        await refreshNotificationStatus()
        guard !Task.isCancelled else { return }
        await syncRemotePushTokenIfPossible()
    }

    func recordLaunchAndRequestReviewIfReady() {
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

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: savedAppearanceMode) ?? .system }
        set { savedAppearanceMode = newValue.rawValue }
    }

    var appLanguage: AppLanguage {
        AppLanguage(rawValue: savedAppLanguage) ?? .system
    }

    var isArabicInterface: Bool {
        appLanguage.layoutDirection == .rightToLeft
    }

    var paymentAvailability: TallaPaymentAvailability {
        guard let payments = remoteAppSettings?.payments else { return TallaPaymentAvailability() }
        return TallaPaymentAvailability(
            applePayEnabled: payments.applePayEnabled,
            benefitPayEnabled: payments.benefitPayEnabled,
            benefitEnabled: payments.benefitEnabled,
            cardEnabled: payments.cardEnabled,
            clickToPayEnabled: payments.clickToPayEnabled ?? payments.cardEnabled,
            cashOnDeliveryEnabled: payments.cashOnDeliveryEnabled
        )
    }

    var shippingConfiguration: TallaShippingConfiguration {
        guard let fulfillment = remoteAppSettings?.fulfillment else { return TallaShippingConfiguration() }
        return TallaShippingConfiguration(
            bahrainRate: fulfillment.bahrainRate,
            khaleejiCashOnDeliverySurcharge: fulfillment.khaleejiCashOnDeliverySurcharge,
            maximumKhaleejiWeightGrams: fulfillment.maximumKhaleejiWeightGrams,
            khaleejiTransitTime: isArabicInterface ? fulfillment.khaleejiTransitAR : fulfillment.khaleejiTransitEN,
            khaleejiTiers: fulfillment.khaleejiTiers.map {
                TallaShippingConfiguration.Tier(maximumWeightGrams: $0.maximumWeightGrams, rate: $0.rate)
            }
        )
    }

    var managedPickupName: String {
        guard let fulfillment = remoteAppSettings?.fulfillment else {
            return AppLocalization.text("pickup_location_short", fallback: "Talla, Riffa")
        }
        return isArabicInterface ? fulfillment.pickupNameAR : fulfillment.pickupNameEN
    }

    var managedPickupAddress: String {
        guard let fulfillment = remoteAppSettings?.fulfillment else {
            return AppLocalization.text("pickup_address", fallback: "Villa 336, Street 1307, Riffa 913")
        }
        return isArabicInterface ? fulfillment.pickupAddressAR : fulfillment.pickupAddressEN
    }

    func version(_ lhs: String, isOlderThan rhs: String) -> Bool {
        let left = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let right = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(left.count, right.count) {
            let leftPart = index < left.count ? left[index] : 0
            let rightPart = index < right.count ? right[index] : 0
            if leftPart != rightPart { return leftPart < rightPart }
        }
        return false
    }

    var requiresAppUpdate: Bool {
        guard let minimum = remoteAppSettings?.release?.minimumSupportedVersion,
              !minimum.isEmpty else { return false }
        return version(currentAppVersion, isOlderThan: minimum)
    }

    var blocksApplicationUse: Bool {
        remoteAppSettings?.release?.maintenanceEnabled == true || requiresAppUpdate
    }

    var hasOptionalAppUpdate: Bool {
        guard !requiresAppUpdate,
              let latest = remoteAppSettings?.release?.latestVersion,
              !latest.isEmpty else { return false }
        return version(currentAppVersion, isOlderThan: latest)
    }

    var body: some View {
        presentedContent
            .font(TallaTheme.Fonts.body)
            .tint(TallaTheme.Colors.accent)
            .textFieldStyle(.talla)
            .buttonBorderShape(.roundedRectangle(radius: TallaTheme.CornerRadius.control))
            .sensoryFeedback(.selection, trigger: activeTab)
            .onOpenURL(perform: handleDeepLink)
            .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
            .environment(\.layoutDirection, appLanguage.layoutDirection)
            .preferredColorScheme(appearanceMode.colorScheme)
    }

    var rootContent: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
                .ignoresSafeArea()

            Circle()
                .fill(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.10 : 0.08))
                .frame(width: isCompact ? 260 : 420)
                .blur(radius: 18)
                .offset(x: isCompact ? 150 : 320, y: -280)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Circle()
                .fill(Color(hex: 0x7A4F25).opacity(isLightAppearance ? 0.06 : 0.09))
                .frame(width: isCompact ? 220 : 360)
                .blur(radius: 24)
                .offset(x: isCompact ? -160 : -340, y: 340)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            if showLaunchSplash {
                launchSplashView
                    .transition(.opacity)
                    .zIndex(80)
            } else {
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
                        accentColor: TallaTheme.Colors.accent,
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
                        accentColor: TallaTheme.Colors.accent,
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

            }
        }
    }

    var lifecycleContent: some View {
        rootContent
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: cartOpen)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: showLaunchSplash)
        .transaction { transaction in
            if reduceMotion {
                transaction.disablesAnimations = true
            }
        }
        .sensoryFeedback(.success, trigger: delightFeedbackTrigger)
        .task {
            guard !didStartInitialLaunchSequence else { return }
            didStartInitialLaunchSequence = true
            if configureReleaseUITestScenarioIfNeeded() { return }
            syncWidgetSharedState(reload: false)
            await runInitialLaunchSequence()
            guard !Task.isCancelled else { return }
            syncWidgetSharedState(reload: true)
        }
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 30_000_000_000)
                } catch {
                    return
                }
                await loadAppSettings()
            }
        }
        .onChange(of: activeTab) { _, newTab in
            guard newTab == .shop, hasLoadedProducts, !didConfigureReleaseUITest else { return }
            Task {
                await refreshProductsIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            synchronizeBrewTimerWithClock()
            Task {
                let restoredCredential = restoreSyncedCustomerCredential()
                if restoredCredential, customerProfile == nil {
                    await loadCustomerProfile()
                }
                await loadAppSettings()
                await loadEventSettings()
                guard hasLoadedProducts else { return }
                if activeTab == .shop {
                    await refreshProductsIfNeeded()
                }
                await refreshWalletPassPresence()
                await refreshNotificationStatus()
                await syncRemotePushTokenIfPossible()
                if customerProfile != nil {
                    await refreshSignedInProfile()
                    await synchronizeCustomerLibrary()
                    await loadOrderHistory()
                    await loadBackendStockAlerts()
                    await loadAddresses()
                    await loadAlertInbox()
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
        .onChange(of: cartItems.map { "\($0.id):\($0.quantity)" }.joined(separator: "|")) { _, _ in
            persistActiveCartForSync()
        }
        .onChange(of: savedAppLanguage) { _, _ in
            syncWidgetSharedState(reload: true)
            guard !didConfigureReleaseUITest else { return }
            Task {
                await loadProducts(force: true)
                await loadBrewingMethods(force: true)
            }
        }
        .onChange(of: shortcutDestination) { _, _ in
            handleShortcutDestination()
        }
        .onChange(of: products.count) { _, _ in
            resolvePendingUniversalLinkProduct()
        }
#if canImport(PhotosUI)
        .onChange(of: conciergeImageSelection) { _, newSelection in
            Task {
                await loadConciergeImage(from: newSelection)
            }
        }
#endif
    }

    var presentedContent: some View {
        ZStack {
            lifecycleContent
            if blocksApplicationUse {
                operationalBlockerView
                    .zIndex(200)
            }
        }
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
        .sheet(isPresented: $isCartRewardsPresented) {
            cartRewardsSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isCoffeeConciergePresented) {
            coffeeConciergeSheet
        }
        .fullScreenCover(isPresented: $isCheckoutPresented, onDismiss: presentPendingPayment) {
            checkoutView
                .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
                .environment(\.layoutDirection, appLanguage.layoutDirection)
        }
        .fullScreenCover(isPresented: $isPostPaymentPresented) {
            postPaymentView
        }
        .fullScreenCover(isPresented: $isAccountOnboardingPresented) {
            accountOnboardingView
                .interactiveDismissDisabled(true)
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
    }

    var operationalBlockerView: some View {
        let release = remoteAppSettings?.release
        let title = requiresAppUpdate
            ? (isArabicInterface ? "يرجى تحديث التطبيق" : "Update required")
            : (isArabicInterface ? release?.titleAR : release?.titleEN)
        let message = requiresAppUpdate
            ? (isArabicInterface ? release?.updateMessageAR : release?.updateMessageEN)
            : (isArabicInterface ? release?.messageAR : release?.messageEN)

        return ZStack {
            pageBackgroundColor.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: requiresAppUpdate ? "arrow.down.app.fill" : "cup.and.saucer.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundColor(TallaTheme.Colors.accent)
                Text(title ?? "Talla")
                    .font(displayFont(size: 32))
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.center)
                Text(message ?? "Please try again shortly.")
                    .font(bodyFont(size: 15))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                if requiresAppUpdate,
                   let urlString = release?.appStoreURL,
                   let url = URL(string: urlString),
                   !urlString.isEmpty {
                    Button(isArabicInterface ? "التحديث من App Store" : "Update on the App Store") {
                        openURL(url)
                    }
                    .buttonStyle(.tallaPrimary)
                    .tint(TallaTheme.Colors.accent)
                }
            }
            .padding(28)
        }
    }

    func resetPaymentFlowAfterCheckoutDismiss() {
        if let eazyShopifyBrowserKind {
            self.eazyShopifyBrowserKind = nil
            paymentFlow.transition(to: .processing)
            presentPostPayment()
            Task {
                await waitForEazyShopifyProgress(openHostedCheckout: eazyShopifyBrowserKind == .shopifyEazy)
            }
            return
        }
        if paymentFlow.selectedMethod == .clickToPay,
           !postPaymentOrderID.isEmpty,
           paymentFlow.state == .awaitingCustomer {
            paymentFlow.transition(to: .processing)
            presentPostPayment()
            Task {
                await waitForClickToPayProgress()
            }
            return
        }
        if paymentFlow.state == .awaitingCustomer {
            paymentFlow.reset()
        }
    }

    @MainActor
    func waitForEazyShopifyProgress(openHostedCheckout: Bool) async {
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
    func refreshActiveEazyShopifyPayment(openHostedCheckout: Bool) async -> Bool {
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
                if postPaymentOrderID.isEmpty,
                   let shopifyOrderName = status.shopifyOrderName,
                   !shopifyOrderName.isEmpty {
                    postPaymentOrderID = shopifyOrderName
                }
                presentPostPayment()
                return true
            }
            if ["FAILED", "CANCELLED"].contains(status.status) {
                paymentFlow.transition(to: status.status == "CANCELLED" ? .cancelled : .failed, error: status.message)
                presentPostPayment()
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

    func resetPaymentFlowAfterBenefitPayDismiss() {
        if paymentFlow.state == .awaitingCustomer {
            paymentFlow.cancel()
        }
    }

    func resetPaymentFlowAfterMastercardDismiss() {
        if paymentFlow.state == .succeeded {
            cartItems.removeAll()
            appliedVoucher = nil
            voucherCodeInput = ""
            voucherError = nil
            Task {
                await loadOrderHistory()
                if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await loadLoyaltyAccount()
                }
            }
            presentPostPayment()
            return
        }
        paymentFlow.reset()
    }

    @ViewBuilder
    var appTabView: some View {
        if #available(iOS 18.0, *) {
            baseTabView
                .tabViewStyle(.sidebarAdaptable)
        } else {
            baseTabView
        }
    }

    @ViewBuilder
    var baseTabView: some View {
        if #available(iOS 18.0, *) {
            modernTabView
        } else {
            legacyTabView
        }
    }

    @available(iOS 18.0, *)
    var modernTabView: some View {
        TabView(selection: $activeTab) {
            SwiftUI.Tab(
                AppLocalization.text("home", fallback: "Home"),
                systemImage: Tab.home.systemImage,
                value: Tab.home
            ) {
                tabScreen(tab: .home) {
                    homeView
                }
                .accessibilityIdentifier("tab.home")
            }

            SwiftUI.Tab(
                AppLocalization.text("shop", fallback: "Shop"),
                systemImage: Tab.shop.systemImage,
                value: Tab.shop
            ) {
                tabScreen(tab: .shop) {
                    shopView
                }
                .accessibilityIdentifier("tab.shop")
            }

            SwiftUI.Tab(
                AppLocalization.text("club", fallback: "Club"),
                systemImage: Tab.club.systemImage,
                value: Tab.club
            ) {
                tabScreen(tab: .club) {
                    clubView
                }
                .accessibilityIdentifier("tab.club")
            }

            SwiftUI.Tab(
                AppLocalization.text("brew", fallback: "Brew"),
                systemImage: Tab.brewing.systemImage,
                value: Tab.brewing
            ) {
                tabScreen(tab: .brewing) {
                    brewingView
                }
                .accessibilityIdentifier("tab.brewing")
            }

            SwiftUI.Tab(
                AppLocalization.text("account", fallback: "Account"),
                systemImage: Tab.account.systemImage,
                value: Tab.account
            ) {
                tabScreen(tab: .account) {
                    accountView
                }
                .accessibilityIdentifier("tab.account")
            }

        }
    }

    var legacyTabView: some View {
        TabView(selection: $activeTab) {
            tabScreen(tab: .home) { homeView }
                .tag(Tab.home)
                .accessibilityIdentifier("tab.home")
                .tabItem {
                    Label(AppLocalization.text("home", fallback: "Home"), systemImage: Tab.home.systemImage)
                }

            tabScreen(tab: .shop) { shopView }
                .tag(Tab.shop)
                .accessibilityIdentifier("tab.shop")
                .tabItem {
                    Label(AppLocalization.text("shop", fallback: "Shop"), systemImage: Tab.shop.systemImage)
                }

            tabScreen(tab: .club) { clubView }
                .tag(Tab.club)
                .accessibilityIdentifier("tab.club")
                .tabItem {
                    Label(AppLocalization.text("club", fallback: "Club"), systemImage: Tab.club.systemImage)
                }

            tabScreen(tab: .brewing) { brewingView }
                .tag(Tab.brewing)
                .accessibilityIdentifier("tab.brewing")
                .tabItem {
                    Label(AppLocalization.text("brew", fallback: "Brew"), systemImage: Tab.brewing.systemImage)
                }

            tabScreen(tab: .account) { accountView }
                .tag(Tab.account)
                .accessibilityIdentifier("tab.account")
                .tabItem {
                    Label(AppLocalization.text("account", fallback: "Account"), systemImage: Tab.account.systemImage)
                }

        }
        .toolbar(.visible, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(tabBarBackgroundColor, for: .tabBar)
    }

    func tabScreen<Content: View>(tab: Tab, @ViewBuilder content: @escaping () -> Content) -> some View {
        NavigationStack {
            tabScrollContent(tab: tab, content: content)
                .toolbar {
                    if #available(iOS 27.1, *) {
                        ToolbarItem(placement: .primaryAction) {
                            if tab == .home || tab == .shop {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.18)) { cartOpen = true }
                                } label: {
                                    Label(AppLocalization.text("bag", fallback: "Bag"), systemImage: "bag")
                                }
                                .badge(cartCount)
                                .accessibilityIdentifier("navigation.bag")
                                .accessibilityValue(String(cartCount))
                            }
                        }
                        ToolbarItem(placement: .secondaryAction) {
                            appearanceMenu
                        }
                    }
                }
                .toolbar(usesSystemNavigationActions ? .visible : .hidden, for: .navigationBar)
                .modifier(DuoToolbarBehavior())
                .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    func tabScrollContent<Content: View>(tab: Tab, @ViewBuilder content: @escaping () -> Content) -> some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear
                            .frame(height: 0)
                            .id("tab-top")
                        if tab == .home {
                            header
                        }
                        // Keep each tab's view identity and local state while resizing.
                        content()
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
        .background(pageBackgroundColor)
    }

    var tabBarBackgroundColor: Color {
        if isLightAppearance {
            return TallaTheme.Colors.lightElevatedSurface.opacity(0.98)
        }
        return isOLEDAppearance ? .black : Color(hex: 0x100D0A).opacity(0.98)
    }

    func topScrollPadding(for tab: Tab) -> CGFloat {
        tab == .account ? 8 : 0
    }

    func bottomScrollPadding(for tab: Tab) -> CGFloat {
        tab == .account ? 56 : 28
    }

    func dismissKeyboard() {
#if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }

    func openTab(_ tab: Tab) {
        activeTab = tab
        tabScrollTarget = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            tabScrollTarget = tab
        }
    }

    func openShop(category: String = "all", searchQuery: String = "") {
        activeCategory = category
        shopSearchQuery = searchQuery
        openTab(.shop)
    }

    func openBrewing(category: String = "All") {
        activeBrewingCategory = category
        openTab(.brewing)
    }

    func startBrewing(product: Product, useRecommendedRecipe: Bool = false) {
        let coffeeName = product.name.trimmingCharacters(in: .whitespacesAndNewlines)
        selectedProduct = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            brewRecipeName = coffeeName
            openBrewing(category: product.categoryKey == "arabic-coffee-beans" ? "Traditional" : "All")
            pendingBrewingCoffeeName = coffeeName
            pendingBrewingCoffeeOrigin = product.countryOfOrigin ?? ""
            pendingBrewingCoffeeNotes = product.desc
            pendingRecommendedRecipe = useRecommendedRecipe
            TallaTelemetry.shared.track(useRecommendedRecipe ? "recommendation_to_brew_started" : "brew_from_product_started", properties: ["product": coffeeName])
            showToast(message: AppLocalization.text("brew_ready", fallback: "Coffee added to your brewing workspace"))
        }
    }

    func openAccountSection(_ target: String, authMode: AccountAuthMode? = nil) {
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

    func handleShortcutDestination() {
        guard !shortcutDestination.isEmpty else { return }

        hasSeenWelcome = true
        let destination = shortcutDestination
        let searchQuery = shortcutSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        shortcutDestination = ""
        shortcutSearchQuery = ""

        switch destination {
        case "home":
            openTab(.home)
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

    func handleWelcomeChoice(_ choice: WelcomeChoice) {
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

    func openCoffeeConcierge() {
        isCoffeeConciergePresented = true
        showToast(message: AppLocalization.text("concierge_opened", fallback: "Coffee Concierge opened"))
    }

    func openDrinksSection() {
        openShop(category: "ready-made-drinks")
        showToast(message: AppLocalization.text("drinks_opened", fallback: "Drinks opened"))
    }

    func handleDeepLink(_ url: URL) {
        if url.scheme?.lowercased() == BenefitPaySDKConfiguration.callbackScheme {
            handleBenefitPayReturn(url)
            return
        }

        let scheme = url.scheme?.lowercased() ?? ""
        let isCustomLink = scheme == "talla"
        let isUniversalLink = ["http", "https"].contains(scheme) && isTallaUniversalLinkHost(url.host)
        guard isCustomLink || isUniversalLink else { return }

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let pathTokens = url.pathComponents.dropFirst().map { $0.lowercased() }
        let rawDestination = isCustomLink
            ? (url.host?.isEmpty == false ? url.host : pathTokens.first)
            : universalLinkDestination(pathTokens: pathTokens)
        let destination = rawDestination?.lowercased() ?? ""

        if isPaymentReturnDestination(destination: destination, pathTokens: pathTokens) {
            handlePaymentReturn(queryItems: queryItems)
            return
        }

        let searchQuery = queryItems.first(where: { $0.name == "q" || $0.name == "search" })?.value ?? ""

        if isUniversalLink, pathTokens.first == "products", let handle = pathTokens.dropFirst().first {
            openProductLink(handle: handle)
            return
        }

        if isUniversalLink, pathTokens.first == "collections", let handle = pathTokens.dropFirst().first {
            openShop(category: appCategoryKey(forCollectionHandle: handle), searchQuery: searchQuery)
            return
        }

        let supportedDestinations: Set<String> = [
            "home", "shop", "concierge", "brewing", "shelf", "favorites",
            "rewards", "orders", "order-history", "checkout-return"
        ]
        if isUniversalLink, !supportedDestinations.contains(destination) {
            openURL(url)
            return
        }

        shortcutSearchQuery = searchQuery
        shortcutDestination = destination
        handleShortcutDestination()
    }

    func isTallaUniversalLinkHost(_ host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        return host == "talla.me" || host == "www.talla.me"
    }

    func universalLinkDestination(pathTokens: [String]) -> String {
        guard let first = pathTokens.first else { return "home" }

        if first == "app" {
            return pathTokens.dropFirst().first ?? "home"
        }

        if first == "pages", pathTokens.dropFirst().first == "loyalty-program" {
            return "rewards"
        }

        if first == "blogs", pathTokens.contains("brewing-methods") {
            return "brewing"
        }

        if first == "account", pathTokens.contains("orders") {
            return "orders"
        }

        if first == "search" {
            return "shop"
        }

        return first
    }

    func appCategoryKey(forCollectionHandle handle: String) -> String {
        switch handle {
        case "coffee-beans":
            return "coffee-beans"
        case "arabic-coffee", "arabic-coffee-beans", "northern-coffee":
            return "arabic-coffee-beans"
        case "cups", "drinkware":
            return "cups"
        case "equipment", "coffee-equipment":
            return "equipment"
        case "gifts", "talla-boxes":
            return "gifts"
        case "ready-made-drinks", "drinks":
            return "ready-made-drinks"
        case "desserts", "crmb":
            return "desserts"
        default:
            return "all"
        }
    }

    func openProductLink(handle: String) {
        hasSeenWelcome = true
        pendingUniversalLinkProductHandle = handle
        openShop(searchQuery: handle.replacingOccurrences(of: "-", with: " "))
        resolvePendingUniversalLinkProduct()
    }

    func resolvePendingUniversalLinkProduct() {
        guard !pendingUniversalLinkProductHandle.isEmpty,
              let product = products.first(where: { $0.handle.caseInsensitiveCompare(pendingUniversalLinkProductHandle) == .orderedSame }) else {
            return
        }

        pendingUniversalLinkProductHandle = ""
        shopSearchQuery = ""
        selectedProduct = product
    }

    func isPaymentReturnDestination(destination: String, pathTokens: [String]) -> Bool {
        if destination == "checkout-return" || destination == "payment-return" {
            return true
        }

        guard destination == "checkout" || destination == "payment" else {
            return false
        }

        return pathTokens.contains("return") || pathTokens.contains("complete")
    }

    func handlePaymentReturn(queryItems: [URLQueryItem]) {
        if !activeEazyShopifyPaymentID.isEmpty {
            checkoutSession = nil
            paymentFlow.transition(to: .processing)
            presentPostPayment()
            Task {
                await waitForEazyShopifyProgress(openHostedCheckout: false)
            }
            return
        }
        if paymentFlow.selectedMethod == .benefit, !postPaymentOrderID.isEmpty {
            checkoutSession = nil
            paymentFlow.transition(to: .processing)
            presentPostPayment()
            Task {
                await waitForBenefitHostedProgress()
            }
            return
        }
        if paymentFlow.selectedMethod == .clickToPay, !postPaymentOrderID.isEmpty {
            paymentFlow.transition(to: .processing)
            checkoutSession = nil
            presentPostPayment()
            Task {
                await waitForClickToPayProgress()
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

        switch status {
        case "success", "succeeded", "paid", "captured", "approved":
            cartItems.removeAll()
            appliedVoucher = nil
            voucherCodeInput = ""
            voucherError = nil
            paymentFlow.transition(to: .succeeded)
        case "cancelled", "canceled", "cancel":
            paymentFlow.transition(to: .cancelled)
        case "failed", "failure", "declined", "error", "not_captured":
            paymentFlow.transition(
                to: .failed,
                error: message ?? AppLocalization.text("payment_failed_detail", fallback: "Please check your details or try another payment method.")
            )
        default:
            paymentFlow.transition(to: .processing)
        }
        presentPostPayment()

        Task {
            await loadOrderHistory()
            if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await loadLoyaltyAccount()
            }
        }
    }

    @MainActor
    func waitForClickToPayProgress() async {
        let orderID = postPaymentOrderID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !orderID.isEmpty else {
            paymentFlow.transition(
                to: .failed,
                error: AppLocalization.text(
                    "payment_verification_unavailable",
                    fallback: "Payment verification is temporarily unavailable."
                )
            )
            return
        }

        for attempt in 0 ..< 20 {
            do {
                let payment = try await TallaPaymentService.retrieveOrder(orderID: orderID)
                let status = payment.status.lowercased()
                if payment.confirmed {
                    cartItems.removeAll()
                    appliedVoucher = nil
                    voucherCodeInput = ""
                    voucherError = nil
                    paymentFlow.transition(to: .succeeded)
                    await loadOrderHistory()
                    if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        await loadLoyaltyAccount()
                    }
                    return
                }
                if status.contains("cancel") {
                    paymentFlow.transition(to: .cancelled)
                    return
                }
                if status.contains("fail") || status.contains("declin") || status.contains("error") {
                    paymentFlow.transition(
                        to: .failed,
                        error: AppLocalization.text(
                            "payment_failed_detail",
                            fallback: "Please check your details or try another payment method."
                        )
                    )
                    return
                }
            } catch {
                if attempt == 19 {
                    checkoutError = customerFacingServiceMessage(
                        for: error,
                        fallback: AppLocalization.text(
                            "payment_verification_unavailable",
                            fallback: "Payment verification is temporarily unavailable."
                        )
                    )
                }
            }

            if attempt < 19 {
                try? await Task.sleep(for: .seconds(1.5))
            }
        }

        isPostPaymentPresented = false
        paymentFlow.reset()
        await loadOrderHistory()
        openAccountSection(AccountSectionView.ScrollTarget.customer)
        showToast(message: AppLocalization.text(
            "payment_verifying",
            fallback: "Payment is still being verified. You can safely return later."
        ))
    }

    @MainActor
    func waitForBenefitHostedProgress() async {
        let orderID = postPaymentOrderID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !orderID.isEmpty else {
            paymentFlow.transition(
                to: .failed,
                error: AppLocalization.text(
                    "payment_verification_unavailable",
                    fallback: "Payment verification is temporarily unavailable."
                )
            )
            return
        }

        for attempt in 0 ..< 20 {
            do {
                let status = try await AccountService.fetchBenefitPaymentStatus(orderID: orderID)
                if status.paid || status.status == "succeeded" {
                    cartItems.removeAll()
                    appliedVoucher = nil
                    voucherCodeInput = ""
                    voucherError = nil
                    paymentFlow.transition(to: .succeeded)
                    await loadOrderHistory()
                    if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        await loadLoyaltyAccount()
                    }
                    return
                }
                if status.status == "cancelled" {
                    paymentFlow.transition(to: .cancelled)
                    return
                }
                if status.status == "failed" {
                    paymentFlow.transition(
                        to: .failed,
                        error: AppLocalization.text(
                            "payment_failed_detail",
                            fallback: "Please check your details or try another payment method."
                        )
                    )
                    return
                }
            } catch {
                if attempt == 19 {
                    checkoutError = customerFacingServiceMessage(
                        for: error,
                        fallback: AppLocalization.text(
                            "payment_verification_unavailable",
                            fallback: "Payment verification is temporarily unavailable."
                        )
                    )
                }
            }

            if attempt < 19 {
                try? await Task.sleep(for: .seconds(1.5))
            }
        }

        isPostPaymentPresented = false
        paymentFlow.reset()
        await loadOrderHistory()
        openAccountSection(AccountSectionView.ScrollTarget.customer)
        showToast(message: AppLocalization.text(
            "payment_verifying",
            fallback: "Payment is still being verified. You can safely return later."
        ))
    }

}
