#if canImport(AppIntents)
import AppIntents
import Foundation
import CoreSpotlight

enum TallaShortcutDestination {
    nonisolated static let destinationKey = "shortcut.destination"
    nonisolated static let searchQueryKey = "shortcut.searchQuery"
    nonisolated static let pendingReorderKey = "shortcut.pendingReorder"

    static func open(_ destination: String, searchQuery: String = "") {
        let defaults = UserDefaults.standard
        defaults.set(searchQuery, forKey: searchQueryKey)
        defaults.set(destination, forKey: destinationKey)
    }
}

enum TallaIntentError: LocalizedError {
    case signIn
    case unavailable(String)
    case notFound(String)

    var errorDescription: String? {
        switch self {
        case .signIn: return "Sign in to Talla before using this action."
        case let .unavailable(message), let .notFound(message): return message
        }
    }
}

private func tallaIntentText(_ value: String) -> LocalizedStringResource {
    LocalizedStringResource(stringLiteral: value)
}

enum TallaIntentSupport {
    static var isSignedIn: Bool { !AccountService.accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    static var customerEmail: String { UserDefaults.standard.string(forKey: "local.customerEmail")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }

    nonisolated static func iso8601Date(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }

    static func requireSignedIn() throws {
        guard isSignedIn, !customerEmail.isEmpty else { throw TallaIntentError.signIn }
    }

    static func orders() async throws -> [ContentView.AccountOrder] {
        try requireSignedIn()
        return try await AccountService.fetchOrders(email: customerEmail)
    }

    static func activeOrders(from orders: [ContentView.AccountOrder]) -> [ContentView.AccountOrder] {
        let inactive = Set(["cancelled", "canceled", "refunded", "fulfilled", "completed", "delivered", "closed"])
        return orders.filter { !inactive.contains($0.status.lowercased()) && !$0.isRefunded }
    }

    static func product(for item: ContentView.AccountOrder.Item) async throws -> (ContentView.Product, ContentView.Product.Variant)? {
        let products = try await ShopifyStorefrontClient.fetchAllProducts(languageCode: AppLocalization.currentLanguage.effectiveLanguageCode)
        let product = products.first(where: { $0.id == item.productTitle })
            ?? products.first(where: { $0.name.caseInsensitiveCompare(item.productTitle ?? "") == .orderedSame })
            ?? products.first(where: { $0.name.caseInsensitiveCompare(item.name) == .orderedSame })
        guard let product else { return nil }
        let variant = product.variants.first(where: { $0.id == item.variantId })
            ?? product.variants.first(where: { $0.title.caseInsensitiveCompare(item.variantTitle ?? "") == .orderedSame })
            ?? product.defaultVariant
        guard let variant else { return nil }
        return (product, variant)
    }
}

struct TallaStoredGift: Codable, Hashable, Sendable, Identifiable {
    let orderID: String
    let drinkName: String
    let token: String
    let savedAt: Date
    var id: String { orderID }
}

enum TallaGiftVault {
    private static let keychainAccount = "coffee-gifts"

    static func all() -> [TallaStoredGift] {
        guard let raw = TallaAccountCredentialStore.readFromKeychain(account: keychainAccount),
              let data = raw.data(using: .utf8),
              let gifts = try? JSONDecoder().decode([TallaStoredGift].self, from: data) else { return [] }
        return gifts
    }

    static func save(orderID: String, drinkName: String = "Coffee gift", token: String) {
        guard !orderID.isEmpty, !token.isEmpty else { return }
        var gifts = all().filter { $0.orderID != orderID }
        gifts.insert(TallaStoredGift(orderID: orderID, drinkName: drinkName, token: token, savedAt: .now), at: 0)
        if let data = try? JSONEncoder().encode(Array(gifts.prefix(20))), let value = String(data: data, encoding: .utf8) {
            TallaAccountCredentialStore.saveToKeychain(value, account: keychainAccount)
        }
    }

