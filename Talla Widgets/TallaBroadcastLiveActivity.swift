#if canImport(ActivityKit) && canImport(WidgetKit)
import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct TallaBroadcastAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var title: String
        var message: String
        var detail: String
    }

    var channelID: String
    var startedAt: String
}

@available(iOS 16.1, *)
struct TallaBroadcastLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TallaBroadcastAttributes.self) { context in
            TallaBroadcastLiveActivityView(
                title: context.state.title,
                message: context.state.message,
                detail: context.state.detail
            )
            .activityBackgroundTint(Color(hex: 0x0F0B07))
            .activitySystemActionForegroundColor(Color(hex: 0xC8965A))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Talla", systemImage: "cup.and.saucer.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: 0xC8965A))
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.message)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        Text(context.state.detail)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } compactLeading: {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(Color(hex: 0xC8965A))
            } compactTrailing: {
                Text("Live")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "cup.and.saucer.fill")
                    .foregroundStyle(Color(hex: 0xC8965A))
            }
            .keylineTint(Color(hex: 0xC8965A))
        }
    }
}

@available(iOS 16.1, *)
private struct TallaBroadcastLiveActivityView: View {
    let title: String
    let message: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: 0xC8965A))
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(Color(hex: 0xC8965A))
                    .lineLimit(1)

                Text(message)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
#endif
