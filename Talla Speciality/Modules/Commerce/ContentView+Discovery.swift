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

struct DuoToolbarBehavior: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension ContentView {
    var header: some View {
        VStack(spacing: isShortHeight ? 4 : 6) {
            HStack {
                Button {
                    openTab(.home)
                } label: {
                    HStack(spacing: 12) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: isShortHeight ? 38 : (customerProfile == nil ? 48 : 46),
                                height: isShortHeight ? 38 : (customerProfile == nil ? 48 : 46)
                            )

                        if let customerProfile {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AppLocalization.text("welcome_back", fallback: "Welcome back,"))
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(AppLocalization.letterSpacing(1.5))
                                    .textCase(.uppercase)
                                    .foregroundColor(readableBrandGoldColor)

                                Text(customerFirstName(for: customerProfile))
                                    .font(displayFont(size: isShortHeight ? 21 : (isCompact ? 26 : 27)))
                                    .foregroundColor(primaryTextColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        } else {
                            Text("TALLA")
                                .font(displayFont(size: isShortHeight ? 25 : (isCompact ? 31 : 30)))
                                .tracking(isCompact ? 1.5 : 2)
                                .foregroundColor(primaryTextColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if !usesSystemNavigationActions && !showLaunchSplash && shouldShowHeaderCartButton {
                    headerCartButton
                }

                if !usesSystemNavigationActions {
                    appearanceMenu
                }
            }
        }
        .padding(.horizontal, isShortHeight ? 12 : 16)
        .padding(.top, isShortHeight ? 7 : 12)
        .padding(.bottom, isShortHeight ? 7 : 12)
        .background(Color.clear)
    }

    var usesSystemNavigationActions: Bool {
        if #available(iOS 27.1, *) { return true }
        return false
    }

    var appearanceMenu: some View {
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
                    Label(AppLocalization.text("appearance_and_language", fallback: "Appearance and language"), systemImage: "circle.lefthalf.filled")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(readableBrandGoldColor)
                        .frame(width: 40, height: 40)
                        .background(cardFillColor)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.14), lineWidth: 1)
                        )
                }
                .menuStyle(.button)
                .accessibilityLabel(AppLocalization.text("appearance_and_language", fallback: "Appearance and language"))
    }

    var headerCartButton: some View {
        HeaderCartButton(
            cartCount: cartCount,
            showingCelebration: showingCartCelebration,
            celebrationID: cartCelebrationID,
            isLightAppearance: isLightAppearance,
            cardFillColor: cardFillColor
        ) {
            withAnimation(.easeInOut(duration: 0.18)) {
                cartOpen = true
            }
        }
    }
}

private struct HeaderCartButton: View {
    let cartCount: Int
    let showingCelebration: Bool
    let celebrationID: Int
    let isLightAppearance: Bool
    let cardFillColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                if showingCelebration {
                    Circle()
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.32 : 0.42), lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .scaleEffect(1.42)
                        .opacity(0.55)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                Image(systemName: cartCount > 0 ? "bag.fill" : "bag")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(cartCount > 0 ? Color(hex: 0x0A0804) : TallaTheme.Colors.accent)
                    .symbolEffect(.bounce, value: celebrationID)
                    .frame(width: 40, height: 40)
                    .background(cartCount > 0 ? TallaTheme.Colors.accent : cardFillColor)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.20 : 0.14), lineWidth: 1)
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
            .scaleEffect(showingCelebration ? 1.16 : 1)
            .rotationEffect(.degrees(showingCelebration ? -4 : 0))
            .animation(.spring(response: 0.26, dampingFraction: 0.48), value: showingCelebration)
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
}

extension ContentView {

    // The home screen is the customer's coffee control centre. These small,
    // data-backed shelves make the existing taste, brew, loyalty, and order
    // history useful before the customer starts browsing the catalogue.
    var savedTasteProfile: TasteProfileRecord {
        TasteProfileRecord(
            acidity: tasteProfileAcidity,
            sweetness: tasteProfileSweetness,
            body: tasteProfileBody,
            roast: tasteProfileRoast,
            temperature: tasteProfileTemperature,
            style: tasteProfileStyle
        )
    }

    var tasteProfileLabels: [String] {
        guard tasteProfileConfigured else { return [] }
        let profile = savedTasteProfile
        let labels: [(String, String)] = [
            (profile.acidity == "low" ? "taste_acidity_low" : profile.acidity == "high" ? "taste_acidity_high" : "taste_acidity_balanced", profile.acidity),
            (profile.sweetness == "subtle" ? "taste_sweetness_subtle" : "taste_sweetness_sweet", profile.sweetness),
            (profile.body == "light" ? "taste_body_light" : profile.body == "full" ? "taste_body_full" : "taste_body_balanced", profile.body),
            (profile.roast == "light" ? "taste_roast_light" : profile.roast == "dark" ? "taste_roast_dark" : "taste_roast_medium", profile.roast),
            (profile.temperature == "iced" ? "taste_temperature_iced" : "taste_temperature_hot", profile.temperature),
            (profile.style == "arabic" ? "taste_style_arabic" : "taste_style_modern", profile.style)
        ]
        return labels.map { AppLocalization.text($0.0, fallback: $0.1.capitalized) }
    }

    var homeTasteProfileTags: [String] {
        let memoryWords = tasteMemoryRecords
            .flatMap { [$0.reaction] + $0.tags }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        var tags: [String] = []
        let candidates: [(String, [String])] = [
            ("Bright", ["bright", "acid", "acidity", "fruity", "floral"]),
            ("Sweet", ["sweet", "caramel", "chocolate", "honey"]),
            ("Full body", ["body", "bold", "rich", "heavy"]),
            ("Light roast", ["light", "light roast"]),
            ("Iced", ["iced", "cold"]),
            ("Arabic coffee", ["arabic", "qahwa", "cardamom"])
        ]

        for (label, keywords) in candidates where keywords.contains(where: { keyword in
            memoryWords.contains(where: { $0.contains(keyword) })
        }) {
            tags.append(label)
        }

        tags.append(contentsOf: tasteProfileLabels)

        if tags.isEmpty, let firstRecommendation = recommendedProducts.first {
            let source = firstRecommendation.catalogClassificationText.lowercased()
            if source.contains("arabic") || source.contains("qahwa") {
                tags.append("Arabic coffee")
            } else if source.contains("fruit") || source.contains("floral") || source.contains("ethiopia") {
                tags.append("Bright")
            } else {
                tags.append("Balanced")
            }
        }

        return Array(tags.prefix(6))
    }

    var homeHasPersonalizationSignals: Bool {
        !UserDefaults.standard.bool(forKey: "privacy.personalization.optOut")
            && (tasteProfileConfigured
            || !tasteMemoryRecords.isEmpty
            || !favoriteProducts.isEmpty
            || !recentlyViewedProducts.isEmpty
            || !orderedProducts.isEmpty)
    }

    var homeTasteProfileSummary: String {
        guard tasteProfileConfigured else {
            return AppLocalization.text("taste_profile_setup_detail", fallback: "Set your preferences so Talla can learn the cup you like.")
        }
        let tags = homeTasteProfileTags
        if tags.isEmpty {
            return AppLocalization.text("taste_profile_empty", fallback: "Tell us what you like and Talla will learn your cup.")
        }
        return tags.prefix(6).joined(separator: " · ")
    }

    var homeUsualProduct: Product? {
        reorderPrompt?.product ?? orderedProducts.first
    }

    var homePurchasedCoffeeProducts: [Product] {
        orderedProducts.filter { product in
            ["coffee-beans", "arabic-coffee-beans"].contains(product.categoryKey)
                && homeAvailableBagCount(for: product) > 0
        }
    }

    func homeAvailableBagCount(for product: Product) -> Int {
        _ = coffeeData.changeToken
        let lotsByID = Dictionary(uniqueKeysWithValues: coffeeData.beanLots().map { ($0.id, $0) })

        return coffeeData.inventory().reduce(into: 0) { count, inventory in
            let lot = inventory.lotID.flatMap { lotsByID[$0] }
            let matchesProduct = lot?.productID == product.id
                || matchingProduct(for: inventory.productName)?.id == product.id
            guard inventory.remainingQuantityGrams > 0, matchesProduct else { return }

            let variant = lot?.variantID.flatMap { variantID in
                product.variants.first {
                    $0.id == variantID || $0.id.hasSuffix("/\(variantID)") || variantID.hasSuffix("/\($0.id)")
                }
            }
            let unitGrams = max(variant?.weightGrams ?? product.defaultVariant?.weightGrams ?? inventory.initialQuantityGrams, 1)
            count += max(1, Int(ceil(inventory.remainingQuantityGrams / unitGrams)))
        }
    }

    var homeBrewRecommendation: Product? {
        let coffeeProducts = recommendedProducts.filter(isBrewableCoffee)
        return coffeeProducts.first ?? signatureRoastProducts.first(where: isBrewableCoffee)
    }

    var homeFreshRoastProducts: [Product] {
        let freshCutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .distantPast
        return products
            .filter { product in
                product.isAvailableForSale
                    && ["coffee-beans", "arabic-coffee-beans"].contains(product.categoryKey.lowercased())
                    && product.roastDate.map { $0 >= freshCutoff && $0 <= .now } == true
            }
            .sorted { ($0.roastDate ?? .distantPast) > ($1.roastDate ?? .distantPast) }
            .prefix(4)
            .map { $0 }
    }

