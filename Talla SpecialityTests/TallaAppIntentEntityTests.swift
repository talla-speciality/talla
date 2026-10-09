import Foundation
import Testing
@testable import Talla_Speciality

struct TallaAppIntentEntityTests {
    @Test func orderEntityKeepsStableIdentifierAndConversationFields() {
        let entity = TallaOrderEntity(id: "order-123", title: "Pickup order", status: "Ready", total: "4.500 BHD", createdAt: "2026-10-09T10:00:00Z")
        #expect(entity.id == "order-123")
        #expect(entity.title == "Pickup order")
        #expect(entity.status == "Ready")
        #expect(entity.total == "4.500 BHD")
    }

    @Test func giftEntityCarriesReferenceWithoutMakingTokenAProperty() {
        let gift = TallaGiftEntity(id: "gift-123", drinkName: "Iced latte", status: "saved", expiresAt: nil, token: String(repeating: "a", count: 64))
        #expect(gift.id == "gift-123")
        #expect(gift.drinkName == "Iced latte")
        #expect(gift.status == "saved")
    }

    @Test func rewardEntityExposesSearchableCatalogFields() {
        let reward = TallaRewardEntity(id: "voucher-123", name: "Free cappuccino", detail: "One regular cappuccino", points: 50, status: "active", expiresAt: "2026-12-31T23:59:59Z")
        #expect(reward.id == "voucher-123")
        #expect(reward.name == "Free cappuccino")
        #expect(reward.points == 50)
        #expect(reward.status == "active")
    }

    @Test func productEntityKeepsStableCatalogAndVariantReferences() {
        let product = TallaProductEntity(id: "variant-123", name: "Ethiopian beans", variant: "250 g", productID: "product-123", variantID: "variant-123")
        #expect(product.id == "variant-123")
        #expect(product.productID == "product-123")
        #expect(product.variantID == "variant-123")
    }

    @Test func activeOrderFilterExcludesTerminalStates() throws {
        let data = Data(#"[{"id":"active","title":"Order","total":"1","status":"Ready","createdAt":"2026-10-09T10:00:00Z"},{"id":"done","title":"Order","total":"1","status":"Completed","createdAt":"2026-10-08T10:00:00Z"}]"#.utf8)
        let orders = try JSONDecoder().decode([ContentView.AccountOrder].self, from: data)
        #expect(TallaIntentSupport.activeOrders(from: orders).map(\.id) == ["active"])
    }

    @Test func iso8601DateAcceptsFractionalAndWholeSecondValues() {
        #expect(TallaIntentSupport.iso8601Date("2026-10-09T10:00:00Z") != nil)
        #expect(TallaIntentSupport.iso8601Date("2026-10-09T10:00:00.123Z") != nil)
    }
}
