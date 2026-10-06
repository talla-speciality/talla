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
    enum Tab: String, CaseIterable, Identifiable {
        case home
        case shop
        case club
        case brewing
        case map
        case account
        case more
        case search

        var id: String { rawValue }

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
            case .map:
                return "map"
            case .account:
                return "person"
            case .more:
                return "ellipsis"
            case .search:
                return "magnifyingglass"
            }
        }
    }

    enum SettingsDetail: String, Identifiable {
        case language
        case notifications
        case appIcon
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
        var tags: [String] = []
        let countryOfOrigin: String?
        var roastDate: Date? = nil
        let isAvailableForSale: Bool
        var catalogSourceText: String? = nil

        var catalogClassificationText: String {
            catalogSourceText ?? "\(name) \(desc) \(categoryLabel)"
        }

        var isGiftCardProduct: Bool {
            let text = ([name, handle, categoryKey, categoryLabel, desc, catalogSourceText ?? ""] + tags)
                .joined(separator: " ").lowercased().replacingOccurrences(of: "-", with: " ")
            return text.contains("gift card") || text.contains("giftcard") || text.contains("e gift")
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

        struct AppFeatures: Decodable {
            let showBrewingGuides: Bool
            let showCommunityRecipes: Bool
            let showEspressoWorkspace: Bool
            let showGulfCoffeeMap: Bool
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
            struct Plan: Decodable, Identifiable {
                let id: String
                let enabled: Bool
                let group: String
                let icon: String
                let titleEN: String
                let titleAR: String
                let detailEN: String
                let detailAR: String
                let categoryKey: String
                let productIDs: [String]?
            }

            let enabled: Bool
            let shipmentCount: Int
            let intervalWeeks: Int
            let discountPercent: Int
            let productIDs: [String]?
            let plans: [Plan]?
        }

        struct CoffeeMemory: Decodable {
            let enabled: Bool
            let automaticPurchaseImport: Bool
            let roastDateOCR: Bool
            let replacementRecommendations: Bool
        }

        struct Fulfillment: Decodable {
            struct Location: Decodable, Identifiable {
                let id: String
                let nameEN: String
                let nameAR: String
                let addressEN: String
                let addressAR: String
                let mapsURL: String
                let openingHoursEN: String
                let openingHoursAR: String
                let temporaryClosureEN: String?
                let temporaryClosureAR: String?
                let pickupSlots: [PickupSlot]?
            }
            struct ShippingTier: Decodable {
                let maximumWeightGrams: Double
                let rate: Double
            }
            struct PickupSlot: Decodable, Identifiable {
                let id: String
                let labelEN: String
                let labelAR: String
                let remaining: Int
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
            let temporaryClosureEN: String?
            let temporaryClosureAR: String?
            let pickupSlots: [PickupSlot]?
            let locations: [Location]?
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
            let reserveThreshold: Int?
            let rewardStep: Int
            let freeDeliveryThresholds: [String: Double]?
            let earlyAccessEnabled: Bool?
            let earlyAccessMinimumTier: String?
            let rewards: [Reward]
        }

        let announcement: Announcement
        let support: Support
        let homeSections: HomeSections
        let appFeatures: AppFeatures?
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
        let streakDays: Int?
        let nextTier: String?
        let beansUntilNextTier: Int?
        let birthdayRewardAvailable: Bool?
        let crossCafeVisits: Int?
        let visitedCafeIDs: [String]?
        let crossCafeReward: CrossCafeReward?
        let visitStreakDays: Int?

        struct CrossCafeReward: Codable {
            let requiredCafes: Int
            let bonusBeans: Int
            let completed: Bool
        }
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
        var isPaidForCafePass: Bool { ["Confirmed", "Completed", "Fulfilled", "Delivered", "Ready"].contains(status) }

        struct Details: Decodable {
            struct Fulfillment: Decodable {
                let method: String?
            }
            struct Tracking: Decodable {
                let company: String?
                let number: String?
                let url: String?
            }
            struct Payment: Decodable {
                let method: String?
                let status: String?
                let refundedAmount: Double?
            }
            struct CafePass: Decodable {
                let creditCount: Int
                let redeemedCredits: Int
                let suspendedCoffee: Bool?
                let giftedCoffee: Bool?
                let giftToken: String?
                let drinkName: String
                let status: String
                let expiresAt: String?
                let variantId: String?
                let unitPriceFils: Int?
                var remainingCredits: Int { max(0, creditCount - redeemedCredits) }
            }
            struct SupportCase: Decodable {
                let id: String?
                let status: String?
                let type: String?
                let note: String?
                let createdAt: String?
                let updatedAt: String?
            }
            let fulfillment: Fulfillment?
            let tracking: Tracking?
            let payment: Payment?
            let coffeeClub: CustomerCoffeeClub?
            let cafePass: CafePass?
            let supportCase: SupportCase?
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

        var isRefunded: Bool {
            let paymentStatus = details?.payment?.status?.lowercased() ?? ""
            return paymentStatus == "refunded" || paymentStatus == "partially_refunded" || status.lowercased() == "refunded"
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

    struct TasteProfileRecord: Codable, Hashable {
        let acidity: String
        let sweetness: String
        let body: String
        let roast: String
        let temperature: String
        let style: String
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
}
