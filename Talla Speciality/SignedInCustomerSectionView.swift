import SwiftUI

struct SignedInCustomerSectionView: View {
    let profile: ContentView.ShopifyCustomerProfile
    let addressesCount: Int
    let orderCount: Int
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let accentColor: Color
    let cardFillColor: Color
    let isLightAppearance: Bool
    let titleFont: Font
    let bodyFont: Font
    let labelFont: Font
    let workspaceColumns: [GridItem]
    let signOutAction: () -> Void
    let profileSection: AnyView
    let passwordSection: AnyView
    let orderHistorySection: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.displayName)
                        .font(titleFont)
                        .foregroundColor(primaryTextColor)

                    Text(profile.email)
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                }

                Spacer()

                Text(AppLocalization.text("active", fallback: "ACTIVE"))
                    .font(labelFont)
                    .tracking(2.4)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            LazyVGrid(columns: workspaceColumns, spacing: 10) {
                workspaceBenefit(title: AppLocalization.text("customer_email", fallback: "Customer Email"), detail: profile.email)
                workspaceBenefit(title: AppLocalization.text("rewards_sync", fallback: "Rewards Sync"), detail: AppLocalization.text("rewards_sync_detail", fallback: "Your rewards lookup is now tied to this sign-in."))
                workspaceBenefit(
                    title: AppLocalization.text("saved_addresses", fallback: "Saved Addresses"),
                    detail: addressesCount == 0
                        ? AppLocalization.text("saved_addresses_empty", fallback: "Add delivery details for faster checkout.")
                        : signedInCountDetail(
                            count: addressesCount,
                            singularKey: "saved_addresses_singular",
                            singularFallback: "1 address ready to use.",
                            pluralKey: "saved_addresses_plural",
                            pluralFallback: "%d addresses ready to use."
                        )
                )
                workspaceBenefit(
                    title: AppLocalization.text("recent_orders", fallback: "Recent Orders"),
                    detail: orderCount == 0
                        ? AppLocalization.text("recent_orders_empty", fallback: "Your next coffee run will show up here.")
                        : signedInCountDetail(
                            count: orderCount,
                            singularKey: "recent_orders_singular",
                            singularFallback: "1 order available in your history.",
                            pluralKey: "recent_orders_plural",
                            pluralFallback: "%d orders available in your history."
                        )
                )
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("profile_workspace", fallback: "Profile Workspace"))
                        .font(labelFont)
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("profile_workspace_detail", fallback: "Edit account details, update your password, and review recent orders."))
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(secondaryTextColor)
                }

                Spacer()

                Button(action: signOutAction) {
                    Text(AppLocalization.text("sign_out", fallback: "Sign Out"))
                        .font(labelFont)
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(secondaryTextColor)
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: workspaceColumns, spacing: 14) {
                workspaceCard(content: profileSection)
                workspaceCard(content: passwordSection)
            }

            workspaceCard(content: orderHistorySection)
        }
    }

    private func workspaceBenefit(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            Text(detail)
                .font(Font.custom("AvenirNext-Regular", size: 13))
                .foregroundColor(primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func workspaceCard(content: AnyView) -> some View {
        SectionCardView(
            backgroundColor: cardFillColor,
            strokeColor: accentColor.opacity(isLightAppearance ? 0.14 : 0.08)
        ) {
            content
        }
    }

    private func signedInCountDetail(
        count: Int,
        singularKey: String,
        singularFallback: String,
        pluralKey: String,
        pluralFallback: String
    ) -> String {
        if count == 1 {
            return AppLocalization.text(singularKey, fallback: singularFallback)
        }

        return String(
            format: AppLocalization.text(pluralKey, fallback: pluralFallback),
            count
        )
    }
}
