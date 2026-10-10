#if canImport(WidgetKit) && canImport(AppIntents)
import AppIntents
import SwiftUI
import WidgetKit
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(UIKit)
import UIKit
#endif

struct TallaWidgetDeepLinks {
    static let shop = URL(string: "talla://shop")!
    static let shelf = URL(string: "talla://shelf")!
    static let concierge = URL(string: "talla://concierge")!
    static let brewing = URL(string: "talla://brewing")!
    static let rewards = URL(string: "talla://rewards")!
    static let gifts = URL(string: "talla://gifts")!
    static let groupOrder = URL(string: "talla://group-order")!
    static let orders = URL(string: "talla://orders")!
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
    static let activeGiftNameKey = "widget.activeGift.name"
    static let activeGiftExpiryKey = "widget.activeGift.expiry"
    static let groupOrderNameKey = "widget.groupOrder.name"
    static let groupOrderParticipantCountKey = "widget.groupOrder.participantCount"
    static let groupOrderDeadlineKey = "widget.groupOrder.deadline"
    static let orderStatusKey = "widget.order.status"
    static let orderIsPickupKey = "widget.order.isPickup"

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
    let activeGiftName: String?
    let activeGiftExpiry: Date?
    let groupOrderName: String?
    let groupOrderParticipantCount: Int
    let groupOrderDeadline: Date?
    let orderStatus: String?
    let orderIsPickup: Bool

