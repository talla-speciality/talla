import Foundation

struct SmartBrewStep: Codable, Equatable, Identifiable {
    let id: Int
    let title: String
    let waterAdded: Int?
    let cumulativeWater: Int?
    let startTime: Int
    let flowRate: String
    let instruction: String
}

struct SmartBrewInput: Equatable {
    let coffeeGrams: Double
    let ratio: Double
    let brewerID: String
    let brewMode: String
    let roast: String
    let process: String
    let tasteGoal: String
    let altitudeMeters: Int?
    let daysOffRoast: Int?
    let grinder: String
    let bloomPreference: String
    let requestedPourCount: Int
    let controlMode: String
}

struct SmartBrewRecipe: Equatable {
    let totalWaterGrams: Double
    let brewingWaterGrams: Double
    let iceGrams: Double
    let bloomWaterGrams: Double
    let bloomDurationSeconds: Int
    let grindDescription: String
    let grindMicrons: Int
    let grinderSetting: String
    let temperatureC: Int
    let temperatureRange: String
    let temperatureReason: String
    let agitation: String
    let targetTimeRange: String
    let expectedBeverageGrams: Double
    let expectedCup: String
    let approach: String
    let steps: [SmartBrewStep]
}

enum SmartBrewRecipeEngine {
    static func generate(_ input: SmartBrewInput) -> SmartBrewRecipe {
        let dose = min(max(input.coffeeGrams, 5), 100)
        let ratio = min(max(input.ratio, 10), 20)
        let total = dose * ratio
        let iced = input.brewMode.localizedCaseInsensitiveContains("iced")
        let cold = input.brewerID == "cold"
        let ice = iced ? total * 0.4 : 0
        let brewingWater = total - ice
        let process = processFamily(input.process)
        let goal = input.tasteGoal.lowercased()
        let roast = input.roast.lowercased()

        let bloomMultiplier: Double
        switch input.bloomPreference {
        case "1:2": bloomMultiplier = 2
        case "1:2.5": bloomMultiplier = 2.5
        case "1:3": bloomMultiplier = 3
        default: bloomMultiplier = process.isSensitive ? 2.25 : 2.5
        }
        let bloom = cold ? 0 : min(dose * bloomMultiplier, brewingWater * 0.4)
        let bloomDuration = cold ? 0 : bloomSeconds(process: process, roast: roast, daysOffRoast: input.daysOffRoast)

        var temperature = roast.contains("dark") ? 89 : roast.contains("light") ? 94 : 92
        if process.isSensitive { temperature -= 1 }
        if let altitude = input.altitudeMeters, altitude >= 1_800 { temperature += 1 }
        if let days = input.daysOffRoast, days < 8 { temperature -= 1 }
        if goal.contains("clar") || goal.contains("bright") || goal.contains("acid") { temperature += 1 }
        if goal.contains("body") || goal.contains("rich") { temperature -= 1 }
        if iced && !process.isSensitive { temperature += 1 }
        temperature = min(max(temperature, 88), 96)

        let geometry = brewerGeometry(input.brewerID)
        var microns = baseMicrons(for: input.brewerID)
        if dose > 24 { microns += 45 }
        if dose < 15 { microns -= 30 }
        if goal.contains("body") || goal.contains("sweet") || goal.contains("rich") { microns -= 30 }
        if goal.contains("clar") || goal.contains("bright") { microns += 25 }
        if process.isSensitive { microns += 25 }
        microns = min(max(microns, 350), 1_100)

        let grind = grindLabel(microns: microns, brewerID: input.brewerID)
        let agitation = process.isSensitive || goal.contains("clar") || goal.contains("bright") ? "Gentle" : (goal.contains("body") || goal.contains("rich") ? "Medium-high" : "Medium")
        let steps = makeSteps(
            dose: dose,
            total: total,
            brewingWater: brewingWater,
            ice: ice,
            bloom: bloom,
            bloomDuration: bloomDuration,
            temperature: temperature,
            geometry: geometry,
            brewerID: input.brewerID,
            requestedPourCount: input.requestedPourCount,
            process: process,
            agitation: agitation
        )
        let end = steps.last?.startTime ?? 180
        let target = cold ? "12–16 hr" : timeRange(around: end, brewerID: input.brewerID)
        let retention = cold ? 0 : dose * 2.1
        let expected = iced ? total : max(total - retention, 1)

        return SmartBrewRecipe(
            totalWaterGrams: total,
            brewingWaterGrams: brewingWater,
            iceGrams: ice,
            bloomWaterGrams: bloom,
            bloomDurationSeconds: bloomDuration,
            grindDescription: grind,
            grindMicrons: microns,
            grinderSetting: grinderSetting(grinder: input.grinder, microns: microns),
            temperatureC: cold ? 20 : temperature,
            temperatureRange: cold ? "Room temperature" : "\(max(temperature - 1, 88))–\(min(temperature + 1, 96)) °C",
            temperatureReason: temperatureReason(roast: roast, process: process, iced: iced),
            agitation: agitation,
            targetTimeRange: target,
            expectedBeverageGrams: expected,
            expectedCup: expectedCup(goal: goal, process: process),
            approach: approach(process: process, geometry: geometry),
            steps: steps
        )
    }