    static func clear() {
        TallaAccountCredentialStore.deleteFromKeychain(account: keychainAccount)
    }
}

struct TallaProductEntity: AppEntity, Identifiable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Product")
    static var defaultQuery = TallaProductQuery()
    let id: String
    let productID: String
    let variantID: String
    @Property(title: "Name") var name: String
    @Property(title: "Variant") var variant: String
    init(id: String, name: String, variant: String, productID: String? = nil, variantID: String? = nil) {
        self.id = id
        self.productID = productID ?? id
        self.variantID = variantID ?? id
        self.name = name
        self.variant = variant
    }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: tallaIntentText(name), subtitle: variant.isEmpty ? nil : tallaIntentText(variant), image: .init(systemName: "cup.and.saucer.fill")) }
}

@available(iOS 18.0, *)
extension TallaProductEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(itemContentType: "com.apple.corespotlight searchable-item")
        attributes.title = name
        attributes.contentDescription = variant.isEmpty ? "Talla coffee product" : "Talla coffee product · \(variant)"
        attributes.keywords = ["Talla", "coffee", name, variant].filter { !$0.isEmpty }
        return attributes
    }
}

struct TallaOrderEntity: AppEntity, Identifiable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Order")
    static var defaultQuery = TallaOrderQuery()
    let id: String
    @Property(title: "Title") var title: String
    @Property(title: "Status") var status: String
    @Property(title: "Total") var total: String
    @Property(title: "Created") var createdAt: String
    init(id: String, title: String, status: String, total: String, createdAt: String) { self.id = id; self.title = title; self.status = status; self.total = total; self.createdAt = createdAt }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: tallaIntentText(title.isEmpty ? "Talla order" : title), subtitle: tallaIntentText("\(status) · \(total)"), image: .init(systemName: "bag.fill")) }
}

@available(iOS 18.0, *)
extension TallaOrderEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(itemContentType: "com.apple.corespotlight searchable-item")
        attributes.title = title.isEmpty ? "Talla order" : title
        attributes.contentDescription = "\(status) · \(total)"
        attributes.keywords = ["Talla", "coffee", "order", status]
        return attributes
    }
}

struct TallaGroupOrderEntity: AppEntity, Identifiable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Group coffee order")
    static var defaultQuery = TallaGroupOrderQuery()
    let id: String
    @Property(title: "Name") var name: String
    @Property(title: "Status") var status: String
    @Property(title: "Participants") var participantCount: Int
    init(id: String, name: String, status: String, participantCount: Int) { self.id = id; self.name = name; self.status = status; self.participantCount = participantCount }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: tallaIntentText(name), subtitle: tallaIntentText("\(participantCount) people · \(status)"), image: .init(systemName: "person.3.fill")) }
}

@available(iOS 18.0, *)
extension TallaGroupOrderEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(itemContentType: "com.apple.corespotlight searchable-item")
        attributes.title = name
        attributes.contentDescription = "Group coffee order · \(status) · \(participantCount) people"
        attributes.keywords = ["Talla", "coffee", "group", "order", status]
        return attributes
    }
}

struct TallaGiftEntity: AppEntity, Identifiable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Coffee gift")
    static var defaultQuery = TallaGiftQuery()
    let id: String
    @Property(title: "Drink") var drinkName: String
    @Property(title: "Status") var status: String
    @Property(title: "Expiration") var expiresAt: String?
    // Redemption tokens remain private and are never indexed or exposed as entity properties.
    var token: String? = nil
    init(id: String, drinkName: String, status: String, expiresAt: String?, token: String?) {
        self.id = id
        self.drinkName = drinkName
        self.status = status
        self.expiresAt = expiresAt
        self.token = token
    }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: tallaIntentText(drinkName), subtitle: tallaIntentText(status), image: .init(systemName: "gift.fill")) }
}