    var hasShelf: Bool { favoriteCount > 0 }
    var isArabic: Bool { languageCode == "ar" }
    var preferredURL: URL { hasShelf ? TallaWidgetDeepLinks.shelf : TallaWidgetDeepLinks.shop }
    var hasActiveGift: Bool { activeGiftName != nil }
    var hasGroupOrder: Bool { groupOrderName != nil }
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
            loyaltyTier: "Bronze",
            loyaltyNextReward: "28 Beans to next reward",
            activeGiftName: "Iced latte",
            activeGiftExpiry: Date().addingTimeInterval(86_400 * 4),
            groupOrderName: "Office coffee",
            groupOrderParticipantCount: 6,
            groupOrderDeadline: Date().addingTimeInterval(7_200),
            orderStatus: "Ready for pickup",
            orderIsPickup: true
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
        let loyaltyTier = defaults.string(forKey: TallaWidgetSharedState.loyaltyTierKey) ?? "Bronze"
        let loyaltyNextReward = defaults.string(forKey: TallaWidgetSharedState.loyaltyNextRewardKey) ?? "Check rewards in app"
        let isoFormatter = ISO8601DateFormatter()
        let activeGiftName = defaults.string(forKey: TallaWidgetSharedState.activeGiftNameKey)
        let activeGiftExpiry = defaults.string(forKey: TallaWidgetSharedState.activeGiftExpiryKey).flatMap(isoFormatter.date)
        let groupOrderName = defaults.string(forKey: TallaWidgetSharedState.groupOrderNameKey)
        let groupOrderDeadline = defaults.string(forKey: TallaWidgetSharedState.groupOrderDeadlineKey).flatMap(isoFormatter.date)
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
            loyaltyNextReward: loyaltyNextReward,
            activeGiftName: activeGiftName,
            activeGiftExpiry: activeGiftExpiry,
            groupOrderName: groupOrderName,
            groupOrderParticipantCount: defaults.integer(forKey: TallaWidgetSharedState.groupOrderParticipantCountKey),
            groupOrderDeadline: groupOrderDeadline,
            orderStatus: defaults.string(forKey: TallaWidgetSharedState.orderStatusKey),
            orderIsPickup: defaults.bool(forKey: TallaWidgetSharedState.orderIsPickupKey)
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
        .widgetURL(priorityURL)
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
            Image(systemName: priorityIcon)
        } currentValueLabel: {
            Text(priorityValue)
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
                Image(systemName: priorityIcon)
                Text(priorityTitle)
                    .font(.system(size: 11, weight: .black, design: .serif))
            }
            .foregroundStyle(accentFill)

            Text(priorityValue)
                .font(.system(size: 14, weight: .black))
                .lineLimit(1)

            Text(priorityDetail)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .widgetURL(TallaWidgetDeepLinks.rewards)
    }

    private var inlineAccessory: some View {
        Label(priorityValue, systemImage: priorityIcon)
            .widgetURL(priorityURL)
    }

    private var priorityIcon: String {
        if entry.hasActiveGift { return "gift.fill" }
        if entry.hasGroupOrder { return "person.3.fill" }
        if entry.orderStatus != nil { return entry.orderIsPickup ? "storefront.fill" : "shippingbox.fill" }
        return "cup.and.saucer.fill"
    }

    private var priorityURL: URL {
        if entry.hasActiveGift { return TallaWidgetDeepLinks.gifts }
        if entry.hasGroupOrder { return TallaWidgetDeepLinks.groupOrder }
        if entry.orderStatus != nil { return TallaWidgetDeepLinks.orders }
        return TallaWidgetDeepLinks.rewards
    }

    private var priorityTitle: String {
        if entry.hasActiveGift { return localized("COFFEE GIFT", "هدية قهوة") }
        if entry.hasGroupOrder { return localized("GROUP ORDER", "طلب جماعي") }
        if entry.orderStatus != nil { return entry.orderIsPickup ? localized("PICKUP", "استلام") : localized("ORDER", "طلب") }
        return "TALLA"
    }

    private var priorityValue: String {
        if let gift = entry.activeGiftName { return gift }
        if entry.hasGroupOrder { return "\(entry.groupOrderParticipantCount) \(localized("participants", "مشاركين"))" }
        if let status = entry.orderStatus { return status }
        return "\(entry.loyaltyPoints) Beans"
    }

    private var priorityDetail: String {
        if entry.hasActiveGift { return giftExpiryText }
        if entry.hasGroupOrder { return groupDeadlineText }
        if entry.orderStatus != nil { return localized("Tap to view status", "اضغط لعرض الحالة") }
        return entry.loyaltyNextReward
    }

    private var giftExpiryText: String {
        guard let expiry = entry.activeGiftExpiry else { return localized("Ready to redeem", "جاهزة للاستبدال") }
        let date = expiry.formatted(date: .abbreviated, time: .omitted)
        return localized("Expires \(date)", "تنتهي \(date)")
    }

    private var groupDeadlineText: String {
        guard let deadline = entry.groupOrderDeadline else { return localized("Open now", "مفتوح الآن") }
        let date = deadline.formatted(date: .abbreviated, time: .shortened)
        return localized("Closes \(date)", "يغلق \(date)")
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 9) {
            widgetHeader(iconSize: 28, titleSize: 16)

            VStack(alignment: .leading, spacing: 6) {
                if entry.hasActiveGift {
                    widgetStatusRow(title: localized("Gift", "هدية"), value: entry.activeGiftName!, detail: giftExpiryText, icon: "gift.fill", url: TallaWidgetDeepLinks.gifts)
                } else if entry.hasGroupOrder {
                    widgetStatusRow(title: localized("Group order", "طلب جماعي"), value: "\(entry.groupOrderParticipantCount) \(localized("participants", "مشاركين"))", detail: groupDeadlineText, icon: "person.3.fill", url: TallaWidgetDeepLinks.groupOrder)
                } else if let orderStatus = entry.orderStatus {
                    widgetStatusRow(title: entry.orderIsPickup ? localized("Pickup", "استلام") : localized("Order", "طلب"), value: orderStatus, detail: nil, icon: entry.orderIsPickup ? "storefront.fill" : "shippingbox.fill", url: TallaWidgetDeepLinks.orders)
                }
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

                Text(localized("Your coffee status, gifts, group orders, and shortcuts in one place.", "حالة قهوتك والهدايا والطلبات الجماعية والاختصارات في مكان واحد."))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                if entry.hasActiveGift || entry.hasGroupOrder || entry.orderStatus != nil {
                    priorityStatusCard
                }

                Spacer(minLength: 0)

                HStack(spacing: 7) {
                    statPill(title: localized("Shelf", "الرف"), value: entry.favoriteCount, icon: "books.vertical.fill")
                    statPill(title: localized("Recent", "الأخيرة"), value: entry.recentCount, icon: "clock.fill")
                    statPill(title: localized("Carts", "السلال"), value: entry.savedCartCount, icon: "cart.fill")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                if entry.hasActiveGift {
                    widgetLink(localized("Gift", "هدية"), systemImage: "gift.fill", url: TallaWidgetDeepLinks.gifts, highlighted: true)
                } else if entry.hasGroupOrder {
                    widgetLink(localized("Group order", "طلب جماعي"), systemImage: "person.3.fill", url: TallaWidgetDeepLinks.groupOrder, highlighted: true)
                } else if entry.orderStatus != nil {
                    widgetLink(entry.orderIsPickup ? localized("Pickup", "استلام") : localized("Order", "طلب"), systemImage: entry.orderIsPickup ? "storefront.fill" : "shippingbox.fill", url: TallaWidgetDeepLinks.orders, highlighted: true)
                }
                widgetLink(localized("Shelf", "الرف"), systemImage: "books.vertical.fill", url: TallaWidgetDeepLinks.shelf, highlighted: entry.hasShelf)
                widgetLink(localized("Shop", "المتجر"), systemImage: "bag.fill", url: TallaWidgetDeepLinks.shop, highlighted: false)
                widgetLink(localized("Concierge", "المرشد"), systemImage: "sparkles", url: TallaWidgetDeepLinks.concierge, highlighted: false)
                widgetLink(localized("Rewards", "المكافآت"), systemImage: "star.circle.fill", url: TallaWidgetDeepLinks.rewards, highlighted: false)
            }
            .frame(width: 116)
        }
        .padding(14)
    }

    private var priorityStatusCard: some View {
        Group {
            if entry.hasActiveGift {
                widgetStatusRow(title: localized("Active coffee gift", "هدية قهوة نشطة"), value: entry.activeGiftName!, detail: giftExpiryText, icon: "gift.fill", url: TallaWidgetDeepLinks.gifts)
            } else if entry.hasGroupOrder {
                widgetStatusRow(title: entry.groupOrderName ?? localized("Group order", "طلب جماعي"), value: "\(entry.groupOrderParticipantCount) \(localized("participants", "مشاركين"))", detail: groupDeadlineText, icon: "person.3.fill", url: TallaWidgetDeepLinks.groupOrder)
            } else if let orderStatus = entry.orderStatus {
                widgetStatusRow(title: entry.orderIsPickup ? localized("Pickup status", "حالة الاستلام") : localized("Order status", "حالة الطلب"), value: orderStatus, detail: nil, icon: entry.orderIsPickup ? "storefront.fill" : "shippingbox.fill", url: TallaWidgetDeepLinks.orders)
            }
        }
    }

    private func widgetStatusRow(title: String, value: String, detail: String?, icon: String, url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 13, weight: .black)).foregroundStyle(accentFill).frame(width: 20)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title).font(.system(size: 9, weight: .black)).foregroundStyle(secondaryForeground).textCase(.uppercase).lineLimit(1)
                    Text(value).font(.system(size: 12, weight: .black)).lineLimit(1)
                    if let detail { Text(detail).font(.system(size: 9, weight: .semibold)).foregroundStyle(secondaryForeground).lineLimit(1) }
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(panelFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
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
        .configurationDisplayName("Talla Coffee Status")
        .description("See an active coffee gift, group-order deadline, pickup status, and your Talla shortcuts.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
        .containerBackgroundRemovable(true)
    }
}

