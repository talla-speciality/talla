import Foundation
import Combine

struct DecentDE1MachineSnapshot: Codable, Equatable {
    var timestamp: String?
    var state: DecentDE1State?
    var flow: Double?
    var pressure: Double?
    var mixTemperature: Double?
    var groupTemperature: Double?
    var targetFlow: Double?
    var targetPressure: Double?
    var targetMixTemperature: Double?
    var targetGroupTemperature: Double?
}

struct DecentDE1State: Codable, Equatable {
    var state: String?
    var substate: String?
}

@MainActor
final class DecentDE1ReadOnlyClient: ObservableObject {
    @Published private(set) var snapshot: DecentDE1MachineSnapshot?
    @Published private(set) var isMonitoring = false
    @Published private(set) var errorMessage: String?

    private var pollingTask: Task<Void, Never>?

    deinit { pollingTask?.cancel() }

    func startMonitoring(baseURL: URL) {
        stopMonitoring()
        let normalized = baseURL.absoluteString.hasSuffix("/") ? baseURL : baseURL.appending(path: "")
        pollingTask = Task { [weak self] in
            guard let self else { return }
            isMonitoring = true
            defer { isMonitoring = false }
            while !Task.isCancelled {
                do {
                    var request = URLRequest(url: normalized.appending(path: "api/v1/machine/state"))
                    request.timeoutInterval = 5
                    let (data, response) = try await URLSession.shared.data(for: request)
                    guard let http = response as? HTTPURLResponse, 200 ..< 300 ~= http.statusCode else {
                        throw URLError(.badServerResponse)
                    }
                    snapshot = try JSONDecoder().decode(DecentDE1MachineSnapshot.self, from: data)
                    errorMessage = nil
                } catch is CancellationError {
                    break
                } catch {
                    errorMessage = "Decent monitor unavailable. Check the local gateway address."
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }

    func stopMonitoring() {
        pollingTask?.cancel()
        pollingTask = nil
        isMonitoring = false
    }
}
