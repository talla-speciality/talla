import Foundation
import SwiftData
import Combine

@MainActor
final class CoffeeDataStore: ObservableObject {
    typealias DataLoader = (URLRequest) async throws -> (Data, URLResponse)

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case synced(Date)
        case offline
        case failed(String)
    }

    enum StorageMode: Equatable {
        case persistent
        case recoveryPersistent
        case memoryOnly
    }

    static let shared = CoffeeDataStore()
    static let migrationKey = "coffeeData.migration.v1.completed"
    static let storageOwnerKey = "coffeeData.storage.owner.v1"
    static let maximumChangesPerRequest = 500
    static let maximumRemotePagesPerSync = 1_000

    let container: ModelContainer
    @Published private(set) var changeToken = 0
    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var storageMode: StorageMode = .persistent
    @Published private(set) var storageRecoveryMessage: String?
    private var context: ModelContext { container.mainContext }
    private let dataLoader: DataLoader
    private let automaticSyncEnabled: Bool
    private let storageDefaults: UserDefaults
    private var automaticSyncTask: Task<Void, Never>?
    private var activeRequestTask: Task<(Data, URLResponse), Error>?
    private var isSynchronizing = false
    private var shouldSynchronizeAgain = false
    private var storageGeneration = 0

    func notifyCoffeeChange(scheduleSynchronization: Bool = true) {
        changeToken &+= 1
        if scheduleSynchronization && automaticSyncEnabled {
            scheduleAutomaticSynchronization()
        }
    }

    init(
        inMemory: Bool = false,
        automaticSyncEnabled: Bool? = nil,
        storageDefaults: UserDefaults = .standard,
        dataLoader: @escaping DataLoader = { request in
            try await AccountService.data(for: request)
        }
    ) {
        self.dataLoader = dataLoader
        self.automaticSyncEnabled = automaticSyncEnabled ?? !inMemory
        self.storageDefaults = storageDefaults
        let schema = Schema(CoffeeSchema.models)
        do {
            let configuration = ModelConfiguration("TallaCoffee", schema: schema, isStoredInMemoryOnly: inMemory)
            container = try ModelContainer(for: schema, configurations: [configuration])
            storageMode = inMemory ? .memoryOnly : .persistent
        } catch let primaryError {
            do {
                let recoveryConfiguration = ModelConfiguration("TallaCoffeeRecovery", schema: schema, isStoredInMemoryOnly: false)
                container = try ModelContainer(for: schema, configurations: [recoveryConfiguration])
                storageMode = .recoveryPersistent
                storageRecoveryMessage = "The primary coffee database could not be opened. Talla preserved it and switched to a recovery database. (\(primaryError.localizedDescription))"
            } catch let recoveryError {
                do {
                    let memoryConfiguration = ModelConfiguration("TallaCoffeeEmergency", schema: schema, isStoredInMemoryOnly: true)
                    container = try ModelContainer(for: schema, configurations: [memoryConfiguration])
                    storageMode = .memoryOnly
                    storageRecoveryMessage = "Coffee data is temporarily available in memory because persistent storage could not be opened. Primary error: \(primaryError.localizedDescription). Recovery error: \(recoveryError.localizedDescription)."
                } catch {
                    preconditionFailure("SwiftData could not create a persistent or in-memory coffee store: \(error.localizedDescription)")
                }
            }
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
        notifyCoffeeChange()
    }

    func legacyObjects(entityType: String) -> [[String: Any]] {
        let descriptor = FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.entityType == entityType && $0.deletedAt == nil }, sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
        return (try? context.fetch(descriptor))?.compactMap { try? JSONSerialization.jsonObject(with: $0.payload) as? [String: Any] } ?? []
    }

    func replaceLegacyRecords(entityType: String, objects: [[String: Any]]) throws {
        if entityType == "recipe" {
            try replaceRecipeRecords(objects, tombstoneMissing: true)
            try context.save(); notifyCoffeeChange()
            return
        }
        let activeIDs = Set(objects.compactMap { value in (value["id"] as? String).flatMap(UUID.init(uuidString:)) })
        let existing = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.entityType == entityType && $0.deletedAt == nil }))
        for envelope in existing where !activeIDs.contains(envelope.recordID) { envelope.deletedAt = .now; envelope.updatedAt = .now; envelope.dirty = true }
        let pairedType = entityType == "brewSession" ? "tasteFeedback" : nil
        if let pairedType {
            let paired = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.entityType == pairedType && $0.deletedAt == nil }))
            for envelope in paired where !activeIDs.contains(envelope.recordID) { envelope.deletedAt = .now; envelope.updatedAt = .now; envelope.dirty = true }
        }
        if entityType == "brewSession" {
            let samples = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.entityType == "sample" && $0.deletedAt == nil }))
            for envelope in samples {
                guard let sessionID = sampleSessionID(in: envelope), !activeIDs.contains(sessionID) else { continue }
                envelope.deletedAt = .now; envelope.updatedAt = .now; envelope.dirty = true
            }
        }
        for object in objects {
            let id = (object["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
            try saveEnvelope(entityType: entityType, id: id, jsonObject: object)
            if entityType == "brewSession" {
                let feedback: [String: Any] = ["id": id.uuidString, "sessionID": id.uuidString, "rating": object["rating"] ?? 3, "notes": object["notes"] ?? "", "createdAt": object["createdAt"] ?? Self.iso.string(from: .now)]
                try saveEnvelope(entityType: "tasteFeedback", id: id, jsonObject: feedback)
            }
        }
        try context.save(); notifyCoffeeChange()
    }

    /// Permanently removes the local cache after account deletion. This is a
    /// privacy boundary, so deleted account data must not remain as a pending
    /// tombstone that could later synchronize into a different account.
    func removeAllLocalCoffeeData() throws {
        automaticSyncTask?.cancel()
        automaticSyncTask = nil
        activeRequestTask?.cancel()
        storageGeneration &+= 1

        for value in try context.fetch(FetchDescriptor<CoffeeLot>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<PurchasedCoffee>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<CoffeeEquipment>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<EquipmentCalibration>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<CoffeeRecipe>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<RecipeVersion>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<CoffeeBrewSession>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<BrewSample>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<CoffeeTasteFeedback>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<MaintenanceEvent>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>()) { context.delete(value) }
        for value in try context.fetch(FetchDescriptor<CoffeeSyncCursor>()) { context.delete(value) }

        try context.save()
        storageDefaults.removeObject(forKey: Self.storageOwnerKey)
        syncStatus = .idle
        notifyCoffeeChange(scheduleSynchronization: false)
    }

    /// The on-device cache belongs to one account at a time. The first signed-in
    /// account adopts migrated local records; switching accounts clears the old
    /// cache before any request for the new account can be sent.
    func associateLocalStorage(with ownerID: String) throws {
        let normalizedOwner = ownerID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalizedOwner.isEmpty else { throw CoffeeDataError.invalidResponse }
        let previousOwner = storageDefaults.string(forKey: Self.storageOwnerKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let previousOwner, !previousOwner.isEmpty, previousOwner != normalizedOwner {
            try removeAllLocalCoffeeData()
        }
        storageDefaults.set(normalizedOwner, forKey: Self.storageOwnerKey)
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
        try context.save(); notifyCoffeeChange()
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
            if existing.payload == data && existing.deletedAt == deletedAt { return }
            existing.payload = data; existing.updatedAt = .now; existing.deletedAt = deletedAt; existing.dirty = true
        } else {
            context.insert(CoffeeSyncEnvelope(entityType: entityType, recordID: id, payload: data, deletedAt: deletedAt))
        }
    }

    func tombstone(entityType: String, id: UUID) throws {
        try saveEnvelope(entityType: entityType, id: id, jsonObject: [:], deletedAt: .now)
        if entityType == "brewSession" {
            let children = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>()).filter {
                ($0.entityType == "sample" || $0.entityType == "tasteFeedback")
                    && $0.deletedAt == nil
                    && sampleSessionID(in: $0) == id
            }
            for child in children {
                child.deletedAt = .now
                child.updatedAt = .now
                child.dirty = true
            }
        }
        try context.save()
        notifyCoffeeChange()
    }

    private func sampleSessionID(in envelope: CoffeeSyncEnvelope) -> UUID? {
        guard let payload = try? JSONSerialization.jsonObject(with: envelope.payload) as? [String: Any],
              let value = payload["sessionID"] as? String else { return nil }
        return UUID(uuidString: value)
    }

    /// Server-wins for two edits based on the same revision. The rejected local
    /// payload is retained in conflictedPayload so the UI can offer recovery.
    func synchronize(ownerID: String, bearerToken: String, baseURL: URL) async throws {
        let normalizedOwner = ownerID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        try associateLocalStorage(with: normalizedOwner)
        let expectedGeneration = storageGeneration
        guard !isSynchronizing else {
            shouldSynchronizeAgain = true
            return
        }
        isSynchronizing = true
        syncStatus = .syncing
        defer {
            isSynchronizing = false
            activeRequestTask = nil
            if shouldSynchronizeAgain {
                shouldSynchronizeAgain = false
                if automaticSyncEnabled { scheduleAutomaticSynchronization() }
            }
        }
        do {
            let cursor = try syncCursor(for: normalizedOwner)
            let dirty = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.dirty }))
            let allChanges = dirty.compactMap(syncChange(from:))
            var batches = allChanges.chunked(into: Self.maximumChangesPerRequest)
            if batches.isEmpty { batches = [[]] }

            var batchIndex = 0
            var hasMore = true
            var pageCount = 0
            while batchIndex < batches.count || hasMore {
                guard pageCount < Self.maximumRemotePagesPerSync else {
                    throw CoffeeDataError.invalidResponse
                }
                let changes = batchIndex < batches.count ? batches[batchIndex] : []
                if batchIndex < batches.count { batchIndex += 1 }
                let previousCursor = cursor.cursor
                let responseJSON = try await performSyncRequest(
                    deviceID: cursor.deviceID,
                    cursor: cursor.cursor,
                    changes: changes,
                    bearerToken: bearerToken,
                    baseURL: baseURL
                )
                guard storageGeneration == expectedGeneration,
                      storageDefaults.string(forKey: Self.storageOwnerKey) == normalizedOwner else {
                    throw CancellationError()
                }
                let conflicts = Set((responseJSON["conflicts"] as? [[String: Any]] ?? []).compactMap { value -> String? in
                    guard let type = value["entityType"] as? String, let id = value["id"] as? String else { return nil }
                    return "\(type):\(id.lowercased())"
                })
                for record in responseJSON["records"] as? [[String: Any]] ?? [] {
                    try applyRemote(record, conflicts: conflicts)
                }
                cursor.cursor = responseJSON["cursor"] as? String ?? cursor.cursor
                cursor.lastSyncedAt = .now
                hasMore = responseJSON["hasMore"] as? Bool ?? false
                if hasMore && changes.isEmpty && cursor.cursor == previousCursor {
                    throw CoffeeDataError.invalidResponse
                }
                try context.save()
                pageCount += 1
            }
            notifyCoffeeChange(scheduleSynchronization: false)
            syncStatus = .synced(.now)

            let remainingDirty = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>(predicate: #Predicate { $0.dirty }))
            if !remainingDirty.isEmpty && automaticSyncEnabled {
                scheduleAutomaticSynchronization()
            }
        } catch is CancellationError {
            syncStatus = .idle
            throw CancellationError()
        } catch {
            if let urlError = error as? URLError,
               [.notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .timedOut].contains(urlError.code) {
                syncStatus = .offline
            } else {
                syncStatus = .failed(error.localizedDescription)
            }
            throw error
        }
    }

    private func syncChange(from envelope: CoffeeSyncEnvelope) -> [String: Any]? {
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

    private func performSyncRequest(
        deviceID: String,
        cursor: String,
        changes: [[String: Any]],
        bearerToken: String,
        baseURL: URL
    ) async throws -> [String: Any] {
        let body: [String: Any] = ["deviceID": deviceID, "cursor": cursor, "changes": changes]
        var request = URLRequest(url: baseURL.appending(path: "/coffee-data/sync"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let requestTask = Task { try await dataLoader(request) }
        activeRequestTask = requestTask
        let (data, response) = try await requestTask.value
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw CoffeeDataError.syncFailed
        }
        guard let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CoffeeDataError.invalidResponse
        }
        return responseJSON
    }

    private func scheduleAutomaticSynchronization() {
        automaticSyncTask?.cancel()
        automaticSyncTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(750))
            guard !Task.isCancelled, let self else { return }
            await self.retryCurrentAccountSynchronization()
        }
    }

    func retryCurrentAccountSynchronization() async {
        let owner = UserDefaults.standard.string(forKey: "local.customerEmail")?
            .trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let token = TallaAccountCredentialStore.accessToken
        guard !owner.isEmpty, !token.isEmpty, let baseURL = BackendConfiguration.serviceBaseURL else {
            syncStatus = .offline
            return
        }
        try? await synchronize(ownerID: owner, bearerToken: token, baseURL: baseURL)
    }

