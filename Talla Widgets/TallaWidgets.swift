#if canImport(WidgetKit) && canImport(AppIntents)
import AppIntents
import SwiftUI
import WidgetKit

struct TallaWidgetDeepLinks {
    static let shop = URL(string: "talla://shop")!
    static let shelf = URL(string: "talla://shelf")!
    static let concierge = URL(string: "talla://concierge")!
    static let brewing = URL(string: "talla://brewing")!
    static let rewards = URL(string: "talla://rewards")!
}

private enum TallaWidgetSharedState {
    static let appGroupID = "group.Talla-Speciality.Talla-Speciality"
    static let loyaltyEmailKey = "loyalty.email"
    static let favoriteCountKey = "widget.favoriteCount"
    static let recentCountKey = "widget.recentCount"
    static let savedCartCountKey = "widget.savedCartCount"
    static let languageKey = "app.language"
    static let loyaltyPointsKey = "watch.loyalty.points"
    static let loyaltyTierKey = "watch.loyalty.tier"
    static let loyaltyNextRewardKey = "watch.loyalty.nextReward"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}

struct TallaQuickActionsEntry: TimelineEntry {
    let date: Date
    let beansText: String
    let nextAction: String
    let favoriteCount: Int
    let recentCount: Int
    let savedCartCount: Int
    let languageCode: String
    let loyaltyPoints: Int
    let loyaltyTier: String
    let loyaltyNextReward: String

    var hasShelf: Bool { favoriteCount > 0 }
    var isArabic: Bool { languageCode == "ar" }
    var preferredURL: URL { hasShelf ? TallaWidgetDeepLinks.shelf : TallaWidgetDeepLinks.shop }
}

struct TallaQuickActionsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TallaQuickActionsEntry {
        TallaQuickActionsEntry(
            date: Date(),
            beansText: "Rewards ready",
            nextAction: "Open Shelf",
            favoriteCount: 3,
            recentCount: 5,
            savedCartCount: 1,
            languageCode: "en",
            loyaltyPoints: 72,
            loyaltyTier: "Reserve",
            loyaltyNextReward: "28 Beans to next reward"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TallaQuickActionsEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TallaQuickActionsEntry>) -> Void) {
        let entry = currentEntry()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3_600)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func currentEntry() -> TallaQuickActionsEntry {
        let defaults = TallaWidgetSharedState.defaults
        let loyaltyEmail = defaults.string(forKey: TallaWidgetSharedState.loyaltyEmailKey) ?? ""
        let favoriteCount = defaults.integer(forKey: TallaWidgetSharedState.favoriteCountKey)
        let recentCount = defaults.integer(forKey: TallaWidgetSharedState.recentCountKey)
        let savedCartCount = defaults.integer(forKey: TallaWidgetSharedState.savedCartCountKey)
        let languageCode = defaults.string(forKey: TallaWidgetSharedState.languageKey) == "ar" ? "ar" : "en"
        let loyaltyPoints = defaults.integer(forKey: TallaWidgetSharedState.loyaltyPointsKey)
        let loyaltyTier = defaults.string(forKey: TallaWidgetSharedState.loyaltyTierKey) ?? "Reserve"
        let loyaltyNextReward = defaults.string(forKey: TallaWidgetSharedState.loyaltyNextRewardKey) ?? "Check rewards in app"
        let isArabic = languageCode == "ar"
        let beansText = loyaltyEmail.isEmpty
            ? (isArabic ? "سجّل الدخول للـ Beans" : "Sign in for Beans")
            : (isArabic ? "المكافآت جاهزة" : "Rewards ready")
        let nextAction = favoriteCount > 0
            ? (isArabic ? "افتح الرف" : "Open Shelf")
            : (isArabic ? "تسوق القهوة" : "Shop Coffee")

        return TallaQuickActionsEntry(
            date: Date(),
            beansText: beansText,
            nextAction: nextAction,
            favoriteCount: favoriteCount,
            recentCount: recentCount,
            savedCartCount: savedCartCount,
            languageCode: languageCode,
            loyaltyPoints: loyaltyPoints,
            loyaltyTier: loyaltyTier,
            loyaltyNextReward: loyaltyNextReward
        )
    }
}

struct TallaQuickActionsWidgetView: View {
    let entry: TallaQuickActionsEntry
    @Environment(\.widgetFamily) private var widgetFamily
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    private var isClearAppearance: Bool {
        !showsWidgetContainerBackground || widgetRenderingMode != .fullColor
    }

