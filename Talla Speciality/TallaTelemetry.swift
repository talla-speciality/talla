import Foundation
#if canImport(MetricKit)
import MetricKit
#endif

@MainActor
final class TallaTelemetry: NSObject {
    static let shared = TallaTelemetry()

    private struct Event: Codable {
        let id: String
        let eventName: String
        let category: String
        let platform: String
        let anonymousId: String
        let sessionId: String
        let appVersion: String
        let occurredAt: String
        let properties: [String: String]
    }

    private let queueKey = "telemetry.pending.v1"
    private let installKey = "telemetry.installID"
    private let activeLaunchKey = "telemetry.activeLaunch"
    private let retentionDayKey = "telemetry.retentionDay"
    private let sessionID = UUID().uuidString
    private let launchStartedAt = ProcessInfo.processInfo.systemUptime
    private var isSending = false

    func start() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: activeLaunchKey) {
            track("crash_detected", category: "crash", properties: ["source": "unclean_foreground_exit"])
        }
        defaults.set(true, forKey: activeLaunchKey)
        track("app_opened")

        let day = Calendar(identifier: .gregorian).startOfDay(for: Date()).timeIntervalSince1970
        if defaults.double(forKey: retentionDayKey) != day {
            defaults.set(day, forKey: retentionDayKey)
            track("retention_active", properties: ["day": String(Int(day / 86_400))])
        }

#if canImport(MetricKit)
        if #available(iOS 13.0, *) { MXMetricManager.shared.add(self) }
#endif
        flush()
    }

    func appReady() {
        let milliseconds = Int((ProcessInfo.processInfo.systemUptime - launchStartedAt) * 1_000)
        track("app_launch_performance", category: "performance", properties: ["duration_ms": String(max(0, milliseconds))])
    }

    func enteredBackground() {
        UserDefaults.standard.set(false, forKey: activeLaunchKey)
        flush()
    }

    func track(_ name: String, category: String = "analytics", properties: [String: String] = [:]) {
        var queue = loadQueue()
        queue.append(Event(
            id: UUID().uuidString,
            eventName: name,
            category: category,
            platform: "ios",
            anonymousId: installID,
            sessionId: sessionID,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            occurredAt: ISO8601DateFormatter().string(from: Date()),
            properties: properties
        ))
        saveQueue(Array(queue.suffix(200)))
        flush()
    }

    private var installID: String {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: installKey), !existing.isEmpty { return existing }
        let created = UUID().uuidString
        defaults.set(created, forKey: installKey)
        return created
    }

    private func loadQueue() -> [Event] {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else { return [] }
        return (try? JSONDecoder().decode([Event].self, from: data)) ?? []
    }

    private func saveQueue(_ events: [Event]) {
        UserDefaults.standard.set(try? JSONEncoder().encode(events), forKey: queueKey)
    }

    private func flush() {
        guard !isSending, let baseURL = BackendConfiguration.serviceBaseURL else { return }
        let queued = Array(loadQueue().prefix(50))
        guard !queued.isEmpty else { return }
        isSending = true
        Task {
            defer { isSending = false }
            do {
                var request = URLRequest(url: baseURL.appending(path: "/telemetry/events"))
                request.httpMethod = "POST"
                request.timeoutInterval = 15
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(["events": queued])
                let (_, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else { return }
                let sentIDs = Set(queued.map(\.id))
                saveQueue(loadQueue().filter { !sentIDs.contains($0.id) })
                if !loadQueue().isEmpty { flush() }
            } catch {
                // The bounded queue remains on-device and retries on the next event or launch.
            }
        }
    }
}

#if canImport(MetricKit)
@available(iOS 13.0, *)
extension TallaTelemetry: MXMetricManagerSubscriber {
    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        Task { @MainActor in
            for payload in payloads {
                TallaTelemetry.shared.track(
                    "metric_kit_performance",
                    category: "performance",
                    properties: ["payload_bytes": String(payload.jsonRepresentation().count)]
                )
            }
        }
    }

    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        Task { @MainActor in
            for payload in payloads {
                TallaTelemetry.shared.track("metric_kit_diagnostic", category: "crash", properties: [
                    "crashes": String(payload.crashDiagnostics?.count ?? 0),
                    "hangs": String(payload.hangDiagnostics?.count ?? 0),
                    "cpu_exceptions": String(payload.cpuExceptionDiagnostics?.count ?? 0),
                    "disk_exceptions": String(payload.diskWriteExceptionDiagnostics?.count ?? 0)
                ])
            }
        }
    }
}
#endif