#if canImport(ActivityKit)
nonisolated struct TallaBrewActivityAttributes: ActivityAttributes, Sendable {
    nonisolated struct ContentState: Codable, Hashable, Sendable {
        let elapsedSeconds: Int
        let timerStartDate: Date
        let currentStep: String
        let nextStep: String
        let currentWaterGrams: Double
        let isPaused: Bool
        let stepTimes: [Int]
        let stepTitles: [String]
        let stepWaterTargets: [Double]
    }

    let methodName: String
    let coffeeGrams: Double
    let ratio: Double
    let totalWaterGrams: Double
    let totalSeconds: Int
    let languageCode: String
}

private func tallaBrewText(_ english: String, arabic: String, languageCode: String) -> String {
    languageCode == "ar" ? arabic : english
}

private enum TallaBrewActivityStyle {
    static let accent = Color(red: 0.78, green: 0.55, blue: 0.29)

    static var background: Color {
#if canImport(UIKit)
        Color(UIColor.systemBackground)
#else
        Color.primary.opacity(0.10)
#endif
    }

    static var primaryText: Color {
#if canImport(UIKit)
        Color(UIColor.label)
#else
        .primary
#endif
    }

    static var secondaryText: Color {
#if canImport(UIKit)
        Color(UIColor.secondaryLabel)
#else
        .secondary
#endif
    }

