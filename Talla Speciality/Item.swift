import Foundation
import SwiftData

protocol CoffeeSyncedModel: AnyObject {
    var id: UUID { get }
    var ownerID: String? { get set }
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
    var deletedAt: Date? { get set }
    var revision: Int64 { get set }
    var syncStateRaw: String { get set }
}

enum CoffeeSyncState: String, Codable { case clean, dirty, conflicted }
enum EquipmentKind: String, Codable, CaseIterable { case brewer, machine, basket, grinder }
enum BrewSessionKind: String, Codable { case filter, espresso }
enum SampleKind: String, Codable { case weight, flow, pressure, temperature }

@Model final class CoffeeLot: CoffeeSyncedModel {
    @Attribute(.unique) var id: UUID
    var ownerID: String?; var createdAt: Date; var updatedAt: Date; var deletedAt: Date?
    var revision: Int64; var syncStateRaw: String
    var name: String; var roaster: String; var origin: String?; var producer: String?
    var variety: String?; var process: String?; var roastLevel: String?; var notes: String?
    init(id: UUID = UUID(), name: String, roaster: String = "", origin: String? = nil, producer: String? = nil, variety: String? = nil, process: String? = nil, roastLevel: String? = nil, notes: String? = nil, ownerID: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, revision: Int64 = 0, syncState: CoffeeSyncState = .dirty) {
        self.id=id; self.name=name; self.roaster=roaster; self.origin=origin; self.producer=producer; self.variety=variety; self.process=process; self.roastLevel=roastLevel; self.notes=notes; self.ownerID=ownerID; self.createdAt=createdAt; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.revision=revision; self.syncStateRaw=syncState.rawValue
    }
}

@Model final class PurchasedCoffee: CoffeeSyncedModel {
    @Attribute(.unique) var id: UUID
    var ownerID: String?; var createdAt: Date; var updatedAt: Date; var deletedAt: Date?
    var revision: Int64; var syncStateRaw: String
    var lotID: UUID?; var productID: String?; var productName: String; var roastDate: Date?
    var purchasedAt: Date?; var initialQuantityGrams: Double; var remainingQuantityGrams: Double
    var currencyCode: String?; var priceMinor: Int?
    init(id: UUID = UUID(), lotID: UUID? = nil, productID: String? = nil, productName: String, roastDate: Date? = nil, purchasedAt: Date? = nil, initialQuantityGrams: Double, remainingQuantityGrams: Double, currencyCode: String? = nil, priceMinor: Int? = nil, ownerID: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, revision: Int64 = 0, syncState: CoffeeSyncState = .dirty) {
        self.id=id; self.lotID=lotID; self.productID=productID; self.productName=productName; self.roastDate=roastDate; self.purchasedAt=purchasedAt; self.initialQuantityGrams=initialQuantityGrams; self.remainingQuantityGrams=remainingQuantityGrams; self.currencyCode=currencyCode; self.priceMinor=priceMinor; self.ownerID=ownerID; self.createdAt=createdAt; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.revision=revision; self.syncStateRaw=syncState.rawValue
    }
}

@Model final class CoffeeEquipment: CoffeeSyncedModel {
    @Attribute(.unique) var id: UUID
    var ownerID: String?; var createdAt: Date; var updatedAt: Date; var deletedAt: Date?
    var revision: Int64; var syncStateRaw: String
    var kindRaw: String; var name: String; var manufacturer: String?; var model: String?
    var parentEquipmentID: UUID?; var notes: String?
    init(id: UUID = UUID(), kind: EquipmentKind, name: String, manufacturer: String? = nil, model: String? = nil, parentEquipmentID: UUID? = nil, notes: String? = nil, ownerID: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, revision: Int64 = 0, syncState: CoffeeSyncState = .dirty) {
        self.id=id; self.kindRaw=kind.rawValue; self.name=name; self.manufacturer=manufacturer; self.model=model; self.parentEquipmentID=parentEquipmentID; self.notes=notes; self.ownerID=ownerID; self.createdAt=createdAt; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.revision=revision; self.syncStateRaw=syncState.rawValue
    }
}

@Model final class EquipmentCalibration: CoffeeSyncedModel {
    @Attribute(.unique) var id: UUID
    var ownerID: String?; var createdAt: Date; var updatedAt: Date; var deletedAt: Date?
    var revision: Int64; var syncStateRaw: String
    var equipmentID: UUID; var coffeeLotID: UUID?; var setting: String; var measuredValue: Double?
    var unit: String?; var notes: String?
    init(id: UUID = UUID(), equipmentID: UUID, coffeeLotID: UUID? = nil, setting: String, measuredValue: Double? = nil, unit: String? = nil, notes: String? = nil, ownerID: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, revision: Int64 = 0, syncState: CoffeeSyncState = .dirty) {
        self.id=id; self.equipmentID=equipmentID; self.coffeeLotID=coffeeLotID; self.setting=setting; self.measuredValue=measuredValue; self.unit=unit; self.notes=notes; self.ownerID=ownerID; self.createdAt=createdAt; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.revision=revision; self.syncStateRaw=syncState.rawValue
    }
}

