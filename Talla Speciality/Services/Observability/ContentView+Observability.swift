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
    @MainActor
    func configureReleaseUITestScenarioIfNeeded() -> Bool {
#if DEBUG
        guard !didConfigureReleaseUITest,
              let scenario = ProcessInfo.processInfo.environment["TALLA_UI_TEST_SCENARIO"],
              !scenario.isEmpty else { return false }
        // Exercise the real launch sequence while the UI-test service keeps
        // every response open. This scenario verifies that network bootstrap
        // can never hold the splash screen.
        if scenario == "startup-network-stall" { return false }
        didConfigureReleaseUITest = true
        hasSeenWelcome = true
        hasSeenFeatureTour = true
        showLaunchSplash = false
        loadingError = nil
        hasLoadedProducts = true
        savedAppLanguage = scenario == "arabic" ? AppLanguage.arabic.rawValue : AppLanguage.english.rawValue

        let testEmail = "release-test@talla.test"
        savedCustomerEmail = testEmail
        savedCustomerAccessToken = "ui-test-access-token"
        TallaAccountCredentialStore.save(
            accessToken: savedCustomerAccessToken,
            refreshToken: "ui-test-refresh-token"
        )

        switch scenario {
        case "checkout", "arabic", "layout", "coffee-club-intro":
            let variant = Product.Variant(
                id: "gid://shopify/ProductVariant/release-test", title: "Default", price: "8.500",
                isAvailableForSale: true, requiresShipping: false, weightGrams: 250
            )
            let product = Product(
                id: "gid://shopify/Product/release-test", handle: "release-test-coffee",
                variantID: variant.id, variants: [variant], name: "Release Test Coffee", price: "8.500",
                categoryKey: "coffee-beans", categoryLabel: "Coffee Beans", imageURL: nil,
                desc: "Deterministic checkout fixture", tag: nil, countryOfOrigin: "Bahrain", isAvailableForSale: true
            )
            products = [product]
            cartItems = [CartItem(id: variant.id, product: product, variant: variant, quantity: 1)]
            fulfillmentMethod = .pickup
            paymentFlow.select(.benefit)
            customerProfile = ShopifyCustomerProfile(
                id: "release-test-customer", firstName: "Release", lastName: "Test", email: testEmail
            )
            isCheckoutPresented = scenario == "checkout" || scenario == "arabic"
            if scenario == "layout" {
                // Apply navigation after the tab hierarchy mounts so persisted state
                // cannot win the initial selection race.
                DispatchQueue.main.async {
                    activeTab = .home
                    tabScrollTarget = .home
                }
            }
            if scenario == "coffee-club-intro" {
                let settingsJSON = #"{"announcement":{"enabled":false,"title":"","message":"","actionLabel":"","actionURL":""},"support":{"whatsappURL":"","privacyURL":"","termsURL":""},"homeSections":{"showQuickDrinks":true,"showFunPick":true,"showSignatureRoasts":true,"showPassport":true},"coffeeClub":{"enabled":true,"shipmentCount":3,"intervalWeeks":4,"discountPercent":10}}"#
                remoteAppSettings = try? JSONDecoder().decode(AppSettings.self, from: Data(settingsJSON.utf8))
                DispatchQueue.main.async {
                    activeTab = .shop
                }
            }
        case "account-deletion":
            customerProfile = ShopifyCustomerProfile(
                id: "release-test-customer", firstName: "Release", lastName: "Test", email: testEmail
            )
            DispatchQueue.main.async {
                activeTab = .more
                isAccountPresentedFromMore = true
            }
        case "account-orders-replay":
            customerProfile = ShopifyCustomerProfile(
                id: "release-test-customer", firstName: "Release", lastName: "Test", email: testEmail
            )
            DispatchQueue.main.async {
                activeTab = .more
                isAccountPresentedFromMore = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                accountOrdersPresentationRequest = 1
            }
        case "offline-recovery", "bluetooth-interruption":
            DispatchQueue.main.async {
                activeTab = .brewing
            }
        default:
            break
        }
        return true
#else
        return false
#endif
    }

    @MainActor
    func refreshNotificationStatus() async {
#if canImport(UserNotifications)
        let status = await ProductAlertNotificationService.authorizationStatus()
        notificationAuthorizationStatus = status.rawValue
        if status == .authorized || status == .provisional || status == .ephemeral {
            registerForRemoteNotifications()
        }
#endif
    }

    @MainActor
    func requestNotificationAccess() async {
        let granted = await ProductAlertNotificationService.requestAuthorization()
        await refreshNotificationStatus()

        if granted {
            registerForRemoteNotifications()
            await syncRemotePushTokenIfPossible()
            showToast(message: AppLocalization.text("notifications_enabled", fallback: "Notifications enabled"))
        } else {
            showToast(message: AppLocalization.text("notifications_not_enabled", fallback: "Notifications not enabled"))
        }
    }

    @MainActor
    func requestNotificationAccessIfNeeded() async -> Bool {
#if canImport(UserNotifications)
        let status = await ProductAlertNotificationService.authorizationStatus()
        notificationAuthorizationStatus = status.rawValue

        switch status {
        case .authorized, .provisional, .ephemeral:
            registerForRemoteNotifications()
            await syncRemotePushTokenIfPossible()
            return true
        case .notDetermined:
            let granted = await ProductAlertNotificationService.requestAuthorization()
            await refreshNotificationStatus()
            if granted {
                registerForRemoteNotifications()
                await syncRemotePushTokenIfPossible()
            }
            return granted
        default:
            return false
        }
#else
        return false
#endif
    }

    @MainActor
    func registerForRemoteNotifications() {
#if canImport(UIKit)
        UIApplication.shared.registerForRemoteNotifications()
#endif
    }

    @MainActor
    func unregisterRemoteNotifications() {
#if canImport(UIKit)
        UIApplication.shared.unregisterForRemoteNotifications()
#endif
    }

    func copyPushDeviceToken() {
        let token = savedPushDeviceToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            showToast(message: AppLocalization.text("push_token_waiting", fallback: "No APNs device token yet. Enable notifications on a real device to create one."))
            return
        }

