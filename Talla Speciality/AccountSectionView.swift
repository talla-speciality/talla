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
                Text("Customer")
                    .font(labelFont)
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Text("ACCOUNT")
                    .font(titleFont)
                    .tracking(1)
                    .foregroundColor(primaryTextColor)
            }

            VStack(alignment: .leading, spacing: 14) {
                Text("Manage your customer sign-in, review rewards, and keep your coffee membership in one place.")
                    .font(introFont)
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Keep the same email across checkout and rewards so everything stays in sync.")
                    .font(bodyFont)
                    .foregroundColor(tertiaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            accountQuickActions
            customerAccountSection
            loyaltySection

            accountCollectionSection(
                title: "Library & Delivery",
                subtitle: "Addresses, alerts, and saved carts for faster reorders.",
                isExpanded: $isLibrarySectionExpanded,
                content: librarySection
            )
            accountCollectionSection(
                title: "Shopping & Discovery",
                subtitle: "Favorites, recently viewed items, and recommendations.",
                isExpanded: $isShoppingSectionExpanded,
                content: shoppingSection
            )
            accountCollectionSection(
                title: "Brewing Archive",
                subtitle: "Keep your saved brew recipes close at hand.",
                isExpanded: $isBrewingSectionExpanded,
                content: brewingSection
            )
            accountCollectionSection(
                title: "Support & Account Tools",
                subtitle: "Quick references and help links when you need them.",
                isExpanded: $isSupportSectionExpanded,
                content: supportSection
            )
        }
    }

    private var accountQuickActions: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ActionTileView(
                title: "Open Rewards",
                detail: "Review points and redeem available rewards.",
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
                title: "Delivery Setup",
                detail: addressesCount == 0 ? "Add your first address." : "\(addressesCount) addresses saved.",
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
                title: "Saved Picks",
                detail: favoriteCount == 0 ? "Start building your favorites." : "\(favoriteCount) favorites saved.",
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
                title: "Brew Archive",
                detail: brewRecipeCount == 0 ? "Keep recipes for later." : "\(brewRecipeCount) recipes saved.",
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
            titleFont: Font.custom("CormorantGaramond-SemiBold", size: 22),
            subtitleFont: Font.custom("AvenirNext-Regular", size: 14),
            titleColor: primaryTextColor,
            subtitleColor: secondaryTextColor,
            accentColor: accentColor,
            backgroundColor: cardFillColor,
            strokeColor: accentColor.opacity(isLightAppearance ? 0.14 : 0.08)
        ) {
            content
        }
    }
}