@Model final class CoffeeRecipe: CoffeeSyncedModel {
    @Attribute(.unique) var id: UUID
    var ownerID: String?; var createdAt: Date; var updatedAt: Date; var deletedAt: Date?
    var revision: Int64; var syncStateRaw: String
    var title: String; var kindRaw: String; var currentVersionID: UUID?
    init(id: UUID = UUID(), title: String, kind: BrewSessionKind = .filter, currentVersionID: UUID? = nil, ownerID: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, revision: Int64 = 0, syncState: CoffeeSyncState = .dirty) {
        self.id=id; self.title=title; self.kindRaw=kind.rawValue; self.currentVersionID=currentVersionID; self.ownerID=ownerID; self.createdAt=createdAt; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.revision=revision; self.syncStateRaw=syncState.rawValue
    }
}

@Model final class RecipeVersion: CoffeeSyncedModel {
    @Attribute(.unique) var id: UUID
    var ownerID: String?; var createdAt: Date; var updatedAt: Date; var deletedAt: Date?
    var revision: Int64; var syncStateRaw: String
    var recipeID: UUID; var versionNumber: Int; var coffeeGrams: Double; var waterGrams: Double?
    var targetYieldGrams: Double?; var temperatureC: Double?; var targetSeconds: Int?
    var grindSetting: String?; var pressureBar: Double?; var stepsJSON: String; var notes: String?
    init(id: UUID = UUID(), recipeID: UUID, versionNumber: Int, coffeeGrams: Double, waterGrams: Double? = nil, targetYieldGrams: Double? = nil, temperatureC: Double? = nil, targetSeconds: Int? = nil, grindSetting: String? = nil, pressureBar: Double? = nil, stepsJSON: String = "[]", notes: String? = nil, ownerID: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, revision: Int64 = 0, syncState: CoffeeSyncState = .dirty) {
        self.id=id; self.recipeID=recipeID; self.versionNumber=versionNumber; self.coffeeGrams=coffeeGrams; self.waterGrams=waterGrams; self.targetYieldGrams=targetYieldGrams; self.temperatureC=temperatureC; self.targetSeconds=targetSeconds; self.grindSetting=grindSetting; self.pressureBar=pressureBar; self.stepsJSON=stepsJSON; self.notes=notes; self.ownerID=ownerID; self.createdAt=createdAt; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.revision=revision; self.syncStateRaw=syncState.rawValue
    }
}

@Model final class CoffeeBrewSession: CoffeeSyncedModel {
    @Attribute(.unique) var id: UUID
    var ownerID: String?; var createdAt: Date; var updatedAt: Date; var deletedAt: Date?
    var revision: Int64; var syncStateRaw: String
    var kindRaw: String; var recipeVersionID: UUID?; var purchasedCoffeeID: UUID?; var grinderID: UUID?
    var brewerID: UUID?; var machineID: UUID?; var basketID: UUID?; var startedAt: Date
    var endedAt: Date?; var doseGrams: Double?; var yieldGrams: Double?; var waterGrams: Double?
    var notes: String?
    init(id: UUID = UUID(), kind: BrewSessionKind, recipeVersionID: UUID? = nil, purchasedCoffeeID: UUID? = nil, grinderID: UUID? = nil, brewerID: UUID? = nil, machineID: UUID? = nil, basketID: UUID? = nil, startedAt: Date = .now, endedAt: Date? = nil, doseGrams: Double? = nil, yieldGrams: Double? = nil, waterGrams: Double? = nil, notes: String? = nil, ownerID: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, revision: Int64 = 0, syncState: CoffeeSyncState = .dirty) {
        self.id=id; self.kindRaw=kind.rawValue; self.recipeVersionID=recipeVersionID; self.purchasedCoffeeID=purchasedCoffeeID; self.grinderID=grinderID; self.brewerID=brewerID; self.machineID=machineID; self.basketID=basketID; self.startedAt=startedAt; self.endedAt=endedAt; self.doseGrams=doseGrams; self.yieldGrams=yieldGrams; self.waterGrams=waterGrams; self.notes=notes; self.ownerID=ownerID; self.createdAt=createdAt; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.revision=revision; self.syncStateRaw=syncState.rawValue
    }
}