#if canImport(UIKit)
        UIPasteboard.general.string = token
        showToast(message: AppLocalization.text("device_token_copied", fallback: "Device token copied"))
#else
        showToast(message: token)
#endif
    }

    @MainActor
    func syncRemotePushTokenIfPossible() async {
        let normalizedToken = savedPushDeviceToken
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalizedToken.isEmpty else { return }

        let status = notificationAuthorizationStatus
        let notificationsEnabled = status == UNAuthorizationStatus.authorized.rawValue
            || status == UNAuthorizationStatus.provisional.rawValue
            || status == UNAuthorizationStatus.ephemeral.rawValue
        guard notificationsEnabled else { return }

        let email = (customerProfile?.email ?? savedCustomerEmail)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !email.isEmpty else { return }

        if savedRegisteredPushDeviceEmail == email && savedRegisteredPushDeviceToken == normalizedToken {
            return
        }

        do {
            try await AccountService.registerPushDeviceToken(email: email, deviceToken: normalizedToken)
            savedRegisteredPushDeviceEmail = email
            savedRegisteredPushDeviceToken = normalizedToken
        } catch {
            return
        }
    }

    func unregisterRemotePushToken(email: String?, accessToken: String) {
        let normalizedToken = savedPushDeviceToken
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let normalizedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !normalizedToken.isEmpty, !normalizedEmail.isEmpty, !accessToken.isEmpty else { return }

        Task {
            try? await AccountService.unregisterPushDeviceToken(
                email: normalizedEmail,
                deviceToken: normalizedToken,
                accessTokenOverride: accessToken
            )
        }
    }

    func syncWidgetSharedState(reload: Bool) {
        let defaults = AppWidgetSharedState.defaults
        defaults.set(savedLoyaltyEmail, forKey: AppWidgetSharedState.loyaltyEmailKey)
        defaults.set(savedFavoriteProductIDs, forKey: AppWidgetSharedState.favoriteProductIDsKey)
        defaults.set(savedRecentlyViewedProductIDs, forKey: AppWidgetSharedState.recentlyViewedProductIDsKey)
        defaults.set(savedCartsPayload, forKey: AppWidgetSharedState.savedCartsKey)
        defaults.set(favoriteProductIDs.count, forKey: AppWidgetSharedState.favoriteCountKey)
        defaults.set(recentlyViewedProductIDs.count, forKey: AppWidgetSharedState.recentCountKey)
        defaults.set(savedCarts.count, forKey: AppWidgetSharedState.savedCartCountKey)
        defaults.set(appLanguage.effectiveLanguageCode, forKey: AppWidgetSharedState.languageKey)
        defaults.set(loyaltyAccount?.pointsBalance ?? 0, forKey: AppWidgetSharedState.loyaltyPointsKey)
        defaults.set(loyaltyAccount?.tier ?? "Bronze", forKey: AppWidgetSharedState.loyaltyTierKey)
        defaults.set(loyaltyAccount?.nextReward ?? "Check rewards in app", forKey: AppWidgetSharedState.loyaltyNextRewardKey)
        defaults.set(loyaltyAccount?.memberID ?? "", forKey: AppWidgetSharedState.loyaltyMemberIDKey)

        let formatter = ISO8601DateFormatter()
        let activeGift = orderHistory.first { order in
            guard let pass = order.details?.cafePass, pass.giftedCoffee == true,
                  pass.remainingCredits > 0, pass.status.lowercased() == "active" else { return false }
            return pass.expiresAt.flatMap(formatter.date).map { $0 > Date() } ?? true
        }?.details?.cafePass
        if let activeGift {
            defaults.set(activeGift.drinkName, forKey: AppWidgetSharedState.activeGiftNameKey)
            if let expiry = activeGift.expiresAt { defaults.set(expiry, forKey: AppWidgetSharedState.activeGiftExpiryKey) }
        } else {
            defaults.removeObject(forKey: AppWidgetSharedState.activeGiftNameKey)
            defaults.removeObject(forKey: AppWidgetSharedState.activeGiftExpiryKey)
        }

        let activeOrder = orderHistory.first { order in
            !["completed", "fulfilled", "delivered", "cancelled", "canceled", "refunded"].contains(order.status.lowercased())
        }
        if let activeOrder {
            defaults.set(activeOrder.status, forKey: AppWidgetSharedState.orderStatusKey)
            defaults.set(activeOrder.isPickup, forKey: AppWidgetSharedState.orderIsPickupKey)
#if canImport(ActivityKit)
            if #available(iOS 16.1, *) {
                TallaCommerceLiveActivityCoordinator.shared.syncOrder(
                    id: activeOrder.id,
                    title: activeOrder.title,
                    status: activeOrder.status,
                    isPickup: activeOrder.isPickup,
                    languageCode: appLanguage.effectiveLanguageCode
                )
            }
#endif
        } else {
            defaults.removeObject(forKey: AppWidgetSharedState.orderStatusKey)
            defaults.removeObject(forKey: AppWidgetSharedState.orderIsPickupKey)
#if canImport(ActivityKit)
            if #available(iOS 16.1, *) {
                if let activeGift {
                    let expiry = activeGift.expiresAt.flatMap(formatter.date)
                    TallaCommerceLiveActivityCoordinator.shared.startGift(
                        id: activeGift.giftToken ?? activeGift.drinkName,
                        title: activeGift.drinkName,
                        expiry: expiry,
                        languageCode: appLanguage.effectiveLanguageCode
                    )
                } else if let groupName = defaults.string(forKey: AppWidgetSharedState.groupOrderNameKey) {
                    let deadline = defaults.string(forKey: AppWidgetSharedState.groupOrderDeadlineKey).flatMap(formatter.date)
                    TallaCommerceLiveActivityCoordinator.shared.startGroupOrder(
                        id: groupName,
                        title: groupName,
                        deadline: deadline,
                        participantCount: defaults.integer(forKey: AppWidgetSharedState.groupOrderParticipantCountKey),
                        languageCode: appLanguage.effectiveLanguageCode
                    )
                } else {
                    TallaCommerceLiveActivityCoordinator.shared.endOrder()
                }
            }
#endif
        }
        defaults.set(Date().timeIntervalSince1970, forKey: AppWidgetSharedState.lastUpdatedKey)

        if reload {
            AppWidgetSharedState.reloadWidget()
        }
    }

}
