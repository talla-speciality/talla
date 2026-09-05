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
        defaults.set(Date().timeIntervalSince1970, forKey: AppWidgetSharedState.lastUpdatedKey)

        if reload {
            AppWidgetSharedState.reloadWidget()
        }
    }

}
