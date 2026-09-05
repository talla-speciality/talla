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
    var latestAccountOrderSummary: (title: String, detail: String)? {
        guard let order = orderHistory.max(by: { orderDate(from: $0.createdAt) < orderDate(from: $1.createdAt) }) else {
            return nil
        }

        let digits = [order.title, order.id]
            .map { $0.filter(\.isNumber) }
            .first(where: { !$0.isEmpty }) ?? String(order.id.prefix(6))
        let orderNumber = String(format: AppLocalization.text("order_number_format", fallback: "Order #%@"), String(digits.suffix(6)))
        let daysAgo = daysSinceOrder(order)
        let timing = daysAgo == 0
            ? AppLocalization.text("ordered_today", fallback: "Ordered today")
            : String(format: AppLocalization.text("last_ordered_days_ago", fallback: "Last ordered %d days ago"), daysAgo)

        return (orderNumber, "\(order.total) · \(timing)")
    }

    var recentlySavedAccountSummary: (title: String, detail: String)? {
        guard let product = favoriteProducts.first else {
            return nil
        }

        return (customerFacingProductName(for: product), product.price)
    }

    var accountView: some View {
        AccountSectionView(
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: Color(hex: 0xC8965A),
            isLightAppearance: isLightAppearance,
            isOLEDAppearance: isOLEDAppearance,
            titleFont: displayFont(size: 32),
            introFont: bodyFont(size: 17),
            bodyFont: bodyFont(size: 14),
            labelFont: labelFont(size: 10, weight: .semibold),
            sectionTitleFont: displayFont(size: 22),
            sectionBodyFont: bodyFont(size: 14),
            quickActionTitleFont: labelFont(size: 11, weight: .bold),
            quickActionBodyFont: bodyFont(size: 13),
            isCustomerSignedIn: customerProfile != nil,
            accountDisplayName: customerProfile?.displayName ?? AppLocalization.text("guest_account_name", fallback: "Talla Speciality"),
            accountEmail: customerProfile?.email ?? savedCustomerEmail,
            membershipTier: loyaltyAccount?.tier ?? AppLocalization.text("bronze", fallback: "Bronze"),
            beansBalance: loyaltyAccount?.pointsBalance ?? 0,
            beansUntilNextReward: loyaltyAccount.map { rewardProgress(for: $0.pointsBalance).remaining } ?? 50,
            orderCount: orderHistory.count,
            addressesCount: addresses.count,
            favoriteCount: favoriteProducts.count,
            brewRecipeCount: brewRecipes.count,
            journalEntryCount: brewJournalEntries.count,
            latestOrderTitle: latestAccountOrderSummary?.title,
            latestOrderDetail: latestAccountOrderSummary?.detail,
            recentlySavedTitle: recentlySavedAccountSummary?.title,
            recentlySavedDetail: recentlySavedAccountSummary?.detail,
            isCustomerSectionExpanded: $isCustomerSectionExpanded,
            isLoyaltySectionExpanded: $isLoyaltySectionExpanded,
            isLibrarySectionExpanded: $isLibrarySectionExpanded,
            isShoppingSectionExpanded: $isShoppingSectionExpanded,
            isBrewingSectionExpanded: $isBrewingSectionExpanded,
            isSupportSectionExpanded: $isSupportSectionExpanded,
            ordersPresentationRequest: accountOrdersPresentationRequest,
            openOrdersAction: {
                Task {
                    await loadOrderHistory()
                }
            },
            signOutAction: {
                signOutCustomer()
            },
            customerAccountSection: AnyView(customerAccountSection),
            personalDetailsSection: AnyView(profileManagementSection),
            passwordSection: AnyView(passwordResetSection),
            ordersSection: AnyView(orderHistorySection),
            loyaltySection: AnyView(loyaltySection),
            addressesSection: AnyView(addressesSection),
            savedCartsSection: AnyView(savedCartsSection),
            alertsSection: AnyView(alertsSection),
            favoritesSection: AnyView(favoritesSection),
            recentlyViewedSection: AnyView(recentlyViewedSection),
            savedRecipesSection: AnyView(brewRecipesSection),
            journalSection: AnyView(coffeeJournalSection),
            deleteAccountSection: AnyView(deleteAccountSettingsCard),
            supportSection: AnyView(settingsAndHelpSection)
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 28)
    }

    var languagePreferenceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
                    .frame(width: 34, height: 34)
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("language", fallback: "Language"))
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(primaryTextColor)

                    Text(AppLocalization.text("language_preference_detail", fallback: "Choose how the app labels and layout appear."))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                ForEach(AppLanguage.allCases) { language in
                    languageOptionButton(language)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    var settingsAndHelpSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalization.text("settings_and_help", fallback: "SETTINGS & HELP"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            VStack(spacing: 0) {
                settingsRow(
                    title: AppLocalization.text("language", fallback: "Language"),
                    value: currentLanguageTitle,
                    systemImage: "globe"
                ) {
                    selectedSettingsDetail = .language
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("notifications", fallback: "Notifications"),
                    value: notificationsEnabled
                        ? AppLocalization.text("on", fallback: "On")
                        : AppLocalization.text("off", fallback: "Off"),
                    systemImage: "bell.fill"
                ) {
                    selectedSettingsDetail = .notifications
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("whatsapp_support", fallback: "WhatsApp Support"),
                    systemImage: "message.fill"
                ) {
                    openURL(managedWhatsAppURL)
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("about_talla", fallback: "About Talla"),
                    systemImage: "info.circle.fill"
                ) {
                    selectedSettingsDetail = .aboutTalla
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("privacy_policy", fallback: "Privacy Policy"),
                    systemImage: "hand.raised.fill"
                ) {
                    openURL(managedPrivacyURL)
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("terms_and_conditions", fallback: "Terms and Conditions"),
                    systemImage: "doc.text.fill"
                ) {
                    openURL(managedTermsURL)
                }

                settingsDivider

                settingsRow(
                    title: AppLocalization.text("delete_account", fallback: "Delete Account"),
                    systemImage: "trash.fill",
                    isDestructive: true
                ) {
                    selectedSettingsDetail = .deleteAccount
                }
            }
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .sheet(item: $selectedSettingsDetail) { detail in
            settingsDetailScreen(detail)
        }
    }

    var currentLanguageTitle: String {
        (AppLanguage(rawValue: savedAppLanguage) ?? .system).title
    }

    var settingsDivider: some View {
        Rectangle()
            .fill(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.10 : 0.06))
            .frame(height: 1)
            .padding(.leading, 54)
    }

    func settingsRow(
        title: String,
        value: String? = nil,
        systemImage: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isDestructive ? .red : Color(hex: 0xC8965A))
                    .frame(width: 34, height: 34)
                    .background((isDestructive ? Color.red : Color(hex: 0xC8965A)).opacity(isLightAppearance ? 0.10 : 0.14))
                    .clipShape(Circle())

                Text(title)
                    .font(labelFont(size: 12, weight: .bold))
                    .foregroundColor(isDestructive ? .red : primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 8)

                if let value {
                    Text(value)
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(tertiaryTextColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func settingsDetailScreen(_ detail: SettingsDetail) -> some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                settingsDetailContent(detail)
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(pageBackgroundColor)
            .navigationTitle(settingsDetailTitle(detail))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedSettingsDetail = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 32, height: 32)
                            .background(cardFillColor)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.16 : 0.10), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))
                }
            }
        }
    }

    func settingsDetailTitle(_ detail: SettingsDetail) -> String {
        switch detail {
        case .language:
            return AppLocalization.text("language", fallback: "Language")
        case .notifications:
            return AppLocalization.text("notifications", fallback: "Notifications")
        case .aboutTalla:
            return AppLocalization.text("about_talla", fallback: "About Talla")
        case .deleteAccount:
            return AppLocalization.text("delete_account", fallback: "Delete Account")
        }
    }

    @ViewBuilder
    func settingsDetailContent(_ detail: SettingsDetail) -> some View {
        switch detail {
        case .language:
            languagePreferenceCard
        case .notifications:
            notificationSettingsCard
        case .aboutTalla:
            accountStatusTile(
                title: AppLocalization.text("about_talla", fallback: "About Talla"),
                detail: AppLocalization.text("about_talla_detail", fallback: "Speciality coffee, rewards, and roastery essentials built around daily rituals in Bahrain.")
            )
        case .deleteAccount:
            deleteAccountSettingsCard
        }
    }

    var notificationSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(notificationStatusMessage)
                .font(bodyFont(size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                if notificationAccessDenied {
                    openNotificationSettings()
                } else {
                    Task {
                        await requestNotificationAccess()
                    }
                }
            } label: {
                Text(notificationsEnabled
                    ? AppLocalization.text("notifications_enabled", fallback: "Notifications enabled")
                    : (notificationAccessDenied
                        ? AppLocalization.text("open_settings", fallback: "Open Settings")
                        : AppLocalization.text("enable_notifications", fallback: "Enable Notifications")))
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canManageNotificationAccess)
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func openNotificationSettings() {
#if canImport(UIKit)
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(settingsURL)
#endif
    }

    var deleteAccountSettingsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(customerProfile == nil
                ? AppLocalization.text("delete_account_sign_in_detail", fallback: "Sign in to the account you want to delete.")
                : AppLocalization.text("delete_account_detail", fallback: "Permanently delete your Talla account and associated customer data. This action cannot be undone."))
                .font(bodyFont(size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                accountDeletionError = nil
                isDeleteConfirmationPresented = true
            } label: {
                HStack(spacing: 8) {
                    if isDeletingAccount {
                        ProgressView()
                            .tint(.white)
                    }

                    Text(AppLocalization.text("delete_account_permanently", fallback: "Delete Account Permanently"))
                }
                .font(labelFont(size: 11, weight: .bold))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.86))
                .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("account.delete")
            .disabled(customerProfile == nil || isDeletingAccount)

            if let accountDeletionError {
                Text(accountDeletionError)
                    .font(bodyFont(size: 13))
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.red.opacity(isLightAppearance ? 0.18 : 0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .alert(
            AppLocalization.text("delete_account_confirmation_title", fallback: "Delete Account Permanently?"),
            isPresented: $isDeleteConfirmationPresented
        ) {
            Button(AppLocalization.text("cancel", fallback: "Cancel"), role: .cancel) {}
            Button(AppLocalization.text("delete_account", fallback: "Delete Account"), role: .destructive) {
                Task {
                    await deleteCustomerAccount()
                }
            }
        } message: {
            Text(AppLocalization.text(
                "delete_account_confirmation_detail",
                fallback: "Your profile, loyalty data, saved addresses, alerts, vouchers, and order records will be permanently deleted."
            ))
        }
    }

    @MainActor
    func deleteCustomerAccount() async {
        guard customerProfile != nil, !isDeletingAccount else { return }

        isDeletingAccount = true
        accountDeletionError = nil
        defer { isDeletingAccount = false }

        do {
            try await AccountService.deleteAccount()
            signOutCustomer(clearError: false, unregisterBackend: false)
            savedLoyaltyEmail = ""
            loyaltyEmail = ""
            loyaltyAccount = nil
            savedFavoriteProductIDs = ""
            savedRecentlyViewedProductIDs = ""
            savedRecentSearchQueries = ""
            savedAlertProductIDs = ""
            try? coffeeData.removeAllLocalCoffeeData()
            savedTasteMemory = ""
            savedCartsPayload = ""
            selectedSettingsDetail = nil
            showToast(message: AppLocalization.text("account_deleted", fallback: "Your account has been deleted."))
        } catch {
            accountDeletionError = friendlyCustomerAuthMessage(
                for: error,
                fallback: AppLocalization.text("account_delete_failed", fallback: "Your account could not be deleted right now. Please try again.")
            )
        }
    }

    func languageOptionButton(_ language: AppLanguage) -> some View {
        let isSelected = (AppLanguage(rawValue: savedAppLanguage) ?? .system) == language

        return Button {
            savedAppLanguage = language.rawValue
        } label: {
            Text(language.title)
                .font(labelFont(size: 10, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color(hex: 0xC8965A) : cardFillColor)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color(hex: 0xC8965A).opacity(isSelected ? 0 : 0.18), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("language.option.\(language.rawValue)")
    }

    var accountWorkspaceColumns: [GridItem] {
        if isCompact {
            [GridItem(.flexible(), spacing: 0)]
        } else {
            [
                GridItem(.flexible(), spacing: 14),
                GridItem(.flexible(), spacing: 14)
            ]
        }
    }

    func accountWorkspaceCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        SectionCardView(
            backgroundColor: cardFillColor,
            strokeColor: Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08)
        ) {
            content()
        }
    }

    func actionEmptyState(
        message: String,
        actionTitle: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
                    .frame(width: 34, height: 34)
                    .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                Text(message)
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: action) {
                Text(actionTitle)
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("favorites", fallback: "FAVORITES"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if favoriteProducts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("favorites_empty", fallback: "Tap the heart on any coffee or gift to save it here."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "heart.fill"
                ) {
                    openShop()
                }
            } else {
                accountCompactProductSection(
                    products: Array(favoriteProducts.prefix(3)),
                    viewAllTitle: AppLocalization.text("view_all_saved_products", fallback: "View all saved products")
                )
            }
        }
    }

    var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("recommended_for_you", fallback: "RECOMMENDED FOR YOU"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if recommendedProducts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("recommendations_empty", fallback: "Recommendations will appear here once products are loaded."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "sparkles"
                ) {
                    openShop()
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalization.text("recommendations_detail", fallback: "Picked from the coffees, tools, and categories you keep coming back to."))
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    LazyVGrid(columns: productGridColumns, spacing: 16) {
                        ForEach(recommendedProducts) { product in
                            productCard(product: product, showDescription: false)
                        }
                    }
                }
            }
        }
    }

    var alertsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("back_in_stock_reminders", fallback: "BACK IN STOCK REMINDERS"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if alertProducts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("alerts_empty", fallback: "Tap Notify when available on a sold-out product and Talla will let you know when it returns."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "bell.fill"
                ) {
                    openShop()
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text(AppLocalization.text("alerts_detail", fallback: "Talla checks real availability changes and notifies you when a saved product returns."))
                        .font(bodyFont(size: 14))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    if !alertInbox.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(AppLocalization.text("recent_alert_updates", fallback: "Recent Alert Updates"))
                                .font(labelFont(size: 10, weight: .bold))
                                .tracking(1.6)
                                .textCase(.uppercase)
                                .foregroundColor(readableBrandGoldColor)

                            ForEach(alertInbox.prefix(2)) { update in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(update.title)
                                        .font(titleFont(size: 16))
                                        .foregroundColor(primaryTextColor)
                                    Text(update.detail)
                                        .font(bodyFont(size: 13))
                                        .foregroundColor(secondaryTextColor)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(cardFillColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                    }

                    ForEach(alertProducts.prefix(6)) { product in
                        HStack(alignment: .center, spacing: 12) {
                            ProductThumbnail(imageURL: product.imageURL, size: 68, cornerRadius: 14)

                            VStack(alignment: .leading, spacing: 6) {
                                Text(product.name)
                                    .font(titleFont(size: 18))
                                    .foregroundColor(primaryTextColor)
                                    .lineLimit(2)

                                Text(stockAlertLabel(for: product))
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(1.6)
                                    .textCase(.uppercase)
                                    .foregroundColor(readableBrandGoldColor)
                            }

                            Spacer(minLength: 0)

                            Button {
                                Task {
                                    await toggleAlert(product: product)
                                }
                            } label: {
                                Image(systemName: "bell.slash")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(primaryTextColor)
                                    .frame(width: 36, height: 36)
                                    .background(cardFillColor)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    var deliveryCountrySelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("delivery_country", fallback: "Delivery country"))
                .font(labelFont(size: 10, weight: .bold))
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)

            Picker(
                AppLocalization.text("delivery_country", fallback: "Delivery country"),
                selection: $addressCountry
            ) {
                ForEach(SupportedDeliveryCountry.allCases) { country in
                    Text("\(country.flag)  \(country.name)")
                        .tag(country)
                }
            }
            .pickerStyle(.menu)
            .tint(readableBrandGoldColor)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: 0xC8965A).opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var accountOnboardingView: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppLocalization.text("complete_your_profile", fallback: "COMPLETE YOUR PROFILE"))
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(2.4)
                            .foregroundColor(readableBrandGoldColor)

                        Text(AppLocalization.text("where_should_we_deliver", fallback: "Where should we deliver?"))
                            .font(displayFont(size: isCompact ? 32 : 38))
                            .foregroundColor(primaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(AppLocalization.text("profile_onboarding_detail", fallback: "Add your phone number and preferred address once. Talla will use them automatically for faster checkout."))
                            .font(bodyFont(size: 15))
                            .foregroundColor(secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        onboardingTextField(
                            AppLocalization.text("full_name", fallback: "Full name"),
                            text: $addressFullName,
                            capitalization: .words
                        )

                        HStack(spacing: 10) {
                            if !addressCountry.phonePrefix.isEmpty {
                                Text(addressCountry.phonePrefix)
                                    .font(labelFont(size: 12, weight: .bold))
                                    .foregroundColor(readableBrandGoldColor)
                            }

                            TextField(
                                addressCountry.phonePrefix.isEmpty
                                    ? AppLocalization.text("phone_with_country_code", fallback: "Phone with +country code")
                                    : AppLocalization.text("phone_number", fallback: "Phone number"),
                                text: $addressPhone
                            )
                                .keyboardType(.phonePad)
                                .font(bodyFont(size: 15))
                                .foregroundColor(primaryTextColor)
                        }
                        .padding(.horizontal, 16)
                        .frame(minHeight: 52)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(Color(hex: 0xC8965A).opacity(0.16), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

                        onboardingTextField(
                            AppLocalization.text("address_line", fallback: "Building, road and block"),
                            text: $addressLine1,
                            capitalization: .words
                        )

                        onboardingTextField(
                            AppLocalization.text("city", fallback: "City / area"),
                            text: $addressCity,
                            capitalization: .words
                        )

                        deliveryCountrySelector

                        onboardingTextField(
                            AppLocalization.text("delivery_notes_optional", fallback: "Delivery notes (optional)"),
                            text: $addressNotes,
                            capitalization: .sentences
                        )
                    }

                    Button {
                        Task {
                            await saveAddress(closeOnboarding: true)
                        }
                    } label: {
                        HStack(spacing: 9) {
                            if isSavingAddress {
                                ProgressView()
                                    .tint(Color(hex: 0x0A0804))
                            }
                            Text(isSavingAddress
                                ? AppLocalization.text("saving", fallback: "Saving...")
                                : AppLocalization.text("save_and_continue", fallback: "Save & Continue"))
                                .font(labelFont(size: 11, weight: .bold))
                                .tracking(1.8)
                                .textCase(.uppercase)
                        }
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color(hex: 0xC8965A))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isSavingAddress)

                    Button {
                        isAccountOnboardingPresented = false
                        signOutCustomer()
                    } label: {
                        Text(AppLocalization.text("sign_out", fallback: "Sign out"))
                            .font(bodyFont(size: 13))
                            .foregroundColor(secondaryTextColor)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 620, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 34)
                .padding(.bottom, 44)
            }
            .background(pageBackgroundColor.ignoresSafeArea())
        }
    }

    func onboardingTextField(
        _ title: String,
        text: Binding<String>,
        capitalization: TextInputAutocapitalization
    ) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(capitalization)
            .font(bodyFont(size: 15))
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Color(hex: 0xC8965A).opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    var addressesSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppLocalization.text("delivery_details", fallback: "DELIVERY DETAILS"))
                    .font(displayFont(size: 22))
                    .tracking(2)
                    .foregroundColor(primaryTextColor)

                Text(addresses.isEmpty
                    ? AppLocalization.text("delivery_details_empty", fallback: "Add an address for faster checkout.")
                    : (addresses.count == 1
                        ? AppLocalization.text("delivery_details_ready_one", fallback: "1 saved address ready.")
                        : String(format: AppLocalization.text("delivery_details_ready_many", fallback: "%d saved addresses ready."), addresses.count)))
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            addressEntryForm

            if !addresses.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(AppLocalization.text("saved_addresses", fallback: "SAVED ADDRESSES"))
                            .font(labelFont(size: 11, weight: .bold))
                            .tracking(1.8)
                            .foregroundColor(primaryTextColor)

                        Spacer()

                        Text("\(addresses.count)")
                            .font(labelFont(size: 11, weight: .bold))
                            .foregroundColor(readableBrandGoldColor)
                    }

                    ForEach(addresses) { address in
                        savedAddressCard(address)
                    }
                }
            }
        }
    }

    var addressEntryForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(AppLocalization.text("add_new_address", fallback: "ADD A NEW ADDRESS"))
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(1.8)
            } icon: {
                Image(systemName: "location.badge.plus")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(readableBrandGoldColor)

            Text(AppLocalization.text("delivery_details_hint", fallback: "Save your preferred address here so checkout feels faster, even when Shopify opens on the web."))
                .font(bodyFont(size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            addressFormTextField(AppLocalization.text("label", fallback: "Label"), text: $addressLabel, capitalization: .words)
            addressFormTextField(AppLocalization.text("full_name", fallback: "Full name"), text: $addressFullName, capitalization: .words)

            HStack(spacing: 8) {
                if !addressCountry.phonePrefix.isEmpty {
                    Text(addressCountry.phonePrefix)
                        .font(labelFont(size: 12, weight: .bold))
                        .foregroundColor(readableBrandGoldColor)
                        .frame(minWidth: 42, alignment: .leading)
                }

                TextField(
                    addressCountry.phonePrefix.isEmpty
                        ? AppLocalization.text("phone_with_country_code", fallback: "Phone with +country code")
                        : AppLocalization.text("phone", fallback: "Phone"),
                    text: $addressPhone
                )
                .keyboardType(.phonePad)
                .font(bodyFont(size: 14))
                .foregroundColor(primaryTextColor)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(cardFillColor)
            .overlay(addressFieldBorder)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            addressFormTextField(AppLocalization.text("address_line", fallback: "Address line"), text: $addressLine1, capitalization: .words)
            deliveryCountrySelector

            Group {
                if isCompact {
                    VStack(spacing: 12) {
                        addressFormTextField(AppLocalization.text("city", fallback: "City"), text: $addressCity, capitalization: .words)
                        addressFormTextField(AppLocalization.text("notes", fallback: "Notes (optional)"), text: $addressNotes, capitalization: .sentences)
                    }
                } else {
                    HStack(spacing: 12) {
                        addressFormTextField(AppLocalization.text("city", fallback: "City"), text: $addressCity, capitalization: .words)
                        addressFormTextField(AppLocalization.text("notes", fallback: "Notes (optional)"), text: $addressNotes, capitalization: .sentences)
                    }
                }
            }

            Button {
                Task {
                    await saveAddress()
                }
            } label: {
                HStack(spacing: 9) {
                    if isSavingAddress {
                        ProgressView()
                            .tint(Color(hex: 0x0A0804))
                    }
                    Text(isSavingAddress
                        ? AppLocalization.text("saving", fallback: "Saving...")
                        : AppLocalization.text("save_address", fallback: "Save Address"))
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(1.8)
                        .textCase(.uppercase)
                }
                .foregroundColor(Color(hex: 0x0A0804))
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color(hex: 0xC8965A))
                .clipShape(Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isSavingAddress)
            .opacity(isSavingAddress ? 0.72 : 1)
        }
        .padding(16)
        .background(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.045 : 0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    func addressFormTextField(
        _ title: String,
        text: Binding<String>,
        capitalization: TextInputAutocapitalization
    ) -> some View {
        TextField(title, text: text)
            .textInputAutocapitalization(capitalization)
            .font(bodyFont(size: 14))
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 14)
            .frame(minHeight: 52)
            .background(cardFillColor)
            .overlay(addressFieldBorder)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    var addressFieldBorder: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Color(hex: 0xC8965A).opacity(0.14), lineWidth: 1)
    }

    func savedAddressCard(_ address: DeliveryAddress) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(address.label)
                        .font(titleFont(size: 18))
                        .foregroundColor(primaryTextColor)

                    if address.isPreferred {
                        Text(AppLocalization.text("preferred", fallback: "Preferred"))
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(hex: 0xC8965A).opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Text("\(address.fullName) • \(address.phone)")
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                Text("\(address.line1), \(address.city), \(address.country.name)")
                    .font(bodyFont(size: 13))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                if let notes = address.notes, !notes.isEmpty {
                    Text(notes)
                        .font(bodyFont(size: 12))
                        .foregroundColor(tertiaryTextColor)
                }
            }

            Spacer(minLength: 0)

            VStack(spacing: 8) {
                if !address.isPreferred {
                    Button {
                        Task {
                            _ = await makePreferredAddress(address)
                        }
                    } label: {
                        HStack(spacing: 7) {
                            if selectingAddressID == address.id {
                                ProgressView()
                                    .tint(readableBrandGoldColor)
                            } else {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            Text(AppLocalization.text("use_this_address", fallback: "Use this address"))
                                .font(labelFont(size: 10, weight: .bold))
                                .lineLimit(1)
                        }
                        .foregroundColor(readableBrandGoldColor)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 48)
                        .background(Color(hex: 0xC8965A).opacity(0.10))
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(selectingAddressID != nil)
                    .accessibilityLabel(AppLocalization.text("use_this_address", fallback: "Use this address"))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(readableBrandGoldColor)
                        .frame(width: 48, height: 48)
                        .accessibilityLabel(AppLocalization.text("preferred", fallback: "Preferred"))
                }

                Button {
                    Task {
                        await deleteAddress(address)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 48, height: 48)
                        .background(primaryTextColor.opacity(0.06))
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("delete_address", fallback: "Delete address"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(address.isPreferred ? Color(hex: 0xC8965A).opacity(0.055) : cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(address.isPreferred ? 0.32 : 0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var brewRecipesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("saved_brew_recipes", fallback: "SAVED BREW RECIPES"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if brewRecipes.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("saved_brew_recipes_empty", fallback: "Save your favorite coffee-to-water ratios from the brew tab and they will appear here."),
                    actionTitle: AppLocalization.text("open_brewing", fallback: "Open Brewing"),
                    systemImage: "book.closed.fill"
                ) {
                    openBrewing()
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(brewRecipes) { recipe in
                        HStack(alignment: .center, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(recipe.name)
                                    .font(titleFont(size: 18))
                                    .foregroundColor(primaryTextColor)

                                Text("\(formattedRatioValue(recipe.coffeeGrams)) g coffee • 1:\(formattedRatioValue(recipe.ratio)) • \(formattedRatioValue(recipe.waterGrams)) g water")
                                    .font(bodyFont(size: 13))
                                    .foregroundColor(secondaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(recipe.category)
                                    .font(labelFont(size: 10, weight: .bold))
                                    .tracking(1.4)
                                    .textCase(.uppercase)
                                    .foregroundColor(readableBrandGoldColor)
                            }

                            Spacer(minLength: 0)

                            VStack(spacing: 8) {
                                Button {
                                    applyBrewRecipe(recipe)
                                } label: {
                                    Text(AppLocalization.text("apply", fallback: "Apply"))
                                        .font(labelFont(size: 10, weight: .bold))
                                        .tracking(1.8)
                                        .textCase(.uppercase)
                                        .foregroundColor(Color(hex: 0x0A0804))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: 0xC8965A))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    deleteBrewRecipe(recipe)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(primaryTextColor)
                                        .frame(width: 34, height: 34)
                                        .background(cardFillColor)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    var savedCartsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("saved_carts", fallback: "SAVED BAGS"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if savedCarts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("saved_carts_empty", fallback: "Save a filled bag and come back to it whenever you are ready to check out."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "cart.fill"
                ) {
                    openShop()
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(savedCarts) { savedCart in
                        HStack(alignment: .center, spacing: 14) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(savedCart.name)
                                    .font(titleFont(size: 18))
                                    .foregroundColor(primaryTextColor)

                                Text(savedCart.items.map { "\($0.productName) x\($0.quantity)" }.joined(separator: " • "))
                                    .font(bodyFont(size: 13))
                                    .foregroundColor(secondaryTextColor)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)

                            VStack(spacing: 8) {
                                Button {
                                    applySavedCart(savedCart)
                                } label: {
                                    Text(AppLocalization.text("load", fallback: "Load"))
                                        .font(labelFont(size: 10, weight: .bold))
                                        .tracking(1.8)
                                        .textCase(.uppercase)
                                        .foregroundColor(Color(hex: 0x0A0804))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(Color(hex: 0xC8965A))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    deleteSavedCart(savedCart)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(primaryTextColor)
                                        .frame(width: 34, height: 34)
                                        .background(cardFillColor)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(cardFillColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
            }
        }
    }

    var recentlyViewedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("recently_viewed", fallback: "RECENTLY VIEWED"))
                .font(displayFont(size: 22))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            if recentlyViewedProducts.isEmpty {
                actionEmptyState(
                    message: AppLocalization.text("recently_viewed_empty", fallback: "Products you open, save, or add to bag will appear here for quick return visits."),
                    actionTitle: AppLocalization.text("browse_products", fallback: "Browse Products"),
                    systemImage: "clock.fill"
                ) {
                    openShop()
                }
            } else {
                accountCompactProductSection(
                    products: Array(recentlyViewedProducts.prefix(3)),
                    viewAllTitle: AppLocalization.text("view_all_recent_products", fallback: "View all recent products")
                )
            }
        }
    }

    func accountCompactProductSection(products: [Product], viewAllTitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(products) { product in
                        accountCompactProductCard(product)
                    }
                }
                .padding(.vertical, 2)
            }

            Button {
                openShop()
            } label: {
                HStack(spacing: 8) {
                    Text(viewAllTitle)
                    Image(systemName: "arrow.forward")
                }
                .font(labelFont(size: 11, weight: .bold))
                .tracking(1.4)
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
    }

    func accountCompactProductCard(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                recordRecentlyViewed(product)
                selectedProduct = product
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    ProductThumbnail(imageURL: product.imageURL, size: 58, cornerRadius: 12)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(customerFacingProductName(for: product))
                            .font(titleFont(size: 17))
                            .foregroundColor(primaryTextColor)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)

                        Text(accountCompactProductMeta(for: product))
                            .font(bodyFont(size: 12))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                if product.hasVariantChoices {
                    recordRecentlyViewed(product)
                    selectedProduct = product
                } else {
                    addToCart(product: product)
                }
            } label: {
                Text(product.hasVariantChoices
                    ? AppLocalization.text("options", fallback: "Options")
                    : AppLocalization.text("add", fallback: "Add"))
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: 0xC8965A))
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 230, alignment: .topLeading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func accountCompactProductMeta(for product: Product) -> String {
        let variant = accountCompactVariantLabel(for: product)
        guard !variant.isEmpty else {
            return product.price
        }

        return "\(product.price) · \(variant)"
    }

    func accountCompactVariantLabel(for product: Product) -> String {
        guard let title = product.defaultVariant?.title.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty,
              title.lowercased() != "default title",
              title.lowercased() != "default" else {
            return ""
        }

        return title
    }

    func accountStatusTile(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(titleFont(size: 20))
                .foregroundColor(primaryTextColor)

            Text(detail)
                .font(bodyFont(size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 136, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color(hex: 0xC8965A).opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @MainActor
    func loadProductsIfNeeded() async {
        guard !hasLoadedProducts else { return }
        await loadProducts()
        await loadBrewingMethodsIfNeeded()

        if !savedCustomerAccessToken.isEmpty, customerProfile == nil {
            await loadCustomerProfile()
        }

        if !savedLoyaltyEmail.isEmpty, loyaltyEmail.isEmpty {
            loyaltyEmail = savedLoyaltyEmail
            await loadLoyaltyAccount()
        }
    }

    @MainActor
    func signInCustomer() async {
        let trimmedEmail = normalizedAccountEmail
        guard !trimmedEmail.isEmpty, !accountPassword.isEmpty else {
            customerAuthError = AppLocalization.text("enter_email_password", fallback: "Enter your customer email and password.")
            return
        }

        isSigningIn = true
        customerAuthError = nil
        defer { isSigningIn = false }

        do {
            let session = try await AccountService.signIn(email: trimmedEmail, password: accountPassword)
            applySignedInSession(session)
            accountPassword = ""
            showToast(message: AppLocalization.text("signed_in_toast", fallback: "Signed in"))
        } catch {
            customerProfile = nil
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

    }

#if canImport(AuthenticationServices)
    func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = Self.randomAppleNonce()
        appleSignInNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)
    }

    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        Task {
            await handleAppleSignInResultAsync(result)
        }
    }

    @MainActor
    func handleAppleSignInResultAsync(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            appleSignInNonce = ""

            if let authorizationError = error as? ASAuthorizationError,
               authorizationError.code == .canceled {
                customerAuthError = nil
                isSigningInWithApple = false
                return
            }

            customerAuthError = friendlyCustomerAuthMessage(
                for: error,
                fallback: AppLocalization.text("apple_sign_in_unavailable", fallback: "Sign in with Apple is unavailable right now.")
            )
            isSigningInWithApple = false
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                customerAuthError = AppLocalization.text("apple_sign_in_invalid_credential", fallback: "Apple sign-in did not return a valid account credential.")
                isSigningInWithApple = false
                return
            }

            guard let tokenData = credential.identityToken,
                  let identityToken = String(data: tokenData, encoding: .utf8),
                  !identityToken.isEmpty else {
                customerAuthError = AppLocalization.text("apple_sign_in_missing_token", fallback: "Apple sign-in did not return an identity token.")
                isSigningInWithApple = false
                return
            }

            let nonce = appleSignInNonce
            guard !nonce.isEmpty else {
                customerAuthError = AppLocalization.text("apple_sign_in_not_verified", fallback: "Apple sign-in could not be verified.")
                isSigningInWithApple = false
                return
            }

            isSigningInWithApple = true
            customerAuthError = nil

            do {
                let session = try await AccountService.signInWithApple(
                    identityToken: identityToken,
                    userIdentifier: credential.user,
                    email: credential.email,
                    firstName: credential.fullName?.givenName,
                    lastName: credential.fullName?.familyName,
                    nonce: nonce
                )
                applySignedInSession(session)
                accountPassword = ""
                accountConfirmPassword = ""
                showToast(message: AppLocalization.text("signed_in_with_apple_toast", fallback: "Signed in with Apple"))
            } catch {
                customerProfile = nil
                customerAuthError = friendlyCustomerAuthMessage(
                    for: error,
                    fallback: AppLocalization.text("apple_sign_in_unavailable", fallback: "Sign in with Apple is unavailable right now.")
                )
            }

            appleSignInNonce = ""
            isSigningInWithApple = false
        }
    }
#endif

    func switchAccountAuthMode(_ mode: AccountAuthMode) {
        accountAuthMode = mode
        customerAuthError = nil
        accountPassword = ""
        accountConfirmPassword = ""
        appleSignInNonce = ""
    }

    func startFirstRunAccountSetup() {
        hasSeenWelcome = true
        cartOpen = false
        openAccountSection(AccountSectionView.ScrollTarget.customer, authMode: .createAccount)
        showToast(message: AppLocalization.text("onboarding_account_started", fallback: "Create your account first. Delivery details come next."))
    }

    @MainActor
    func prepareNewCustomerAddressSetup(firstName: String, lastName: String) {
        if addressLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressLabel = AppLocalization.text("home_address_label", fallback: "Home")
        }

        if addressFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressFullName = [firstName, lastName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        isAccountOnboardingPresented = true
    }

    @MainActor
    func createCustomerAccount() async {
        let trimmedFirstName = accountFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = accountLastName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = normalizedAccountEmail

        guard !trimmedFirstName.isEmpty, !trimmedLastName.isEmpty, !trimmedEmail.isEmpty, !accountPassword.isEmpty else {
            customerAuthError = AppLocalization.text("complete_account_fields", fallback: "Complete your name, email, and password to create an account.")
            return
        }

        guard accountPassword == accountConfirmPassword else {
            customerAuthError = AppLocalization.text("password_confirmation_mismatch", fallback: "Your password confirmation does not match.")
            return
        }

        guard accountPassword.count >= 5 else {
            customerAuthError = AppLocalization.text("password_min_length", fallback: "Use a password with at least 5 characters.")
            return
        }

        isCreatingAccount = true
        customerAuthError = nil

        do {
            let session = try await AccountService.register(
                firstName: trimmedFirstName,
                lastName: trimmedLastName,
                email: trimmedEmail,
                password: accountPassword
            )

            applySignedInSession(session)
            accountPassword = ""
            accountConfirmPassword = ""
            accountAuthMode = .signIn
            prepareNewCustomerAddressSetup(firstName: trimmedFirstName, lastName: trimmedLastName)
        } catch {
            customerProfile = nil
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isCreatingAccount = false
    }

    @MainActor
    func requestPasswordResetLink() async {
        let trimmedEmail = normalizedAccountEmail
        guard !trimmedEmail.isEmpty else {
            customerAuthError = AppLocalization.text("enter_email_first", fallback: "Enter your email address first.")
            return
        }

        isRequestingPasswordResetLink = true
        customerAuthError = nil

        do {
            try await AccountService.requestPasswordResetLink(email: trimmedEmail)
            accountPassword = ""
            showToast(message: AppLocalization.text("reset_link_sent", fallback: "If an account exists for that email, a reset link has been sent."))
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(
                for: error,
                fallback: AppLocalization.text("email_reset_link", fallback: "Password reset email is unavailable right now.")
            )
        }

        isRequestingPasswordResetLink = false
    }

    @MainActor
    func loadCustomerProfile() async {
        guard !savedCustomerAccessToken.isEmpty, !isLoadingCustomer else { return }

        isLoadingCustomer = true
        customerAuthError = nil

        do {
            let profile = try await AccountService.fetchProfile()
            applySignedInProfile(profile, loadLoyalty: loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } catch AccountService.SessionError.invalid {
            signOutCustomer(clearError: false)
            customerAuthError = AppLocalization.text("account_session_expired", fallback: "Your account session expired. Sign in again to continue.")
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isLoadingCustomer = false
    }

    @MainActor
    func refreshSignedInProfile() async {
        guard customerProfile != nil, !isLoadingCustomer else { return }
        isLoadingCustomer = true
        defer { isLoadingCustomer = false }

        do {
            let profile = try await AccountService.fetchProfile()
            customerProfile = profile
            savedCustomerEmail = profile.email
            accountEmail = profile.email
            profileFirstName = profile.firstName ?? ""
            profileLastName = profile.lastName ?? ""
        } catch AccountService.SessionError.invalid {
            signOutCustomer(clearError: false)
            customerAuthError = AppLocalization.text("account_session_expired", fallback: "Your account session expired. Sign in again to continue.")
        } catch {
            // Keep the last known account state during transient network failures.
        }
    }

    @MainActor
    @discardableResult
    func restoreSyncedCustomerCredential() -> Bool {
        guard savedCustomerAccessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            TallaAccountCredentialStore.save(savedCustomerAccessToken)
            return false
        }

        let syncedToken = TallaAccountCredentialStore.accessToken
        guard !syncedToken.isEmpty else { return false }
        savedCustomerAccessToken = syncedToken
        return true
    }

    func signOutCustomer(clearError: Bool = true, unregisterBackend: Bool = true) {
        let emailToUnregister = customerProfile?.email ?? (!savedCustomerEmail.isEmpty ? savedCustomerEmail : nil)
        let accessTokenToUnregister = savedCustomerAccessToken
        if unregisterBackend {
            unregisterRemotePushToken(email: emailToUnregister, accessToken: accessTokenToUnregister)
        }
        unregisterRemoteNotifications()
        savedRegisteredPushDeviceEmail = ""
        savedRegisteredPushDeviceToken = ""
        savedCustomerEmail = ""
        savedCustomerAccessToken = ""
        TallaAccountCredentialStore.clear()
        customerProfile = nil
        isAccountOnboardingPresented = false
        accountAuthMode = .signIn
        accountFirstName = ""
        accountLastName = ""
        accountPassword = ""
        accountConfirmPassword = ""
        appleSignInNonce = ""
        profileFirstName = ""
        profileLastName = ""
        currentPasswordInput = ""
        newPasswordInput = ""
        confirmNewPasswordInput = ""
        orderHistory = []
        ordersError = nil
        addresses = []
        addressLabel = ""
        addressFullName = ""
        addressPhone = ""
        addressLine1 = ""
        addressCity = ""
        addressCountry = .bahrain
        addressNotes = ""
        backendStockAlerts = []
        availableVouchers = []
        appliedVoucher = nil
        voucherCodeInput = ""
        voucherError = nil

        if clearError {
            customerAuthError = nil
        }
    }

    @MainActor
    func applySignedInProfile(_ profile: ShopifyCustomerProfile, loadLoyalty: Bool = true) {
        savedCustomerEmail = profile.email
        savedLoyaltyEmail = profile.email
        customerProfile = profile
        accountEmail = profile.email
        profileFirstName = profile.firstName ?? ""
        profileLastName = profile.lastName ?? ""

        if loadLoyalty {
            loyaltyEmail = profile.email
        }

        registerForRemoteNotifications()
        Task {
            await refreshWalletPassPresence()
            await syncRemotePushTokenIfPossible()
            await synchronizeCustomerLibrary()
            if loadLoyalty {
                await loadLoyaltyAccount()
            }
            await loadOrderHistory()
            await syncBackendStockAlerts()
            await loadBackendStockAlerts()
            await loadAddresses()
            await loadAlertInbox()
        }
    }

    @MainActor
    func applySignedInSession(_ session: AccountService.CustomerSession, loadLoyalty: Bool = true) {
        TallaAccountCredentialStore.save(accessToken: session.accessToken, refreshToken: session.refreshToken)
        savedCustomerAccessToken = session.accessToken
        applySignedInProfile(session.profile, loadLoyalty: loadLoyalty)
    }

    @MainActor
    func saveProfile() async -> Bool {
        guard let profile = customerProfile else { return false }
        let firstName = profileFirstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = profileLastName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !firstName.isEmpty, !lastName.isEmpty else {
            customerAuthError = AppLocalization.text("enter_full_name_before_saving", fallback: "Enter both first and last name before saving.")
            return false
        }

        isSavingProfile = true
        customerAuthError = nil

        do {
            let updated = try await AccountService.updateProfile(email: profile.email, firstName: firstName, lastName: lastName)
            customerProfile = updated
            profileFirstName = updated.firstName ?? ""
            profileLastName = updated.lastName ?? ""
            showToast(message: AppLocalization.text("profile_updated_toast", fallback: "Profile updated"))
            isSavingProfile = false
            return true
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isSavingProfile = false
        return false
    }

    @MainActor
    func resetPassword() async {
        guard let profile = customerProfile else { return }

        guard newPasswordInput == confirmNewPasswordInput else {
            customerAuthError = AppLocalization.text("new_password_confirmation_mismatch", fallback: "The new password confirmation does not match.")
            return
        }

        guard newPasswordInput.count >= 5 else {
            customerAuthError = AppLocalization.text("password_min_length", fallback: "Use a password with at least 5 characters.")
            return
        }

        isResettingPassword = true
        customerAuthError = nil

        do {
            try await AccountService.resetPassword(
                email: profile.email,
                currentPassword: currentPasswordInput,
                newPassword: newPasswordInput
            )
            currentPasswordInput = ""
            newPasswordInput = ""
            confirmNewPasswordInput = ""
            showToast(message: AppLocalization.text("update_password", fallback: "Password updated"))
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isResettingPassword = false
    }

    @MainActor
    func refreshWalletPassPresence() async {
#if canImport(PassKit)
        guard PKPassLibrary.isPassLibraryAvailable() else {
            isLoyaltyPassInWallet = false
            return
        }

        guard let email = customerProfile?.email ?? (!savedLoyaltyEmail.isEmpty ? savedLoyaltyEmail : nil) else {
            isLoyaltyPassInWallet = false
            return
        }

        do {
            let pass = try await AccountService.fetchWalletPass(email: email)
            let library = PKPassLibrary()
            let isPassInWallet = library.containsPass(pass)
            if isPassInWallet {
                _ = library.replacePass(with: pass)
            }
            isLoyaltyPassInWallet = isPassInWallet
        } catch {
            isLoyaltyPassInWallet = false
        }
#else
        isLoyaltyPassInWallet = false
#endif
    }

    @MainActor
    func changePasswordWithoutSignIn() async {
        let trimmedEmail = normalizedAccountEmail

        guard !trimmedEmail.isEmpty, !accountPassword.isEmpty, !accountConfirmPassword.isEmpty else {
            customerAuthError = AppLocalization.text("enter_email_current_new_password", fallback: "Enter your email, current password, and new password.")
            return
        }

        guard accountConfirmPassword.count >= 5 else {
            customerAuthError = AppLocalization.text("password_min_length", fallback: "Use a password with at least 5 characters.")
            return
        }

        isResettingPassword = true
        customerAuthError = nil

        do {
            try await AccountService.changePasswordWithoutSignIn(
                email: trimmedEmail,
                currentPassword: accountPassword,
                newPassword: accountConfirmPassword
            )
            accountAuthMode = .signIn
            accountPassword = ""
            accountConfirmPassword = ""
            showToast(message: AppLocalization.text("update_password", fallback: "Password updated"))
        } catch {
            customerAuthError = friendlyCustomerAuthMessage(for: error)
        }

        isResettingPassword = false
    }

    @MainActor
    func loadOrderHistory() async {
        guard let profile = customerProfile, !isLoadingOrders else { return }

        isLoadingOrders = true
        ordersError = nil

        do {
            orderHistory = try await AccountService.fetchOrders(email: profile.email)
            if let remoteTasteMemory = try? await AccountService.fetchTasteMemory(email: profile.email) {
                persistTasteMemoryRecords(remoteTasteMemory)
            }
        } catch {
            orderHistory = []
            ordersError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("orders_refresh_failed", fallback: "Orders could not be refreshed right now.")
            )
        }

        isLoadingOrders = false
    }

    @MainActor
    func loadBackendStockAlerts() async {
        guard let profile = customerProfile, !isLoadingBackendAlerts else { return }

        isLoadingBackendAlerts = true
        do {
            backendStockAlerts = try await AccountService.fetchStockAlerts(email: profile.email)
        } catch {
            backendStockAlerts = []
        }
        isLoadingBackendAlerts = false
    }

    @MainActor
    func loadAddresses() async {
        guard let profile = customerProfile else { return }
        if let loaded = try? await AccountService.fetchAddresses(email: profile.email) {
            addresses = loaded
            if loaded.isEmpty {
                prepareAccountOnboarding(for: profile)
            }
        }
    }

    @MainActor
    func prepareAccountOnboarding(for profile: ShopifyCustomerProfile) {
        if addressLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressLabel = AppLocalization.text("home_address_label", fallback: "Home")
        }

        if addressFullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            addressFullName = [profile.firstName, profile.lastName]
                .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
        }

        isAccountOnboardingPresented = true
    }

    @MainActor
    func loadAlertInbox() async {
        guard let profile = customerProfile else { return }
        if let loaded = try? await AccountService.fetchAlertInbox(email: profile.email) {
            alertInbox = loaded
        }
    }

    @MainActor
    func syncBackendStockAlerts() async {
        guard let profile = customerProfile, !alertProducts.isEmpty else { return }

        let records = alertProducts.map {
            StockAlertRecord(
                productID: $0.id,
                productName: $0.name,
                tag: $0.tag,
                isAvailableForSale: $0.isAvailableForSale,
                status: $0.isAvailableForSale ? "Available now" : "Waiting for availability",
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
        }

        if let synced = try? await AccountService.syncStockAlerts(email: profile.email, alerts: records) {
            backendStockAlerts = synced
        }
    }

    @MainActor
    func saveAddress(closeOnboarding: Bool = false) async {
        guard let profile = customerProfile else { return }
        let label = addressLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let fullName = addressFullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = normalizedPhoneNumber(addressPhone)
        let line1 = addressLine1.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = addressCity.trimmingCharacters(in: .whitespacesAndNewlines)
        let notes = addressNotes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !label.isEmpty, !fullName.isEmpty, !phone.isEmpty, !line1.isEmpty, !city.isEmpty else {
            showToast(message: AppLocalization.text("complete_address_details", fallback: "Complete the address details first"))
            return
        }

        isSavingAddress = true
        defer { isSavingAddress = false }

        do {
            addresses = try await AccountService.saveAddress(
                email: profile.email,
                label: label,
                fullName: fullName,
                phone: phone,
                line1: line1,
                city: city,
                countryCode: addressCountry.rawValue,
                notes: notes.isEmpty ? nil : notes
            )
            addressLabel = ""
            addressFullName = ""
            addressPhone = ""
            addressLine1 = ""
            addressCity = ""
            addressCountry = .bahrain
            addressNotes = ""
            if closeOnboarding {
                isAccountOnboardingPresented = false
            }
            showToast(message: AppLocalization.text("address_saved_toast", fallback: "Address saved"))
        } catch {
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("address_save_failed", fallback: "Address could not be saved right now.")
            ))
        }
    }

    func normalizedPhoneNumber(_ rawValue: String) -> String {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        let compact = trimmed
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")

        if compact.hasPrefix("+") {
            return compact
        }

        guard !addressCountry.phonePrefix.isEmpty else { return "" }
        let localNumber = compact.drop(while: { $0 == "0" })
        return "\(addressCountry.phonePrefix)\(localNumber)"
    }

    @MainActor
    func deleteAddress(_ address: DeliveryAddress) async {
        guard let profile = customerProfile else { return }

        do {
            addresses = try await AccountService.deleteAddress(email: profile.email, addressID: address.id)
            showToast(message: AppLocalization.text("address_removed_toast", fallback: "Address removed"))
        } catch {
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("address_remove_failed", fallback: "Address could not be removed right now.")
            ))
        }
    }

    @MainActor
    func makePreferredAddress(_ address: DeliveryAddress) async -> Bool {
        guard let profile = customerProfile else { return false }
        guard !address.isPreferred else { return true }

        let previousAddresses = addresses
        selectingAddressID = address.id
        addresses = addresses.map { candidate in
            DeliveryAddress(
                id: candidate.id,
                label: candidate.label,
                fullName: candidate.fullName,
                phone: candidate.phone,
                line1: candidate.line1,
                city: candidate.city,
                countryCode: candidate.countryCode,
                notes: candidate.notes,
                isPreferred: candidate.id == address.id
            )
        }
        defer { selectingAddressID = nil }

        do {
            addresses = try await AccountService.setPreferredAddress(
                email: profile.email,
                addressID: address.id
            )
            checkoutError = nil
            showToast(message: AppLocalization.text("delivery_address_selected", fallback: "Delivery address selected"))
            return true
        } catch {
            addresses = previousAddresses
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("address_selection_failed", fallback: "The delivery address could not be selected right now.")
            ))
            return false
        }
    }

    func friendlyCustomerAuthMessage(for error: Error, fallback: String? = nil) -> String {
        if let urlError = error as? URLError,
           [.cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost, .notConnectedToInternet].contains(urlError.code) {
            return BackendConfiguration.connectionMessage(for: "account service")
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = message.lowercased()

        if normalized.contains("backendbaseurl") || normalized.contains("127.0.0.1") || normalized.contains("localhost") {
            return fallback ?? AppLocalization.text("connection_issue_try_again", fallback: "Talla is having trouble connecting. Check your internet connection and try again.")
        }

        if normalized.contains("invalid email or password") {
            return fallback ?? "The email or password is incorrect."
        }

        if normalized.contains("account already exists") {
            return fallback ?? "An account with this email already exists."
        }

        if normalized.contains("account not found") {
            return fallback ?? "No account was found for that email."
        }

        if normalized.contains("password reset email is not configured") || normalized.contains("password reset email could not be sent") {
            return fallback ?? "Password reset email is unavailable right now."
        }

        if normalized.contains("unidentified customer") {
            return fallback ?? "This account could not be recognized yet. Check that the email and password are correct and try again."
        }

        return fallback ?? message
    }

    func customerFacingServiceMessage(for error: Error, fallback: String) -> String {
        if let urlError = error as? URLError,
           [.cannotConnectToHost, .cannotFindHost, .timedOut, .networkConnectionLost, .notConnectedToInternet].contains(urlError.code) {
            return AppLocalization.text("connection_issue_try_again", fallback: "Talla is having trouble connecting. Check your internet connection and try again.")
        }

        let message = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = message.lowercased()

        if message.isEmpty ||
            normalized.contains("backendbaseurl") ||
            normalized.contains("127.0.0.1") ||
            normalized.contains("localhost") ||
            normalized.contains("url is invalid") ||
            normalized.contains("invalid response") ||
            normalized.contains("service is unavailable") ||
            normalized.contains("could not complete your request") {
            return fallback
        }

        return message
    }

    func isExpiredCustomerSessionError(_ error: Error) -> Bool {
        let message = error.localizedDescription
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        return message.contains("sign in again")
            || message.contains("invalid customer token")
            || message.contains("customer authorization required")
            || message.contains("customer access token")
    }

    var normalizedAccountEmail: String {
        accountEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    @MainActor
    func loadProducts(force: Bool = false) async {
        guard !isLoadingProducts else { return }
        guard force || !hasLoadedProducts else { return }

        isLoadingProducts = true
        loadingError = nil

        do {
            let fetchedProducts = try await ShopifyStorefrontClient.fetchAllProducts()
            products = fetchedProducts
            hasLoadedProducts = true
            lastProductsRefreshAt = Date()
            await loadHomeSettings()
            await loadPassportSettings()
            await loadAppSettings()
            await loadEventSettings()

            if !availableCategories.contains(where: { $0.key == activeCategory }) {
                activeCategory = "all"
            }

            if customerProfile != nil {
                await syncBackendStockAlerts()
                await loadBackendStockAlerts()
            }
        } catch {
            loadingError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("shop_retry_later", fallback: "Products could not be loaded right now. Please try again.")
            )
        }

        isLoadingProducts = false
    }

    @MainActor
    func loadHomeSettings() async {
        do {
            let settings = try await HomeSettingsService.fetchHomeSettings()
            remoteHomeSettings = settings
            remoteSignatureRoastProductIDs = settings.signatureRoastProductIDs
        } catch {
            remoteHomeSettings = nil
            remoteSignatureRoastProductIDs = []
        }
    }

    @MainActor
    func loadPassportSettings() async {
        do {
            remotePassportSettings = try await HomeSettingsService.fetchPassportSettings()
        } catch {
            remotePassportSettings = nil
        }
    }

    @MainActor
    func loadAppSettings() async {
        do {
            let settings = try await HomeSettingsService.fetchAppSettings()
            remoteAppSettings = settings
            if settings.fulfillment?.deliveryEnabled == false,
               settings.fulfillment?.pickupEnabled == true {
                fulfillmentMethod = .pickup
            } else if settings.fulfillment?.pickupEnabled == false,
                      settings.fulfillment?.deliveryEnabled == true {
                fulfillmentMethod = .delivery
            }
        } catch {
            // Keep the bundled defaults when live controls are unavailable.
        }
    }

    @MainActor
    func loadEventSettings() async {
        do {
            remoteEventSettings = try await HomeSettingsService.fetchEventSettings()
        } catch {
            // Seasonal content is optional; keep the normal storefront if unavailable.
        }
    }

    @MainActor
    func refreshProductsIfNeeded() async {
        let now = Date()
        if let lastProductsRefreshAt,
           now.timeIntervalSince(lastProductsRefreshAt) < 45 {
            return
        }

        await loadProducts(force: true)
    }

    @MainActor
    func loadBrewingMethodsIfNeeded() async {
        guard !hasLoadedBrewingMethods else { return }
        await loadBrewingMethods()
    }

    @MainActor
    func loadBrewingMethods(force: Bool = false) async {
        guard !isLoadingBrewingMethods else { return }
        guard force || !hasLoadedBrewingMethods else { return }

        isLoadingBrewingMethods = true
        brewingMethodsError = nil

        do {
            brewingMethods = try await ShopifyStorefrontClient.fetchBrewingMethods()
            hasLoadedBrewingMethods = true
        } catch {
            brewingMethods = []
            brewingMethodsError = AppLocalization.text("brewing_articles_fallback", fallback: "Brewing articles couldn't be loaded from Shopify. Showing curated fallback methods.")
        }

        isLoadingBrewingMethods = false
    }

    @MainActor
    func loadLoyaltyAccount() async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = AppLocalization.text("enter_order_email_loyalty", fallback: "Enter the email you use for your coffee orders.")
            return
        }

        isLoadingLoyalty = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.fetchAccount(email: trimmedEmail)
            savedLoyaltyEmail = trimmedEmail
            syncWidgetSharedState(reload: true)
            await loadAvailableVouchers(for: trimmedEmail)
            await refreshWalletPassPresence()
            showToast(message: AppLocalization.text("rewards_loaded_toast", fallback: "Rewards loaded"))
        } catch {
            loyaltyAccount = nil
            loyaltyError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("rewards_refresh_failed", fallback: "Rewards could not be refreshed right now.")
            )
        }

        isLoadingLoyalty = false
    }

    @MainActor
    func redeemReward(points: Int, reward: String) async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = AppLocalization.text("enter_rewards_email_first", fallback: "Enter the email tied to your rewards account first.")
            return
        }

        isRedeemingReward = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.redeemReward(email: trimmedEmail, points: points, reward: reward)
            syncWidgetSharedState(reload: true)
            let voucherCode = loyaltyAccount?.transactions.first(where: { $0.type == "redeem" })?.voucherCode
            if let voucherCode, !voucherCode.isEmpty {
                showToast(message: String(format: AppLocalization.text("reward_redeemed_with_code", fallback: "%@ redeemed • %@"), reward, voucherCode))
            } else {
                showToast(message: String(format: AppLocalization.text("reward_redeemed", fallback: "%@ redeemed"), reward))
            }
            await refreshWalletPassPresence()
        } catch {
            loyaltyError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("reward_redeem_failed", fallback: "This reward could not be redeemed right now.")
            )
        }

        isRedeemingReward = false
    }

    @MainActor
    func earnPoints(points: Int, note: String) async {
        let trimmedEmail = loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else {
            loyaltyError = AppLocalization.text("enter_rewards_email_first", fallback: "Enter the email tied to your rewards account first.")
            return
        }

        isEarningPoints = true
        loyaltyError = nil

        do {
            loyaltyAccount = try await LoyaltyService.earnPoints(email: trimmedEmail, points: points, note: note)
            syncWidgetSharedState(reload: true)
            showToast(message: String(format: AppLocalization.text("beans_added_toast", fallback: "%d Beans added"), points))
        } catch {
            loyaltyError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("beans_update_failed", fallback: "Beans could not be updated right now.")
            )
        }

        isEarningPoints = false
    }

    @MainActor
    func addLoyaltyPassToWallet() async {
#if canImport(PassKit)
        guard PKPassLibrary.isPassLibraryAvailable() else {
            showToast(message: AppLocalization.text("apple_wallet_unavailable", fallback: "Apple Wallet is unavailable on this device"))
            return
        }

        guard let email = customerProfile?.email ?? (!savedLoyaltyEmail.isEmpty ? savedLoyaltyEmail : nil) else {
            showToast(message: AppLocalization.text("sign_in_before_wallet_pass", fallback: "Sign in before adding your Wallet pass"))
            return
        }

        isLoadingWalletPass = true

        do {
            let pass = try await AccountService.fetchWalletPass(email: email)
            let library = PKPassLibrary()
            if library.containsPass(pass) {
                _ = library.replacePass(with: pass)
                isLoyaltyPassInWallet = true
                showToast(message: AppLocalization.text("wallet_pass_updated", fallback: "The Talla Club card was updated in Apple Wallet"))
            } else {
                loyaltyWalletPass = WalletPassItem(pass: pass)
            }
        } catch {
            showToast(message: customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("wallet_pass_failed", fallback: "Wallet pass could not be loaded right now.")
            ))
        }

        isLoadingWalletPass = false
#else
        showToast(message: AppLocalization.text("apple_wallet_unavailable", fallback: "Apple Wallet is unavailable on this device"))
#endif
    }

}
