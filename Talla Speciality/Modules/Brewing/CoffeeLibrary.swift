import SwiftData
import SwiftUI

struct BrewCurvePoint: Identifiable, Codable, Equatable {
    let id: UUID
    let seconds: Double
    let weightGrams: Double
    let flowGramsPerSecond: Double?
}

struct BrewCurveComparison: Codable, Equatable {
    let reference: [BrewCurvePoint]
    let attempt: [BrewCurvePoint]
    let finalWeightDifference: Double
    let timeDifference: Double
}

struct BrewMeasurementRecommendation: Codable, Equatable {
    let title: String
    let detail: String
    let confidence: Double
}

struct ShareableBrewCard: Codable, Equatable {
    let title: String
    let method: String
    let doseGrams: Double?
    let finalWeightGrams: Double?
    let durationSeconds: Double?
    let curve: [BrewCurvePoint]
    let isReference: Bool

    var payload: Data? { try? JSONEncoder().encode(self) }
}

struct BrewTelemetryChart: View {
    let samples: [CoffeeSampleInput]
    var accent: Color = .orange

    var body: some View {
        GeometryReader { proxy in
            let weights = samples.filter { $0.kind == .weight }.sorted { $0.elapsedMilliseconds < $1.elapsedMilliseconds }
            let maxWeight = max(weights.map(\.value).max() ?? 1, 1)
            Canvas { context, size in
                guard weights.count > 1 else { return }
                var path = Path()
                let maxTime = max(Double(weights.last?.elapsedMilliseconds ?? 1), 1)
                for (index, point) in weights.enumerated() {
                    let x = CGFloat(Double(point.elapsedMilliseconds) / maxTime) * size.width
                    let y = size.height - CGFloat(point.value / maxWeight) * (size.height - 8) - 4
                    if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                context.stroke(path, with: .color(accent), lineWidth: 2.5)
            }
            .overlay(alignment: .topLeading) {
                Text("WEIGHT CURVE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(7)
            }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
        }
    }
}

struct BrewShareCardView: View {
    let title: String
    let method: String
    let finalWeight: Double?
    let duration: Double

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "drop.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 48, height: 48)
                .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(method).font(.subheadline).foregroundStyle(.secondary)
                Text("\(finalWeight.map { String(format: "%.1f g", $0) } ?? "—")  ·  \(Int(duration.rounded())) s")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            Spacer()
            Text("Measured brew").font(.caption2.weight(.semibold)).foregroundStyle(.orange)
        }
        .padding(14)
        .background(Color.orange.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.25)))
    }
}

enum BrewReferenceStore {
    private static let key = "talla.brewing.referenceCurve.v1"
    static func save(_ samples: [CoffeeSampleInput]) { UserDefaults.standard.set(try? JSONEncoder().encode(samples), forKey: key) }
    static func load() -> [CoffeeSampleInput] { guard let data = UserDefaults.standard.data(forKey: key) else { return [] }; return (try? JSONDecoder().decode([CoffeeSampleInput].self, from: data)) ?? [] }
}

struct BrewTelemetryComparisonChart: View {
    let reference: [CoffeeSampleInput]
    let attempt: [CoffeeSampleInput]

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                draw(reference, color: .gray, context: &context, size: size)
                draw(attempt, color: .orange, context: &context, size: size)
            }
            .overlay(alignment: .topLeading) {
                HStack(spacing: 10) {
                    Label("Best", systemImage: "circle.fill").foregroundStyle(.gray)
                    Label("This brew", systemImage: "circle.fill").foregroundStyle(.orange)
                }
                .font(.caption2)
                .padding(6)
                .background(.thinMaterial, in: Capsule())
            }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.quaternary))
        }
    }

    private func draw(_ values: [CoffeeSampleInput], color: Color, context: inout GraphicsContext, size: CGSize) {
        let weights = values.filter { $0.kind == .weight }.sorted { $0.elapsedMilliseconds < $1.elapsedMilliseconds }
        guard weights.count > 1 else { return }
        let maxWeight = max(weights.map(\.value).max() ?? 1, 1)
        let maxTime = max(Double(weights.last?.elapsedMilliseconds ?? 1), 1)
        var path = Path()
        for (index, point) in weights.enumerated() {
            let x = CGFloat(Double(point.elapsedMilliseconds) / maxTime) * size.width
            let y = size.height - CGFloat(point.value / maxWeight) * (size.height - 8) - 4
            if index == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        context.stroke(path, with: .color(color), lineWidth: 2)
    }
}

struct CoffeeInventoryRecord: Identifiable {
    let id: UUID
    let lotID: UUID?
    let productName: String
    let roaster: String
    let origin: String
    let region: String
    let variety: String
    let process: String
    let roastLevel: String
    let tastingNotes: String
    let roastDate: Date?
    let initialQuantityGrams: Double
    let remainingQuantityGrams: Double
    let openedAt: Date?
    let usedQuantityGrams: Double

    func estimatedBrews(doseGrams: Double = 18) -> Int {
        guard doseGrams > 0 else { return 0 }
        return max(0, Int((remainingQuantityGrams / doseGrams).rounded(.down)))
    }
}

struct CoffeeEquipmentRecord: Identifiable {
    let id: UUID
    let kind: EquipmentKind
    let name: String
    let manufacturer: String
    let model: String
    let burrSet: String
}

struct CoffeeCalibrationRecord: Identifiable {
    let id: UUID
    let equipmentID: UUID
    let setting: String
    let measuredValue: Double?
    let unit: String
    let notes: String
}

struct CoffeeMaintenanceRecord: Identifiable {
    let id: UUID
    let equipmentID: UUID
    let kind: String
    let performedAt: Date?
    let notes: String
}

