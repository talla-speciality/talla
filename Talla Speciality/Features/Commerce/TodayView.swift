import SwiftUI

extension ContentView {
    /// The daily coffee loop: choose a cup, brew it, learn from the result, and
    /// keep the next bag within reach. Commerce shelves remain available from
    /// Shop and the existing home implementation is retained as a fallback.
    var homeView: some View {
        legacyHomeView
    }

    var todayView: some View {
        VStack(alignment: .leading, spacing: 18) {
            todayGreeting
            todayNextCupCard
            todayBrewCard
            todayLastResultCard
            todayReorderCard
            todayDiscoveryCard
            todayQuickLinks
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .accessibilityIdentifier("home.today")
        .task { await loadNextCupRecommendation() }
    }

    @ViewBuilder
    var todayNextCupCard: some View {
        Group {
            if let response = nextCupRecommendation,
               let recommendation = response.recommendations.first {
            let product = products.first {
                $0.id == recommendation.productID || recommendation.productID.hasSuffix("/\($0.id)") || $0.id.hasSuffix("/\(recommendation.productID)")
            }
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: response.action == "reorder-or-discover" ? "arrow.clockwise.circle.fill" : "sparkles")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(readableBrandGoldColor)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(response.headline)
                            .font(displayFont(size: 20))
                            .foregroundColor(primaryTextColor)
                        Text(recommendation.title)
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(AppLocalization.letterSpacing(1.1))
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)
                    }
                    Spacer(minLength: 0)
                }

                Text(recommendation.recommendation.summary)
                    .font(bodyFont(size: 12))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                if !recommendation.recommendation.reasons.isEmpty {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(Array(recommendation.recommendation.reasons.prefix(3)), id: \.self) { reason in
                                Label(reason, systemImage: "checkmark.circle")
                                    .font(bodyFont(size: 11))
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                        .padding(.top, 4)
                    } label: {
                        Text(AppLocalization.text("why_this_pick", fallback: "Why this pick"))
                            .font(labelFont(size: 10, weight: .semibold))
                            .foregroundColor(readableBrandGoldColor)
                    }
                    .tint(readableBrandGoldColor)
                }

                if response.freshness.state != "unknown" {
                    Label(
                        response.freshness.state == "stale-risk" ? "Use your current bag soon" : "Your coffee freshness is being tracked",
                        systemImage: response.freshness.state == "stale-risk" ? "clock.badge.exclamationmark" : "leaf.fill"
                    )
                    .font(labelFont(size: 10, weight: .semibold))
                    .foregroundColor(response.freshness.state == "stale-risk" ? .orange : readableBrandGoldColor)
                }

                if let reorder = response.coffeeInsights?.reorder.first {
                    Label(
                        "\(reorder.productName) · about \(reorder.estimatedBrews) brews left",
                        systemImage: "arrow.clockwise.circle"
                    )
                    .font(labelFont(size: 10, weight: .semibold))
                    .foregroundColor(.orange)
                }