    private enum ProcessFamily {
        case washed, natural, honey, anaerobic, extended, carbonic, coferment, decaf, other
        var isSensitive: Bool {
            switch self { case .natural, .honey, .anaerobic, .extended, .carbonic, .coferment, .decaf: true; default: false }
        }
    }

    private enum Geometry { case cone, flat, immersion, espresso, cold }

    private static func processFamily(_ value: String) -> ProcessFamily {
        let p = value.lowercased()
        if p.contains("decaf") { return .decaf }
        if p.contains("co-ferment") || p.contains("coferment") || p.contains("fruit fermentation") { return .coferment }
        if p.contains("carbonic") { return .carbonic }
        if p.contains("extended") { return .extended }
        if p.contains("anaerobic") || p.contains("ferment") || p.contains("thermal") || p.contains("koji") { return .anaerobic }
        if p.contains("honey") || p.contains("pulped") { return .honey }
        if p.contains("natural") { return .natural }
        if p.contains("washed") { return .washed }
        return .other
    }

    private static func brewerGeometry(_ id: String) -> Geometry {
        switch id {
        case "kalita", "orea", "flat": return .flat
        case "aeropress", "french-press", "arabic": return .immersion
        case "espresso": return .espresso
        case "cold": return .cold
        default: return .cone
        }
    }

    private static func bloomSeconds(process: ProcessFamily, roast: String, daysOffRoast: Int?) -> Int {
        var value: Int
        switch process {
        case .washed: value = 45
        case .natural, .decaf: value = 34
        case .honey, .carbonic: value = 30
        case .anaerobic, .extended, .coferment: value = 28
        case .other: value = 40
        }
        if roast.contains("dark") { value -= 5 }
        if let daysOffRoast, daysOffRoast < 8 { value += 8 }
        return min(max(value, 24), 60)
    }

    private static func baseMicrons(for brewerID: String) -> Int {
        switch brewerID {
        case "espresso": return 350
        case "aeropress": return 600
        case "french-press", "cold": return 1_000
        case "chemex": return 850
        case "kalita", "orea", "flat": return 720
        default: return 650
        }
    }

    private static func grindLabel(microns: Int, brewerID: String) -> String {
        if brewerID == "espresso" { return "Fine" }
        if microns < 550 { return "Medium-fine" }
        if microns < 700 { return "Medium-fine" }
        if microns < 850 { return "Medium" }
        if microns < 975 { return "Medium-coarse" }
        return "Coarse"
    }