struct CoffeeDataConflict: Identifiable {
    let entityType: String
    let recordID: UUID
    let localPayload: Data
    let serverPayload: Data

    var id: String { "\(entityType):\(recordID.uuidString.lowercased())" }
}

extension CoffeeDataStore {
    func equipmentRecords() -> [CoffeeEquipmentRecord] {
        legacyObjects(entityType: "equipment").compactMap { row in
            guard let id = (row["id"] as? String).flatMap(UUID.init(uuidString:)),
                  let kind = (row["kind"] as? String).flatMap(EquipmentKind.init(rawValue:)) else { return nil }
            return CoffeeEquipmentRecord(
                id: id, kind: kind, name: row["name"] as? String ?? AppLocalization.text("library_equipment", fallback: "Equipment"),
                manufacturer: row["manufacturer"] as? String ?? "", model: row["model"] as? String ?? "",
                burrSet: row["burrSet"] as? String ?? ""
            )
        }
    }

    func calibrationRecords() -> [CoffeeCalibrationRecord] {
        legacyObjects(entityType: "calibration").compactMap { row in
            guard let id = (row["id"] as? String).flatMap(UUID.init(uuidString:)),
                  let equipmentID = (row["equipmentID"] as? String).flatMap(UUID.init(uuidString:)) else { return nil }
            return CoffeeCalibrationRecord(
                id: id, equipmentID: equipmentID, setting: row["setting"] as? String ?? "",
                measuredValue: (row["measuredValue"] as? NSNumber)?.doubleValue,
                unit: row["unit"] as? String ?? "", notes: row["notes"] as? String ?? ""
            )
        }
    }

    func maintenanceRecords() -> [CoffeeMaintenanceRecord] {
        legacyObjects(entityType: "maintenance").compactMap { row in
            guard let id = (row["id"] as? String).flatMap(UUID.init(uuidString:)),
                  let equipmentID = (row["equipmentID"] as? String).flatMap(UUID.init(uuidString:)) else { return nil }
            return CoffeeMaintenanceRecord(
                id: id, equipmentID: equipmentID, kind: row["kind"] as? String ?? AppLocalization.text("library_maintenance", fallback: "Maintenance"),
                performedAt: (row["performedAt"] as? String).flatMap(Self.coffeeISO.date(from:)),
                notes: row["notes"] as? String ?? ""
            )
        }
    }