struct TallaRewardEntity: AppEntity, Identifiable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Reward")
    static var defaultQuery = TallaRewardQuery()
    let id: String
    @Property(title: "Reward") var name: String
    @Property(title: "Details") var detail: String
    @Property(title: "Points") var points: Int
    @Property(title: "Status") var status: String
    @Property(title: "Expiration") var expiresAt: String

    init(id: String, name: String, detail: String, points: Int, status: String, expiresAt: String) {
        self.id = id
        self.name = name
        self.detail = detail
        self.points = points
        self.status = status
        self.expiresAt = expiresAt
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: tallaIntentText(name), subtitle: tallaIntentText("\(points) Beans · \(status)"), image: .init(systemName: "star.circle.fill"))
    }
}

@available(iOS 18.0, *)
extension TallaRewardEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(itemContentType: "com.apple.corespotlight searchable-item")
        attributes.title = name
        attributes.contentDescription = "Talla reward · \(points) Beans · \(status)"
        attributes.keywords = ["Talla", "coffee", "reward", "Beans", name, detail, status].filter { !$0.isEmpty }
        return attributes
    }
}

@available(iOS 18.0, *)
extension TallaGiftEntity: IndexedEntity {
    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = CSSearchableItemAttributeSet(itemContentType: "com.apple.corespotlight searchable-item")
        attributes.title = drinkName
        attributes.contentDescription = "Coffee gift · \(status)"
        attributes.keywords = ["Talla", "coffee", "gift", "redeem", status]
        return attributes
    }
}

private extension TallaOrderEntity { init(_ order: ContentView.AccountOrder) { self.init(id: order.id, title: order.title, status: order.status, total: order.total, createdAt: order.createdAt) } }
private extension TallaGroupOrderEntity { init(_ group: SocialCoffeeGroup) { self.init(id: group.id, name: group.name, status: group.status, participantCount: group.participants.count) } }
private extension TallaRewardEntity { init(_ voucher: ContentView.VoucherRecord) { self.init(id: voucher.id, name: voucher.reward, detail: voucher.detail, points: voucher.points, status: voucher.status, expiresAt: voucher.expiresAt) } }

struct TallaOrderQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TallaOrderEntity] { try await TallaIntentSupport.orders().filter { identifiers.contains($0.id) }.map(TallaOrderEntity.init) }
    func suggestedEntities() async throws -> [TallaOrderEntity] { try await TallaIntentSupport.activeOrders(from: TallaIntentSupport.orders()).prefix(10).map(TallaOrderEntity.init) }
}

struct TallaGroupOrderQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [TallaGroupOrderEntity] { try await AccountService.fetchSocialCoffeeGroups().filter { identifiers.contains($0.id) }.map(TallaGroupOrderEntity.init) }
    func suggestedEntities() async throws -> [TallaGroupOrderEntity] { try await AccountService.fetchSocialCoffeeGroups().filter { $0.status == "open" }.map(TallaGroupOrderEntity.init) }
}

struct TallaGiftQuery: EntityQuery {
    private func allGifts() async throws -> [TallaGiftEntity] {
        let orderGifts = (try? await TallaIntentSupport.orders())?.compactMap { order -> TallaGiftEntity? in
            guard let pass = order.details?.cafePass, pass.giftedCoffee == true else { return nil }
            return TallaGiftEntity(id: order.id, drinkName: pass.drinkName, status: pass.status, expiresAt: pass.expiresAt, token: pass.giftToken)
        } ?? []
        let storedGifts = await TallaGiftVault.all().map { gift in
            TallaGiftEntity(id: gift.orderID, drinkName: gift.drinkName, status: "saved", expiresAt: nil, token: gift.token)
        }
        return Array(Dictionary((orderGifts + storedGifts).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first }).values)
    }

    func entities(for identifiers: [String]) async throws -> [TallaGiftEntity] {
        return try await allGifts().filter { identifiers.contains($0.id) }
    }
    func suggestedEntities() async throws -> [TallaGiftEntity] { try await allGifts() }
}

