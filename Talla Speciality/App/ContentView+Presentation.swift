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
    var body: some View {
        presentedContent
            .font(TallaTheme.Fonts.body)
            .tint(TallaTheme.Colors.ink)
            .textFieldStyle(.talla)
            .buttonBorderShape(.roundedRectangle(radius: TallaTheme.CornerRadius.control))
            .controlSize(.large)
            .sensoryFeedback(.selection, trigger: activeTab)
            .onOpenURL(perform: handleDeepLink)
            .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
            .environment(\.layoutDirection, appLanguage.layoutDirection)
            .preferredColorScheme(appearanceMode.colorScheme)
    }

    var rootContent: some View {
        ZStack {
            LinearGradient(
                colors: backgroundGradientColors,
                startPoint: .top,
                endPoint: .bottom
            )
                .ignoresSafeArea()

            Circle()
                .fill(TallaTheme.Colors.accent.opacity(isOLEDAppearance ? 0 : (isLightAppearance ? 0.10 : 0.08)))
                .frame(width: isCompact ? 260 : 420)
                .blur(radius: 18)
                .offset(x: isCompact ? 150 : 320, y: -280)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Circle()
                .fill(TallaTheme.Colors.brand.opacity(isOLEDAppearance ? 0 : (isLightAppearance ? 0.06 : 0.09)))
                .frame(width: isCompact ? 220 : 360)
                .blur(radius: 24)
                .offset(x: isCompact ? -160 : -340, y: 340)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            if showLaunchSplash {
                launchSplashView
                    .transition(.opacity)
                    .zIndex(80)
            } else {
                appTabView

                if cartOpen {
                    cartDrawer
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if !hasSeenWelcome {
                    WelcomeOverlayView(
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        cardFillColor: elevatedSurfaceColor,
                        accentColor: TallaTheme.Colors.accent,
                        scrimColor: scrimColor,
                        titleFont: displayFont(size: isCompact ? 34 : 42),
                        bodyFont: bodyFont(size: 14),
                        labelFont: labelFont(size: 10, weight: .bold),
                        startAction: {
                            startFirstRunAccountSetup()
                        },
                        choiceAction: { choice in
                            handleWelcomeChoice(choice)
                        },
                        skipAction: {
                            hasSeenWelcome = true
                        }
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(40)
                }

                if shouldShowFeatureTour {
                    FeatureTourOverlayView(
                        highlights: featureTourHighlights,
                        currentIndex: featureTourIndex,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                        cardFillColor: elevatedSurfaceColor,
                        accentColor: TallaTheme.Colors.accent,
                        scrimColor: scrimColor,
                        titleFont: displayFont(size: isCompact ? 30 : 36),
                        bodyFont: bodyFont(size: 14),
                        labelFont: labelFont(size: 10, weight: .bold),
                        nextAction: advanceFeatureTour,
                        skipAction: dismissFeatureTour
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .zIndex(45)
                }

            }
        }
        .onChange(of: cartOpen) { _, open in
            if open { dismissKeyboard() }
        }
        .onChange(of: activeTab) { oldTab, newTab in
            if oldTab != newTab { dismissKeyboard() }
        }
    }

    var lifecycleContent: some View {
        rootContent
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: cartOpen)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: showLaunchSplash)
        .transaction { transaction in
            if reduceMotion {
                transaction.disablesAnimations = true
            }
        }
        .sensoryFeedback(.success, trigger: delightFeedbackTrigger)
        .task {
            guard !didStartInitialLaunchSequence else { return }
            didStartInitialLaunchSequence = true
            if configureReleaseUITestScenarioIfNeeded() { return }
            syncWidgetSharedState(reload: false)
            await runInitialLaunchSequence()
            guard !Task.isCancelled else { return }
            syncWidgetSharedState(reload: true)
        }
        .task {
            refreshHomeShelfCache()
        }
        .onChange(of: coffeeData.changeToken) { _, _ in
            refreshHomeShelfCache()
        }
        .onChange(of: lastProductsRefreshAt) { _, _ in
            refreshHomeShelfCache()
        }
        .onChange(of: orderHistory.count) { _, _ in
            refreshHomeShelfCache()
        }
        .task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 30_000_000_000)
                } catch {
                    return
                }
                await loadAppSettings()
            }
        }
        .onChange(of: activeTab) { _, newTab in
            guard newTab == .shop, hasLoadedProducts, !didConfigureReleaseUITest else { return }
            Task {
                await refreshProductsIfNeeded()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
#if DEBUG
            guard ProcessInfo.processInfo.environment["TALLA_UI_TEST_SCENARIO"] == nil else { return }
#endif
            synchronizeBrewTimerWithClock()
            Task {
                let restoredCredential = restoreSyncedCustomerCredential()
                if restoredCredential, customerProfile == nil {
                    await loadCustomerProfile()
                }
                await loadAppSettings()
                await loadEventSettings()
                guard hasLoadedProducts else { return }
                if activeTab == .shop {
                    await refreshProductsIfNeeded()
                }
                await refreshWalletPassPresence()
                await refreshNotificationStatus()
                await syncRemotePushTokenIfPossible()
                if customerProfile != nil {
                    await refreshSignedInProfile()
                    await synchronizeCustomerLibrary()
                    await loadOrderHistory()
                    await loadBackendStockAlerts()
                    await loadAddresses()
                    await loadAlertInbox()
                    if !activeEazyShopifyPaymentID.isEmpty, checkoutSession == nil {
                        await refreshActiveEazyShopifyPayment(openHostedCheckout: false)
                    }
                    if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        await loadLoyaltyAccount()
                    }
                }
                recordLaunchAndRequestReviewIfReady()
            }
        }
        .onChange(of: savedPushDeviceToken) { _, _ in
            Task {
                await syncRemotePushTokenIfPossible()
            }
        }
        .onChange(of: savedCustomerAccessToken) { _, _ in
            Task {
                await syncRemotePushTokenIfPossible()
            }
        }
        .onChange(of: savedLoyaltyEmail) { _, _ in
            syncWidgetSharedState(reload: true)
        }
        .onChange(of: savedFavoriteProductIDs) { _, _ in
            syncWidgetSharedState(reload: true)
        }
        .onChange(of: savedRecentlyViewedProductIDs) { _, _ in
            syncWidgetSharedState(reload: true)
        }
        .onChange(of: savedCartsPayload) { _, _ in
            syncWidgetSharedState(reload: true)
        }
        .onChange(of: cartItems.map { "\($0.id):\($0.quantity)" }.joined(separator: "|")) { _, _ in
            persistActiveCartForSync()
        }
        .onChange(of: savedAppLanguage) { _, _ in
            syncWidgetSharedState(reload: true)
            guard !didConfigureReleaseUITest else { return }
            Task {
                await loadProducts(force: true)
                await loadBrewingMethods(force: true)
            }
        }
        .onChange(of: shortcutDestination) { _, _ in
            handleShortcutDestination()
        }
        .onChange(of: products.count) { _, _ in
            resolvePendingUniversalLinkProduct()
        }
