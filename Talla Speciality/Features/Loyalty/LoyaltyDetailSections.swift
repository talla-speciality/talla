import SwiftUI
#if canImport(PassKit)
import PassKit
#endif

struct LoyaltyRewardsActionsView: View {
    let account: ContentView.LoyaltyAccount
    let configuration: ContentView.AppSettings.Loyalty?
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let cardFillColor: Color
    let accentColor: Color
    let isLightAppearance: Bool
    let isRedeemingReward: Bool
    let redeemAction: (Int, String, String) -> Void

    private struct RewardOption: Identifiable {
        let id: String
        let title: String
        let detail: String
        let points: Int
        let reward: String
    }

    private var rewardOptions: [RewardOption] {
        if let configuration {
            return configuration.rewards.filter { reward in
                reward.enabled && ["free drink", "pastry pairing", "coffee bag credit"].contains(reward.reward.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
            }.map { reward in
                RewardOption(
                    id: reward.id,
                    title: AppLocalization.currentLanguage.effectiveLanguageCode == "ar" ? reward.titleAR : reward.titleEN,
                    detail: AppLocalization.currentLanguage.effectiveLanguageCode == "ar" ? reward.detailAR : reward.detailEN,
                    points: reward.points,
                    reward: reward.reward
                )
            }
        }
        return [
            RewardOption(
                id: "espresso-pour",
                title: AppLocalization.text("reward_espresso_pour", fallback: "Drink of Your Choice"),
                detail: AppLocalization.text("reward_espresso_pour_detail", fallback: "Choose any eligible drink"),
                points: 50,
                reward: "Free Drink"
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("earn_beans", fallback: "Earn Beans"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(AppLocalization.letterSpacing(2))
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            VStack(alignment: .leading, spacing: 8) {
                Text(configuration.map {
                    String(format: AppLocalization.text("earn_beans_rate_dynamic", fallback: "Completed orders earn %.1f Beans for every 1 BHD spent."), $0.pointsPerBHD)
                } ?? AppLocalization.text("earn_beans_rate", fallback: "Completed orders earn 5 Beans for every 1 BHD spent."))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(AppLocalization.letterSpacing(1.3))
                    .foregroundColor(primaryTextColor)

                Text(AppLocalization.text("earn_beans_detail", fallback: "Completed purchases update your rewards balance automatically once they are recorded."))
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(cardFillColor)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(AppLocalization.text("redeem_rewards", fallback: "Redeem Rewards"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(AppLocalization.letterSpacing(2))
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(rewardOptions) { reward in
                    redeemButton(reward)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("CLUB-ONLY OFFERS")
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(AppLocalization.letterSpacing(2))
                    .foregroundColor(accentColor)
                clubOfferCard(title: "Early access", detail: "Taste seasonal coffees before they reach the wider shop.", icon: "clock.badge.checkmark")
                clubOfferCard(title: "Birthday reward", detail: "A little something from Talla during your birthday month.", icon: "birthday.cake.fill")
                clubOfferCard(title: "Free delivery", detail: "Your tier unlocks a lower delivery threshold, up to free delivery at Reserve.", icon: "shippingbox.fill")
                clubOfferCard(title: "Double-Bean brew days", detail: "Watch the Club for selected days where every brew earns twice.", icon: "2.circle.fill")
                clubOfferCard(title: "Across the café", detail: "Visits, referrals, reviews, and events earn in the same Beans balance.", icon: "arrow.triangle.2.circlepath")
            }

            let firstRewardPoints = rewardOptions.map(\.points).min() ?? 50
            Text(account.pointsBalance >= firstRewardPoints
                ? AppLocalization.text("choose_reward_redeem", fallback: "Choose a reward to redeem with your available Beans.")
                : String(format: AppLocalization.text("reach_first_reward_dynamic", fallback: "Reach %d Beans to unlock your first reward."), firstRewardPoints))
                .font(Font.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(tertiaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func redeemButton(_ reward: RewardOption) -> some View {
        let isUnlocked = account.pointsBalance >= reward.points
        let remaining = max(reward.points - account.pointsBalance, 0)

        return Button {
            redeemAction(reward.points, reward.id, reward.title)
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 6) {
                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10, weight: .bold))
                    }

                    Text(reward.title)
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(AppLocalization.letterSpacing(1.6))
                        .textCase(.uppercase)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }

                Text(reward.detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 2)

                Text(isUnlocked
                    ? String(format: AppLocalization.text("beans_count", fallback: "%d Beans"), reward.points)
                    : String(format: AppLocalization.text("beans_remaining_format", fallback: "%d Beans remaining"), remaining))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .foregroundColor(isUnlocked ? Color(hex: 0x151515) : accentColor)
            }
            .foregroundColor(isUnlocked ? Color(hex: 0x151515) : primaryTextColor)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(isUnlocked ? accentColor : cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentColor.opacity(isUnlocked ? 0 : 0.24), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRedeemingReward || !isUnlocked)
    }

    private func clubOfferCard(title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor)
                .frame(width: 34, height: 34)
                .background(accentColor.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Font.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundColor(primaryTextColor)
                Text(detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(cardFillColor)
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
}

struct ExpiringRewardsSectionView: View {
    let vouchers: [ContentView.VoucherRecord]
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let accentColor: Color
    let cardFillColor: Color
    let isLightAppearance: Bool
    let expiryLabel: (ContentView.VoucherRecord) -> String
    let expiresSoon: (ContentView.VoucherRecord) -> Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("expiring_rewards", fallback: "Expiring Rewards"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(AppLocalization.letterSpacing(2))
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            if vouchers.isEmpty {
                Text(AppLocalization.text("expiring_rewards_empty", fallback: "Redeemed rewards will appear here with their expiry window."))
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(secondaryTextColor)
            } else {
                ForEach(vouchers.prefix(3)) { voucher in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(voucher.reward)
                                .font(Font.custom("AvenirNext-Bold", size: 11))
                                .tracking(AppLocalization.letterSpacing(1.5))
                                .textCase(.uppercase)
                                .foregroundColor(primaryTextColor)

                            Spacer()

                            Text(expiryLabel(voucher))
                                .font(Font.custom("AvenirNext-Bold", size: 10))
                                .tracking(AppLocalization.letterSpacing(1.2))
                                .textCase(.uppercase)
                                .foregroundColor(expiresSoon(voucher) ? Color.red.opacity(0.85) : accentColor)
                        }

                        Text(voucher.code)
                            .font(Font.custom("AvenirNext-Regular", size: 12))
                            .foregroundColor(accentColor)

                        Text(voucher.detail)
                            .font(Font.custom("AvenirNext-Regular", size: 12))
                            .foregroundColor(secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .background(cardFillColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }
}

struct LoyaltyTransactionsSectionView: View {
    let account: ContentView.LoyaltyAccount
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let accentColor: Color
    let cardFillColor: Color
    let isLightAppearance: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("recent_activity", fallback: "Recent Activity"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(AppLocalization.letterSpacing(2))
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            if account.transactions.isEmpty {
                Text(AppLocalization.text("no_loyalty_activity", fallback: "No loyalty activity yet."))
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(secondaryTextColor)
            } else {
                ForEach(account.transactions.prefix(4)) { transaction in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color(hex: transaction.type == "redeem" ? 0x8A5E30 : 0x151515))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.note)
                                .font(Font.custom("AvenirNext-Bold", size: 11))
                                .tracking(AppLocalization.letterSpacing(1.5))
                                .foregroundColor(primaryTextColor)

                            if let voucherCode = transaction.voucherCode, !voucherCode.isEmpty {
                                Text("\(AppLocalization.text("voucher", fallback: "Voucher")): \(voucherCode)")
                                    .font(Font.custom("AvenirNext-Bold", size: 10))
                                    .tracking(AppLocalization.letterSpacing(1.2))
                                    .foregroundColor(accentColor)
                            }

                            if let voucherDetail = transaction.voucherDetail, !voucherDetail.isEmpty {
                                Text(voucherDetail)
                                    .font(Font.custom("AvenirNext-Regular", size: 12))
                                    .foregroundColor(secondaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if transaction.voucherCode != nil {
                                let expiryText = transaction.voucherExpiresAt?.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: "") ?? "N/A"
                                let usageText = transaction.voucherSingleUse == false
                                    ? AppLocalization.text("multi_use", fallback: "Multi-use")
                                    : AppLocalization.text("single_use", fallback: "Single use")
                                let statusText = transaction.voucherStatus?.capitalized ?? AppLocalization.text("active", fallback: "Active")

                                Text("\(usageText) • \(AppLocalization.text("expires", fallback: "Expires")) \(expiryText) • \(statusText)")
                                    .font(Font.custom("AvenirNext-Regular", size: 11))
                                    .foregroundColor(tertiaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Text(formattedTransactionDate(transaction.createdAt))
                                .font(Font.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(tertiaryTextColor)
                        }

                        Spacer()

                        Text("\(transaction.type == "redeem" ? "-" : "+")\(transaction.points)")
                            .font(Font.custom("AvenirNext-Bold", size: 12))
                            .foregroundColor(transaction.type == "redeem" ? primaryTextColor : accentColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(cardFillColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }

    private func formattedTransactionDate(_ value: String) -> String {
        if let date = ISO8601DateFormatter().date(from: value) {
            return displayTransactionDate(date)
        }

        let normalized = value
            .replacingOccurrences(of: "T", with: " ")
            .replacingOccurrences(of: "Z", with: "")

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = .current

        for format in ["yyyy-MM-dd HH:mm:ss.SSS", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd"] {
            parser.dateFormat = format
            if let date = parser.date(from: normalized) {
                return displayTransactionDate(date)
            }
        }

        return normalized
    }

    private func displayTransactionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMMM yyyy · h:mm a"
        return formatter.string(from: date)
    }
}

struct LoyaltyWalletCallToActionView: View {
    let isLoadingWalletPass: Bool
    let isWalletPassAdded: Bool
    let tertiaryTextColor: Color
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if isWalletPassAdded {
                EmptyView()
            } else {
#if canImport(PassKit)
                AddPassToWalletButton(action: action)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .addPassToWalletButtonStyle(.black)
#else
                Button(action: action) {
                    Text(isLoadingWalletPass
                        ? AppLocalization.text("loading_wallet_pass", fallback: "LOADING WALLET PASS...")
                        : AppLocalization.text("add_to_apple_wallet", fallback: "ADD TO APPLE WALLET"))
                        .font(Font.custom("AvenirNext-Bold", size: 12))
                        .tracking(AppLocalization.letterSpacing(2.5))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.black)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
#endif
            }

        }
    }
}

struct ClubSectionView: View {
    private enum ClubArea: String, CaseIterable, Identifiable {
        case overview, subscriptions, rewards, coffeeClub, coffeeSchool, appIcon
        var id: String { rawValue }

        var title: String {
            switch self {
            case .overview: return "Overview"
            case .subscriptions: return "Subscriptions"
            case .rewards: return "Rewards"
            case .coffeeClub: return "Coffee Club"
            case .coffeeSchool: return "Coffee School"
            case .appIcon: return "App Icon"
            }
        }
    }

    let rewardsContent: AnyView
    let coffeeSchoolContent: AnyView
    let appIconContent: AnyView
    let beansBalance: Int
    let membershipTier: String
    let isCustomerSignedIn: Bool
    let coffeeClubEnabled: Bool
    let coffeeClubShipmentCount: Int
    let coffeeClubIntervalWeeks: Int
    let coffeeClubDiscountPercent: Int
    let subscriptionPlans: [ContentView.AppSettings.CoffeeClub.Plan]?
    let coffeeClubProducts: [ContentView.Product]
    let memberName: String
    let coffeeClubOrders: [ContentView.AccountOrder]
    let seasonalEvents: [ContentView.EventSettings.SeasonalEvent]
    let savedRecipeCount: Int
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let cardFillColor: Color
    let accentColor: Color
    let pageBackgroundColor: Color
    let isLightAppearance: Bool
    let openCoffeeClubAction: () -> Void
    let openShopCategoryAction: (String) -> Void
    let openSubscriptionPlanAction: (String, String) -> Void
    let addCoffeeToClubAction: (ContentView.Product, ContentView.Product.Variant, Int, TallaFulfillmentMethod) -> Void
    @State private var selectedClubArea: ClubArea = .overview
    @State private var configuredCoffee: ContentView.Product?
    @State private var configuredVariantID = ""
    @State private var configuredQuantity = 1
    @State private var configuredFulfillment: TallaFulfillmentMethod = .delivery

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            clubWelcomeHeader

            clubNavigation

            clubAreaContent
        }
        .sheet(item: $configuredCoffee) { product in
            coffeeClubConfigureSheet(product: product)
        }
    }

    private var clubNavigation: some View {
        Menu {
            ForEach(ClubArea.allCases) { area in
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        selectedClubArea = area
                    }
                } label: {
                    if selectedClubArea == area {
                        Label(area.title, systemImage: "checkmark")
                    } else {
                        Text(area.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 9) {
                Text(selectedClubArea.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(primaryTextColor)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(accentColor)
            }
            .padding(.horizontal, 14)
            .frame(width: 220, height: 42)
            .background(cardFillColor, in: Capsule())
            .overlay(Capsule().stroke(accentColor.opacity(0.18), lineWidth: 1))
        }
        .accessibilityIdentifier("club.sectionPicker")
    }

    @ViewBuilder
    private var clubAreaContent: some View {
        switch selectedClubArea {
        case .overview:
            VStack(alignment: .leading, spacing: 14) {
                membershipDashboard
                ForYourRitualCard(
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    cardFillColor: cardFillColor,
                    accentColor: accentColor
                )
            }
        case .subscriptions:
            subscriptionsDetail
                .padding(.top, 2)
        case .rewards:
            VStack(alignment: .leading, spacing: 14) {
                rewardsContent
                clubExclusives
            }
            .padding(.top, 2)
        case .coffeeClub:
            coffeeClubDetail
                .padding(.top, 2)
        case .coffeeSchool:
            coffeeSchoolContent
                .padding(.top, 2)
        case .appIcon:
            appIconContent
                .padding(.top, 2)
        }
    }

    private var clubWelcomeHeader: some View {
        HStack(alignment: .center, spacing: 13) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(accentColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text("THE TALLA CLUB")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.0)
                    .foregroundColor(accentColor)
                Text(isCustomerSignedIn ? "Welcome back, \(memberName)." : "Your coffee ritual, in one place.")
                    .font(.system(size: 22, weight: .semibold, design: .serif))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                Text("\(beansBalance)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(primaryTextColor)
                Text("BEANS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(secondaryTextColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(accentColor.opacity(0.18), lineWidth: 1))
    }

    private var coffeeClubOverviewCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("COFFEE CLUB")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.0)
                        .foregroundColor(Color(hex: 0xEFD6AF))
                    Text(coffeeClubEnabled ? "Your next bag is already\nwithin reach." : "Coffee Club is\ncoming soon.")
                        .font(.system(size: 27, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.10), in: Circle())
            }

            Text(coffeeClubEnabled
                 ? "Choose your coffee once, then enjoy a considered delivery every few weeks — prepaid and without auto-renewal."
                 : "A considered subscription for your daily ritual.")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 7) {
                overviewClubFact("\(coffeeClubShipmentCount) bags", icon: "shippingbox")
                overviewClubFact("Every \(coffeeClubIntervalWeeks) weeks", icon: "calendar")
                overviewClubFact("\(coffeeClubDiscountPercent)% saving", icon: "percent")
            }

            Button(coffeeClubEnabled ? "EXPLORE COFFEE CLUB" : "LEARN MORE") {
                selectedClubArea = .coffeeClub
            }
            .clubPrimaryButton(accent: Color(hex: 0x151515))
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Color(hex: 0x151515), Color(hex: 0x56331C)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func overviewClubFact(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(Color.white.opacity(0.82))
            .lineLimit(1)
            .padding(.horizontal, 9)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.09), in: Capsule())
    }

    private var overviewSnapshot: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("YOUR SNAPSHOT")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.0)
                    .foregroundColor(accentColor)
                Spacer()
                Text(membershipTier.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(secondaryTextColor)
            }
            HStack(spacing: 9) {
                overviewMetric(value: "\(beansBalance)", label: "BEANS", icon: "sparkles")
                overviewMetric(value: "\(savedRecipeCount)", label: "RECIPES", icon: "book.closed.fill")
                overviewMetric(value: coffeeClubOrders.isEmpty ? "—" : "Active", label: "COFFEE CLUB", icon: "shippingbox.fill")
            }
            Button(isCustomerSignedIn ? "VIEW REWARDS" : "OPEN REWARDS") {
                selectedClubArea = .rewards
            }
            .clubSecondaryButton(accent: accentColor, foreground: primaryTextColor)
        }
        .padding(18)
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(accentColor.opacity(0.16), lineWidth: 1))
    }

    private func overviewMetric(value: String, label: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(accentColor)
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(primaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(label)
                .font(.system(size: 8, weight: .bold))
                .tracking(1.1)
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var overviewShortcuts: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text("KEEP EXPLORING")
                .font(.system(size: 10, weight: .bold))
                .tracking(2.0)
                .foregroundColor(accentColor)
            HStack(spacing: 9) {
                overviewShortcut(title: "Coffee School", detail: "Learn your next brew", icon: "drop.fill") {
                    selectedClubArea = .coffeeSchool
                }
                overviewShortcut(title: "App Icon", detail: "Make Talla yours", icon: "app.gift.fill") {
                    selectedClubArea = .appIcon
                }
            }
        }
    }

    private func overviewShortcut(title: String, detail: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(accentColor)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(primaryTextColor)
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
            .padding(13)
            .background(cardFillColor, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(accentColor.opacity(0.15), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var membershipDashboard: some View {
        let nextRewardTarget = max(50, ((beansBalance / 50) + 1) * 50)
        let rewardProgress = min(Double(beansBalance % 50) / 50.0, 1)
        let activeOrder = coffeeClubOrders.first(where: { order in
            guard let club = order.details?.coffeeClub else { return false }
            return club.lifecycleStatus == "active" || club.lifecycleStatus == "paused"
        })

        return VStack(alignment: .leading, spacing: 13) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("YOUR CLUB")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.8)
                        .foregroundColor(accentColor)
                    Text("A little closer to your next cup.")
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundColor(primaryTextColor)
                }
                Spacer()
                Text("\(beansBalance)")
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .foregroundColor(primaryTextColor)
                Text("BEANS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(1)
                    .foregroundColor(secondaryTextColor)
            }

            HStack(spacing: 8) {
                Text("Next reward")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(secondaryTextColor)
                Spacer()
                Text("\(beansBalance) / \(nextRewardTarget)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(accentColor)
            }
            ProgressView(value: rewardProgress == 0 && beansBalance > 0 ? 0.02 : rewardProgress)
                .tint(accentColor)

            if let club = activeOrder?.details?.coffeeClub {
                HStack(spacing: 9) {
                    Image(systemName: "shippingbox.fill")
                        .foregroundColor(accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(club.preference?.coffeeName ?? "Coffee Club delivery")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(primaryTextColor)
                        Text(club.nextShipmentAt.map { formattedClubDate($0) } ?? "\(club.remainingCount) deliveries remaining")
                            .font(.system(size: 11))
                            .foregroundColor(secondaryTextColor)
                    }
                    Spacer()
                    Text(club.lifecycleStatus.capitalized)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(accentColor)
                }
                .padding(11)
                .background(accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            Button("OPEN REWARDS") { selectedClubArea = .rewards }
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundColor(primaryTextColor)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(accentColor.opacity(0.13), in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(16)
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 21, style: .continuous).stroke(accentColor.opacity(0.16), lineWidth: 1))
    }

    private func dashboardStat(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 8, weight: .bold)).tracking(1.2).foregroundColor(secondaryTextColor)
                Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(primaryTextColor).lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(accentColor.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func dashboardPreferenceChip(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(primaryTextColor)
            .lineLimit(1)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(cardFillColor, in: Capsule())
            .overlay(Capsule().stroke(accentColor.opacity(0.14), lineWidth: 1))
    }

    private func formattedClubDate(_ value: String) -> String {
        let parser = ISO8601DateFormatter()
        if let date = parser.date(from: value) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, d MMM · h:mm a"
            return formatter.string(from: date)
        }
        return value.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: "")
    }

    private var clubExclusives: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("CLUB EXCLUSIVES")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.1)
                        .foregroundColor(accentColor)
                    Text("More to look forward to")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(primaryTextColor)
                }
                Spacer()
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(accentColor)
            }

            if seasonalEvents.isEmpty {
                exclusiveRow(title: "Seasonal coffees", detail: "First taste of limited drops", icon: "leaf.fill")
                exclusiveRow(title: "Member pricing", detail: "Better value on your regulars", icon: "tag.fill")
            } else {
                ForEach(seasonalEvents.prefix(2)) { event in
                    exclusiveRow(title: event.titleEN, detail: event.subtitleEN, icon: event.symbol.isEmpty ? "sparkles" : event.symbol)
                }
            }

            HStack(spacing: 8) {
                exclusivePill("Early access")
                exclusivePill("Tasting events")
                exclusivePill("Limited drops")
            }
        }
        .padding(21)
        .background(
            LinearGradient(colors: [Color(hex: 0xF6E7D3), Color(hex: 0xE8C799)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
    }

    private func exclusiveRow(title: String, detail: String, icon: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: 0x6C431F))
                .frame(width: 34, height: 34)
                .background(Color.white.opacity(0.45), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: 0x151515))
                Text(detail).font(.system(size: 12)).foregroundColor(Color(hex: 0x4A2A16).opacity(0.78))
            }
            Spacer()
        }
    }

