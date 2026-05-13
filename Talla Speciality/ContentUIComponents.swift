import SwiftUI

struct WelcomeOverlayView: View {
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let cardFillColor: Color
    let accentColor: Color
    let scrimColor: Color
    let titleFont: Font
    let bodyFont: Font
    let labelFont: Font
    let startAction: () -> Void
    let skipAction: () -> Void

    var body: some View {
        ZStack {
            scrimColor
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalization.text("welcome_eyebrow", fallback: "Welcome to Talla"))
                        .font(labelFont)
                        .tracking(2.4)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("welcome_title", fallback: "Coffee, rewards, and your daily ritual in one place."))
                        .font(titleFont)
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(AppLocalization.text("welcome_intro", fallback: "Shop specialty coffee, collect Beans, and keep your rewards close as you explore Talla."))
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 12) {
                    welcomePoint(
                        icon: "bag.fill",
                        title: AppLocalization.text("welcome_shop_title", fallback: "Shop faster"),
                        detail: AppLocalization.text("welcome_shop_detail", fallback: "Search, sort, and browse coffees, tools, and gifts.")
                    )
                    welcomePoint(
                        icon: "sparkles",
                        title: AppLocalization.text("welcome_beans_title", fallback: "Earn Beans"),
                        detail: AppLocalization.text("welcome_beans_detail", fallback: "Track rewards and redeem perks from your account.")
                    )
                    welcomePoint(
                        icon: "wallet.pass.fill",
                        title: AppLocalization.text("welcome_wallet_title", fallback: "Stay connected"),
                        detail: AppLocalization.text("welcome_wallet_detail", fallback: "Use Wallet and alerts when you want updates close by.")
                    )
                }

                VStack(spacing: 10) {
                    Button(action: startAction) {
                        Text(AppLocalization.text("start_exploring", fallback: "Start Exploring"))
                            .font(labelFont)
                            .tracking(2)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accentColor)
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: skipAction) {
                        Text(AppLocalization.text("skip_for_now", fallback: "Skip for now"))
                            .font(bodyFont)
                            .foregroundColor(secondaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .frame(maxWidth: 440)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(accentColor.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(.horizontal, 20)
        }
    }

    private func welcomePoint(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(accentColor)
                .frame(width: 34, height: 34)
                .background(accentColor.opacity(0.14))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(labelFont)
                    .foregroundColor(primaryTextColor)

                Text(detail)
                    .font(bodyFont)
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionCardView<Content: View>: View {
    let backgroundColor: Color
    let strokeColor: Color
    let cornerRadius: CGFloat
    let content: Content

    init(
        backgroundColor: Color,
        strokeColor: Color,
        cornerRadius: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.strokeColor = strokeColor
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

struct ActionTileView: View {
    let title: String
    let detail: String
    let systemImage: String
    let titleFont: Font
    let detailFont: Font
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let accentColor: Color
    let backgroundColor: Color
    let strokeColor: Color
    let minHeight: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accentColor)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(titleFont)
                        .foregroundColor(primaryTextColor)

                    Text(detail)
                        .font(detailFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .leading)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct CollapsibleSectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var isExpanded: Bool
    let titleFont: Font
    let subtitleFont: Font
    let titleColor: Color
    let subtitleColor: Color
    let accentColor: Color
    let backgroundColor: Color
    let strokeColor: Color
    let content: Content

    init(
        title: String,
        subtitle: String,
        isExpanded: Binding<Bool>,
        titleFont: Font,
        subtitleFont: Font,
        titleColor: Color,
        subtitleColor: Color,
        accentColor: Color,
        backgroundColor: Color,
        strokeColor: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self._isExpanded = isExpanded
        self.titleFont = titleFont
        self.subtitleFont = subtitleFont
        self.titleColor = titleColor
        self.subtitleColor = subtitleColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.strokeColor = strokeColor
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(title)
                            .font(titleFont)
                            .foregroundColor(titleColor)

                        Text(subtitle)
                            .font(subtitleFont)
                            .foregroundColor(subtitleColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(strokeColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 28) {
                    content
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct DetailStatusCardView: View {
    let title: String
    let detail: String
    let titleFont: Font
    let detailFont: Font
    let accentColor: Color
    let primaryTextColor: Color
    let backgroundColor: Color
    let strokeColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(titleFont)
                .foregroundColor(accentColor)

            Text(detail)
                .font(detailFont)
                .foregroundColor(primaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct SummaryValueRow: View {
    let title: String
    let value: String
    let emphasized: Bool
    let regularFont: Font
    let emphasizedFont: Font
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let accentColor: Color

    var body: some View {
        HStack {
            Text(title)
                .font(emphasized ? emphasizedFont : regularFont)
                .tracking(emphasized ? 1.5 : 0)
                .foregroundColor(emphasized ? primaryTextColor : secondaryTextColor)

            Spacer()

            Text(value)
                .font(emphasized ? emphasizedFont : regularFont)
                .tracking(emphasized ? 1.2 : 0)
                .foregroundColor(emphasized ? accentColor : primaryTextColor)
        }
    }
}

struct ToastBannerView: View {
    let message: String
    let font: Font
    let backgroundColor: Color
    let foregroundColor: Color

    var body: some View {
        Text(message)
            .font(font)
            .tracking(1)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(2)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 20)
            .padding(.bottom, 24)
    }
}
