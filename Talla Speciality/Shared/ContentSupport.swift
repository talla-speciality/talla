import Foundation
import SwiftUI

extension ContentView {
    func homeSettingText(_ value: String?, arabicValue: String? = nil, localizationKey: String, fallback: String) -> String {
        AppLocalization.homeText(value, arabicValue: arabicValue, key: localizationKey, fallback: fallback)
    }

    var homeHeroSubtitleText: String {
        let subtitle = homeSettingText(
            remoteHomeSettings?.heroSubtitle,
            arabicValue: remoteHomeSettings?.heroSubtitleAR,
            localizationKey: "hero_subtitle",
            fallback: "Discover fresh roasts, brewing essentials, and rewarding coffee rituals."
        )

        if subtitle.localizedCaseInsensitiveContains("without digging through the app") {
            return AppLocalization.text("hero_subtitle_refined", fallback: "Discover fresh roasts, brewing essentials, and rewarding coffee rituals.")
        }

        return subtitle
    }

    func managedURL(_ value: String?, fallback: String) -> URL {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return URL(string: trimmedValue.isEmpty ? fallback : trimmedValue) ?? URL(string: fallback)!
    }

    var managedWhatsAppURL: URL {
        managedURL(remoteAppSettings?.support.whatsappURL, fallback: "https://wa.me/97339392414")
    }

    var managedPrivacyURL: URL {
        managedURL(remoteAppSettings?.support.privacyURL, fallback: "https://duneroastery.myshopify.com/policies/privacy-policy")
    }

    var managedTermsURL: URL {
        managedURL(remoteAppSettings?.support.termsURL, fallback: "https://duneroastery.myshopify.com/policies/terms-of-service")
    }
}

enum TallaTheme {
    enum Colors {
        // Talla website palette: white surfaces and near-black primary actions.
        // Gold is reserved for brand details; action labels must contrast with the
        // surface they sit on.
        static let accent = Color(hex: 0x151515)
        // Foregrounds and outlines adapt independently of black action fills.
        static let ink = Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? .white
                : UIColor(white: 21.0 / 255.0, alpha: 1)
        })
        static let accentHighlight = Color(hex: 0x3B3B3B)
        static let espresso = Color(hex: 0x151515)
        static let warmWhite = Color(hex: 0xFFFFFF)
        static let readableAccentLight = Color(hex: 0x151515)
        static let readableAccentDark = Color(hex: 0xFFFFFF)
        static let lightBackground = Color(hex: 0xFFFFFF)
        static let darkBackground = Color(hex: 0x151515)
        static let lightSurface = Color(hex: 0xFFFFFF)
        static let darkSurface = Color(hex: 0x202020)
        static let lightElevatedSurface = Color(hex: 0xF2F2F2)
        static let darkElevatedSurface = Color(hex: 0x2B2B2B)
    }

    enum CornerRadius {
        static let control: CGFloat = 14
        static let card: CGFloat = 18
        static let featuredCard: CGFloat = 22
        static let sheet: CGFloat = 28
    }

    enum Spacing {
        static let hairline: CGFloat = 4
        static let compact: CGFloat = 8
        static let standard: CGFloat = 12
        static let section: CGFloat = 18
        static let page: CGFloat = 20
        static let spacious: CGFloat = 28
    }

    enum Fonts {
        static let body = Font.system(.body, design: .rounded)
        static let field = Font.system(.body, design: .rounded)
        static let button = Font.system(.callout, design: .rounded).weight(.bold)
        static let sectionTitle = Font.system(.headline, design: .rounded).weight(.bold)
        static let display = Font.system(.largeTitle, design: .serif).weight(.bold)
    }

    enum Shadow {
        static let cardRadius: CGFloat = 14
        static let cardY: CGFloat = 6
    }
}

struct TallaCardModifier: ViewModifier {
    enum Prominence {
        case standard
        case elevated
    }

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("app.appearanceMode") private var appearanceMode = "system"
    let prominence: Prominence
    let cornerRadius: CGFloat

    private var fill: Color {
        if appearanceMode == "oled" { return .black }
        switch (colorScheme, prominence) {
        case (.dark, .standard): return TallaTheme.Colors.darkSurface
        case (.dark, .elevated): return TallaTheme.Colors.darkElevatedSurface
        case (_, .standard): return TallaTheme.Colors.lightSurface
        case (_, .elevated): return TallaTheme.Colors.lightElevatedSurface
        }
    }