    func saveEquipment(recordID: UUID? = nil, kind: EquipmentKind, name: String, manufacturer: String, model: String, burrSet: String = "", ownerID: String? = nil) throws {
        let id = recordID ?? UUID()
        if let recordID {
            let descriptor = FetchDescriptor<CoffeeEquipment>(predicate: #Predicate { $0.id == recordID })
            if let equipment = try container.mainContext.fetch(descriptor).first {
                equipment.kindRaw = kind.rawValue; equipment.name = name; equipment.manufacturer = manufacturer; equipment.model = model
                equipment.updatedAt = .now; equipment.syncStateRaw = CoffeeSyncState.dirty.rawValue
            }
        } else {
            container.mainContext.insert(CoffeeEquipment(id: id, kind: kind, name: name, manufacturer: manufacturer, model: model, ownerID: ownerID))
        }
        try saveEnvelope(entityType: "equipment", id: id, jsonObject: [
            "id": id.uuidString, "kind": kind.rawValue, "name": name,
            "manufacturer": manufacturer, "model": model, "burrSet": burrSet
        ])
        try container.mainContext.save(); notifyCoffeeChange()
    }

    func saveCalibration(recordID: UUID? = nil, equipmentID: UUID, setting: String, measuredValue: Double?, unit: String, notes: String, ownerID: String? = nil) throws {
        let calibration: EquipmentCalibration
        if let recordID, let existing = try container.mainContext.fetch(FetchDescriptor<EquipmentCalibration>(predicate: #Predicate { $0.id == recordID })).first {
            calibration = existing
            calibration.equipmentID = equipmentID; calibration.setting = setting; calibration.measuredValue = measuredValue
            calibration.unit = unit; calibration.notes = notes; calibration.updatedAt = .now; calibration.syncStateRaw = CoffeeSyncState.dirty.rawValue
        } else {
            calibration = EquipmentCalibration(id: recordID ?? UUID(), equipmentID: equipmentID, setting: setting, measuredValue: measuredValue, unit: unit, notes: notes, ownerID: ownerID)
            container.mainContext.insert(calibration)
        }
        try saveEnvelope(entityType: "calibration", id: calibration.id, jsonObject: [
            "id": calibration.id.uuidString, "equipmentID": equipmentID.uuidString, "setting": setting,
            "measuredValue": measuredValue.map { $0 as Any } ?? NSNull(), "unit": unit, "notes": notes
        ])
        try container.mainContext.save(); notifyCoffeeChange()
    }

    func deleteCoffeeRecord(entityType: String, id: UUID) throws {
        try tombstone(entityType: entityType, id: id)
    }

    func inventory() -> [CoffeeInventoryRecord] {
        let lots = Dictionary(uniqueKeysWithValues: legacyObjects(entityType: "coffeeLot").compactMap { row -> (String, [String: Any])? in
            guard let id = row["id"] as? String else { return nil }
            return (id.lowercased(), row)
        })
        return legacyObjects(entityType: "purchasedCoffee").compactMap { row in
            guard let id = (row["id"] as? String).flatMap(UUID.init(uuidString:)) else { return nil }
            let lotID = (row["lotID"] as? String).flatMap(UUID.init(uuidString:))
            let lot = lotID.flatMap { lots[$0.uuidString.lowercased()] }
            return CoffeeInventoryRecord(
                id: id,
                lotID: lotID,
                productName: row["productName"] as? String ?? lot?["name"] as? String ?? "Coffee",
                roaster: lot?["roaster"] as? String ?? "",
                origin: lot?["origin"] as? String ?? "",
                region: lot?["region"] as? String ?? lot?["producer"] as? String ?? "",
                variety: lot?["variety"] as? String ?? "",
                process: lot?["process"] as? String ?? "",
                roastLevel: lot?["roastLevel"] as? String ?? "",
                tastingNotes: lot?["notes"] as? String ?? "",
                roastDate: (row["roastDate"] as? String).flatMap(Self.coffeeISO.date(from:)),
                initialQuantityGrams: (row["initialQuantityGrams"] as? NSNumber)?.doubleValue ?? 0,
                remainingQuantityGrams: (row["remainingQuantityGrams"] as? NSNumber)?.doubleValue ?? 0
                ,openedAt: (row["openedAt"] as? String).flatMap(Self.coffeeISO.date(from:)),
                usedQuantityGrams: usedGrams(id)
            )
        }
    }

    func addPurchasedCoffee(
        name: String,
        roaster: String,
        origin: String = "",
        region: String = "",
        variety: String = "",
        process: String = "",
        roastLevel: String = "",
        tastingNotes: String = "",
        roastDate: Date?,
        quantityGrams: Double,
        ownerID: String? = nil
    ) throws {
        let lot = CoffeeLot(
            name: name, roaster: roaster, origin: origin.nilIfBlank,
            producer: region.nilIfBlank, variety: variety.nilIfBlank,
            process: process.nilIfBlank, roastLevel: roastLevel.nilIfBlank,
            notes: tastingNotes.nilIfBlank, ownerID: ownerID
        )
        let purchase = PurchasedCoffee(
            lotID: lot.id,
            productName: name,
            roastDate: roastDate,
            purchasedAt: .now,
            initialQuantityGrams: quantityGrams,
            remainingQuantityGrams: quantityGrams,
            ownerID: ownerID
        )
        container.mainContext.insert(lot)
        container.mainContext.insert(purchase)
        try saveEnvelope(entityType: "coffeeLot", id: lot.id, jsonObject: [
            "id": lot.id.uuidString,
            "name": name,
            "roaster": roaster,
            "origin": origin,
            "region": region,
            "variety": variety,
            "process": process,
            "roastLevel": roastLevel,
            "tastingNotes": tastingNotes
        ])
        try saveEnvelope(entityType: "purchasedCoffee", id: purchase.id, jsonObject: [
            "id": purchase.id.uuidString,
            "lotID": lot.id.uuidString,
            "productName": name,
            "roastDate": roastDate.map { Self.coffeeISO.string(from: $0) as Any } ?? NSNull(),
            "purchasedAt": Self.coffeeISO.string(from: .now),
            "initialQuantityGrams": quantityGrams,
            "remainingQuantityGrams": quantityGrams
        ])
        try container.mainContext.save()
        notifyCoffeeChange()
    }

    func updateRemainingQuantity(recordID: UUID, remainingGrams: Double) throws {
        guard let row = legacyObjects(entityType: "purchasedCoffee").first(where: { ($0["id"] as? String)?.lowercased() == recordID.uuidString.lowercased() }) else { return }
        var updated = row
        updated["remainingQuantityGrams"] = max(remainingGrams, 0)
        try saveEnvelope(entityType: "purchasedCoffee", id: recordID, jsonObject: updated)
        let descriptor = FetchDescriptor<PurchasedCoffee>(predicate: #Predicate { $0.id == recordID })
        if let model = try container.mainContext.fetch(descriptor).first {
            model.remainingQuantityGrams = max(remainingGrams, 0)
            model.updatedAt = .now
            model.syncStateRaw = CoffeeSyncState.dirty.rawValue
        }
        try container.mainContext.save()
        notifyCoffeeChange()
    }

    func updateRoastDate(recordID: UUID, roastDate: Date?) throws {
        guard var row = legacyObjects(entityType: "purchasedCoffee").first(where: { ($0["id"] as? String)?.lowercased() == recordID.uuidString.lowercased() }) else { return }
        row["roastDate"] = roastDate.map { Self.coffeeISO.string(from: $0) as Any } ?? NSNull()
        try saveEnvelope(entityType: "purchasedCoffee", id: recordID, jsonObject: row)
        try container.mainContext.save()
        notifyCoffeeChange()
    }

    func recordMaintenance(recordID: UUID? = nil, equipmentID: UUID, kind: String, notes: String, ownerID: String? = nil) throws {
        let event: MaintenanceEvent
        if let recordID, let existing = try container.mainContext.fetch(FetchDescriptor<MaintenanceEvent>(predicate: #Predicate { $0.id == recordID })).first {
            event = existing
            event.equipmentID = equipmentID; event.kind = kind; event.notes = notes; event.updatedAt = .now; event.syncStateRaw = CoffeeSyncState.dirty.rawValue
        } else {
            event = MaintenanceEvent(id: recordID ?? UUID(), equipmentID: equipmentID, kind: kind, notes: notes, ownerID: ownerID)
            container.mainContext.insert(event)
        }
        try saveEnvelope(entityType: "maintenance", id: event.id, jsonObject: [
            "id": event.id.uuidString,
            "equipmentID": equipmentID.uuidString,
            "kind": kind,
            "performedAt": Self.coffeeISO.string(from: event.performedAt),
            "notes": notes
        ])
        try container.mainContext.save()
        notifyCoffeeChange()
    }

    func recordCompletedBrew(
        id: UUID,
        title: String,
        method: String,
        coffeeGrams: Double?,
        waterGrams: Double?,
        durationSeconds: Int?,
        rating: Int,
        notes: String,
        purchasedCoffeeID: UUID? = nil,
        ownerID: String? = nil,
        samples: [CoffeeSampleInput] = []
    ) throws {
        let kind: BrewSessionKind = method.localizedCaseInsensitiveContains("espresso") ? .espresso : .filter
        let startedAt = Date().addingTimeInterval(-Double(durationSeconds ?? 0))
        let availablePurchases = inventory().filter { $0.remainingQuantityGrams > 0 }
        let activePurchase = purchasedCoffeeID.flatMap { id in availablePurchases.first { $0.id == id } }
            ?? availablePurchases.filter { $0.openedAt != nil }.sorted { $0.openedAt! > $1.openedAt! }.first
            ?? (availablePurchases.count == 1 ? availablePurchases.first : nil)
        let session = CoffeeBrewSession(
            id: id,
            kind: kind,
            purchasedCoffeeID: activePurchase?.id,
            startedAt: startedAt,
            endedAt: .now,
            doseGrams: coffeeGrams,
            yieldGrams: kind == .espresso ? waterGrams : nil,
            waterGrams: kind == .filter ? waterGrams : nil,
            notes: title,
            ownerID: ownerID
        )
        let feedback = CoffeeTasteFeedback(id: id, sessionID: id, rating: rating, notes: notes, ownerID: ownerID)
        container.mainContext.insert(session)
        container.mainContext.insert(feedback)
        var capturedSamples = samples.filter { $0.value.isFinite }
        if let waterGrams, !capturedSamples.contains(where: { $0.kind == .weight }) {
            capturedSamples.append(CoffeeSampleInput(
                kind: .weight,
                elapsedMilliseconds: max(durationSeconds ?? 0, 0) * 1_000,
                value: waterGrams,
                unit: "g"
            ))
        }
        for captured in capturedSamples {
            let sample = BrewSample(sessionID: id, kind: captured.kind, elapsedMilliseconds: captured.elapsedMilliseconds, value: captured.value, unit: captured.unit, ownerID: ownerID)
            container.mainContext.insert(sample)
            try saveEnvelope(entityType: "sample", id: sample.id, jsonObject: [
                "id": sample.id.uuidString,
                "sessionID": id.uuidString,
                "kind": captured.kind.rawValue,
                "elapsedMilliseconds": sample.elapsedMilliseconds,
                "value": captured.value,
                "unit": captured.unit
            ])
        }
        if let purchase = activePurchase, let coffeeGrams, coffeeGrams > 0 {
            try recordDose(sessionID: id, purchaseID: purchase.id, grams: coffeeGrams)
            try updateRemainingQuantity(recordID: purchase.id, remainingGrams: purchase.remainingQuantityGrams - coffeeGrams)
        }
        try container.mainContext.save()
        notifyCoffeeChange()
    }

    func pendingConflicts() -> [CoffeeDataConflict] {
        let descriptor = FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.conflictedPayload != nil })
        return ((try? container.mainContext.fetch(descriptor)) ?? []).compactMap { envelope in
            guard let local = envelope.conflictedPayload else { return nil }
            return CoffeeDataConflict(entityType: envelope.entityType, recordID: envelope.recordID, localPayload: local, serverPayload: envelope.payload)
        }
    }

    func resolveConflict(_ conflict: CoffeeDataConflict, keepLocal: Bool) throws {
        let compoundID = conflict.id
        let descriptor = FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.compoundID == compoundID })
        guard let envelope = try container.mainContext.fetch(descriptor).first else { return }
        if keepLocal {
            envelope.payload = conflict.localPayload
            envelope.updatedAt = .now
            envelope.dirty = true
        }
        envelope.conflictedPayload = nil
        try container.mainContext.save()
        notifyCoffeeChange()
    }

