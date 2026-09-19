import Foundation
import SwiftUI
import SwiftData
import CryptoKit

extension ContentView {
    struct SavedCart: Codable, Identifiable {
        struct Item: Codable, Identifiable {
            var id: String { productID }
            let productID: String
            let productName: String
            let quantity: Int
        }
        let id: UUID
        let name: String
        let items: [Item]
        let createdAt: String
    }

    struct SyncedActiveCart: Codable, Identifiable {
        struct Item: Codable {
            let productID: String
            let variantID: String
            let quantity: Int
        }
        let id: UUID
        let items: [Item]
        let updatedAt: String
    }

    struct ReorderPrompt {
        let order: AccountOrder
        let product: Product
        let daysAgo: Int
    }

    struct CoffeeLotRecommendation: Identifiable {
        let lot: BeanLotRecord
        let product: Product
        let exact: Bool
        let reason: String
        var id: UUID { lot.id }
    }

    struct CoffeePassportOrigin: Identifiable, Hashable {
        let id: String
        let title: String
        let detail: String
        let symbol: String
    }
}

struct BeanLotRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var roaster: String = ""
    var origin: String = ""
    var region: String = ""
    var variety: String = ""
    var process: String = ""
    var roastLevel: String = ""
    var tastingNotes: String = ""
    var productID: String?
    var variantID: String?
    var replacementProductID: String?
    var excludeFromReplacements: Bool = false
}

struct WaterProfileRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var hardnessPPM: Double
    var alkalinityPPM: Double
}

struct TemperaturePresetRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var celsius: Double
}

struct DoseUsageRecord: Codable, Identifiable {
    var id: UUID // The completed session ID is also the idempotency key.
    var purchasedCoffeeID: UUID
    var grams: Double
    var createdAt: Date
}

extension CoffeeDataStore {
    func commitPendingCoffeeChanges() throws {
        try container.mainContext.save()
        notifyCoffeeChange()
    }

    static func stableID(_ key: String) -> UUID {
        var bytes = Array(SHA256.hash(data: Data(key.utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0f) | 0x50
        bytes[8] = (bytes[8] & 0x3f) | 0x80
        return UUID(uuid: (bytes[0],bytes[1],bytes[2],bytes[3],bytes[4],bytes[5],bytes[6],bytes[7],bytes[8],bytes[9],bytes[10],bytes[11],bytes[12],bytes[13],bytes[14],bytes[15]))
    }

    func records<T: Decodable>(_ type: T.Type, entity: String) -> [T] {
        legacyObjects(entityType: entity).compactMap { object in
            guard let data = try? JSONSerialization.data(withJSONObject: object) else { return nil }
            let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
            return try? decoder.decode(type, from: data)
        }
    }

    func saveRecord<T: Encodable>(_ record: T, id: UUID, entity: String) throws {
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(record)
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw CoffeeDataError.invalidResponse }
        try saveEnvelope(entityType: entity, id: id, jsonObject: object)
        try container.mainContext.save(); notifyCoffeeChange()
    }

    func beanLots() -> [BeanLotRecord] {
        // Old and server-imported lots may not contain the optional descriptive fields.
        legacyObjects(entityType: "coffeeLot").compactMap { row in
            guard let id = (row["id"] as? String).flatMap(UUID.init(uuidString:)) else { return nil }
            return BeanLotRecord(id: id, name: row["name"] as? String ?? "Coffee", roaster: row["roaster"] as? String ?? "",
                origin: row["origin"] as? String ?? "", region: row["region"] as? String ?? "", variety: row["variety"] as? String ?? "",
                process: row["process"] as? String ?? "", roastLevel: row["roastLevel"] as? String ?? "", tastingNotes: row["tastingNotes"] as? String ?? "",
                productID: row["productID"] as? String, variantID: row["variantID"] as? String,
                replacementProductID: row["replacementProductID"] as? String,
                excludeFromReplacements: row["excludeFromReplacements"] as? Bool ?? false)
        }
    }

    func saveLot(_ lot: BeanLotRecord) throws {
        guard !lot.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw CoffeeDataError.invalidResponse }
        try saveRecord(lot, id: lot.id, entity: "coffeeLot")
    }

