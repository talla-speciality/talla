import Foundation
import SwiftUI
import StoreKit
#if canImport(Security)
import Security
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

struct DuoToolbarBehavior: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension ContentView {
    var header: some View {
        VStack(spacing: isShortHeight ? 4 : 6) {
            HStack {
                Button {
                    openTab(.home)
                } label: {
                    HStack(spacing: 12) {
                        Image("Logo")
                            .resizable()
                            .scaledToFit()
                            .frame(
                                width: isShortHeight ? 38 : (customerProfile == nil ? 48 : 46),
                                height: isShortHeight ? 38 : (customerProfile == nil ? 48 : 46)
                            )

                        if let customerProfile {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(AppLocalization.text("welcome_back", fallback: "Welcome back,"))
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(AppLocalization.letterSpacing(1.5))
                                    .textCase(.uppercase)
                                    .foregroundColor(readableBrandGoldColor)

                                Text(customerFirstName(for: customerProfile))
                                    .font(displayFont(size: isShortHeight ? 21 : (isCompact ? 26 : 27)))
                                    .foregroundColor(primaryTextColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                            }
                        } else {
                            Text("TALLA")
                                .font(displayFont(size: isShortHeight ? 25 : (isCompact ? 31 : 30)))
                                .tracking(isCompact ? 1.5 : 2)
                                .foregroundColor(primaryTextColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                if !usesSystemNavigationActions && !showLaunchSplash && shouldShowHeaderCartButton {
                    headerCartButton
                }

                if !usesSystemNavigationActions {
                    appearanceMenu
                }
            }
        }
        .padding(.horizontal, isShortHeight ? 12 : 16)
        .padding(.top, isShortHeight ? 7 : 12)
        .padding(.bottom, isShortHeight ? 7 : 12)
        .background(Color.clear)
    }

    var usesSystemNavigationActions: Bool {
        if #available(iOS 27.0, *) { return true }
        return false
    }

    var appearanceMenu: some View {
                Menu {
                    Section(AppLocalization.text("appearance", fallback: "Appearance")) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Button {
                                savedAppearanceMode = mode.rawValue
                            } label: {
                                HStack {
                                    Text(mode.title)
                                    if appearanceMode == mode {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                    Section(AppLocalization.text("language", fallback: "Language")) {
                        ForEach(AppLanguage.allCases) { language in
                            Button {
                                savedAppLanguage = language.rawValue
                            } label: {
                                HStack {
                                    Text(language.title)
                                    if (AppLanguage(rawValue: savedAppLanguage) ?? .system) == language {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                } label: {
                    Label(AppLocalization.text("appearance_and_language", fallback: "Appearance and language"), systemImage: "circle.lefthalf.filled")
                        .labelStyle(.iconOnly)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(readableBrandGoldColor)
                        .frame(width: 40, height: 40)
                        .background(cardFillColor)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.16 : 0.14), lineWidth: 1)
                        )
                }
                .menuStyle(.button)
                .accessibilityLabel(AppLocalization.text("appearance_and_language", fallback: "Appearance and language"))
    }

    var headerCartButton: some View {
        HeaderCartButton(
            cartCount: cartCount,
            showingCelebration: showingCartCelebration,
            celebrationID: cartCelebrationID,
            isLightAppearance: isLightAppearance,
            cardFillColor: cardFillColor
        ) {
            withAnimation(.easeInOut(duration: 0.18)) {
                cartOpen = true
            }
        }
    }
}

private struct HeaderCartButton: View {
    let cartCount: Int
    let showingCelebration: Bool
    let celebrationID: Int
    let isLightAppearance: Bool
    let cardFillColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                if showingCelebration {
                    Circle()
                        .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.32 : 0.42), lineWidth: 2)
                        .frame(width: 44, height: 44)
                        .scaleEffect(1.42)
                        .opacity(0.55)
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }

                Image(systemName: cartCount > 0 ? "bag.fill" : "bag")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(cartCount > 0 ? .white : TallaTheme.Colors.ink)
                    .symbolEffect(.bounce, value: celebrationID)
                    .frame(width: 40, height: 40)
                    .background(cartCount > 0 ? TallaTheme.Colors.accent : cardFillColor)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(TallaTheme.Colors.ink.opacity(isLightAppearance ? 0.20 : 0.14), lineWidth: 1)
                    )

                if cartCount > 0 {
                    Text(cartCount > 99 ? "99+" : "\(cartCount)")
                        .font(.system(size: cartCount > 99 ? 8 : 9, weight: .black))
                        .foregroundColor(Color(hex: 0x1A1208))
                        .padding(.horizontal, cartCount > 99 ? 6 : 0)
                        .frame(minWidth: 18, minHeight: 18)
                        .background(Color(hex: 0xF7E1B7))
                        .contentTransition(.numericText())
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: 0x8A5E30).opacity(0.35), lineWidth: 1.2)
                        )
                        .shadow(color: Color.black.opacity(isLightAppearance ? 0.12 : 0.22), radius: 5, y: 2)
                        .offset(x: 5, y: -4)
                }
            }
            .frame(width: 44, height: 44, alignment: .center)
            .scaleEffect(showingCelebration ? 1.16 : 1)
            .rotationEffect(.degrees(showingCelebration ? -4 : 0))
            .animation(.spring(response: 0.26, dampingFraction: 0.48), value: showingCelebration)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(AppLocalization.text("open_bag", fallback: "Open bag"))
        .accessibilityValue(
            cartCount > 0
                ? String(format: AppLocalization.text("items_in_bag", fallback: "%d items in bag"), cartCount)
                : AppLocalization.text("empty_bag", fallback: "Empty bag")
        )
    }
}
