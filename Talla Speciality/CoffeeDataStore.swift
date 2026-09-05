import Foundation
import SwiftData
import Combine

@MainActor
final class CoffeeDataStore: ObservableObject {
    static let shared = CoffeeDataStore()
    static let migrationKey = "coffeeData.migration.v1.completed"

    let container: ModelContainer
    @Published private(set) var changeToken = 0
    private var context: ModelContext { container.mainContext }

    func notifyCoffeeChange() {
        changeToken &+= 1
    }

    private init(inMemory: Bool = false) {
        do {
            let schema = Schema(CoffeeSchema.models)
            let configuration = ModelConfiguration("TallaCoffee", schema: schema, isStoredInMemoryOnly: inMemory)
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to open the coffee database: \(error.localizedDescription)")
        }
    }

    /// Imports the old JSON once. Original defaults remain intact until the
    /// transaction succeeds, making rollback to an older app build safe.
    func migrateLegacyJSON(defaults: UserDefaults = .standard) throws {
        guard !defaults.bool(forKey: Self.migrationKey) else { return }
        try migrateRecipes(defaults.string(forKey: "brewRecipes.saved"))
        try migrateJournal(defaults.string(forKey: "brewJournal.saved"))
        try migrateEquipment(defaults: defaults)
        try context.save()
        defaults.set(true, forKey: Self.migrationKey)
        changeToken &+= 1
    }