#if canImport(PhotosUI)
        .onChange(of: conciergeImageSelection) { _, newSelection in
            Task {
                await loadConciergeImage(from: newSelection)
            }
        }
#endif
    }

    var presentedContent: some View {
        ZStack {
            lifecycleContent
            if blocksApplicationUse {
                operationalBlockerView
                    .zIndex(200)
            }
        }
        .sheet(item: $checkoutSession, onDismiss: resetPaymentFlowAfterCheckoutDismiss) { session in
            CheckoutWebView(url: session.url)
        }
        .sheet(item: $benefitPaySession, onDismiss: resetPaymentFlowAfterBenefitPayDismiss) { session in
            BenefitPayCheckoutSheet(session: session) {
                benefitPaySession = nil
                paymentFlow.cancel()
            }
        }
#if canImport(Gateway) && canImport(uSDK) && canImport(UIKit)
        .sheet(item: $mastercardPaymentContext, onDismiss: resetPaymentFlowAfterMastercardDismiss) { context in
            MastercardPaymentSheet(context: context, flow: paymentFlow)
        }
#endif
        .sheet(item: $articleSession) { session in
            CheckoutWebView(url: session.url)
        }
        .sheet(item: $selectedProduct) { product in
            productDetailSheet(product: product)
                .tallaSystemSheetSurface()
        }
        .sheet(
            isPresented: Binding(
                get: { selectedCoffeeShelfID != nil },
                set: { isPresented in
                    if !isPresented {
                        selectedCoffeeShelfID = nil
                    }
                }
            )
        ) {
            if let coffeeID = selectedCoffeeShelfID {
                coffeeShelfDetailSheet(coffeeID: coffeeID)
                    .tallaSystemSheetSurface()
            }
        }
        .sheet(item: $socialCoffeeInvite) { invite in
            SocialCoffeeGroupInviteView(invite: invite, products: products, isSignedIn: customerProfile != nil, hasItemsInBag: { !cartItems.isEmpty }, clearBagAction: clearBagForNewFlow, accountAction: {
                accountScrollTarget = nil
                openTab(.account)
            }, checkoutAction: { group in
                guard cartItems.isEmpty else {
                    showToast(message: "Finish or clear your current bag before reviewing this group order.")
                    cartOpen = true
                    return
                }
                requestedSubscriptionPlanType = ""
                cartSubscriptionPlanType = ""
                isCoffeeClubPrepaid = false
                isCafePassPrepaid = false
                suspendedCoffeePass = false
                for line in group.items {
                    guard let product = products.first(where: { $0.id == line.productID }),
                          let variant = product.variants.first(where: { $0.id == line.variantID }),
                          product.isAvailableForSale, variant.isAvailableForSale else { continue }
                    let itemID = cartItemIdentifier(productID: product.id, variantID: variant.id)
                    if let index = cartItems.firstIndex(where: { $0.id == itemID }) {
                        updateCartItemQuantity(at: index, quantity: cartItems[index].quantity + line.quantity)
                    } else {
                        cartItems.append(CartItem(id: itemID, product: product, variant: variant, quantity: line.quantity))
                    }
                }
                isGiftOrder = false
                cartOpen = !cartItems.isEmpty
            })
            .presentationDetents([.medium, .large])
            .tallaSystemSheetSurface()
        }
        .sheet(item: $socialCoffeePassGift) { gift in
            SocialCoffeePassGiftView(gift: gift)
                .presentationDetents([.medium, .large])
                .tallaSystemSheetSurface()
        }
        .sheet(isPresented: $isCoffeeGiftVaultPresented) {
            TallaCoffeeGiftVaultView { gift in
                isCoffeeGiftVaultPresented = false
                socialCoffeePassGift = SocialCoffeePassGift(orderID: gift.orderID, token: gift.token)
            }
            .presentationDetents([.medium, .large])
            .tallaSystemSheetSurface()
        }
        .sheet(isPresented: $isFavoriteShelfPresented) {
            favoriteShelfSheet
                .tallaSystemSheetSurface()
        }
        .sheet(isPresented: $isCartRewardsPresented) {
            cartRewardsSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .tallaSystemSheetSurface()
        }
        .sheet(isPresented: $isCoffeeConciergePresented) {
            coffeeConciergeSheet
                .tallaSystemSheetSurface()
        }
        .fullScreenCover(isPresented: $isCheckoutPresented, onDismiss: presentPendingPayment) {
            checkoutView
                .environment(\.locale, Locale(identifier: appLanguage.localeIdentifier))
                .environment(\.layoutDirection, appLanguage.layoutDirection)
        }
        .fullScreenCover(isPresented: $isPostPaymentPresented) {
            postPaymentView
        }
        .fullScreenCover(isPresented: $isAccountOnboardingPresented) {
            accountOnboardingView
                .interactiveDismissDisabled(true)
        }
        .alert(AppLocalization.text("empty_bag_confirmation_title", fallback: "Empty bag?"), isPresented: $isConfirmingEmptyBag) {
            Button(AppLocalization.text("cancel", fallback: "Cancel"), role: .cancel) {
                pendingCartRemovalID = nil
            }

            Button(AppLocalization.text("remove", fallback: "Remove"), role: .destructive) {
                if let pendingCartRemovalID {
                    removeFromCart(id: pendingCartRemovalID)
                }
                pendingCartRemovalID = nil
            }
        } message: {
            Text(AppLocalization.text("empty_bag_confirmation_message", fallback: "Remove the last item from your bag?"))
        }
        .confirmationDialog("Replace current bag?", isPresented: $isConfirmingCartReplacement, titleVisibility: .visible) {
            Button("Replace bag and continue", role: .destructive) {
                let action = pendingCartReplacementAction
                pendingCartReplacementAction = nil
                clearBagForNewFlow()
                action?()
            }
            Button("Keep current bag", role: .cancel) {
                pendingCartReplacementAction = nil
            }
        } message: {
            Text("These items can’t be checked out together. Replace the \(cartCount) item\(cartCount == 1 ? "" : "s") in your bag to start \(pendingCartReplacementFlowName)?")
        }
#if canImport(PassKit)
        .sheet(item: $loyaltyWalletPass, onDismiss: {
            Task {
                await refreshWalletPassPresence()
            }
        }) { item in
            WalletPassView(pass: item.pass)
        }
#endif
    }

    var operationalBlockerView: some View {
        let release = remoteAppSettings?.release
        let title = requiresAppUpdate
            ? (isArabicInterface ? "يرجى تحديث التطبيق" : "Update required")
            : (isArabicInterface ? release?.titleAR : release?.titleEN)
        let message = requiresAppUpdate
            ? (isArabicInterface ? release?.updateMessageAR : release?.updateMessageEN)
            : (isArabicInterface ? release?.messageAR : release?.messageEN)

        return ZStack {
            pageBackgroundColor.ignoresSafeArea()
            VStack(spacing: 18) {
                Image(systemName: requiresAppUpdate ? "arrow.down.app.fill" : "cup.and.saucer.fill")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundColor(TallaTheme.Colors.ink)
                Text(title ?? "Talla")
                    .font(displayFont(size: 32))
                    .foregroundColor(primaryTextColor)
                    .multilineTextAlignment(.center)
                Text(message ?? "Please try again shortly.")
                    .font(bodyFont(size: 15))
                    .foregroundColor(secondaryTextColor)
                    .multilineTextAlignment(.center)
                if requiresAppUpdate,
                   let urlString = release?.appStoreURL,
                   let url = URL(string: urlString),
                   !urlString.isEmpty {
                    Button(isArabicInterface ? "التحديث من App Store" : "Update on the App Store") {
                        openURL(url)
                    }
                    .buttonStyle(.tallaPrimary)
                    .tint(TallaTheme.Colors.ink)
                }
            }
            .padding(28)
        }
    }

    func resetPaymentFlowAfterCheckoutDismiss() {
        if let eazyShopifyBrowserKind {
            self.eazyShopifyBrowserKind = nil
            paymentFlow.transition(to: .processing)
            presentPostPayment()
            Task {
                await waitForEazyShopifyProgress(openHostedCheckout: eazyShopifyBrowserKind == .shopifyEazy)
            }
            return
        }
        if paymentFlow.selectedMethod == .clickToPay,
           !postPaymentOrderID.isEmpty,
           paymentFlow.state == .awaitingCustomer {
            paymentFlow.transition(to: .processing)
            presentPostPayment()
            Task {
                await waitForClickToPayProgress()
            }
            return
        }
        if paymentFlow.state == .awaitingCustomer {
            paymentFlow.reset()
        }
    }

    @MainActor
    func waitForEazyShopifyProgress(openHostedCheckout: Bool) async {
        for attempt in 0 ..< 20 {
            let completed = await refreshActiveEazyShopifyPayment(openHostedCheckout: openHostedCheckout)
            if completed || checkoutSession != nil { return }
            if attempt < 19 {
                try? await Task.sleep(for: .seconds(1.5))
            }
        }
        paymentFlow.transition(to: .processing)
        showToast(message: AppLocalization.text("payment_verifying", fallback: "Payment is still being verified. You can safely return later."))
    }

    @MainActor
    @discardableResult
    func refreshActiveEazyShopifyPayment(openHostedCheckout: Bool) async -> Bool {
        let paymentID = activeEazyShopifyPaymentID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !paymentID.isEmpty else { return true }
        do {
            let status = try await AccountService.fetchEazyShopifyPaymentStatus(tallaPaymentID: paymentID)
            if status.paid || status.status == "PAID" {
                activeEazyShopifyPaymentID = ""
                cartItems.removeAll()
                requestedSubscriptionPlanType = ""
                appliedVoucher = nil
                voucherCodeInput = ""
                voucherError = nil
                paymentFlow.transition(to: .succeeded)
                await loadOrderHistory()
                if postPaymentOrderID.isEmpty,
                   let shopifyOrderName = status.shopifyOrderName,
                   !shopifyOrderName.isEmpty {
                    postPaymentOrderID = shopifyOrderName
                }
                presentPostPayment()
                return true
            }
            if ["FAILED", "CANCELLED"].contains(status.status) {
                paymentFlow.transition(to: status.status == "CANCELLED" ? .cancelled : .failed, error: status.message)
                presentPostPayment()
                return true
            }
            if openHostedCheckout, let paymentURL = status.paymentUrl {
                paymentFlow.transition(to: .awaitingCustomer)
                eazyShopifyBrowserKind = .eazyHosted
                checkoutSession = CheckoutSession(url: paymentURL, kind: .eazyHosted)
                return true
            }
            paymentFlow.transition(to: .processing)
            return false
        } catch {
            checkoutError = customerFacingServiceMessage(
                for: error,
                fallback: AppLocalization.text("payment_verification_unavailable", fallback: "Payment verification is temporarily unavailable.")
            )
            return false
        }
    }

    func resetPaymentFlowAfterBenefitPayDismiss() {
        if paymentFlow.state == .awaitingCustomer {
            paymentFlow.cancel()
        }
    }

    func resetPaymentFlowAfterMastercardDismiss() {
        if paymentFlow.state == .succeeded {
            cartItems.removeAll()
            requestedSubscriptionPlanType = ""
            appliedVoucher = nil
            voucherCodeInput = ""
            voucherError = nil
            Task {
                await loadOrderHistory()
                if !loyaltyEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await loadLoyaltyAccount()
                }
            }
            presentPostPayment()
            return
        }
        paymentFlow.reset()
    }

    @ViewBuilder
    var appTabView: some View {
        GeometryReader { proxy in
            if isCompactSinglePaneDisplay(proxy) {
                duoOuterTabView
            } else if #available(iOS 18.0, *) {
                baseTabView
                    .tabViewStyle(.sidebarAdaptable)
            } else {
                baseTabView
            }
        }
    }

    /// The Duo outer display is tall and narrow, but it has enough width for
    /// the app to use edge-to-edge. A custom collapsed chooser keeps that
    /// width available instead of reserving it for the adaptable sidebar.
    func isCompactSinglePaneDisplay(_ proxy: GeometryProxy) -> Bool {
        proxy.size.width >= 350
            && proxy.size.width < 600
            && proxy.size.height > proxy.size.width * 1.18
    }

    var duoOuterTabView: some View {
        ZStack(alignment: .topTrailing) {
            ZStack {
                tabScreen(tab: .home) { homeView }
                    .opacity(activeTab == .home ? 1 : 0)
                tabScreen(tab: .shop) { shopView }
                    .opacity(activeTab == .shop ? 1 : 0)
                tabScreen(tab: .brewing) { brewingView }
                    .opacity(activeTab == .brewing ? 1 : 0)
                tabScreen(tab: .discover) { discoverView }
                    .opacity(activeTab == .discover ? 1 : 0)
                tabScreen(tab: .account) { accountView }
                    .opacity(activeTab == .account ? 1 : 0)
            }
            .allowsHitTesting(!isDuoTabChooserExpanded)

            DuoOuterTabChooser(
                activeTab: $activeTab,
                isExpanded: $isDuoTabChooserExpanded,
                title: { tab in
                    switch tab {
                    case .home: AppLocalization.text("home", fallback: "Home")
                    case .shop: AppLocalization.text("shop", fallback: "Shop")
                    case .brewing: AppLocalization.text("brew", fallback: "Brew")
                    case .discover: AppLocalization.text("discover", fallback: "Discover")
                    case .account: AppLocalization.text("account", fallback: "Account")
                    case .search: "Search"
                    }
                }
            )
        }
        .toolbar(.hidden, for: .tabBar)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: activeTab)
    }

    @ViewBuilder
    var baseTabView: some View {
        if #available(iOS 18.0, *) {
            modernTabView
        } else {
            legacyTabView
        }
    }

    @available(iOS 18.0, *)
    var modernTabView: some View {
        TabView(selection: $activeTab) {
            SwiftUI.Tab(
                AppLocalization.text("home", fallback: "Home"),
                systemImage: Tab.home.systemImage,
                value: Tab.home
            ) {
                tabScreen(tab: .home) {
                    homeView
                }
                .accessibilityIdentifier("tab.home")
            }
            SwiftUI.Tab(
                AppLocalization.text("shop", fallback: "Shop"),
                systemImage: Tab.shop.systemImage,
                value: Tab.shop
            ) {
                tabScreen(tab: .shop) {
                    shopView
                }
                .accessibilityIdentifier("tab.shop")
            }

            SwiftUI.Tab(
                AppLocalization.text("brew", fallback: "Brew"),
                systemImage: Tab.brewing.systemImage,
                value: Tab.brewing
            ) {
                tabScreen(tab: .brewing) {
                    brewingView
                }
                .accessibilityIdentifier("tab.brewing")
            }

            SwiftUI.Tab(
                AppLocalization.text("discover", fallback: "Discover"),
                systemImage: Tab.discover.systemImage,
                value: Tab.discover
            ) {
                tabScreen(tab: .discover) {
                    discoverView
                }
                .accessibilityIdentifier("tab.discover")
            }

            SwiftUI.Tab(
                AppLocalization.text("account", fallback: "Account"),
                systemImage: Tab.account.systemImage,
                value: Tab.account
            ) {
                tabScreen(tab: .account) {
                    accountView
                }
                .accessibilityIdentifier("tab.account")
            }
        }
        .toolbar(.visible, for: .tabBar)
        .tallaAdaptiveTabBarBackground()
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: activeTab)
    }

    var legacyTabView: some View {
        TabView(selection: $activeTab) {
            tabScreen(tab: .home) { homeView }
                .tag(Tab.home)
                .accessibilityIdentifier("tab.home")
                .tabItem {
                    Label(AppLocalization.text("home", fallback: "Home"), systemImage: Tab.home.systemImage)
                }

            tabScreen(tab: .shop) { shopView }
                .tag(Tab.shop)
                .accessibilityIdentifier("tab.shop")
                .tabItem {
                    Label(AppLocalization.text("shop", fallback: "Shop"), systemImage: Tab.shop.systemImage)
                }

            tabScreen(tab: .brewing) { brewingView }
                .tag(Tab.brewing)
                .accessibilityIdentifier("tab.brewing")
                .tabItem {
                    Label(AppLocalization.text("brew", fallback: "Brew"), systemImage: Tab.brewing.systemImage)
                }
            tabScreen(tab: .discover) { discoverView }
                .tag(Tab.discover)
                .accessibilityIdentifier("tab.discover")
                .tabItem {
                    Label(AppLocalization.text("discover", fallback: "Discover"), systemImage: Tab.discover.systemImage)
                }

            tabScreen(tab: .account) { accountView }
                .tag(Tab.account)
                .accessibilityIdentifier("tab.account")
                .tabItem {
                    Label(AppLocalization.text("account", fallback: "Account"), systemImage: Tab.account.systemImage)
                }

        }
        .toolbar(.visible, for: .tabBar)
        .tallaAdaptiveTabBarBackground()
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: activeTab)
    }

    func tabScreen<Content: View>(tab: Tab, @ViewBuilder content: @escaping () -> Content) -> some View {
        NavigationStack {
            tabScrollContent(tab: tab, content: content)
                .toolbar {
                    if #available(iOS 27.0, *) {
                        ToolbarItem(placement: .primaryAction) {
                            if tab == .home || tab == .shop {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.18)) { cartOpen = true }
                                } label: {
                                    Label(AppLocalization.text("bag", fallback: "Bag"), systemImage: "bag")
                                }
                                .badge(cartCount)
                                .accessibilityIdentifier("navigation.bag")
                                .accessibilityValue(String(cartCount))
                            }
                        }
                        ToolbarItem(placement: .secondaryAction) {
                            appearanceMenu
                        }
                    }
                }
                .toolbar(usesSystemNavigationActions ? .visible : .hidden, for: .navigationBar)
                .modifier(DuoToolbarBehavior())
                .tallaAdaptiveNavigationBarBackground(systemChrome: usesSystemNavigationActions)
        }
    }

    func tabScrollContent<Content: View>(tab: Tab, @ViewBuilder content: @escaping () -> Content) -> some View {
        DuoSafePane {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            Color.clear
                                .frame(height: 0)
                                .id("tab-top")
                            if tab == .home {
                                header
                            }
                            // Keep each tab's view identity and local state while resizing.
                            content()
                            Color.clear
                                .frame(height: bottomScrollPadding(for: tab))
                        }
                        .padding(.top, topScrollPadding(for: tab))
                    }
                    .safeAreaPadding(.top, tab == .home ? 1 : 0)
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: accountScrollTarget) { _, target in
                        guard activeTab == .account, let target else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                proxy.scrollTo(target, anchor: .top)
                            }
                            accountScrollTarget = nil
                        }
                    }
                    .onChange(of: tabScrollTarget) { _, target in
                        guard activeTab == tab, target == tab else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            withAnimation(.easeInOut(duration: 0.28)) {
                                proxy.scrollTo("tab-top", anchor: .top)
                            }
                            tabScrollTarget = nil
                        }
                    }
                    .onChange(of: shopCatalogueScrollRequest) { _, _ in
                        guard activeTab == .shop, tab == .shop else { return }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            withAnimation(.easeInOut(duration: 0.28)) {
                                proxy.scrollTo("shop-catalogue", anchor: .top)
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity)
        .background(pageBackgroundColor)
    }

    var tabBarBackgroundColor: Color {
        if isLightAppearance {
            return TallaTheme.Colors.lightElevatedSurface.opacity(0.98)
        }
        return isOLEDAppearance ? .black : TallaTheme.Colors.darkSurface.opacity(0.98)
    }

    var discoverView: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TALLA SPECIALITY")
                    .font(labelFont(size: 11, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(readableBrandGoldColor)
                Text("Find your next coffee moment.")
                    .font(displayFont(size: 30))
                    .foregroundStyle(primaryTextColor)
                Text("Explore cafés, roasters, community, and the wider coffee world.")
                    .font(bodyFont(size: 15))
                    .foregroundStyle(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 18)

            clubView

            VStack(spacing: 12) {
                if remoteAppSettings?.appFeatures?.showGulfCoffeeMap != false {
                    NavigationLink {
                        gulfCoffeeMapView
                    } label: {
                        discoverNavigationRow(
                            title: "Gulf Coffee Map",
                            detail: "Find cafés, roasters and places carrying Talla beans.",
                            systemImage: "map.fill"
                        )
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    SocialCoffeeView(
                        accent: TallaTheme.Colors.accent,
                        background: pageBackgroundColor,
                        surface: cardFillColor,
                        primary: primaryTextColor,
                        secondary: secondaryTextColor,
                        products: products,
                        isSignedIn: customerProfile != nil,
                        cartCount: cartCount,
                        hasItemsInBag: { !cartItems.isEmpty },
                        canContinueGiftShopping: {
                            isGiftOrder && !isCoffeeClubPrepaid && !isCafePassPrepaid
                                && !cartItems.contains(where: { $0.product.isGiftCardProduct })
                        },
                        clearBagAction: clearBagForNewFlow,
                        openCartAction: { cartOpen = true },
                        accountAction: {
                            accountScrollTarget = nil
                            openTab(.account)
                        },
                        addGiftCardAction: { product, variantID, recipientName, recipientEmail, recipientMessage in
                            guard cartItems.isEmpty else {
                                showToast(message: "Finish your current bag before starting a gift-card checkout.")
                                cartOpen = true
                                return
                            }
                            requestedSubscriptionPlanType = ""
                            selectedVariantIDs[product.id] = variantID
                            giftRecipientName = recipientName.trimmingCharacters(in: .whitespacesAndNewlines)
                            giftRecipientEmail = recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines)
                            giftMessage = recipientMessage
                            isGiftOrder = true
                            addToCart(product: product)
                            cartOpen = true
                        },
                        addCoffeeGiftAction: { product, variantID, recipientName, recipientMessage in
                            guard cartItems.isEmpty else {
                                showToast(message: "Finish your current bag before sending a coffee gift.")
                                cartOpen = true
                                return
                            }
                            requestedSubscriptionPlanType = ""
                            selectedVariantIDs[product.id] = variantID
                            addToCart(product: product)
                            isCafePassPrepaid = true
                            cafePassCreditCount = 1
                            suspendedCoffeePass = true
                            isGiftOrder = true
                            giftRecipientName = recipientName
                            giftRecipientPhone = ""
                            giftMessage = recipientMessage
                            fulfillmentMethod = .pickup
                            cartOpen = true
                        },
                        addSuspendedCoffeeAction: { product, variantID, count in
                            guard cartItems.isEmpty else {
                                showToast(message: "Finish your current bag before sponsoring counter coffees.")
                                cartOpen = true
                                return
                            }
                            requestedSubscriptionPlanType = ""
                            selectedVariantIDs[product.id] = variantID
                            addToCart(product: product)
                            isCafePassPrepaid = true
                            cafePassCreditCount = count
                            suspendedCoffeePass = true
                            isGiftOrder = false
                            fulfillmentMethod = .pickup
                            cartOpen = true
                        },
                        shopAction: { category in
                            let canAddToCurrentGift = ["coffee-beans", "coffee-equipment"].contains(category)
                                && isGiftOrder && !isCoffeeClubPrepaid && !isCafePassPrepaid
                                && !cartItems.contains(where: { $0.product.isGiftCardProduct })
                            guard cartItems.isEmpty || canAddToCurrentGift else {
                                showToast(message: "Finish or clear your current bag before starting a Social Coffee gift.")
                                cartOpen = true
                                return
                            }
                            requestedSubscriptionPlanType = ""
                            isGiftOrder = true
                            openShop(category: category)
                        },
                        openGroupAction: { id in
                            socialCoffeeInvite = SocialCoffeeInvite(id: id, inviteCode: "")
                        }
                    )
                } label: {
                    discoverNavigationRow(
                        title: "Social Coffee",
                        detail: "Send, gift, gather, and keep your coffee people close.",
                        systemImage: "person.2.wave.2.fill"
                    )
                }
                .buttonStyle(.plain)

            }
            .padding(.horizontal, 18)
        }
        .padding(.top, 18)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(pageBackgroundColor)
        .navigationTitle(AppLocalization.text("discover", fallback: "Discover"))
        .navigationBarTitleDisplayMode(.large)
    }

    func discoverNavigationRow(title: String, detail: String, systemImage: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(readableBrandGoldColor)
                .frame(width: 48, height: 48)
                .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.14 : 0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                Text(detail)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(tertiaryTextColor)
        }
        .padding(16)
        .tallaCard(.standard, cornerRadius: TallaTheme.CornerRadius.card)
    }

    func topScrollPadding(for tab: Tab) -> CGFloat {
        tab == .account ? 8 : 0
    }

    func bottomScrollPadding(for tab: Tab) -> CGFloat {
        switch tab {
        case .home: 36
        case .account: 56
        default: 28
        }
    }
}