    func body(content: Content) -> some View {
        content
            .background(fill, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        TallaTheme.Colors.ink.opacity(colorScheme == .dark ? 0.24 : 0.13),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.18 : 0.07),
                radius: prominence == .elevated ? TallaTheme.Shadow.cardRadius : 8,
                y: prominence == .elevated ? TallaTheme.Shadow.cardY : 3
            )
    }
}

extension View {
    func tallaCard(
        _ prominence: TallaCardModifier.Prominence = .standard,
        cornerRadius: CGFloat = TallaTheme.CornerRadius.card
    ) -> some View {
        modifier(TallaCardModifier(prominence: prominence, cornerRadius: cornerRadius))
    }
}

struct TallaTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("app.appearanceMode") private var appearanceMode = "system"

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(TallaTheme.Fonts.field)
            .foregroundStyle(TallaTheme.Colors.ink)
            .tint(TallaTheme.Colors.ink)
            .padding(.horizontal, TallaTheme.Spacing.standard)
            .frame(minHeight: 48)
            .background(
                appearanceMode == "oled" ? Color.black : colorScheme == .dark
                    ? TallaTheme.Colors.darkElevatedSurface
                    : TallaTheme.Colors.lightElevatedSurface
            )
            .overlay {
                RoundedRectangle(cornerRadius: TallaTheme.CornerRadius.control, style: .continuous)
                    .stroke(TallaTheme.Colors.ink.opacity(colorScheme == .dark ? 0.24 : 0.20), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: TallaTheme.CornerRadius.control, style: .continuous))
    }
}

extension TextFieldStyle where Self == TallaTextFieldStyle {
    static var talla: TallaTextFieldStyle { TallaTextFieldStyle() }
}

struct TallaPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TallaTheme.Fonts.button)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(
                LinearGradient(
                    colors: [
                        TallaTheme.Colors.espresso,
                        colorScheme == .dark ? Color(hex: 0x3B3B3B) : TallaTheme.Colors.espresso
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: TallaTheme.CornerRadius.control, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: TallaTheme.CornerRadius.control, style: .continuous))
            .shadow(
                color: TallaTheme.Colors.espresso.opacity(configuration.isPressed ? 0.12 : 0.20),
                radius: configuration.isPressed ? 3 : 9,
                y: configuration.isPressed ? 1 : 5
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.48)
            .animation(
                reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.72),
                value: configuration.isPressed
            )
            .contentShape(RoundedRectangle(cornerRadius: TallaTheme.CornerRadius.control, style: .continuous))
    }
}

extension ButtonStyle where Self == TallaPrimaryButtonStyle {
    static var tallaPrimary: TallaPrimaryButtonStyle { TallaPrimaryButtonStyle() }
}

struct TallaSecondaryButtonStyle: ButtonStyle {
    @AppStorage("app.appearanceMode") private var appearanceMode = "system"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(TallaTheme.Fonts.button)
            .foregroundStyle(TallaTheme.Colors.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(
                appearanceMode == "oled" ? Color.black : colorScheme == .dark
                    ? TallaTheme.Colors.darkElevatedSurface
                    : TallaTheme.Colors.lightElevatedSurface
            )
            .overlay {
                RoundedRectangle(cornerRadius: TallaTheme.CornerRadius.control, style: .continuous)
                    .stroke(TallaTheme.Colors.ink.opacity(0.34), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: TallaTheme.CornerRadius.control, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .opacity(isEnabled ? 1 : 0.48)
            .animation(
                reduceMotion ? nil : .spring(response: 0.24, dampingFraction: 0.78),
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == TallaSecondaryButtonStyle {
    static var tallaSecondary: TallaSecondaryButtonStyle { TallaSecondaryButtonStyle() }
}



extension View {
    func tallaGlassCapsule(tint: Color, enabled: Bool = true) -> some View {
        foregroundStyle(enabled ? Color.white : Color.secondary)
            .background(
                enabled ? tint : tint.opacity(0.12),
                in: Capsule(style: .continuous)
            )
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(tint.opacity(enabled ? 0.28 : 0.12), lineWidth: 1)
            }
            .contentShape(Capsule(style: .continuous))
    }

    @ViewBuilder
    func tallaGlassCard(tint: Color, cornerRadius: CGFloat) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(.regular.tint(tint), in: .rect(cornerRadius: cornerRadius))
        } else {
            background(tint, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case arabic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return AppLocalization.text("system_language", fallback: "System")
        case .english:
            return AppLocalization.text("english", fallback: "English")
        case .arabic:
            return AppLocalization.text("arabic", fallback: "العربية")
        }
    }

    var localeIdentifier: String {
        switch self {
        case .system:
            return Locale.current.identifier
        case .english:
            return "en"
        case .arabic:
            return "ar"
        }
    }

    var layoutDirection: LayoutDirection {
        switch effectiveLanguageCode {
        case "ar":
            return .rightToLeft
        default:
            return .leftToRight
        }
    }

    var effectiveLanguageCode: String {
        switch self {
        case .system:
            return Locale.current.language.languageCode?.identifier ?? "en"
        case .english:
            return "en"
        case .arabic:
            return "ar"
        }
    }
}

enum AppLocalization {
    private static let translations: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "Translations", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String: String]].self, from: data) else {
            return [:]
        }