    var homeNearYouProducts: [Product] {
        let availableDrinks = quickDrinkProducts
        if !availableDrinks.isEmpty { return Array(availableDrinks.prefix(4)) }
        return Array(products.filter { $0.isAvailableForSale && $0.categoryKey == "ready-made-drinks" }.prefix(4))
    }

    var homeNearYouTitle: String {
        guard let city = preferredAddress?.city.trimmingCharacters(in: .whitespacesAndNewlines), !city.isEmpty else {
            return AppLocalization.text("talla_express", fallback: "Talla Express")
        }
        return AppLocalization.text("near_you_now", fallback: "Near you now")
    }

    var homeNearYouDetail: String {
        guard let city = preferredAddress?.city.trimmingCharacters(in: .whitespacesAndNewlines), !city.isEmpty else {
            return AppLocalization.text("available_to_order", fallback: "Available to order")
        }
        return String(format: AppLocalization.text("order_in_city_format", fallback: "Order for %@"), city)
    }

    @ViewBuilder
    var homePersonalizedHub: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("your_coffee_today", fallback: "Your coffee today"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(AppLocalization.letterSpacing(2.1))
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)
                    Text(AppLocalization.text("todays_brew_title", fallback: "Today's brew"))
                        .font(displayFont(size: isCompact ? 24 : 28))
                        .foregroundColor(primaryTextColor)
                }
                Spacer(minLength: 8)
                Button {
                    openTasteProfileEditor()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(readableBrandGoldColor)
                        .frame(width: 40, height: 40)
                        .background(cardFillColor, in: Circle())
                        .overlay(Circle().stroke(TallaTheme.Colors.accent.opacity(0.22), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text(tasteProfileConfigured ? "edit_taste" : "taste_setup_action", fallback: tasteProfileConfigured ? "Edit taste" : "Set your taste"))
            }

            if let product = homeBrewRecommendation {
                homeFeaturedBrewCard(product)
            } else {
                homeEmptyBrewCard
            }

            HStack(spacing: 10) {
                if homePurchasedCoffeeProducts.isEmpty, let product = homeUsualProduct {
                    homeCompactShortcut(
                        title: AppLocalization.text("your_usual", fallback: "Your usual"),
                        detail: customerFacingProductName(for: product),
                        systemImage: "cup.and.saucer.fill"
                    ) { quickBuyDrink(product) }
                } else if homePurchasedCoffeeProducts.isEmpty {
                    homeCompactShortcut(
                        title: AppLocalization.text("your_usual", fallback: "Your usual"),
                        detail: AppLocalization.text("usual_empty_detail", fallback: "Your go-to coffee will appear here after your first order."),
                        systemImage: "cup.and.saucer.fill"
                    ) { openShop(category: "coffee-beans") }
                }

                homeCompactShortcut(
                    title: AppLocalization.text("your_beans_rewards", fallback: "Beans & rewards"),
                    detail: loyaltyAccount.map { String(format: AppLocalization.text("beans_tier_format", fallback: "%d Beans · %@"), $0.pointsBalance, $0.tier) } ?? AppLocalization.text("rewards_membership_detail", fallback: "View your rewards"),
                    systemImage: "sparkles"
                ) { openAccountSection(AccountSectionView.ScrollTarget.loyalty) }
            }

            if let brew = brewAgainHistoryItems.first {
                Button {
                    continueHomeBrew(brew)
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "arrow.counterclockwise")
                        Text(AppLocalization.text("continue_last_brew", fallback: "Continue your last brew"))
                        Text("· \(brew.title)").lineLimit(1)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.right")
                    }
                    .font(labelFont(size: 10, weight: .semibold))
                    .foregroundColor(secondaryTextColor)
                    .padding(.top, 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    func homeFeaturedBrewCard(_ product: Product) -> some View {
        Button {
            startBrewing(product: product, useRecommendedRecipe: true)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalization.text("brew_this_morning", fallback: "Brew this morning").uppercased())
                        .font(labelFont(size: 9, weight: .bold))
                        .tracking(AppLocalization.letterSpacing(1.5))
                        .foregroundColor(Color(hex: 0xE7C28D))
                        .lineLimit(1)
                    Text(customerFacingProductName(for: product))
                        .font(displayFont(size: isCompact ? 21 : 25))
                        .foregroundColor(Color(hex: 0xFFF8EF))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(homeHasPersonalizationSignals
                         ? productTasteSummary(for: product)
                         : AppLocalization.text("brew_guide_detail", fallback: "A Talla brewing guide for this coffee"))
                        .font(bodyFont(size: 11))
                        .foregroundColor(Color(hex: 0xE9DED0).opacity(0.86))
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        Text(AppLocalization.text("start_brewing", fallback: "Start brewing"))
                            .font(labelFont(size: 10, weight: .bold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0x29190D))
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(Color(hex: 0xD7AD78), in: Capsule())
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                ProductThumbnail(imageURL: product.imageURL, size: isCompact ? 104 : 126, cornerRadius: 17)
                    .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(Color(hex: 0xD7AD78).opacity(0.3), lineWidth: 1))
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: isCompact ? 178 : 202, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [Color(hex: 0x322116), Color(hex: 0x1C130D)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 23, style: .continuous)
            )
            .overlay(RoundedRectangle(cornerRadius: 23, style: .continuous).stroke(Color(hex: 0xC8965A).opacity(0.3), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    var homeEmptyBrewCard: some View {
        Button { openShop() } label: {
            HStack(spacing: 14) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(Color(hex: 0xE7C28D))
                    .frame(width: 56, height: 56)
                    .background(Color.white.opacity(0.08), in: Circle())
                VStack(alignment: .leading, spacing: 5) {
                    Text(AppLocalization.text("discover_at_talla", fallback: "Discover at Talla"))
                        .font(displayFont(size: 20))
                        .foregroundColor(Color(hex: 0xFFF8EF))
                    Text(AppLocalization.text("first_brew_detail", fallback: "Choose a coffee and Talla will help you make your first cup."))
                        .font(bodyFont(size: 12))
                        .foregroundColor(Color(hex: 0xE9DED0).opacity(0.85))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .foregroundColor(Color(hex: 0xE7C28D))
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 112)
            .background(LinearGradient(colors: [Color(hex: 0x322116), Color(hex: 0x1C130D)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 23, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func homeCompactShortcut(title: String, detail: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(readableBrandGoldColor)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(labelFont(size: 9, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                    Text(detail)
                        .font(bodyFont(size: 10))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(cardFillColor)
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(TallaTheme.Colors.accent.opacity(0.18), lineWidth: 0.8))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    func homeShortcutCard(title: String, detail: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(readableBrandGoldColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(labelFont(size: 9, weight: .bold)).foregroundColor(primaryTextColor).lineLimit(1)
                    Text(detail).font(bodyFont(size: 10)).foregroundColor(secondaryTextColor).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 13)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(cardFillColor.opacity(isLightAppearance ? 0.78 : 0.62))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(TallaTheme.Colors.accent.opacity(0.16), lineWidth: 0.8))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func homePersonalizedProductCard(title: String, detail: String, product: Product, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 13)
                    .frame(height: isCompact ? 64 : 78)
                Text(title)
                    .font(labelFont(size: 9, weight: .bold))
                    .tracking(AppLocalization.letterSpacing(0.8))
                    .foregroundColor(readableBrandGoldColor)
                    .lineLimit(1)
                Text(customerFacingProductName(for: product))
                    .font(displayFont(size: 16))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                Text(detail)
                    .font(bodyFont(size: 11))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFillColor.opacity(isLightAppearance ? 0.78 : 0.64))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(TallaTheme.Colors.accent.opacity(0.2), lineWidth: 0.8))
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(width: isCompact ? 174 : 206, height: isCompact ? 194 : 210, alignment: .topLeading)
    }

    func homePersonalizedActionCard(title: String, detail: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(readableBrandGoldColor)
                Text(title)
                    .font(labelFont(size: 10, weight: .bold))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                Text(detail)
                    .font(bodyFont(size: 11))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(3)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: isCompact ? 110 : 120, alignment: .topLeading)
            .background(cardFillColor)
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(TallaTheme.Colors.accent.opacity(0.12), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
        }
        .buttonStyle(.plain)
        .frame(width: isCompact ? 174 : 206, height: isCompact ? 194 : 210, alignment: .topLeading)
    }

    func continueHomeBrew(_ brew: BrewRecipeRecord) {
        brewRecipeName = brew.title
        if let coffeeGrams = brew.coffeeGrams {
            ratioCoffeeInput = formattedRatioValue(coffeeGrams)
        }
        if let ratio = brew.ratio {
            ratioValueInput = formattedRatioValue(ratio)
        }
        openBrewing()
    }

    func openTasteProfileEditor() {
        openShop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            isCoffeeQuizExpanded = true
        }
    }

    var homeView: some View {
        VStack(spacing: 0) {
            homePurchasedCoffeeShelf
            if remoteAppSettings?.homeSections.showQuickDrinks != false {
                homeQuickDrinks
            }
            if remoteAppSettings?.homeSections.showSignatureRoasts != false {
                featuredProducts
            }
            seasonalEventsSection
            appAnnouncementCard
            optionalAppUpdateCard

            homeMoreSectionsToggle

            if isHomeMoreExpanded {
                Group {
                    if remoteAppSettings?.homeSections.showFunPick != false {
                        homeSurprisePick
                    }
                    if remoteAppSettings?.homeSections.showPassport != false {
                        tallaPassportSection
                    }
                    homeRecentlyViewedShelf
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    var homePurchasedCoffeeShelf: some View {
        if !homePurchasedCoffeeProducts.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    Text(AppLocalization.text("coffee_shelf", fallback: "Coffee Shelf"))
                        .font(.system(size: isCompact ? 20 : 22, weight: .bold))
                        .foregroundColor(Color(hex: 0x4A2410))

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(woodPlankGradient)
                .overlay(Rectangle().fill(Color.white.opacity(0.22)).frame(height: 1), alignment: .top)
                .overlay(Rectangle().fill(Color(hex: 0x6E3415).opacity(0.42)).frame(height: 2), alignment: .bottom)

                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color(hex: 0xEDBC70), Color(hex: 0xCF8741), Color(hex: 0xE5A95A)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    LinearGradient(
                        colors: [Color(hex: 0x6E3415).opacity(0.34), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 22)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .allowsHitTesting(false)

                    VStack(spacing: 27) {
                        ForEach(0..<8, id: \.self) { _ in
                            Rectangle()
                                .fill(Color(hex: 0x7B401D).opacity(0.075))
                                .frame(height: 1)
                        }
                    }
                    .padding(.horizontal, 8)
                    .allowsHitTesting(false)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: isCompact ? 12 : 20) {
                            ForEach(homePurchasedCoffeeProducts) { product in
                                homePurchasedCoffeeBagCard(product)
                            }
                        }
                        .padding(.horizontal, 14)
                        .frame(height: isCompact ? 164 : 180, alignment: .bottom)
                    }
                    .frame(height: isCompact ? 164 : 180, alignment: .bottom)

                }
                .frame(height: isCompact ? 164 : 180)
                .clipped()

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color(hex: 0xF8D99A))
                        .frame(height: 7)
                        .shadow(color: .black.opacity(0.32), radius: 5, y: -3)
                    Rectangle()
                        .fill(woodPlankGradient)
                        .frame(height: 19)
                        .overlay(Rectangle().fill(Color.black.opacity(0.22)).frame(height: 2), alignment: .bottom)
                }
            }
            .background(woodCabinetGradient)
            .clipShape(Rectangle())
            .shadow(color: .black.opacity(isLightAppearance ? 0.20 : 0.42), radius: 18, y: 11)
            .padding(.bottom, 22)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("home.purchasedCoffeeShelf")
        }
    }

    var woodPlankGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xF5D08A), Color(hex: 0xD89A4F), Color(hex: 0xEDBE70)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var woodCabinetGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xE7B366), Color(hex: 0xB86D32), Color(hex: 0xD99549)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    func shelfBagImage(for product: Product) -> some View {
        ZStack {
            if let imageURL = product.imageURL {
                AsyncImage(url: imageURL, transaction: Transaction(animation: nil)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(Color(hex: 0x9B5A2B))
                    case .success(let image):
                        image
                            .resizable()
                            .interpolation(.high)
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "bag.fill")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(Color(hex: 0x9B5A2B).opacity(0.72))
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            } else {
                Image(systemName: "bag.fill")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(Color(hex: 0x9B5A2B).opacity(0.72))
            }
        }
        .contentShape(Rectangle())
    }

    func homePurchasedCoffeeBagCard(_ product: Product) -> some View {
        let availableBagCount = homeAvailableBagCount(for: product)

        return Button {
            recordRecentlyViewed(product)
            selectedProduct = product
        } label: {
            ZStack(alignment: .topTrailing) {
                shelfBagImage(for: product)
                    .frame(width: isCompact ? 100 : 116, height: isCompact ? 154 : 170)
                    .scaleEffect(1.18, anchor: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .shadow(color: .black.opacity(0.30), radius: 6, x: 1, y: 4)
                    .offset(y: isCompact ? 7 : 8)

                if availableBagCount > 1 {
                    Text(availableBagCount > 99 ? "99+" : "\(availableBagCount)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(minWidth: 23, minHeight: 23)
                        .padding(.horizontal, availableBagCount > 99 ? 3 : 0)
                        .background(Color(hex: 0xE53B36), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.88), lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.28), radius: 3, y: 2)
                        .offset(x: isCompact ? 3 : 5, y: -3)
                        .accessibilityLabel("\(availableBagCount) bags remaining")
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.purchasedCoffeeShelf.bag.\(product.id)")
        .accessibilityLabel(
            availableBagCount > 1
                ? "\(customerFacingProductName(for: product)), \(availableBagCount) bags remaining"
                : customerFacingProductName(for: product)
        )
        .frame(width: isCompact ? 116 : 138, alignment: .bottom)
    }

    var homeMoreSectionsToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                isHomeMoreExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(AppLocalization.text("more_from_talla", fallback: "More from Talla"))
                        .font(titleFont(size: 17))
                        .foregroundColor(primaryTextColor)
                    Text(AppLocalization.text("more_from_talla_summary", fallback: "Surprise picks, passport, and recent discoveries"))
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: isHomeMoreExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
            }
            .padding(15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.18 : 0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
        .padding(.bottom, 18)
        .accessibilityValue(isHomeMoreExpanded
            ? AppLocalization.text("expanded", fallback: "Expanded")
            : AppLocalization.text("collapsed", fallback: "Collapsed"))
    }

    @ViewBuilder
    var appAnnouncementCard: some View {
        if let announcement = remoteAppSettings?.announcement,
           announcement.enabled,
           !announcement.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !announcement.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Label(announcement.title, systemImage: "megaphone.fill")
                    .font(titleFont(size: 18))
                    .foregroundColor(primaryTextColor)

                Text(announcement.message)
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                if !announcement.actionLabel.isEmpty,
                   let actionURL = URL(string: announcement.actionURL),
                   ["https", "talla"].contains(actionURL.scheme?.lowercased()) {
                    Button(announcement.actionLabel) {
                        openURL(actionURL)
                    }
                    .font(labelFont(size: 11, weight: .bold))
                    .buttonStyle(.tallaPrimary)
                    .tint(TallaTheme.Colors.accent)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.24 : 0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
        }
    }

    @ViewBuilder
    var optionalAppUpdateCard: some View {
        if hasOptionalAppUpdate, let release = remoteAppSettings?.release {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.app.fill")
                    .foregroundColor(readableBrandGoldColor)
                Text(isArabicInterface ? release.updateMessageAR : release.updateMessageEN)
                    .font(bodyFont(size: 13))
                    .foregroundColor(primaryTextColor)
                Spacer(minLength: 6)
                if let url = URL(string: release.appStoreURL), !release.appStoreURL.isEmpty {
                    Button(isArabicInterface ? "تحديث" : "Update") { openURL(url) }
                        .font(labelFont(size: 10, weight: .bold))
                        .buttonStyle(.tallaSecondary)
                        .tint(TallaTheme.Colors.accent)
                }
            }
            .padding(14)
            .background(cardFillColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    var seasonalEventsSection: some View {
        if !activeSeasonalEvents.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text(eventText(english: "Seasonal at Talla", arabic: "المواسم في تالا"))
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 2.2)
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(activeSeasonalEvents) { event in
                            seasonalEventCard(event)
                        }
                    }
                }
                .scrollClipDisabled()
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
    }

    func seasonalEventCard(_ event: EventSettings.SeasonalEvent) -> some View {
        let accent = eventColor(event.accentHex, fallback: 0xC8965A)
        let secondary = eventColor(event.secondaryHex, fallback: 0x2A1D14)
        let targetCategory = seasonalEventCategories.contains(where: { $0.key == eventCategoryKey(event) })
            ? eventCategoryKey(event)
            : "all"

        return Button {
            openShop(category: targetCategory)
        } label: {
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: [secondary, secondary.opacity(0.88), accent.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let imageURL = URL(string: event.imageURL), !event.imageURL.isEmpty {
                    AsyncImage(url: imageURL, transaction: Transaction(animation: nil)) { phase in
                        if case let .success(image) = phase {
                            image
                                .resizable()
                                .scaledToFill()
                                .overlay(LinearGradient(colors: [secondary.opacity(0.92), secondary.opacity(0.30)], startPoint: .leading, endPoint: .trailing))
                        }
                    }
                } else {
                    Image(systemName: event.symbol.isEmpty ? "sparkles" : event.symbol)
                        .font(.system(size: 86, weight: .semibold))
                        .foregroundColor(accent.opacity(0.25))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.trailing, 22)
                }

                VStack(alignment: .leading, spacing: 8) {
                    let badge = eventText(english: event.badgeEN, arabic: event.badgeAR)
                    if !badge.isEmpty {
                        Text(badge)
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.6)
                            .textCase(.uppercase)
                            .foregroundColor(secondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(accent)
                            .clipShape(Capsule())
                    }

                    Text(eventText(english: event.titleEN, arabic: event.titleAR, fallback: event.name))
                        .font(displayFont(size: 25))
                        .foregroundColor(.white)
                        .lineLimit(2)

                    let subtitle = eventText(english: event.subtitleEN, arabic: event.subtitleAR)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(bodyFont(size: 13))
                            .foregroundColor(.white.opacity(0.82))
                            .lineLimit(3)
                    }

                    HStack(spacing: 8) {
                        Text(eventText(english: event.ctaEN, arabic: event.ctaAR, fallback: AppLocalization.text("explore", fallback: "Explore")))
                            .font(labelFont(size: 10, weight: .bold))
                            .textCase(.uppercase)
                        Image(systemName: appLanguage.layoutDirection == .rightToLeft ? "arrow.left" : "arrow.right")
                            .font(.system(size: 10, weight: .bold))

                        if let endAt = event.endAt.flatMap(eventDate) {
                            Spacer(minLength: 6)
                            Text(endAt, style: .timer)
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        }
                    }
                    .foregroundColor(accent)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: isCompact ? 326 : 500, height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(accent.opacity(0.38), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(eventText(english: event.titleEN, arabic: event.titleAR, fallback: event.name))
    }

    func eventColor(_ value: String, fallback: UInt32) -> Color {
        let normalized = value.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        return Color(hex: UInt32(normalized, radix: 16) ?? fallback)
    }

    @ViewBuilder
    var homeQuickDrinks: some View {
        if isLoadingProducts && products.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                quickDrinksHeader
                productSkeletonGrid(count: isCompact ? 2 : 4)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
        } else if !quickDrinkProducts.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                quickDrinksHeader

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(Array(quickDrinkProducts.prefix(6))) { product in
                            quickDrinkCard(product)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
        }
    }

    var quickDrinksHeader: some View {
        HStack(alignment: .lastTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Label(
                    homeNearYouTitle,
                    systemImage: "bolt.fill"
                )
                .font(labelFont(size: 9, weight: .bold))
                .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.8)
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

                Text((preferredAddress?.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
                    ? AppLocalization.text("quick_drinks_title", fallback: "Drinks, one tap away")
                    : homeNearYouDetail)
                    .font(titleFont(size: isCompact ? 21 : 23))
                    .foregroundColor(primaryTextColor)
            }

            Spacer(minLength: 8)

            Button {
                openDrinksSection()
            } label: {
                Text(AppLocalization.text("see_all", fallback: "See All"))
                    .font(labelFont(size: 9, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)
            }
            .buttonStyle(.plain)
        }
    }

    func quickDrinkCard(_ product: Product) -> some View {
        let cardWidth: CGFloat = dynamicTypeSize.isAccessibilitySize ? 280 : (isCompact ? 154 : 170)

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                recordRecentlyViewed(product)
                selectedProduct = product
            } label: {
                ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 14)
                    .frame(width: cardWidth - 20, height: isCompact ? 106 : 118)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(format: AppLocalization.text("view_product_format", fallback: "View %@"), customerFacingProductName(for: product)))

            Text(customerFacingProductName(for: product))
                .font(titleFont(size: isCompact ? 15 : 16))
                .foregroundColor(primaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .frame(minHeight: 38, alignment: .topLeading)

            Text(product.price)
                .font(labelFont(size: 10, weight: .bold))
                .foregroundColor(readableBrandGoldColor)
                .lineLimit(1)

            Button {
                quickBuyDrink(product)
            } label: {
                Label(
                    product.hasVariantChoices
                        ? AppLocalization.text("choose", fallback: "Choose")
                        : AppLocalization.text("buy_now", fallback: "Buy Now"),
                    systemImage: product.hasVariantChoices ? "slider.horizontal.3" : "bolt.fill"
                )
                .font(labelFont(size: 9, weight: .bold))
                .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0x0A0804))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(TallaTheme.Colors.accent)
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .frame(width: cardWidth, alignment: .topLeading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.09), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func quickBuyDrink(_ product: Product) {
        if product.hasVariantChoices {
            recordRecentlyViewed(product)
            selectedProduct = product
            return
        }

        addToCart(product: product)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            cartOpen = true
        }
    }

    var homeSurprisePick: some View {
        VStack(alignment: .leading, spacing: 12) {
            surprisePickHeader

            if isSurprisePickExpanded {
                surprisePickExpandedContent
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(isSurprisePickExpanded ? 14 : 10)
        .background(
            LinearGradient(
                colors: isLightAppearance
                    ? [Color(hex: 0xFFF8EF), Color(hex: 0xF0DEC5)]
                    : (isOLEDAppearance
                        ? [.black, .black]
                        : [Color(hex: 0x21170F), Color(hex: 0x120D08)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.2 : 0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: isSurprisePickExpanded)
    }

    var surprisePickHeader: some View {
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
                    .padding(isSurprisePickExpanded ? 10 : 8)
                    .frame(width: isSurprisePickExpanded ? 40 : 32, height: isSurprisePickExpanded ? 40 : 32)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppLocalization.text("daily_surprise_title", fallback: "Today's Hot Pick"))
                        .font(labelFont(size: isSurprisePickExpanded ? 10 : 9, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 2)
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

                    if isSurprisePickExpanded {
                        Text(AppLocalization.text("daily_surprise_detail", fallback: "Not sure what to choose? Let Talla decide."))
                            .font(bodyFont(size: 12))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
                    }
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

    var surprisePickExpandedContent: some View {
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
                        .frame(minHeight: 44)
                        .background(TallaTheme.Colors.accent)
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

    var surpriseRevealCup: some View {
        Button {
            revealSurprisePick()
        } label: {
            ZStack {
                CoffeeBeansBurstView(accentColor: TallaTheme.Colors.accent, id: surpriseRevealID)
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
                        .background(TallaTheme.Colors.accent)
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

    func revealedSurprisePick(_ product: Product) -> some View {
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
                            .foregroundColor(readableBrandGoldColor)

                        Text(AppLocalization.text("limited_daily_reward", fallback: "Limited daily reward inside"))
                            .font(labelFont(size: 8, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(TallaTheme.Colors.accent.opacity(0.9))
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
                        .background(TallaTheme.Colors.accent)
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
            CoffeeBeansBurstView(accentColor: TallaTheme.Colors.accent, id: surpriseRevealID)
                .offset(x: 18, y: -34)
                .allowsHitTesting(false)
        }
    }

    func surprisePickInfoRow(title: String, detail: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(readableBrandGoldColor)
                .frame(width: 24, height: 24)
                .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.12 : 0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(labelFont(size: 9, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)

                Text(detail)
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    func refreshSurprisePick() {
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

    func revealSurprisePick() {
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

    func surprisePickReason(for product: Product) -> String {
        let source = product.catalogClassificationText.lowercased()

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

    func surprisePickBrewMethod(for product: Product) -> String {
        let source = product.catalogClassificationText.lowercased()

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
    var homeFavoritesShelf: some View {
        if !favoriteProducts.isEmpty || !reorderPrompts.isEmpty || !coffeeLotRecommendations.isEmpty {
            let shelfItemCount = favoriteProducts.count + reorderPrompts.count + coffeeLotRecommendations.count

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    Button {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                            isHomeShelfExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(AppLocalization.text("favorites_shelf", fallback: "Your Shelf"))
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(AppLocalization.letterSpacing(2.2))
                                    .textCase(.uppercase)
                                    .foregroundColor(readableBrandGoldColor)

                                Text(String(format: AppLocalization.text("shelf_ready_count", fallback: "%d items ready"), shelfItemCount))
                                    .font(bodyFont(size: 12))
                                    .foregroundColor(secondaryTextColor)
                            }

                            Spacer(minLength: 8)

                            Image(systemName: isHomeShelfExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(primaryTextColor)
                                .frame(width: 30, height: 30)
                                .background(cardFillColor)
                                .clipShape(Circle())
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("favorites_shelf", fallback: "Your Shelf"))
                    .accessibilityValue(isHomeShelfExpanded ? "Expanded" : "Collapsed")

                    Button {
                        isFavoriteShelfPresented = true
                    } label: {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color(hex: 0x0A0804))
                            .frame(width: 38, height: 38)
                            .background(TallaTheme.Colors.accent)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("open_favorites_shelf", fallback: "Open favorites shelf"))
                }

                if isHomeShelfExpanded {
                    Group {
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

                        if !coffeeLotRecommendations.isEmpty {
                            personalizedShelfSection(
                                title: "From your coffee library",
                                detail: "Reorder the same lot when it is available, or use the closest current replacement.",
                                systemImage: "shippingbox.fill"
                            ) {
                                VStack(spacing: 10) {
                                    ForEach(coffeeLotRecommendations.prefix(3)) { recommendation in
                                        coffeeLotRecommendationCard(recommendation)
                                    }
                                }
                            }
                        }

                        if reorderPrompts.isEmpty && !favoriteProducts.isEmpty {
                            personalizedProductShelfSection(
                                title: AppLocalization.text("favorites_stand", fallback: "Favorites"),
                                detail: AppLocalization.text("favorites_shelf_stand_detail", fallback: "Products you saved for later."),
                                systemImage: "heart.fill",
                                products: Array(favoriteProducts.prefix(4)),
                                emptyMessage: ""
                            )
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
            .animation(.spring(response: 0.34, dampingFraction: 0.82), value: isHomeShelfExpanded)
        }
    }

    @ViewBuilder
    var homeRecentlyViewedShelf: some View {
        if !recentlyViewedUnboughtProducts.isEmpty {
            recentlyViewedShelfSection
                .padding(.horizontal, 18)
                .padding(.bottom, 14)
        }
    }

    @ViewBuilder
    var recentlyViewedShelfSection: some View {
        personalizedShelfSection(
            title: AppLocalization.text("recently_viewed", fallback: "Recently Viewed"),
            detail: AppLocalization.text("recently_viewed_home_detail", fallback: "Products you explored but did not buy."),
            systemImage: "eye.fill",
            trailingHeader: recentlyViewedSectionMenu
        ) {
            let products = Array(recentlyViewedUnboughtProducts.prefix(6))

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

    @ViewBuilder
    func personalizedProductShelfSection(title: String, detail: String, systemImage: String, products: [Product], emptyMessage: String) -> some View {
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

    var recentlyViewedSectionMenu: AnyView {
        AnyView(
            Menu {
                Button(role: .destructive) {
                    savedRecentlyViewedProductIDs = ""
                    if customerProfile != nil {
                        Task { _ = try? await AccountService.clearRecentlyViewed() }
                    }
                } label: {
                    Label(AppLocalization.text("clear_history", fallback: "Clear history"), systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
                    .frame(width: 30, height: 30)
                    .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.10 : 0.14))
                    .clipShape(Circle())
            }
            .menuStyle(.button)
            .disabled(recentlyViewedProductIDs.isEmpty)
        )
    }

    func personalizedShelfSection<Content: View>(title: String, detail: String, systemImage: String, trailingHeader: AnyView = AnyView(EmptyView()), @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
                    .frame(width: 28, height: 28)
                    .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.10 : 0.14))
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
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.12 : 0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var shelfGreetingText: String {
        if customerProfile != nil {
            return AppLocalization.text("shelf_summary_signed_in", fallback: "Your favourites, previous orders, and recent discoveries.")
        }

        return AppLocalization.text("shelf_signed_out_prompt", fallback: "Sign in to save favourites and quickly reorder.")
    }

    func customerFirstName(for profile: ShopifyCustomerProfile) -> String {
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

    var signedOutShelfPrompt: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(readableBrandGoldColor)
                .frame(width: 34, height: 34)
                .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.10 : 0.14))
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
                    .tracking(AppLocalization.letterSpacing(1.2))
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(elevatedSurfaceColor.opacity(isLightAppearance ? 0.72 : 0.54))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func shelfProductCard(_ product: Product, width: CGFloat = 140) -> some View {
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
                    .foregroundColor(readableBrandGoldColor)
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

    func reorderPromptCard(_ prompt: ReorderPrompt) -> some View {
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
                    .tracking(AppLocalization.letterSpacing(1.4))
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .tallaGlassCapsule(tint: TallaTheme.Colors.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func coffeeLotRecommendationCard(_ recommendation: CoffeeLotRecommendation) -> some View {
        HStack(spacing: 14) {
            ProductThumbnail(imageURL: recommendation.product.imageURL, size: 72, cornerRadius: 16)
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.exact ? "Reorder \(recommendation.lot.name)" : "Closest replacement for \(recommendation.lot.name)")
                    .font(titleFont(size: 16)).foregroundColor(primaryTextColor)
                Text("\(customerFacingProductName(for: recommendation.product)) · \(recommendation.reason)")
                    .font(bodyFont(size: 12)).foregroundColor(secondaryTextColor)
            }
            Spacer()
            Button {
                if recommendation.product.hasVariantChoices {
                    recordRecentlyViewed(recommendation.product)
                    selectedProduct = recommendation.product
                } else {
                    addToCart(product: recommendation.product)
                }
            } label: {
                Image(systemName: recommendation.product.hasVariantChoices ? "slider.horizontal.3" : "cart.badge.plus")
                    .frame(width: 38, height: 38).background(TallaTheme.Colors.accent).clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14).background(cardFillColor).clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func orderRecommendationCard(source: Product, recommended: Product) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(readableBrandGoldColor)
                .frame(width: 34, height: 34)
                .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.10 : 0.14))
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
                    .background(TallaTheme.Colors.accent)
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
                .stroke(TallaTheme.Colors.accent.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var favoriteShelfSheet: some View {
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
                                .tracking(AppLocalization.letterSpacing(1.4))
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

    var favoriteShelfStand: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 38, height: 38)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppLocalization.text("favorites_stand", fallback: "Favorites stand"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(AppLocalization.letterSpacing(2.2))
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

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
                        .fill(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.34 : 0.24))
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
                .stroke(TallaTheme.Colors.accent.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isLightAppearance ? 0.08 : 0.24), radius: 18, x: 0, y: 10)
    }

    func favoriteShelfProductRow(product: Product, index: Int) -> some View {
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
                        .tracking(AppLocalization.letterSpacing(2))
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

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

                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tertiaryTextColor)
            }
            .padding(12)
            .background(cardFillColor)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    var tallaPassportSection: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .center, spacing: 10) {
                passportLogoIcon

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(AppLocalization.text("talla_passport", fallback: "Talla Passport"))
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(2.2))
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)

                        Text("\(stampedCoffeePassportOriginKeys.count) / \(coffeePassportOrigins.count) \(AppLocalization.text("passport_origins", fallback: "origins"))")
                            .font(labelFont(size: 10, weight: .bold))
                            .foregroundColor(secondaryTextColor)
                    }

                    Text(isCoffeePassportComplete
                        ? AppLocalization.text("talla_passport_complete_short", fallback: "Passport complete. Your reward is ready.")
                        : AppLocalization.text("talla_passport_reward_hint_short", fallback: "Complete your passport to unlock a reward."))
                        .font(bodyFont(size: 11))
                        .foregroundColor(isCoffeePassportComplete ? Color(hex: 0x6F8B55) : secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }

                Spacer(minLength: 0)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.12 : 0.10))

                    Capsule(style: .continuous)
                        .fill(LinearGradient(colors: [TallaTheme.Colors.accent, Color(hex: 0x6F8B55)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(proxy.size.width * passportProgressFraction, stampedCoffeePassportOriginKeys.isEmpty ? 0 : 12))
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: stampedCoffeePassportOriginKeys.count)
                }
            }
            .frame(height: 7)

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
                .tracking(AppLocalization.letterSpacing(1.2))
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)
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
        .padding(12)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(.horizontal, 18)
        .padding(.bottom, 14)
    }

    var passportLogoIcon: some View {
        ZStack {
            Circle()
                .fill(TallaTheme.Colors.accent)

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

    func passportStampButton(for origin: CoffeePassportOrigin) -> some View {
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
            .background(isStamped ? TallaTheme.Colors.accent : elevatedSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(TallaTheme.Colors.accent.opacity(isStamped ? 0 : 0.18), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if isStamped {
                    Text(AppLocalization.text("passport_stamp_mark", fallback: "STAMPED"))
                        .font(labelFont(size: 7, weight: .black))
                        .tracking(AppLocalization.letterSpacing(0.8))
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

    var homeQuickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("start_here", fallback: "Start here"))
                .font(labelFont(size: 10, weight: .bold))
                .tracking(AppLocalization.letterSpacing(2.2))
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

            LazyVGrid(columns: homeQuickActionColumns, spacing: 10) {
                ActionTileView(
                    title: AppLocalization.text("shop_bestsellers", fallback: "Shop Bestsellers"),
                    detail: AppLocalization.text("shop_bestsellers_detail", fallback: "Go straight to coffees, tools, and gifts."),
                    systemImage: "bag.fill",
                    titleFont: labelFont(size: 10, weight: .bold),
                    detailFont: bodyFont(size: 12),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    accentColor: TallaTheme.Colors.accent,
                    backgroundColor: cardFillColor,
                    strokeColor: TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08),
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
                    accentColor: TallaTheme.Colors.accent,
                    backgroundColor: cardFillColor,
                    strokeColor: TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08),
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
                    accentColor: TallaTheme.Colors.accent,
                    backgroundColor: cardFillColor,
                    strokeColor: TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08),
                    minHeight: 106
                ) {
                    isLibrarySectionExpanded = true
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
                    accentColor: TallaTheme.Colors.accent,
                    backgroundColor: cardFillColor,
                    strokeColor: TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08),
                    minHeight: 106
                ) {
                    openBrewing()
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
    }

    var homeLoyaltyTeaser: some View {
        Group {
            if let loyaltyAccount, !savedLoyaltyEmail.isEmpty {
                let rewardProgressState = rewardProgress(for: loyaltyAccount.pointsBalance)

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(AppLocalization.text("the_talla_club", fallback: "The Talla Club"))
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(AppLocalization.letterSpacing(2.2))
                                .textCase(.uppercase)
                                .foregroundColor(readableBrandGoldColor)

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
                                .tracking(AppLocalization.letterSpacing(1.8))
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: 0x0A0804))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(TallaTheme.Colors.accent)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(AppLocalization.text("reward_progress_home", fallback: "Reward Progress"))
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(AppLocalization.letterSpacing(1.8))
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
                                    .fill(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.12 : 0.10))

                                Capsule(style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [TallaTheme.Colors.accent, Color(hex: 0x8A5E30)],
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
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
            }
        }
    }

    var heroSection: some View {
        heroIntroduction
        .padding(isCompact ? 16 : 20)
        .background(
            LinearGradient(
                colors: isLightAppearance
                    ? [Color(hex: 0xFFF7ED), Color(hex: 0xEAD9C3)]
                    : (isOLEDAppearance ? [.black, .black] : [Color(hex: 0x22170F), elevatedSurfaceColor]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 14)
        .accessibilityIdentifier("home.hero")
    }

    var heroIntroduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            (dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 12))) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(homeSettingText(remoteHomeSettings?.heroEyebrow, arabicValue: remoteHomeSettings?.heroEyebrowAR, localizationKey: "roastery", fallback: "Welcome"))
                        .font(labelFont(size: 10, weight: .bold))
                        .tracking(AppLocalization.letterSpacing(3))
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

                }

                Spacer(minLength: 12)

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                    Text(homeSettingText(remoteHomeSettings?.heroBadge, arabicValue: remoteHomeSettings?.heroBadgeAR, localizationKey: "fresh_roast", fallback: "Fresh Roast"))
                        .font(labelFont(size: 9, weight: .bold))
                        .tracking(AppLocalization.letterSpacing(1.5))
                        .textCase(.uppercase)
                }
                .foregroundColor(readableBrandGoldColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color(hex: 0xF3DFC2).opacity(isLightAppearance ? 0.95 : 0.12))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.22 : 0.08), lineWidth: 1)
                )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(homeSettingText(remoteHomeSettings?.heroTitle, arabicValue: remoteHomeSettings?.heroTitleAR, localizationKey: "hero_title", fallback: "Better coffee starts here"))
                    .font(displayFont(size: isCompact ? 26 : 32))
                    .lineSpacing(1)
                    .foregroundColor(primaryTextColor)

                    Text(homeSettingText(remoteHomeSettings?.heroSubtitle, arabicValue: remoteHomeSettings?.heroSubtitleAR, localizationKey: "hero_subtitle", fallback: "Freshly roasted specialty coffee, brewing essentials, and guided recipes—all in one place."))
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            (dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 10))
                : AnyLayout(HStackLayout(spacing: 10))) {
                heroActions
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    var heroActions: some View {
        Button {
            openShop()
        } label: {
            Text(homeSettingText(remoteHomeSettings?.primaryButtonTitle, arabicValue: remoteHomeSettings?.primaryButtonTitleAR, localizationKey: "explore_coffees", fallback: "SHOP").uppercased())
                .font(labelFont(size: 11, weight: .bold))
                .tracking(AppLocalization.letterSpacing(2))
                .foregroundColor(Color(hex: 0x0A0804))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
                .background(TallaTheme.Colors.accent)
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.explore")

        Button {
            openBrewing()
        } label: {
            Text(homeSettingText(remoteHomeSettings?.secondaryButtonTitle, arabicValue: remoteHomeSettings?.secondaryButtonTitleAR, localizationKey: "brewing_guide", fallback: "GUIDED BREW").uppercased())
                .font(labelFont(size: 11, weight: .bold))
                .tracking(AppLocalization.letterSpacing(2))
                .foregroundColor(primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.18 : 0.08), lineWidth: 1)
                )
                .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.brew")
    }

    var featureStrip: some View {
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

    var loyaltySection: some View {
        LoyaltySectionView(
            isCompact: isCompact,
            isLightAppearance: isLightAppearance,
            isOLEDAppearance: isOLEDAppearance,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            elevatedSurfaceColor: elevatedSurfaceColor,
            accentColor: TallaTheme.Colors.accent,
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
            ,phaseSixSection: AnyView(phaseSixLoyaltySection)
        )
    }

    var phaseSixLoyaltySection: some View {
        let completed = Set(phaseSixCompletedPayload.split(separator: ",").map(String.init))
        let activities: [(String, String, String, Int)] = [
            ("birthday", "Birthday reward", "A complimentary birthday drink is waiting in your birthday month.", 50),
            ("mission", "Monthly brewing mission", "Brew three different methods and log the cups this month.", 40),
            ("achievement", "Method achievement", "Unlock badges for V60, espresso, immersion, and traditional brewing.", 30),
            ("review", "Useful review", "Share a helpful tasting note or complete a coffee lesson.", 25)
        ]
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("More ways to earn", systemImage: "sparkles")
                    .font(labelFont(size: 11, weight: .bold))
                    .foregroundStyle(TallaTheme.Colors.accent)
                Spacer()
                Text("Phase 6").font(.caption.weight(.bold)).foregroundStyle(secondaryTextColor)
            }
            Text("Birthday rewards, monthly missions, method achievements, and useful reviews turn your coffee habits into Beans.")
                .font(bodyFont(size: 15)).foregroundStyle(secondaryTextColor)
            ForEach(activities, id: \.0) { id, title, detail, points in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: completed.contains(id) ? "checkmark.seal.fill" : "circle.dotted")
                        .foregroundStyle(completed.contains(id) ? TallaTheme.Colors.accent : secondaryTextColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(primaryTextColor)
                        Text(detail).font(.caption).foregroundStyle(secondaryTextColor)
                    }
                    Spacer()
                    if !completed.contains(id) {
                        Button("+\(points)") {
                            let next = completed.union([id]).sorted().joined(separator: ",")
                            phaseSixCompletedPayload = next
                            Task { await earnPhaseSixPoints(activityID: id, points: points, note: title) }
                        }
                        .font(.caption.weight(.bold))
                        .buttonStyle(.borderedProminent)
                        .tint(TallaTheme.Colors.accent)
                    }
                }
            }
            if !phaseSixPersonalizedOfferTitles.isEmpty {
                Divider()
                Label("Picked for your taste", systemImage: "wand.and.stars").font(.subheadline.weight(.bold)).foregroundStyle(primaryTextColor)
                ForEach(phaseSixPersonalizedOfferTitles, id: \.self) { Text($0).font(.caption).foregroundStyle(secondaryTextColor) }
            }
            if !phaseSixLimitedLotTitles.isEmpty {
                Divider()
                Label("Early access", systemImage: "ticket.fill").font(.subheadline.weight(.bold)).foregroundStyle(primaryTextColor)
                ForEach(phaseSixLimitedLotTitles, id: \.self) { Text($0).font(.caption).foregroundStyle(secondaryTextColor) }
            }
        }
        .padding(16)
        .background(cardFillColor)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func earnPhaseSixPoints(activityID: String, points: Int, note: String) async {
        guard !savedLoyaltyEmail.isEmpty else { return }
        let idempotencyKey = activityID == "birthday"
            ? "phase6:birthday:\(Calendar.current.component(.year, from: .now))"
            : "phase6:\(activityID)"
        if let updated = try? await LoyaltyService.earnPoints(email: savedLoyaltyEmail, points: points, note: note, idempotencyKey: idempotencyKey) {
            await MainActor.run { loyaltyAccount = updated }
        }
    }

    var phaseSixPersonalizedOfferTitles: [String] {
        let taste = tasteMemoryRecords.first.map { ([$0.reaction] + $0.tags).joined(separator: " ").lowercased() } ?? ""
        if taste.contains("bright") || taste.contains("acid") {
            return ["10% off a bright washed lot", "Try the V60 mission for bonus Beans"]
        }
        if orderHistory.contains(where: { $0.items?.contains(where: { $0.name.localizedCaseInsensitiveContains("espresso") }) == true }) {
            return ["Early access to the next espresso lot", "A milk-base recipe matched to your recent order"]
        }
        return ["A curated starter offer based on your coffee history", "Complete a brewing lesson for bonus Beans"]
    }

    var phaseSixLimitedLotTitles: [String] {
        activeSeasonalEvents.filter { $0.enabled }.map { "\($0.name) · \($0.subtitleEN)" }
    }

    /// Coffee Club is explicitly curated in Admin > Live Controls > Coffee Club.
    /// Until products are selected there, keep the legacy coffee-bean fallback but
    /// never expose drip bags as subscription choices.
    var coffeeClubEligibleProducts: [ContentView.Product] {
        let configuredIDs = Set(remoteAppSettings?.coffeeClub?.productIDs ?? [])
        if !configuredIDs.isEmpty {
            return products.filter { configuredIDs.contains($0.id) && $0.isAvailableForSale }
        }

        return products.filter { product in
            let category = product.categoryKey.lowercased()
            let normalizedName = product.name.lowercased().replacingOccurrences(of: "&", with: "and")
            let excludedAccessoryNames = [
                "coffee brew water", "coffee scale", "coffee server", "coffee spoon",
                "rdt", "bean doser", "v60 dripper", "v60 filters"
            ]
            let isAccessory = excludedAccessoryNames.contains { normalizedName.contains($0) }
            let isDripBag = category == "drip-bags"
                || normalizedName.contains("drip bag")
                || normalizedName.contains("drip-bags")
            let isHawarIslandsCoffee = normalizedName.contains("hawar islands")
            return (["coffee-beans", "arabic-coffee-beans"].contains(category) || isHawarIslandsCoffee)
                && !isAccessory
                && !isDripBag
                && product.isAvailableForSale
        }
    }

    var clubView: some View {
        ClubSectionView(
            rewardsContent: AnyView(loyaltySection),
            coffeeSchoolContent: AnyView(CoffeeEducationView()),
            appIconContent: AnyView(appIconPickerCard),
            beansBalance: loyaltyAccount?.pointsBalance ?? 0,
            membershipTier: loyaltyAccount?.tier ?? AppLocalization.text("bronze", fallback: "Bronze"),
            isCustomerSignedIn: customerProfile != nil,
            coffeeClubEnabled: remoteAppSettings?.coffeeClub?.enabled ?? true,
            coffeeClubShipmentCount: configuredCoffeeClubShipmentCount,
            coffeeClubIntervalWeeks: configuredCoffeeClubIntervalWeeks,
            coffeeClubDiscountPercent: configuredCoffeeClubDiscountPercent,
            coffeeClubProducts: coffeeClubEligibleProducts,
            memberName: customerProfile?.displayName ?? AppLocalization.text("coffee_friend", fallback: "coffee friend"),
            coffeeClubOrders: orderHistory.filter { $0.details?.coffeeClub != nil },
            seasonalEvents: activeSeasonalEvents,
            savedRecipeCount: brewRecipes.count,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: TallaTheme.Colors.accent,
            pageBackgroundColor: pageBackgroundColor,
            isLightAppearance: isLightAppearance,
            openCoffeeClubAction: {
                activeCategory = "coffee-beans"
                shopSearchQuery = ""
                openTab(.shop)
            },
            addCoffeeToClubAction: { product, variant, quantity, fulfillment in
                addCoffeeClubToCart(product: product, variant: variant, quantity: quantity, fulfillment: fulfillment)
            }
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
    }

    var cartRewardsSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                loyaltySection
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
            }
            .background(pageBackgroundColor.ignoresSafeArea())
            .navigationTitle(AppLocalization.text("the_talla_club", fallback: "The Talla Club"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCartRewardsPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 32, height: 32)
                            .background(cardFillColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))
                }
            }
        }
    }

    var customerAccountSection: some View {
        CustomerAccountSectionView(
            isCompact: isCompact,
            isLightAppearance: isLightAppearance,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            cardFillColor: cardFillColor,
            elevatedSurfaceColor: elevatedSurfaceColor,
            accentColor: TallaTheme.Colors.accent,
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

    var primaryAccountActionTitle: String {
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

    func signedInCustomerCard(_ profile: ShopifyCustomerProfile) -> some View {
        SignedInCustomerSectionView(
            profile: profile,
            addressesCount: addresses.count,
            orderCount: orderHistory.count,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: TallaTheme.Colors.accent,
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

    var profileManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProfileManagementSectionView(
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                accentColor: TallaTheme.Colors.accent,
                cardFillColor: cardFillColor,
                isLightAppearance: isLightAppearance,
                firstName: $profileFirstName,
                lastName: $profileLastName,
                birthdayMonth: $birthdayMonth,
                birthdayDay: $birthdayDay,
                isSaving: isSavingProfile,
                saveAction: {
                    await saveProfile()
                }
            )

            accountTasteProfileCard
        }
    }

    var accountTasteProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(readableBrandGoldColor)
                Text(AppLocalization.text("your_taste_profile", fallback: "Taste profile"))
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(AppLocalization.letterSpacing(1.8))
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)
                Spacer()
                Button(AppLocalization.text(tasteProfileConfigured ? "edit" : "taste_setup_action", fallback: tasteProfileConfigured ? "Edit" : "Set your taste")) {
                    openTasteProfileEditor()
                }
                .font(labelFont(size: 10, weight: .bold))
                .foregroundColor(readableBrandGoldColor)
                .buttonStyle(.plain)
            }

            Text(AppLocalization.text(tasteProfileConfigured ? "taste_profile_account_detail" : "taste_profile_setup_detail", fallback: tasteProfileConfigured ? "Talla uses these preferences to shape your home screen, recommendations, and brew suggestions." : "Set your preferences so Talla can learn the cup you like."))
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            if tasteProfileConfigured {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], spacing: 8) {
                    ForEach(tasteProfileLabels, id: \.self) { label in
                        Text(label)
                            .font(labelFont(size: 9, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(elevatedSurfaceColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(cardFillColor)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(TallaTheme.Colors.accent.opacity(0.14), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var passwordResetSection: some View {
        PasswordResetSectionView(
            primaryTextColor: primaryTextColor,
            accentColor: TallaTheme.Colors.accent,
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

    var orderHistorySection: some View {
        OrderHistorySectionView(
            orders: orderHistory,
            isLoadingOrders: isLoadingOrders,
            ordersError: ordersError,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            accentColor: TallaTheme.Colors.accent,
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            tasteMemoryLookup: tasteMemoryLookup,
            coffeeClubProducts: coffeeClubEligibleProducts,
            deliveryAddresses: addresses,
            buyAgainAction: { order in
                buyAgain(order: order)
            },
            saveTasteMemoryAction: { order, item, reaction, tags in
                saveTasteMemory(order: order, item: item, reaction: reaction, tags: tags)
            },
            pickupDirectionsAction: {
                guard let pickupURL = URL(string: "https://maps.app.goo.gl/PaaVd6sz66JGk4KS9?g_st=ic") else { return }
                openURL(pickupURL)
            },
            browseProductsAction: {
                openShop()
            },
            orderSupportAction: { order in
                var components = URLComponents(url: managedWhatsAppURL, resolvingAgainstBaseURL: false)
                var items = components?.queryItems ?? []
                items.append(URLQueryItem(name: "text", value: String(format: AppLocalization.text("order_support_message", fallback: "Hello Talla, I need help with order %@."), order.title)))
                components?.queryItems = items
                openURL(components?.url ?? managedWhatsAppURL)
            },
            customerOrderAction: { order, action in
                await submitCustomerOrderAction(order: order, action: action)
            },
            manageCoffeeClubAction: { order, action, note, coffeeName, variantID, coffeeItems, address, fulfillmentMethod in
                await manageCoffeeClub(
                    order: order,
                    action: action,
                    note: note,
                    coffeeName: coffeeName,
                    variantID: variantID,
                    address: address,
                    fulfillmentMethod: fulfillmentMethod,
                    coffeeItems: coffeeItems
                )
            }
        )
    }

    var featuredProducts: some View {
        let freshRoasts = homeFreshRoastProducts
        let showingFreshRoasts = !freshRoasts.isEmpty
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppLocalization.text(showingFreshRoasts ? "recently_roasted" : "roastery_selection", fallback: showingFreshRoasts ? "Just roasted" : "Roastery Selection"))
                        .font(labelFont(size: 10, weight: .semibold))
                        .tracking(AppLocalization.letterSpacing(3))
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

                    Text(AppLocalization.text(showingFreshRoasts ? "fresh_roast_week" : "signature_roasts", fallback: showingFreshRoasts ? "Freshly roasted this week" : "Signature Roasts"))
                        .font(displayFont(size: 24))
                        .tracking(AppLocalization.letterSpacing(0.5))
                        .foregroundColor(primaryTextColor)
                }

                Spacer(minLength: 12)

                Button {
                    openShop()
                } label: {
                    Label(AppLocalization.text("browse_shop", fallback: "Browse Shop"), systemImage: "arrow.forward")
                        .font(labelFont(size: 11, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)
                }
                .buttonStyle(.plain)
            }

            if isLoadingProducts && products.isEmpty {
                productSkeletonGrid(count: isCompact ? 2 : 4)
            } else if let loadingError, products.isEmpty {
                errorSection(message: loadingError)
            } else {
                let roasts = Array((showingFreshRoasts ? freshRoasts : signatureRoastProducts).prefix(4))

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
                        columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2),
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
        .padding(.bottom, 20)
    }

    var collections: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("")
                    .font(labelFont(size: 10, weight: .semibold))
                    .tracking(AppLocalization.letterSpacing(4))
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)

                Text(AppLocalization.text("from_the_roastery", fallback: "FROM THE ROASTERY"))
                    .font(displayFont(size: 28))
                    .tracking(AppLocalization.letterSpacing(1))
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

    var shopView: some View {
        ShopSectionView(
            activeCategoryTitle: activeCategory == "all" ? AppLocalization.text("full_catalog", fallback: "Full catalog") : categoryLabel(for: activeCategory),
            availableCategories: availableCategories,
            filteredProducts: filteredProducts,
            allProductsAreEmpty: products.isEmpty,
            isLoadingProducts: isLoadingProducts,
            loadingError: loadingError,
            showsCoffeeClubIntroduction: remoteAppSettings?.coffeeClub?.enabled ?? false,
            coffeeClubShipmentCount: configuredCoffeeClubShipmentCount,
            coffeeClubIntervalWeeks: configuredCoffeeClubIntervalWeeks,
            coffeeClubDiscountPercent: configuredCoffeeClubDiscountPercent,
            curatedBundleProducts: curatedBundleProducts,
            activeCategory: $activeCategory,
            searchQuery: $shopSearchQuery,
            sortMode: $shopSortMode,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: TallaTheme.Colors.accent,
            isLightAppearance: isLightAppearance,
            titleFont: displayFont(size: 28),
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
        .padding(.top, 18)
        .padding(.bottom, 22)
    }

    var recentSearchQueries: [String] {
        savedRecentSearchQueries
            .split(separator: "|")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var quickSearches: [(title: String, query: String, categoryKey: String)] {
        [
            (AppLocalization.text("beans", fallback: "Beans"), "beans", "coffee-beans"),
            (AppLocalization.text("summer_boxes", fallback: "Summer Boxes"), "box", "summer-drinks"),
            (AppLocalization.text("gifts", fallback: "Gifts"), "gift", "gifts"),
            (AppLocalization.text("crmb", fallback: "CRMB"), "crmb", "desserts"),
            (AppLocalization.text("equipment", fallback: "Equipment"), "brew", "coffee-equipment"),
            (AppLocalization.text("decaf", fallback: "Decaf"), "decaf", "all"),
            (AppLocalization.text("available", fallback: "In stock"), "available", "all"),
            (AppLocalization.text("budget", fallback: "Budget picks"), "budget", "all"),
            (AppLocalization.text("fruity", fallback: "Fruity"), "fruity", "all"),
            (AppLocalization.text("espresso", fallback: "Espresso"), "espresso", "all"),
            (AppLocalization.text("hosting", fallback: "Hosting"), "hosting", "gifts")
        ]
    }

    func recordRecentSearch(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        var queries = recentSearchQueries.filter { $0.localizedCaseInsensitiveCompare(trimmedQuery) != .orderedSame }
        queries.insert(trimmedQuery, at: 0)
        savedRecentSearchQueries = queries.prefix(6).joined(separator: "|")
    }

    var shopGuidancePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            coffeeQuizPanel
        }
    }

    var coffeeQuizPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 34, height: 34)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Circle())

                Text(AppLocalization.text("coffee_quiz_title", fallback: "Find Your Talla"))
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.6)
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)

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
                    .background(TallaTheme.Colors.accent)
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

                quizOptionRow(title: AppLocalization.text("taste_acidity_title", fallback: "Acidity"), options: [("low", AppLocalization.text("taste_acidity_low", fallback: "Low")), ("balanced", AppLocalization.text("taste_acidity_balanced", fallback: "Balanced")), ("high", AppLocalization.text("taste_acidity_high", fallback: "Bright"))], selection: $tasteProfileAcidity)
                quizOptionRow(title: AppLocalization.text("taste_sweetness_title", fallback: "Sweetness"), options: [("subtle", AppLocalization.text("taste_sweetness_subtle", fallback: "Subtle")), ("sweet", AppLocalization.text("taste_sweetness_sweet", fallback: "Sweet"))], selection: $tasteProfileSweetness)
                quizOptionRow(title: AppLocalization.text("taste_body_title", fallback: "Body"), options: [("light", AppLocalization.text("taste_body_light", fallback: "Light")), ("balanced", AppLocalization.text("taste_body_balanced", fallback: "Balanced")), ("full", AppLocalization.text("taste_body_full", fallback: "Full"))], selection: $tasteProfileBody)
                quizOptionRow(title: AppLocalization.text("taste_roast_title", fallback: "Roast preference"), options: [("light", AppLocalization.text("taste_roast_light", fallback: "Light")), ("medium", AppLocalization.text("taste_roast_medium", fallback: "Medium")), ("dark", AppLocalization.text("taste_roast_dark", fallback: "Dark"))], selection: $tasteProfileRoast)
                quizOptionRow(title: AppLocalization.text("taste_temperature_title", fallback: "Temperature"), options: [("hot", AppLocalization.text("taste_temperature_hot", fallback: "Hot")), ("iced", AppLocalization.text("taste_temperature_iced", fallback: "Iced"))], selection: $tasteProfileTemperature)
                quizOptionRow(title: AppLocalization.text("taste_style_title", fallback: "Coffee style"), options: [("modern", AppLocalization.text("taste_style_modern", fallback: "Modern specialty")), ("arabic", AppLocalization.text("taste_style_arabic", fallback: "Arabic coffee"))], selection: $tasteProfileStyle)

                Text(AppLocalization.text("taste_profile_usage_detail", fallback: "Talla uses this profile to shape your home screen and recommendations. You can change it anytime."))
                    .font(bodyFont(size: 11))
                    .foregroundColor(tertiaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    tasteProfileConfigured = true
                    isCoffeeQuizExpanded = false
                    showToast(message: AppLocalization.text("taste_profile_saved", fallback: "Taste profile saved"))
                } label: {
                    Text(AppLocalization.text("save_taste_profile", fallback: "Save taste profile"))
                        .font(labelFont(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(TallaTheme.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

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
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    func quizOptionRow(
        title: String,
        options: [(id: String, title: String)],
        selection: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(labelFont(size: 9, weight: .bold))
                .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

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
                            .background(selection.wrappedValue == option.id ? TallaTheme.Colors.accent : cardFillColor)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(TallaTheme.Colors.accent.opacity(selection.wrappedValue == option.id ? 0 : 0.18), lineWidth: 1)
                            )
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func quizResultCard(_ product: Product) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 12)
                .frame(width: 82, height: 98)

            VStack(alignment: .leading, spacing: 9) {
                Text(AppLocalization.text("coffee_quiz_match_label", fallback: "Your Talla Match"))
                    .font(labelFont(size: 9, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.3)
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)

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
                        TallaTelemetry.shared.track("recommendation_to_product_conversion", properties: ["source": "taste_quiz", "product": product.name])
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
                            .background(TallaTheme.Colors.accent)
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
                                    .stroke(TallaTheme.Colors.accent.opacity(0.18), lineWidth: 1)
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
                                    .stroke(TallaTheme.Colors.accent.opacity(0.18), lineWidth: 1)
                            )
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.09 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var quizMatchedProduct: Product? {
        quizCandidateProducts.max { lhs, rhs in
            quizScore(for: lhs) < quizScore(for: rhs)
        }
    }

    var quizCandidateProducts: [Product] {
        let candidates = products.filter {
            $0.categoryKey == "coffee-beans" || $0.categoryKey == "arabic-coffee-beans"
        }

        return candidates.isEmpty ? signatureRoastProducts : candidates
    }

    func quizScore(for product: Product) -> Int {
        let text = product.catalogClassificationText.lowercased()
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

        if tasteProfileConfigured {
        switch savedTasteProfile.acidity {
        case "low": score += quizTextScore(text, keywords: ["smooth", "low acid", "chocolate", "nutty", "brazil"])
        case "high": score += quizTextScore(text, keywords: ["bright", "acid", "citrus", "floral", "fruit", "ethiopia"])
        default: score += quizTextScore(text, keywords: ["balanced", "clean", "sweet"])
        }

        switch savedTasteProfile.sweetness {
        case "sweet": score += quizTextScore(text, keywords: ["sweet", "caramel", "honey", "chocolate", "brown sugar"])
        default: score += quizTextScore(text, keywords: ["clean", "tea", "floral"])
        }

        switch savedTasteProfile.body {
        case "light": score += quizTextScore(text, keywords: ["tea", "clean", "floral", "washed"])
        case "full": score += quizTextScore(text, keywords: ["body", "rich", "espresso", "chocolate", "nutty"])
        default: score += quizTextScore(text, keywords: ["balanced", "smooth"])
        }

        switch savedTasteProfile.roast {
        case "light": score += quizTextScore(text, keywords: ["light", "washed", "floral", "fruit"])
        case "dark": score += quizTextScore(text, keywords: ["dark", "bold", "roast", "espresso"])
        default: score += quizTextScore(text, keywords: ["medium", "balanced", "sweet"])
        }

        if savedTasteProfile.temperature == "iced" {
            score += quizTextScore(text, keywords: ["iced", "cold", "summer", "refreshing"])
        }

        if savedTasteProfile.style == "arabic" {
            score += quizTextScore(text, keywords: ["arabic", "qahwa", "cardamom", "yemen", "shamali"])
        } else {
            score += quizTextScore(text, keywords: ["single-origin", "specialty", "washed", "natural"])
        }
        }

        if product.isAvailableForSale {
            score += 3
        }

        return score
    }

    func quizTextScore(_ text: String, keywords: [String]) -> Int {
        keywords.reduce(0) { partialResult, keyword in
            partialResult + (text.contains(keyword) ? 4 : 0)
        }
    }

    func quizResultDescription(for product: Product) -> String {
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

    var coffeeConciergeSheet: some View {
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

    var coffeeConciergePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 30, height: 30)
                    .background(TallaTheme.Colors.accent)
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
                            .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    Task { await runCoffeeConcierge() }
                } label: {
                    Image(systemName: isRunningConcierge ? "hourglass" : "arrow.forward")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(width: 38, height: 38)
                        .background(TallaTheme.Colors.accent)
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
                            .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                    )
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)

                if isLoadingConciergeImage {
                    ProgressView()
                        .tint(TallaTheme.Colors.accent)
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
                            .foregroundColor(readableBrandGoldColor)

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
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(elevatedSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

#if canImport(PhotosUI)
    @ViewBuilder
    var conciergeImagePreview: some View {
#if canImport(UIKit)
        if let conciergeImageData, let image = UIImage(data: conciergeImageData) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFill()
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.22 : 0.12), lineWidth: 1)
                )
                .accessibilityLabel(AppLocalization.text("selected_image", fallback: "Selected image"))
        }
#else
        Image(systemName: "photo.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(readableBrandGoldColor)
            .frame(width: 42, height: 42)
            .background(cardFillColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
#endif
    }
#endif

    func conciergePromptChip(_ title: String) -> some View {
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
                        .stroke(TallaTheme.Colors.accent.opacity(0.18), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRunningConcierge || products.isEmpty)
    }

#if canImport(PhotosUI)
    @MainActor
    func loadConciergeImage(from selection: PhotosPickerItem?) async {
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
    func runCoffeeConcierge(requestOverride: String? = nil) async {
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

}