    static var iconForeground: Color {
#if canImport(UIKit)
        Color(UIColor.systemBackground)
#else
        .primary
#endif
    }
}

@available(iOS 16.1, *)
private struct TallaBrewActivitySnapshot {
    let elapsedSeconds: Int
    let currentStep: String
    let nextStep: String
    let currentWaterGrams: Double
}

@available(iOS 16.1, *)
private func tallaBrewActivitySnapshot(for context: ActivityViewContext<TallaBrewActivityAttributes>, at date: Date = Date()) -> TallaBrewActivitySnapshot {
    let elapsed = context.state.isPaused
        ? context.state.elapsedSeconds
        : min(
            context.attributes.totalSeconds,
            max(context.state.elapsedSeconds, Int(date.timeIntervalSince(context.state.timerStartDate)))
        )

    guard !context.state.stepTimes.isEmpty, context.state.stepTimes.count == context.state.stepTitles.count else {
        return TallaBrewActivitySnapshot(
            elapsedSeconds: elapsed,
            currentStep: elapsed >= context.attributes.totalSeconds ? "Brew complete" : context.state.currentStep,
            nextStep: elapsed >= context.attributes.totalSeconds ? "Ready to taste" : context.state.nextStep,
            currentWaterGrams: context.state.currentWaterGrams
        )
    }

    let currentIndex = context.state.stepTimes.lastIndex { elapsed >= $0 } ?? 0
    let nextIndex = context.state.stepTimes.firstIndex { elapsed < $0 }
    let waterTargets = context.state.stepWaterTargets
    let water = waterTargets
        .prefix(min(currentIndex + 1, waterTargets.count))
        .last { $0 >= 0 } ?? context.state.currentWaterGrams

    return TallaBrewActivitySnapshot(
        elapsedSeconds: elapsed,
        currentStep: elapsed >= context.attributes.totalSeconds ? "Brew complete" : context.state.stepTitles[currentIndex],
        nextStep: nextIndex.map { context.state.stepTitles[$0] } ?? "Ready to taste",
        currentWaterGrams: water
    )
}