    func importPurchasedCoffee(from orders: [ContentView.AccountOrder], catalog: [ContentView.Product], ownerID: String?) throws {
        let existing = Set(inventory().map(\.id))
        for order in orders {
            for (index, item) in (order.items ?? []).enumerated() {
                let variantID = item.variantId ?? ""
                guard let product = catalog.first(where: { product in
                    ["coffee-beans", "arabic-coffee-beans"].contains(product.categoryKey)
                        && (product.variants.contains { $0.id == variantID || $0.id.hasSuffix("/\(variantID)") }
                            || product.name.localizedCaseInsensitiveCompare(item.productTitle ?? item.name) == .orderedSame)
                }) else { continue }
                let purchaseID = Self.stableID("shopify:\(order.id):\(variantID):\(index)")
                guard !existing.contains(purchaseID) else { continue }
                let variant = product.variants.first { $0.id == variantID || $0.id.hasSuffix("/\(variantID)") } ?? product.defaultVariant
                let grams = max(variant?.weightGrams ?? 250, 1) * Double(max(item.quantity, 1))
                let lotID = Self.stableID("shopify-lot:\(product.id):\(variant?.id ?? variantID)")
                let lot = BeanLotRecord(id: lotID, name: product.name, origin: product.countryOfOrigin ?? "", productID: product.id, variantID: variant?.id ?? variantID)
                try saveLot(lot)
                let payload: [String: Any] = [
                    "id": purchaseID.uuidString.lowercased(), "lotID": lotID.uuidString.lowercased(),
                    "productID": product.id, "variantID": variant?.id ?? variantID,
                    "productName": product.name, "purchasedAt": order.createdAt,
                    "initialQuantityGrams": grams, "remainingQuantityGrams": grams
                ]
                try saveEnvelope(entityType: "purchasedCoffee", id: purchaseID, jsonObject: payload)
            }
        }
        try container.mainContext.save()
        notifyCoffeeChange()
    }

    func markOpened(_ id: UUID, date: Date) throws {
        guard var row = legacyObjects(entityType: "purchasedCoffee").first(where: { ($0["id"] as? String)?.lowercased() == id.uuidString.lowercased() }) else { return }
        row["openedAt"] = ISO8601DateFormatter().string(from: date)
        try saveEnvelope(entityType: "purchasedCoffee", id: id, jsonObject: row)
        try container.mainContext.save(); notifyCoffeeChange()
    }

    func usedGrams(_ purchaseID: UUID) -> Double {
        records(DoseUsageRecord.self, entity: "doseUsage").filter { $0.purchasedCoffeeID == purchaseID && $0.grams.isFinite && $0.grams > 0 }.reduce(0) { $0 + $1.grams }
    }

    func recordDose(sessionID: UUID, purchaseID: UUID, grams: Double) throws {
        guard grams.isFinite, grams > 0, inventory().contains(where: { $0.id == purchaseID }) else { throw CoffeeDataError.invalidResponse }
        guard !records(DoseUsageRecord.self, entity: "doseUsage").contains(where: { $0.id == sessionID }) else { return }
        let usage = DoseUsageRecord(id: sessionID, purchasedCoffeeID: purchaseID, grams: grams, createdAt: .now)
        try saveRecord(usage, id: usage.id, entity: "doseUsage")
    }

    func saveWater(_ water: WaterProfileRecord) throws {
        guard !water.name.isEmpty, water.hardnessPPM.isFinite, water.alkalinityPPM.isFinite,
              (0...1000).contains(water.hardnessPPM), (0...1000).contains(water.alkalinityPPM) else { throw CoffeeDataError.invalidResponse }
        try saveRecord(water, id: water.id, entity: "waterProfile")
    }

    func saveTemperature(_ preset: TemperaturePresetRecord) throws {
        guard !preset.name.isEmpty, preset.celsius.isFinite, (0...100).contains(preset.celsius) else { throw CoffeeDataError.invalidResponse }
        try saveRecord(preset, id: preset.id, entity: "temperaturePreset")
    }

