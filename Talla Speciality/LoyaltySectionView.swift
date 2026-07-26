import SwiftUI

struct LoyaltySectionView: View {
    @State private var isRewardsCatalogPresented = false

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
    let isCustomerSignedIn: Bool
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
            Text(AppLocalization.text("loyalty", fallback: "Loyalty"))
                .font(labelFont)
                .tracking(4)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            if isCustomerSignedIn {
                rewardsConnectedCard
            } else {
                loyaltyLookupCard

                if !savedLoyaltyEmail.isEmpty {
                    loyaltyBenefit(title: AppLocalization.text("signed_in", fallback: "Signed In"), detail: savedLoyaltyEmail)
                }
            }

            if let loyaltyAccount {
                compactReserveCard(account: loyaltyAccount)

                expiringRewardsSection
                transactionsSection
            }
        }
        .sheet(isPresented: $isRewardsCatalogPresented) {
            rewardsCatalogScreen
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

    private func compactReserveCard(account: ContentView.LoyaltyAccount) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: AppLocalization.text("beans_count", fallback: "%d Beans"), account.pointsBalance))
                        .font(Font.custom("CormorantGaramond-SemiBold", size: isCompact ? 34 : 40))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)

                    Text(account.tier)
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                }

                Spacer(minLength: 10)

                Text(nextRewardLabel)
                    .font(Font.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }

            reserveProgressBar

            HStack(spacing: 10) {
                Button {
                    isRewardsCatalogPresented = true
                } label: {
                    Label(AppLocalization.text("view_rewards", fallback: "View Rewards"), systemImage: "gift.fill")
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accentColor)
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)

                walletCallToAction
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var nextRewardLabel: String {
        guard let rewardProgress else {
            return AppLocalization.text("next_reward", fallback: "Next reward")
        }

        if rewardProgress.remaining == 0 {
            return AppLocalization.text("reward_ready", fallback: "Reward ready")
        }

        return String(
            format: AppLocalization.text("beans_until_next_reward", fallback: "%d Beans until your next reward"),
            rewardProgress.remaining
        )
    }

    private var reserveProgressBar: some View {
        let fraction = rewardProgress?.fraction ?? 0

        return VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(accentColor.opacity(0.12))

                    Capsule()
                        .fill(accentColor)
                        .frame(width: max(geometry.size.width * fraction, 10))
                        .animation(.spring(response: 0.48, dampingFraction: 0.78), value: fraction)
                }
            }
            .frame(height: 9)

            if let rewardProgress {
                HStack {
                    Text(String(format: AppLocalization.text("beans_count", fallback: "%d Beans"), rewardProgress.current))
                    Spacer()
                    Text(String(format: AppLocalization.text("beans_count", fallback: "%d Beans"), rewardProgress.target))
                }
                .font(Font.custom("AvenirNext-Regular", size: 11))
                .foregroundColor(tertiaryTextColor)
            }
        }
    }

    private var rewardsCatalogScreen: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                rewardsActionsSection
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(isLightAppearance ? Color(hex: 0xFFFDF9) : Color(hex: 0x181411))
            .navigationTitle(AppLocalization.text("rewards", fallback: "Rewards"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isRewardsCatalogPresented = false
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

    private var loyaltyLookupCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("lookup_rewards", fallback: "Lookup Rewards"))
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
                Text(isLoadingLoyalty
                    ? AppLocalization.text("checking", fallback: "CHECKING...")
                    : AppLocalization.text("check_rewards", fallback: "CHECK REWARDS"))
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
                    Text(AppLocalization.text("sign_out", fallback: "SIGN OUT"))
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

    private var rewardsConnectedCard: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(accentColor)
                .frame(width: 36, height: 36)
                .background(accentColor.opacity(isLightAppearance ? 0.12 : 0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(AppLocalization.text("rewards_connected", fallback: "Rewards connected"))
                    .font(sectionTitleFont)
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)

                Text(savedLoyaltyEmail)
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }

            Spacer(minLength: 8)

            Button(action: checkRewardsAction) {
                Text(isLoadingLoyalty
                    ? AppLocalization.text("refreshing", fallback: "Refreshing...")
                    : AppLocalization.text("refresh", fallback: "Refresh"))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)
            }
            .buttonStyle(.plain)
            .disabled(isLoadingLoyalty || savedLoyaltyEmail.isEmpty)
        }
        .padding(14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                        .animation(.spring(response: 0.48, dampingFraction: 0.78), value: fraction)
                }
            }
            .frame(height: 10)

            HStack {
                Text(String(format: AppLocalization.text("beans_count", fallback: "%d Beans"), current))
                Spacer()
                Text(String(format: AppLocalization.text("beans_count", fallback: "%d Beans"), target))
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
