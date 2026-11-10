import Foundation
#if canImport(AppIntents)
import AppIntents
#endif
#if canImport(CoreSpotlight)
import CoreSpotlight
import UniformTypeIdentifiers
#endif

enum TallaSpotlightIndexer {
    static let domain = "com.talla.speciality.private"

    static func reindex(orders: [ContentView.AccountOrder], groups: [SocialCoffeeGroup] = []) {
        #if canImport(CoreSpotlight)
        guard !orders.isEmpty || !groups.isEmpty else { return }
        var items: [CSSearchableItem] = []

        for order in orders {
            let attributes = CSSearchableItemAttributeSet(itemContentType: UTType.item.identifier)
            attributes.title = order.title.isEmpty ? "Talla order" : order.title
            attributes.contentDescription = "\(order.status) · \(order.total)"
            attributes.keywords = ["Talla", "coffee", "order", order.status]
            items.append(CSSearchableItem(uniqueIdentifier: "order:\(order.id)", domainIdentifier: domain, attributeSet: attributes))

            if let pass = order.details?.cafePass, pass.giftedCoffee == true {
                let giftAttributes = CSSearchableItemAttributeSet(itemContentType: UTType.item.identifier)
                giftAttributes.title = pass.drinkName
                giftAttributes.contentDescription = "Coffee gift · \(pass.status)"
                giftAttributes.keywords = ["Talla", "coffee", "gift", "redeem", pass.status]
                // Never include the redemption token in the index.
                items.append(CSSearchableItem(uniqueIdentifier: "gift:\(order.id)", domainIdentifier: domain, attributeSet: giftAttributes))
            }
        }

        for group in groups {
            let attributes = CSSearchableItemAttributeSet(itemContentType: UTType.item.identifier)
            attributes.title = group.name
            attributes.contentDescription = "Group coffee order · \(group.status) · \(group.participants.count) people"
            attributes.keywords = ["Talla", "coffee", "group", "order", group.status]
            items.append(CSSearchableItem(uniqueIdentifier: "group:\(group.id)", domainIdentifier: domain, attributeSet: attributes))
        }

        CSSearchableIndex.default().indexSearchableItems(items)
        if #available(iOS 27.0, *) {
            Task {
                try? await reindexNativeEntities(orderIDs: orders.map(\.id), groupIDs: groups.map(\.id))
            }
        }
        #endif
    }

    @available(iOS 27.0, *)
    private static func reindexNativeEntities(orderIDs: [String], groupIDs: [String]) async throws {
        #if canImport(AppIntents)
        if !orderIDs.isEmpty {
            try await CSSearchableIndex.default().indexAppEntities(try await TallaOrderQuery().entities(for: orderIDs), priority: 10)
            try await CSSearchableIndex.default().indexAppEntities(try await TallaGiftQuery().entities(for: orderIDs), priority: 10)
        }
        if !groupIDs.isEmpty {
            try await CSSearchableIndex.default().indexAppEntities(try await TallaGroupOrderQuery().entities(for: groupIDs), priority: 10)
        }
        #endif
    }

    static func removeAll() {
        #if canImport(CoreSpotlight)
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [domain])
        #endif
    }

    static func reindexStoredGifts() {
        #if canImport(CoreSpotlight)
        let items = TallaGiftVault.all().map { gift -> CSSearchableItem in
            let attributes = CSSearchableItemAttributeSet(itemContentType: "com.apple.corespotlight searchable-item")
            attributes.title = gift.drinkName
            attributes.contentDescription = "Coffee gift · saved"
            attributes.keywords = ["Talla", "coffee", "gift", "redeem"]
            return CSSearchableItem(uniqueIdentifier: "gift:\(gift.orderID)", domainIdentifier: domain, attributeSet: attributes)
        }
        CSSearchableIndex.default().indexSearchableItems(items)
        if #available(iOS 27.0, *) {
            Task { try? await CSSearchableIndex.default().indexAppEntities(try await TallaGiftQuery().suggestedEntities(), priority: 10) }
        }
        #endif
    }

    static func reindexRewards(_ rewards: [ContentView.VoucherRecord]) {
        #if canImport(CoreSpotlight)
        let items = rewards.map { reward -> CSSearchableItem in
            let attributes = CSSearchableItemAttributeSet(itemContentType: "com.apple.corespotlight searchable-item")
            attributes.title = reward.reward
            attributes.contentDescription = "Talla reward · \(reward.points) Beans · \(reward.status)"
            attributes.keywords = ["Talla", "coffee", "reward", "Beans", reward.reward, reward.detail, reward.status].filter { !$0.isEmpty }
            return CSSearchableItem(uniqueIdentifier: "reward:\(reward.id)", domainIdentifier: domain, attributeSet: attributes)
        }
        CSSearchableIndex.default().indexSearchableItems(items)
        if #available(iOS 27.0, *) {
            Task { try? await CSSearchableIndex.default().indexAppEntities(try await TallaRewardQuery().suggestedEntities(), priority: 10) }
        }
        #endif
    }
}