    func recommendation(for lot: BeanLotRecord, in catalog: [ContentView.Product]) -> (product: ContentView.Product, exact: Bool, reason: String)? {
        let available = catalog.filter { ["coffee-beans", "arabic-coffee-beans"].contains($0.categoryKey) && $0.isAvailableForSale
            && $0.variants.contains(where: \.isAvailableForSale)
            && !$0.catalogClassificationText.localizedCaseInsensitiveContains("Talla Replacement Excluded") }
        if let exact = available.first(where: { $0.id == lot.productID }) {
            let sameVariant = exact.variants.contains { $0.id == lot.variantID && $0.isAvailableForSale }
            return (exact, true, sameVariant ? "Same Shopify coffee variant" : "Same coffee lot in an available size")
        }
        if let replacementID = lot.replacementProductID,
           let replacement = available.first(where: { $0.id == replacementID }) {
            return (replacement, false, "Replacement selected by Talla")
        }
        var ranked: [(product: ContentView.Product, score: Int, reasons: [String])] = []
        for product in available where product.id != lot.productID {
            var score = 0; var reasons: [String] = []
            let traits: [(value: String, label: String, weight: Int)] = [
                (lot.origin, "origin", 4), (lot.process, "process", 3), (lot.roastLevel, "roast", 2)
            ]
            for trait in traits where !trait.value.isEmpty {
                if product.catalogClassificationText.localizedCaseInsensitiveContains(trait.value)
                    || product.countryOfOrigin?.localizedCaseInsensitiveCompare(trait.value) == .orderedSame {
                    score += trait.weight
                    reasons.append(trait.label)
                }
            }
            let lotNotes = Set((lot.tastingNotes + " " + lot.variety).normalizedCoffeeTokens)
            let productNotes = Set(product.catalogClassificationText.normalizedCoffeeTokens)
            let sharedNotes = lotNotes.intersection(productNotes).count
            if sharedNotes > 0 {
                score += min(sharedNotes, 3)
                reasons.append("flavour profile")
            }
            ranked.append((product, score, reasons))
        }
        ranked.sort { $0.score == $1.score ? $0.product.id < $1.product.id : $0.score > $1.score }
        guard let best = ranked.first, best.score > 0 else { return nil }
        return (best.product, false, "Similar " + best.reasons.joined(separator: ", "))
    }
}

private extension String {
    var normalizedCoffeeTokens: [String] {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }
    }
}

struct CoffeeMemoryProfilesView: View {
    @EnvironmentObject private var store: CoffeeDataStore
    @State private var waterName = ""
    @State private var hardness = 70.0
    @State private var alkalinity = 40.0
    @State private var temperatureName = ""
    @State private var temperature = 93.0
    @State private var error: String?
    var body: some View {
        GroupBox("Water and temperature") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Water profile name", text: $waterName)
                HStack {
                    Text("Hardness (ppm)"); TextField("Hardness", value: $hardness, format: .number).keyboardType(.decimalPad)
                    Text("Alkalinity (ppm)"); TextField("Alkalinity", value: $alkalinity, format: .number).keyboardType(.decimalPad)
                }
                Button("Save water profile") { perform { try store.saveWater(WaterProfileRecord(name: waterName, hardnessPPM: hardness, alkalinityPPM: alkalinity)) } }
                ForEach(store.records(WaterProfileRecord.self, entity: "waterProfile")) { water in
                    HStack {
                        Text("\(water.name): \(water.hardnessPPM, specifier: "%.0f") / \(water.alkalinityPPM, specifier: "%.0f") ppm")
                        Spacer()
                        Button("Delete", role: .destructive) { perform { try store.tombstone(entityType: "waterProfile", id: water.id) } }
                    }
                }
                TextField("Temperature preset name", text: $temperatureName)
                Stepper("\(temperature, specifier: "%.0f") °C", value: $temperature, in: 0...100)
                Button("Save temperature preset") { perform { try store.saveTemperature(TemperaturePresetRecord(name: temperatureName, celsius: temperature)) } }
                ForEach(store.records(TemperaturePresetRecord.self, entity: "temperaturePreset")) { preset in
                    HStack {
                        Text("\(preset.name): \(preset.celsius, specifier: "%.0f") °C")
                        Spacer()
                        Button("Delete", role: .destructive) { perform { try store.tombstone(entityType: "temperaturePreset", id: preset.id) } }
                    }
                }
                if let error { Text(error).foregroundStyle(.red) }
            }.textFieldStyle(.roundedBorder)
        }
    }
    private func perform(_ action: () throws -> Void) {
        do { try action(); error = nil } catch { self.error = "Enter a name and valid numeric values." }
    }
}