    private static func grinderSetting(grinder: String, microns: Int) -> String {
        let g = grinder.lowercased()
        if g.contains("ode") { return String(format: "Ode %.1f · about %d μm", min(max(Double(microns - 300) / 75, 1), 11), microns) }
        if g.contains("comandante") || g.contains("c40") { return "C40 \(min(max(Int((Double(microns) - 250) / 22), 12), 40)) clicks · about \(microns) μm" }
        if g.contains("zp6") { return String(format: "ZP6 %.1f · about %d μm", min(max(Double(microns - 250) / 100, 2), 7), microns) }
        if g.contains("k-ultra") || g.contains("kultra") { return String(format: "K-Ultra %.1f · about %d μm", min(max(Double(microns - 250) / 100, 3), 10), microns) }
        if g.contains("timemore") || g.contains("c3") { return "Timemore \(min(max(Int(Double(microns) / 45), 10), 30)) clicks · about \(microns) μm" }
        if g.contains("ek43") { return String(format: "EK43 %.1f · about %d μm", min(max(Double(microns - 250) / 100, 3), 11), microns) }
        return "About \(microns) μm"
    }

    private static func makeSteps(dose: Double, total: Double, brewingWater: Double, ice: Double, bloom: Double, bloomDuration: Int, temperature: Int, geometry: Geometry, brewerID: String, requestedPourCount: Int, process: ProcessFamily, agitation: String) -> [SmartBrewStep] {
        if geometry == .cold {
            let water = Int(brewingWater.rounded())
            return [
                .init(id: 0, title: "Add coffee", waterAdded: nil, cumulativeWater: nil, startTime: 0, flowRate: "—", instruction: "Add \(Int(dose.rounded())) g coarse coffee to a clean vessel."),
                .init(id: 1, title: "Add filtered water", waterAdded: water, cumulativeWater: water, startTime: 10, flowRate: "Steady", instruction: "Pour \(water) g room-temperature water and stir until all grounds are wet."),
                .init(id: 2, title: "Steep covered", waterAdded: nil, cumulativeWater: water, startTime: 60, flowRate: "—", instruction: "Cover and steep for 12–16 hours."),
                .init(id: 3, title: "Filter and serve", waterAdded: nil, cumulativeWater: water, startTime: 43_200, flowRate: "—", instruction: "Filter fully, refrigerate, and dilute to taste.")
            ]
        }
        if geometry == .espresso {
            return [
                .init(id: 0, title: "Prepare the puck", waterAdded: nil, cumulativeWater: nil, startTime: 0, flowRate: "—", instruction: "Dose \(Int(dose.rounded())) g, distribute evenly, and tamp level."),
                .init(id: 1, title: "Start extraction", waterAdded: nil, cumulativeWater: nil, startTime: 5, flowRate: "—", instruction: "Start the shot and watch for an even flow."),
                .init(id: 2, title: "Stop at target", waterAdded: nil, cumulativeWater: Int((dose * 2).rounded()), startTime: 30, flowRate: "—", instruction: "Stop near \(Int((dose * 2).rounded())) g yield, then taste before changing grind.")
            ]
        }

        var rows: [SmartBrewStep] = []
        if ice > 0 {
            rows.append(.init(id: rows.count, title: "Add ice", waterAdded: nil, cumulativeWater: nil, startTime: 0, flowRate: "—", instruction: "Weigh \(Int(ice.rounded())) g ice into the server before brewing."))
        }
        rows.append(.init(id: rows.count, title: "Rinse and add coffee", waterAdded: nil, cumulativeWater: nil, startTime: ice > 0 ? 5 : 0, flowRate: "—", instruction: "Rinse the filter, discard rinse water, then add \(Int(dose.rounded())) g coffee."))
        let bloomInt = Int(bloom.rounded())
        rows.append(.init(id: rows.count, title: "Bloom", waterAdded: bloomInt, cumulativeWater: bloomInt, startTime: 10, flowRate: "2–3 g/s", instruction: "Pour \(bloomInt) g at \(temperature) °C, wet every ground, then wait \(bloomDuration) seconds."))

        let requested = min(max(requestedPourCount, 2), 5)
        let afterBloom = max(requested - 1, 1)
        let remaining = max(Int(brewingWater.rounded()) - bloomInt, 0)
        let weights: [Double]
        if geometry == .flat { weights = normalizedWeights(count: afterBloom, preferred: [0.45, 0.35, 0.20]) }
        else if dose <= 14 { weights = normalizedWeights(count: afterBloom, preferred: [0.55, 0.45]) }
        else { weights = normalizedWeights(count: afterBloom, preferred: [0.38, 0.32, 0.30]) }
        var cumulative = bloomInt
        var time = 10 + bloomDuration
        for index in weights.indices {
            let added = index == weights.count - 1 ? Int(brewingWater.rounded()) - cumulative : Int((Double(remaining) * weights[index]).rounded())
            cumulative += max(added, 0)
            let final = index == weights.count - 1
            let direction = process.isSensitive ? "Use a calm centre pour; do not swirl." : (agitation == "Medium-high" ? "Finish with one gentle swirl." : "Use controlled circles and keep the bed level.")
            rows.append(.init(id: rows.count, title: final ? "Final pour" : "Pour \(index + 1)", waterAdded: max(added, 0), cumulativeWater: cumulative, startTime: time, flowRate: geometry == .flat ? "3–4 g/s" : "2–3 g/s", instruction: "Pour to \(cumulative) g. \(direction)"))
            time += max(28, Int(Double(max(added, 0)) / 3.0) + 12)
        }
        rows.append(.init(id: rows.count, title: ice > 0 ? "Draw down and swirl" : "Drawdown", waterAdded: nil, cumulativeWater: Int(brewingWater.rounded()), startTime: time + 35, flowRate: "—", instruction: ice > 0 ? "Let the bed drain, then swirl the server until the brewing ice is melted evenly." : "Let the bed drain without stirring and stop at slow drips."))
        return rows
    }