struct TallaProductQuery: EntityQuery {
    private func allProducts() async throws -> [TallaProductEntity] {
        try await ShopifyStorefrontClient.fetchAllProducts(languageCode: AppLocalization.currentLanguage.effectiveLanguageCode).flatMap { product -> [TallaProductEntity] in
            guard product.isAvailableForSale else { return [] }
            return product.variants.filter(\.isAvailableForSale).map { variant in
                TallaProductEntity(id: variant.id, name: product.name, variant: variant.title, productID: product.id, variantID: variant.id)
            }
        }
    }
    func entities(for identifiers: [String]) async throws -> [TallaProductEntity] { try await allProducts().filter { identifiers.contains($0.id) } }
    func suggestedEntities() async throws -> [TallaProductEntity] { Array(try await allProducts().prefix(20)) }
}

struct TallaRewardQuery: EntityQuery {
    private func allRewards() async throws -> [TallaRewardEntity] {
        try await TallaIntentSupport.requireSignedIn()
        return try await AccountService.fetchVouchers(email: TallaIntentSupport.customerEmail).map(TallaRewardEntity.init)
    }

    func entities(for identifiers: [String]) async throws -> [TallaRewardEntity] {
        try await allRewards().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [TallaRewardEntity] { try await allRewards() }
}

@available(iOS 27.0, *)
extension TallaProductQuery: IndexedEntityQuery {
    func reindexEntities(for identifiers: [TallaProductEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(try await entities(for: identifiers), priority: 10)
    }
    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(try await suggestedEntities(), priority: 5)
    }
}

@available(iOS 27.0, *)
extension TallaOrderQuery: IndexedEntityQuery {
    func reindexEntities(for identifiers: [TallaOrderEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(try await entities(for: identifiers), priority: 10)
    }
    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(try await suggestedEntities(), priority: 10)
    }
}

@available(iOS 27.0, *)
extension TallaGroupOrderQuery: IndexedEntityQuery {
    func reindexEntities(for identifiers: [TallaGroupOrderEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(try await entities(for: identifiers), priority: 10)
    }
    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(try await suggestedEntities(), priority: 10)
    }
}

@available(iOS 27.0, *)
extension TallaGiftQuery: IndexedEntityQuery {
    func reindexEntities(for identifiers: [TallaGiftEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(try await entities(for: identifiers), priority: 10)
    }
    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(try await suggestedEntities(), priority: 10)
    }
}

@available(iOS 27.0, *)
extension TallaRewardQuery: IndexedEntityQuery {
    func reindexEntities(for identifiers: [TallaRewardEntity.ID], indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(try await entities(for: identifiers), priority: 10)
    }

    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        try await CSSearchableIndex.default().indexAppEntities(try await suggestedEntities(), priority: 10)
    }
}

struct OpenTallaOrderIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Talla Order"
    @Parameter(title: "Order") var target: TallaOrderEntity
    func perform() async throws -> some IntentResult { UserDefaults.standard.set(target.id, forKey: "shortcut.orderID"); await TallaShortcutDestination.open("orders"); return .result() }
}

struct OpenTallaProductIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Talla Product"
    @Parameter(title: "Product") var target: TallaProductEntity
    func perform() async throws -> some IntentResult { await TallaShortcutDestination.open("shop", searchQuery: target.name); return .result() }
}

struct AddTallaProductToBagIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Talla Product to Bag"
    static let description = IntentDescription("Adds a specific Talla product and variant to your bag for review.")
    static let openAppWhenRun = true
    @Parameter(title: "Product") var product: TallaProductEntity
    @Parameter(title: "Quantity", default: 1) var quantity: Int

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let safeQuantity = max(1, min(quantity, 20))
        let payload: [String: Any] = ["name": product.name, "productTitle": product.productID, "variantID": product.variantID, "quantity": safeQuantity]
        UserDefaults.standard.set(payload, forKey: TallaShortcutDestination.pendingReorderKey)
        await TallaShortcutDestination.open("reorder")
        return .result(dialog: "I’ll add \(product.name) to your bag for review.")
    }
}

struct OpenTallaGroupOrderIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Group Coffee Order"
    @Parameter(title: "Group order") var target: TallaGroupOrderEntity
    func perform() async throws -> some IntentResult { await TallaShortcutDestination.open("group-order", searchQuery: target.id); return .result() }
}

struct OpenTallaGiftIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Coffee Gift"
    @Parameter(title: "Gift") var target: TallaGiftEntity
    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(target.id, forKey: "shortcut.giftID")
        await TallaShortcutDestination.open("gifts")
        return .result()
    }
}

struct OpenTallaRewardIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Talla Reward"
    @Parameter(title: "Reward") var target: TallaRewardEntity

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(target.id, forKey: "shortcut.rewardID")
        await TallaShortcutDestination.open("rewards")
        return .result()
    }
}

struct ApplyTallaRewardIntent: AppIntent {
    static let title: LocalizedStringResource = "Apply Talla Reward"
    static let description = IntentDescription("Applies a selected Talla reward voucher to the current bag when eligible.")
    static let openAppWhenRun = true
    @Parameter(title: "Reward") var reward: TallaRewardEntity

    func perform() async throws -> some IntentResult & ProvidesDialog {
        UserDefaults.standard.set(reward.id, forKey: "shortcut.rewardID")
        await TallaShortcutDestination.open("apply-reward")
        return .result(dialog: "I’ll apply (reward.name) to your bag for review.")
    }
}

struct ShowCoffeeGiftsIntent: AppIntent {
    static let title: LocalizedStringResource = "Show My Coffee Gifts"
    static let description = IntentDescription("Shows coffee gifts associated with your Talla account.")
    static let openAppWhenRun = true
    func perform() async throws -> some IntentResult { _ = try await TallaGiftQuery().suggestedEntities(); await TallaShortcutDestination.open("gifts"); return .result(dialog: "Opening your coffee gifts.") }
}

struct ShowExpiringCoffeeGiftsIntent: AppIntent {
    static let title: LocalizedStringResource = "Show Gifts Expiring This Month"
    static let description = IntentDescription("Shows Talla coffee gifts that expire before the end of the current month.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let gifts = try await TallaGiftQuery().suggestedEntities()
        let calendar = Calendar.current
        let now = Date()
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            await TallaShortcutDestination.open("gifts")
            return .result(dialog: "Opening your coffee gifts.")
        }

        let expiring = gifts.filter { gift in
            guard let value = gift.expiresAt, let date = TallaIntentSupport.iso8601Date(value) else { return false }
            return date >= now && date < monthInterval.end
        }
        await TallaShortcutDestination.open("gifts")
        if expiring.isEmpty {
            return .result(dialog: "You have no coffee gifts expiring this month.")
        }
        return .result(dialog: "You have \(expiring.count) coffee gift\(expiring.count == 1 ? "" : "s") expiring this month.")
    }
}

struct CheckCoffeeGiftRedeemabilityIntent: AppIntent {
    static let title: LocalizedStringResource = "Check Whether My Gift Is Redeemable"
    static let description = IntentDescription("Checks the current redemption status of a Talla coffee gift.")
    @Parameter(title: "Gift") var gift: TallaGiftEntity
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let token = gift.token, !token.isEmpty else { throw TallaIntentError.unavailable("This gift does not contain a verifiable redemption token.") }
        let status = try await AccountService.fetchSocialCoffeeGiftStatus(orderID: gift.id, token: token)
        switch status.status {
        case "ready": return .result(dialog: "Yes. \(status.drinkName) is ready to redeem.")
        case "redeemed": return .result(dialog: "No. This coffee gift has already been redeemed.")
        case "expired": return .result(dialog: "No. This coffee gift has expired.")
        default: return .result(dialog: "This coffee gift is not currently redeemable.")
        }
    }
}

