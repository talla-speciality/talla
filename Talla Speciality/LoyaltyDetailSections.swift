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
    let redeemAction: (Int, String) -> Void

    private struct RewardOption: Identifiable {
        let id: String
        let title: String
        let detail: String
        let points: Int
        let reward: String
    }

    private var rewardOptions: [RewardOption] {
        if let configuration {
            return configuration.rewards.filter { $0.enabled && $0.reward.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "free drink" }.map { reward in
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
                clubOfferCard(title: "Member pricing", detail: "Coffee Club members receive preferred pricing on selected drops.", icon: "tag.fill")
                clubOfferCard(title: "Tasting table", detail: "Get first notice for workshops and guided tasting events.", icon: "person.3.fill")
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
            redeemAction(reward.points, reward.reward)
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
                    .foregroundColor(isUnlocked ? Color(hex: 0x0A0804) : accentColor)
            }
            .foregroundColor(isUnlocked ? Color(hex: 0x0A0804) : primaryTextColor)
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
                            .fill(Color(hex: transaction.type == "redeem" ? 0x8A5E30 : 0xC8965A))
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
        case overview, rewards, coffeeClub, coffeeSchool
        var id: String { rawValue }

        var title: String {
            switch self {
            case .overview: return "Overview"
            case .rewards: return "Rewards"
            case .coffeeClub: return "Coffee Club"
            case .coffeeSchool: return "Coffee School"
            }
        }
    }

    let rewardsContent: AnyView
    let coffeeSchoolContent: AnyView
    let beansBalance: Int
    let membershipTier: String
    let isCustomerSignedIn: Bool
    let coffeeClubEnabled: Bool
    let coffeeClubShipmentCount: Int
    let coffeeClubIntervalWeeks: Int
    let coffeeClubDiscountPercent: Int
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
    let addCoffeeToClubAction: (ContentView.Product, ContentView.Product.Variant, Int, TallaFulfillmentMethod) -> Void
    @State private var selectedClubArea: ClubArea = .overview
    @State private var configuredCoffee: ContentView.Product?
    @State private var configuredVariantID = ""
    @State private var configuredQuantity = 1
    @State private var configuredFulfillment: TallaFulfillmentMethod = .delivery

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            clubHero

            clubNavigation

            Text(selectedClubArea == .overview ? "INSIDE THE CLUB" : selectedClubArea.title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(2.4)
                .foregroundColor(accentColor)

            clubAreaContent
        }
        .sheet(item: $configuredCoffee) { product in
            coffeeClubConfigureSheet(product: product)
        }
    }

    private var clubNavigation: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ClubArea.allCases) { area in
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            selectedClubArea = area
                        }
                    } label: {
                        Text(area.title)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(selectedClubArea == area ? Color(hex: 0x24180E) : secondaryTextColor)
                            .padding(.horizontal, 15)
                            .frame(minHeight: 40)
                            .background(selectedClubArea == area ? accentColor : cardFillColor, in: Capsule())
                            .overlay(Capsule().stroke(accentColor.opacity(selectedClubArea == area ? 0 : 0.18), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private var clubAreaContent: some View {
        switch selectedClubArea {
        case .overview:
            VStack(alignment: .leading, spacing: 16) {
                membershipDashboard
                rewardsCard
                coffeeClubCard
                ForYourRitualCard(
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                    cardFillColor: cardFillColor,
                    accentColor: accentColor
                )
                coffeeSchoolCard
                clubExclusives
            }
        case .rewards:
            rewardsContent
                .padding(.top, 2)
        case .coffeeClub:
            coffeeClubDetail
                .padding(.top, 2)
        case .coffeeSchool:
            coffeeSchoolContent
                .padding(.top, 2)
        }
    }

    private var clubHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("THE TALLA CLUB")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2.5)
                    .foregroundColor(Color(hex: 0x3A2112))
                Spacer()
                Text("EST. 2024")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: 0x3A2112).opacity(0.65))
            }
            Text(isCustomerSignedIn ? "Welcome back, \(memberName)." : "A better coffee ritual, built around you.")
                .font(.system(size: 37, weight: .bold, design: .serif))
                .foregroundColor(Color(hex: 0x24180E))
                .fixedSize(horizontal: false, vertical: true)
            Text("Rewards, curated coffee, and lessons to help you brew with more confidence.")
                .font(.system(size: 15))
                .foregroundColor(Color(hex: 0x4A2A16).opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                clubHeroStat(value: "\(beansBalance)", label: "BEANS")
                clubHeroStat(value: membershipTier.uppercased(), label: "TIER")
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(hex: 0xF2D4A8), Color(hex: 0xD19A5A)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 76, weight: .thin))
                .foregroundColor(Color(hex: 0x6D431F).opacity(0.17))
                .rotationEffect(.degrees(-12))
                .offset(x: 8, y: 10)
        }
    }

    private func clubHeroStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value).font(.system(size: 15, weight: .bold, design: .rounded))
            Text(label).font(.system(size: 8, weight: .bold)).tracking(1.4).opacity(0.65)
        }
        .foregroundColor(Color(hex: 0x24180E))
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.30), in: Capsule())
    }

    private var membershipDashboard: some View {
        let nextRewardTarget = max(50, ((beansBalance / 50) + 1) * 50)
        let rewardProgress = min(Double(beansBalance % 50) / 50.0, 1)
        let activeOrder = coffeeClubOrders.first(where: { order in
            guard let club = order.details?.coffeeClub else { return false }
            return club.lifecycleStatus == "active" || club.lifecycleStatus == "paused"
        })

        return VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("MEMBERSHIP DASHBOARD")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(2.1)
                        .foregroundColor(accentColor)
                    Text("Your coffee, at a glance")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundColor(primaryTextColor)
                }
                Spacer()
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 44, height: 44)
                    .background(accentColor.opacity(0.12), in: Circle())
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Next reward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(primaryTextColor)
                    Spacer()
                    Text("\(beansBalance) / \(nextRewardTarget) Beans")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(accentColor)
                }
                ProgressView(value: rewardProgress == 0 && beansBalance > 0 ? 0.02 : rewardProgress)
                    .tint(accentColor)
                Text(beansBalance >= nextRewardTarget
                     ? "Your next reward is ready to redeem."
                     : "\(max(nextRewardTarget - beansBalance, 0)) Beans to go")
                    .font(.system(size: 12))
                    .foregroundColor(secondaryTextColor)
            }

            HStack(spacing: 8) {
                dashboardStat(
                    title: "CLUB STATUS",
                    value: activeOrder == nil ? "Ready" : (activeOrder?.details?.coffeeClub?.lifecycleStatus.capitalized ?? "Active"),
                    icon: "shippingbox.fill"
                )
                dashboardStat(
                    title: "SAVED RECIPES",
                    value: "\(savedRecipeCount)",
                    icon: "book.closed.fill"
                )
            }

            if let club = activeOrder?.details?.coffeeClub {
                VStack(alignment: .leading, spacing: 8) {
                    Text("UPCOMING DELIVERY")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.7)
                        .foregroundColor(accentColor)
                    HStack(spacing: 10) {
                        Image(systemName: activeOrder?.isPickup == true ? "storefront.fill" : "shippingbox.fill")
                            .foregroundColor(accentColor)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(club.preference?.coffeeName ?? "Your saved coffee")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(primaryTextColor)
                            Text(club.nextShipmentAt.map { formattedClubDate($0) } ?? "Schedule updating")
                                .font(.system(size: 12))
                                .foregroundColor(secondaryTextColor)
                        }
                        Spacer()
                        Text("\(club.remainingCount) left")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(accentColor)
                    }
                }
                .padding(13)
                .background(accentColor.opacity(0.07), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Text("Coffee Club is ready when you are — choose a coffee, size, quantity, and delivery preference.")
                    .font(.system(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                dashboardPreferenceChip(title: activeOrder?.details?.coffeeClub?.preference?.coffeeName ?? "Choose coffee", icon: "cup.and.saucer.fill")
                dashboardPreferenceChip(title: activeOrder?.isPickup == true ? "Pickup" : "Delivery", icon: activeOrder?.isPickup == true ? "storefront.fill" : "truck.box.fill")
            }

            if !coffeeClubOrders.isEmpty {
                VStack(alignment: .leading, spacing: 9) {
                    Text("SHIPMENT HISTORY")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1.7)
                        .foregroundColor(accentColor)
                    ForEach(coffeeClubOrders.prefix(3)) { order in
                        HStack(spacing: 9) {
                            Image(systemName: order.historyStatus == "collected" || order.historyStatus == "delivered" ? "checkmark.circle.fill" : "shippingbox.fill")
                                .foregroundColor(order.historyStatus == "collected" || order.historyStatus == "delivered" ? .green : accentColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(order.details?.coffeeClub?.preference?.coffeeName ?? order.title)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(primaryTextColor)
                                    .lineLimit(1)
                                Text(order.historyStatus.capitalized)
                                    .font(.system(size: 11))
                                    .foregroundColor(secondaryTextColor)
                            }
                            Spacer()
                            Text(formattedClubDate(order.createdAt))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(tertiaryTextColor)
                        }
                    }
                }
                .padding(13)
                .background(accentColor.opacity(0.05), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(21)
        .background(cardFillColor, in: RoundedRectangle(cornerRadius: 25, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 25, style: .continuous).stroke(accentColor.opacity(0.18), lineWidth: 1))
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
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(Color(hex: 0x24180E))
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
                    .foregroundColor(Color(hex: 0xD19A5A))
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
            .clubPrimaryButton(accent: Color(hex: 0xD19A5A))
        }
        .padding(22)
        .background(
            LinearGradient(colors: [Color(hex: 0x24180E), Color(hex: 0x4A2A16)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 25, style: .continuous)
        )
    }

    private func coffeeClubStep(number: String, title: String) -> some View {
        VStack(spacing: 5) {
            Text(number).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundColor(Color(hex: 0xD19A5A))
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
                    .foregroundColor(Color(hex: 0x24180E))
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
                LinearGradient(colors: [Color(hex: 0xF5E8D5), Color(hex: 0xE8CDAA)], startPoint: .topLeading, endPoint: .bottomTrailing),
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
                .foregroundColor(Color(hex: 0x24180E))
                .padding(.horizontal, 16)
                .frame(minHeight: 42)
                .background(emphasis ? Color(hex: 0xD19A5A) : accentColor, in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            emphasis
                ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x24180E), Color(hex: 0x4A2A16)], startPoint: .topLeading, endPoint: .bottomTrailing))
                : AnyShapeStyle(cardFillColor),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(emphasis ? Color(hex: 0xD19A5A).opacity(0.32) : accentColor.opacity(isLightAppearance ? 0.16 : 0.10), lineWidth: 1))
    }

    private var coffeeClubDetail: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("A calmer way to keep great coffee at home.")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(primaryTextColor)
            Text("Choose your coffees, prepay for a set of shipments, and keep your ritual moving without automatic renewal.")
                .font(.system(size: 16))
                .foregroundColor(secondaryTextColor)
            HStack(spacing: 10) {
                clubFact("\(coffeeClubShipmentCount) shipments", icon: "shippingbox.fill")
                clubFact("Every \(coffeeClubIntervalWeeks) weeks", icon: "calendar")
            }
            clubFact("\(coffeeClubDiscountPercent)% coffee saving", icon: "percent")
            Text("CHOOSE YOUR COFFEE")
                .font(.system(size: 10, weight: .bold))
                .tracking(2.1)
                .foregroundColor(accentColor)

            if coffeeClubProducts.isEmpty {
                Text("Coffee Club coffees will appear here when the shop is loaded.")
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
                Button("CHOOSE YOUR COFFEE") {
                    selectedClubArea = .overview
                    openCoffeeClubAction()
                }
                .font(.system(size: 12, weight: .bold))
                .tracking(1.6)
                .foregroundColor(Color(hex: 0x24180E))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .buttonStyle(.plain)
            }
        }
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
            Button("CUSTOMIZE CLUB BAG") {
                configuredCoffee = product
                configuredVariantID = product.variants.first(where: \.isAvailableForSale)?.id ?? ""
                configuredQuantity = 1
                configuredFulfillment = .delivery
            }
            .font(.system(size: 9, weight: .bold))
            .tracking(1.0)
            .foregroundColor(Color(hex: 0x24180E))
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
                    .buttonStyle(.borderedProminent)
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
            .foregroundColor(Color(hex: 0x24180E))
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .background(accent, in: Capsule())
            .buttonStyle(.plain)
    }
}
