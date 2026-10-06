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
            .tint(TallaTheme.Colors.accent)
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
                .fill(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.10 : 0.08))
                .frame(width: isCompact ? 260 : 420)
                .blur(radius: 18)
                .offset(x: isCompact ? 150 : 320, y: -280)
                .allowsHitTesting(false)
                .accessibilityHidden(true)

            Circle()
                .fill(Color(hex: 0x7A4F25).opacity(isLightAppearance ? 0.06 : 0.09))
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
        }
        .sheet(item: $socialCoffeeInvite) { invite in
            SocialCoffeeGroupInviteView(invite: invite, products: products, isSignedIn: customerProfile != nil, hasItemsInBag: { !cartItems.isEmpty }, clearBagAction: clearBagForNewFlow, accountAction: {
                accountScrollTarget = nil
                isAccountPresentedFromMore = true
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
        }
        .sheet(item: $socialCoffeePassGift) { gift in
            SocialCoffeePassGiftView(gift: gift)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $isFavoriteShelfPresented) {
            favoriteShelfSheet
        }
        .sheet(isPresented: $isCartRewardsPresented) {
            cartRewardsSheet
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isCoffeeConciergePresented) {
            coffeeConciergeSheet
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
                    .foregroundColor(TallaTheme.Colors.accent)
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
                    .tint(TallaTheme.Colors.accent)
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
        if #available(iOS 18.0, *) {
            baseTabView
                .tabViewStyle(.sidebarAdaptable)
        } else {
            baseTabView
        }
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
                AppLocalization.text("club", fallback: "Club"),
                systemImage: Tab.club.systemImage,
                value: Tab.club
            ) {
                tabScreen(tab: .club) {
                    clubView
                }
                .accessibilityIdentifier("tab.club")
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
                "More",
                systemImage: Tab.more.systemImage,
                value: Tab.more
            ) {
                tabScreen(tab: .more) {
                    moreView
                }
                .accessibilityIdentifier("tab.more")
            }
        }
        .toolbar(.visible, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(tabBarBackgroundColor, for: .tabBar)
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

            tabScreen(tab: .club) { clubView }
                .tag(Tab.club)
                .accessibilityIdentifier("tab.club")
                .tabItem {
                    Label(AppLocalization.text("club", fallback: "Club"), systemImage: Tab.club.systemImage)
                }

            tabScreen(tab: .brewing) { brewingView }
                .tag(Tab.brewing)
                .accessibilityIdentifier("tab.brewing")
                .tabItem {
                    Label(AppLocalization.text("brew", fallback: "Brew"), systemImage: Tab.brewing.systemImage)
                }
            tabScreen(tab: .more) { moreView }
                .tag(Tab.more)
                .accessibilityIdentifier("tab.more")
                .tabItem {
                    Label("More", systemImage: Tab.more.systemImage)
                }

        }
        .toolbar(.visible, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(tabBarBackgroundColor, for: .tabBar)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: activeTab)
    }

    func tabScreen<Content: View>(tab: Tab, @ViewBuilder content: @escaping () -> Content) -> some View {
        NavigationStack {
            tabScrollContent(tab: tab, content: content)
                .toolbar {
                    if #available(iOS 27.1, *) {
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
                .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    func tabScrollContent<Content: View>(tab: Tab, @ViewBuilder content: @escaping () -> Content) -> some View {
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
        .frame(maxWidth: contentMaxWidth)
        .frame(maxWidth: .infinity)
        .background(pageBackgroundColor)
    }

    var tabBarBackgroundColor: Color {
        if isLightAppearance {
            return TallaTheme.Colors.lightElevatedSurface.opacity(0.98)
        }
        return isOLEDAppearance ? .black : Color(hex: 0x100D0A).opacity(0.98)
    }

    var moreView: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("TALLA SPECIALITY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(readableBrandGoldColor)
                Text("Everything in one place.")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(primaryTextColor)
                Text("Explore the Gulf coffee guide or manage your Talla account.")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 12) {
                if remoteAppSettings?.appFeatures?.showGulfCoffeeMap != false {
                    NavigationLink {
                        gulfCoffeeMapView
                    } label: {
                        moreNavigationRow(
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
                            isAccountPresentedFromMore = true
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
                    moreNavigationRow(
                        title: "Social Coffee",
                        detail: "Send, gift, gather, and keep your coffee people close.",
                        systemImage: "person.2.wave.2.fill"
                    )
                }
                .buttonStyle(.plain)

                Button {
                    accountScrollTarget = nil
                    isAccountPresentedFromMore = true
                } label: {
                    moreNavigationRow(
                        title: "Account",
                        detail: "Orders, rewards, saved coffees and settings.",
                        systemImage: "person.fill"
                    )
                }
                .buttonStyle(.plain)
            }

            Text("More from Talla")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(tertiaryTextColor)
                .textCase(.uppercase)
                .tracking(1.1)

            HStack(spacing: 12) {
                moreFeatureTile(title: "Brew", detail: "Dial in", systemImage: "drop.fill") {
                    openTab(.brewing)
                }
                moreFeatureTile(title: "Club", detail: "Earn beans", systemImage: "sparkles") {
                    openTab(.club)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(pageBackgroundColor)
        .sheet(isPresented: $isAccountPresentedFromMore) {
            accountPresentationView
        }
        .navigationTitle("More")
        .navigationBarTitleDisplayMode(.large)
    }

    func moreNavigationRow(title: String, detail: String, systemImage: String) -> some View {
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

    func moreFeatureTile(title: String, detail: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(readableBrandGoldColor)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryTextColor)
                Text(detail)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(secondaryTextColor)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
            .padding(16)
            .tallaCard(.elevated, cornerRadius: TallaTheme.CornerRadius.card)
        }
        .buttonStyle(.plain)
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