                HStack(spacing: 9) {
                    Button {
                        Task { await NextCupRecommendationService.record(action: "brew", productID: recommendation.productID) }
                        if let product { startBrewing(product: product, useRecommendedRecipe: true) } else { openBrewing() }
                    } label: {
                        Label(AppLocalization.text("brew_this", fallback: "Brew this"), systemImage: "drop.fill")
                            .font(labelFont(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(TallaTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        let action = response.action == "reorder-or-discover" ? "reorder" : "buy"
                        Task { await NextCupRecommendationService.record(action: action, productID: recommendation.productID) }
                        if let product { openShop(category: product.categoryKey, searchQuery: product.name) } else { openShop(category: "coffee-beans") }
                    } label: {
                            Label(response.action == "reorder-or-discover" ? AppLocalization.text("reorder", fallback: "Reorder") : AppLocalization.text("shop_now", fallback: "Shop"), systemImage: response.action == "reorder-or-discover" ? "arrow.clockwise" : "bag.fill")
                            .font(labelFont(size: 10, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(cardFillColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(TallaTheme.Colors.ink.opacity(0.14), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(15)
            .background(cardFillColor.opacity(isLightAppearance ? 0.86 : 0.66), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.36 : 0.25), lineWidth: 1))
            .padding(.horizontal, 18)
            .accessibilityIdentifier("home.nextCupRecommendation")
            } else if isLoadingNextCupRecommendation {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
        }
        .task { await loadNextCupRecommendation() }
    }

    @MainActor
    func loadNextCupRecommendation() async {
        guard !TallaAccountCredentialStore.accessToken.isEmpty, nextCupRecommendation == nil, !isLoadingNextCupRecommendation else { return }
        isLoadingNextCupRecommendation = true
        defer { isLoadingNextCupRecommendation = false }
        nextCupRecommendation = try? await NextCupRecommendationService.fetch()
    }

    private var todayGreeting: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(todayDateTitle)
                .font(labelFont(size: 11, weight: .bold))
                .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.4)
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

            Text(AppLocalization.text("today_title", fallback: "Your coffee, today"))
                .font(displayFont(size: isCompact ? 30 : 36))
                .foregroundColor(primaryTextColor)

            Text(AppLocalization.text("today_subtitle", fallback: "One good cup, then a better one tomorrow."))
                .font(bodyFont(size: 14))
                .foregroundColor(secondaryTextColor)
        }
        .padding(.top, 4)
    }

    var todayDateTitle: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var todayCoffeeCandidates: [Product] {
        let sources = homePurchasedCoffeeProducts
            + coffeeLotRecommendations.map(\.product)
            + recommendedProducts
            + products

        return sources.reduce(into: [Product]()) { result, product in
            let isCoffee = ["coffee-beans", "arabic-coffee-beans"].contains(product.categoryKey.lowercased())
            guard product.isAvailableForSale, isCoffee else { return }
            guard !result.contains(where: { $0.id == product.id }) else { return }
            result.append(product)
        }
    }

    var todayBrewProduct: Product? {
        let candidates = todayCoffeeCandidates
        guard !candidates.isEmpty else { return nil }
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return candidates[(dayOfYear - 1) % candidates.count]
    }

    var todayCompactCard: some View {
        Button {
            if let product = todayBrewProduct {
                openShop(category: product.categoryKey, searchQuery: product.name)
            } else if tasteProfileConfigured {
                openShop(category: "coffee-beans")
            } else {
                openTasteProfileEditor()
            }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "sunrise.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(readableBrandGoldColor)

                VStack(alignment: .leading, spacing: 3) {
                    Text(AppLocalization.text("today", fallback: "Today"))
                        .font(labelFont(size: 9, weight: .bold))
                        .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 0.8)
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)
                    Text(todayDateTitle)
                        .font(bodyFont(size: 13))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 10)

                Text(todayBrewProduct.map { customerFacingProductName(for: $0) } ?? AppLocalization.text("today_start", fallback: "Start your ritual"))
                    .font(bodyFont(size: 11))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(cardFillColor.opacity(isLightAppearance ? 0.78 : 0.62))
            .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(TallaTheme.Colors.ink.opacity(0.16), lineWidth: 0.8))
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
        .accessibilityIdentifier("home.todayCard")
    }

