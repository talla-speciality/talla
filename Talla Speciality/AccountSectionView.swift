import SwiftUI

struct AccountSectionView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var presentedDetail: AccountDetail?
    @State private var handledOrdersPresentationRequest = 0

    private enum AccountDetail: String, Identifiable {
        case personalDetails
        case password
        case orders
        case addresses
        case savedCarts
        case alerts
        case beansBalance
        case rewardProgress
        case redeemRewards
        case appleWallet
        case favourites
        case recentlyViewed
        case savedRecipes
        case journalEntries
        case brewArchive
        case support

        var id: String { rawValue }
    }

    enum ScrollTarget {
        static let customer = "account-customer"
        static let loyalty = "account-loyalty"
        static let library = "account-library"
        static let shopping = "account-shopping"
        static let brewing = "account-brewing"
        static let support = "account-support"
    }

    let primaryTextColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let cardFillColor: Color
    let accentColor: Color
    let isLightAppearance: Bool
    let titleFont: Font
    let introFont: Font
    let bodyFont: Font
    let labelFont: Font
    let sectionTitleFont: Font
    let sectionBodyFont: Font
    let quickActionTitleFont: Font
    let quickActionBodyFont: Font
    let isCustomerSignedIn: Bool
    let accountDisplayName: String
    let accountEmail: String
    let membershipTier: String
    let beansBalance: Int
    let beansUntilNextReward: Int
    let orderCount: Int
    let addressesCount: Int
    let favoriteCount: Int
    let brewRecipeCount: Int
    let journalEntryCount: Int
    let latestOrderTitle: String?
    let latestOrderDetail: String?
    let recentlySavedTitle: String?
    let recentlySavedDetail: String?
    @Binding var isCustomerSectionExpanded: Bool
    @Binding var isLoyaltySectionExpanded: Bool
    @Binding var isLibrarySectionExpanded: Bool
    @Binding var isShoppingSectionExpanded: Bool
    @Binding var isBrewingSectionExpanded: Bool
    @Binding var isSupportSectionExpanded: Bool
    let ordersPresentationRequest: Int
    let openOrdersAction: () -> Void
    let signOutAction: () -> Void
    let customerAccountSection: AnyView
    let personalDetailsSection: AnyView
    let passwordSection: AnyView
    let ordersSection: AnyView
    let loyaltySection: AnyView
    let addressesSection: AnyView
    let savedCartsSection: AnyView
    let alertsSection: AnyView
    let favoritesSection: AnyView
    let recentlyViewedSection: AnyView
    let savedRecipesSection: AnyView
    let journalSection: AnyView
    let supportSection: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            accountSummaryCard
            accountQuickActions
            accountHomeHighlights
            accountNavigationAreas
        }
        .sheet(item: $presentedDetail) { detail in
            accountDetailScreen(detail)
        }
        .onAppear {
            handleOrdersPresentationRequest(ordersPresentationRequest)
        }
        .onChange(of: ordersPresentationRequest) { _, request in
            handleOrdersPresentationRequest(request)
        }
    }

    private func handleOrdersPresentationRequest(_ request: Int) {
        guard request > 0, request != handledOrdersPresentationRequest else { return }
        handledOrdersPresentationRequest = request
        isCustomerSectionExpanded = true
        presentedDetail = .orders
        openOrdersAction()
    }

    private var accountSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 46, height: 46)
                    .background(accentColor.opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(accountDisplayName)
                        .font(titleFont)
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)

                    if !accountEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(accountEmail)
                            .font(quickActionBodyFont)
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }

                    Text(String(format: AppLocalization.text("membership_tier_format", fallback: "Membership: %@"), membershipTier))
                        .font(Font.custom("AvenirNext-Bold", size: 12))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)
            }

            HStack(spacing: 10) {
                accountSummaryMetric(
                    value: "\(beansBalance)",
                    label: AppLocalization.text("beans", fallback: "Beans")
                )

                accountSummaryMetric(
                    value: "\(beansUntilNextReward)",
                    label: AppLocalization.text("until_next_reward", fallback: "until reward")
                )
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .id(ScrollTarget.loyalty)
    }

    private func accountSummaryMetric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(Font.custom("Georgia-Bold", size: 28))
                .foregroundColor(primaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(label)
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(1.3)
                .textCase(.uppercase)
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(isLightAppearance ? 0.08 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var accountHomeHighlights: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let latestOrderTitle, let latestOrderDetail {
                accountHighlightCard(
                    eyebrow: AppLocalization.text("latest_order", fallback: "Latest order"),
                    title: latestOrderTitle,
                    detail: latestOrderDetail,
                    systemImage: "shippingbox.fill",
                    action: {
                        presentedDetail = .orders
                        isCustomerSectionExpanded = true
                        openOrdersAction()
                    }
                )
            }

            if let recentlySavedTitle, let recentlySavedDetail {
                accountHighlightCard(
                    eyebrow: AppLocalization.text("recently_saved_item", fallback: "Recently saved item"),
                    title: recentlySavedTitle,
                    detail: recentlySavedDetail,
                    systemImage: "heart.fill",
                    action: {
                        presentedDetail = .favourites
                        isShoppingSectionExpanded = true
                    }
                )
            }
        }
    }

    private func accountHighlightCard(
        eyebrow: String,
        title: String,
        detail: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 38, height: 38)
                    .background(accentColor.opacity(isLightAppearance ? 0.10 : 0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(eyebrow)
                        .font(labelFont)
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                        .lineLimit(1)

                    Text(title)
                        .font(quickActionTitleFont)
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(detail)
                        .font(quickActionBodyFont)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tertiaryTextColor)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var accountNavigationAreas: some View {
        VStack(alignment: .leading, spacing: 12) {
            accountAreaCard(
                title: AppLocalization.text("account_and_settings", fallback: "Account & Settings"),
                rows: [
                    accountNavigationRowData(
                        detail: .personalDetails,
                        title: AppLocalization.text("personal_information", fallback: "Personal information"),
                        subtitle: accountProfileSubtitle,
                        systemImage: "person.text.rectangle.fill"
                    ),
                    accountNavigationRowData(
                        detail: .password,
                        title: AppLocalization.text("password_and_security", fallback: "Password and security"),
                        subtitle: AppLocalization.text("manage_password", fallback: "Manage password"),
                        systemImage: "lock.fill"
                    ),
                    accountNavigationRowData(
                        detail: .support,
                        title: AppLocalization.text("support", fallback: "Support"),
                        subtitle: AppLocalization.text("settings_help_summary", fallback: "Language, notifications, support"),
                        systemImage: "gearshape.fill"
                    )
                ]
            )
            .id(ScrollTarget.customer)

            accountAreaCard(
                title: AppLocalization.text("shopping_tools", fallback: "Shopping tools"),
                rows: [
                    accountNavigationRowData(
                        detail: .savedCarts,
                        title: AppLocalization.text("saved_carts", fallback: "Saved bags"),
                        subtitle: AppLocalization.text("resume_checkout", fallback: "Resume checkout"),
                        systemImage: "bag.badge.plus"
                    ),
                    accountNavigationRowData(
                        detail: .alerts,
                        title: AppLocalization.text("back_in_stock_alerts", fallback: "Back-in-stock alerts"),
                        subtitle: AppLocalization.text("notify_when_available", fallback: "Notify when available"),
                        systemImage: "bell.fill"
                    )
                ]
            )
            .id(ScrollTarget.library)

            accountAreaCard(
                title: AppLocalization.text("brewing", fallback: "Brewing"),
                rows: [
                    accountNavigationRowData(
                        detail: .brewArchive,
                        title: AppLocalization.text("brew_archive", fallback: "Brew Archive"),
                        subtitle: brewArchiveSubtitle,
                        systemImage: "book.closed.fill"
                    )
                ]
            )
            .id(ScrollTarget.brewing)

            accountAreaCard(
                title: AppLocalization.text("session", fallback: "Session"),
                rows: [
                    accountNavigationRowData(
                        detail: nil,
                        title: AppLocalization.text("sign_out", fallback: "Sign out"),
                        subtitle: isCustomerSignedIn ? AppLocalization.text("end_session", fallback: "End this session") : AppLocalization.text("not_signed_in", fallback: "Not signed in"),
                        systemImage: "rectangle.portrait.and.arrow.right",
                        action: signOutAction
                    )
                ]
            )
        }
    }

    private struct AccountNavigationRowData: Identifiable {
        let id = UUID()
        let detail: AccountDetail?
        let title: String
        let subtitle: String
        let systemImage: String
        let action: (() -> Void)?
    }

    private func accountNavigationRowData(
        detail: AccountDetail?,
        title: String,
        subtitle: String,
        systemImage: String,
        action: (() -> Void)? = nil
    ) -> AccountNavigationRowData {
        AccountNavigationRowData(detail: detail, title: title, subtitle: subtitle, systemImage: systemImage, action: action)
    }

    private func accountAreaCard(title: String, rows: [AccountNavigationRowData]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(sectionTitleFont)
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            VStack(spacing: 0) {
                ForEach(rows.indices, id: \.self) { index in
                    accountNavigationRow(rows[index])

                    if index < rows.count - 1 {
                        Rectangle()
                            .fill(accentColor.opacity(isLightAppearance ? 0.10 : 0.06))
                            .frame(height: 1)
                            .padding(.leading, 50)
                    }
                }
            }
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func accountNavigationRow(_ row: AccountNavigationRowData) -> some View {
        Button {
            row.action?()
            if let detail = row.detail {
                presentedDetail = detail
                expandBackingSection(for: detail)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: row.systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 34, height: 34)
                    .background(accentColor.opacity(isLightAppearance ? 0.10 : 0.14))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(row.title)
                        .font(quickActionTitleFont)
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)

                    Text(row.subtitle)
                        .font(quickActionBodyFont)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tertiaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var accountProfileSubtitle: String {
        guard isCustomerSignedIn else {
            return AppLocalization.text("sign_in_required", fallback: "Sign in required")
        }

        if accountEmail.isEmpty {
            return accountDisplayName
        }

        return "\(accountDisplayName) · \(accountEmail)"
    }

    private var brewArchiveSubtitle: String {
        let recipeLabel = brewRecipeCount == 1
            ? AppLocalization.text("one_saved_recipe", fallback: "1 saved recipe")
            : String(format: AppLocalization.text("saved_recipes_count", fallback: "%d saved recipes"), brewRecipeCount)
        let journalLabel = journalEntryCount == 1
            ? AppLocalization.text("one_journal_entry", fallback: "1 journal entry")
            : String(format: AppLocalization.text("journal_entries_count", fallback: "%d journal entries"), journalEntryCount)

        return "\(recipeLabel) and \(journalLabel)"
    }

    private func accountDetailScreen(_ detail: AccountDetail) -> some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                activeDetailContent(detail)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(isLightAppearance ? Color(hex: 0xFFFDF9) : Color(hex: 0x181411))
            .navigationTitle(activeDetailTitle(detail))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        presentedDetail = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 32, height: 32)
                            .background(cardFillColor)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(accentColor.opacity(isLightAppearance ? 0.16 : 0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))
                }
            }
        }
    }

    private func activeDetailTitle(_ detail: AccountDetail) -> String {
        switch detail {
        case .personalDetails:
            return AppLocalization.text("personal_details", fallback: "Personal details")
        case .password:
            return AppLocalization.text("password", fallback: "Password")
        case .orders:
            return AppLocalization.text("orders", fallback: "Orders")
        case .addresses:
            return AppLocalization.text("delivery_addresses", fallback: "Delivery addresses")
        case .savedCarts:
            return AppLocalization.text("saved_carts", fallback: "Saved bags")
        case .alerts:
            return AppLocalization.text("back_in_stock_alerts", fallback: "Back-in-stock alerts")
        case .beansBalance:
            return AppLocalization.text("the_talla_club", fallback: "The Talla Club")
        case .rewardProgress:
            return AppLocalization.text("reward_progress", fallback: "Reward progress")
        case .redeemRewards:
            return AppLocalization.text("redeem_rewards", fallback: "Redeem rewards")
        case .appleWallet:
            return AppLocalization.text("apple_wallet", fallback: "Apple Wallet")
        case .favourites:
            return AppLocalization.text("favorites", fallback: "Favourites")
        case .recentlyViewed:
            return AppLocalization.text("recently_viewed", fallback: "Recently viewed")
        case .savedRecipes:
            return AppLocalization.text("saved_recipes", fallback: "Saved recipes")
        case .journalEntries:
            return AppLocalization.text("journal_entries", fallback: "Journal entries")
        case .brewArchive:
            return AppLocalization.text("brew_archive", fallback: "Brew Archive")
        case .support:
            return AppLocalization.text("settings_and_help", fallback: "Settings & Help")
        }
    }

    @ViewBuilder
    private func activeDetailContent(_ detail: AccountDetail) -> some View {
        switch detail {
        case .personalDetails:
            isCustomerSignedIn ? personalDetailsSection : customerAccountSection
        case .password:
            isCustomerSignedIn ? passwordSection : customerAccountSection
        case .orders:
            ordersSection
        case .addresses:
            addressesSection
        case .savedCarts:
            savedCartsSection
        case .alerts:
            alertsSection
        case .beansBalance, .rewardProgress, .redeemRewards, .appleWallet:
            loyaltySection
        case .favourites:
            favoritesSection
        case .recentlyViewed:
            recentlyViewedSection
        case .savedRecipes:
            savedRecipesSection
        case .journalEntries:
            journalSection
        case .brewArchive:
            VStack(alignment: .leading, spacing: 28) {
                savedRecipesSection
                Rectangle()
                    .fill(accentColor.opacity(isLightAppearance ? 0.12 : 0.08))
                    .frame(height: 1)
                journalSection
            }
        case .support:
            supportSection
        }
    }

    private func expandBackingSection(for detail: AccountDetail) {
        switch detail {
        case .personalDetails, .password, .orders:
            isCustomerSectionExpanded = true
        case .addresses, .savedCarts, .alerts:
            isLibrarySectionExpanded = true
        case .beansBalance, .rewardProgress, .redeemRewards, .appleWallet:
            isLoyaltySectionExpanded = true
        case .favourites, .recentlyViewed:
            isShoppingSectionExpanded = true
        case .savedRecipes, .journalEntries, .brewArchive:
            isBrewingSectionExpanded = true
        case .support:
            isSupportSectionExpanded = true
        }
    }

    private var accountQuickActions: some View {
        LazyVGrid(columns: accountQuickActionColumns, spacing: 10) {
            accountQuickChip(
                title: AppLocalization.text("orders", fallback: "Orders"),
                detail: orderCount == 0
                    ? AppLocalization.text("no_orders_short", fallback: "No orders")
                    : "\(orderCount) saved",
                systemImage: "shippingbox.fill",
                action: {
                    presentedDetail = .orders
                    isCustomerSectionExpanded = true
                    openOrdersAction()
                }
            )

            accountQuickChip(
                title: AppLocalization.text("loyalty", fallback: "Rewards"),
                detail: "\(beansBalance) Beans",
                systemImage: "sparkles",
                action: {
                    presentedDetail = .beansBalance
                    isLoyaltySectionExpanded = true
                }
            )

            accountQuickChip(
                title: AppLocalization.text("addresses", fallback: "Addresses"),
                detail: addressesCount == 0
                    ? AppLocalization.text("delivery_setup_empty", fallback: "Add address")
                    : "\(addressesCount) saved",
                systemImage: "location.fill",
                action: {
                    presentedDetail = .addresses
                    isLibrarySectionExpanded = true
                }
            )

            accountQuickChip(
                title: AppLocalization.text("saved", fallback: "Saved"),
                detail: "\(favoriteCount) picks",
                systemImage: "heart.fill",
                action: {
                    presentedDetail = .favourites
                    isShoppingSectionExpanded = true
                }
            )
        }
    }

    private var accountQuickActionColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 10), count: count)
    }

    private func accountQuickChip(
        title: String,
        detail: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 28, height: 28)
                    .background(accentColor.opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(quickActionTitleFont)
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)

                    Text(detail)
                        .font(quickActionBodyFont)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func accountCollectionSection(
        title: String,
        subtitle: String,
        isExpanded: Binding<Bool>,
        content: AnyView
    ) -> some View {
        CollapsibleSectionCard(
            title: title,
            subtitle: subtitle,
            isExpanded: isExpanded,
            titleFont: sectionTitleFont,
            subtitleFont: sectionBodyFont,
            titleColor: primaryTextColor,
            subtitleColor: secondaryTextColor,
            accentColor: accentColor,
            backgroundColor: cardFillColor,
            strokeColor: accentColor.opacity(isLightAppearance ? 0.14 : 0.08)
        ) {
            content
        }
    }

    private func accountCountDetail(
        count: Int,
        singularKey: String,
        singularFallback: String,
        pluralKey: String,
        pluralFallback: String
    ) -> String {
        if count == 1 {
            return AppLocalization.text(singularKey, fallback: singularFallback)
        }

        return AppLocalization.text(pluralKey, fallback: pluralFallback.replacingOccurrences(of: "\(count)", with: String(count)))
            .replacingOccurrences(of: "%d", with: String(count))
    }
}
