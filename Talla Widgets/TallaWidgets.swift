#if canImport(WidgetKit) && canImport(AppIntents)
import AppIntents
import SwiftUI
import WidgetKit

struct TallaWidgetDeepLinks {
    static let shop = URL(string: "talla://shop")!
    static let concierge = URL(string: "talla://concierge")!
    static let brewing = URL(string: "talla://brewing")!
    static let rewards = URL(string: "talla://rewards")!
}

struct TallaQuickActionsEntry: TimelineEntry {
    let date: Date
    let beansText: String
    let nextAction: String
}

struct TallaQuickActionsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TallaQuickActionsEntry {
        TallaQuickActionsEntry(date: Date(), beansText: "Beans", nextAction: "Coffee Concierge")
    }

    func getSnapshot(in context: Context, completion: @escaping (TallaQuickActionsEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TallaQuickActionsEntry>) -> Void) {
        let entry = currentEntry()
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date().addingTimeInterval(14_400)
        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }

    private func currentEntry() -> TallaQuickActionsEntry {
        let defaults = UserDefaults.standard
        let loyaltyEmail = defaults.string(forKey: "loyalty.email") ?? ""
        let beansText = loyaltyEmail.isEmpty ? "Sign in for Beans" : "Rewards ready"
        return TallaQuickActionsEntry(date: Date(), beansText: beansText, nextAction: "Coffee Concierge")
    }
}

struct TallaQuickActionsWidgetView: View {
    let entry: TallaQuickActionsEntry
    @Environment(\.widgetFamily) private var widgetFamily

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
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
                    widgetLink("Shop", systemImage: "bag.fill", url: TallaWidgetDeepLinks.shop)
                    widgetLink("Concierge", systemImage: "sparkles", url: TallaWidgetDeepLinks.concierge)
                    widgetLink("Rewards", systemImage: "star.circle.fill", url: TallaWidgetDeepLinks.rewards)
                }
            } else {
                Link(destination: TallaWidgetDeepLinks.concierge) {
                    Label(entry.nextAction, systemImage: "sparkles")
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
        .widgetURL(TallaWidgetDeepLinks.shop)
    }

    private func widgetLink(_ title: String, systemImage: String, url: URL) -> some View {
        Link(destination: url) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 11, weight: .bold))
                .labelStyle(.iconOnly)
                .frame(maxWidth: .infinity, minHeight: 34)
                .background(Color.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}

struct TallaQuickActionsWidget: Widget {
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