@Model final class BrewSample: CoffeeSyncedModel {
    @Attribute(.unique) var id: UUID
    var ownerID: String?; var createdAt: Date; var updatedAt: Date; var deletedAt: Date?
    var revision: Int64; var syncStateRaw: String
    var sessionID: UUID; var kindRaw: String; var elapsedMilliseconds: Int; var value: Double; var unit: String
    init(id: UUID = UUID(), sessionID: UUID, kind: SampleKind, elapsedMilliseconds: Int, value: Double, unit: String, ownerID: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, revision: Int64 = 0, syncState: CoffeeSyncState = .dirty) {
        self.id=id; self.sessionID=sessionID; self.kindRaw=kind.rawValue; self.elapsedMilliseconds=elapsedMilliseconds; self.value=value; self.unit=unit; self.ownerID=ownerID; self.createdAt=createdAt; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.revision=revision; self.syncStateRaw=syncState.rawValue
    }
}

@Model final class CoffeeTasteFeedback: CoffeeSyncedModel {
    @Attribute(.unique) var id: UUID
    var ownerID: String?; var createdAt: Date; var updatedAt: Date; var deletedAt: Date?
    var revision: Int64; var syncStateRaw: String
    var sessionID: UUID?; var purchasedCoffeeID: UUID?; var rating: Int; var tagsJSON: String; var notes: String
    init(id: UUID = UUID(), sessionID: UUID? = nil, purchasedCoffeeID: UUID? = nil, rating: Int, tagsJSON: String = "[]", notes: String = "", ownerID: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, revision: Int64 = 0, syncState: CoffeeSyncState = .dirty) {
        self.id=id; self.sessionID=sessionID; self.purchasedCoffeeID=purchasedCoffeeID; self.rating=min(max(rating, 1), 5); self.tagsJSON=tagsJSON; self.notes=notes; self.ownerID=ownerID; self.createdAt=createdAt; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.revision=revision; self.syncStateRaw=syncState.rawValue
    }
}

@Model final class MaintenanceEvent: CoffeeSyncedModel {
    @Attribute(.unique) var id: UUID
    var ownerID: String?; var createdAt: Date; var updatedAt: Date; var deletedAt: Date?
    var revision: Int64; var syncStateRaw: String
    var equipmentID: UUID; var kind: String; var performedAt: Date; var usageCount: Int?; var notes: String?
    init(id: UUID = UUID(), equipmentID: UUID, kind: String, performedAt: Date = .now, usageCount: Int? = nil, notes: String? = nil, ownerID: String? = nil, createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil, revision: Int64 = 0, syncState: CoffeeSyncState = .dirty) {
        self.id=id; self.equipmentID=equipmentID; self.kind=kind; self.performedAt=performedAt; self.usageCount=usageCount; self.notes=notes; self.ownerID=ownerID; self.createdAt=createdAt; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.revision=revision; self.syncStateRaw=syncState.rawValue
    }
}

@Model final class CoffeeSyncEnvelope {
    @Attribute(.unique) var compoundID: String
    var entityType: String; var recordID: UUID; var payload: Data; var updatedAt: Date
    var deletedAt: Date?; var baseRevision: Int64; var dirty: Bool; var conflictedPayload: Data?
    init(entityType: String, recordID: UUID, payload: Data, updatedAt: Date = .now, deletedAt: Date? = nil, baseRevision: Int64 = 0, dirty: Bool = true) {
        self.compoundID="\(entityType):\(recordID.uuidString.lowercased())"; self.entityType=entityType; self.recordID=recordID; self.payload=payload; self.updatedAt=updatedAt; self.deletedAt=deletedAt; self.baseRevision=baseRevision; self.dirty=dirty
    }
}

@Model final class CoffeeSyncCursor {
    @Attribute(.unique) var ownerID: String
    var cursor: String; var deviceID: String; var lastSyncedAt: Date?
    init(ownerID: String, cursor: String = "1970-01-01T00:00:00.000Z", deviceID: String = UUID().uuidString) { self.ownerID=ownerID; self.cursor=cursor; self.deviceID=deviceID }
}

enum CoffeeSchema {
    static let models: [any PersistentModel.Type] = [CoffeeLot.self, PurchasedCoffee.self, CoffeeEquipment.self, EquipmentCalibration.self, CoffeeRecipe.self, RecipeVersion.self, CoffeeBrewSession.self, BrewSample.self, CoffeeTasteFeedback.self, MaintenanceEvent.self, CoffeeSyncEnvelope.self, CoffeeSyncCursor.self]
}
