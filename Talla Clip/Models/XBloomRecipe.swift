import Foundation

/// Portable recipe format for the community xbloom-ble client.
/// No machine commands are issued by this model.
struct XBloomRecipe: Codable {
    struct Pour: Codable {
        var ml: Int
        var temp_c: Int
        var pattern: String
        var agitation: Bool
        var pause_s: Int
        var rpm: Int
        var flow_ml_s: Double
    }
    var name: String
    var dose_g: Int
    var grind: Int
    var pours: [Pour]

    func validatedJSON() throws -> String {
        guard (1...18).contains(dose_g), (0...80).contains(grind),
              (2...5).contains(pours.count) else {
            throw ValidationError.invalid("Use a whole-number dose of 1–18 g, grind 0–80, and 2–5 pours.")
        }
        for pour in pours {
            guard (1...500).contains(pour.ml), (40...95).contains(pour.temp_c),
                  ["center", "ring", "spiral"].contains(pour.pattern),
                  !pour.agitation || pour.pattern == "spiral",
                  (0...99).contains(pour.pause_s),
                  (30...35).contains(pour.flow_ml_s * 10),
                  abs(pour.flow_ml_s * 10 - (pour.flow_ml_s * 10).rounded()) < 0.001,
                  pour.pattern == "center" ? pour.rpm == 0 : (60...120).contains(pour.rpm) && pour.rpm % 10 == 0 else {
                throw ValidationError.invalid("Check pour volume, temperature, pattern, agitation, pause, speed and flow.")
            }
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return String(decoding: try encoder.encode(self), as: UTF8.self)
    }

    enum ValidationError: LocalizedError {
        case invalid(String)
        var errorDescription: String? {
            switch self { case .invalid(let message): return message }
        }
    }
}
