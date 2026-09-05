import SwiftUI

struct LoyaltySectionView: View {
    @State private var isRewardsCatalogPresented = false

    let isCompact: Bool
    let isLightAppearance: Bool
    let isOLEDAppearance: Bool
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
        VStack(alignment: .leading, spacing: 16) {
            if isCustomerSignedIn {
                rewardsConnectedCard
            } else {
                loyaltyLookupCard

                if !savedLoyaltyEmail.isEmpty {
                    loyaltyBenefit(title: AppLocalization.text("rewards_email_connected", fallback: "Rewards email connected"), detail: savedLoyaltyEmail)
                }
            }

            if let loyaltyAccount {
                compactClubCard(account: loyaltyAccount)

                VStack(alignment: .leading, spacing: 20) {
                    expiringRewardsSection

                    Rectangle()
                        .fill(accentColor.opacity(isLightAppearance ? 0.12 : 0.08))
                        .frame(height: 1)

                    transactionsSection
                }
                .padding(18)
                .background(cardFillColor)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
        .sheet(isPresented: $isRewardsCatalogPresented) {
            rewardsCatalogScreen
        }
    }

    private func compactClubCard(account: ContentView.LoyaltyAccount) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text("\(account.pointsBalance)")
                            .font(Font.custom("CormorantGaramond-SemiBold", size: isCompact ? 52 : 60))
                            .foregroundColor(primaryTextColor)

                        Text(AppLocalization.text("beans", fallback: "Beans"))
                            .font(Font.custom("AvenirNext-DemiBold", size: 15))
                            .foregroundColor(primaryTextColor.opacity(0.78))
                    }

                    Text(account.tier)
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                }

                Spacer(minLength: 10)

                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(rewardProgress?.remaining ?? 0)")
                        .font(Font.custom("CormorantGaramond-SemiBold", size: 30))
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("until_reward", fallback: "until reward"))
                        .font(Font.custom("AvenirNext-Bold", size: 9))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(secondaryTextColor)
                }
            }

            stampProgressCard(pointsBalance: account.pointsBalance)

            VStack(spacing: 10) {
                Button {
                    isRewardsCatalogPresented = true
                } label: {
                    Label(AppLocalization.text("view_rewards", fallback: "View Rewards"), systemImage: "gift.fill")
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accentColor)
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)

                walletCallToAction
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    accentColor.opacity(isLightAppearance ? 0.13 : 0.18),
                    cardFillColor,
                    cardFillColor
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.20 : 0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var nextRewardLabel: String {
        guard let rewardProgress else {
            return AppLocalization.text("next_reward", fallback: "Next reward")
        }

        if rewardProgress.fraction >= 0.999 {
            return AppLocalization.text("reward_ready", fallback: "Reward ready")
        }

        return String(
            format: AppLocalization.text("beans_until_next_reward", fallback: "%d Beans until your next reward"),
            rewardProgress.remaining
        )
    }

    private func stampProgressCard(pointsBalance: Int) -> some View {
        let cyclePoints = max(pointsBalance, 0) % 300
        let currentPoints = cyclePoints == 0 && pointsBalance > 0 ? 300 : cyclePoints
        let filledCount = min(max(currentPoints / 50, 0), 6)
        let bottlesLeft = max(6 - filledCount, 0)

        return VStack(spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    productStamp(isEarned: index < filledCount)
                }
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accentColor)

                Text(AppLocalization.text("loyalty_bottle_value", fallback: "Every 50 Beans fills one bottle and unlocks a drink of your choice."))
                    .font(Font.custom("AvenirNext-Medium", size: 12))
                    .foregroundColor(secondaryTextColor)

                Spacer(minLength: 8)

                Text(filledCount == 6
                    ? AppLocalization.text("complete", fallback: "Complete")
                    : String(format: AppLocalization.text("loyalty_bottles_left", fallback: "%d left"), bottlesLeft))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .foregroundColor(primaryTextColor)
            }
        }
        .padding(.top, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(
                format: AppLocalization.text("loyalty_bottle_progress_accessibility", fallback: "%d of 6 bottles filled. Every filled bottle unlocks a drink of your choice."),
                filledCount
            )
        )
    }

    private func productStamp(isEarned: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cardFillColor.opacity(isEarned ? 1 : 0.42))

            Image(isEarned ? "LoyaltyBottleFull" : "LoyaltyBottleEmpty")
                .resizable()
                .interpolation(.high)
                .antialiased(true)
                .scaledToFit()
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
        }
        .frame(height: isCompact ? 58 : 68)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .opacity(isEarned ? 1 : 0.48)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(isEarned ? 0.38 : 0.12), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            if isEarned {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(cardFillColor, accentColor)
                    .padding(5)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isEarned)
    }

    private var coffeeBeanFallback: some View {
        ZStack {
            accentColor.opacity(0.10)

            Image(systemName: "leaf.fill")
                .font(.system(size: 23, weight: .semibold))
                .rotationEffect(.degrees(38))
                .foregroundColor(accentColor)
        }
    }

    private var rewardsCatalogScreen: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                rewardsActionsSection
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(isLightAppearance ? Color(hex: 0xFFFDF9) : (isOLEDAppearance ? .black : Color(hex: 0x181411)))
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
                    .tallaGlassCapsule(tint: accentColor)
            }
            .buttonStyle(.plain)
            .disabled(isLoadingLoyalty || loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            if !savedLoyaltyEmail.isEmpty {
                Button(action: signOutAction) {
                    Text(AppLocalization.text("disconnect_rewards", fallback: "DISCONNECT REWARDS"))
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
                .frame(width: 32, height: 32)
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
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(accentColor.opacity(isLightAppearance ? 0.08 : 0.12))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
