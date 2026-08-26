import Foundation
import SwiftUI
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
