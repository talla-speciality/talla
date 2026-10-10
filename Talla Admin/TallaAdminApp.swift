import SwiftUI

@main
struct TallaAdminApp: App {
    @UIApplicationDelegateAdaptor(TallaAdminAppDelegate.self) private var appDelegate
    @StateObject private var session = AdminSession()

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isRestoring {
                    LaunchView()
                } else if session.isAuthenticated {
                    AdminRootView()
                } else {
                    AdminLoginView()
                }
            }
            .environmentObject(session)
            .tint(TallaAdminStyle.caramel)
            .fontDesign(.rounded)
            .task { await session.bootstrap() }
        }
    }
}

enum TallaAdminStyle {
    // Mirrors the customer app: neutral surfaces, ink-first actions, and
    // restrained gold reserved for brand and status accents.
    static let espresso = adaptive(light: (0.08, 0.08, 0.08), dark: (1, 1, 1))
    static let action = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let caramel = adaptive(light: (0.45, 0.29, 0.10), dark: (0.88, 0.69, 0.40))
    static let cream = adaptive(light: (0.96, 0.96, 0.96), dark: (0.10, 0.10, 0.10))
    static let paper = adaptive(light: (1, 1, 1), dark: (0.08, 0.08, 0.08))
    static let card = adaptive(light: (1, 1, 1), dark: (0.13, 0.13, 0.13))
    static let background = adaptive(light: (0.97, 0.97, 0.97), dark: (0.06, 0.06, 0.06))
    static let border = adaptive(light: (0.82, 0.82, 0.82), dark: (0.28, 0.28, 0.28))
    static let success = adaptive(light: (0.13, 0.42, 0.25), dark: (0.38, 0.76, 0.49))
    static let warning = adaptive(light: (0.67, 0.39, 0.06), dark: (0.96, 0.68, 0.25))

    enum CornerRadius {
        static let control: CGFloat = 14
        static let card: CGFloat = 18
        static let featuredCard: CGFloat = 22
    }

    enum Spacing {
        static let compact: CGFloat = 8
        static let standard: CGFloat = 12
        static let section: CGFloat = 18
        static let page: CGFloat = 20
    }

    enum Font {
        static let display = SwiftUI.Font.system(.largeTitle, design: .serif).weight(.bold)
        static let sectionTitle = SwiftUI.Font.system(.headline, design: .rounded).weight(.bold)
        static let body = SwiftUI.Font.system(.body, design: .rounded)
        static let button = SwiftUI.Font.system(.callout, design: .rounded).weight(.bold)
    }

    private static func adaptive(
        light: (CGFloat, CGFloat, CGFloat),
        dark: (CGFloat, CGFloat, CGFloat)
    ) -> Color {
        Color(uiColor: UIColor { traits in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: value.0, green: value.1, blue: value.2, alpha: 1)
        })
    }
}

struct TallaAdminPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TallaAdminStyle.Font.button)
            .foregroundStyle(.white)
            .padding(.horizontal, TallaAdminStyle.Spacing.section)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(TallaAdminStyle.action)
            .clipShape(RoundedRectangle(cornerRadius: TallaAdminStyle.CornerRadius.control, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(isEnabled ? 1 : 0.48)
            .animation(reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.78), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == TallaAdminPrimaryButtonStyle {
    static var tallaAdminPrimary: TallaAdminPrimaryButtonStyle { TallaAdminPrimaryButtonStyle() }
}

extension View {
    func tallaAdminCard() -> some View {
        padding(TallaAdminStyle.Spacing.page)
            .background(TallaAdminStyle.card)
            .overlay {
                RoundedRectangle(cornerRadius: TallaAdminStyle.CornerRadius.featuredCard, style: .continuous)
                    .strokeBorder(TallaAdminStyle.border.opacity(0.55), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: TallaAdminStyle.CornerRadius.featuredCard, style: .continuous))
    }

    func tallaAdminField() -> some View {
        font(TallaAdminStyle.Font.body)
            .padding(.horizontal, TallaAdminStyle.Spacing.standard)
            .frame(minHeight: 48)
            .background(TallaAdminStyle.card)
            .overlay {
                RoundedRectangle(cornerRadius: TallaAdminStyle.CornerRadius.control, style: .continuous)
                    .strokeBorder(TallaAdminStyle.border.opacity(0.65), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: TallaAdminStyle.CornerRadius.control, style: .continuous))
    }
}

private struct LaunchView: View {
    var body: some View {
        ZStack {
            TallaAdminStyle.cream.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(TallaAdminStyle.caramel)
                Text("TALLA ADMIN")
                    .font(.caption.weight(.bold))
                    .tracking(4)
                    .foregroundStyle(TallaAdminStyle.espresso)
                ProgressView()
            }
        }
    }
}