    private static let coffeeISO: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

struct CoffeeLibraryView: View {
    @EnvironmentObject private var coffeeData: CoffeeDataStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var name = ""
    @State private var roaster = ""
    @State private var origin = ""
    @State private var region = ""
    @State private var variety = ""
    @State private var process = ""
    @State private var roastLevel = ""
    @State private var tastingNotes = ""
    @State private var quantity = "250"
    @State private var roastDate = Date()
    @State private var hasRoastDate = true
    @State private var equipmentID: UUID?
    @State private var equipmentKind = EquipmentKind.brewer
    @State private var equipmentName = ""
    @State private var equipmentManufacturer = ""
    @State private var equipmentModel = ""
    @State private var equipmentBurrSet = ""
    @State private var calibrationSetting = ""
    @State private var calibrationID: UUID?
    @State private var calibrationValue = ""
    @State private var calibrationUnit = ""
    @State private var calibrationNotes = ""
    @State private var maintenanceKind = "Cleaning"
    @State private var maintenanceNotes = ""
    @State private var maintenanceID: UUID?
    @State private var editingLot: BeanLotRecord?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            Text(AppLocalization.text("coffee_inventory", fallback: "Coffee inventory"))
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .accessibilityAddTraits(.isHeader)

            coffeeSyncStatusBanner