    private var todayBrewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(AppLocalization.text("today_brew_next", fallback: "Brew next"), systemImage: "drop.fill")
                    .font(labelFont(size: 11, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
                Spacer()
                Text(AppLocalization.text("today_personalized", fallback: "FOR YOU"))
                    .font(labelFont(size: 9, weight: .bold))
                    .foregroundColor(secondaryTextColor)
            }

            if let product = todayBrewProduct {
                HStack(spacing: 14) {
                    ProductThumbnail(imageURL: product.imageURL, size: isCompact ? 82 : 96, cornerRadius: 18)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(customerFacingProductName(for: product))
                            .font(titleFont(size: isCompact ? 20 : 23))
                            .foregroundColor(primaryTextColor)
                            .lineLimit(2)
                        Text(homePurchasedCoffeeProducts.contains(where: { $0.id == product.id })
                             ? AppLocalization.text("today_on_shelf", fallback: "Already on your shelf")
                             : AppLocalization.text("today_match", fallback: "A match for your taste"))
                            .font(bodyFont(size: 12))
                            .foregroundColor(secondaryTextColor)
                    }
                    Spacer(minLength: 0)
                }

                Button {
                    TallaTelemetry.shared.track("today_brew_started")
                    startBrewing(product: product, useRecommendedRecipe: true)
                } label: {
                    Label(AppLocalization.text("today_start_brewing", fallback: "Start brewing"), systemImage: "play.fill")
                        .font(labelFont(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(TallaTheme.Colors.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("today.startBrewing")
            } else {
                Text(AppLocalization.text("today_no_coffee", fallback: "Choose a coffee and Talla will build your daily ritual here."))
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                Button(
                    tasteProfileConfigured
                        ? AppLocalization.text("today_browse_coffee", fallback: "Browse coffee")
                        : AppLocalization.text("today_set_taste", fallback: "Set your taste")
                ) {
                    if tasteProfileConfigured {
                        openShop(category: "coffee-beans")
                    } else {
                        openTasteProfileEditor()
                    }
                }
                    .buttonStyle(.tallaPrimary)
                    .accessibilityIdentifier(tasteProfileConfigured ? "today.browseCoffee" : "today.setTaste")
            }
        }
        .padding(16)
        .background(todayCardBackground)
        .accessibilityIdentifier("today.brewCard")
    }

    private var todayLastResultCard: some View {
        Group {
            if let entry = brewJournalEntries.sorted(by: { $0.createdAt > $1.createdAt }).first {
                VStack(alignment: .leading, spacing: 10) {
                    todaySectionLabel(AppLocalization.text("today_last_result", fallback: "Last result"), systemImage: "checkmark.seal.fill")
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.title)
                                .font(titleFont(size: 19))
                                .foregroundColor(primaryTextColor)
                            Text(entry.method)
                                .font(bodyFont(size: 12))
                                .foregroundColor(secondaryTextColor)
                        }
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { index in
                                Image(systemName: index <= entry.rating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(readableBrandGoldColor)
                            }
                        }
                    }
                    if !entry.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(entry.notes)
                            .font(bodyFont(size: 13))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(2)
                    }
                    Label(todayImprovementHint(for: entry.rating), systemImage: "lightbulb.fill")
                        .font(bodyFont(size: 12))
                        .foregroundColor(readableBrandGoldColor)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(AppLocalization.text("today_improve_next", fallback: "Improve the next cup")) { openCoffeeJournal() }
                        .font(labelFont(size: 10, weight: .bold))
                        .buttonStyle(.plain)
                        .foregroundColor(readableBrandGoldColor)
                        .accessibilityIdentifier("today.improveNext")
                }
                .padding(16)
                .background(todayCardBackground)
                .accessibilityIdentifier("today.lastResult")
            }
        }
    }

    private func todayImprovementHint(for rating: Int) -> String {
        switch rating {
        case 1...2:
            return AppLocalization.text("today_change_low", fallback: "Next experiment: grind a little finer and slow the pour.")
        case 3:
            return AppLocalization.text("today_change_mid", fallback: "Next experiment: keep the recipe and change one variable only.")
        default:
            return AppLocalization.text("today_change_high", fallback: "Next experiment: repeat this recipe before changing anything.")
        }
    }

    private var todayReorderCard: some View {
        Group {
            if let recommendation = coffeeLotRecommendations.first(where: { $0.product.isAvailableForSale }) {
                todayReorderRow(
                    product: recommendation.product,
                    detail: recommendation.reason,
                    actionTitle: AppLocalization.text("today_reorder", fallback: "Restock"),
                    action: {
                        TallaTelemetry.shared.track("today_restock_started", properties: ["product": recommendation.product.name])
                        addToCart(product: recommendation.product)
                        cartOpen = true
                    }
                )
            } else if let prompt = reorderPrompt {
                todayReorderRow(
                    product: prompt.product,
                    detail: String(format: AppLocalization.text("today_reorder_detail", fallback: "%@ was ordered %d days ago"), customerFacingProductName(for: prompt.product), prompt.daysAgo),
                    actionTitle: AppLocalization.text("reorder", fallback: "Reorder"),
                    action: {
                        TallaTelemetry.shared.track("today_reorder_started", properties: ["product": prompt.product.name])
                        buyAgain(order: prompt.order)
                    }
                )
            }
        }
    }

    private func todayReorderRow(product: Product, detail: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            ProductThumbnail(imageURL: product.imageURL, size: 48, cornerRadius: 12)
            VStack(alignment: .leading, spacing: 3) {
                Text(AppLocalization.text("today_reorder_title", fallback: "Keep the ritual going"))
                    .font(labelFont(size: 11, weight: .bold))
                    .foregroundColor(primaryTextColor)
                Text(detail)
                    .font(bodyFont(size: 11))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            Button(actionTitle, action: action)
                .font(labelFont(size: 10, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(TallaTheme.Colors.accent, in: Capsule())
                .buttonStyle(.plain)
                .accessibilityIdentifier("today.reorder.action")
        }
        .padding(13)
        .background(todayCardBackground)
        .accessibilityIdentifier("today.reorder")
    }

    private var todayDiscoveryCard: some View {
        Group {
            if let product = recommendedProducts.first(where: { $0.id != todayBrewProduct?.id }) ?? recommendedProducts.first {
                Button {
                    TallaTelemetry.shared.track("today_discovery_opened", properties: ["product": product.name])
                    recordRecentlyViewed(product)
                    selectedProduct = product
                } label: {
                    HStack(spacing: 13) {
                        ProductThumbnail(imageURL: product.imageURL, size: 62, cornerRadius: 14)
                        VStack(alignment: .leading, spacing: 4) {
                            todaySectionLabel(AppLocalization.text("today_try_next", fallback: "Try something new"), systemImage: "sparkles")
                            Text(customerFacingProductName(for: product))
                                .font(titleFont(size: 18))
                                .foregroundColor(primaryTextColor)
                                .lineLimit(1)
                            Text(productTasteSummary(for: product))
                                .font(bodyFont(size: 11))
                                .foregroundColor(secondaryTextColor)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .foregroundColor(readableBrandGoldColor)
                    }
                }
                .buttonStyle(.plain)
                .padding(13)
                .background(todayCardBackground)
                .accessibilityIdentifier("today.discovery")
            }
        }
    }

    private var todayQuickLinks: some View {
        HStack(spacing: 10) {
            todayQuickLink(title: AppLocalization.text("journal", fallback: "Journal"), icon: "book.closed", identifier: "today.journal", action: {
                TallaTelemetry.shared.track("today_journal_opened")
                openCoffeeJournal()
            })
            todayQuickLink(title: AppLocalization.text("shop", fallback: "Shop"), icon: "square.grid.2x2", identifier: "today.shop", action: { openShop(category: "coffee-beans") })
        }
    }

    private func todayQuickLink(title: String, icon: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(labelFont(size: 10, weight: .bold))
                .foregroundColor(primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(elevatedSurfaceColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private func todaySectionLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(labelFont(size: 10, weight: .bold))
            .foregroundColor(readableBrandGoldColor)
    }

    private var todayCardBackground: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(cardFillColor.opacity(isLightAppearance ? 0.82 : 0.66))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.14 : 0.10), lineWidth: 1))
    }
}