    func legacyObjects(entityType: String) -> [[String: Any]] {
        let descriptor = FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.entityType == entityType && $0.deletedAt == nil }, sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? context.fetch(descriptor))?.compactMap { try? JSONSerialization.jsonObject(with: $0.payload) as? [String: Any] } ?? []
    }

    func replaceLegacyRecords(entityType: String, objects: [[String: Any]]) throws {
        let activeIDs = Set(objects.compactMap { value in (value["id"] as? String).flatMap(UUID.init(uuidString:)) })
        let existing = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.entityType == entityType && $0.deletedAt == nil }))
        for envelope in existing where !activeIDs.contains(envelope.recordID) { envelope.deletedAt = .now; envelope.updatedAt = .now; envelope.dirty = true }
        let pairedType = entityType == "recipe" ? "recipeVersion" : (entityType == "brewSession" ? "tasteFeedback" : nil)
        if let pairedType {
            let paired = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.entityType == pairedType && $0.deletedAt == nil }))
            for envelope in paired where !activeIDs.contains(envelope.recordID) { envelope.deletedAt = .now; envelope.updatedAt = .now; envelope.dirty = true }
        }
        for object in objects {
            let id = (object["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
            try saveEnvelope(entityType: entityType, id: id, jsonObject: object)
            if entityType == "recipe" {
                var version = object; version["recipeID"] = id.uuidString; version["versionNumber"] = version["versionNumber"] ?? 1
                try saveEnvelope(entityType: "recipeVersion", id: id, jsonObject: version)
            } else if entityType == "brewSession" {
                let feedback: [String: Any] = ["id": id.uuidString, "sessionID": id.uuidString, "rating": object["rating"] ?? 3, "notes": object["notes"] ?? "", "createdAt": object["createdAt"] ?? Self.iso.string(from: .now)]
                try saveEnvelope(entityType: "tasteFeedback", id: id, jsonObject: feedback)
            }
        }
        try context.save(); changeToken &+= 1
    }

    func removeAllLocalCoffeeData() throws {
        for envelope in try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.deletedAt == nil })) {
            envelope.deletedAt = .now; envelope.updatedAt = .now; envelope.dirty = true
        }
        try context.save(); changeToken &+= 1
    }

    func equipmentName(kind: EquipmentKind) -> String {
        legacyObjects(entityType: "equipment").first { ($0["kind"] as? String) == kind.rawValue }?["name"] as? String ?? ""
    }

    func saveEquipmentName(kind: EquipmentKind, name: String) throws {
        let current = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.entityType == "equipment" && $0.deletedAt == nil }))
        let matching = current.first { envelope in
            ((try? JSONSerialization.jsonObject(with: envelope.payload)) as? [String: Any])?["kind"] as? String == kind.rawValue
        }
        let id = matching?.recordID ?? UUID()
        try saveEnvelope(entityType: "equipment", id: id, jsonObject: ["id": id.uuidString, "kind": kind.rawValue, "name": name])
        try context.save(); changeToken &+= 1
    }

    func calibrationJSON() -> String {
        Self.jsonString(legacyObjects(entityType: "calibration"))
    }

    func saveCalibrationJSON(_ json: String) throws {
        guard let data = json.data(using: .utf8), let objects = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        try replaceLegacyRecords(entityType: "calibration", objects: objects)
    }

    func saveEnvelope(entityType: String, id: UUID, jsonObject: [String: Any], deletedAt: Date? = nil) throws {
        let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [.sortedKeys])
        let compoundID = "\(entityType):\(id.uuidString.lowercased())"
        let descriptor = FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.compoundID == compoundID })
        if let existing = try context.fetch(descriptor).first {
            existing.payload = data; existing.updatedAt = .now; existing.deletedAt = deletedAt; existing.dirty = true
        } else {
            context.insert(CoffeeSyncEnvelope(entityType: entityType, recordID: id, payload: data, deletedAt: deletedAt))
        }
    }

    func tombstone(entityType: String, id: UUID) throws {
        try saveEnvelope(entityType: entityType, id: id, jsonObject: [:], deletedAt: .now)
        try context.save()
    }

    /// Server-wins for two edits based on the same revision. The rejected local
    /// payload is retained in conflictedPayload so the UI can offer recovery.
    func synchronize(ownerID: String, bearerToken: String, baseURL: URL) async throws {
        let cursor = try syncCursor(for: ownerID)
        let dirty = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.dirty }))
        let changes: [[String: Any]] = dirty.compactMap { envelope in
            let payload = (try? JSONSerialization.jsonObject(with: envelope.payload)) as? [String: Any] ?? [:]
            return [
                "entityType": envelope.entityType,
                "id": envelope.recordID.uuidString.lowercased(),
                "payload": payload,
                "updatedAt": Self.iso.string(from: envelope.updatedAt),
                "deletedAt": envelope.deletedAt.map(Self.iso.string(from:)) ?? NSNull(),
                "baseRevision": envelope.baseRevision
            ]
        }
        let body: [String: Any] = ["deviceID": cursor.deviceID, "cursor": cursor.cursor, "changes": changes]
        var request = URLRequest(url: baseURL.appending(path: "/coffee-data/sync"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw CoffeeDataError.syncFailed }
        guard let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw CoffeeDataError.invalidResponse }
        let conflicts = Set((responseJSON["conflicts"] as? [[String: Any]] ?? []).compactMap { value -> String? in
            guard let type = value["entityType"] as? String, let id = value["id"] as? String else { return nil }
            return "\(type):\(id.lowercased())"
        })
        for record in responseJSON["records"] as? [[String: Any]] ?? [] { try applyRemote(record, conflicts: conflicts) }
        cursor.cursor = responseJSON["cursor"] as? String ?? cursor.cursor
        cursor.lastSyncedAt = .now
        try context.save()
        changeToken &+= 1
    }

    private func syncCursor(for ownerID: String) throws -> CoffeeSyncCursor {
        let descriptor = FetchDescriptor<CoffeeSyncCursor>(predicate: #Predicate { $0.ownerID == ownerID })
        if let value = try context.fetch(descriptor).first { return value }
        let value = CoffeeSyncCursor(ownerID: ownerID); context.insert(value); return value
    }

    private func applyRemote(_ record: [String: Any], conflicts: Set<String>) throws {
        guard let type = record["entityType"] as? String, let idString = record["id"] as? String,
              let id = UUID(uuidString: idString), let payload = record["payload"] as? [String: Any] else { return }
        let key = "\(type):\(idString.lowercased())"
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        let descriptor = FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.compoundID == key })
        let envelope = try context.fetch(descriptor).first ?? CoffeeSyncEnvelope(entityType: type, recordID: id, payload: data)
        if envelope.modelContext == nil { context.insert(envelope) }
        if conflicts.contains(key) { envelope.conflictedPayload = envelope.payload }
        envelope.payload = data
        envelope.updatedAt = Self.iso.date(from: record["updatedAt"] as? String ?? "") ?? .now
        envelope.deletedAt = (record["deletedAt"] as? String).flatMap(Self.iso.date(from:))
        envelope.baseRevision = (record["revision"] as? NSNumber)?.int64Value ?? envelope.baseRevision
        envelope.dirty = false
    }

    private func migrateRecipes(_ json: String?) throws {
        guard let data = json?.data(using: .utf8), let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        for row in rows {
            let id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            let title = row["name"] as? String ?? "Imported recipe"
            let kind: BrewSessionKind = ((row["category"] as? String)?.lowercased().contains("espresso") == true) ? .espresso : .filter
            let recipe = CoffeeRecipe(id: id, title: title, kind: kind)
            let versionID = id; recipe.currentVersionID = versionID
            context.insert(recipe)
            context.insert(RecipeVersion(id: versionID, recipeID: id, versionNumber: 1, coffeeGrams: row["coffeeGrams"] as? Double ?? 0, waterGrams: row["waterGrams"] as? Double, temperatureC: (row["temperatureC"] as? NSNumber)?.doubleValue, grindSetting: row["grind"] as? String, stepsJSON: Self.jsonString(row["steps"]) ))
            try saveEnvelope(entityType: "recipe", id: id, jsonObject: row)
            var versionPayload = row; versionPayload["recipeID"] = id.uuidString; versionPayload["versionNumber"] = 1
            try saveEnvelope(entityType: "recipeVersion", id: versionID, jsonObject: versionPayload)
        }
    }

    private func migrateJournal(_ json: String?) throws {
        guard let data = json?.data(using: .utf8), let rows = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        for row in rows {
            let id = UUID(uuidString: row["id"] as? String ?? "") ?? UUID()
            let started = Self.iso.date(from: row["createdAt"] as? String ?? "") ?? .now
            let kind: BrewSessionKind = ((row["method"] as? String)?.lowercased().contains("espresso") == true) ? .espresso : .filter
            context.insert(CoffeeBrewSession(id: id, kind: kind, startedAt: started, endedAt: started, doseGrams: (row["coffeeGrams"] as? NSNumber)?.doubleValue, yieldGrams: (row["waterGrams"] as? NSNumber)?.doubleValue, notes: row["title"] as? String))
            let feedbackID = id
            context.insert(CoffeeTasteFeedback(id: feedbackID, sessionID: id, rating: (row["rating"] as? NSNumber)?.intValue ?? 3, notes: row["notes"] as? String ?? ""))
            try saveEnvelope(entityType: "brewSession", id: id, jsonObject: row)
            try saveEnvelope(entityType: "tasteFeedback", id: feedbackID, jsonObject: ["sessionID": id.uuidString, "rating": row["rating"] ?? 3, "notes": row["notes"] ?? ""])
        }
    }

    private func migrateEquipment(defaults: UserDefaults) throws {
        let values: [(String, EquipmentKind)] = [(defaults.string(forKey: "talla.brewing.profileBrewer.v1") ?? "", .brewer), (defaults.string(forKey: "talla.brewing.equipmentGrinder.v1") ?? "", .grinder)]
        for (name, kind) in values where !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let equipment = CoffeeEquipment(kind: kind, name: name); context.insert(equipment)
            try saveEnvelope(entityType: "equipment", id: equipment.id, jsonObject: ["kind": kind.rawValue, "name": name])
        }
        guard let raw = defaults.string(forKey: "talla.brewing.coffeeCalibrations.v1"), let data = raw.data(using: .utf8),
              let rows = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return }
        for row in rows {
            let equipment = CoffeeEquipment(kind: .grinder, name: row["roaster"] as? String ?? "Imported calibration")
            context.insert(equipment)
            let calibration = EquipmentCalibration(equipmentID: equipment.id, setting: "legacy-smart-brew", notes: Self.jsonString(row))
            context.insert(calibration)
            try saveEnvelope(entityType: "calibration", id: calibration.id, jsonObject: row)
        }
    }

    private static func jsonString(_ value: Any?) -> String {
        guard let value, JSONSerialization.isValidJSONObject(value), let data = try? JSONSerialization.data(withJSONObject: value) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private static let iso: ISO8601DateFormatter = { let value = ISO8601DateFormatter(); value.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return value }()
}

enum CoffeeDataError: Error { case syncFailed, invalidResponse }