            GroupBox(AppLocalization.text("add_coffee", fallback: "Add coffee")) {
                VStack(spacing: 12) {
                    TextField(AppLocalization.text("coffee_name", fallback: "Coffee name"), text: $name)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("coffee.inventory.name")
                    TextField(AppLocalization.text("roaster", fallback: "Roaster"), text: $roaster)
                        .textFieldStyle(.roundedBorder)
                    TextField("Origin", text: $origin).textFieldStyle(.roundedBorder)
                    TextField("Region or producer", text: $region).textFieldStyle(.roundedBorder)
                    TextField("Variety", text: $variety).textFieldStyle(.roundedBorder)
                    TextField("Process", text: $process).textFieldStyle(.roundedBorder)
                    TextField("Roast level", text: $roastLevel).textFieldStyle(.roundedBorder)
                    TextField("Tasting notes", text: $tastingNotes).textFieldStyle(.roundedBorder)
                    TextField(AppLocalization.text("quantity_grams", fallback: "Quantity (g)"), text: $quantity)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    Toggle(AppLocalization.text("roast_date", fallback: "Roast date"), isOn: $hasRoastDate)
                    if hasRoastDate { DatePicker("", selection: $roastDate, displayedComponents: .date).labelsHidden() }
                    Button(AppLocalization.text("save", fallback: "Save"), action: addCoffee)
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("coffee.inventory.save")
                }
                .padding(.top, 8)
            }

            ForEach(coffeeData.inventory()) { coffee in
                VStack(alignment: .leading, spacing: 8) {
                    Text(coffee.productName).font(.headline)
                    if !coffee.roaster.isEmpty { Text(coffee.roaster).font(.subheadline) }
                    if let roastDate = coffee.roastDate {
                        DatePicker(
                            "Roasted",
                            selection: Binding(
                                get: { roastDate },
                                set: { try? coffeeData.updateRoastDate(recordID: coffee.id, roastDate: $0) }
                            ),
                            displayedComponents: .date
                        )
                        .font(.caption)
                        Button("Remove roast date", role: .destructive) {
                            try? coffeeData.updateRoastDate(recordID: coffee.id, roastDate: nil)
                        }
                        .font(.caption)
                    } else {
                        Button("Add roast date") {
                            try? coffeeData.updateRoastDate(recordID: coffee.id, roastDate: .now)
                        }
                        .buttonStyle(.borderless)
                    }
                    if let openedAt = coffee.openedAt {
                        Text("Opened \(openedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                    } else {
                        Button("Mark opened today") { try? coffeeData.markOpened(coffee.id, date: .now) }
                            .buttonStyle(.borderless)
                    }
                    Text("\(coffee.estimatedBrews()) estimated brews · \(coffee.usedQuantityGrams, specifier: "%.0f") g logged")
                        .font(.caption)
                    Text("Original bag weight: \(coffee.initialQuantityGrams, specifier: "%.0f") g")
                        .font(.caption)
                    Stepper(
                        "\(Int(coffee.remainingQuantityGrams.rounded())) g remaining",
                        value: Binding(
                            get: { Int(coffee.remainingQuantityGrams.rounded()) },
                            set: { try? coffeeData.updateRemainingQuantity(recordID: coffee.id, remainingGrams: Double($0)) }
                        ),
                        in: 0...max(Int(coffee.initialQuantityGrams.rounded()), 1),
                        step: 5
                    )
                    .accessibilityIdentifier("coffee.inventory.remaining.\(coffee.id.uuidString)")
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(coffeeCardColor, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: 0xC8965A).opacity(colorScheme == .dark ? 0.18 : 0.12), lineWidth: 1)
                )
                .accessibilityIdentifier("offline.cached-brew")
            }