    var body: some View {
        Group {
            switch widgetFamily {
            case .accessoryCircular:
                circularAccessory
            case .accessoryRectangular:
                rectangularAccessory
            case .accessoryInline:
                inlineAccessory
            case .systemMedium:
                mediumWidget
            default:
                smallWidget
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
        .foregroundStyle(primaryForeground)
        .widgetURL(entry.preferredURL)
    }

    private var primaryForeground: Color {
        if isClearAppearance {
            return .primary
        }

        return colorScheme == .dark
            ? Color(red: 0.98, green: 0.92, blue: 0.80)
            : Color(red: 0.16, green: 0.10, blue: 0.06)
    }

    private var panelFill: Color {
        if isClearAppearance {
            return Color.primary.opacity(0.08)
        }

        return colorScheme == .dark
            ? Color.white.opacity(0.12)
            : Color.white.opacity(0.54)
    }

    private var subtlePanelFill: Color {
        if isClearAppearance {
            return Color.primary.opacity(0.06)
        }

        return colorScheme == .dark
            ? Color.white.opacity(0.11)
            : Color.white.opacity(0.42)
    }

    private var accentFill: Color {
        if isClearAppearance {
            return Color.accentColor.opacity(0.22)
        }

        return colorScheme == .dark
            ? Color(red: 0.82, green: 0.62, blue: 0.36)
            : Color(red: 0.53, green: 0.34, blue: 0.17)
    }

    private var accentText: Color {
        if isClearAppearance {
            return Color.primary
        }

        return colorScheme == .dark
            ? Color(red: 0.06, green: 0.04, blue: 0.02)
            : Color.white
    }

    private var secondaryForeground: Color {
        if isClearAppearance {
            return Color.secondary
        }

        return colorScheme == .dark
            ? Color(red: 0.98, green: 0.92, blue: 0.80).opacity(0.72)
            : Color(red: 0.16, green: 0.10, blue: 0.06).opacity(0.66)
    }

    private func localized(_ english: String, _ arabic: String) -> String {
        entry.isArabic ? arabic : english
    }

    private var accessoryProgress: Double {
        Double(entry.loyaltyPoints % 100) / 100
    }

    private var circularAccessory: some View {
        Gauge(value: accessoryProgress) {
            Image(systemName: "cup.and.saucer.fill")
        } currentValueLabel: {
            Text("\(entry.loyaltyPoints)")
                .font(.system(size: 15, weight: .black, design: .serif))
                .minimumScaleFactor(0.6)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(accentFill)
        .widgetURL(TallaWidgetDeepLinks.rewards)
    }

    private var rectangularAccessory: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "cup.and.saucer.fill")
                Text("TALLA")
                    .font(.system(size: 11, weight: .black, design: .serif))
            }
            .foregroundStyle(accentFill)

            Text("\(entry.loyaltyPoints) Beans")
                .font(.system(size: 14, weight: .black))
                .lineLimit(1)

            Text(entry.loyaltyNextReward)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .widgetURL(TallaWidgetDeepLinks.rewards)
    }

    private var inlineAccessory: some View {
        Label("\(entry.loyaltyPoints) Beans", systemImage: "cup.and.saucer.fill")
            .widgetURL(TallaWidgetDeepLinks.rewards)
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 9) {
            widgetHeader(iconSize: 28, titleSize: 16)

            VStack(alignment: .leading, spacing: 6) {
                statLine(title: localized("Shelf", "الرف"), value: entry.favoriteCount, icon: "books.vertical.fill")
                statLine(title: localized("Recent", "الأخيرة"), value: entry.recentCount, icon: "clock.fill")
                statLine(title: localized("Carts", "السلال"), value: entry.savedCartCount, icon: "cart.fill")
            }

            Spacer(minLength: 0)

            Link(destination: entry.preferredURL) {
                Label(entry.nextAction, systemImage: entry.hasShelf ? "books.vertical.fill" : "bag.fill")
                    .font(.system(size: 11, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, minHeight: 30)
                    .background(accentFill, in: Capsule())
                    .foregroundStyle(accentText)
            }
        }
        .padding(14)
    }

    private var mediumWidget: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                widgetHeader(iconSize: 30, titleSize: 18)

