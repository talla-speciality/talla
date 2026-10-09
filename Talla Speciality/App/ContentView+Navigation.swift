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
    func dismissKeyboard() {
#if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
#endif
    }

    func openTab(_ tab: Tab) {
        activeTab = tab
        tabScrollTarget = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            tabScrollTarget = tab
        }
    }

    func openShop(category: String = "all", searchQuery: String = "") {
        activeCategory = ProductCatalogRules.shopCategoryKey(for: category)
        shopSearchQuery = searchQuery
        openTab(.shop)
    }

    func openBrewing(category: String = "All") {
        activeBrewingCategory = category
        openTab(.brewing)
    }

    func startBrewing(product: Product, useRecommendedRecipe: Bool = false) {
        let coffeeName = product.name.trimmingCharacters(in: .whitespacesAndNewlines)
        selectedProduct = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            brewRecipeName = coffeeName
            openBrewing(category: product.categoryKey == "arabic-coffee-beans" ? "Traditional" : "All")
            pendingBrewingCoffeeName = coffeeName
            pendingBrewingCoffeeOrigin = product.countryOfOrigin ?? ""
            pendingBrewingCoffeeNotes = product.desc
            pendingRecommendedRecipe = useRecommendedRecipe
            TallaTelemetry.shared.track(useRecommendedRecipe ? "recommendation_to_brew_started" : "brew_from_product_started", properties: ["product": coffeeName])
            showToast(message: AppLocalization.text("brew_ready", fallback: "Coffee added to your brewing workspace"))
        }
    }

    func openAccountSection(_ target: String, authMode: AccountAuthMode? = nil) {
        if let authMode {
            switchAccountAuthMode(authMode)
        }

        switch target {
        case AccountSectionView.ScrollTarget.customer:
            isCustomerSectionExpanded = true
        case AccountSectionView.ScrollTarget.loyalty:
            isLoyaltySectionExpanded = true
            savedLoyaltyEmail = savedCustomerEmail.isEmpty ? savedLoyaltyEmail : savedCustomerEmail
        case AccountSectionView.ScrollTarget.library:
            isLibrarySectionExpanded = true
        case AccountSectionView.ScrollTarget.shopping:
            isShoppingSectionExpanded = true
        case AccountSectionView.ScrollTarget.brewing:
            isBrewingSectionExpanded = true
        case AccountSectionView.ScrollTarget.support:
            isSupportSectionExpanded = true
        default:
            break
        }

        activeTab = .more
        isAccountPresentedFromMore = true
        accountScrollTarget = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            accountScrollTarget = target
        }
    }

    func handleShortcutDestination() {
        guard !shortcutDestination.isEmpty else { return }

        hasSeenWelcome = true
        let destination = shortcutDestination
        let searchQuery = shortcutSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        shortcutDestination = ""
        shortcutSearchQuery = ""

        switch destination {
        case "home":
            openTab(.home)
        case "shop":
            openShop(searchQuery: searchQuery)
        case "concierge":
            if !searchQuery.isEmpty {
                conciergeRequest = searchQuery
            }
            openCoffeeConcierge()
            if !searchQuery.isEmpty {
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(350))
                    await runCoffeeConcierge(requestOverride: searchQuery)
                }
            }
        case "brewing":
            openBrewing()
        case "gifts":
            let giftID = UserDefaults.standard.string(forKey: "shortcut.giftID")
            UserDefaults.standard.removeObject(forKey: "shortcut.giftID")
            if let giftID, let stored = TallaGiftVault.all().first(where: { $0.orderID == giftID }) {
                socialCoffeePassGift = SocialCoffeePassGift(orderID: stored.orderID, token: stored.token)
            } else {
                isCoffeeGiftVaultPresented = true
            }
        case "group-order":
            guard !searchQuery.isEmpty else { break }
            socialCoffeeInvite = SocialCoffeeInvite(id: searchQuery, inviteCode: "")
        case "reorder":
            Task { await handlePendingReorderFromShortcut() }
        case "shelf", "favorites":
            openTab(.home)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                isFavoriteShelfPresented = true
            }
        case "rewards":
            openAccountSection(AccountSectionView.ScrollTarget.loyalty)
        case "apply-reward":
            let rewardID = UserDefaults.standard.string(forKey: "shortcut.rewardID") ?? ""
            UserDefaults.standard.removeObject(forKey: "shortcut.rewardID")
            openAccountSection(AccountSectionView.ScrollTarget.loyalty)
            guard !rewardID.isEmpty else { break }
            voucherCodeInput = rewardID
            Task { await applyVoucher() }
        case "orders", "order-history", "checkout-return":
            openAccountSection(AccountSectionView.ScrollTarget.customer)
            Task {
                await loadOrderHistory()
                if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await loadLoyaltyAccount()
                }
            }
            showToast(message: AppLocalization.text("order_history_opened", fallback: "Order history opened"))
        default:
            break
        }
    }

    @MainActor
    func handlePendingReorderFromShortcut() async {
        guard let payload = UserDefaults.standard.dictionary(forKey: TallaShortcutDestination.pendingReorderKey),
              let name = payload["name"] as? String else { return }
        guard hasLoadedProducts else {
            await loadProducts()
            guard hasLoadedProducts else {
                UserDefaults.standard.removeObject(forKey: TallaShortcutDestination.pendingReorderKey)
                showToast(message: "The catalog is unavailable right now. Please try again shortly.")
                return
            }
            return await handlePendingReorderFromShortcut()
        }
        defer { UserDefaults.standard.removeObject(forKey: TallaShortcutDestination.pendingReorderKey) }

        let productTitle = payload["productTitle"] as? String ?? ""
        let variantID = payload["variantID"] as? String ?? ""
        let quantity = max(1, min(payload["quantity"] as? Int ?? 1, 20))
        let product = products.first(where: { $0.id == productTitle })
            ?? products.first(where: { $0.name.caseInsensitiveCompare(productTitle) == .orderedSame })
            ?? products.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })
        guard let product else {
            showToast(message: "That coffee is no longer available in the catalog.")
            openShop(searchQuery: name)
            return
        }
        let variant = product.variants.first(where: { $0.id == variantID }) ?? product.defaultVariant
        guard let variant, product.isAvailableForSale, variant.isAvailableForSale else {
            showToast(message: "That coffee or size is no longer available.")
            openShop(searchQuery: product.name)
            return
        }
        addShortcutReorderToCart(product: product, variant: variant, quantity: quantity)
        cartOpen = true
        showToast(message: "Added your last coffee to the bag for review.")
    }

    func handleWelcomeChoice(_ choice: WelcomeChoice) {
        hasSeenWelcome = true

        switch choice {
        case .beans:
            openShop(category: "coffee-beans")
        case .drinks:
            openDrinksSection()
        case .gifts:
            openShop(category: "gifts")
        case .concierge:
            openCoffeeConcierge()
        }
    }

    func openCoffeeConcierge() {
        isCoffeeConciergePresented = true
        showToast(message: AppLocalization.text("concierge_opened", fallback: "Coffee Concierge opened"))
    }

    func openDrinksSection() {
        openShop(category: "ready-made-drinks")
        showToast(message: AppLocalization.text("drinks_opened", fallback: "Drinks opened"))
    }

    func handleDeepLink(_ url: URL) {
        if url.scheme?.lowercased() == BenefitPaySDKConfiguration.callbackScheme {
            handleBenefitPayReturn(url)
            return
        }

        let scheme = url.scheme?.lowercased() ?? ""
        let isCustomLink = scheme == "talla"
        let isUniversalLink = ["http", "https"].contains(scheme) && isTallaUniversalLinkHost(url.host)
        guard isCustomLink || isUniversalLink else { return }

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let pathTokens = url.pathComponents.dropFirst().map { $0.lowercased() }
        let rawDestination = isCustomLink
            ? (url.host?.isEmpty == false ? url.host : pathTokens.first)
            : universalLinkDestination(pathTokens: pathTokens)
        let destination = rawDestination?.lowercased() ?? ""

        if isPaymentReturnDestination(destination: destination, pathTokens: pathTokens) {
            handlePaymentReturn(queryItems: queryItems)
            return
        }

        let searchQuery = queryItems.first(where: { $0.name == "q" || $0.name == "search" })?.value ?? ""

        if isUniversalLink, pathTokens.first == "products", let handle = pathTokens.dropFirst().first {
            openProductLink(handle: handle)
            return
        }

        if isUniversalLink, let socialLink = SocialCoffeeSharedLink.parse(url) {
            hasSeenWelcome = true
            switch socialLink {
            case let .group(id, inviteCode):
                socialCoffeeInvite = SocialCoffeeInvite(id: id, inviteCode: inviteCode)
            case let .gift(orderID, token):
                socialCoffeePassGift = SocialCoffeePassGift(orderID: orderID, token: token)
                if let token {
                    TallaGiftVault.save(orderID: orderID, token: token)
                    TallaSpotlightIndexer.reindexStoredGifts()
                }
            }
            return
        }

        if isUniversalLink, pathTokens.first == "collections", let handle = pathTokens.dropFirst().first {
            openShop(category: appCategoryKey(forCollectionHandle: handle), searchQuery: searchQuery)
            return
        }

        let supportedDestinations: Set<String> = [
            "home", "shop", "concierge", "brewing", "shelf", "favorites",
            "rewards", "orders", "order-history", "checkout-return"
        ]
        if isUniversalLink, !supportedDestinations.contains(destination) {
            openURL(url)
            return
        }

        shortcutSearchQuery = searchQuery
        shortcutDestination = destination
        handleShortcutDestination()
    }

    func isTallaUniversalLinkHost(_ host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        return host == "talla.me" || host == "www.talla.me"
    }

    func universalLinkDestination(pathTokens: [String]) -> String {
        guard let first = pathTokens.first else { return "home" }

        if first == "app" {
            return pathTokens.dropFirst().first ?? "home"
        }

        if first == "pages", pathTokens.dropFirst().first == "loyalty-program" {
            return "rewards"
        }

        if first == "blogs", pathTokens.contains("brewing-methods") {
            return "brewing"
        }

        if first == "account", pathTokens.contains("orders") {
            return "orders"
        }

        if first == "search" {
            return "shop"
        }

        return first
    }

    func appCategoryKey(forCollectionHandle handle: String) -> String {
        switch handle {
        case "coffee-beans", "drip-bags":
            return "coffee-beans"
        case "arabic-coffee", "arabic-coffee-beans", "northern-coffee":
            return "arabic-coffee-beans"
        case "cups", "drinkware":
            return "cups"
        case "equipment", "coffee-equipment":
            return "equipment"
        case "gifts", "talla-boxes":
            return "gifts"
        case "ready-made-drinks", "drinks":
            return "ready-made-drinks"
        case "desserts", "crmb":
            return "desserts"
        default:
            return "all"
        }
    }

    func openProductLink(handle: String) {
        hasSeenWelcome = true
        pendingUniversalLinkProductHandle = handle
        openShop(searchQuery: handle.replacingOccurrences(of: "-", with: " "))
        resolvePendingUniversalLinkProduct()
    }

    func resolvePendingUniversalLinkProduct() {
        guard !pendingUniversalLinkProductHandle.isEmpty,
              let product = products.first(where: { $0.handle.caseInsensitiveCompare(pendingUniversalLinkProductHandle) == .orderedSame }) else {
            return
        }

        pendingUniversalLinkProductHandle = ""
        shopSearchQuery = ""
        selectedProduct = product
    }

    func isPaymentReturnDestination(destination: String, pathTokens: [String]) -> Bool {
        if destination == "checkout-return" || destination == "payment-return" {
            return true
        }

        guard destination == "checkout" || destination == "payment" else {
            return false
        }

        return pathTokens.contains("return") || pathTokens.contains("complete")
    }

    func handlePaymentReturn(queryItems: [URLQueryItem]) {
        if !activeEazyShopifyPaymentID.isEmpty {
            checkoutSession = nil
            paymentFlow.transition(to: .processing)
            presentPostPayment()
            Task {
                await waitForEazyShopifyProgress(openHostedCheckout: false)
            }
            return
        }
        if paymentFlow.selectedMethod == .benefit, !postPaymentOrderID.isEmpty {
            checkoutSession = nil
            paymentFlow.transition(to: .processing)
            presentPostPayment()
            Task {
                await waitForBenefitHostedProgress()
            }
            return
        }
        if paymentFlow.selectedMethod == .clickToPay, !postPaymentOrderID.isEmpty {
            paymentFlow.transition(to: .processing)
            checkoutSession = nil
            presentPostPayment()
            Task {
                await waitForClickToPayProgress()
            }
            return
        }
        let status = queryItems.first {
            ["status", "result", "paymentStatus"].contains($0.name)
        }?.value?.lowercased().replacingOccurrences(of: " ", with: "_") ?? ""
        let message = queryItems.first {
            ["message", "error", "reason"].contains($0.name)
        }?.value

        checkoutSession = nil

        switch status {
        case "success", "succeeded", "paid", "captured", "approved":
            cartItems.removeAll()
            requestedSubscriptionPlanType = ""
            appliedVoucher = nil
            voucherCodeInput = ""
            voucherError = nil
            paymentFlow.transition(to: .succeeded)
        case "cancelled", "canceled", "cancel":
            paymentFlow.transition(to: .cancelled)
        case "failed", "failure", "declined", "error", "not_captured":
            paymentFlow.transition(
                to: .failed,
                error: message ?? AppLocalization.text("payment_failed_detail", fallback: "Please check your details or try another payment method.")
            )
        default:
            paymentFlow.transition(to: .processing)
        }
        presentPostPayment()

        Task {
            await loadOrderHistory()
            if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                await loadLoyaltyAccount()
            }
        }
    }

    @MainActor
    func waitForClickToPayProgress() async {
        let orderID = postPaymentOrderID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !orderID.isEmpty else {
            paymentFlow.transition(
                to: .failed,
                error: AppLocalization.text(
                    "payment_verification_unavailable",
                    fallback: "Payment verification is temporarily unavailable."
                )
            )
            return
        }

        for attempt in 0 ..< 20 {
            do {
                let payment = try await TallaPaymentService.retrieveOrder(orderID: orderID)
                let status = payment.status.lowercased()
                if payment.confirmed {
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
                    return
                }
                if status.contains("cancel") {
                    paymentFlow.transition(to: .cancelled)
                    return
                }
                if status.contains("fail") || status.contains("declin") || status.contains("error") {
                    paymentFlow.transition(
                        to: .failed,
                        error: AppLocalization.text(
                            "payment_failed_detail",
                            fallback: "Please check your details or try another payment method."
                        )
                    )
                    return
                }
            } catch {
                if attempt == 19 {
                    checkoutError = customerFacingServiceMessage(
                        for: error,
                        fallback: AppLocalization.text(
                            "payment_verification_unavailable",
                            fallback: "Payment verification is temporarily unavailable."
                        )
                    )
                }
            }

            if attempt < 19 {
                try? await Task.sleep(for: .seconds(1.5))
            }
        }

        isPostPaymentPresented = false
        paymentFlow.reset()
        await loadOrderHistory()
        openAccountSection(AccountSectionView.ScrollTarget.customer)
        showToast(message: AppLocalization.text(
            "payment_verifying",
            fallback: "Payment is still being verified. You can safely return later."
        ))
    }

    @MainActor
    func waitForBenefitHostedProgress() async {
        let orderID = postPaymentOrderID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !orderID.isEmpty else {
            paymentFlow.transition(
                to: .failed,
                error: AppLocalization.text(
                    "payment_verification_unavailable",
                    fallback: "Payment verification is temporarily unavailable."
                )
            )
            return
        }

        for attempt in 0 ..< 20 {
            do {
                let status = try await AccountService.fetchBenefitPaymentStatus(orderID: orderID)
                if status.paid || status.status == "succeeded" {
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
                    return
                }
                if status.status == "cancelled" {
                    paymentFlow.transition(to: .cancelled)
                    return
                }
                if status.status == "failed" {
                    paymentFlow.transition(
                        to: .failed,
                        error: AppLocalization.text(
                            "payment_failed_detail",
                            fallback: "Please check your details or try another payment method."
                        )
                    )
                    return
                }
            } catch {
                if attempt == 19 {
                    checkoutError = customerFacingServiceMessage(
                        for: error,
                        fallback: AppLocalization.text(
                            "payment_verification_unavailable",
                            fallback: "Payment verification is temporarily unavailable."
                        )
                    )
                }
            }

            if attempt < 19 {
                try? await Task.sleep(for: .seconds(1.5))
            }
        }

        isPostPaymentPresented = false
        paymentFlow.reset()
        await loadOrderHistory()
        openAccountSection(AccountSectionView.ScrollTarget.customer)
        showToast(message: AppLocalization.text(
            "payment_verifying",
            fallback: "Payment is still being verified. You can safely return later."
        ))
    }

}