#if DEBUG
    func configureOfflineRecoveryUITest() throws {
        if inventory().isEmpty {
            try addPurchasedCoffee(name: "Cached V60", roaster: "Talla", roastDate: .now, quantityGrams: 250)
        }
        automaticSyncTask?.cancel()
        automaticSyncTask = nil
        syncStatus = .offline
    }
#endif

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
        try replaceRecipeRecords(rows, tombstoneMissing: false)
    }

    /// A recipe is the mutable pointer to its current revision; every content
    /// change creates a separate immutable recipeVersion record.
    private func replaceRecipeRecords(_ objects: [[String: Any]], tombstoneMissing: Bool) throws {
        let recipeEnvelopes = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>()).filter {
            $0.entityType == "recipe" && $0.deletedAt == nil
        }
        let versionEnvelopes = try context.fetch(FetchDescriptor<CoffeeSyncEnvelope>()).filter {
            $0.entityType == "recipeVersion" && $0.deletedAt == nil
        }
        let activeIDs = Set(objects.compactMap { ($0["id"] as? String).flatMap(UUID.init(uuidString:)) })

        if tombstoneMissing {
            for envelope in recipeEnvelopes where !activeIDs.contains(envelope.recordID) {
                envelope.deletedAt = .now
                envelope.updatedAt = .now
                envelope.dirty = true
            }
        }

        let typedRecipes = try context.fetch(FetchDescriptor<CoffeeRecipe>())
        for rawObject in objects {
            let recipeID = (rawObject["id"] as? String).flatMap(UUID.init(uuidString:)) ?? UUID()
            let recipeIDString = recipeID.uuidString.lowercased()
            var recipePayload = rawObject
            recipePayload["id"] = recipeIDString

            let currentEnvelope = recipeEnvelopes.first { $0.recordID == recipeID }
            let currentPayload = currentEnvelope.flatMap {
                try? JSONSerialization.jsonObject(with: $0.payload) as? [String: Any]
            } ?? nil
            let recipeVersions = versionEnvelopes.compactMap { envelope -> (CoffeeSyncEnvelope, [String: Any])? in
                guard let payload = try? JSONSerialization.jsonObject(with: envelope.payload) as? [String: Any],
                      (payload["recipeID"] as? String)?.lowercased() == recipeIDString else { return nil }
                return (envelope, payload)
            }
            let currentVersionID = (currentPayload?["currentVersionID"] as? String).flatMap(UUID.init(uuidString:))
            let currentVersion = currentVersionID.flatMap { id in recipeVersions.first { $0.0.recordID == id } }
                ?? recipeVersions.max { lhs, rhs in
                    (lhs.1["versionNumber"] as? NSNumber)?.intValue ?? 0 < (rhs.1["versionNumber"] as? NSNumber)?.intValue ?? 0
                }
            let contentChanged = currentVersion.map { recipeFingerprint($0.1) != recipeFingerprint(recipePayload) } ?? true

            let versionID: UUID
            let versionNumber: Int
            if contentChanged {
                versionID = UUID()
                versionNumber = (recipeVersions.compactMap { ($0.1["versionNumber"] as? NSNumber)?.intValue }.max() ?? 0) + 1
                var versionPayload = recipePayload
                versionPayload["id"] = versionID.uuidString.lowercased()
                versionPayload["recipeID"] = recipeIDString
                versionPayload["versionNumber"] = versionNumber
                versionPayload["createdAt"] = Self.iso.string(from: .now)
                try saveEnvelope(entityType: "recipeVersion", id: versionID, jsonObject: versionPayload)
                context.insert(RecipeVersion(
                    id: versionID,
                    recipeID: recipeID,
                    versionNumber: versionNumber,
                    coffeeGrams: (recipePayload["coffeeGrams"] as? NSNumber)?.doubleValue ?? 0,
                    waterGrams: (recipePayload["waterGrams"] as? NSNumber)?.doubleValue,
                    targetYieldGrams: (recipePayload["targetYieldGrams"] as? NSNumber)?.doubleValue,
                    temperatureC: (recipePayload["temperatureC"] as? NSNumber)?.doubleValue,
                    targetSeconds: (recipePayload["targetSeconds"] as? NSNumber)?.intValue,
                    grindSetting: recipePayload["grind"] as? String,
                    pressureBar: (recipePayload["pressureBar"] as? NSNumber)?.doubleValue,
                    stepsJSON: Self.jsonString(recipePayload["steps"]),
                    notes: recipePayload["notes"] as? String
                ))
            } else {
                versionID = currentVersion?.0.recordID ?? UUID()
                versionNumber = (currentVersion?.1["versionNumber"] as? NSNumber)?.intValue ?? 1
            }

            recipePayload["currentVersionID"] = versionID.uuidString.lowercased()
            recipePayload["versionNumber"] = versionNumber
            try saveEnvelope(entityType: "recipe", id: recipeID, jsonObject: recipePayload)

            let kind: BrewSessionKind = ((recipePayload["category"] as? String)?.lowercased().contains("espresso") == true) ? .espresso : .filter
            if let recipe = typedRecipes.first(where: { $0.id == recipeID }) {
                recipe.title = recipePayload["name"] as? String ?? recipe.title
                recipe.kindRaw = kind.rawValue
                recipe.currentVersionID = versionID
                recipe.updatedAt = .now
                recipe.syncStateRaw = CoffeeSyncState.dirty.rawValue
            } else {
                context.insert(CoffeeRecipe(
                    id: recipeID,
                    title: recipePayload["name"] as? String ?? "Recipe",
                    kind: kind,
                    currentVersionID: versionID
                ))
            }
        }
    }

    private func recipeFingerprint(_ payload: [String: Any]) -> Data? {
        var comparable = payload
        ["id", "recipeID", "currentVersionID", "versionNumber", "createdAt", "updatedAt"].forEach {
            comparable.removeValue(forKey: $0)
        }
        return try? JSONSerialization.data(withJSONObject: comparable, options: [.sortedKeys])
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

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0, !isEmpty else { return [] }
        return stride(from: 0, to: count, by: size).map { start in
            Array(self[start..<Swift.min(start + size, count)])
        }
    }
}

enum CoffeeDataError: Error { case syncFailed, invalidResponse }
