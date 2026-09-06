import SwiftData
import SwiftUI

struct CoffeeInventoryRecord: Identifiable {
    let id: UUID
    let lotID: UUID?
    let productName: String
    let roaster: String
    let roastDate: Date?
    let initialQuantityGrams: Double
    let remainingQuantityGrams: Double
}

struct CoffeeEquipmentRecord: Identifiable {
    let id: UUID
    let kind: EquipmentKind
    let name: String
    let manufacturer: String
    let model: String
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
                id: id, kind: kind, name: row["name"] as? String ?? "Equipment",
                manufacturer: row["manufacturer"] as? String ?? "", model: row["model"] as? String ?? ""
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
                id: id, equipmentID: equipmentID, kind: row["kind"] as? String ?? "Maintenance",
                performedAt: (row["performedAt"] as? String).flatMap(Self.coffeeISO.date(from:)),
                notes: row["notes"] as? String ?? ""
            )
        }
    }

    func saveEquipment(recordID: UUID? = nil, kind: EquipmentKind, name: String, manufacturer: String, model: String, ownerID: String? = nil) throws {
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
            "manufacturer": manufacturer, "model": model
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
        notifyCoffeeChange()
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
                roastDate: (row["roastDate"] as? String).flatMap(Self.coffeeISO.date(from:)),
                initialQuantityGrams: (row["initialQuantityGrams"] as? NSNumber)?.doubleValue ?? 0,
                remainingQuantityGrams: (row["remainingQuantityGrams"] as? NSNumber)?.doubleValue ?? 0
            )
        }
    }

    func addPurchasedCoffee(
        name: String,
        roaster: String,
        roastDate: Date?,
        quantityGrams: Double,
        ownerID: String? = nil
    ) throws {
        let lot = CoffeeLot(name: name, roaster: roaster, ownerID: ownerID)
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
            "roaster": roaster
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
        ownerID: String? = nil
    ) throws {
        let kind: BrewSessionKind = method.localizedCaseInsensitiveContains("espresso") ? .espresso : .filter
        let startedAt = Date().addingTimeInterval(-Double(durationSeconds ?? 0))
        let session = CoffeeBrewSession(
            id: id,
            kind: kind,
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
        if let waterGrams {
            let sample = BrewSample(
                sessionID: id,
                kind: .weight,
                elapsedMilliseconds: max(durationSeconds ?? 0, 0) * 1_000,
                value: waterGrams,
                unit: "g",
                ownerID: ownerID
            )
            container.mainContext.insert(sample)
            try saveEnvelope(entityType: "sample", id: sample.id, jsonObject: [
                "id": sample.id.uuidString,
                "sessionID": id.uuidString,
                "kind": SampleKind.weight.rawValue,
                "elapsedMilliseconds": sample.elapsedMilliseconds,
                "value": waterGrams,
                "unit": "g"
            ])
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
    @State private var name = ""
    @State private var roaster = ""
    @State private var quantity = "250"
    @State private var roastDate = Date()
    @State private var hasRoastDate = true
    @State private var equipmentID: UUID?
    @State private var equipmentKind = EquipmentKind.brewer
    @State private var equipmentName = ""
    @State private var equipmentManufacturer = ""
    @State private var equipmentModel = ""
    @State private var calibrationSetting = ""
    @State private var calibrationID: UUID?
    @State private var calibrationValue = ""
    @State private var calibrationUnit = ""
    @State private var calibrationNotes = ""
    @State private var maintenanceKind = "Cleaning"
    @State private var maintenanceNotes = ""
    @State private var maintenanceID: UUID?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
        VStack(alignment: .leading, spacing: 18) {
            Text(AppLocalization.text("coffee_inventory", fallback: "Coffee inventory"))
                .font(.system(size: 28, weight: .semibold, design: .serif))
                .accessibilityAddTraits(.isHeader)

            GroupBox(AppLocalization.text("add_coffee", fallback: "Add coffee")) {
                VStack(spacing: 12) {
                    TextField(AppLocalization.text("coffee_name", fallback: "Coffee name"), text: $name)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityIdentifier("coffee.inventory.name")
                    TextField(AppLocalization.text("roaster", fallback: "Roaster"), text: $roaster)
                        .textFieldStyle(.roundedBorder)
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
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
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
        .onAppear { equipmentID = equipmentID ?? coffeeData.equipmentRecords().first?.id }
    }

    private var equipmentSection: some View {
        GroupBox("Equipment") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Type", selection: $equipmentKind) {
                    ForEach(EquipmentKind.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                TextField("Name", text: $equipmentName).textFieldStyle(.roundedBorder).accessibilityIdentifier("coffee.equipment.name")
                TextField("Manufacturer", text: $equipmentManufacturer).textFieldStyle(.roundedBorder)
                TextField("Model", text: $equipmentModel).textFieldStyle(.roundedBorder)
                Button(equipmentID == nil ? "Add equipment" : "Save equipment", action: saveEquipment)
                    .buttonStyle(.borderedProminent).accessibilityIdentifier("coffee.equipment.save")
                ForEach(coffeeData.equipmentRecords()) { equipment in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(equipment.name).font(.headline)
                            Text([equipment.kind.rawValue.capitalized, equipment.manufacturer, equipment.model].filter { !$0.isEmpty }.joined(separator: " · ")).font(.caption)
                        }
                        Spacer()
                        Button("Edit") { beginEditing(equipment) }
                        Button(role: .destructive) { delete("equipment", equipment.id) } label: { Image(systemName: "trash") }
                    }
                }
                if equipmentID != nil { Button("Add another") { clearEquipmentEditor() }.buttonStyle(.borderless) }
            }.padding(.top, 8)
        }
    }

    private var equipmentPicker: some View {
        Picker("Equipment", selection: $equipmentID) {
            Text("Select equipment").tag(nil as UUID?)
            ForEach(coffeeData.equipmentRecords()) { Text($0.name).tag(Optional($0.id)) }
        }
    }

    private var calibrationSection: some View {
        GroupBox("Calibrations") {
            VStack(alignment: .leading, spacing: 10) {
                equipmentPicker
                TextField("Setting", text: $calibrationSetting).textFieldStyle(.roundedBorder).accessibilityIdentifier("coffee.calibration.setting")
                HStack {
                    TextField("Measured value", text: $calibrationValue).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    TextField("Unit", text: $calibrationUnit).textFieldStyle(.roundedBorder)
                }
                TextField("Notes", text: $calibrationNotes).textFieldStyle(.roundedBorder)
                Button("Save calibration", action: saveCalibration).buttonStyle(.borderedProminent).accessibilityIdentifier("coffee.calibration.save")
                ForEach(coffeeData.calibrationRecords()) { calibration in
                    HStack {
                        Text([calibration.setting, calibration.measuredValue.map { String($0) } ?? "", calibration.unit].filter { !$0.isEmpty }.joined(separator: " · "))
                        Spacer()
                        Button("Edit") { beginEditing(calibration) }
                        Button(role: .destructive) { delete("calibration", calibration.id) } label: { Image(systemName: "trash") }
                    }
                }
            }.padding(.top, 8)
        }
    }

    private var maintenanceSection: some View {
        GroupBox("Maintenance") {
            VStack(alignment: .leading, spacing: 10) {
                equipmentPicker
                TextField("Maintenance type", text: $maintenanceKind).textFieldStyle(.roundedBorder).accessibilityIdentifier("coffee.maintenance.kind")
                TextField("Notes", text: $maintenanceNotes).textFieldStyle(.roundedBorder)
                Button("Record maintenance", action: saveMaintenance).buttonStyle(.borderedProminent).accessibilityIdentifier("coffee.maintenance.save")
                ForEach(coffeeData.maintenanceRecords()) { event in
                    HStack {
                        VStack(alignment: .leading) { Text(event.kind); if !event.notes.isEmpty { Text(event.notes).font(.caption) } }
                        Spacer()
                        Button("Edit") { beginEditing(event) }
                        Button(role: .destructive) { delete("maintenance", event.id) } label: { Image(systemName: "trash") }
                    }
                }
            }.padding(.top, 8)
        }
    }

    private func beginEditing(_ equipment: CoffeeEquipmentRecord) {
        equipmentID = equipment.id; equipmentKind = equipment.kind; equipmentName = equipment.name
        equipmentManufacturer = equipment.manufacturer; equipmentModel = equipment.model
    }

    private func clearEquipmentEditor() {
        equipmentID = nil; equipmentName = ""; equipmentManufacturer = ""; equipmentModel = ""
    }

    private func saveEquipment() {
        guard !equipmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { errorMessage = "Enter an equipment name."; return }
        do {
            try coffeeData.saveEquipment(recordID: equipmentID, kind: equipmentKind, name: equipmentName, manufacturer: equipmentManufacturer, model: equipmentModel)
            equipmentID = coffeeData.equipmentRecords().first { $0.name == equipmentName }?.id; errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func saveCalibration() {
        guard let equipmentID, !calibrationSetting.isEmpty else { errorMessage = "Select equipment and enter a setting."; return }
        do {
            try coffeeData.saveCalibration(recordID: calibrationID, equipmentID: equipmentID, setting: calibrationSetting, measuredValue: Double(calibrationValue), unit: calibrationUnit, notes: calibrationNotes)
            calibrationID = nil; calibrationSetting = ""; calibrationValue = ""; calibrationNotes = ""; errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func saveMaintenance() {
        guard let equipmentID, !maintenanceKind.isEmpty else { errorMessage = "Select equipment and enter a maintenance type."; return }
        do {
            try coffeeData.recordMaintenance(recordID: maintenanceID, equipmentID: equipmentID, kind: maintenanceKind, notes: maintenanceNotes)
            maintenanceID = nil; maintenanceNotes = ""; errorMessage = nil
        } catch { errorMessage = error.localizedDescription }
    }

    private func beginEditing(_ calibration: CoffeeCalibrationRecord) {
        calibrationID = calibration.id; equipmentID = calibration.equipmentID; calibrationSetting = calibration.setting
        calibrationValue = calibration.measuredValue.map { String($0) } ?? ""; calibrationUnit = calibration.unit; calibrationNotes = calibration.notes
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
                roastDate: hasRoastDate ? roastDate : nil,
                quantityGrams: grams
            )
            name = ""
            roaster = ""
            quantity = "250"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
