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
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 44, height: 44)
                    .background(accentColor.opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.displayName)
                        .font(titleFont)
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(profile.email)
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Label(AppLocalization.text("rewards_connected", fallback: "Rewards connected"), systemImage: "checkmark.circle.fill")
                        .font(labelFont)
                        .tracking(1.3)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                }

                Spacer(minLength: 8)
            }
            .padding(14)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

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
