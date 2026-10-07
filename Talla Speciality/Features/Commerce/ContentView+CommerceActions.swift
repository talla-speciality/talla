import Foundation
import SwiftUI
import StoreKit
#if canImport(Security)
import Security
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif
#if canImport(WidgetKit)
import WidgetKit
#endif
#if canImport(PassKit)
import PassKit
#endif
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(SafariServices) && canImport(UIKit)
import SafariServices
import UIKit
#endif

extension ContentView {
    func bagSupportsSubscription(_ planType: String) -> Bool {
        guard !cartItems.isEmpty else { return true }
        let currentPlan = cartSubscriptionPlanType.isEmpty ? coffeeClubPlanType : cartSubscriptionPlanType
        return isCoffeeClubPrepaid
            && !isCafePassPrepaid
            && !isGiftOrder
            && currentPlan == planType
            && cartItems.allSatisfy { item in
                ProductCatalogRules.subscriptionPlanType(
                    detectedPlan: defaultPrepaidPlanType(for: item.product),
                    requestedPlan: planType
                ) == planType
            }
    }

    func offerToReplaceBag(for flowName: String, then action: @escaping () -> Void) {
        pendingCartReplacementFlowName = flowName
        pendingCartReplacementAction = action
        isConfirmingCartReplacement = true
    }

    func clearBagForNewFlow() {
        cartItems.removeAll()
        cartSubscriptionPlanType = ""
        isCoffeeClubPrepaid = false
        coffeeClubTermsAccepted = false
        isCafePassPrepaid = false
        suspendedCoffeePass = false
        isGiftOrder = false
        giftRecipientName = ""
        giftRecipientEmail = ""
        giftRecipientPhone = ""
        giftMessage = ""
        appliedVoucher = nil
        voucherCodeInput = ""
        voucherError = nil
        checkoutError = nil
        cartOpen = false
    }

    func addToCart(product: Product) {
        guard let variant = selectedVariant(for: product), variant.isAvailableForSale else {
            showToast(message: String(format: AppLocalization.text("product_unavailable_toast", fallback: "%@ is unavailable"), product.name))
            return
        }

        let chosenPlanType = requestedSubscriptionPlanType
        let productPlanType = prepaidPlanType(for: product)
        if !chosenPlanType.isEmpty, productPlanType != chosenPlanType {
            showToast(message: "This product is not available for the selected prepaid plan.")
            return
        }
        if !cartItems.isEmpty {
            let hasExclusiveItem = isCafePassPrepaid || isCoffeeClubPrepaid
                || product.isGiftCardProduct
                || cartItems.contains(where: { $0.product.isGiftCardProduct })
                || (isGiftOrder && cartItems.contains(where: { $0.variant.requiresShipping != variant.requiresShipping }))
            let incompatibleSubscription = !chosenPlanType.isEmpty && !bagSupportsSubscription(chosenPlanType)
            if (hasExclusiveItem && chosenPlanType.isEmpty) || incompatibleSubscription {
                let flowName = chosenPlanType.isEmpty ? "this new order" : "a new subscription"
                offerToReplaceBag(for: flowName) { addToCart(product: product) }
                return
            }
        }
        if !chosenPlanType.isEmpty {
            isCoffeeClubPrepaid = true
            cartSubscriptionPlanType = chosenPlanType
            isGiftOrder = false
            coffeeClubTermsAccepted = false
        } else if cartItems.isEmpty || productPlanType == nil {
            isCoffeeClubPrepaid = false
            cartSubscriptionPlanType = ""
            coffeeClubTermsAccepted = false
        }
        isCafePassPrepaid = false
        suspendedCoffeePass = false
        if product.isGiftCardProduct { isGiftOrder = true }

        recordRecentlyViewed(product)

        let cartItemID = cartItemIdentifier(productID: product.id, variantID: variant.id)

        if let index = cartItems.firstIndex(where: { $0.id == cartItemID }) {
            updateCartItemQuantity(at: index, quantity: cartItems[index].quantity + 1)
        } else {
            cartItems.append(CartItem(id: cartItemID, product: product, variant: variant, quantity: 1))
        }

        checkoutError = nil
        autoApplyAvailableFreeDrinkVoucherIfNeeded()
        triggerCartCelebration()
        let variantSuffix = product.hasVariantChoices ? " (\(variant.title))" : ""
        showToast(message: String(format: AppLocalization.text("product_added_to_cart", fallback: "%@%@ added to bag"), product.name, variantSuffix))
    }

    func addCoffeeClubToCart(product: Product, variant: Product.Variant, quantity: Int, fulfillment: TallaFulfillmentMethod) {
        guard variant.isAvailableForSale else {
            showToast(message: String(format: AppLocalization.text("product_unavailable_toast", fallback: "%@ is unavailable"), product.name))
            return
        }

        guard let selectedPlanType = prepaidPlanType(for: product) else {
            showToast(message: "This product is not available for a prepaid plan.")
            return
        }
        guard bagSupportsSubscription(selectedPlanType) else {
            offerToReplaceBag(for: "a new subscription") {
                addCoffeeClubToCart(product: product, variant: variant, quantity: quantity, fulfillment: fulfillment)
            }
            return
        }
        recordRecentlyViewed(product)

        let safeQuantity = max(1, min(quantity, 6))
        let cartItemID = cartItemIdentifier(productID: product.id, variantID: variant.id)
        if let index = cartItems.firstIndex(where: { $0.id == cartItemID }) {
            updateCartItemQuantity(at: index, quantity: cartItems[index].quantity + safeQuantity)
        } else {
            cartItems.append(CartItem(id: cartItemID, product: product, variant: variant, quantity: safeQuantity))
        }

        fulfillmentMethod = fulfillment
        isCoffeeClubPrepaid = true
        cartSubscriptionPlanType = selectedPlanType
        isGiftOrder = false
        isCafePassPrepaid = false
        coffeeClubTermsAccepted = false
        checkoutError = nil
        triggerCartCelebration()
        cartOpen = true
        let variantSuffix = product.hasVariantChoices ? " (\(variant.title))" : ""
        showToast(message: String(format: AppLocalization.text("product_added_to_cart", fallback: "%@%@ added to bag"), product.name, variantSuffix))
    }

    func addStarterSetupToCart(coffee: Product, setup: Product) {
        guard selectedVariant(for: coffee)?.isAvailableForSale == true,
              selectedVariant(for: setup)?.isAvailableForSale == true else {
            showToast(message: "The coffee or starter setup is currently unavailable.")
            return
        }
        let incompatibleBag = !cartItems.isEmpty && (isCoffeeClubPrepaid || isCafePassPrepaid
            || isGiftOrder || !requestedSubscriptionPlanType.isEmpty
            || cartItems.contains(where: { $0.product.isGiftCardProduct }))
        if incompatibleBag {
            offerToReplaceBag(for: "a coffee and starter setup order") {
                addStarterSetupToCart(coffee: coffee, setup: setup)
            }
            return
        }
        requestedSubscriptionPlanType = ""
        addToCart(product: coffee)
        addToCart(product: setup)
        showToast(message: AppLocalization.text("setup_added_to_bag", fallback: "Coffee and starter setup added to your bag."))
    }

