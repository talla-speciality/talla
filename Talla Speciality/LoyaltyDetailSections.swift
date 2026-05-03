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
                redeemButton(title: AppLocalization.text("reward_espresso_pour", fallback: "Espresso Pour"), points: 50, reward: "Espresso pour")
                redeemButton(title: AppLocalization.text("reward_pastry_pairing", fallback: "Pastry Pairing"), points: 75, reward: "Pastry pairing")
                redeemButton(title: AppLocalization.text("reward_signature_sip", fallback: "Signature Sip"), points: 100, reward: "Signature sip")
                redeemButton(title: AppLocalization.text("reward_bag_credit", fallback: "Bag Credit"), points: 150, reward: "Coffee bag credit")
                redeemButton(title: AppLocalization.text("reward_talla_box_treat", fallback: "Talla Box Treat"), points: 200, reward: "Talla box treat")
                redeemButton(title: AppLocalization.text("reward_gold_reserve_gift", fallback: "Gold Reserve Gift"), points: 250, reward: "Gold reserve gift")
            }

            Text(account.pointsBalance >= 50
                ? AppLocalization.text("choose_reward_redeem", fallback: "Choose a reward to redeem with your available Beans.")
                : AppLocalization.text("reach_first_reward", fallback: "Reach 50 Beans to unlock your first reward."))
                .font(Font.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(tertiaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func redeemButton(title: String, points: Int, reward: String) -> some View {
        Button {
            redeemAction(points, reward)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(2)
                    .textCase(.uppercase)

                Text(String(format: AppLocalization.text("beans_count", fallback: "%d Beans"), points))
                    .font(Font.custom("AvenirNext-Regular", size: 13))
            }
            .foregroundColor(Color(hex: 0x0A0804))
            .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .glassEffect(.regular.tint(accentColor).interactive(), in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .disabled(isRedeemingReward || account.pointsBalance < points)
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

                            Text(transaction.createdAt.replacingOccurrences(of: "T", with: " ").replacingOccurrences(of: "Z", with: ""))
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

            Text("")
                .font(Font.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(tertiaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
