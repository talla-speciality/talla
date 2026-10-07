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
            accentColor: TallaTheme.Colors.accent,
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
            consumeOrdersPresentationRequest: {
                accountOrdersPresentationRequest = 0
            },
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
        .sheet(item: $editingBrewRecipe) { recipe in
            NavigationStack {
                SavedBrewRecipeEditor(
                    recipe: recipe,
                    accent: TallaTheme.Colors.accent,
                    background: cardFillColor,
                    primary: primaryTextColor,
                    secondary: secondaryTextColor
                ) { updated in
                    persistBrewRecipes([updated] + brewRecipes.filter { $0.id != updated.id })
                    showToast(message: AppLocalization.text("brew_recipe_saved_toast", fallback: "Brew recipe saved"))
                }
            }
        }
    }

    var accountPresentationView: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    accountView
                    Color.clear
                        .frame(height: 24)
                        .id("account-bottom")
                }
                .onChange(of: accountScrollTarget) { _, target in
                    guard let target else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(target, anchor: .top)
                        }
                        accountScrollTarget = nil
                    }
                }
            }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    var languagePreferenceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(readableBrandGoldColor)
                    .frame(width: 34, height: 34)
                    .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("language", fallback: "Language"))
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(AppLocalization.letterSpacing(1.8))
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
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    var settingsAndHelpSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalization.text("settings_and_help", fallback: "SETTINGS & HELP"))
                .font(displayFont(size: 22))
                .tracking(AppLocalization.letterSpacing(2))
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
                    title: AppLocalization.text("app_icon", fallback: "App Icon"),
                    value: currentAppIconTitle,
                    systemImage: "app.badge.fill"
                ) {
                    selectedSettingsDetail = .appIcon
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
                .accessibilityIdentifier("account.navigation.deleteAccount")
            }
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
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

    var currentAppIconTitle: String {
        let currentName = UIApplication.shared.alternateIconName
        if currentName == "TallaIcon1" || currentName == nil {
            return "Bahrain Pink"
        }
        return TallaAppIconOption.all.first(where: { $0.iconName == currentName })?.title
            ?? "Bahrain Pink"
    }

    var settingsDivider: some View {
        Rectangle()
            .fill(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.10 : 0.06))
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
                    .foregroundColor(isDestructive ? .red : TallaTheme.Colors.accent)
                    .frame(width: 34, height: 34)
                    .background((isDestructive ? Color.red : TallaTheme.Colors.accent).opacity(isLightAppearance ? 0.10 : 0.14))
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
                                    .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.10), lineWidth: 1)
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
        case .appIcon:
            return AppLocalization.text("app_icon", fallback: "App Icon")
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
        case .appIcon:
            appIconPickerCard
        case .aboutTalla:
            accountStatusTile(
                title: AppLocalization.text("about_talla", fallback: "About Talla"),
                detail: AppLocalization.text("about_talla_detail", fallback: "Speciality coffee, rewards, and roastery essentials built around daily rituals in Bahrain.")
            )
        case .deleteAccount:
            deleteAccountSettingsCard
        }
    }

    var appIconPickerCard: some View {
        TallaAppIconPicker(
            accentColor: TallaTheme.Colors.accent,
            cardColor: cardFillColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            onError: { showToast(message: $0) }
        )
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
                    .tracking(AppLocalization.letterSpacing(1.6))
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x151515))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canManageNotificationAccess)
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
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
                .tracking(AppLocalization.letterSpacing(1.6))
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
            .accessibilityIdentifier("account.delete.confirm")
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
                .foregroundColor(isSelected ? Color(hex: 0x151515) : primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? TallaTheme.Colors.accent : cardFillColor)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(TallaTheme.Colors.accent.opacity(isSelected ? 0 : 0.18), lineWidth: 1)
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
            strokeColor: TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08)
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
                    .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.12 : 0.16))
                    .clipShape(Circle())

                Text(message)
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: action) {
                Text(actionTitle)
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(AppLocalization.letterSpacing(1.8))
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x151515))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("favorites", fallback: "FAVORITES"))
                .font(displayFont(size: 22))
                .tracking(AppLocalization.letterSpacing(2))
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
                .tracking(AppLocalization.letterSpacing(2))
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
                    Text(AppLocalization.text("recommendation_explanation", fallback: "Why these picks: Talla combines your taste profile, favorites, recent orders, coffee-library matches, and current availability. You can change this in Privacy & Explanations."))
                        .font(bodyFont(size: 12))
                        .foregroundColor(secondaryTextColor)
                        .padding(12)
                        .background(cardFillColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityIdentifier("recommendations.explanation")

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
                .tracking(AppLocalization.letterSpacing(2))
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
                                .tracking(AppLocalization.letterSpacing(1.6))
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
                                        .stroke(TallaTheme.Colors.accent.opacity(0.12), lineWidth: 1)
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
                                    .tracking(AppLocalization.letterSpacing(1.6))
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
                                .stroke(TallaTheme.Colors.accent.opacity(0.12), lineWidth: 1)
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
                .tracking(AppLocalization.letterSpacing(1.5))
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
                    .stroke(TallaTheme.Colors.accent.opacity(0.18), lineWidth: 1)
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
                            .tracking(AppLocalization.letterSpacing(2.4))
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
                                .stroke(TallaTheme.Colors.accent.opacity(0.16), lineWidth: 1)
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
                                    .tint(Color(hex: 0x151515))
                            }
                            Text(isSavingAddress
                                ? AppLocalization.text("saving", fallback: "Saving...")
                                : AppLocalization.text("save_and_continue", fallback: "Save & Continue"))
                                .font(labelFont(size: 11, weight: .bold))
                                .tracking(AppLocalization.letterSpacing(1.8))
                                .textCase(.uppercase)
                        }
                        .foregroundColor(Color(hex: 0x151515))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(TallaTheme.Colors.accent)
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
                    .stroke(TallaTheme.Colors.accent.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    var addressesSection: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppLocalization.text("delivery_details", fallback: "DELIVERY DETAILS"))
                    .font(displayFont(size: 22))
                    .tracking(AppLocalization.letterSpacing(2))
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
                            .tracking(AppLocalization.letterSpacing(1.8))
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
                    .tracking(AppLocalization.letterSpacing(1.8))
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
                            .tint(Color(hex: 0x151515))
                    }
                    Text(isSavingAddress
                        ? AppLocalization.text("saving", fallback: "Saving...")
                        : AppLocalization.text("save_address", fallback: "Save Address"))
                        .font(labelFont(size: 11, weight: .bold))
                        .tracking(AppLocalization.letterSpacing(1.8))
                        .textCase(.uppercase)
                }
                .foregroundColor(Color(hex: 0x151515))
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(TallaTheme.Colors.accent)
                .clipShape(Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isSavingAddress)
            .opacity(isSavingAddress ? 0.72 : 1)
        }
        .padding(16)
        .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.045 : 0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(0.16), lineWidth: 1)
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
            .stroke(TallaTheme.Colors.accent.opacity(0.14), lineWidth: 1)
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
                            .tracking(AppLocalization.letterSpacing(1.2))
                            .textCase(.uppercase)
                            .foregroundColor(readableBrandGoldColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(TallaTheme.Colors.accent.opacity(0.12))
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
                        .background(TallaTheme.Colors.accent.opacity(0.10))
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
        .background(address.isPreferred ? TallaTheme.Colors.accent.opacity(0.055) : cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(address.isPreferred ? 0.32 : 0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var brewRecipesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("saved_brew_recipes", fallback: "SAVED BREW RECIPES"))
                .font(displayFont(size: 22))
                .tracking(AppLocalization.letterSpacing(2))
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
                                    .tracking(AppLocalization.letterSpacing(1.4))
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
                                        .tracking(AppLocalization.letterSpacing(1.8))
                                        .textCase(.uppercase)
                                        .foregroundColor(Color(hex: 0x151515))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(TallaTheme.Colors.accent)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                Button {
                                    editBrewRecipe(recipe)
                                } label: {
                                    Label(AppLocalization.text("edit", fallback: "Edit"), systemImage: "pencil")
                                        .font(labelFont(size: 10, weight: .bold))
                                        .tracking(AppLocalization.letterSpacing(1.4))
                                        .textCase(.uppercase)
                                        .foregroundColor(primaryTextColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(cardFillColor)
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
                                .stroke(TallaTheme.Colors.accent.opacity(0.12), lineWidth: 1)
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
                .tracking(AppLocalization.letterSpacing(2))
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
                                        .tracking(AppLocalization.letterSpacing(1.8))
                                        .textCase(.uppercase)
                                        .foregroundColor(Color(hex: 0x151515))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .background(TallaTheme.Colors.accent)
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
                                .stroke(TallaTheme.Colors.accent.opacity(0.12), lineWidth: 1)
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
                .tracking(AppLocalization.letterSpacing(2))
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
                .tracking(AppLocalization.letterSpacing(1.4))
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
                    .tracking(AppLocalization.letterSpacing(1.4))
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x151515))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 230, alignment: .topLeading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.08), lineWidth: 1)
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
                .stroke(TallaTheme.Colors.accent.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