struct JoinGroupCoffeeOrderIntent: AppIntent {
    static let title: LocalizedStringResource = "Join This Group Coffee Order"
    static let description = IntentDescription("Joins an open Talla group coffee order.")
    @Parameter(title: "Group order") var group: TallaGroupOrderEntity
    @Parameter(title: "Your name") var name: String
    @Parameter(title: "Invite code", requestValueDialog: "What is the group invite code?") var inviteCode: String
    func perform() async throws -> some IntentResult & ProvidesDialog {
        try await TallaIntentSupport.requireSignedIn()
        let current = try await AccountService.fetchSocialCoffeeGroup(id: group.id)
        guard current.status == "open" else { throw TallaIntentError.unavailable("This group coffee order is no longer open.") }
        guard !inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw TallaIntentError.unavailable("I need the invite code for this private group order.") }
        _ = try await AccountService.joinSocialCoffeeGroup(id: group.id, inviteCode: inviteCode.trimmingCharacters(in: .whitespacesAndNewlines), name: name.trimmingCharacters(in: .whitespacesAndNewlines))
        return .result(dialog: "You joined \(group.name).")
    }
}

struct AddUsualCoffeeToGroupOrderIntent: AppIntent {
    static let title: LocalizedStringResource = "Add My Usual Coffee to the Group Order"
    static let description = IntentDescription("Adds the coffee from your most recent Talla order to an open group order.")
    @Parameter(title: "Group order") var group: TallaGroupOrderEntity
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let orders = try await TallaIntentSupport.orders()
        guard let last = orders.sorted(by: { $0.createdAt > $1.createdAt }).first, let item = last.items?.first else { throw TallaIntentError.notFound("I couldn’t find a previous coffee to add.") }
        guard let (product, variant) = try await TallaIntentSupport.product(for: item), product.isAvailableForSale, variant.isAvailableForSale else { throw TallaIntentError.unavailable("Your usual coffee is no longer available in the catalog.") }
        _ = try await AccountService.addSocialCoffeeGroupItem(id: group.id, productID: product.id, variantID: variant.id, quantity: max(1, min(item.quantity, 20)))
        return .result(dialog: "Added your usual \(product.name) to \(group.name).")
    }
}

struct ShowActiveOrdersIntent: AppIntent {
    static let title: LocalizedStringResource = "Show My Active Orders"
    static let description = IntentDescription("Shows your current Talla orders that are not completed or cancelled.")
    static let openAppWhenRun = true
    func perform() async throws -> some IntentResult & ProvidesDialog { let active = await TallaIntentSupport.activeOrders(from: try await TallaIntentSupport.orders()); await TallaShortcutDestination.open("orders"); return .result(dialog: active.isEmpty ? "You have no active Talla orders." : "You have \(active.count) active Talla order\(active.count == 1 ? "" : "s").") }
}

struct ReorderLastCoffeeIntent: AppIntent {
    static let title: LocalizedStringResource = "Reorder My Last Coffee"
    static let description = IntentDescription("Adds the coffee from your most recent Talla order to your bag for review.")
    static let openAppWhenRun = true
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let orders = try await TallaIntentSupport.orders()
        guard let order = orders.sorted(by: { $0.createdAt > $1.createdAt }).first, let item = order.items?.first else { throw TallaIntentError.notFound("I couldn’t find a coffee in your recent orders.") }
        let payload: [String: Any] = ["orderID": order.id, "name": item.name, "productTitle": item.productTitle ?? "", "variantID": item.variantId ?? "", "quantity": item.quantity]
        UserDefaults.standard.set(payload, forKey: TallaShortcutDestination.pendingReorderKey)
        await TallaShortcutDestination.open("reorder")
        return .result(dialog: "I found your last coffee. Opening Talla to review it before adding it to your bag.")
    }
}

