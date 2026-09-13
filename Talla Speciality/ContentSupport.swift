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

extension View {
    @ViewBuilder
    func tallaGlassCapsule(tint: Color, enabled: Bool = true) -> some View {
        if #available(iOS 26.0, *) {
            glassEffect(enabled ? .regular.tint(tint).interactive() : .clear, in: .capsule)
        } else {
            background(enabled ? tint : Color.clear, in: Capsule(style: .continuous))
        }
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
            return "System"
        case .english:
            return "English"
        case .arabic:
            return "العربية"
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
        "This part of Talla is unavailable right now. Please try again in a moment."
    }

    static func connectionMessage(for serviceName: String) -> String {
        "Talla is having trouble connecting. Check your internet connection and try again."
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