@available(iOS 16.1, *)
struct TallaBrewLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TallaBrewActivityAttributes.self) { context in
            TallaBrewLockScreenView(context: context)
                .activityBackgroundTint(TallaBrewActivityStyle.background)
                .activitySystemActionForegroundColor(TallaBrewActivityStyle.accent)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.attributes.methodName)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                        Text(
                            tallaBrewText(
                                "\(Int(context.attributes.coffeeGrams.rounded())) g coffee",
                                arabic: "\(Int(context.attributes.coffeeGrams.rounded())) غ قهوة",
                                languageCode: context.attributes.languageCode
                            )
                        )
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    TimelineView(.periodic(from: context.state.timerStartDate, by: 1)) { timeline in
                        let snapshot = tallaBrewActivitySnapshot(for: context, at: timeline.date)
                        VStack(alignment: .trailing, spacing: 3) {
                            TallaBrewActivityTimer(context: context, font: .caption.weight(.black))
                            Text("\(Int(snapshot.currentWaterGrams.rounded())) / \(Int(context.attributes.totalWaterGrams.rounded())) g")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    TimelineView(.periodic(from: context.state.timerStartDate, by: 1)) { timeline in
                        let snapshot = tallaBrewActivitySnapshot(for: context, at: timeline.date)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(snapshot.currentStep)
                                .font(.headline.weight(.bold))
                                .lineLimit(1)
                            Text(
                                tallaBrewText(
                                    "Next: \(snapshot.nextStep)",
                                    arabic: "التالي: \(snapshot.nextStep)",
                                    languageCode: context.attributes.languageCode
                                )
                            )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            TallaBrewActivityProgress(context: context, currentDate: timeline.date)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "drop.fill")
                    .foregroundStyle(TallaBrewActivityStyle.accent)
            } compactTrailing: {
                TallaBrewActivityTimer(context: context, font: .caption2.weight(.bold))
                    .frame(maxWidth: 40)
            } minimal: {
                Image(systemName: "drop.fill")
                    .foregroundStyle(TallaBrewActivityStyle.accent)
            }
        }
    }
}

@available(iOS 16.1, *)
private struct TallaBrewLockScreenView: View {
    let context: ActivityViewContext<TallaBrewActivityAttributes>

