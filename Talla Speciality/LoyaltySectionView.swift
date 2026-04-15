import SwiftUI

struct LoyaltySectionView: View {
    let isCompact: Bool
    let isLightAppearance: Bool
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let cardFillColor: Color
    let elevatedSurfaceColor: Color
    let accentColor: Color
    let labelFont: Font
    let titleFont: Font
    let bodyFont: Font
    let sectionTitleFont: Font
    let savedLoyaltyEmail: String
    @Binding var loyaltyEmail: String
    let loyaltyError: String?
    let isLoadingLoyalty: Bool
    let loyaltyAccount: ContentView.LoyaltyAccount?
    let loyaltyPerks: [String]
    let rewardProgress: (current: Int, target: Int, remaining: Int, fraction: Double)?
    let tierProgress: (label: String, current: Int, target: Int, remaining: Int, fraction: Double)?
    let checkRewardsAction: () -> Void
    let signOutAction: () -> Void
    let expiringRewardsSection: AnyView
    let rewardsActionsSection: AnyView
    let transactionsSection: AnyView
    let walletCallToAction: AnyView

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Loyalty")
                .font(labelFont)
                .tracking(4)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            VStack(alignment: .leading, spacing: 12) {
                Text("TALLA RESERVE")
                    .font(titleFont)
                    .foregroundColor(primaryTextColor)

                Text("Use your order email to unlock points, rewards, and member perks in one place.")
                    .font(bodyFont)
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            loyaltyLookupCard

            if !savedLoyaltyEmail.isEmpty {
                loyaltyBenefit(title: "Signed In", detail: savedLoyaltyEmail)
            }

            if let loyaltyAccount {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(loyaltyAccount.pointsBalance)")
                            .font(Font.custom("CormorantGaramond-SemiBold", size: isCompact ? 38 : 44))
                            .foregroundColor(primaryTextColor)

                        Text("Points available")
                            .font(Font.custom("AvenirNext-DemiBold", size: 11))
                            .tracking(2.5)
                            .textCase(.uppercase)
                            .foregroundColor(tertiaryTextColor)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text(loyaltyAccount.tier)
                            .font(Font.custom("AvenirNext-Bold", size: 12))
                            .tracking(2.5)
                            .textCase(.uppercase)
                            .foregroundColor(accentColor)

                        Text(loyaltyAccount.nextReward)
                            .font(Font.custom("AvenirNext-Regular", size: 13))
                            .foregroundColor(secondaryTextColor)
                    }
                }

                if let rewardProgress {
                    loyaltyProgressCard(
                        title: "Next Reward",
                        accent: "\(rewardProgress.remaining) points to go",
                        current: rewardProgress.current,
                        target: rewardProgress.target,
                        fraction: rewardProgress.fraction
                    )
                }

                if let tierProgress {
                    loyaltyProgressCard(
                        title: "Tier Progress",
                        accent: tierProgress.remaining == 0
                            ? tierProgress.label
                            : "\(tierProgress.remaining) points to \(tierProgress.label)",
                        current: tierProgress.current,
                        target: tierProgress.target,
                        fraction: tierProgress.fraction
                    )
                }

                expiringRewardsSection
                loyaltyBenefit(title: "Member ID", detail: loyaltyAccount.memberID)
                rewardsActionsSection
                transactionsSection
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(loyaltyPerks, id: \.self) { perk in
                    loyaltyBenefit(title: "Member benefit", detail: perk)
                }
            }

            walletCallToAction

            Text("Completed orders now award 10 points per 1 BHD.")
                .font(Font.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(tertiaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(22)
        .background(elevatedSurfaceColor.opacity(isLightAppearance ? 0.82 : 0.26))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(accentColor.opacity(0.16), lineWidth: 1)
        )
        .glassEffect(
            .regular.tint(Color(hex: 0x8A5E30).opacity(0.18)),
            in: .rect(cornerRadius: 28)
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var loyaltyLookupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lookup Rewards")
                .font(sectionTitleFont)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            TextField("name@email.com", text: $loyaltyEmail)
                .textInputAutocapitalization(.never)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .font(Font.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button(action: checkRewardsAction) {
                Text(isLoadingLoyalty ? "CHECKING..." : "CHECK REWARDS")
                    .font(Font.custom("AvenirNext-Bold", size: 12))
                    .tracking(2.5)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .glassEffect(.regular.tint(accentColor).interactive(), in: .capsule)
            }
            .buttonStyle(.plain)
            .disabled(isLoadingLoyalty || loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if !savedLoyaltyEmail.isEmpty {
                Button(action: signOutAction) {
                    Text("SIGN OUT")
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(secondaryTextColor)
                }
                .buttonStyle(.plain)
            }

            if let loyaltyError {
                Text(loyaltyError)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func loyaltyBenefit(title: String, detail: String) -> some View {
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

    private func loyaltyProgressCard(title: String, accent: String, current: Int, target: Int, fraction: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(sectionTitleFont)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)

                Spacer()

                Text(accent)
                    .font(Font.custom("AvenirNext-DemiBold", size: 11))
                    .foregroundColor(accentColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(accentColor.opacity(0.12))

                    Capsule()
                        .fill(accentColor)
                        .frame(width: max(geometry.size.width * fraction, 12))
                }
            }
            .frame(height: 10)

            HStack {
                Text("\(current) pts")
                Spacer()
                Text("\(target) pts")
            }
            .font(Font.custom("AvenirNext-Regular", size: 12))
            .foregroundColor(tertiaryTextColor)
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