            GroupBox("Bean library") {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(coffeeData.beanLots()) { lot in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lot.name).font(.headline)
                                if !lot.roaster.isEmpty { Text(lot.roaster).font(.subheadline) }
                                let details = [lot.origin, lot.region, lot.variety, lot.process, lot.roastLevel]
                                    .filter { !$0.isEmpty }.joined(separator: " · ")
                                if !details.isEmpty { Text(details).font(.caption) }
                                if !lot.tastingNotes.isEmpty { Text(lot.tastingNotes).font(.caption).foregroundStyle(.secondary) }
                            }
                            Spacer()
                            Button("Edit") { editingLot = lot }
                            Button(role: .destructive) { delete("coffeeLot", lot.id) } label: { Image(systemName: "trash") }
                        }
                    }
                    if coffeeData.beanLots().isEmpty {
                        Text("Add a coffee above to create your first bean lot.").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 8)
            }

            equipmentSection
            calibrationSection
            maintenanceSection

            ForEach(coffeeData.pendingConflicts()) { conflict in
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalization.text("sync_conflict", fallback: "Sync conflict"))
                        .font(.headline)
                    Text(conflict.entityType).font(.caption)
                    HStack {
                        Button(AppLocalization.text("keep_server", fallback: "Keep server")) {
                            try? coffeeData.resolveConflict(conflict, keepLocal: false)
                        }
                        Button(AppLocalization.text("restore_local", fallback: "Restore local")) {
                            try? coffeeData.resolveConflict(conflict, keepLocal: true)
                        }
                    }
                }
                .padding(14)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                .accessibilityIdentifier("coffee.sync.conflict")
            }

            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
        }
        }
        .groupBoxStyle(TallaCoffeeGroupBoxStyle())
        .onAppear { equipmentID = equipmentID ?? coffeeData.equipmentRecords().first?.id }
        .sheet(item: $editingLot) { lot in
            CoffeeLotEditorView(lot: lot)
                .environmentObject(coffeeData)
        }
    }

    private var coffeeCardColor: Color {
        colorScheme == .dark ? Color(hex: 0x17120D) : Color(hex: 0xFFFCF5)
    }

    @ViewBuilder
    private var coffeeSyncStatusBanner: some View {
        if let recoveryMessage = coffeeData.storageRecoveryMessage {
            Label(recoveryMessage, systemImage: "externaldrive.badge.exclamationmark")
                .font(.footnote)
                .foregroundStyle(.orange)
                .accessibilityIdentifier("coffee.storage.recovery")
        }
        switch coffeeData.syncStatus {
        case .idle:
            EmptyView()
        case .syncing:
            Label(AppLocalization.text("syncing", fallback: "Syncing saved coffee data…"), systemImage: "arrow.triangle.2.circlepath")
                .accessibilityIdentifier("offline.status")
        case .synced:
            Label(AppLocalization.text("coffee_sync_recovered", fallback: "Back online. Your saved coffee data is synced."), systemImage: "checkmark.icloud.fill")
                .foregroundStyle(.green)
                .accessibilityIdentifier("offline.status")
        case .offline, .failed(_):
            VStack(alignment: .leading, spacing: 10) {
                Label(AppLocalization.text("coffee_offline_cache", fallback: "Offline. Showing saved coffee data."), systemImage: "icloud.slash")
                    .accessibilityIdentifier("offline.status")
                Button(AppLocalization.text("retry", fallback: "Retry connection")) {
                    Task { await coffeeData.retryCurrentAccountSynchronization() }
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("offline.retry")
            }
        }
    }

    private var equipmentSection: some View {
        GroupBox(AppLocalization.text("library_equipment", fallback: "Equipment")) {
            VStack(alignment: .leading, spacing: 10) {
                Picker(AppLocalization.text("library_type", fallback: "Type"), selection: $equipmentKind) {
                    ForEach(EquipmentKind.allCases, id: \.self) { Text(AppLocalization.text("library_\($0.rawValue)", fallback: $0.rawValue.capitalized)).tag($0) }
                }
                TextField(AppLocalization.text("library_name", fallback: "Name"), text: $equipmentName).textFieldStyle(.roundedBorder).accessibilityIdentifier("coffee.equipment.name")
                TextField(AppLocalization.text("library_manufacturer", fallback: "Manufacturer"), text: $equipmentManufacturer).textFieldStyle(.roundedBorder)
                TextField(AppLocalization.text("library_model", fallback: "Model"), text: $equipmentModel).textFieldStyle(.roundedBorder)
                if equipmentKind == .grinder {
                    TextField("Burr set (size, geometry, coating)", text: $equipmentBurrSet).textFieldStyle(.roundedBorder)
                }
                Button(equipmentID == nil ? AppLocalization.text("library_add_equipment", fallback: "Add equipment") : AppLocalization.text("library_save_equipment", fallback: "Save equipment"), action: saveEquipment)
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("coffee.equipment.save")
                ForEach(coffeeData.equipmentRecords()) { equipment in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(equipment.name).font(.headline)
                            Text([AppLocalization.text("library_\(equipment.kind.rawValue)", fallback: equipment.kind.rawValue.capitalized), equipment.manufacturer, equipment.model, equipment.burrSet].filter { !$0.isEmpty }.joined(separator: " · ")).font(.caption)
                        }
                        Spacer()
                        Button(AppLocalization.text("library_edit", fallback: "Edit")) { beginEditing(equipment) }
                        Button(role: .destructive) { delete("equipment", equipment.id) } label: { Image(systemName: "trash") }
                    }
                }
                if equipmentID != nil { Button(AppLocalization.text("library_add_another", fallback: "Add another")) { clearEquipmentEditor() }.buttonStyle(.borderless) }
            }.padding(.top, 8)
        }
    }

    private var equipmentPicker: some View {
        Picker(AppLocalization.text("library_equipment", fallback: "Equipment"), selection: $equipmentID) {
            Text(AppLocalization.text("library_select_equipment", fallback: "Select equipment")).tag(nil as UUID?)
            ForEach(coffeeData.equipmentRecords()) { Text($0.name).tag(Optional($0.id)) }
        }
    }

    private var calibrationSection: some View {
        GroupBox(AppLocalization.text("library_calibrations", fallback: "Calibrations")) {
            VStack(alignment: .leading, spacing: 10) {
                equipmentPicker
                TextField(AppLocalization.text("library_setting", fallback: "Setting"), text: $calibrationSetting).textFieldStyle(.roundedBorder).accessibilityIdentifier("coffee.calibration.setting")
                HStack {
                    TextField(AppLocalization.text("library_measured_value", fallback: "Measured value"), text: $calibrationValue).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    TextField(AppLocalization.text("library_unit", fallback: "Unit"), text: $calibrationUnit).textFieldStyle(.roundedBorder)
                }
                TextField(AppLocalization.text("library_notes", fallback: "Notes"), text: $calibrationNotes).textFieldStyle(.roundedBorder)
                Button(AppLocalization.text("library_save_calibration", fallback: "Save calibration"), action: saveCalibration).buttonStyle(.borderedProminent).accessibilityIdentifier("coffee.calibration.save")
                ForEach(coffeeData.calibrationRecords()) { calibration in
                    HStack {
                        Text(calibrationDescription(calibration))
                        Spacer()
                        Button(AppLocalization.text("library_edit", fallback: "Edit")) { beginEditing(calibration) }
                        Button(role: .destructive) { delete("calibration", calibration.id) } label: { Image(systemName: "trash") }
                    }
                }
            }.padding(.top, 8)
        }
    }

    private var maintenanceSection: some View {
        GroupBox(AppLocalization.text("library_maintenance", fallback: "Maintenance")) {
            VStack(alignment: .leading, spacing: 10) {
                equipmentPicker
                TextField(AppLocalization.text("library_maintenance_type", fallback: "Maintenance type"), text: $maintenanceKind).textFieldStyle(.roundedBorder).accessibilityIdentifier("coffee.maintenance.kind")
                TextField(AppLocalization.text("library_notes", fallback: "Notes"), text: $maintenanceNotes).textFieldStyle(.roundedBorder)
                Button(AppLocalization.text("library_record_maintenance", fallback: "Record maintenance"), action: saveMaintenance).buttonStyle(.borderedProminent).accessibilityIdentifier("coffee.maintenance.save")
                ForEach(coffeeData.maintenanceRecords()) { event in
                    HStack {
                        VStack(alignment: .leading) { Text(event.kind); if !event.notes.isEmpty { Text(event.notes).font(.caption) } }
                        Spacer()
                        Button(AppLocalization.text("library_edit", fallback: "Edit")) { beginEditing(event) }
                        Button(role: .destructive) { delete("maintenance", event.id) } label: { Image(systemName: "trash") }
                    }
                }
            }.padding(.top, 8)
        }
    }

    private func beginEditing(_ equipment: CoffeeEquipmentRecord) {
        equipmentID = equipment.id; equipmentKind = equipment.kind; equipmentName = equipment.name
        equipmentManufacturer = equipment.manufacturer; equipmentModel = equipment.model
        equipmentBurrSet = equipment.burrSet
    }

    private func clearEquipmentEditor() {
        equipmentID = nil; equipmentName = ""; equipmentManufacturer = ""; equipmentModel = ""; equipmentBurrSet = ""
    }

    private func saveEquipment() {
        guard !equipmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { errorMessage = AppLocalization.text("library_enter_equipment", fallback: "Enter an equipment name."); return }
        do {
            try coffeeData.saveEquipment(recordID: equipmentID, kind: equipmentKind, name: equipmentName, manufacturer: equipmentManufacturer, model: equipmentModel, burrSet: equipmentBurrSet)
            equipmentID = coffeeData.equipmentRecords().first { $0.name == equipmentName }?.id; errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func saveCalibration() {
        guard let equipmentID, !calibrationSetting.isEmpty else { errorMessage = AppLocalization.text("library_enter_calibration", fallback: "Select equipment and enter a setting."); return }
        do {
            try coffeeData.saveCalibration(recordID: calibrationID, equipmentID: equipmentID, setting: calibrationSetting, measuredValue: Double(calibrationValue), unit: calibrationUnit, notes: calibrationNotes)
            calibrationID = nil; calibrationSetting = ""; calibrationValue = ""; calibrationNotes = ""; errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func saveMaintenance() {
        guard let equipmentID, !maintenanceKind.isEmpty else { errorMessage = AppLocalization.text("library_enter_maintenance", fallback: "Select equipment and enter a maintenance type."); return }
        do {
            try coffeeData.recordMaintenance(recordID: maintenanceID, equipmentID: equipmentID, kind: maintenanceKind, notes: maintenanceNotes)
            maintenanceID = nil; maintenanceNotes = ""; errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func beginEditing(_ calibration: CoffeeCalibrationRecord) {
        calibrationID = calibration.id; equipmentID = calibration.equipmentID; calibrationSetting = calibration.setting
        calibrationValue = calibration.measuredValue.map { String(describing: $0) } ?? ""
        calibrationUnit = calibration.unit
        calibrationNotes = calibration.notes
    }

    private func calibrationDescription(_ calibration: CoffeeCalibrationRecord) -> String {
        var parts = [calibration.setting]
        if let measuredValue = calibration.measuredValue {
            parts.append(String(describing: measuredValue))
        }
        if !calibration.unit.isEmpty {
            parts.append(calibration.unit)
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private func beginEditing(_ event: CoffeeMaintenanceRecord) {
        maintenanceID = event.id; equipmentID = event.equipmentID; maintenanceKind = event.kind; maintenanceNotes = event.notes
    }

    private func delete(_ entityType: String, _ id: UUID) {
        do { try coffeeData.deleteCoffeeRecord(entityType: entityType, id: id); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }

    private func addCoffee() {
        guard let grams = Double(quantity), grams > 0, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = AppLocalization.text("invalid_coffee_inventory", fallback: "Enter a coffee name and quantity.")
            return
        }
        do {
            try coffeeData.addPurchasedCoffee(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                roaster: roaster.trimmingCharacters(in: .whitespacesAndNewlines),
                origin: origin.trimmingCharacters(in: .whitespacesAndNewlines),
                region: region.trimmingCharacters(in: .whitespacesAndNewlines),
                variety: variety.trimmingCharacters(in: .whitespacesAndNewlines),
                process: process.trimmingCharacters(in: .whitespacesAndNewlines),
                roastLevel: roastLevel.trimmingCharacters(in: .whitespacesAndNewlines),
                tastingNotes: tastingNotes.trimmingCharacters(in: .whitespacesAndNewlines),
                roastDate: hasRoastDate ? roastDate : nil,
                quantityGrams: grams
            )
            name = ""
            roaster = ""
            origin = ""; region = ""; variety = ""; process = ""; roastLevel = ""; tastingNotes = ""
            quantity = "250"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct CoffeeLotEditorView: View {
    @EnvironmentObject private var coffeeData: CoffeeDataStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    let lot: BeanLotRecord
    @State private var name: String
    @State private var roaster: String
    @State private var origin: String
    @State private var region: String
    @State private var variety: String
    @State private var process: String
    @State private var roastLevel: String
    @State private var tastingNotes: String
    @State private var errorMessage: String?

    init(lot: BeanLotRecord) {
        self.lot = lot
        _name = State(initialValue: lot.name); _roaster = State(initialValue: lot.roaster)
        _origin = State(initialValue: lot.origin); _region = State(initialValue: lot.region)
        _variety = State(initialValue: lot.variety); _process = State(initialValue: lot.process)
        _roastLevel = State(initialValue: lot.roastLevel); _tastingNotes = State(initialValue: lot.tastingNotes)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Coffee name", text: $name)
                TextField("Roaster", text: $roaster)
                TextField("Origin", text: $origin)
                TextField("Region or producer", text: $region)
                TextField("Variety", text: $variety)
                TextField("Process", text: $process)
                TextField("Roast level", text: $roastLevel)
                TextField("Tasting notes", text: $tastingNotes)
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .scrollContentBackground(.hidden)
            .background((colorScheme == .dark ? Color(hex: 0x0A0804) : Color(hex: 0xFBF8F1)).ignoresSafeArea())
            .navigationTitle("Edit bean lot")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        do {
                            try coffeeData.saveLot(BeanLotRecord(
                                id: lot.id, name: name, roaster: roaster, origin: origin, region: region,
                                variety: variety, process: process, roastLevel: roastLevel, tastingNotes: tastingNotes,
                                productID: lot.productID, variantID: lot.variantID,
                                replacementProductID: lot.replacementProductID,
                                excludeFromReplacements: lot.excludeFromReplacements
                            ))
                            dismiss()
                        } catch { errorMessage = error.localizedDescription }
                    }
                }
            }
        }
    }
}

extension CoffeeDataStore {
    func measuredCurve(for sessionID: UUID, bucketSeconds: Double = 1) -> [BrewCurvePoint] {
        let rows = legacyObjects(entityType: "sample").filter { ($0["sessionID"] as? String).flatMap(UUID.init(uuidString:)) == sessionID }
        let weights = Dictionary(grouping: rows.filter { ($0["kind"] as? String) == SampleKind.weight.rawValue }, by: { ($0["elapsedMilliseconds"] as? NSNumber)?.intValue ?? 0 })
        let flows = Dictionary(uniqueKeysWithValues: rows.filter { ($0["kind"] as? String) == SampleKind.flow.rawValue }.compactMap { row -> (Int, Double)? in
            guard let time = (row["elapsedMilliseconds"] as? NSNumber)?.intValue, let value = (row["value"] as? NSNumber)?.doubleValue else { return nil }
            return (time, value)
        })
        guard bucketSeconds > 0 else { return [] }
        return weights.keys.sorted().compactMap { elapsed in
            guard let value = weights[elapsed]?.last?["value"] as? NSNumber else { return nil }
            return BrewCurvePoint(id: UUID(), seconds: Double(elapsed) / 1000, weightGrams: value.doubleValue, flowGramsPerSecond: flows[elapsed] ?? flows.keys.sorted().last(where: { $0 <= elapsed }).flatMap { flows[$0] })
        }.reduce(into: [Int: BrewCurvePoint]()) { result, point in
            result[Int((point.seconds / bucketSeconds).rounded())] = point
        }.values.sorted { $0.seconds < $1.seconds }
    }

    func compareMeasuredBrews(referenceID: UUID, attemptID: UUID) -> BrewCurveComparison {
        let reference = measuredCurve(for: referenceID), attempt = measuredCurve(for: attemptID)
        return BrewCurveComparison(reference: reference, attempt: attempt,
            finalWeightDifference: (attempt.last?.weightGrams ?? 0) - (reference.last?.weightGrams ?? 0),
            timeDifference: (attempt.last?.seconds ?? 0) - (reference.last?.seconds ?? 0))
    }

    func markBestMeasuredBrew(_ sessionID: UUID) {
        UserDefaults.standard.set(sessionID.uuidString, forKey: "talla.brewing.referenceBrewID.v1")
    }

    func bestMeasuredBrewID() -> UUID? {
        UUID(uuidString: UserDefaults.standard.string(forKey: "talla.brewing.referenceBrewID.v1") ?? "")
    }

    func recommendation(for sessionID: UUID, targetSeconds: Double? = nil, targetWeight: Double? = nil, rating: Int? = nil, tasteNotes: String = "") -> BrewMeasurementRecommendation? {
        let curve = measuredCurve(for: sessionID)
        guard let last = curve.last else { return nil }
        let taste = rating ?? 3
        let averageFlow = curve.suffix(8).compactMap(\.flowGramsPerSecond).reduce(0, +) / Double(max(1, curve.suffix(8).compactMap(\.flowGramsPerSecond).count))
        if taste <= 2 || tasteNotes.localizedCaseInsensitiveContains("sour") {
            return BrewMeasurementRecommendation(title: "Extract more", detail: "The cup feedback and measured curve suggest a finer grind or a 10–15 second longer finish.", confidence: 0.78)
        }
        if taste >= 4 && (targetSeconds == nil || abs(last.seconds - targetSeconds!) <= 10) {
            return BrewMeasurementRecommendation(title: "Repeat this curve", detail: "This was a strong cup with a controlled \(String(format: "%.1f", averageFlow)) g/s finish. Use it as your reference brew.", confidence: 0.86)
        }
        if let targetWeight, last.weightGrams < targetWeight * 0.95 {
            return BrewMeasurementRecommendation(title: "Increase the final pour", detail: "The measured brew finished \(String(format: "%.1f", targetWeight - last.weightGrams)) g below target.", confidence: 0.71)
        }
        return BrewMeasurementRecommendation(title: "Keep the next brew steady", detail: "The measured curve is close to target. Repeat the timing and refine from taste.", confidence: 0.58)
    }

    func shareableBrewCard(sessionID: UUID, title: String, method: String, doseGrams: Double?, isReference: Bool = false) -> ShareableBrewCard {
        let curve = measuredCurve(for: sessionID)
        return ShareableBrewCard(title: title, method: method, doseGrams: doseGrams, finalWeightGrams: curve.last?.weightGrams, durationSeconds: curve.last?.seconds, curve: curve, isReference: isReference)
    }
}

private struct TallaCoffeeGroupBoxStyle: GroupBoxStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            configuration.label
                .font(.system(size: 17, weight: .semibold, design: .rounded))
            configuration.content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorScheme == .dark ? Color(hex: 0x17120D) : Color(hex: 0xFFFCF5))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(colorScheme == .dark ? 0.18 : 0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