        return decoded
    }()

    // Use bundled catalog copy only while it still matches the source product.
    // New Shopify translations win; changed English copy never gets an outdated translation.
    static func catalogText(_ value: String, source: String, key: String) -> String {
        func normalized(_ text: String) -> String {
            text.components(separatedBy: .whitespacesAndNewlines).joined()
        }
        guard currentLanguage.effectiveLanguageCode == "ar",
              normalized(value) == normalized(source),
              let entry = translations[key], let original = entry["en"],
              normalized(original) == normalized(source), let arabic = entry["ar"] else { return value }
        return arabic
    }

    static func catalogOption(_ value: String) -> String {
        value.components(separatedBy: " / ").map {
            text("catalog_term_" + $0.trimmingCharacters(in: .whitespaces).lowercased(), fallback: $0)
        }.joined(separator: " / ")
    }

    static func letterSpacing(_ value: CGFloat) -> CGFloat {
        currentLanguage.effectiveLanguageCode == "ar" ? 0 : value
    }

    static func homeText(_ value: String?, arabicValue: String? = nil, key: String, fallback: String) -> String {
        if currentLanguage.effectiveLanguageCode == "ar",
           let arabic = arabicValue?.trimmingCharacters(in: .whitespacesAndNewlines), !arabic.isEmpty {
            return arabic
        }
        let remote = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !remote.isEmpty else { return text(key, fallback: fallback) }
        if currentLanguage.effectiveLanguageCode == "ar",
           !remote.unicodeScalars.contains(where: { (0x0600...0x06FF).contains(Int($0.value)) }) {
            return text(key, fallback: fallback)
        }
        return remote
    }

    static var currentLanguage: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: "app.language") ?? AppLanguage.system.rawValue
        return AppLanguage(rawValue: rawValue) ?? .system
    }

    static func text(_ key: String, fallback: String) -> String {
        let languageCode = currentLanguage.effectiveLanguageCode
        return translations[key]?[languageCode] ?? fallback
    }
}

enum BackendConfiguration {
    private static let infoPlistKey = "BackendBaseURL"
    private static let simulatorDefaultURL = URL(string: "http://127.0.0.1:8787")

    static var serviceBaseURL: URL? {
        #if DEBUG && targetEnvironment(simulator)
        if let override = ProcessInfo.processInfo.environment["TALLA_BACKEND_BASE_URL"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !override.isEmpty,
           let overrideURL = URL(string: override) {
            return overrideURL
        }
        #endif

        if let configuredURL {
            return configuredURL
        }

        #if targetEnvironment(simulator)
        return simulatorDefaultURL
        #else
        return nil
        #endif
    }

    static func unavailableMessage(for serviceName: String) -> String {
        AppLocalization.text("service_unavailable", fallback: "This part of Talla is unavailable right now. Please try again in a moment.")
    }

    static func connectionMessage(for serviceName: String) -> String {
        AppLocalization.text("connection_problem", fallback: "Talla is having trouble connecting. Check your internet connection and try again.")
    }

    private static var configuredURL: URL? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: infoPlistKey) as? String else {
            return nil
        }

        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedValue.isEmpty, let url = URL(string: trimmedValue) else {
            return nil
        }

        #if targetEnvironment(simulator)
        return url
        #else
        guard let host = url.host?.lowercased(), host != "127.0.0.1", host != "localhost" else {
            return nil
        }
        return url
        #endif
    }
}
