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

                Text("ACTIVE")
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
                workspaceBenefit(title: "Customer Email", detail: profile.email)
                workspaceBenefit(title: "Rewards Sync", detail: "Your rewards lookup is now tied to this sign-in.")
                workspaceBenefit(
                    title: "Saved Addresses",
                    detail: addressesCount == 0 ? "Add delivery details for faster checkout." : "\(addressesCount) address\(addressesCount == 1 ? "" : "es") ready to use."
                )
                workspaceBenefit(
                    title: "Recent Orders",
                    detail: orderCount == 0 ? "Your next coffee run will show up here." : "\(orderCount) order\(orderCount == 1 ? "" : "s") available in your history."
                )
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profile Workspace")
                        .font(labelFont)
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    Text("Edit account details, update your password, and review recent orders.")
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(secondaryTextColor)
                }

                Spacer()

                Button(action: signOutAction) {
                    Text("Sign Out")
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
}
