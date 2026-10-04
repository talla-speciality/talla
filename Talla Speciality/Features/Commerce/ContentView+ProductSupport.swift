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
    func productCard(product: Product, showDescription: Bool) -> some View {
        let tasteSummary = productTasteSummary(for: product)
        let cardMinimumHeight: CGFloat = showDescription ? (isCompact ? 340 : 360) : (isCompact ? 396 : 416)
        let shouldShowAlertButton = !product.isAvailableForSale || isAlertEnabled(product)

        return VStack(alignment: .leading, spacing: showDescription ? 8 : 10) {
            ZStack(alignment: .topTrailing) {
                ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 10)
                    .frame(height: showDescription ? (isCompact ? 138 : 152) : (isCompact ? 176 : 184))

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
                            .foregroundColor(isFavorite(product) ? TallaTheme.Colors.accent : primaryTextColor)
                            .symbolEffect(.bounce, value: isFavorite(product))
                            .frame(width: 34, height: 34)
                            .background(cardFillColor.opacity(0.92))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFavorite(product)
                        ? AppLocalization.text("remove_from_favorites", fallback: "Remove from favourites")
                        : AppLocalization.text("add_to_favorites", fallback: "Add to favourites"))

                    if shouldShowAlertButton {
                        Button {
                            Task {
                                await toggleAlert(product: product)
                            }
                        } label: {
                            Image(systemName: isAlertEnabled(product) ? "bell.fill" : "bell")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(isAlertEnabled(product) ? TallaTheme.Colors.accent : primaryTextColor)
                                .symbolEffect(.bounce, value: isAlertEnabled(product))
                                .frame(width: 34, height: 34)
                                .background(cardFillColor.opacity(0.92))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isAlertEnabled(product)
                            ? AppLocalization.text("remove_alert", fallback: "Remove alert")
                            : AppLocalization.text("notify_when_available", fallback: "Notify when available"))
                    }

                    if let tag = product.tag {
                        Text(tag)
                            .font(.system(size: 8, weight: .semibold))
                            .tracking(AppLocalization.letterSpacing(1.2))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                            .background(TallaTheme.Colors.accent)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .cornerRadius(2)
                            .frame(maxWidth: 86, alignment: .trailing)
                    }
                }
                .padding(10)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    Text(product.categoryLabel)
                        .font(labelFont(size: 10, weight: .semibold))
                        .tracking(AppLocalization.letterSpacing(1.4))
                        .textCase(.uppercase)
                        .foregroundColor(tertiaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Spacer(minLength: 2)

                    if let countryOfOrigin = productCountryOfOrigin(for: product) {
                        Label(countryOfOrigin, systemImage: "globe.europe.africa.fill")
                            .font(labelFont(size: 9, weight: .semibold))
                            .foregroundColor(readableBrandGoldColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .accessibilityLabel("\(AppLocalization.text("country_of_origin", fallback: "Country of origin")): \(countryOfOrigin)")
                    }
                }
                .frame(minHeight: 13, alignment: .leading)

                Text(product.name)
                    .font(titleFont(size: showDescription ? (isCompact ? 16 : 18) : (isCompact ? 18 : 20)))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .lineSpacing(1)
                    .minimumScaleFactor(0.78)
                    .frame(minHeight: showDescription ? 40 : 48, alignment: .topLeading)

                if showDescription {
                    Text(tasteSummary)
                        .font(bodyFont(size: isCompact ? 11 : 12))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity, minHeight: 16, alignment: .leading)
                }
            }

            Spacer(minLength: 0)

            if !showDescription {
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
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(displayedProductPrice(product.price))
                    .font(labelFont(size: isCompact ? 14 : 15, weight: .bold))
                    .foregroundColor(product.isAvailableForSale ? TallaTheme.Colors.accent : tertiaryTextColor)
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
                    .tallaGlassCapsule(tint: TallaTheme.Colors.accent, enabled: product.isAvailableForSale)
                }
                .buttonStyle(.plain)
                .disabled(!product.isAvailableForSale || selectedVariant(for: product) == nil)
            }
            .frame(maxWidth: .infinity, minHeight: showDescription ? 68 : 74, alignment: .bottom)
        }
        .padding(showDescription ? 10 : 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(cardFillColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, minHeight: cardMinimumHeight, alignment: .topLeading)
        .hoverEffect(.lift)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .onTapGesture {
            recordRecentlyViewed(product)
            selectedProduct = product
        }
    }

    func signatureRoastCard(_ product: Product) -> some View {
        let notes = productTasteNotes(for: product)
        let compactCardWidth: CGFloat = 176

        return VStack(alignment: .leading, spacing: 7) {
            ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 14)
                .frame(maxWidth: .infinity)
                .frame(height: isCompact ? 122 : 146)

            VStack(alignment: .leading, spacing: 4) {
                Text(productOriginLabel(for: product))
                    .font(labelFont(size: 8, weight: .bold))
                    .tracking(AppLocalization.letterSpacing(1))
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)
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
                            .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.12 : 0.16))
                            .clipShape(Capsule())
                    }
                }
                .frame(height: 22, alignment: .leading)
            }

            HStack(spacing: 8) {
                Text(displayedProductPrice(product.price))
                    .font(labelFont(size: 11, weight: .bold))
                    .foregroundColor(product.isAvailableForSale ? TallaTheme.Colors.accent : tertiaryTextColor)
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
                        .tracking(AppLocalization.letterSpacing(0.6))
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.68)
                        .foregroundColor(product.isAvailableForSale ? Color(hex: 0x0A0804) : tertiaryTextColor)
                        .frame(width: 82)
                        .padding(.vertical, 7)
                        .tallaGlassCapsule(tint: TallaTheme.Colors.accent, enabled: product.isAvailableForSale)
                }
                .buttonStyle(.plain)
                .disabled(!product.isAvailableForSale || selectedVariant(for: product) == nil)
            }
            .frame(height: 30, alignment: .center)
        }
        .padding(10)
        .frame(width: isCompact ? compactCardWidth : nil, height: isCompact ? 258 : 288, alignment: .topLeading)
        .frame(maxWidth: isCompact ? nil : .infinity, alignment: .topLeading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            recordRecentlyViewed(product)
            selectedProduct = product
        }
        .hoverEffect(.lift)
    }

    func signatureRoastActionTitle(for product: Product) -> String {
        if !product.isAvailableForSale {
            return AppLocalization.text("sold_out", fallback: "Sold Out")
        }

        return product.hasVariantChoices
            ? AppLocalization.text("options", fallback: "Options")
            : AppLocalization.text("add", fallback: "Add")
    }

    func productPreviewDescription(for product: Product) -> String {
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

    func customerFacingProductName(for product: Product) -> String {
        let cleanedName = customerFacingText(product.name)
        return cleanedName.isEmpty ? AppLocalization.text("this_product", fallback: "this product") : cleanedName
    }

    func customerFacingText(_ text: String) -> String {
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

    func recommendationCopy(source: Product, recommended: Product) -> String {
        let sourceName = customerFacingProductName(for: source)
        let recommendedName = customerFacingProductName(for: recommended)
        return String(format: AppLocalization.text("similar_order_recommendation_plain", fallback: "Loved %@? Try %@ for your next gathering."), sourceName, recommendedName)
    }

    func productOriginLabel(for product: Product) -> String {
        if let countryOfOrigin = productCountryOfOrigin(for: product) {
            return AppLocalization.catalogOption(countryOfOrigin)
        }

        return product.categoryLabel.isEmpty
            ? AppLocalization.text("signature_roast_origin_fallback", fallback: "Signature Roast")
            : product.categoryLabel
    }

    func productCountryOfOrigin(for product: Product) -> String? {
        // A gift box can contain coffees from several origins, but the box
        // itself does not have a single coffee origin.
        guard product.categoryKey != "gifts" else { return nil }

        if let countryOfOrigin = product.countryOfOrigin {
            return AppLocalization.catalogOption(countryOfOrigin)
        }

        return firstMatchedValue(in: normalizedSearchText(for: product), matches: [
            ("ethiopia", "Ethiopia"),
            ("colombia", "Colombia"),
            ("brazil", "Brazil"),
            ("yemen", "Yemen"),
            ("kenya", "Kenya"),
            ("guatemala", "Guatemala"),
            ("costa rica", "Costa Rica"),
            ("greece", "Greece"),
            ("qatar", "Qatar"),
            ("united arab emirates", "United Arab Emirates"),
            ("emirati", "United Arab Emirates"),
            ("kuwait", "Kuwait")
        ])
    }

    func productTasteNotes(for product: Product) -> [String] {
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

    func productTasteSummary(for product: Product) -> String {
        let searchableText = normalizedSearchText(for: product)
        let matchedNotes = orderedUniqueValues(tasteNoteMatches(in: searchableText))

        if !matchedNotes.isEmpty {
            return matchedNotes.prefix(3).joined(separator: " - ")
        }

        if product.categoryKey == "coffee-beans" || product.categoryKey == "drip-bags" {
            return AppLocalization.text("coffee_card_default_taste", fallback: "Balanced - Sweet - Clean")
        }

        switch product.categoryKey {
        case "ready-made-drinks":
            return AppLocalization.text("ready_drink_card_summary", fallback: "Ready to drink")
        case "summer-drinks":
            return AppLocalization.text("summer_box_card_summary", fallback: "Seasonal drink box")
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

    func tasteNoteMatches(in searchableText: String) -> [String] {
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
            searchableText.contains(pair.keyword) ? AppLocalization.catalogOption(pair.note) : nil
        }
    }

    func productBrewRecommendation(for product: Product) -> String {
        let searchableText = normalizedSearchText(for: product)

        if product.categoryKey == "gifts" {
            return AppLocalization.text("best_for_gifts", fallback: "A curated gift box for sharing and special moments.")
        }

        if product.categoryKey == "ready-made-drinks" {
            return AppLocalization.text("best_ready_to_drink", fallback: "Best served chilled and ready to drink.")
        }

        if product.categoryKey == "summer-drinks" {
            return AppLocalization.text("best_summer_box", fallback: "A chilled seasonal box made for sharing.")
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

    func productMetadataChips(for product: Product) -> [(icon: String, title: String)] {
        if product.categoryKey == "gifts" {
            return [
                ("gift.fill", AppLocalization.text("gift_box", fallback: "Gift box")),
                ("tag.fill", product.categoryLabel)
            ]
        }

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

    func productMetadataChip(icon: String, title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))

            Text(title)
                .font(labelFont(size: 9, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundColor(readableBrandGoldColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.10 : 0.14))
        .clipShape(Capsule())
    }

    func productBrewChipTitle(for product: Product) -> String {
        let searchableText = normalizedSearchText(for: product)

        if product.categoryKey == "ready-made-drinks" { return AppLocalization.catalogOption("Chilled") }
        if product.categoryKey == "summer-drinks" { return AppLocalization.catalogOption("Share") }
        if product.categoryKey == "cups" { return AppLocalization.catalogOption("Serve") }
        if product.categoryKey == "coffee-equipment" { return AppLocalization.catalogOption("Gear") }
        if searchableText.contains("espresso") { return AppLocalization.catalogOption("Espresso") }
        if searchableText.contains("arabic") { return AppLocalization.catalogOption("Arabic") }
        if searchableText.contains("drip") { return AppLocalization.catalogOption("Drip") }
        return "V60"
    }

    func normalizedSearchText(for product: Product) -> String {
        product.catalogClassificationText.lowercased()
    }

    func coffeePassportOriginKey(in text: String) -> String? {
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

    func firstMatchedValue(in text: String, matches: [(needle: String, value: String)]) -> String? {
        matches.first { text.contains($0.needle) }.map { AppLocalization.catalogOption($0.value) }
    }

    func orderedUniqueValues(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }

    func productBadges(for product: Product) -> [String] {
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

        if product.categoryKey == "gifts" || product.categoryKey == "summer-drinks" {
            badges.append(AppLocalization.text("gift_ready", fallback: "Gift ready"))
        }

        if product.categoryKey.contains("coffee") && product.isAvailableForSale {
            badges.append(AppLocalization.text("reward_eligible", fallback: "Reward eligible"))
        }

        if normalizedName.contains("cold") || normalizedName.contains("iced") {
            badges.append(AppLocalization.text("cold_pick", fallback: "Cold pick"))
        }

        return Array(badges.prefix(2))
    }

    func productBadge(_ title: String) -> some View {
        Text(title)
            .font(labelFont(size: 8, weight: .bold))
            .tracking(AppLocalization.letterSpacing(1.2))
            .textCase(.uppercase)
            .foregroundColor(Color(hex: 0x0A0804))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(TallaTheme.Colors.accent)
            .clipShape(Capsule(style: .continuous))
    }

    func productDetailSheet(product: Product) -> some View {
        let selectedVariant = selectedVariant(for: product)
        let canPurchase = selectedVariant?.isAvailableForSale ?? product.isAvailableForSale

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                productImageGallery(product)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(product.categoryLabel)
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(2))
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)

                        Text(product.name)
                            .font(titleFont(size: 28))
                            .foregroundColor(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button {
                        toggleFavorite(product: product)
                    } label: {
                        Image(systemName: isFavorite(product) ? "heart.fill" : "heart")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(isFavorite(product) ? TallaTheme.Colors.accent : primaryTextColor)
                            .frame(width: 40, height: 40)
                            .background(cardFillColor, in: Circle())
                            .overlay(Circle().stroke(TallaTheme.Colors.accent.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFavorite(product) ? "Remove from saved" : "Save coffee")

                    if let tag = product.tag {
                        Text(tag)
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(1.8))
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(TallaTheme.Colors.accent)
                            .clipShape(Capsule())
                    }
                }

                Text(displayedProductPrice(selectedVariant?.price ?? product.price))
                    .font(displayFont(size: 24))
                    .foregroundColor((selectedVariant?.isAvailableForSale ?? product.isAvailableForSale) ? TallaTheme.Colors.accent : tertiaryTextColor)

                productFactsSection(product)

                if isBrewableCoffee(product) && tasteProfileConfigured {
                    productTasteProfileFitSection(product)
                }

                if product.hasVariantChoices {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppLocalization.text("variants", fallback: "VARIANTS"))
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(2))
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)

                        ForEach(product.variants) { variant in
                            Button {
                                selectedVariantIDs[product.id] = variant.id
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(variant.title)
                                            .font(bodyFont(size: 14))
                                            .foregroundColor(primaryTextColor)
                                        Text(displayedProductPrice(variant.price))
                                            .font(labelFont(size: 10, weight: .bold))
                                            .tracking(AppLocalization.letterSpacing(1.4))
                                            .foregroundColor(readableBrandGoldColor)
                                    }

                                    Spacer()

                                    Text(variant.isAvailableForSale ? AppLocalization.text("available", fallback: "Available") : AppLocalization.text("sold_out", fallback: "Sold Out"))
                                        .font(labelFont(size: 9, weight: .bold))
                                        .tracking(AppLocalization.letterSpacing(1.4))
                                        .textCase(.uppercase)
                                        .foregroundColor(variant.isAvailableForSale ? primaryTextColor : tertiaryTextColor)

                                    Image(systemName: selectedVariant?.id == variant.id ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedVariant?.id == variant.id ? TallaTheme.Colors.accent : tertiaryTextColor)
                                }
                                .padding(14)
                                .background(cardFillColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(
                                            (selectedVariant?.id == variant.id ? TallaTheme.Colors.accent : TallaTheme.Colors.accent.opacity(0.14)),
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
                        detail: canPurchase ? AppLocalization.text("ready_to_order", fallback: "Ready to order now") : AppLocalization.text("currently_sold_out", fallback: "Currently sold out"),
                        titleFont: labelFont(size: 10, weight: .bold),
                        detailFont: bodyFont(size: 13),
                        accentColor: TallaTheme.Colors.accent,
                        primaryTextColor: primaryTextColor,
                        backgroundColor: cardFillColor,
                        strokeColor: TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08)
                    )
                    DetailStatusCardView(
                        title: AppLocalization.text("category", fallback: "Category"),
                        detail: product.categoryLabel,
                        titleFont: labelFont(size: 10, weight: .bold),
                        detailFont: bodyFont(size: 13),
                        accentColor: TallaTheme.Colors.accent,
                        primaryTextColor: primaryTextColor,
                        backgroundColor: cardFillColor,
                        strokeColor: TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08)
                    )
                }

                VStack(spacing: 12) {
                    if isBrewableCoffee(product) {
                        Button {
                            startBrewing(product: product, useRecommendedRecipe: true)
                        } label: {
                            Label(
                                AppLocalization.text("recommended_recipe", fallback: "Brew the Recommended Recipe"),
                                systemImage: "wand.and.stars"
                            )
                                .font(labelFont(size: 11, weight: .bold))
                                .tracking(AppLocalization.letterSpacing(1.6))
                                .textCase(.uppercase)
                                .foregroundColor(Color(hex: 0x0A0804))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(TallaTheme.Colors.accent)
                                .clipShape(Capsule(style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("product.recommended-recipe.primary")

                        if let setupProduct = starterSetupProduct(for: product) {
                            Button {
                                addToCart(product: product)
                                addToCart(product: setupProduct)
                                showToast(message: AppLocalization.text("setup_added_to_bag", fallback: "Coffee and starter setup added to your bag."))
                            } label: {
                                Label(
                                    AppLocalization.text("buy_the_setup", fallback: "Buy the Setup"),
                                    systemImage: "shippingbox.and.arrow.backward.fill"
                                )
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(AppLocalization.letterSpacing(1.4))
                                .textCase(.uppercase)
                                .foregroundColor(primaryTextColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(TallaTheme.Colors.accent.opacity(0.14))
                                .overlay(Capsule().stroke(TallaTheme.Colors.accent.opacity(0.32), lineWidth: 1))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("product.buy-setup")
                        }

                    }
                    HStack(spacing: 12) {
                        if !product.isAvailableForSale || isAlertEnabled(product) {
                            Button {
                                Task {
                                    await toggleAlert(product: product)
                                }
                            } label: {
                                Label(
                                    isAlertEnabled(product)
                                        ? AppLocalization.text("notification_on", fallback: "Notification On")
                                        : AppLocalization.text("notify_when_available", fallback: "Notify When Available"),
                                    systemImage: isAlertEnabled(product) ? "bell.fill" : "bell"
                                )
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(AppLocalization.letterSpacing(1.4))
                                    .textCase(.uppercase)
                                    .foregroundColor(primaryTextColor)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(cardFillColor)
                                    .overlay(
                                        Capsule()
                                            .stroke(TallaTheme.Colors.accent.opacity(0.18), lineWidth: 1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        addToCart(product: product)
                        selectedProduct = nil
                    } label: {
                        Text((selectedVariant?.isAvailableForSale ?? product.isAvailableForSale) ? AppLocalization.text("add_to_bag", fallback: "Add to Bag") : AppLocalization.text("sold_out", fallback: "Sold Out"))
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(2))
                            .textCase(.uppercase)
                            .foregroundColor((selectedVariant?.isAvailableForSale ?? product.isAvailableForSale) ? Color(hex: 0x0A0804) : tertiaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .tallaGlassCapsule(
                                tint: TallaTheme.Colors.accent,
                                enabled: selectedVariant?.isAvailableForSale ?? product.isAvailableForSale
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

    @ViewBuilder
    func productTasteProfileFitSection(_ product: Product) -> some View {
        let score = tastePreferenceScore(for: product)
        let productText = normalizedSearchText(for: product)
        let matchingProfileSignals = tasteProfileLabels.filter { label in
            let keywords: [String]
            switch label {
            case AppLocalization.text("taste_acidity_low", fallback: "Low acidity"):
                keywords = ["smooth", "low acid", "chocolate", "nutty", "brazil"]
            case AppLocalization.text("taste_acidity_balanced", fallback: "Balanced acidity"):
                keywords = ["balanced", "clean", "sweet"]
            case AppLocalization.text("taste_acidity_high", fallback: "Bright acidity"):
                keywords = ["bright", "acid", "citrus", "floral", "fruit", "berry"]
            case AppLocalization.text("taste_sweetness_sweet", fallback: "Sweet"):
                keywords = ["sweet", "caramel", "honey", "chocolate"]
            case AppLocalization.text("taste_body_full", fallback: "Full body"):
                keywords = ["body", "rich", "espresso", "chocolate", "nutty"]
            case AppLocalization.text("taste_body_light", fallback: "Light body"):
                keywords = ["tea", "clean", "floral", "washed"]
            case AppLocalization.text("taste_temperature_iced", fallback: "Iced"):
                keywords = ["iced", "cold", "summer", "refreshing"]
            case AppLocalization.text("taste_style_arabic", fallback: "Arabic coffee"):
                keywords = ["arabic", "qahwa", "cardamom", "yemen"]
            default:
                keywords = [label.lowercased()]
            }
            return keywords.contains(where: { productText.contains($0) })
        }

        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: score >= 0 ? "wand.and.stars" : "slider.horizontal.3")
                    .foregroundColor(readableBrandGoldColor)
                Text("Fits your taste profile")
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(AppLocalization.letterSpacing(1.5))
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)
                Spacer()
                Text(score >= 10
                     ? AppLocalization.text("taste_match_strong", fallback: "Strong fit")
                     : score >= 4
                        ? AppLocalization.text("taste_match_possible", fallback: "Possible fit")
                        : AppLocalization.text("taste_match_explore", fallback: "Explore beyond your usual"))
                    .font(labelFont(size: 9, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
            }

            Text(matchingProfileSignals.isEmpty
                 ? AppLocalization.text("taste_match_explore_detail", fallback: "A Talla pick to help you explore beyond your usual cup.")
                 : String(format: AppLocalization.text("taste_match_signals_format", fallback: "This coffee overlaps with %@."), matchingProfileSignals.prefix(2).joined(separator: " and ")))
                .font(bodyFont(size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 7) {
                ForEach(Array(tasteProfileLabels.prefix(4)), id: \.self) { label in
                    Text(label)
                        .font(labelFont(size: 9, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(elevatedSurfaceColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.08 : 0.11))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    func productFactsSection(_ product: Product) -> some View {
        let isGiftBox = product.categoryKey == "gifts"
        let origin = productCountryOfOrigin(for: product)
        let summary = productTasteSummary(for: product)
        let facts: [(String, String)] = isGiftBox
            ? [(AppLocalization.text("contents", fallback: "Contents"), summary.isEmpty ? AppLocalization.text("gift_box", fallback: "Gift box") : summary)]
            : [
                (AppLocalization.text("origin", fallback: "Origin"), origin ?? "—"),
                (AppLocalization.text("tasting_notes", fallback: "Tasting notes"), summary.isEmpty ? "—" : summary)
            ]
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text(isGiftBox ? "box_details" : "coffee_facts", fallback: isGiftBox ? "Box details" : "Coffee facts"))
                .font(labelFont(size: 10, weight: .bold))
                .tracking(AppLocalization.letterSpacing(1.8))
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)
            ForEach(Array(facts.enumerated()), id: \.offset) { _, fact in
                VStack(alignment: .leading, spacing: 3) {
                    Text(fact.0).font(labelFont(size: 9, weight: .bold)).foregroundColor(tertiaryTextColor)
                    Text(fact.1).font(bodyFont(size: 13)).foregroundColor(primaryTextColor).fixedSize(horizontal: false, vertical: true)
                }
            }
            if !productMetadataChips(for: product).isEmpty {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                    ForEach(Array(productMetadataChips(for: product).enumerated()), id: \.offset) { _, chip in
                        productMetadataChip(icon: chip.icon, title: chip.title)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(14)
        .background(cardFillColor)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("product.coffee-facts")
    }

    func starterSetupProduct(for coffee: Product) -> Product? {
        let coffeeText = coffee.catalogClassificationText.lowercased()
        return products.first { product in
            guard product.categoryKey == "coffee-equipment", product.isAvailableForSale else { return false }
            let text = product.catalogClassificationText.lowercased()
            if coffeeText.contains("espresso") { return text.contains("espresso") || text.contains("machine") }
            if coffeeText.contains("aeropress") { return text.contains("aeropress") }
            return text.contains("v60") || text.contains("pour") || text.contains("filter") || text.contains("brewer")
        }
    }

    @ViewBuilder
    func productImageGallery(_ product: Product) -> some View {
        let images = product.imageURLs
        if images.count > 1 {
            TabView {
                ForEach(Array(images.enumerated()), id: \.element) { index, imageURL in
                    ProductThumbnail(imageURL: imageURL, size: nil, cornerRadius: 22)
                        .accessibilityLabel("\(product.name), photo \(index + 1) of \(images.count)")
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 240)
        } else {
            ProductThumbnail(imageURL: images.first, size: nil, cornerRadius: 22)
                .frame(height: 240)
                .accessibilityLabel(product.name)
        }
    }

    func isBrewableCoffee(_ product: Product) -> Bool {
        ["coffee-beans", "arabic-coffee-beans", "drip-bags"].contains(product.categoryKey)
    }

    func collectionTile(eyebrow: String, name: String, desc: String, accent: String, systemImage: String, color: Color, categoryKey: String) -> some View {
        Button {
            openShop(category: categoryKey)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(eyebrow)
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(2.4))
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)

                        Text(name)
                            .font(titleFont(size: 22))
                            .foregroundColor(primaryTextColor)
                    }

                    Spacer()

                    Image(systemName: systemImage)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(readableBrandGoldColor)
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
                        .foregroundColor(TallaTheme.Colors.accent.opacity(0.72))
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

    func featureItem(symbol: String, eyebrow: String, title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: eyebrow.isEmpty ? 0 : 8) {
                    if !eyebrow.isEmpty {
                        Text(eyebrow)
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(2.4))
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
                            : (isOLEDAppearance
                                ? [.black, .black]
                                : [
                                    Color(hex: 0x241A12).opacity(0.94),
                                    elevatedSurfaceColor.opacity(0.96)
                                ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.18 : 0.08), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color(hex: 0xD8AE72).opacity(isLightAppearance ? 0.16 : 0.08))
                .frame(width: 68, height: 68)
                .blur(radius: 10)
                .offset(x: 14, y: -10)
        }
    }

    func heroStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(value)
                .font(titleFont(size: 22))
                .foregroundColor(primaryTextColor)

            Text(label)
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Capsule(style: .continuous)
                .fill(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.22 : 0.14))
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
                            : (isOLEDAppearance
                                ? [.black, .black]
                                : [
                                    Color.white.opacity(0.03),
                                    Color(hex: 0x2A1D14).opacity(0.82)
                                ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.18 : 0.09), lineWidth: 1)
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

    func loyaltyBenefit(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(labelFont(size: 11, weight: .bold))
                .tracking(AppLocalization.letterSpacing(2))
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

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
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func loyaltyRewardsActions(account: LoyaltyAccount) -> some View {
        LoyaltyRewardsActionsView(
            account: account,
            configuration: remoteAppSettings?.loyalty,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: TallaTheme.Colors.accent,
            isLightAppearance: isLightAppearance,
            isRedeemingReward: isRedeemingReward,
            redeemAction: { points, rewardID, rewardTitle in
                Task {
                    await redeemReward(points: points, rewardID: rewardID, rewardTitle: rewardTitle)
                }
            }
        )
    }

    func loyaltyProgressCard(title: String, accent: String, current: Int, target: Int, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(AppLocalization.letterSpacing(2))
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)

                Spacer()

                Text("\(current)/\(target)")
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
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var expiringRewardsSection: some View {
        ExpiringRewardsSectionView(
            vouchers: expiringVouchers,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: TallaTheme.Colors.accent,
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

    func loyaltyTransactionsSection(account: LoyaltyAccount) -> some View {
        LoyaltyTransactionsSectionView(
            account: account,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            accentColor: TallaTheme.Colors.accent,
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance
        )
    }

    var walletCallToAction: some View {
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

    func infoChip(symbol: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16))
                .foregroundColor(readableBrandGoldColor)

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .tracking(AppLocalization.letterSpacing(2))
                .textCase(.uppercase)
                .foregroundColor(secondaryTextColor)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(TallaTheme.Colors.accent.opacity(0.15), lineWidth: 1)
        )
    }

    func infoTile(title: String, detail: String, actionTitle: String, destination: URL) -> some View {
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
                .tracking(AppLocalization.letterSpacing(1.8))
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    func socialChip(label: String, systemImage: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(label)
        }
        .font(.system(size: 10, weight: .medium))
        .tracking(AppLocalization.letterSpacing(2))
        .textCase(.uppercase)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(TallaTheme.Colors.accent.opacity(0.2), lineWidth: 1)
        )
        .foregroundColor(primaryTextColor)
    }

    func formattedRatioValue(_ value: Double) -> String {
        if value == 0 {
            return "0"
        }

        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value)
    }

    func displayFont(size: CGFloat) -> Font {
        isArabicInterface ? .system(size: size * displayFontScale, weight: .bold) : .custom("Georgia-Bold", size: size, relativeTo: .largeTitle)
    }

    func titleFont(size: CGFloat) -> Font {
        isArabicInterface ? .system(size: size * titleFontScale, weight: .bold) : .custom("Georgia-Bold", size: size, relativeTo: .title3)
    }

    func bodyFont(size: CGFloat) -> Font {
        isArabicInterface ? .system(size: size * bodyFontScale) : .custom("AvenirNext-Regular", size: size, relativeTo: .body)
    }

    func labelFont(size: CGFloat, weight: Font.Weight) -> Font {
        if isArabicInterface { return .system(size: size * labelFontScale, weight: weight) }
        switch weight {
        case .bold:
            return .custom("AvenirNext-Bold", size: size, relativeTo: .caption)
        case .semibold:
            return .custom("AvenirNext-DemiBold", size: size, relativeTo: .caption)
        default:
            return .custom("AvenirNext-Medium", size: size, relativeTo: .caption)
        }
    }

}
