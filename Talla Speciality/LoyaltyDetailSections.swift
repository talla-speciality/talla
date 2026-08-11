import SwiftUI
#if canImport(PassKit)
import PassKit
#endif

struct LoyaltyRewardsActionsView: View {
    let account: ContentView.LoyaltyAccount
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
        [
            RewardOption(
                id: "espresso-pour",
                title: AppLocalization.text("reward_espresso_pour", fallback: "Drink of Your Choice"),
                detail: AppLocalization.text("reward_espresso_pour_detail", fallback: "Choose any eligible drink"),
                points: 50,
                reward: "Free Drink"
            ),
            RewardOption(
                id: "pastry-pairing",
                title: AppLocalization.text("reward_pastry_pairing", fallback: "Pastry Pairing"),
                detail: AppLocalization.text("reward_pastry_pairing_detail", fallback: "Pastry with coffee"),
                points: 75,
                reward: "Pastry pairing"
            ),
            RewardOption(
                id: "signature-sip",
                title: AppLocalization.text("reward_signature_sip", fallback: "Signature Sip"),
                detail: AppLocalization.text("reward_signature_sip_detail", fallback: "One signature drink"),
                points: 100,
                reward: "Signature sip"
            ),
            RewardOption(
                id: "majlis-hosting",
                title: AppLocalization.text("reward_majlis_hosting", fallback: "Majlis Hosting"),
                detail: AppLocalization.text("reward_majlis_hosting_detail", fallback: "Arabic coffee service"),
                points: 120,
                reward: "Majlis hosting reward"
            ),
            RewardOption(
                id: "bag-credit",
                title: AppLocalization.text("reward_bag_credit", fallback: "Bag Credit"),
                detail: AppLocalization.text("reward_bag_credit_detail", fallback: "Coffee bag discount"),
                points: 150,
                reward: "Coffee bag credit"
            ),
            RewardOption(
                id: "talla-box-treat",
                title: AppLocalization.text("reward_talla_box_treat", fallback: "Talla Box Treat"),
                detail: AppLocalization.text("reward_talla_box_treat_detail", fallback: "Gift box credit"),
                points: 200,
                reward: "Talla box treat"
            ),
            RewardOption(
                id: "gold-reserve-gift",
                title: AppLocalization.text("reward_gold_reserve_gift", fallback: "Gold Reserve Gift"),
                detail: AppLocalization.text("reward_gold_reserve_gift_detail", fallback: "Exclusive Reserve gift"),
                points: 250,
                reward: "Gold reserve gift"
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("earn_beans", fallback: "Earn Beans"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalization.text("earn_beans_rate", fallback: "Completed orders earn 5 Beans for every 1 BHD spent."))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(1.3)
                    .foregroundColor(primaryTextColor)

                Text(AppLocalization.text("earn_beans_detail", fallback: "Completed purchases update your rewards balance automatically once they are recorded."))
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentColor.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Text(AppLocalization.text("redeem_rewards", fallback: "Redeem Rewards"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(rewardOptions) { reward in
                    redeemButton(reward)
                }
            }

            Text(account.pointsBalance >= 50
                ? AppLocalization.text("choose_reward_redeem", fallback: "Choose a reward to redeem with your available Beans.")
                : AppLocalization.text("reach_first_reward", fallback: "Reach 50 Beans to unlock your first reward."))
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
                        .tracking(1.6)
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
                .tracking(2)
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
                                .tracking(1.5)
                                .textCase(.uppercase)
                                .foregroundColor(primaryTextColor)

                            Spacer()

                            Text(expiryLabel(voucher))
                                .font(Font.custom("AvenirNext-Bold", size: 10))
                                .tracking(1.2)
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
                    )
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
                .tracking(2)
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
                                .tracking(1.5)
                                .foregroundColor(primaryTextColor)

                            if let voucherCode = transaction.voucherCode, !voucherCode.isEmpty {
                                Text("\(AppLocalization.text("voucher", fallback: "Voucher")): \(voucherCode)")
                                    .font(Font.custom("AvenirNext-Bold", size: 10))
                                    .tracking(1.2)
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(accentColor.opacity(isLightAppearance ? 0.14 : 0.06), lineWidth: 1)
                    )
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
                        .tracking(2.5)
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