    var body: some View {
        TimelineView(.periodic(from: context.state.timerStartDate, by: 1)) { timeline in
            let snapshot = tallaBrewActivitySnapshot(for: context, at: timeline.date)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(TallaBrewActivityStyle.iconForeground)
                        .frame(width: 34, height: 34)
                        .background(TallaBrewActivityStyle.accent, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(
                            tallaBrewText(
                                "Guided Brew",
                                arabic: "تحضير موجّه",
                                languageCode: context.attributes.languageCode
                            )
                        )
                            .font(.system(size: 11, weight: .black))
                            .tracking(1.4)
                            .textCase(.uppercase)
                            .foregroundStyle(TallaBrewActivityStyle.accent)

                        Text(context.attributes.methodName)
                            .font(.system(size: 19, weight: .heavy))
                            .foregroundStyle(TallaBrewActivityStyle.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }

                    Spacer(minLength: 8)

                    TallaBrewActivityTimer(context: context, font: .system(size: 24, weight: .heavy))
                        .foregroundStyle(TallaBrewActivityStyle.primaryText)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(snapshot.currentStep)
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundStyle(TallaBrewActivityStyle.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    HStack(spacing: 8) {
                        Text(
                            tallaBrewText(
                                "\(Int(snapshot.currentWaterGrams.rounded())) / \(Int(context.attributes.totalWaterGrams.rounded())) g water",
                                arabic: "\(Int(snapshot.currentWaterGrams.rounded())) / \(Int(context.attributes.totalWaterGrams.rounded())) غ ماء",
                                languageCode: context.attributes.languageCode
                            )
                        )
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(TallaBrewActivityStyle.secondaryText)
                            .lineLimit(1)

                        Circle()
                            .fill(TallaBrewActivityStyle.secondaryText.opacity(0.35))
                            .frame(width: 4, height: 4)

                        Text(
                            tallaBrewText(
                                "Next: \(snapshot.nextStep)",
                                arabic: "التالي: \(snapshot.nextStep)",
                                languageCode: context.attributes.languageCode
                            )
                        )
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(TallaBrewActivityStyle.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                }

                TallaBrewActivityProgress(context: context, currentDate: timeline.date)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
}

@available(iOS 16.1, *)
private struct TallaBrewActivityTimer: View {
    let context: ActivityViewContext<TallaBrewActivityAttributes>
    let font: Font

    var body: some View {
        Group {
            if context.state.isPaused {
                Text(formattedTime(context.state.elapsedSeconds))
            } else {
                Text(
                    timerInterval: context.state.timerStartDate...context.state.timerStartDate.addingTimeInterval(Double(context.attributes.totalSeconds)),
                    countsDown: false
                )
            }
        }
        .font(font)
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

@available(iOS 16.1, *)
private struct TallaBrewActivityProgress: View {
    let context: ActivityViewContext<TallaBrewActivityAttributes>
    var currentDate = Date()

    private var progress: Double {
        let elapsed = context.state.isPaused
            ? context.state.elapsedSeconds
            : max(context.state.elapsedSeconds, Int(currentDate.timeIntervalSince(context.state.timerStartDate)))
        return min(max(Double(elapsed) / Double(max(context.attributes.totalSeconds, 1)), 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous)
                    .fill(TallaBrewActivityStyle.accent.opacity(0.22))
                Capsule(style: .continuous)
                    .fill(TallaBrewActivityStyle.accent)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 6)
    }
}

/// Commerce updates share one activity so an order can move from confirmation to
/// pickup without dismissing and recreating the user's Live Activity.
@available(iOS 16.1, *)
nonisolated struct TallaCommerceActivityAttributes: ActivityAttributes, Sendable {
    enum Kind: String, Codable, Hashable, Sendable {
        case order
        case groupOrder
        case gift
    }

    nonisolated struct ContentState: Codable, Hashable, Sendable {
        let status: String
        let statusKey: String
        let progress: Double
        let deadline: Date?
        let detail: String?
    }

    let kind: Kind
    let referenceID: String
    let title: String
    let isPickup: Bool
    let languageCode: String
}

@available(iOS 16.1, *)
struct TallaCommerceLiveActivity: Widget {
    private let accent = Color(red: 0.78, green: 0.55, blue: 0.29)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TallaCommerceActivityAttributes.self) { context in
            TallaCommerceLockScreenView(context: context)
                .activityBackgroundTint(Color(.systemBackground))
                .activitySystemActionForegroundColor(accent)
                .widgetURL(URL(string: "talla://orders"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.attributes.title, systemImage: icon(for: context.attributes.kind))
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(status(for: context))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(accent)
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(detail(for: context))
                            .font(.headline.weight(.bold))
                            .lineLimit(1)
                        TallaCommerceProgress(progress: context.state.progress, accent: accent)
                    }
                }
            } compactLeading: {
                Image(systemName: icon(for: context.attributes.kind)).foregroundStyle(accent)
            } compactTrailing: {
                Text(status(for: context)).font(.caption2.weight(.bold)).lineLimit(1)
            } minimal: {
                Image(systemName: icon(for: context.attributes.kind)).foregroundStyle(accent)
            }
        }
    }

    private func icon(for kind: TallaCommerceActivityAttributes.Kind) -> String {
        switch kind {
        case .order: "bag.fill"
        case .groupOrder: "person.3.fill"
        case .gift: "gift.fill"
        }
    }

    private func status(for context: ActivityViewContext<TallaCommerceActivityAttributes>) -> String {
        guard context.attributes.languageCode == "ar" else { return context.state.status }
        switch context.state.statusKey {
        case "order_confirmed": return "تم تأكيد الطلب"
        case "preparing": return "قيد التحضير"
        case "ready_for_pickup": return "جاهز للاستلام"
        case "group_order_closing_soon": return "إغلاق الطلب قريباً"
        case "gift_ready_to_redeem": return "الهدية جاهزة للاستبدال"
        default: return context.state.status
        }
    }

    private func detail(for context: ActivityViewContext<TallaCommerceActivityAttributes>) -> String {
        guard context.attributes.languageCode == "ar" else { return context.state.detail ?? status(for: context) }
        switch context.state.statusKey {
        case "order_confirmed": return "استلمنا طلبك"
        case "preparing": return "يتم تحضير قهوتك الآن"
        case "ready_for_pickup": return "طلبك ينتظرك في تالا"
        case "group_order_closing_soon": return "انضم المزيد من الأشخاص قبل الإغلاق"
        case "gift_ready_to_redeem": return "أظهر الهدية عند الكاونتر"
        default: return context.state.detail ?? status(for: context)
        }
    }
}

@available(iOS 16.1, *)
private struct TallaCommerceLockScreenView: View {
    let context: ActivityViewContext<TallaCommerceActivityAttributes>
    private let accent = Color(red: 0.78, green: 0.55, blue: 0.29)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(Color(.systemBackground))
                    .frame(width: 34, height: 34)
                    .background(accent, in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 11, weight: .black))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(accent)
                    Text(context.attributes.title)
                        .font(.headline.weight(.heavy))
                        .lineLimit(1)
                }
                Spacer(minLength: 4)
                Text(status)
                    .font(.subheadline.weight(.bold))
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }

