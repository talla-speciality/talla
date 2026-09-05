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

struct CoffeeDataConflict: Identifiable {
    let entityType: String
    let recordID: UUID
    let localPayload: Data
    let serverPayload: Data

    var id: String { "\(entityType):\(recordID.uuidString.lowercased())" }
}

extension CoffeeDataStore {
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

    func recordMaintenance(equipmentID: UUID, kind: String, notes: String, ownerID: String? = nil) throws {
        let event = MaintenanceEvent(equipmentID: equipmentID, kind: kind, notes: notes, ownerID: ownerID)
        container.mainContext.insert(event)
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
    @State private var errorMessage: String?

    var body: some View {
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