struct OpenTallaShopIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Talla Shop"
    static let description = IntentDescription("Opens Talla Speciality to the shop.")
    static let openAppWhenRun = true
    func perform() async throws -> some IntentResult { await TallaShortcutDestination.open("shop"); return .result() }
}
struct SearchTallaProductsIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Talla Products"
    static let description = IntentDescription("Opens Talla Speciality and searches the product catalog.")
    static let openAppWhenRun = true
    @Parameter(title: "Search") var searchQuery: String
    func perform() async throws -> some IntentResult { await TallaShortcutDestination.open("shop", searchQuery: searchQuery); return .result() }
}
struct OpenTallaConciergeIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Coffee Concierge"
    static let description = IntentDescription("Opens the Coffee Concierge in Talla Speciality.")
    static let openAppWhenRun = true
    func perform() async throws -> some IntentResult { await TallaShortcutDestination.open("concierge"); return .result() }
}
struct OpenTallaBrewingIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Brewing Guide"
    static let description = IntentDescription("Opens Talla Speciality to brewing guides and recipes.")
    static let openAppWhenRun = true
    func perform() async throws -> some IntentResult { await TallaShortcutDestination.open("brewing"); return .result() }
}
struct OpenTallaRewardsIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Talla Rewards"
    static let description = IntentDescription("Opens Talla Speciality to account rewards.")
    static let openAppWhenRun = true
    func perform() async throws -> some IntentResult { await TallaShortcutDestination.open("rewards"); return .result() }
}

struct TallaAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ShowCoffeeGiftsIntent(), phrases: ["Show my coffee gifts in \(.applicationName)"], shortTitle: "Coffee Gifts", systemImageName: "gift.fill")
        AppShortcut(intent: ShowExpiringCoffeeGiftsIntent(), phrases: ["Show my gifts expiring this month in \(.applicationName)"], shortTitle: "Expiring Gifts", systemImageName: "calendar.badge.exclamationmark")
        AppShortcut(intent: JoinGroupCoffeeOrderIntent(), phrases: ["Join this group coffee order in \(.applicationName)"], shortTitle: "Join Group Order", systemImageName: "person.3.fill")
        AppShortcut(intent: AddUsualCoffeeToGroupOrderIntent(), phrases: ["Add my usual coffee to the group order in \(.applicationName)"], shortTitle: "Add Usual Coffee", systemImageName: "cup.and.saucer.fill")
        AppShortcut(intent: ShowActiveOrdersIntent(), phrases: ["Show my active orders in \(.applicationName)"], shortTitle: "Active Orders", systemImageName: "bag.fill")
        AppShortcut(intent: ReorderLastCoffeeIntent(), phrases: ["Reorder my last coffee in \(.applicationName)", "Add the coffee I bought last time in \(.applicationName)"], shortTitle: "Reorder Coffee", systemImageName: "arrow.clockwise")
        AppShortcut(intent: AddTallaProductToBagIntent(), phrases: ["Add this product to my bag in \(.applicationName)"], shortTitle: "Add Product", systemImageName: "cart.badge.plus")
        AppShortcut(intent: ApplyTallaRewardIntent(), phrases: ["Apply this reward in \(.applicationName)"], shortTitle: "Apply Reward", systemImageName: "checkmark.seal.fill")
        AppShortcut(intent: OpenTallaConciergeIntent(), phrases: ["Ask Coffee Concierge in \(.applicationName)"], shortTitle: "Coffee Concierge", systemImageName: "sparkles")
        AppShortcut(intent: OpenTallaRewardsIntent(), phrases: ["Show my Talla rewards in \(.applicationName)"], shortTitle: "Rewards", systemImageName: "star.circle.fill")
    }
}
#endif