    func triggerCartCelebration() {
        cartCelebrationID += 1
        delightFeedbackTrigger += 1

        withAnimation(.spring(response: 0.26, dampingFraction: 0.48)) {
            showingCartCelebration = true
        }

        let celebrationID = cartCelebrationID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            guard cartCelebrationID == celebrationID else { return }

            withAnimation(.easeOut(duration: 0.18)) {
                showingCartCelebration = false
            }
        }
    }

    func removeFromCart(id: String) {
        cartItems.removeAll { $0.id == id }
        let subscriptionItemsStillMatch = !cartSubscriptionPlanType.isEmpty
            && cartItems.allSatisfy { item in
                ProductCatalogRules.subscriptionPlanType(
                    detectedPlan: defaultPrepaidPlanType(for: item.product),
                    requestedPlan: cartSubscriptionPlanType
                ) == cartSubscriptionPlanType
            }
        if cartItems.isEmpty || !subscriptionItemsStillMatch {
            isCoffeeClubPrepaid = false
            cartSubscriptionPlanType = ""
            coffeeClubTermsAccepted = false
        }
        if cartItems.isEmpty || !isCafePassEligible { isCafePassPrepaid = false }
        if cartItems.isEmpty || !isCafePassEligible { suspendedCoffeePass = false }
        if cartItems.isEmpty {
            requestedSubscriptionPlanType = ""
            isGiftOrder = false
        }
        checkoutError = nil
    }

    func requestRemoveFromCart(id: String) {
        if cartItems.count == 1 {
            pendingCartRemovalID = id
            isConfirmingEmptyBag = true
        } else {
            removeFromCart(id: id)
        }
    }

    func updateCartItemQuantity(at index: Int, quantity: Int) {
        guard cartItems.indices.contains(index) else { return }
        guard !isCafePassActive || quantity == 1 else { return }
        var updatedItem = cartItems[index]
        updatedItem.quantity = max(quantity, 1)
        cartItems[index] = updatedItem
    }

    func cartItemIdentifier(productID: String, variantID: String) -> String {
        "\(productID)::\(variantID)"
    }

    func selectedVariant(for product: Product) -> Product.Variant? {
        if let selectedVariantID = selectedVariantIDs[product.id],
           let variant = product.variants.first(where: { $0.id == selectedVariantID }) {
            return variant
        }

        return product.defaultVariant
    }

    func cartVariantDisplayTitle(for item: CartItem) -> String? {
        let title = item.variant.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard item.product.hasVariantChoices,
              !title.isEmpty,
              title.localizedCaseInsensitiveCompare("Default") != .orderedSame,
              title.localizedCaseInsensitiveCompare("Default Title") != .orderedSame else {
            return nil
        }

        return title
    }

    func isFavorite(_ product: Product) -> Bool {
        favoriteProductIDs.contains(product.id)
    }

    func isAlertEnabled(_ product: Product) -> Bool {
        alertProductIDs.contains(product.id)
    }

    func persistSavedCarts(_ carts: [SavedCart]) {
        guard let data = try? JSONEncoder().encode(carts),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        savedCartsPayload = json
        let activeIDs = Set(carts.map(\.id))
        for cart in carts {
            guard let cartData = try? JSONEncoder().encode(cart),
                  let object = try? JSONSerialization.jsonObject(with: cartData) as? [String: Any] else { continue }
            try? coffeeData.saveEnvelope(entityType: "savedCart", id: cart.id, jsonObject: object)
        }
        for object in coffeeData.legacyObjects(entityType: "savedCart") {
            guard let rawID = object["id"] as? String, let id = UUID(uuidString: rawID), !activeIDs.contains(id) else { continue }
            try? coffeeData.tombstone(entityType: "savedCart", id: id)
        }
        try? coffeeData.commitPendingCoffeeChanges()
    }

    func persistActiveCartForSync() {
        let id = CoffeeDataStore.stableID("active-cart")
        let record = SyncedActiveCart(
            id: id,
            items: cartItems.map { .init(productID: $0.product.id, variantID: $0.variant.id, quantity: $0.quantity) },
            updatedAt: ISO8601DateFormatter().string(from: .now)
        )
        try? coffeeData.saveRecord(record, id: id, entity: "activeCart")
    }

    func restoreSyncedActiveCart() {
        guard cartItems.isEmpty,
              let record = coffeeData.records(SyncedActiveCart.self, entity: "activeCart").first else { return }
        cartItems = record.items.compactMap { item in
            guard let product = products.first(where: { $0.id == item.productID }),
                  let variant = product.variants.first(where: { $0.id == item.variantID }),
                  product.isAvailableForSale, variant.isAvailableForSale else { return nil }
            return CartItem(
                id: cartItemIdentifier(productID: product.id, variantID: variant.id),
                product: product, variant: variant, quantity: max(item.quantity, 1)
            )
        }
        if !cartItems.isEmpty {
            showToast(message: "Your cart was restored from another device")
        }
    }

    func saveCurrentCart() {
        guard !cartItems.isEmpty else {
            showToast(message: AppLocalization.text("add_items_before_saving_cart", fallback: "Add items before saving a bag"))
            return
        }

        let trimmedName = cartSaveName.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedCart = SavedCart(
            id: UUID(),
            name: trimmedName.isEmpty ? defaultSavedCartName() : trimmedName,
            items: cartItems.map {
                SavedCart.Item(productID: $0.product.id, variantID: $0.variant.id, variantTitle: $0.variant.title, productName: $0.product.name, quantity: $0.quantity)
            },
            createdAt: ISO8601DateFormatter().string(from: Date())
        )

        persistSavedCarts([savedCart] + savedCarts)
        cartSaveName = ""
        isCartSaveEntryExpanded = false
        showToast(message: AppLocalization.text("cart_saved_toast", fallback: "Bag saved"))
    }

    func applySavedCart(_ savedCart: SavedCart) {
        guard cartItems.isEmpty else {
            showToast(message: "Finish or clear your current bag before loading a saved bag.")
            cartOpen = true
            return
        }
        let matchedItems = savedCart.items.compactMap { item -> (Product, Product.Variant, Int)? in
            if let product = products.first(where: { $0.id == item.productID }) ?? matchingProduct(for: item.productName) {
                let variant = item.variantID.flatMap { savedID in
                    product.variants.first { $0.id == savedID || $0.id.hasSuffix("/\(savedID)") }
                } ?? selectedVariant(for: product)
                if let variant, variant.isAvailableForSale { return (product, variant, item.quantity) }
            }

            return nil
        }

        guard !matchedItems.isEmpty else {
            showToast(message: AppLocalization.text("saved_cart_unavailable", fallback: "Saved bag items are unavailable right now"))
            return
        }

        cartItems = []
        requestedSubscriptionPlanType = ""
        cartSubscriptionPlanType = ""
        isCoffeeClubPrepaid = false
        isCafePassPrepaid = false
        suspendedCoffeePass = false
        isGiftOrder = false
        for (product, variant, quantity) in matchedItems {
            cartItems.append(
                CartItem(
                    id: cartItemIdentifier(productID: product.id, variantID: variant.id),
                    product: product,
                    variant: variant,
                    quantity: quantity
                )
            )
        }

        cartOpen = true
        if matchedItems.count < savedCart.items.count {
            showToast(message: AppLocalization.text("saved_cart_partially_loaded", fallback: "Some saved options are unavailable and were left out."))
            return
        }
        showToast(message: String(format: AppLocalization.text("saved_cart_loaded_toast", fallback: "%@ loaded"), savedCart.name))
    }

    func deleteSavedCart(_ savedCart: SavedCart) {
        persistSavedCarts(savedCarts.filter { $0.id != savedCart.id })
        showToast(message: AppLocalization.text("saved_cart_deleted_toast", fallback: "Saved bag deleted"))
    }

    func defaultSavedCartName() -> String {
        let itemCount = cartItems.reduce(0) { $0 + $1.quantity }
        return String(format: AppLocalization.text("cart_item_count_accessibility", fallback: "Cart, %d items"), itemCount)
    }

    func toggleFavorite(product: Product) {
        var updatedFavorites = favoriteProductIDs
        recordRecentlyViewed(product)
        let isFavorite: Bool

        if updatedFavorites.contains(product.id) {
            updatedFavorites.remove(product.id)
            isFavorite = false
            showToast(message: AppLocalization.text("removed_from_favorites", fallback: "Removed from favorites"))
        } else {
            updatedFavorites.insert(product.id)
            isFavorite = true
            showToast(message: AppLocalization.text("saved_to_favorites", fallback: "Saved to favorites"))
        }

        delightFeedbackTrigger += 1
        savedFavoriteProductIDs = updatedFavorites.sorted().joined(separator: ",")
        if customerProfile != nil {
            Task { _ = try? await AccountService.setFavorite(productID: product.id, favorite: isFavorite) }
        }
    }

    @MainActor
    func toggleAlert(product: Product) async {
        var updatedAlerts = alertProductIDs

        if updatedAlerts.contains(product.id) {
            updatedAlerts.remove(product.id)
            if let email = customerProfile?.email {
                do {
                    try await AccountService.removeStockAlert(email: email, productID: product.id)
                } catch {
                    showToast(message: isArabicInterface ? "تعذر تحديث التنبيه. حاول مرة أخرى." : "Could not update the alert. Please try again.")
                    return
                }
                backendStockAlerts.removeAll { $0.productID == product.id }
            }
            showToast(message: AppLocalization.text("removed_from_alerts", fallback: "Removed from alerts"))
        } else {
            updatedAlerts.insert(product.id)
            recordRecentlyViewed(product)
            if let email = customerProfile?.email {
                let record = StockAlertRecord(
                    productID: product.id,
                    productName: product.name,
                    tag: product.tag,
                    isAvailableForSale: product.isAvailableForSale,
                    status: product.isAvailableForSale ? "Available now" : "Waiting for availability",
                    updatedAt: ISO8601DateFormatter().string(from: Date())
                )
                do {
                    let stored = try await AccountService.watchStockAlert(email: email, alert: record)
                    backendStockAlerts.removeAll { $0.productID == stored.productID }
                    backendStockAlerts.insert(stored, at: 0)
                } catch {
                    showToast(message: isArabicInterface ? "تعذر حفظ التنبيه. حاول مرة أخرى." : "Could not save the alert. Please try again.")
                    return
                }
            }
            let granted = await requestNotificationAccessIfNeeded()
            if granted {
                showToast(message: AppLocalization.text("availability_notification_enabled", fallback: "We’ll notify you when this product is available."))
            } else {
                showToast(message: AppLocalization.text("added_to_alerts_notifications_off", fallback: "Alert saved. Notifications are not enabled."))
            }
        }

        delightFeedbackTrigger += 1
        savedAlertProductIDs = updatedAlerts.sorted().joined(separator: ",")
    }

    func recordRecentlyViewed(_ product: Product) {
        var updated = recentlyViewedProductIDs.filter { $0 != product.id }
        updated.insert(product.id, at: 0)
        updated = Array(updated.prefix(12))
        savedRecentlyViewedProductIDs = updated.joined(separator: ",")
        if customerProfile != nil {
            Task { _ = try? await AccountService.recordRecentlyViewed(productID: product.id) }
        }
    }

    func productAlertLabel(for product: Product) -> String {
        if !product.isAvailableForSale {
            return AppLocalization.text("waiting_for_availability", fallback: "Waiting for availability")
        }
        return AppLocalization.text("available_now", fallback: "Available now")
    }

    func stockAlertLabel(for product: Product) -> String {
        guard let status = backendStockAlertLookup[product.id]?.status,
              !status.localizedCaseInsensitiveContains("watch") else {
            return productAlertLabel(for: product)
        }
        return status
    }

    func buyAgain(order: AccountOrder) {
        guard cartItems.isEmpty || (!isCoffeeClubPrepaid && !isCafePassPrepaid && !isGiftOrder
            && !cartItems.contains(where: { $0.product.isGiftCardProduct })) else {
            showToast(message: "Finish or clear your current bag before adding another order.")
            cartOpen = true
            return
        }
        guard let items = order.items, !items.isEmpty else { return }

        let matchedProducts = items.compactMap { item -> (Product, Int)? in
            guard let product = matchingProduct(for: item.name) else { return nil }
            return (product, item.quantity)
        }

        guard !matchedProducts.isEmpty else {
            showToast(message: AppLocalization.text("items_unavailable_currently", fallback: "Those items are currently unavailable"))
            return
        }

        if cartItems.isEmpty {
            requestedSubscriptionPlanType = ""
            cartSubscriptionPlanType = ""
            isCoffeeClubPrepaid = false
            isCafePassPrepaid = false
            suspendedCoffeePass = false
            isGiftOrder = false
        }

        for (product, quantity) in matchedProducts {
            guard let variant = selectedVariant(for: product) else { continue }
            let cartItemID = cartItemIdentifier(productID: product.id, variantID: variant.id)
            if let index = cartItems.firstIndex(where: { $0.id == cartItemID }) {
                updateCartItemQuantity(at: index, quantity: cartItems[index].quantity + quantity)
            } else {
                cartItems.append(CartItem(id: cartItemID, product: product, variant: variant, quantity: quantity))
            }
        }

        checkoutError = nil
        cartOpen = true

        if matchedProducts.count == items.count {
            showToast(message: AppLocalization.text("order_added_to_cart", fallback: "Order added to bag"))
        } else {
            showToast(message: AppLocalization.text("available_items_added_from_order", fallback: "Available items from that order were added"))
        }
    }

    func saveTasteMemory(order: AccountOrder, item: AccountOrder.Item, reaction: String, tags: [String]) {
        let record = TasteMemoryRecord(
            id: tasteMemoryKey(order: order, item: item),
            orderID: order.id,
            productName: item.name,
            reaction: reaction,
            tags: tags,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: nil
        )
        let existing = tasteMemoryRecords.filter { $0.id != record.id }
        let updated = Array(([record] + existing).prefix(80))

        persistTasteMemoryRecords(updated)
        delightFeedbackTrigger += 1
        showToast(message: AppLocalization.text("taste_memory_saved", fallback: "Taste memory saved"))

        if let profile = customerProfile {
            Task {
                do {
                    _ = try await AccountService.saveTasteMemory(
                        email: profile.email,
                        orderID: order.id,
                        productName: item.name,
                        reaction: reaction,
                        tags: tags
                    )
                    let remoteTasteMemory = try await AccountService.fetchTasteMemory(email: profile.email)
                    await MainActor.run {
                        persistTasteMemoryRecords(remoteTasteMemory)
                    }
                } catch {
                    return
                }
            }
        }
    }

    func persistTasteMemoryRecords(_ records: [TasteMemoryRecord]) {
        let sortedRecords = records
            .sorted {
                let lhsDate = ISO8601DateFormatter().date(from: $0.updatedAt ?? $0.createdAt) ?? .distantPast
                let rhsDate = ISO8601DateFormatter().date(from: $1.updatedAt ?? $1.createdAt) ?? .distantPast
                return lhsDate > rhsDate
            }
        var seenRecordIDs = Set<String>()
        let uniqueRecords = Array(sortedRecords.filter { record in
            guard !seenRecordIDs.contains(record.id) else { return false }
            seenRecordIDs.insert(record.id)
            return true
        }.prefix(80))

        guard let data = try? JSONEncoder().encode(uniqueRecords),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        savedTasteMemory = json
    }

    func matchingProduct(for orderItemName: String) -> Product? {
        let normalizedOrderName = normalizedProductName(orderItemName)

        return products.first { normalizedProductName($0.name) == normalizedOrderName }
            ?? products.first {
                let normalizedProduct = normalizedProductName($0.name)
                return normalizedProduct.contains(normalizedOrderName) || normalizedOrderName.contains(normalizedProduct)
            }
    }

    func tasteMemoryKey(order: AccountOrder, item: AccountOrder.Item) -> String {
        "\(order.id)-\(normalizedProductName(item.name))"
    }

    func tastePreferenceScore(for product: Product) -> Int {
        let productText = normalizedSearchText(for: product)
        var profileScore = 0
        if tasteProfileConfigured {
        switch savedTasteProfile.acidity {
        case "low": profileScore += profileKeywordScore(productText, keywords: ["smooth", "low acid", "chocolate", "nutty", "brazil"])
        case "high": profileScore += profileKeywordScore(productText, keywords: ["bright", "acid", "citrus", "floral", "fruit", "ethiopia"])
        default: profileScore += profileKeywordScore(productText, keywords: ["balanced", "clean", "sweet"])
        }
        switch savedTasteProfile.sweetness {
        case "sweet": profileScore += profileKeywordScore(productText, keywords: ["sweet", "caramel", "honey", "chocolate"])
        default: profileScore += profileKeywordScore(productText, keywords: ["clean", "tea", "floral"])
        }
        switch savedTasteProfile.body {
        case "light": profileScore += profileKeywordScore(productText, keywords: ["tea", "clean", "floral", "washed"])
        case "full": profileScore += profileKeywordScore(productText, keywords: ["body", "rich", "espresso", "chocolate", "nutty"])
        default: profileScore += profileKeywordScore(productText, keywords: ["balanced", "smooth"])
        }
        switch savedTasteProfile.roast {
        case "light": profileScore += profileKeywordScore(productText, keywords: ["light", "washed", "floral", "fruit"])
        case "dark": profileScore += profileKeywordScore(productText, keywords: ["dark", "bold", "espresso"])
        default: profileScore += profileKeywordScore(productText, keywords: ["medium", "balanced", "sweet"])
        }
        if savedTasteProfile.temperature == "iced" {
            profileScore += profileKeywordScore(productText, keywords: ["iced", "cold", "summer", "refreshing"])
        }
        if savedTasteProfile.style == "arabic" {
            profileScore += profileKeywordScore(productText, keywords: ["arabic", "qahwa", "cardamom", "yemen"])
        } else {
            profileScore += profileKeywordScore(productText, keywords: ["single-origin", "specialty", "washed", "natural"])
        }
        }

        return tasteMemoryRecords.reduce(profileScore) { score, record in
            let tagScore = record.tags.reduce(0) { partialResult, tag in
                partialResult + (productText.contains(tag.lowercased()) ? 3 : 0)
            }
            let reactionScore = record.reaction == "loved" ? tagScore : -tagScore
            let productPenalty = record.reaction == "not-for-me" && normalizedProductName(record.productName) == normalizedProductName(product.name) ? -8 : 0
            return score + reactionScore + productPenalty
        }
    }

    func profileKeywordScore(_ text: String, keywords: [String]) -> Int {
        keywords.reduce(0) { partialResult, keyword in
            partialResult + (text.contains(keyword) ? 2 : 0)
        }
    }

    func daysSinceOrder(_ order: AccountOrder) -> Int {
        let startOfOrderDay = Calendar.current.startOfDay(for: orderDate(from: order.createdAt))
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return max(Calendar.current.dateComponents([.day], from: startOfOrderDay, to: startOfToday).day ?? 0, 0)
    }

    func orderDate(from value: String) -> Date {
        if let date = ISO8601DateFormatter().date(from: value) {
            return date
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        if let date = formatter.date(from: value) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value) ?? .distantPast
    }

    func normalizedProductName(_ name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: "&", with: "and")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }

    @MainActor
    func applyVoucher() async {
        guard let profile = customerProfile else {
            voucherError = AppLocalization.text("sign_in_to_apply_voucher", fallback: "Sign in to apply a loyalty voucher.")
            return
        }

        let trimmedCode = voucherCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedCode.isEmpty else {
            voucherError = AppLocalization.text("enter_voucher_code_first", fallback: "Enter a voucher code first.")
            return
        }

        isApplyingVoucher = true
        voucherError = nil

        do {
            let voucher = try await AccountService.previewVoucher(code: trimmedCode, email: profile.email)
            guard !LoyaltyVoucherRules.isFreeDrink(voucher.reward) || cartDiscountForFreeDrink > 0 else {
                throw LoyaltyServiceError.operationFailed(
                    AppLocalization.text(
                        "free_drink_requires_eligible_drink",
                        fallback: "Add a drink from the Drinks section before applying this reward."
                    )
                )
            }
            appliedVoucher = voucher
            voucherCodeInput = trimmedCode
            await loadAvailableVouchers(for: profile.email)
            showToast(message: AppLocalization.text("voucher_applied_toast", fallback: "Voucher applied"))
        } catch {
            appliedVoucher = nil
            voucherError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("voucher_apply_failed", fallback: "This voucher could not be applied right now.")
            )
        }

        isApplyingVoucher = false
    }

    func removeAppliedVoucher() {
        appliedVoucher = nil
        voucherError = nil
        voucherCodeInput = ""
    }

    @MainActor
    func loadAvailableVouchers(for email: String) async {
        guard !email.isEmpty else { return }

        isLoadingAvailableVouchers = true

        do {
            availableVouchers = try await AccountService.fetchVouchers(email: email)
        } catch {
            availableVouchers = []
        }

        isLoadingAvailableVouchers = false
    }

    @MainActor
    func autoApplyAvailableFreeDrinkVoucherIfNeeded() {
        guard appliedVoucher == nil, cartDiscountForFreeDrink > 0 else { return }
        guard let voucher = availableVouchers.first(where: { LoyaltyVoucherRules.isFreeDrink($0.reward) }) else { return }

        appliedVoucher = voucher
        voucherCodeInput = voucher.code
        showToast(message: "Free drink added to your bag")
    }

    @MainActor
    func preparePostPaymentContext(orderID: String, method: TallaPaymentMethod) {
        postPaymentOrderID = orderID
        postPaymentTotal = formattedCustomerCurrency(cartTotal)
        postPaymentMethodTitle = method.title
        if isDigitalGiftCardOnlyCart {
            postPaymentFulfillmentTitle = isArabicInterface ? "إرسال رقمي" : "Digital delivery"
            postPaymentDestination = giftRecipientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if fulfillmentMethod == .pickup {
            postPaymentFulfillmentTitle = AppLocalization.text("pickup", fallback: "Pickup")
            postPaymentDestination = managedPickupName
        } else {
            postPaymentFulfillmentTitle = AppLocalization.text("delivery", fallback: "Delivery")
            postPaymentDestination = preferredAddress.map {
                "\($0.label) · \($0.line1), \($0.city), \($0.country.name)"
            } ?? ""
        }
    }

    @MainActor
    func presentPostPayment() {
        isCheckoutPresented = false
        isPostPaymentPresented = true
    }

    @MainActor
    func dismissPostPayment(openOrders: Bool = false, openShop shouldOpenShop: Bool = false) {
        isPostPaymentPresented = false

        if !paymentFlow.state.isBusy {
            paymentFlow.reset()
        }

        guard openOrders || shouldOpenShop else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if openOrders {
                openAccountSection(AccountSectionView.ScrollTarget.customer)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                    accountOrdersPresentationRequest += 1
                }
            } else if shouldOpenShop {
                openShop()
            }
        }
    }

    @MainActor
    func retryPostPayment() {
        isPostPaymentPresented = false
        paymentFlow.reset()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            prepareCheckout()
        }
    }

    @MainActor
    func prepareCheckout() {
        guard !cartItems.isEmpty else { return }

        if cartRequiresPickup || isCafePassActive { fulfillmentMethod = .pickup }

        guard remoteAppSettings?.release?.checkoutMaintenanceEnabled != true,
              remoteAppSettings?.release?.maintenanceEnabled != true else {
            checkoutError = isArabicInterface ? "الدفع غير متاح مؤقتاً." : "Checkout is temporarily unavailable."
            return
        }

        guard isDigitalGiftCardOnlyCart || isCafePassActive
                || (fulfillmentMethod == .delivery && remoteAppSettings?.fulfillment?.deliveryEnabled != false)
                || (fulfillmentMethod == .pickup && remoteAppSettings?.fulfillment?.pickupEnabled != false && !pickupTemporarilyClosed && !pickupTimeSlots.isEmpty) else {
            checkoutError = isArabicInterface ? "طريقة الاستلام هذه غير متاحة حالياً." : "This fulfillment method is currently unavailable."
            return
        }

        if cartItems.contains(where: { $0.product.isGiftCardProduct }) {
            // Shopify Checkout chooses the actual online method; the app must not promise a local gateway.
            paymentFlow.select(.card)
        } else if paymentFlow.selectedMethod == nil {
            if isApplePayAvailable && MastercardSDKAvailability.isAvailable {
                paymentFlow.select(.applePay)
            } else if BenefitPaySDKConfiguration.isAvailable {
                paymentFlow.select(.benefitPay)
            } else {
                paymentFlow.select(.benefit)
            }
        }

        checkoutError = nil
        cartOpen = false
        isCheckoutPresented = true
    }

    @MainActor
    func beginCheckout() async {
        let containsDigitalGiftCard = cartItems.contains { $0.product.isGiftCardProduct }
        guard let selectedPaymentMethod = paymentFlow.selectedMethod else {
            isPaymentMethodSheetPresented = true
            return
        }

        guard containsDigitalGiftCard || paymentAvailability.isEnabled(selectedPaymentMethod) else {
            paymentFlow.transition(to: .failed)
            checkoutError = isArabicInterface ? "طريقة الدفع هذه غير متاحة حالياً." : "This payment method is currently unavailable."
            return
        }

        if !containsDigitalGiftCard, selectedPaymentMethod == .applePay, !isApplePayAvailable {
#if canImport(PassKit)
            PKPassLibrary().openPaymentSetup()
#endif
            checkoutError = AppLocalization.text(
                "apple_pay_setup_required",
                fallback: "Add a supported card to Apple Wallet, then return to complete checkout with Apple Pay."
            )
            return
        }

        guard !isCheckingOut, paymentFlow.begin() else { return }

        guard !cartItems.isEmpty else {
            paymentFlow.transition(to: .failed)
            checkoutError = AppLocalization.text("cart_no_purchasable_items", fallback: "Your bag has no purchasable items.")
            return
        }

        guard let profile = customerProfile else {
            paymentFlow.transition(to: .failed)
            checkoutError = AppLocalization.text("sign_in_before_checkout", fallback: "Sign in before checkout.")
            return
        }

        if isGiftOrder && !cartItems.contains(where: { $0.product.isGiftCardProduct })
            && giftRecipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            paymentFlow.transition(to: .failed)
            checkoutError = AppLocalization.text("gift_recipient_required", fallback: "Add the recipient name before placing a gift order.")
            return
        }

        let trimmedGiftRecipientEmail = giftRecipientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if containsDigitalGiftCard {
            let emailParts = trimmedGiftRecipientEmail.split(separator: "@", omittingEmptySubsequences: false)
            guard emailParts.count == 2,
                  !emailParts[0].isEmpty,
                  emailParts[1].contains("."),
                  !emailParts[1].hasPrefix("."),
                  !emailParts[1].hasSuffix(".") else {
                paymentFlow.transition(to: .failed)
                checkoutError = "Enter a valid recipient email for the digital gift card."
                return
            }
            guard selectedPaymentMethod != .cashOnDelivery else {
                paymentFlow.transition(to: .failed)
                checkoutError = "Digital gift cards require online payment. Choose a card or Benefit payment method."
                return
            }
        }

        if isCoffeeClubActive && coffeeClubPlanType == "office"
            && officeCompanyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            paymentFlow.transition(to: .failed)
            checkoutError = "Add your company name for the office coffee order."
            return
        }

        guard canStartCheckoutWithShipping else {
            paymentFlow.transition(to: .failed)
            checkoutError = cartShipmentWeightGrams == nil
                ? AppLocalization.text("shipping_weight_missing_detail", fallback: "A product in your bag has no shipping weight. Please contact us before checkout.")
                : AppLocalization.text("shipping_weight_over_limit_detail", fallback: "Khaleeji delivery is available for shipments up to 4 kg. Please contact us for a larger order.")
            return
        }

        if isCoffeeClubActive {
            guard coffeeClubTermsAccepted else {
                paymentFlow.transition(to: .failed)
                checkoutError = AppLocalization.text(
                    "coffee_club_terms_required",
                    fallback: "Accept the Coffee Club prepaid plan terms before checkout."
                )
                return
            }
            guard selectedPaymentMethod != .cashOnDelivery else {
                paymentFlow.transition(to: .failed)
                checkoutError = AppLocalization.text(
                    "coffee_club_online_payment_required",
                    fallback: "Coffee Club is prepaid. Choose BenefitPay, BENEFIT, card, Click to Pay, or Apple Pay."
                )
                return
            }
            guard fulfillmentMethod == .pickup || preferredAddress?.country == .bahrain else {
                paymentFlow.transition(to: .failed)
                checkoutError = AppLocalization.text(
                    "coffee_club_bahrain_only",
                    fallback: "Coffee Club delivery is currently available in Bahrain. Choose pickup or use a Bahrain delivery address."
                )
                return
            }
        }

        if isCafePassActive {
            guard selectedPaymentMethod != .cashOnDelivery else {
                paymentFlow.transition(to: .failed)
                checkoutError = "The café pass must be paid online before use."
                return
            }
            guard fulfillmentMethod == .pickup else {
                paymentFlow.transition(to: .failed)
                checkoutError = "The café pass is for café pickup only."
                return
            }
        }

        isCheckingOut = true
        checkoutError = nil
        preparePostPaymentContext(orderID: "", method: selectedPaymentMethod)

        do {
            if let appliedVoucher,
               LoyaltyVoucherRules.isFreeDrink(appliedVoucher.reward),
               cartDiscountForFreeDrink <= 0 {
                throw LoyaltyServiceError.operationFailed(
                    AppLocalization.text(
                        "free_drink_requires_eligible_drink",
                        fallback: "Add a drink from the Drinks section before using this reward."
                    )
                )
            }

            if selectedPaymentMethod.route == .shopifyCashOnDelivery || containsDigitalGiftCard {
                guard appliedVoucher == nil else {
                    throw LoyaltyServiceError.operationFailed(
                        AppLocalization.text(
                            "cash_on_delivery_remove_voucher",
                            fallback: "Remove the Talla voucher before using Shopify Checkout so the verified totals stay identical."
                        )
                    )
                }
                let lines = cartItems.map { item -> ShopifyCheckoutLine in
                    guard item.product.isGiftCardProduct else {
                        return ShopifyCheckoutLine(merchandiseId: item.variant.id, quantity: item.quantity)
                    }
                    var attributes = [
                        ["key": "Recipient email", "value": trimmedGiftRecipientEmail],
                        ["key": "__shopify_send_gift_card_to_recipient", "value": "true"]
                    ]
                    let recipientName = giftRecipientName.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !recipientName.isEmpty {
                        attributes.append(["key": "Recipient name", "value": String(recipientName.prefix(120))])
                    }
                    let message = giftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !message.isEmpty {
                        attributes.append(["key": "Message", "value": String(message.prefix(200))])
                    }
                    return ShopifyCheckoutLine(merchandiseId: item.variant.id, quantity: item.quantity, attributes: attributes)
                }
                let checkoutAddress = !isDigitalGiftCardOnlyCart && fulfillmentMethod == .delivery ? preferredAddress.map { address in
                    ShopifyCheckoutAddress(
                        email: profile.email,
                        fullName: address.fullName,
                        phone: address.phone,
                        address1: address.line1,
                        city: address.city,
                        country: address.country.rawValue
                    )
                } : nil
                let checkoutURL = try await ShopifyStorefrontClient.createCheckoutURL(
                    lines: lines,
                    customerEmail: profile.email,
                    checkoutAddress: checkoutAddress,
                    fulfillmentMethod: isDigitalGiftCardOnlyCart ? nil : fulfillmentMethod,
                    pickupSlot: !isDigitalGiftCardOnlyCart && fulfillmentMethod == .pickup ? selectedPickupSlot : nil,
                    giftOrder: isGiftOrder,
                    giftRecipientName: giftRecipientName,
                    giftRecipientPhone: giftRecipientPhone,
                    giftMessage: giftMessage
                )
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                presentPayment(.hosted(CheckoutSession(url: checkoutURL)))
                let checkoutPrompt = containsDigitalGiftCard
                    ? "Complete online payment in Shopify Checkout. Shopify will email the digital gift card to the recipient after fulfillment."
                    : fulfillmentMethod == .pickup
                    ? AppLocalization.text(
                        "cash_on_pickup_shopify_prompt",
                        fallback: "Choose local pickup and Cash on Delivery in Shopify Checkout to place your order."
                    )
                    : AppLocalization.text(
                        "cash_on_delivery_shopify_prompt",
                        fallback: "Choose Cash on Delivery in Shopify Checkout to place your order."
                    )
                showToast(message: checkoutPrompt)
                isCheckingOut = false
                return
            }

            let checkoutItems = cartItems.map { item in
                (
                    name: item.product.name,
                    quantity: item.quantity,
                    variantID: item.variant.id
                )
            }
            let checkoutStart = try await AccountService.recordCheckoutStarted(
                email: profile.email,
                items: checkoutItems,
                total: cartTotal,
                fulfillmentMethod: fulfillmentMethod,
                address: fulfillmentMethod == .delivery ? preferredAddress : nil,
                pickupSlot: fulfillmentMethod == .pickup && !isCafePassActive ? selectedPickupSlot : nil,
                pickupLocationID: fulfillmentMethod == .pickup && !isCafePassActive ? selectedPickupLocationID : nil,
                paymentMethod: selectedPaymentMethod,
                voucherCode: isCafePassActive ? nil : appliedVoucher?.code,
                prepaidCoffeeClub: isCoffeeClubActive,
                prepaidCafePass: isCafePassActive,
                coffeeClubShipmentCount: configuredCoffeeClubShipmentCount,
                coffeeClubIntervalWeeks: coffeeClubIntervalWeeks,
                coffeeClubPlanType: coffeeClubPlanType,
                coffeeClubTermsAccepted: coffeeClubTermsAccepted,
                giftOrder: isGiftOrder,
                giftRecipientName: giftRecipientName,
                giftRecipientPhone: giftRecipientPhone,
                giftMessage: giftMessage,
                officeDetails: isCoffeeClubActive && coffeeClubPlanType == "office" ? [
                    "companyName": officeCompanyName,
                    "vatRegistrationNumber": officeVATNumber,
                    "commercialRegistrationNumber": officeCommercialRegistrationNumber,
                    "purchaseOrderReference": officePurchaseOrderReference
                ] : nil,
                cafePassCreditCount: cafePassCreditCount,
                suspendedCoffeePass: suspendedCoffeePass
            )
            if let appliedVoucher {
                if checkoutStart.pricingVersion != 2 {
                    _ = try await AccountService.consumeVoucher(code: appliedVoucher.code, email: profile.email)
                }
                await loadAvailableVouchers(for: profile.email)
            }
            orderHistory = checkoutStart.orders
            preparePostPaymentContext(orderID: checkoutStart.orderID, method: selectedPaymentMethod)

            switch selectedPaymentMethod.route {
            case .benefitHosted:
                let paymentURL = try await AccountService.createBenefitPayment(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                presentPayment(.hosted(CheckoutSession(url: paymentURL)))
            case .benefitPaySDK:
                guard BenefitPaySDKConfiguration.isAvailable else {
                    throw PaymentServiceError.gateway("BenefitPay is not configured in this build.")
                }
                let session = try await BenefitPayService.createSession(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                presentPayment(.benefitPay(session))
            case .cardGateway:
                guard MastercardSDKAvailability.isAvailable else {
                    throw PaymentServiceError.gateway("Gateway.xcframework and uSDK.xcframework are required for card entry and 3-D Secure.")
                }
                let session = try await TallaPaymentService.createCardSession(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                presentPayment(.mastercard(MastercardPaymentContext(
                    localOrderID: checkoutStart.orderID,
                    session: session,
                    kind: .card
                )))
            case .clickToPayHosted:
                let checkout = try await TallaPaymentService.createClickToPay(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                presentPayment(.hosted(CheckoutSession(url: checkout.paymentUrl, kind: .clickToPay)))
            case .applePayGateway:
                guard isApplePayAvailable else {
                    throw PaymentServiceError.gateway("Apple Pay is unavailable on this device.")
                }
                guard MastercardSDKAvailability.isAvailable else {
                    throw PaymentServiceError.gateway("Gateway.xcframework and uSDK.xcframework are required for Apple Pay gateway tokenization.")
                }
                let session = try await TallaPaymentService.createApplePaySession(orderID: checkoutStart.orderID)
                paymentFlow.transition(to: .awaitingCustomer)
                cartOpen = false
                presentPayment(.mastercard(MastercardPaymentContext(
                    localOrderID: checkoutStart.orderID,
                    session: session,
                    kind: .applePay
                )))
            case .shopifyCashOnDelivery:
                break
            }
            appliedVoucher = nil
            voucherCodeInput = ""
            voucherError = nil
            showToast(message: AppLocalization.text("checkout_opened_toast", fallback: "Checkout opened. Return to Talla after payment."))
        } catch {
            paymentFlow.transition(to: .failed, error: error.localizedDescription)
            if isExpiredCustomerSessionError(error) {
                signOutCustomer(clearError: false)
                checkoutError = AppLocalization.text(
                    "checkout_session_expired",
                    fallback: "Your session expired. Sign in again to continue checkout."
                )
            } else {
                checkoutError = customerFacingServiceMessage(
                    for: error,
                    fallback: AppLocalization.text("checkout_start_failed", fallback: "Checkout could not be started right now. Your bag is still saved.")
                )
            }
        }

        isCheckingOut = false
    }

    func showToast(message: String) {
        let message = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        withAnimation(.easeOut(duration: 0.2)) {
            toastMessage = message
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            guard toastMessage == message else { return }
            withAnimation(.easeIn(duration: 0.2)) {
                toastMessage = nil
            }
        }
    }

    func categoryDefinition(for key: String) -> ShopCategory {
        if key == "drip-bags" {
            return categoryDefinition(for: "coffee-beans")
        }
        if let event = eventForCategory(key) {
            return ShopCategory(
                key: key,
                title: eventCategoryTitle(event),
                subtitle: eventCategorySubtitle(event),
                symbol: event.symbol.isEmpty ? "sparkles" : event.symbol
            )
        }

        if key == "tea" || key == "drinks" {
            return categoryDefinition(for: "ready-made-drinks")
        }

        if key == "drink-cups" || key == "mugs" || key == "drinkware" {
            return categoryDefinition(for: "cups")
        }

        if key == "northern-coffee" {
            return categoryDefinition(for: "arabic-coffee-beans")
        }

        if key == "bread" || key == "crmb-tallas-speciality-bakery" {
            return categoryDefinition(for: "desserts")
        }

        if key == "other" {
            return categoryDefinition(for: "arabic-coffee-beans")
        }

        if let category = categoryCatalog.first(where: { $0.key == key }) {
            return localizedCategory(category)
        }

        let normalizedKey = key.replacingOccurrences(of: "_", with: "-")

        return ShopCategory(
            key: key,
            title: categoryLabel(for: key),
            subtitle: normalizedKey.contains("drink") ? "Ready-to-enjoy picks" : "Curated Talla selection",
            symbol: categorySymbol(for: normalizedKey)
        )
    }

    func categoryLabel(for key: String) -> String {
        guard key != "all" else { return AppLocalization.text("category_all", fallback: "All") }
        if let event = eventForCategory(key) {
            return eventCategoryTitle(event)
        }
        if key == "summer-drinks" {
            return AppLocalization.text("category_summer_drinks", fallback: "Summer Boxes")
        }
        if key == "coffee-beans" {
            return AppLocalization.text("category_coffee_beans", fallback: "Coffee Beans")
        }
        if key == "arabic-coffee-beans" || key == "northern-coffee" || key == "other" {
            return AppLocalization.text("category_arabic_coffee", fallback: "Arabic & Shamali Coffee")
        }
        if key == "drip-bags" {
            return AppLocalization.text("category_drip_bags", fallback: "Drip Bags")
        }
        if key == "coffee-equipment" {
            return AppLocalization.text("category_equipment", fallback: "Equipment")
        }
        if key == "ready-made-drinks" || key == "tea" || key == "drinks" {
            return AppLocalization.text("category_ready_drinks", fallback: "Drinks")
        }
        if key == "cups" || key == "drink-cups" || key == "mugs" || key == "drinkware" {
            return AppLocalization.text("category_cups", fallback: "Cups")
        }
        if key == "crmb-tallas-speciality-bakery" || key == "desserts" || key == "bread" {
            return AppLocalization.text("category_desserts", fallback: "CRMB")
        }
        if key == "spreads" {
            return AppLocalization.text("category_spreads", fallback: "Spreads")
        }
        if key == "hot-chocolate" {
            return AppLocalization.text("category_hot_chocolate", fallback: "Hot Chocolate")
        }
        if key == "gifts" {
            return AppLocalization.text("category_gifts", fallback: "Talla Boxes")
        }
        return key
            .replacingOccurrences(of: "_", with: "-")
            .split(separator: "-")
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    func categorySymbol(for key: String) -> String {
        if key.contains("summer") {
            return "sun.max.fill"
        }

        if key.contains("bean") || key.contains("coffee") {
            return "leaf.fill"
        }

        if key.contains("drip") {
            return "drop.fill"
        }

        if key.contains("equipment") {
            return "flask.fill"
        }

        if key.contains("cup") {
            return "mug.fill"
        }

        if key.contains("drink") {
            return "takeoutbag.and.cup.and.straw.fill"
        }

        if key.contains("tea") {
            return "teapot.fill"
        }

        if key.contains("dessert") || key.contains("bread") {
            return "birthday.cake.fill"
        }

        if key.contains("spread") || key.contains("jam") || key.contains("butter") {
            return "takeoutbag.and.cup.and.straw.fill"
        }

        if key.contains("chocolate") {
            return "takeoutbag.and.cup.and.straw.fill"
        }

        if key.contains("gift") {
            return "gift.fill"
        }

        return "shippingbox.fill"
    }

    func bundledLoyaltyPass() -> PKPass? {
        guard let passURL = Bundle.main.url(forResource: "TallaLoyalty", withExtension: "pkpass"),
              let data = try? Data(contentsOf: passURL),
              let pass = try? PKPass(data: data) else {
            return nil
        }

        return pass
    }

    func priceValue(from price: String) -> Double {
        let sanitized = price
            .replacingOccurrences(of: "BHD", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(sanitized) ?? 0
    }

    func formattedBHD(_ value: Double) -> String {
        CheckoutCurrencyFormatter.bhd(Decimal(value))
    }

    func formattedCustomerCurrency(_ value: Double) -> String {
        CheckoutCurrencyFormatter.customerDisplay(
            bhdAmount: value,
            country: preferredAddress?.country ?? .bahrain
        )
    }

    func displayedProductPrice(_ value: String) -> String {
        guard value.uppercased().contains("BHD") else { return value }
        return formattedCustomerCurrency(customerPriceValue(from: value))
    }

    func voucherExpiresSoon(_ voucher: VoucherRecord) -> Bool {
        guard let expiryDate = ISO8601DateFormatter().date(from: voucher.expiresAt) else { return false }
        return expiryDate.timeIntervalSinceNow <= 3 * 24 * 60 * 60
    }

    func voucherExpiryLabel(for voucher: VoucherRecord) -> String {
        guard let expiryDate = ISO8601DateFormatter().date(from: voucher.expiresAt) else {
            return AppLocalization.text("voucher_active", fallback: "Active")
        }

        let days = max(Int(ceil(expiryDate.timeIntervalSinceNow / (24 * 60 * 60))), 0)
        if days <= 0 {
            return AppLocalization.text("voucher_expires_today", fallback: "Expires today")
        }
        if days == 1 {
            return AppLocalization.text("voucher_one_day_left", fallback: "1 day left")
        }
        return String(format: AppLocalization.text("voucher_days_left", fallback: "%d days left"), days)
    }

    func formattedDiscountLabel(for voucher: VoucherRecord) -> String {
        switch voucher.reward.lowercased() {
        case "free drink":
            return AppLocalization.text("one_eligible_drink", fallback: "1 eligible drink")
        default:
            return voucher.detail
        }
    }

    func formattedVoucherDetail(for voucher: VoucherRecord) -> String {
        if LoyaltyVoucherRules.isFreeDrink(voucher.reward) {
            return AppLocalization.text("free_drink_reward_detail", fallback: "One drink of your choice from the Drinks section.")
        }
        return voucher.detail
    }

    var cartDiscountForFreeDrink: Double {
        LoyaltyVoucherRules.freeDrinkDiscount(
            lines: cartItems.map {
                (
                    categoryKey: $0.product.categoryKey,
                    unitPrice: priceValue(from: $0.variant.price),
                    quantity: $0.quantity
                )
            }
        )
    }

    func handleBenefitPayReturn(_ url: URL) {
        guard let session = benefitPaySession,
              BenefitPayCallbackParser.referenceID(from: url) == session.referenceId else {
            benefitPaySession = nil
            paymentFlow.transition(to: .failed, error: "BenefitPay returned an invalid payment reference.")
            presentPostPayment()
            return
        }
        benefitPaySession = nil
        paymentFlow.transition(to: .processing)
        presentPostPayment()
        Task {
            do {
                let confirmation = try await BenefitPayService.confirm(session: session)
                guard confirmation.status == "succeeded" else {
                    paymentFlow.transition(to: .failed, error: "BenefitPay did not confirm this payment.")
                    return
                }
                cartItems.removeAll()
                requestedSubscriptionPlanType = ""
                appliedVoucher = nil
                voucherCodeInput = ""
                voucherError = nil
                paymentFlow.transition(to: .succeeded)
                await loadOrderHistory()
                if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await loadLoyaltyAccount()
                }
            } catch {
                paymentFlow.transition(to: .failed, error: error.localizedDescription)
            }
        }
    }

}
