import SwiftUI

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