            Text(detail).font(.title3.weight(.heavy)).lineLimit(1)
            if let deadline = context.state.deadline {
                Text(timerInterval: Date()...deadline, countsDown: true)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            TallaCommerceProgress(progress: context.state.progress, accent: accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var icon: String {
        switch context.attributes.kind {
        case .order: "bag.fill"
        case .groupOrder: "person.3.fill"
        case .gift: "gift.fill"
        }
    }

    private var label: String {
        switch context.attributes.kind {
        case .order: context.attributes.languageCode == "ar" ? "استلام من تالا" : (context.attributes.isPickup ? "Talla Pickup" : "Talla Order")
        case .groupOrder: context.attributes.languageCode == "ar" ? "طلب جماعي" : "Group Order"
        case .gift: context.attributes.languageCode == "ar" ? "هدية قهوة" : "Coffee Gift"
        }
    }

    private var status: String {
        guard context.attributes.languageCode == "ar" else { return context.state.status }
        switch context.state.statusKey {
        case "order_confirmed": return "تم تأكيد الطلب"
        case "preparing": return "قيد التحضير"
        case "ready_for_pickup": return "جاهز للاستلام"
        case "group_order_closing_soon": return "إغلاق الطلب قريباً"
        case "gift_ready_to_redeem": return "الهدية جاهزة للاستبدال"
        default: return context.state.status
        }
    }

    private var detail: String {
        guard context.attributes.languageCode == "ar" else { return context.state.detail ?? status }
        switch context.state.statusKey {
        case "order_confirmed": return "استلمنا طلبك"
        case "preparing": return "يتم تحضير قهوتك الآن"
        case "ready_for_pickup": return "طلبك ينتظرك عند تالا"
        case "group_order_closing_soon": return "انضم المزيد من الأشخاص قبل الإغلاق"
        case "gift_ready_to_redeem": return "أظهر الهدية عند الكاونتر"
        default: return context.state.detail ?? status
        }
    }
}

@available(iOS 16.1, *)
private struct TallaCommerceProgress: View {
    let progress: Double
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(accent.opacity(0.22))
                Capsule().fill(accent).frame(width: proxy.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 6)
    }
}
#endif

@available(iOS 18.0, *)
struct TallaConciergeControl: ControlWidget {
    static let kind = "com.talla.speciality.concierge-control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenTallaConciergeIntent()) {
                Label("Concierge", systemImage: "sparkles")
                    .controlWidgetActionHint("Open Talla AI")
            }
        }
        .displayName("Talla AI")
        .description("Open Talla AI for coffee guidance from Control Center, the Lock Screen, or the Action Button.")
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
