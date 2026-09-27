import Foundation
import HealthKit

/// Writes estimated caffeine from completed Talla brews to Apple Health.
/// Caffeine is intentionally stored as an estimate because a brew recipe does
/// not provide a laboratory measurement of the caffeine extracted.
@MainActor
final class TallaHealthKitService {
    static let shared = TallaHealthKitService()

    private let healthStore = HKHealthStore()
    private let caffeineType = HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!
    private let processedPrefix = "talla.healthkit.caffeine.recorded."

    private init() {}

    func saveEstimatedCaffeine(
        forBrewID brewID: UUID,
        milligrams: Double,
        date: Date,
        title: String
    ) async {
        guard HKHealthStore.isHealthDataAvailable(), milligrams.isFinite, milligrams > 0 else { return }

        let processedKey = processedPrefix + brewID.uuidString.lowercased()
        guard !UserDefaults.standard.bool(forKey: processedKey) else { return }

        do {
            try await healthStore.requestAuthorization(toShare: [caffeineType], read: [])

            let quantity = HKQuantity(unit: .gramUnit(with: .milli), doubleValue: milligrams)
            let sample = HKQuantitySample(
                type: caffeineType,
                quantity: quantity,
                start: date,
                end: date,
                metadata: [
                    HKMetadataKeyExternalUUID: brewID.uuidString,
                    HKMetadataKeyWasUserEntered: false,
                    HKMetadataKeySyncIdentifier: "talla-caffeine-\(brewID.uuidString.lowercased())",
                    HKMetadataKeySyncVersion: 1,
                    HKMetadataKeyFoodType: title
                ]
            )
            try await healthStore.save(sample)
            UserDefaults.standard.set(true, forKey: processedKey)
        } catch {
            // Health permissions and HealthKit availability are user-controlled.
            // A failed write must never prevent the brew from being saved.
        }
    }
}

enum TallaCaffeineEstimator {
    /// Returns an estimated caffeine amount in milligrams.
    /// The estimate is based on dose and brew style, not a clinical measurement.
    static func estimate(milligramsForDoseGrams dose: Double?, method: String) -> Double? {
        guard let dose, dose.isFinite, dose > 0 else { return nil }

        let normalized = method.lowercased()
        let milligramsPerGram: Double
        if normalized.contains("espresso") {
            milligramsPerGram = 6.5
        } else if normalized.contains("french") || normalized.contains("immersion") || normalized.contains("cold") {
            milligramsPerGram = 9.0
        } else {
            milligramsPerGram = 10.0
        }

        return (dose * milligramsPerGram).rounded()
    }
}