                Text(localized("Your coffee shortcuts, shelf, and rewards in one place.", "اختصارات القهوة والرف والمكافآت في مكان واحد."))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)

                HStack(spacing: 7) {
                    statPill(title: localized("Shelf", "الرف"), value: entry.favoriteCount, icon: "books.vertical.fill")
                    statPill(title: localized("Recent", "الأخيرة"), value: entry.recentCount, icon: "clock.fill")
                    statPill(title: localized("Carts", "السلال"), value: entry.savedCartCount, icon: "cart.fill")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                widgetLink(localized("Shelf", "الرف"), systemImage: "books.vertical.fill", url: TallaWidgetDeepLinks.shelf, highlighted: entry.hasShelf)
                widgetLink(localized("Shop", "المتجر"), systemImage: "bag.fill", url: TallaWidgetDeepLinks.shop, highlighted: false)
                widgetLink(localized("Concierge", "المرشد"), systemImage: "sparkles", url: TallaWidgetDeepLinks.concierge, highlighted: false)
                widgetLink(localized("Rewards", "المكافآت"), systemImage: "star.circle.fill", url: TallaWidgetDeepLinks.rewards, highlighted: false)
            }
            .frame(width: 116)
        }
        .padding(14)
    }

    private func widgetHeader(iconSize: CGFloat, titleSize: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: iconSize * 0.54, weight: .black))
                .foregroundStyle(accentText)
                .frame(width: iconSize, height: iconSize)
                .background(accentFill, in: Circle())
                .widgetAccentable()

            VStack(alignment: .leading, spacing: 1) {
                Text("TALLA")
                    .font(.system(size: titleSize, weight: .black, design: .serif))
                    .lineLimit(1)
                    .widgetAccentable()
                Text(entry.beansText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(secondaryForeground)
                    .lineLimit(1)
            }
        }
    }

    private func statLine(title: String, value: Int, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
                .frame(width: 16)
            Text("\(value) \(title)")
                .font(.system(size: 10, weight: .bold))
                .lineLimit(1)
        }
        .foregroundStyle(secondaryForeground)
    }

    private func statPill(title: String, value: Int, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
            Text("\(value)")
                .font(.system(size: 17, weight: .black))
            Text(title)
                .font(.system(size: 8, weight: .bold))
                .textCase(.uppercase)
                .foregroundStyle(secondaryForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func widgetLink(_ title: String, systemImage: String, url: URL, highlighted: Bool) -> some View {
        Link(destination: url) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .black))
                    .frame(width: 14)
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity, minHeight: 30)
            .background(
                highlighted ? accentFill : subtlePanelFill,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .foregroundStyle(highlighted ? accentText : primaryForeground)
        }
    }

    private var widgetBackground: some View {
        ZStack {
            if isClearAppearance {
                Color.clear
            } else if colorScheme == .dark {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.05, blue: 0.03),
                        Color(red: 0.18, green: 0.11, blue: 0.06),
                        Color(red: 0.30, green: 0.19, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [Color.white.opacity(0.14), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.95, blue: 0.88),
                        Color(red: 0.94, green: 0.86, blue: 0.74),
                        Color(red: 0.84, green: 0.69, blue: 0.51)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                LinearGradient(
                    colors: [Color.white.opacity(0.48), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
        }
    }
}

struct TallaQuickActionsWidget: Widget {
    static let kind = "com.talla.speciality.quick-actions"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: TallaQuickActionsProvider()) { entry in
            TallaQuickActionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Talla Shelf")
        .description("Open your saved shelf, shop, Coffee Concierge, and rewards quickly.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        .containerBackgroundRemovable(true)
    }
}

@available(iOS 18.0, *)
struct TallaConciergeControl: ControlWidget {
    static let kind = "com.talla.speciality.concierge-control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenTallaConciergeIntent()) {
                Label("Concierge", systemImage: "sparkles")
                    .controlWidgetActionHint("Open Coffee Concierge")
            }
        }
        .displayName("Coffee Concierge")
        .description("Open Talla Coffee Concierge from Control Center, the Lock Screen, or the Action Button.")
    }
}

@available(iOS 18.0, *)
struct TallaShopControl: ControlWidget {
    static let kind = "com.talla.speciality.shop-control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenTallaShopIntent()) {
                Label("Shop", systemImage: "bag.fill")
                    .controlWidgetActionHint("Open Talla Shop")
            }
        }
        .displayName("Talla Shop")
        .description("Open the Talla shop from Control Center, the Lock Screen, or the Action Button.")
    }
}
#endif