    private func exclusivePill(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Color(hex: 0x4A2A16))
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(Color.white.opacity(0.42), in: Capsule())
    }

    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("TALLA REWARDS CLUB")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.1)
                        .foregroundColor(accentColor)
                    Text(isCustomerSignedIn ? "Member wallet" : "Your member wallet")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(primaryTextColor)
                }
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 46, height: 46)
                    .background(accentColor.opacity(0.13), in: Circle())
            }
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(isCustomerSignedIn ? "\(beansBalance)" : "—")
                    .font(.system(size: 52, weight: .bold, design: .serif))
                    .foregroundColor(primaryTextColor)
                Text("BEANS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundColor(secondaryTextColor)
            }
            HStack(spacing: 0) {
                rewardWalletRow(title: "TIER", value: membershipTier)
                Rectangle().fill(accentColor.opacity(0.16)).frame(width: 1, height: 32)
                rewardWalletRow(title: "NEXT REWARD", value: "50 Beans")
            }
            .padding(.vertical, 13)
            .background(accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
            Button(isCustomerSignedIn ? "VIEW REWARDS" : "OPEN REWARDS") {
                selectedClubArea = .rewards
            }
            .clubPrimaryButton(accent: accentColor)
        }
        .padding(21)
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(accentColor.opacity(0.18), lineWidth: 1))
    }

    private func rewardWalletRow(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 8, weight: .bold)).tracking(1.3).foregroundColor(secondaryTextColor)
            Text(value).font(.system(size: 13, weight: .semibold)).foregroundColor(primaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var coffeeClubCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("TALLA COFFEE CLUB")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.1)
                    .foregroundColor(Color(hex: 0xEFD6AF))
                Spacer()
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.white)
            }
            Text(coffeeClubEnabled ? "Your coffee,\non repeat." : "Coffee Club\nis coming soon.")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundColor(.white)
            Text(coffeeClubEnabled
                 ? "A considered subscription for a better daily ritual."
                 : "A considered subscription for your daily ritual.")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.72))
            HStack(spacing: 0) {
                coffeeClubStep(number: "01", title: "CHOOSE")
                coffeeClubStep(number: "02", title: "RECEIVE")
                coffeeClubStep(number: "03", title: "BREW")
            }
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Button("EXPLORE COFFEE CLUB") {
                selectedClubArea = .coffeeClub
            }
            .clubPrimaryButton(accent: Color(hex: 0x151515))
        }
        .padding(22)
        .background(
            LinearGradient(colors: [Color(hex: 0x151515), Color(hex: 0x4A2A16)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
    }

    private func coffeeClubStep(number: String, title: String) -> some View {
        VStack(spacing: 5) {
            Text(number).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(.white)
            Text(title).font(.system(size: 8, weight: .bold)).tracking(1.2).foregroundColor(Color.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
    }

    private var coffeeSchoolCard: some View {
        Button {
            selectedClubArea = .coffeeSchool
        } label: {
            VStack(alignment: .leading, spacing: 17) {
                HStack {
                    Text("COFFEE SCHOOL")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.1)
                    Spacer()
                    Text("START →")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.2)
                }
                .foregroundColor(Color(hex: 0x5D371D))
                Text("Taste more.\nUnderstand more.")
                    .font(.system(size: 31, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: 0x151515))
                    .multilineTextAlignment(.leading)
                Text("A guided path from flavour notes to confident brewing.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: 0x4A2A16).opacity(0.78))
                HStack(spacing: 7) {
                    schoolPathStep(icon: "leaf.fill", title: "TASTE")
                    schoolPathStep(icon: "drop.fill", title: "BREW")
                    schoolPathStep(icon: "checkmark.seal.fill", title: "MASTER")
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xE8CDAA)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 25, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private func schoolPathStep(icon: String, title: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14, weight: .bold))
            Text(title).font(.system(size: 8, weight: .bold)).tracking(1.1)
        }
        .foregroundColor(Color(hex: 0x5D371D))
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color.white.opacity(0.38), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    private func clubCard(eyebrow: String, title: String, detail: String, icon: String, actionTitle: String, emphasis: Bool = false, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(emphasis ? Color(hex: 0xEFD6AF) : accentColor)
                    .frame(width: 44, height: 44)
                    .background(accentColor.opacity(isLightAppearance ? 0.12 : 0.18), in: Circle())
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(emphasis ? Color.white.opacity(0.7) : secondaryTextColor)
            }
            Text(eyebrow)
                .font(.system(size: 10, weight: .bold))
                .tracking(2)
                .foregroundColor(emphasis ? Color(hex: 0xEFD6AF) : accentColor)
            Text(title)
                .font(.system(size: 23, weight: .semibold, design: .serif))
                .foregroundColor(emphasis ? .white : primaryTextColor)
            Text(detail)
                .font(.system(size: 14))
                .foregroundColor(emphasis ? Color.white.opacity(0.72) : secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
            Button(actionTitle, action: action)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(minHeight: 42)
                .background(emphasis ? Color(hex: 0x151515) : accentColor, in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            emphasis
                ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x151515), Color(hex: 0x4A2A16)], startPoint: .topLeading, endPoint: .bottomTrailing))
                : AnyShapeStyle(cardFillColor),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(emphasis ? Color(hex: 0x151515).opacity(0.32) : accentColor.opacity(isLightAppearance ? 0.16 : 0.10), lineWidth: 1))
    }

    private var coffeeClubDetail: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Coffee Club")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundColor(primaryTextColor)
                Spacer()
                Text("PREPAID")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(accentColor)
            }
            Text("Build your next set of deliveries. Pay once; renew when you’re ready.")
                .font(.system(size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 7) {
                clubFact("\(coffeeClubShipmentCount) deliveries", icon: "shippingbox.fill")
                clubFact("Every \(coffeeClubIntervalWeeks) weeks", icon: "calendar")
                clubFact("\(coffeeClubDiscountPercent)% off", icon: "percent")
            }
            Text("PICK YOUR COFFEE")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.8)
                .foregroundColor(accentColor)

            if coffeeClubProducts.isEmpty {
                Text("Eligible products will appear here when the shop is loaded.")
                    .font(.system(size: 14))
                    .foregroundColor(secondaryTextColor)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(coffeeClubProducts) { product in
                            coffeeClubProductCard(product)
                        }
                    }
                }
            }
            if coffeeClubProducts.isEmpty {
                Button("CHOOSE PLAN ITEMS") {
                    selectedClubArea = .overview
                    openCoffeeClubAction()
                }
                .font(.system(size: 12, weight: .bold))
                .tracking(1.6)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .buttonStyle(.plain)
            }
        }
    }

    private var subscriptionsDetail: some View {
        VStack(alignment: .leading, spacing: 25) {
            VStack(alignment: .leading, spacing: 7) {
                Text("SUBSCRIPTIONS")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(2.2)
                    .foregroundColor(accentColor)
                Text("Coffee, on your terms.")
                    .font(.system(size: 30, weight: .medium, design: .serif))
                    .foregroundColor(primaryTextColor)
                Text("A good ritual, made easy to keep.")
                    .font(.system(size: 15))
                    .foregroundColor(secondaryTextColor)
            }

            subscriptionFlexibilityNote

            VStack(alignment: .leading, spacing: 9) {
                subscriptionGroupHeading("AT HOME", detail: "Your coffee shelf, taken care of.")
                VStack(spacing: 0) {
                    subscriptionPlanCards(group: "home")
                }
            }

            VStack(alignment: .leading, spacing: 9) {
                subscriptionGroupHeading("FOR YOUR DAY", detail: "At work or on the way.")
                VStack(spacing: 0) {
                    subscriptionPlanCards(group: "day")
                    if subscriptionPlans?.contains(where: { $0.enabled && $0.group == "day" }) == true {
                        subscriptionRowDivider
                    }
                    subscriptionPlanCard(title: "Daily cup pass", detail: "20 drinks · pickup · valid for 30 days.", icon: "cup.and.saucer", actionTitle: "Choose a drink") {
                        openShopCategoryAction("ready-made-drinks")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func subscriptionPlanCards(group: String) -> some View {
        if let plans = subscriptionPlans {
            let visiblePlans = plans.filter { $0.enabled && $0.group == group }
            ForEach(Array(visiblePlans.enumerated()), id: \.element.id) { index, plan in
                subscriptionPlanCard(
                    title: AppLocalization.currentLanguage.effectiveLanguageCode == "ar" && !plan.titleAR.isEmpty ? plan.titleAR : plan.titleEN,
                    detail: AppLocalization.currentLanguage.effectiveLanguageCode == "ar" && !plan.detailAR.isEmpty ? plan.detailAR : plan.detailEN,
                    icon: plan.icon,
                    actionTitle: coffeeClubEnabled ? subscriptionCTA(for: plan.id) : nil,
                    action: coffeeClubEnabled ? { openSubscriptionPlanAction(plan.id, plan.categoryKey) } : nil
                )
                if index < visiblePlans.count - 1 { subscriptionRowDivider }
            }
        } else if group == "home" {
            subscriptionPlanCard(title: "Bean deliveries", detail: "\(coffeeClubShipmentCount) deliveries · every \(coffeeClubIntervalWeeks) weeks · \(coffeeClubDiscountPercent)% off", icon: "shippingbox", actionTitle: coffeeClubEnabled ? "Choose beans" : nil, action: coffeeClubEnabled ? { openSubscriptionPlanAction("beans", "coffee-beans") } : nil)
            subscriptionRowDivider
            subscriptionPlanCard(title: "Drip bags", detail: "A fresh cup, every week.", icon: "drop", actionTitle: coffeeClubEnabled ? "Choose drip bags" : nil, action: coffeeClubEnabled ? { openSubscriptionPlanAction("drip-bags", "drip-bags") } : nil)
            subscriptionRowDivider
            subscriptionPlanCard(title: "Discovery box", detail: "A new seasonal selection.", icon: "sparkles", actionTitle: coffeeClubEnabled ? "Choose a box" : nil, action: coffeeClubEnabled ? { openSubscriptionPlanAction("seasonal-box", "gifts") } : nil)
            subscriptionRowDivider
            subscriptionPlanCard(title: "Qahwa replenishment", detail: "Arabic coffee, ready when you are.", icon: "flame", actionTitle: coffeeClubEnabled ? "Choose Qahwa" : nil, action: coffeeClubEnabled ? { openSubscriptionPlanAction("arabic-coffee", "arabic-coffee-beans") } : nil)
            subscriptionRowDivider
            subscriptionPlanCard(title: "Machine care", detail: "Cleaning and descaling essentials.", icon: "wrench.and.screwdriver", actionTitle: coffeeClubEnabled ? "Choose supplies" : nil, action: coffeeClubEnabled ? { openSubscriptionPlanAction("equipment", "coffee-equipment") } : nil)
            subscriptionRowDivider
            subscriptionPlanCard(title: "Coffee filters", detail: "V60 · AeroPress · Kalita · Chemex.", icon: "line.3.horizontal.decrease", actionTitle: coffeeClubEnabled ? "Choose filters" : nil, action: coffeeClubEnabled ? { openSubscriptionPlanAction("filters", "coffee-equipment") } : nil)
        } else {
            subscriptionPlanCard(title: "Office coffee", detail: "Multi-bag supply · pickup or Bahrain delivery.", icon: "building.2", actionTitle: coffeeClubEnabled ? "Build a plan" : nil, action: coffeeClubEnabled ? { openSubscriptionPlanAction("office", "coffee-beans") } : nil)
        }
    }

    private func subscriptionCTA(for planID: String) -> String {
        switch planID {
        case "beans": return "Choose beans"
        case "drip-bags": return "Choose drip bags"
        case "seasonal-box": return "Choose a box"
        case "arabic-coffee": return "Choose Qahwa"
        case "equipment": return "Choose supplies"
        case "filters": return "Choose filters"
        case "office": return "Build a plan"
        default: return "Choose plan"
        }
    }

    private var subscriptionFlexibilityNote: some View {
        HStack(spacing: 9) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(accentColor)
            Text("Prepaid, never auto-renews")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(secondaryTextColor)
            Text("·")
                .foregroundColor(tertiaryTextColor)
            Text("Skip · pause · swap")
                .font(.system(size: 12))
                .foregroundColor(secondaryTextColor)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            Rectangle().fill(accentColor.opacity(0.18)).frame(height: 1)
        }
    }

    private var subscriptionRowDivider: some View {
        Rectangle()
            .fill(accentColor.opacity(0.16))
            .frame(height: 1)
            .padding(.leading, 45)
    }

    private func subscriptionGroupHeading(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .tracking(1.8)
                .foregroundColor(accentColor)
            Text(detail)
                .font(.system(size: 13))
                .foregroundColor(secondaryTextColor)
        }
    }

    private func subscriptionPlanCard(
        title: String,
        detail: String,
        icon: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) -> some View {
        Button {
            action?()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(accentColor)
                    .frame(width: 32, height: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium, design: .serif))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                if action != nil {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(accentColor)
                } else {
                    Text("SOON")
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                        .foregroundColor(tertiaryTextColor)
                }
            }
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityLabel("\(title). \(detail). \(actionTitle ?? "Coming soon")")
    }

    private func coffeeClubProductCard(_ product: ContentView.Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if let imageURL = product.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            productPlaceholder
                        }
                    }
                } else {
                    productPlaceholder
                }
            }
            .frame(width: 150, height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(product.name)
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundColor(primaryTextColor)
                .lineLimit(2)
                .frame(width: 150, alignment: .leading)
            Text(product.price)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(secondaryTextColor)
            Button("CHOOSE FOR PLAN") {
                configuredCoffee = product
                configuredVariantID = product.variants.first(where: \.isAvailableForSale)?.id ?? ""
                configuredQuantity = 1
                configuredFulfillment = .delivery
            }
            .font(.system(size: 9, weight: .bold))
            .tracking(1.0)
            .foregroundColor(.white)
            .frame(width: 150)
            .frame(minHeight: 34)
            .background(accentColor, in: Capsule())
            .buttonStyle(.plain)
        }
        .padding(10)
        .frame(width: 170, alignment: .leading)
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(accentColor.opacity(0.16), lineWidth: 1))
    }

    private func coffeeClubConfigureSheet(product: ContentView.Product) -> some View {
        NavigationStack {
            Form {
                Section("Coffee") {
                    Text(product.name)
                        .font(.headline)
                    if product.hasVariantChoices {
                        Picker("Bag size", selection: $configuredVariantID) {
                            ForEach(product.variants.filter(\.isAvailableForSale)) { variant in
                                Text(variant.title).tag(variant.id)
                            }
                        }
                    }
                    Stepper("Quantity · \(configuredQuantity)", value: $configuredQuantity, in: 1...6)
                }

                Section("Fulfilment") {
                    Picker("Receive your coffee", selection: $configuredFulfillment) {
                        Text("Delivery").tag(TallaFulfillmentMethod.delivery)
                        Text("Pickup at Talla").tag(TallaFulfillmentMethod.pickup)
                    }
                    .pickerStyle(.segmented)

                    Text(configuredFulfillment == .pickup
                         ? "Collect from Talla in Riffa when your shipment is ready."
                         : "Delivery is scheduled with your Coffee Club shipments.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button {
                        guard let variant = product.variants.first(where: { $0.id == configuredVariantID && $0.isAvailableForSale }) else { return }
                        addCoffeeToClubAction(product, variant, configuredQuantity, configuredFulfillment)
                        configuredCoffee = nil
                    } label: {
                        Text("ADD TO COFFEE CLUB")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.tallaPrimary)
                    .tint(accentColor)
                }
            }
            .navigationTitle("Customize your bag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { configuredCoffee = nil }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var productPlaceholder: some View {
        ZStack {
            LinearGradient(colors: [accentColor.opacity(0.24), accentColor.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(accentColor)
        }
    }

    private func clubFact(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 14)
            .frame(minHeight: 42)
            .background(cardFillColor, in: Capsule())
            .overlay(Capsule().stroke(accentColor.opacity(0.16), lineWidth: 1))
    }

}

private struct ForYourRitualCard: View {
    @AppStorage(BrewingSectionView.BrewSessionStorage.profileExperienceKey) private var experience = "basics"
    @AppStorage(BrewingSectionView.BrewSessionStorage.profileBrewerKey) private var brewer = "v60"
    @AppStorage(BrewingSectionView.BrewSessionStorage.profileTasteKey) private var taste = "balanced"
    @AppStorage(BrewingSectionView.BrewSessionStorage.lastMethodKey) private var lastMethod = ""

    let primaryTextColor: Color
    let secondaryTextColor: Color
    let cardFillColor: Color
    let accentColor: Color

    private var methodName: String {
        switch lastMethod.lowercased() {
        case "aeropress": return "AeroPress"
        case "frenchpress", "french_press": return "French press"
        case "espresso": return "Espresso"
        case "kalita": return "Kalita Wave"
        case "moka": return "Moka pot"
        default: return brewer == "v60" ? "V60 pour over" : "your saved brew"
        }
    }

    private var tasteLabel: String {
        switch taste.lowercased() {
        case "bright", "fruity": return "bright and fruity"
        case "bold", "strong": return "bold and full-bodied"
        case "sweet": return "sweet and rounded"
        default: return "balanced and clear"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 42, height: 42)
                    .background(accentColor.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("FOR YOUR RITUAL")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.1)
                        .foregroundColor(accentColor)
                    Text("A better next cup")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(primaryTextColor)
                }
                Spacer(minLength: 0)
            }

            Text("Your \(experience == "expert" ? "advanced" : "saved") setup leans \(tasteLabel). Start with \(methodName), then keep one variable steady while you dial it in.")
                .font(.system(size: 15))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                ritualChip(title: methodName, icon: "cup.and.saucer.fill")
                ritualChip(title: tasteLabel.capitalized, icon: "sparkles")
            }
        }
        .padding(21)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(accentColor.opacity(0.18), lineWidth: 1))
    }

    private func ritualChip(title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(primaryTextColor)
            .lineLimit(1)
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(accentColor.opacity(0.09), in: Capsule())
    }
}

private extension View {
    func clubPrimaryButton(accent: Color) -> some View {
        self
            .font(.system(size: 11, weight: .bold))
            .tracking(1.5)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(accent, in: Capsule())
            .buttonStyle(.plain)
    }

    func clubSecondaryButton(accent: Color, foreground: Color) -> some View {
        self
            .font(.system(size: 11, weight: .bold))
            .tracking(1.5)
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 42)
            .background(accent.opacity(0.12), in: Capsule())
            .overlay(Capsule().stroke(accent.opacity(0.22), lineWidth: 1))
            .buttonStyle(.plain)
    }
}
