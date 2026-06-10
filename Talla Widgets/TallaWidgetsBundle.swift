#if canImport(WidgetKit) && canImport(AppIntents)
import AppIntents
import SwiftUI
import WidgetKit

private enum TallaWidgetDestination {
    static let destinationKey = "shortcut.destination"
    static let searchQueryKey = "shortcut.searchQuery"

    static func open(_ destination: String) {
        let defaults = UserDefaults.standard
        defaults.set("", forKey: searchQueryKey)
        defaults.set(destination, forKey: destinationKey)
    }
}

private struct OpenTallaShopFromWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Talla Shop"
    static let description = IntentDescription("Opens Talla Speciality to the shop.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        TallaWidgetDestination.open("shop")
        return .result()
    }
}

private struct OpenTallaConciergeFromWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Coffee Concierge"
    static let description = IntentDescription("Opens the Coffee Concierge in Talla Speciality.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        TallaWidgetDestination.open("concierge")
        return .result()
    }
}

private struct OpenTallaRewardsFromWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Talla Rewards"
    static let description = IntentDescription("Opens Talla Speciality to account rewards.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        TallaWidgetDestination.open("rewards")
        return .result()
    }
}

private struct TallaQuickActionsEntry: TimelineEntry {
    let date: Date
    let beansText: String
}

private struct TallaQuickActionsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TallaQuickActionsEntry {
        TallaQuickActionsEntry(date: Date(), beansText: "Beans")
    }

    func getSnapshot(in context: Context, completion: @escaping (TallaQuickActionsEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TallaQuickActionsEntry>) -> Void) {
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date().addingTimeInterval(14_400)
        completion(Timeline(entries: [currentEntry()], policy: .after(refreshDate)))
    }

    private func currentEntry() -> TallaQuickActionsEntry {
        let loyaltyEmail = UserDefaults.standard.string(forKey: "loyalty.email") ?? ""
        return TallaQuickActionsEntry(
            date: Date(),
            beansText: loyaltyEmail.isEmpty ? "Sign in for Beans" : "Rewards ready"
        )
    }
}

private struct TallaQuickActionsWidgetView: View {
    let entry: TallaQuickActionsEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 20, weight: .bold))
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("TALLA")
                        .font(.system(size: 15, weight: .black, design: .serif))
                    Text(entry.beansText)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            if widgetFamily == .systemMedium {
                HStack(spacing: 8) {
                    widgetButton(title: "Shop", systemImage: "bag.fill", action: OpenTallaShopFromWidgetIntent())
                    widgetButton(title: "Concierge", systemImage: "sparkles", action: OpenTallaConciergeFromWidgetIntent())
                    widgetButton(title: "Rewards", systemImage: "star.circle.fill", action: OpenTallaRewardsFromWidgetIntent())
                }
            } else {
                Button(intent: OpenTallaConciergeFromWidgetIntent()) {
                    Label("Concierge", systemImage: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(red: 0.12, green: 0.08, blue: 0.04), Color(red: 0.42, green: 0.29, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .foregroundStyle(Color(red: 0.97, green: 0.89, blue: 0.76))
    }

    private func widgetButton<I: AppIntent>(title: String, systemImage: String, action: I) -> some View {
        Button(intent: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11, weight: .bold))
                .labelStyle(.iconOnly)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

private struct TallaQuickActionsWidget: Widget {
    static let kind = "com.talla.speciality.quick-actions"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: TallaQuickActionsProvider()) { entry in
            TallaQuickActionsWidgetView(entry: entry)
        }
        .configurationDisplayName("Talla Quick Actions")
        .description("Open the shop, Coffee Concierge, and rewards quickly.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@available(iOS 18.0, *)
private struct TallaConciergeControl: ControlWidget {
    static let kind = "com.talla.speciality.concierge-control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenTallaConciergeFromWidgetIntent()) {
                Label("Concierge", systemImage: "sparkles")
                    .controlWidgetActionHint("Open Coffee Concierge")
            }
        }
        .displayName("Coffee Concierge")
        .description("Open Talla Coffee Concierge from Control Center, the Lock Screen, or the Action Button.")
    }
}

@available(iOS 18.0, *)
private struct TallaShopControl: ControlWidget {
    static let kind = "com.talla.speciality.shop-control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: OpenTallaShopFromWidgetIntent()) {
                Label("Shop", systemImage: "bag.fill")
                    .controlWidgetActionHint("Open Talla Shop")
            }
        }
        .displayName("Talla Shop")
        .description("Open the Talla shop from Control Center, the Lock Screen, or the Action Button.")
    }
}

@main
struct TallaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TallaQuickActionsWidget()

        if #available(iOS 18.0, *) {
            TallaConciergeControl()
            TallaShopControl()
        }
    }
}
#endif
