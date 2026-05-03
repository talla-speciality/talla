import SwiftUI

struct CartDrawerView: View {
    let scrimColor: Color
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let elevatedSurfaceColor: Color
    let accentColor: Color
    let hasItems: Bool
    let emptyState: AnyView
    let reviewContent: AnyView
    let footerContent: AnyView
    let closeAction: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                scrimColor
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeAction()
                    }

                VStack(alignment: .leading, spacing: 20) {
                    Capsule()
                        .fill(primaryTextColor.opacity(0.2))
                        .frame(width: 54, height: 5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 6)

                    HStack {
                        Text(AppLocalization.text("your_cart", fallback: "YOUR CART"))
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .tracking(2)
                            .foregroundColor(accentColor)

                        Spacer()

                        Button(action: closeAction) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(secondaryTextColor)
                        }
                        .buttonStyle(.plain)
                    }

                    if hasItems {
                        ScrollView(showsIndicators: false) {
                            reviewContent
                                .padding(.bottom, 8)
                        }

                        footerContent
                    } else {
                        emptyState
                        Spacer(minLength: 0)
                    }
                }
                .padding(24)
                .frame(maxWidth: 400)
                .frame(maxHeight: min(geometry.size.height * 0.82, 720), alignment: .top)
                .background(elevatedSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(accentColor.opacity(0.16), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
    }
}