/// Keeps a single-column screen inside one physical Duo pane when iOS reports
/// a vertical division region. This is intentionally conservative: a feed or
/// form is easier to use in one uninterrupted pane than split across the hinge.
struct DuoSafePane<Content: View>: View {
    @Environment(\.layoutDirection) private var layoutDirection
    @ViewBuilder let content: () -> Content

    var body: some View {
        GeometryReader { proxy in
            let division = Self.division(in: proxy)
            let isVerticalDivision = division.width > 0 && division.height > division.width
            let isHorizontalDivision = division.height > 0 && division.width > division.height
            let leadingWidth = max(0, division.minX - 24)
            let trailingWidth = max(0, proxy.size.width - division.maxX - 24)
            let paneWidth = layoutDirection == .rightToLeft ? trailingWidth : leadingWidth
            let topHeight = max(0, division.minY - 24)

            Group {
                if isVerticalDivision && paneWidth >= 280 {
                    content()
                        .frame(width: paneWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: layoutDirection == .rightToLeft ? .trailing : .leading)
                } else if isHorizontalDivision && topHeight >= 280 {
                    content()
                        .frame(maxHeight: topHeight, alignment: .top)
                        .frame(maxHeight: .infinity, alignment: .top)
                } else {
                    content()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private static func division(in proxy: GeometryProxy) -> CGRect {
        guard #available(iOS 27.1, *) else { return .zero }

        return proxy.reservedRegions(kind: .division)
            .map(\.frame)
            .first(where: {
                let verticalDivision = $0.height > $0.width
                    && $0.minX > 0
                    && $0.maxX < proxy.size.width
                    && $0.width < proxy.size.width * 0.25
                let horizontalDivision = $0.width > $0.height
                    && $0.minY > 0
                    && $0.maxY < proxy.size.height
                    && $0.height < proxy.size.height * 0.25
                return verticalDivision || horizontalDivision
            }) ?? .zero
    }
}

private struct DuoOuterTabChooser: View {
    @Binding var activeTab: ContentView.Tab
    @Binding var isExpanded: Bool
    let title: (ContentView.Tab) -> String

    private let tabs: [ContentView.Tab] = [.home, .shop, .brewing, .discover, .account]

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(tabs.filter { $0 != .home }) { tab in
                        railButton(systemImage: tab.systemImage, label: title(tab)) {
                            activeTab = tab
                            withAnimation(.easeOut(duration: 0.18)) {
                                isExpanded = false
                            }
                        }
                        .accessibilityAddTraits(activeTab == tab ? .isSelected : [])
                    }
                }
                .padding(.top, 8)
                .transition(.scale.combined(with: .opacity))
            }

            railButton(systemImage: "house.fill", label: title(.home)) {
                if activeTab == .home {
                    withAnimation(.easeOut(duration: 0.18)) {
                        isExpanded.toggle()
                    }
                } else {
                    activeTab = .home
                    withAnimation(.easeOut(duration: 0.18)) {
                        isExpanded = false
                    }
                }
            }
            .accessibilityHint(activeTab == .home ? "Show app tabs" : "Go to Home")
            .accessibilityAddTraits(activeTab == .home ? .isSelected : [])

            Circle()
                .fill(Color.black)
                .frame(width: 36, height: 36)
                .padding(.top, 8)
                .accessibilityHidden(true)
        }
        .padding(.top, 24)
        .padding(.trailing, 18)
        .padding(.bottom, 28)
        .frame(maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
    }

    private func railButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: 52, height: 52)
                .foregroundStyle(TallaTheme.Colors.ink)
                .background(
                    Circle()
                        .fill(activeTab == .home && label == title(.home) ? .white : .white.opacity(0.76))
                )
                .overlay {
                    Circle()
                        .stroke(TallaTheme.Colors.ink.opacity(0.10), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