    private static func normalizedWeights(count: Int, preferred: [Double]) -> [Double] {
        let values: [Double]
        if count <= preferred.count { values = Array(preferred.prefix(count)) }
        else { values = Array(repeating: 1 / Double(count), count: count) }
        let sum = values.reduce(0, +)
        return values.map { $0 / sum }
    }

    private static func timeRange(around seconds: Int, brewerID: String) -> String {
        if brewerID == "french-press" { return "4:00–4:30" }
        let low = max(seconds - 15, 90), high = seconds + 20
        return "\(low / 60):\(String(format: "%02d", low % 60))–\(high / 60):\(String(format: "%02d", high % 60))"
    }

    private static func temperatureReason(roast: String, process: ProcessFamily, iced: Bool) -> String {
        if iced && !process.isSensitive { return "Slightly hotter brewing water preserves extraction over ice." }
        if process.isSensitive { return "A gentler temperature protects fermented sweetness and limits harshness." }
        if roast.contains("dark") { return "Lower heat avoids extracting roast bitterness." }
        if roast.contains("light") { return "Higher heat supports even extraction from a less soluble light roast." }
        return "A moderate temperature is a repeatable starting point for this coffee."
    }

    private static func expectedCup(goal: String, process: ProcessFamily) -> String {
        let style = goal.contains("body") || goal.contains("rich") ? "rounded body" : goal.contains("clar") || goal.contains("bright") ? "high clarity and lively acidity" : goal.contains("sweet") ? "pronounced sweetness" : "balanced sweetness and clarity"
        let character: String
        switch process { case .natural, .anaerobic, .extended, .carbonic, .coferment: character = "fruit-forward aromatics"; case .honey: character = "syrupy sweetness"; case .washed: character = "clean origin character"; default: character = "a clean finish" }
        return "Expect \(style), \(character), and a controlled finish."
    }

    private static func approach(process: ProcessFamily, geometry: Geometry) -> String {
        let processNote = process.isSensitive ? "This coffee is likely highly soluble, so the recipe limits agitation." : "This coffee can handle a steady, even extraction."
        let brewerNote = geometry == .flat ? "Flat-bed pulses keep extraction even across the bed." : geometry == .cone ? "Controlled cone pours keep flow centred and repeatable." : "Immersion time is the main extraction control."
        return "\(processNote) \(brewerNote)"
    }
}
