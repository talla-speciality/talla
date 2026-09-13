import ActivityKit
import Foundation
import Testing
@testable import Talla_Speciality

struct BrewActivityCompatibilityTests {
    @Test func liveActivityPayloadRoundTripsOutsideMainActor() async throws {
        let payload = try await Task.detached {
            let attributes = TallaBrewActivityAttributes(
                methodName: "V60", coffeeGrams: 20, ratio: 16,
                totalWaterGrams: 320, totalSeconds: 180, languageCode: "ar"
            )
            let state = TallaBrewActivityAttributes.ContentState(
                elapsedSeconds: 30, timerStartDate: Date(timeIntervalSince1970: 1_000),
                currentStep: "Bloom", nextStep: "Pour", currentWaterGrams: 50,
                isPaused: false, stepTimes: [0, 45], stepTitles: ["Bloom", "Pour"],
                stepWaterTargets: [50, 320]
            )
            let encoder = JSONEncoder()
            let decoder = JSONDecoder()
            let decodedAttributes = try decoder.decode(
                TallaBrewActivityAttributes.self, from: encoder.encode(attributes)
            )
            let decodedState = try decoder.decode(
                TallaBrewActivityAttributes.ContentState.self, from: encoder.encode(state)
            )
            #expect(decodedState == state)
            return (decodedAttributes, decodedState)
        }.value

        #expect(payload.0.languageCode == "ar")
        #expect(payload.0.totalWaterGrams == 320)
        #expect(payload.1.stepWaterTargets == [50, 320])
    }
}
