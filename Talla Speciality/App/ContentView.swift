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
    @AppStorage("tasteProfile.acidity") var tasteProfileAcidity = "balanced"
    @AppStorage("tasteProfile.sweetness") var tasteProfileSweetness = "sweet"
    @AppStorage("tasteProfile.body") var tasteProfileBody = "balanced"
    @AppStorage("tasteProfile.roast") var tasteProfileRoast = "medium"
    @AppStorage("tasteProfile.temperature") var tasteProfileTemperature = "hot"
    @AppStorage("tasteProfile.style") var tasteProfileStyle = "modern"
    @AppStorage("tasteProfile.configured") var tasteProfileConfigured = false
    @State var products: [Product] = []
    @State var pendingUniversalLinkProductHandle = ""
    @State var pendingBrewingCoffeeName = ""
    @State var pendingBrewingCoffeeOrigin = ""
    @State var pendingBrewingCoffeeNotes = ""
    @State var pendingRecommendedRecipe = false
    @State var cartItems: [CartItem] = []
    @State var isCoffeeClubPrepaid = false
    @State var coffeeClubTermsAccepted = false
    @State var isCafePassPrepaid = false
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
    @State var pendingBrewHealthID: UUID?
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
    @State var cachedHomePurchasedCoffeeProducts: [Product] = []
    @State var cachedHomeBagCounts: [String: Int] = [:]
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
    @AppStorage("loyalty.phase6.completed") var phaseSixCompletedPayload = ""
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
    @State var birthdayMonth = ""
    @State var birthdayDay = ""
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
    @State var fulfillmentMethod: TallaFulfillmentMethod = .delivery; @State var selectedPickupSlot = "10:00–12:00"; @State var selectedPickupLocationID = ""
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
    @State var isAccountPresentedFromMore = false
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

}
