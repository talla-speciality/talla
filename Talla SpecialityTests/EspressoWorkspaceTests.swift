import Foundation
import Testing
@testable import Talla_Speciality

struct EspressoWorkspaceTests {
    @Test func espressoRatioUsesDoseAndYield() {
        var shot = EspressoShot()
        shot.dose = 18
        shot.yield = 40
        #expect(abs(shot.ratio - (40.0 / 18.0)) < 0.001)
    }

    @Test func positiveEspressoRequiresFourOrFiveStars() {
        var shot = EspressoShot()
        shot.rating = 3
        #expect(!shot.isPositive)
        shot.rating = 4
        #expect(shot.isPositive)
    }

    @Test func espressoDefaultsMatchBaseRecipe() {
        let shot = EspressoShot()
        #expect(shot.dose == 18)
        #expect(shot.yield == 36)
        #expect(shot.temperature == 93)
        #expect(shot.firstDripSeconds == 8)
    }

    @Test func extractionYieldUsesDoseBeverageMassAndTDS() {
        let extraction = EspressoExtractionMath.extractionYieldPercent(
            doseGrams: 18,
            beverageYieldGrams: 36,
            tdsPercent: 9
        )
        #expect(extraction == 18)
    }

    @Test func extractionYieldRejectsInvalidMeasurements() {
        #expect(EspressoExtractionMath.extractionYieldPercent(doseGrams: 0, beverageYieldGrams: 36, tdsPercent: 9) == nil)
        #expect(EspressoExtractionMath.extractionYieldPercent(doseGrams: 18, beverageYieldGrams: 36, tdsPercent: -1) == nil)
    }

    @Test func referenceOverlaySeparatesAndSortsSensorStreams() {
        let samples = [
            EspressoTelemetrySample(elapsedSeconds: 2, kind: .flow, value: 1.8),
            EspressoTelemetrySample(elapsedSeconds: 1, kind: .pressure, value: 8.5),
            EspressoTelemetrySample(elapsedSeconds: 3, kind: .temperature, value: 92),
            EspressoTelemetrySample(elapsedSeconds: 0, kind: .pressure, value: 2)
        ]
        let overlay = EspressoReferenceOverlay(samples: samples)
        #expect(overlay.pressure.map(\.elapsedSeconds) == [0, 1])
        #expect(overlay.flow.count == 1)
        #expect(overlay.temperature.first?.value == 92)
    }

    @Test func machineControlIsExplicitlyCapabilityGated() {
        let readOnly = EspressoMachineIntegration.examples[0]
        let controlled = EspressoMachineIntegration.catalog.first(where: { $0.id == "linea-mini" })!
        #expect(readOnly.accessMode == .readOnly)
        #expect(controlled.accessMode == .officialControl)
        #expect(readOnly.supportedStreams.contains(.flow))
        #expect(EspressoMachineIntegration.catalog.contains { $0.id == "decent-de1" && $0.supportedStreams.contains(.pressure) })
        #expect(EspressoMachineIntegration.catalog.contains { $0.id == "home-connect-coffee" && $0.supportLevel == .officialCloudAPI })
        #expect(!EspressoMachineControlPolicy.allows(.startShot, integration: controlled, adapter: nil))
        let adapter = EspressoMachineAdapterDescriptor(id: "approved", integrationID: controlled.id, officialApprovalReference: "vendor-ticket-1", allowsControl: true)
        #expect(EspressoMachineControlPolicy.allows(.startShot, integration: controlled, adapter: adapter))
    }
}
