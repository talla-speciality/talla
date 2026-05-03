import SwiftUI

struct AccountSectionView: View {
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
    let addressesCount: Int
    let favoriteCount: Int
    let brewRecipeCount: Int
    @Binding var isLibrarySectionExpanded: Bool
    @Binding var isShoppingSectionExpanded: Bool
    @Binding var isBrewingSectionExpanded: Bool
    @Binding var isSupportSectionExpanded: Bool
    let openRewardsAction: () -> Void
    let openDeliveryAction: () -> Void
    let openSavedPicksAction: () -> Void
    let openBrewArchiveAction: () -> Void
    let customerAccountSection: AnyView
    let loyaltySection: AnyView
    let librarySection: AnyView
    let shoppingSection: AnyView
    let brewingSection: AnyView
    let supportSection: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppLocalization.text("customer", fallback: "Customer"))
                    .font(labelFont)
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Text(AppLocalization.text("account_heading", fallback: "ACCOUNT"))
                    .font(titleFont)
                    .tracking(1)
                    .foregroundColor(primaryTextColor)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text(AppLocalization.text("account_intro", fallback: "Manage your customer sign-in, review rewards, and keep your coffee membership in one place."))
                    .font(introFont)
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(AppLocalization.text("account_sync_hint", fallback: "Keep the same email across checkout and rewards so everything stays in sync."))
                    .font(bodyFont)
                    .foregroundColor(tertiaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            accountQuickActions
            customerAccountSection
            loyaltySection

            accountCollectionSection(
                title: AppLocalization.text("library_delivery", fallback: "Library & Delivery"),
                subtitle: AppLocalization.text("library_delivery_subtitle", fallback: "Addresses, alerts, and saved carts for faster reorders."),
                isExpanded: $isLibrarySectionExpanded,
                content: librarySection
            )
            accountCollectionSection(
                title: AppLocalization.text("shopping_discovery", fallback: "Shopping & Discovery"),
                subtitle: AppLocalization.text("shopping_discovery_subtitle", fallback: "Favorites, recently viewed items, and recommendations."),
                isExpanded: $isShoppingSectionExpanded,
                content: shoppingSection
            )
            accountCollectionSection(
                title: AppLocalization.text("brewing_archive", fallback: "Brewing Archive"),
                subtitle: AppLocalization.text("brewing_archive_subtitle", fallback: "Keep your saved brew recipes close at hand."),
                isExpanded: $isBrewingSectionExpanded,
                content: brewingSection
            )
            accountCollectionSection(
                title: AppLocalization.text("support_tools", fallback: "Support & Account Tools"),
                subtitle: AppLocalization.text("support_tools_subtitle", fallback: "Quick references and help links when you need them."),
                isExpanded: $isSupportSectionExpanded,
                content: supportSection
            )
        }
    }

    private var accountQuickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ActionTileView(
                title: AppLocalization.text("open_rewards", fallback: "Open Rewards"),
                detail: AppLocalization.text("open_rewards_detail", fallback: "Review points and redeem available rewards."),
                systemImage: "sparkles",
                titleFont: quickActionTitleFont,
                detailFont: quickActionBodyFont,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                accentColor: accentColor,
                backgroundColor: cardFillColor,
                strokeColor: accentColor.opacity(isLightAppearance ? 0.14 : 0.08),
                minHeight: 126,
                action: openRewardsAction
            )

            ActionTileView(
                title: AppLocalization.text("delivery_setup", fallback: "Delivery Setup"),
                detail: addressesCount == 0
                    ? AppLocalization.text("delivery_setup_empty", fallback: "Add your first address.")
                    : accountCountDetail(
                        count: addressesCount,
                        singularKey: "address_saved_singular",
                        singularFallback: "1 address saved.",
                        pluralKey: "address_saved_plural",
                        pluralFallback: "\(addressesCount) addresses saved."
                    ),
                systemImage: "location.fill",
                titleFont: quickActionTitleFont,
                detailFont: quickActionBodyFont,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                accentColor: accentColor,
                backgroundColor: cardFillColor,
                strokeColor: accentColor.opacity(isLightAppearance ? 0.14 : 0.08),
                minHeight: 126,
                action: openDeliveryAction
            )

            ActionTileView(
                title: AppLocalization.text("saved_picks", fallback: "Saved Picks"),
                detail: favoriteCount == 0
                    ? AppLocalization.text("saved_picks_empty", fallback: "Start building your favorites.")
                    : accountCountDetail(
                        count: favoriteCount,
                        singularKey: "favorite_saved_singular",
                        singularFallback: "1 favorite saved.",
                        pluralKey: "favorite_saved_plural",
                        pluralFallback: "\(favoriteCount) favorites saved."
                    ),
                systemImage: "heart.fill",
                titleFont: quickActionTitleFont,
                detailFont: quickActionBodyFont,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                accentColor: accentColor,
                backgroundColor: cardFillColor,
                strokeColor: accentColor.opacity(isLightAppearance ? 0.14 : 0.08),
                minHeight: 126,
                action: openSavedPicksAction
            )

            ActionTileView(
                title: AppLocalization.text("brew_archive", fallback: "Brew Archive"),
                detail: brewRecipeCount == 0
                    ? AppLocalization.text("brew_archive_empty", fallback: "Keep recipes for later.")
                    : accountCountDetail(
                        count: brewRecipeCount,
                        singularKey: "recipe_saved_singular",
                        singularFallback: "1 recipe saved.",
                        pluralKey: "recipe_saved_plural",
                        pluralFallback: "\(brewRecipeCount) recipes saved."
                    ),
                systemImage: "book.closed.fill",
                titleFont: quickActionTitleFont,
                detailFont: quickActionBodyFont,
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                accentColor: accentColor,
                backgroundColor: cardFillColor,
                strokeColor: accentColor.opacity(isLightAppearance ? 0.14 : 0.08),
                minHeight: 126,
                action: openBrewArchiveAction
            )
        }
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
