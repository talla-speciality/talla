import SwiftUI

struct AccountSectionView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
    let addressesCount: Int
    let favoriteCount: Int
    let brewRecipeCount: Int
    @Binding var isCustomerSectionExpanded: Bool
    @Binding var isLoyaltySectionExpanded: Bool
    @Binding var isLibrarySectionExpanded: Bool
    @Binding var isShoppingSectionExpanded: Bool
    @Binding var isBrewingSectionExpanded: Bool
    @Binding var isSupportSectionExpanded: Bool
    let openRewardsAction: () -> Void
    let openDeliveryAction: () -> Void
    let openSavedPicksAction: () -> Void
    let openBrewArchiveAction: () -> Void
    let openSupportAction: () -> Void
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
            accountCollectionSection(
                title: AppLocalization.text("talla_account", fallback: "Talla Account"),
                subtitle: AppLocalization.text("talla_account_detail", fallback: "Your Talla account connects checkout, rewards, and saved details in one place."),
                isExpanded: $isCustomerSectionExpanded,
                content: customerAccountSection
            )
            .id(ScrollTarget.customer)
            accountCollectionSection(
                title: "TALLA RESERVE",
                subtitle: AppLocalization.text("reserve_copy", fallback: "Use your order email to unlock Beans, rewards, and Reserve perks in one place."),
                isExpanded: $isLoyaltySectionExpanded,
                content: loyaltySection
            )
            .id(ScrollTarget.loyalty)

            accountCollectionSection(
                title: AppLocalization.text("delivery_reminders", fallback: "Delivery & Reminders"),
                subtitle: AppLocalization.text("delivery_reminders_subtitle", fallback: "Addresses, back in stock reminders, and saved carts for faster reorders."),
                isExpanded: $isLibrarySectionExpanded,
                content: librarySection
            )
            .id(ScrollTarget.library)
            accountCollectionSection(
                title: AppLocalization.text("settings_help", fallback: "Settings & Help"),
                subtitle: AppLocalization.text("settings_help_subtitle", fallback: "Quick references and account tools when you need them."),
                isExpanded: $isSupportSectionExpanded,
                content: supportSection
            )
            .id(ScrollTarget.support)
        }
    }

    private var accountQuickActions: some View {
        LazyVGrid(columns: accountQuickActionColumns, spacing: 10) {
            accountQuickChip(
                title: AppLocalization.text("loyalty", fallback: "Rewards"),
                detail: AppLocalization.text("open_rewards", fallback: "Open Rewards"),
                systemImage: "sparkles",
                action: openRewardsAction
            )

            accountQuickChip(
                title: AppLocalization.text("delivery_setup", fallback: "Delivery"),
                detail: addressesCount == 0
                    ? AppLocalization.text("delivery_setup_empty", fallback: "Add address")
                    : "\(addressesCount) saved",
                systemImage: "location.fill",
                action: openDeliveryAction
            )

            accountQuickChip(
                title: AppLocalization.text("settings_help_short", fallback: "Help"),
                detail: AppLocalization.text("account_tools", fallback: "Tools"),
                systemImage: "questionmark.circle.fill",
                action: openSupportAction
            )
        }
    }

    private var accountQuickActionColumns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
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
