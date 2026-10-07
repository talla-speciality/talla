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
    func advanceFeatureTour() {
        if featureTourIndex >= featureTourHighlights.count - 1 {
            dismissFeatureTour()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                featureTourIndex += 1
            }
        }
    }

    func dismissFeatureTour() {
        withAnimation(.easeInOut(duration: 0.22)) {
            hasSeenFeatureTour = true
            featureTourIndex = 0
        }
    }

    var launchSplashView: some View {
        ZStack {
            Group {
                if isLightAppearance {
                    Color.white
                } else {
                    LinearGradient(
                        colors: isOLEDAppearance
                            ? [.black, .black, .black]
                            : [
                                Color(hex: 0x100B07),
                                Color(hex: 0x1A120C),
                                Color(hex: 0x151515)
                            ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .ignoresSafeArea()

            if !isLightAppearance {
                Circle()
                    .fill(TallaTheme.Colors.accent.opacity(0.12))
                    .blur(radius: 90)
                    .frame(width: 240, height: 240)
                    .offset(x: 90, y: -160)
            }

            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: isCompact ? 132 : 168, height: isCompact ? 132 : 168)
                .accessibilityLabel(AppLocalization.text("talla_logo", fallback: "Talla Speciality"))
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("launch.splash")
    }

    @MainActor
    func runInitialLaunchSequence() async {
        let startTime = Date()

        restoreSyncedCustomerCredential()

        let minimumSplashDuration: TimeInterval = 1.25
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < minimumSplashDuration {
            do {
                try await Task.sleep(nanoseconds: UInt64((minimumSplashDuration - elapsed) * 1_000_000_000))
            } catch {
                return
            }
        }
        guard !Task.isCancelled else { return }

        withAnimation(.easeInOut(duration: 0.28)) {
            showLaunchSplash = false
        }

        recordLaunchAndRequestReviewIfReady()
        handleShortcutDestination()

        // Network bootstrap is deliberately performed after the splash is
        // dismissed. Storefront, notification, and account services are
        // optional at launch and must never prevent the local UI from opening.
        async let bootstrapTask: Void = loadProductsIfNeeded()
        async let notificationTask: Void = refreshNotificationStatus()
        await bootstrapTask
        await notificationTask
        guard !Task.isCancelled else { return }
        await syncRemotePushTokenIfPossible()
    }

    func recordLaunchAndRequestReviewIfReady() {
        guard !didRecordReviewLaunch else { return }
        didRecordReviewLaunch = true
        reviewLaunchCount += 1

        guard hasSeenWelcome else { return }
        guard reviewLaunchCount >= 4 else { return }
        guard reviewPromptedVersion != currentAppVersion else { return }

        let now = Date().timeIntervalSince1970
        let minimumPromptInterval: TimeInterval = 60 * 60 * 24 * 60
        guard reviewLastPromptAt == 0 || now - reviewLastPromptAt > minimumPromptInterval else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            guard hasSeenWelcome,
                  !cartOpen,
                  checkoutSession == nil,
                  articleSession == nil,
                  selectedProduct == nil,
                  toastMessage == nil else {
                return
            }

            requestReview()
            reviewLastPromptAt = Date().timeIntervalSince1970
            reviewPromptedVersion = currentAppVersion
        }
    }

    var appearanceMode: AppearanceMode {
        get { AppearanceMode(rawValue: savedAppearanceMode) ?? .system }
        set { savedAppearanceMode = newValue.rawValue }
    }

    var appLanguage: AppLanguage {
        AppLanguage(rawValue: savedAppLanguage) ?? .system
    }

    var isArabicInterface: Bool {
        appLanguage.layoutDirection == .rightToLeft
    }

    var paymentAvailability: TallaPaymentAvailability {
        guard let payments = remoteAppSettings?.payments else { return TallaPaymentAvailability() }
        return TallaPaymentAvailability(
            applePayEnabled: payments.applePayEnabled,
            benefitPayEnabled: payments.benefitPayEnabled,
            benefitEnabled: payments.benefitEnabled,
            cardEnabled: payments.cardEnabled,
            clickToPayEnabled: payments.clickToPayEnabled ?? payments.cardEnabled,
            cashOnDeliveryEnabled: payments.cashOnDeliveryEnabled
        )
    }

    var shippingConfiguration: TallaShippingConfiguration {
        guard let fulfillment = remoteAppSettings?.fulfillment else { return TallaShippingConfiguration() }
        return TallaShippingConfiguration(
            bahrainRate: fulfillment.bahrainRate,
            khaleejiCashOnDeliverySurcharge: fulfillment.khaleejiCashOnDeliverySurcharge,
            maximumKhaleejiWeightGrams: fulfillment.maximumKhaleejiWeightGrams,
            khaleejiTransitTime: isArabicInterface ? fulfillment.khaleejiTransitAR : fulfillment.khaleejiTransitEN,
            khaleejiTiers: fulfillment.khaleejiTiers.map {
                TallaShippingConfiguration.Tier(maximumWeightGrams: $0.maximumWeightGrams, rate: $0.rate)
            }
        )
    }

    var managedPickupName: String {
        guard let fulfillment = remoteAppSettings?.fulfillment else {
            return AppLocalization.text("pickup_location_short", fallback: "Talla, Riffa")
        }
        if let location = fulfillment.locations?.first(where: { $0.id == selectedPickupLocationID }) ?? fulfillment.locations?.first {
            return isArabicInterface ? location.nameAR : location.nameEN
        }
        return isArabicInterface ? fulfillment.pickupNameAR : fulfillment.pickupNameEN
    }

    var managedPickupAddress: String {
        guard let fulfillment = remoteAppSettings?.fulfillment else {
            return AppLocalization.text("pickup_address", fallback: "Villa 336, Street 1307, Riffa 913")
        }
        if let location = fulfillment.locations?.first(where: { $0.id == selectedPickupLocationID }) ?? fulfillment.locations?.first {
            return isArabicInterface ? location.addressAR : location.addressEN
        }
        return isArabicInterface ? fulfillment.pickupAddressAR : fulfillment.pickupAddressEN
    }

    func version(_ lhs: String, isOlderThan rhs: String) -> Bool {
        let left = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let right = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(left.count, right.count) {
            let leftPart = index < left.count ? left[index] : 0
            let rightPart = index < right.count ? right[index] : 0
            if leftPart != rightPart { return leftPart < rightPart }
        }
        return false
    }

    var requiresAppUpdate: Bool {
        guard let minimum = remoteAppSettings?.release?.minimumSupportedVersion,
              !minimum.isEmpty else { return false }
        return version(currentAppVersion, isOlderThan: minimum)
    }

    var blocksApplicationUse: Bool {
        remoteAppSettings?.release?.maintenanceEnabled == true || requiresAppUpdate
    }

    var hasOptionalAppUpdate: Bool {
        guard !requiresAppUpdate,
              let latest = remoteAppSettings?.release?.latestVersion,
              !latest.isEmpty else { return false }
        return version(currentAppVersion, isOlderThan: latest)
    }
}
