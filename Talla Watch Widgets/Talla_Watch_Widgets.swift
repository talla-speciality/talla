import SwiftUI
import WidgetKit

private enum TallaWatchWidgetSharedState {
    static let appGroupID = "group.Talla-Speciality.Talla-Speciality"
    static let loyaltyEmailKey = "loyalty.email"
    static let favoriteCountKey = "widget.favoriteCount"
    static let recentCountKey = "widget.recentCount"
    static let savedCartCountKey = "widget.savedCartCount"
    static let loyaltyPointsKey = "watch.loyalty.points"
    static let loyaltyTierKey = "watch.loyalty.tier"
    static let loyaltyNextRewardKey = "watch.loyalty.nextReward"
    static let lastUpdatedKey = "widget.lastUpdated"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}

struct TallaWatchWidgetEntry: TimelineEntry {
    let date: Date
    let points: Int
    let tier: String
    let nextReward: String
    let isSignedIn: Bool
    let favoriteCount: Int
    let recentCount: Int
    let savedCartCount: Int

    var progress: Double {
        Double(points % 50) / 50
    }

    var beansToNextReward: Int {
        let remainder = points % 50
        return remainder == 0 && points > 0 ? 0 : 50 - remainder
    }
}

struct TallaWatchWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TallaWatchWidgetEntry {
        TallaWatchWidgetEntry(
            date: Date(),
            points: 72,
            tier: "Reserve",
            nextReward: "28 Beans to your next reward",
            isSignedIn: true,
            favoriteCount: 3,
            recentCount: 5,
            savedCartCount: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TallaWatchWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TallaWatchWidgetEntry>) -> Void) {
        let entry = currentEntry()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1_800)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func currentEntry() -> TallaWatchWidgetEntry {
        let defaults = TallaWatchWidgetSharedState.defaults
        let email = defaults.string(forKey: TallaWatchWidgetSharedState.loyaltyEmailKey) ?? ""
        let lastUpdated = defaults.double(forKey: TallaWatchWidgetSharedState.lastUpdatedKey)

        return TallaWatchWidgetEntry(
            date: lastUpdated > 0 ? Date(timeIntervalSince1970: lastUpdated) : Date(),
            points: defaults.integer(forKey: TallaWatchWidgetSharedState.loyaltyPointsKey),
            tier: defaults.string(forKey: TallaWatchWidgetSharedState.loyaltyTierKey) ?? "Reserve",
            nextReward: defaults.string(forKey: TallaWatchWidgetSharedState.loyaltyNextRewardKey) ?? "Open Talla on your iPhone",
            isSignedIn: !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            favoriteCount: defaults.integer(forKey: TallaWatchWidgetSharedState.favoriteCountKey),
            recentCount: defaults.integer(forKey: TallaWatchWidgetSharedState.recentCountKey),
            savedCartCount: defaults.integer(forKey: TallaWatchWidgetSharedState.savedCartCountKey)
        )
    }
}

struct TallaWatchWidgetsEntryView: View {
    let entry: TallaWatchWidgetEntry
    @Environment(\.widgetFamily) private var widgetFamily

    private let accent = Color(red: 0.79, green: 0.59, blue: 0.35)

    var body: some View {
        Group {
            switch widgetFamily {
            case .accessoryCircular:
                circularComplication
            case .accessoryInline:
                inlineComplication
#if os(watchOS)
            case .accessoryCorner:
                if #available(watchOSApplicationExtension 9.0, *) {
                    cornerComplication
                } else {
                    circularComplication
                }
#endif
            default:
                rectangularComplication
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
        .widgetURL(URL(string: "talla://rewards"))
    }

    private var circularComplication: some View {
        Gauge(value: entry.isSignedIn ? entry.progress : 0) {
            Image(systemName: "cup.and.saucer.fill")
        } currentValueLabel: {
            Text(entry.isSignedIn ? "\(entry.points)" : "T")
                .font(.system(size: 15, weight: .black, design: .serif))
                .minimumScaleFactor(0.55)
        }
        .gaugeStyle(.accessoryCircular)
        .tint(accent)
    }

    private var rectangularComplication: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Image(systemName: "cup.and.saucer.fill")
                Text("TALLA")
                    .font(.system(size: 11, weight: .black, design: .serif))
                Spacer(minLength: 0)
                Text(entry.isSignedIn ? entry.tier : "Connect")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .foregroundStyle(accent)

            Text(entry.isSignedIn ? "\(entry.points) Beans" : "Connect Talla")
                .font(.system(size: 15, weight: .black))
                .lineLimit(1)

            Text(entry.isSignedIn ? rewardLine : "Open on iPhone")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var inlineComplication: some View {
        Label(entry.isSignedIn ? "\(entry.points) Beans" : "Connect Talla", systemImage: "cup.and.saucer.fill")
    }

#if os(watchOS)
    @available(watchOSApplicationExtension 9.0, *)
    private var cornerComplication: some View {
        Text(entry.isSignedIn ? "\(entry.points)" : "T")
            .font(.system(size: 12, weight: .black, design: .serif))
            .widgetCurvesContent()
            .widgetLabel {
                Gauge(value: entry.isSignedIn ? entry.progress : 0) {
                    Text(entry.isSignedIn ? "Beans" : "Open")
                }
                .tint(accent)
            }
    }
#endif

    private var rewardLine: String {
        entry.beansToNextReward == 0 ? "Reward ready" : "\(entry.beansToNextReward) Beans to your next reward"
    }
}

struct Talla_Watch_Widgets: Widget {
    let kind = "com.talla.speciality.watch-rewards"

    private var supportedWatchFamilies: [WidgetFamily] {
        var families: [WidgetFamily] = [.accessoryCircular, .accessoryRectangular, .accessoryInline]
#if os(watchOS)
        if #available(watchOSApplicationExtension 9.0, *) {
            families.append(.accessoryCorner)
        }
#endif
        return families
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TallaWatchWidgetProvider()) { entry in
            TallaWatchWidgetsEntryView(entry: entry)
        }
        .configurationDisplayName("The Talla Club")
        .description("Beans, rewards, and saved shelf counts for Apple Watch.")
        .supportedFamilies(supportedWatchFamilies)
    }
}

#Preview(as: .accessoryRectangular) {
    Talla_Watch_Widgets()
} timeline: {
    TallaWatchWidgetEntry(
        date: .now,
        points: 72,
        tier: "Reserve",
        nextReward: "28 Beans to your next reward",
        isSignedIn: true,
        favoriteCount: 3,
        recentCount: 5,
        savedCartCount: 1
    )
}
