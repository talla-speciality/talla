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
    var clubView: some View {
        ClubSectionView(
            rewardsContent: AnyView(loyaltySection),
            coffeeSchoolContent: AnyView(CoffeeEducationView()),
            appIconContent: AnyView(appIconPickerCard),
            beansBalance: loyaltyAccount?.pointsBalance ?? 0,
            membershipTier: loyaltyAccount?.tier ?? AppLocalization.text("bronze", fallback: "Bronze"),
            isCustomerSignedIn: customerProfile != nil,
            coffeeClubEnabled: remoteAppSettings?.coffeeClub?.enabled ?? true,
            coffeeClubShipmentCount: configuredCoffeeClubShipmentCount,
            coffeeClubIntervalWeeks: configuredCoffeeClubIntervalWeeks,
            coffeeClubDiscountPercent: configuredCoffeeClubDiscountPercent,
            subscriptionPlans: remoteAppSettings?.coffeeClub?.plans,
            coffeeClubProducts: coffeeClubEligibleProducts,
            memberName: customerProfile?.displayName ?? AppLocalization.text("coffee_friend", fallback: "coffee friend"),
            coffeeClubOrders: orderHistory.filter { $0.details?.coffeeClub != nil },
            seasonalEvents: activeSeasonalEvents,
            savedRecipeCount: brewRecipes.count,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: TallaTheme.Colors.accent,
            pageBackgroundColor: pageBackgroundColor,
            isLightAppearance: isLightAppearance,
            openCoffeeClubAction: {
                requestedSubscriptionPlanType = ""
                activeCategory = "coffee-beans"
                shopSearchQuery = ""
                openTab(.shop)
            },
            openShopCategoryAction: { category in
                requestedSubscriptionPlanType = ""
                activeCategory = category
                shopSearchQuery = ""
                openTab(.shop)
            },
            openSubscriptionPlanAction: { planType, category in
                requestedSubscriptionPlanType = planType
                activeCategory = category
                shopSearchQuery = ""
                openTab(.shop)
            },
            addCoffeeToClubAction: { product, variant, quantity, fulfillment in
                addCoffeeClubToCart(product: product, variant: variant, quantity: quantity, fulfillment: fulfillment)
            }
        )
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
    }

    var cartRewardsSheet: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                loyaltySection
                    .padding(.horizontal, 18)
                    .padding(.top, 20)
                    .padding(.bottom, 28)
            }
            .background(pageBackgroundColor.ignoresSafeArea())
            .navigationTitle(AppLocalization.text("the_talla_club", fallback: "The Talla Club"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCartRewardsPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 32, height: 32)
                            .background(cardFillColor)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))
                }
            }
        }
    }

    var customerAccountSection: some View {
        CustomerAccountSectionView(
            isCompact: isCompact,
            isLightAppearance: isLightAppearance,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            cardFillColor: cardFillColor,
            elevatedSurfaceColor: elevatedSurfaceColor,
            accentColor: TallaTheme.Colors.accent,
            labelFont: labelFont(size: 10, weight: .semibold),
            titleFont: displayFont(size: isCompact ? 28 : 32),
            bodyFont: bodyFont(size: 15),
            sectionTitleFont: labelFont(size: 11, weight: .bold),
            accountAuthMode: $accountAuthMode,
            accountFirstName: $accountFirstName,
            accountLastName: $accountLastName,
            accountEmail: $accountEmail,
            accountPassword: $accountPassword,
            accountConfirmPassword: $accountConfirmPassword,
            isSigningIn: isSigningIn,
            isCreatingAccount: isCreatingAccount,
            isResettingPassword: isResettingPassword,
            isRequestingPasswordResetLink: isRequestingPasswordResetLink,
            isSigningInWithApple: isSigningInWithApple,
            isLoadingCustomer: isLoadingCustomer,
            customerAuthError: customerAuthError,
            customerProfile: customerProfile,
            primaryActionTitle: primaryAccountActionTitle,
            toggleModeAction: { mode in
                switchAccountAuthMode(mode)
            },
            submitAction: {
                Task {
                    if accountAuthMode == .createAccount {
                        await createCustomerAccount()
                    } else if accountAuthMode == .changePassword {
                        await changePasswordWithoutSignIn()
                    } else {
                        await signInCustomer()
                    }
                }
            },
            requestPasswordResetLinkAction: {
                Task {
                    await requestPasswordResetLink()
                }
            },
            configureAppleSignInRequest: configureAppleSignInRequest(_:),
            handleAppleSignInResult: handleAppleSignInResult(_:),
            signedInContent: AnyView(
                Group {
                    if let customerProfile {
                        signedInCustomerCard(customerProfile)
                    }
                }
            )
        )
        .padding(.horizontal, 18)
        .padding(.bottom, 8)
    }

    var primaryAccountActionTitle: String {
        if accountAuthMode == .createAccount {
            return isCreatingAccount
                ? AppLocalization.text("creating_account", fallback: "CREATING ACCOUNT...")
                : AppLocalization.text("create_account", fallback: "CREATE ACCOUNT")
        }

        if accountAuthMode == .changePassword {
            return isResettingPassword
                ? AppLocalization.text("updating_password", fallback: "UPDATING PASSWORD...")
                : AppLocalization.text("change_password", fallback: "CHANGE PASSWORD")
        }

        return isSigningIn || isSigningInWithApple || isLoadingCustomer
            ? AppLocalization.text("signing_in", fallback: "SIGNING IN...")
            : AppLocalization.text("sign_in", fallback: "SIGN IN")
    }

    func signedInCustomerCard(_ profile: ShopifyCustomerProfile) -> some View {
        SignedInCustomerSectionView(
            profile: profile,
            addressesCount: addresses.count,
            orderCount: orderHistory.count,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: TallaTheme.Colors.accent,
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            titleFont: titleFont(size: 24),
            bodyFont: bodyFont(size: 14),
            labelFont: labelFont(size: 11, weight: .bold),
            workspaceColumns: accountWorkspaceColumns,
            signOutAction: {
                signOutCustomer()
            },
            profileSection: AnyView(profileManagementSection),
            passwordSection: AnyView(passwordResetSection),
            orderHistorySection: AnyView(orderHistorySection)
        )
    }

    var profileManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProfileManagementSectionView(
                primaryTextColor: primaryTextColor,
                secondaryTextColor: secondaryTextColor,
                accentColor: TallaTheme.Colors.accent,
                cardFillColor: cardFillColor,
                isLightAppearance: isLightAppearance,
                firstName: $profileFirstName,
                lastName: $profileLastName,
                birthdayMonth: $birthdayMonth,
                birthdayDay: $birthdayDay,
                isSaving: isSavingProfile,
                saveAction: {
                    await saveProfile()
                }
            )

            accountTasteProfileCard
        }
    }

    var accountTasteProfileCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(readableBrandGoldColor)
                Text(AppLocalization.text("your_taste_profile", fallback: "Taste profile"))
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(AppLocalization.letterSpacing(1.8))
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)
                Spacer()
                Button(AppLocalization.text(tasteProfileConfigured ? "edit" : "taste_setup_action", fallback: tasteProfileConfigured ? "Edit" : "Set your taste")) {
                    openTasteProfileEditor()
                }
                .font(labelFont(size: 10, weight: .bold))
                .foregroundColor(readableBrandGoldColor)
                .buttonStyle(.plain)
            }

            Text(AppLocalization.text(tasteProfileConfigured ? "taste_profile_account_detail" : "taste_profile_setup_detail", fallback: tasteProfileConfigured ? "Talla uses these preferences to shape your home screen, recommendations, and brew suggestions." : "Set your preferences so Talla can learn the cup you like."))
                .font(bodyFont(size: 12))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            if tasteProfileConfigured {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], spacing: 8) {
                    ForEach(tasteProfileLabels, id: \.self) { label in
                        Text(label)
                            .font(labelFont(size: 9, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(elevatedSurfaceColor)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(14)
        .background(cardFillColor)
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(TallaTheme.Colors.accent.opacity(0.14), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var passwordResetSection: some View {
        PasswordResetSectionView(
            primaryTextColor: primaryTextColor,
            accentColor: TallaTheme.Colors.accent,
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            currentPassword: $currentPasswordInput,
            newPassword: $newPasswordInput,
            confirmPassword: $confirmNewPasswordInput,
            isResetting: isResettingPassword,
            resetAction: {
                Task {
                    await resetPassword()
                }
            }
        )
    }

    var orderHistorySection: some View {
        OrderHistorySectionView(
            orders: orderHistory,
            isLoadingOrders: isLoadingOrders,
            ordersError: ordersError,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            accentColor: TallaTheme.Colors.accent,
            cardFillColor: cardFillColor,
            isLightAppearance: isLightAppearance,
            tasteMemoryLookup: tasteMemoryLookup,
            coffeeClubProducts: coffeeClubEligibleProducts,
            cafePassProducts: products.filter { $0.isAvailableForSale && ["ready-made-drinks", "summer-drinks"].contains($0.categoryKey) },
            deliveryAddresses: addresses,
            buyAgainAction: { order in
                buyAgain(order: order)
            },
            saveTasteMemoryAction: { order, item, reaction, tags in
                saveTasteMemory(order: order, item: item, reaction: reaction, tags: tags)
            },
            pickupDirectionsAction: {
                guard let pickupURL = URL(string: "https://maps.app.goo.gl/PaaVd6sz66JGk4KS9?g_st=ic") else { return }
                openURL(pickupURL)
            },
            browseProductsAction: {
                openShop()
            },
            orderSupportAction: { order in
                var components = URLComponents(url: managedWhatsAppURL, resolvingAgainstBaseURL: false)
                var items = components?.queryItems ?? []
                items.append(URLQueryItem(name: "text", value: String(format: AppLocalization.text("order_support_message", fallback: "Hello Talla, I need help with order %@."), order.title)))
                components?.queryItems = items
                openURL(components?.url ?? managedWhatsAppURL)
            },
            customerOrderAction: { order, action in
                await submitCustomerOrderAction(order: order, action: action)
            },
            manageCoffeeClubAction: { order, action, note, coffeeName, variantID, coffeeItems, address, fulfillmentMethod in
                await manageCoffeeClub(
                    order: order,
                    action: action,
                    note: note,
                    coffeeName: coffeeName,
                    variantID: variantID,
                    address: address,
                    fulfillmentMethod: fulfillmentMethod,
                    coffeeItems: coffeeItems
                )
            },
            swapCafePassAction: { order, variantID in
                await swapCafePassDrink(order: order, variantID: variantID)
            }
        )
    }

    var featuredProducts: some View {
        let freshRoasts = homeFreshRoastProducts
        let showingFreshRoasts = !freshRoasts.isEmpty
        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .lastTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppLocalization.text(showingFreshRoasts ? "recently_roasted" : "roastery_selection", fallback: showingFreshRoasts ? "Just roasted" : "Roastery Selection"))
                        .font(labelFont(size: 10, weight: .semibold))
                        .tracking(AppLocalization.letterSpacing(3))
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)

                    Text(AppLocalization.text(showingFreshRoasts ? "fresh_roast_week" : "signature_roasts", fallback: showingFreshRoasts ? "Freshly roasted this week" : "Signature Roasts"))
                        .font(displayFont(size: 24))
                        .tracking(AppLocalization.letterSpacing(0.5))
                        .foregroundColor(primaryTextColor)
                }

                Spacer(minLength: 12)

                Button {
                    openShop()
                } label: {
                    Label(AppLocalization.text("browse_shop", fallback: "Browse Shop"), systemImage: "arrow.forward")
                        .font(labelFont(size: 11, weight: .bold))
                        .textCase(.uppercase)
                        .foregroundColor(readableBrandGoldColor)
                }
                .buttonStyle(.plain)
            }

            if isLoadingProducts && products.isEmpty {
                productSkeletonGrid(count: isCompact ? 2 : 4)
            } else if let loadingError, products.isEmpty {
                errorSection(message: loadingError)
            } else {
                let roasts = Array((showingFreshRoasts ? freshRoasts : signatureRoastProducts).prefix(4))

                if isCompact {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(roasts) { product in
                                signatureRoastCard(product)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } else {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: dynamicTypeSize.isAccessibilitySize ? 1 : 2),
                        alignment: .leading,
                        spacing: 12
                    ) {
                        ForEach(roasts) { product in
                            signatureRoastCard(product)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .padding(.bottom, 20)
    }

    var collections: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("")
                    .font(labelFont(size: 10, weight: .semibold))
                    .tracking(AppLocalization.letterSpacing(4))
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)

                Text(AppLocalization.text("from_the_roastery", fallback: "FROM THE ROASTERY"))
                    .font(displayFont(size: 28))
                    .tracking(AppLocalization.letterSpacing(1))
                    .foregroundColor(primaryTextColor)

                Text(AppLocalization.text("from_the_roastery_detail", fallback: "A tighter selection of coffees, tools, and gifts shaped around the daily ritual of the roastery."))
                    .font(bodyFont(size: 15))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(columns: collectionGridColumns, spacing: 12) {
                collectionTile(
                    eyebrow: "Signature",
                    name: "Roasted Beans",
                    desc: "Single-origin coffees and house profiles selected for clarity, sweetness, and everyday brewing range.",
                    accent: "Explore the beans that define the Talla cup.",
                    systemImage: "leaf.fill",
                    color: Color(hex: 0x8A5A28),
                    categoryKey: "coffee-beans"
                )
                collectionTile(
                    eyebrow: "Precision",
                    name: "Brewing Tools",
                    desc: "Professional brewers, scales, and tools for a more refined home coffee setup.",
                    accent: "Built for repeatable, cafe-level brewing.",
                    systemImage: "flask.fill",
                    color: Color(hex: 0x315C72),
                    categoryKey: "coffee-equipment"
                )
                collectionTile(
                    eyebrow: "Gifting",
                    name: "Talla Boxes",
                    desc: "Curated gift boxes and roastery bundles prepared for hosting, gifting, and seasonal moments.",
                    accent: "Elegant selections ready to share.",
                    systemImage: "gift.fill",
                    color: Color(hex: 0x6D5C24),
                    categoryKey: "gifts"
                )
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 40)
    }

    var shopView: some View {
        ShopSectionView(
            activeCategoryTitle: activeCategory == "all" ? AppLocalization.text("full_catalog", fallback: "Full catalog") : categoryLabel(for: activeCategory),
            availableCategories: availableCategories,
            filteredProducts: filteredProducts,
            allProductsAreEmpty: products.isEmpty,
            isLoadingProducts: isLoadingProducts,
            loadingError: loadingError,
            showsCoffeeClubIntroduction: remoteAppSettings?.coffeeClub?.enabled ?? false,
            coffeeClubShipmentCount: configuredCoffeeClubShipmentCount,
            coffeeClubIntervalWeeks: configuredCoffeeClubIntervalWeeks,
            coffeeClubDiscountPercent: configuredCoffeeClubDiscountPercent,
            activeCategory: $activeCategory,
            searchQuery: $shopSearchQuery,
            sortMode: $shopSortMode,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            tertiaryTextColor: tertiaryTextColor,
            cardFillColor: cardFillColor,
            accentColor: TallaTheme.Colors.accent,
            isLightAppearance: isLightAppearance,
            titleFont: displayFont(size: 28),
            sectionTitleFont: displayFont(size: 22),
            bodyFont: bodyFont(size: 15),
            labelFont: labelFont(size: 10, weight: .semibold),
            categoryLabelFont: labelFont(size: 11, weight: .bold),
            categoryBodyFont: bodyFont(size: 13),
            gridColumns: shopProductGridColumns,
            recentSearches: recentSearchQueries,
            quickSearches: quickSearches,
            guidancePanel: AnyView(shopGuidancePanel),
            renderProductCard: { product, showDescription in
                AnyView(productCard(product: product, showDescription: showDescription))
            },
            submitSearch: { query in
                recordRecentSearch(query)
            },
            selectQuickSearch: { query, categoryKey in
                activeCategory = categoryKey
                shopSearchQuery = query
                recordRecentSearch(query)
                shopCatalogueScrollRequest += 1
            },
            clearRecentSearches: {
                savedRecentSearchQueries = ""
            },
            retryLoad: {
                Task {
                    await loadProducts(force: true)
                }
            },
            categorySelected: {
                shopCatalogueScrollRequest += 1
            }
        )
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 22)
    }

    var recentSearchQueries: [String] {
        savedRecentSearchQueries
            .split(separator: "|")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var quickSearches: [(title: String, query: String, categoryKey: String)] {
        [
            (AppLocalization.text("beans", fallback: "Beans"), "beans", "coffee-beans"),
            (AppLocalization.text("summer_boxes", fallback: "Summer Boxes"), "box", "summer-drinks"),
            (AppLocalization.text("gifts", fallback: "Gifts"), "gift", "gifts"),
            (AppLocalization.text("crmb", fallback: "CRMB"), "crmb", "desserts"),
            (AppLocalization.text("equipment", fallback: "Equipment"), "brew", "coffee-equipment"),
            (AppLocalization.text("decaf", fallback: "Decaf"), "decaf", "all"),
            (AppLocalization.text("available", fallback: "In stock"), "available", "all"),
            (AppLocalization.text("budget", fallback: "Budget picks"), "budget", "all"),
            (AppLocalization.text("fruity", fallback: "Fruity"), "fruity", "all"),
            (AppLocalization.text("espresso", fallback: "Espresso"), "espresso", "all"),
            (AppLocalization.text("hosting", fallback: "Hosting"), "hosting", "gifts")
        ]
    }

    func recordRecentSearch(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }

        var queries = recentSearchQueries.filter { $0.localizedCaseInsensitiveCompare(trimmedQuery) != .orderedSame }
        queries.insert(trimmedQuery, at: 0)
        savedRecentSearchQueries = queries.prefix(6).joined(separator: "|")
    }

    var shopGuidancePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            coffeeQuizPanel
        }
    }

    var coffeeQuizPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 34, height: 34)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Circle())

                Text(AppLocalization.text("coffee_quiz_title", fallback: "Find Your Talla"))
                    .font(labelFont(size: 10, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.6)
                    .textCase(.uppercase)
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Button {
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        isCoffeeQuizExpanded.toggle()
                    }
                    delightFeedbackTrigger += 1
                } label: {
                    HStack(spacing: 6) {
                        Text(isCoffeeQuizExpanded
                            ? AppLocalization.text("collapse", fallback: "Close")
                            : AppLocalization.text("start_quiz", fallback: "Start"))
                            .font(labelFont(size: 10, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                            .textCase(.uppercase)

                        Image(systemName: isCoffeeQuizExpanded ? "chevron.up" : "arrow.forward")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(TallaTheme.Colors.accent)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if isCoffeeQuizExpanded {
                quizOptionRow(
                    title: AppLocalization.text("coffee_quiz_brew_question", fallback: "How do you brew?"),
                    options: [
                        ("v60", "V60"),
                        ("espresso", "Espresso"),
                        ("aeropress", "AeroPress"),
                        ("arabic", "Arabic coffee")
                    ],
                    selection: $quizBrewMethod
                )
                .transition(.move(edge: .top).combined(with: .opacity))

                quizOptionRow(
                    title: AppLocalization.text("coffee_quiz_flavor_question", fallback: "What flavours do you enjoy?"),
                    options: [
                        ("chocolate", "Chocolate"),
                        ("fruity", "Fruity"),
                        ("floral", "Floral"),
                        ("caramel", "Caramel")
                    ],
                    selection: $quizFlavor
                )
                .transition(.move(edge: .top).combined(with: .opacity))

                quizOptionRow(
                    title: AppLocalization.text("coffee_quiz_adventure_question", fallback: "How adventurous are you?"),
                    options: [
                        ("comfort", "Keep it familiar"),
                        ("curious", "Curious"),
                        ("wild", "Surprise me")
                    ],
                    selection: $quizAdventure
                )
                .transition(.move(edge: .top).combined(with: .opacity))

                quizOptionRow(title: AppLocalization.text("taste_acidity_title", fallback: "Acidity"), options: [("low", AppLocalization.text("taste_acidity_low", fallback: "Low")), ("balanced", AppLocalization.text("taste_acidity_balanced", fallback: "Balanced")), ("high", AppLocalization.text("taste_acidity_high", fallback: "Bright"))], selection: $tasteProfileAcidity)
                quizOptionRow(title: AppLocalization.text("taste_sweetness_title", fallback: "Sweetness"), options: [("subtle", AppLocalization.text("taste_sweetness_subtle", fallback: "Subtle")), ("sweet", AppLocalization.text("taste_sweetness_sweet", fallback: "Sweet"))], selection: $tasteProfileSweetness)
                quizOptionRow(title: AppLocalization.text("taste_body_title", fallback: "Body"), options: [("light", AppLocalization.text("taste_body_light", fallback: "Light")), ("balanced", AppLocalization.text("taste_body_balanced", fallback: "Balanced")), ("full", AppLocalization.text("taste_body_full", fallback: "Full"))], selection: $tasteProfileBody)
                quizOptionRow(title: AppLocalization.text("taste_roast_title", fallback: "Roast preference"), options: [("light", AppLocalization.text("taste_roast_light", fallback: "Light")), ("medium", AppLocalization.text("taste_roast_medium", fallback: "Medium")), ("dark", AppLocalization.text("taste_roast_dark", fallback: "Dark"))], selection: $tasteProfileRoast)
                quizOptionRow(title: AppLocalization.text("taste_temperature_title", fallback: "Temperature"), options: [("hot", AppLocalization.text("taste_temperature_hot", fallback: "Hot")), ("iced", AppLocalization.text("taste_temperature_iced", fallback: "Iced"))], selection: $tasteProfileTemperature)
                quizOptionRow(title: AppLocalization.text("taste_style_title", fallback: "Coffee style"), options: [("modern", AppLocalization.text("taste_style_modern", fallback: "Modern specialty")), ("arabic", AppLocalization.text("taste_style_arabic", fallback: "Arabic coffee"))], selection: $tasteProfileStyle)

                Text(AppLocalization.text("taste_profile_usage_detail", fallback: "Talla uses this profile to shape your home screen and recommendations. You can change it anytime."))
                    .font(bodyFont(size: 11))
                    .foregroundColor(tertiaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    tasteProfileConfigured = true
                    isCoffeeQuizExpanded = false
                    showToast(message: AppLocalization.text("taste_profile_saved", fallback: "Taste profile saved"))
                } label: {
                    Text(AppLocalization.text("save_taste_profile", fallback: "Save taste profile"))
                        .font(labelFont(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(TallaTheme.Colors.accent)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                if let match = quizMatchedProduct {
                    quizResultCard(match)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Text(AppLocalization.text("coffee_quiz_loading", fallback: "Load the shop once and Talla will match you with a real coffee."))
                        .font(bodyFont(size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
        }
        .padding(isCoffeeQuizExpanded ? 16 : 14)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.16 : 0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    func quizOptionRow(
        title: String,
        options: [(id: String, title: String)],
        selection: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(labelFont(size: 9, weight: .bold))
                .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                .textCase(.uppercase)
                .foregroundColor(readableBrandGoldColor)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 8)], spacing: 8) {
                ForEach(options.indices, id: \.self) { index in
                    let option = options[index]
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selection.wrappedValue = option.id
                        }
                    } label: {
                        Text(option.title)
                            .font(bodyFont(size: 13))
                            .foregroundColor(selection.wrappedValue == option.id ? Color(hex: 0x0A0804) : primaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 10)
                            .background(selection.wrappedValue == option.id ? TallaTheme.Colors.accent : cardFillColor)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(TallaTheme.Colors.accent.opacity(selection.wrappedValue == option.id ? 0 : 0.18), lineWidth: 1)
                            )
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func quizResultCard(_ product: Product) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ProductThumbnail(imageURL: product.imageURL, size: nil, cornerRadius: 12)
                .frame(width: 82, height: 98)

            VStack(alignment: .leading, spacing: 9) {
                Text(AppLocalization.text("coffee_quiz_match_label", fallback: "Your Talla Match"))
                    .font(labelFont(size: 9, weight: .bold))
                    .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.3)
                    .textCase(.uppercase)
                    .foregroundColor(readableBrandGoldColor)

                Text(product.name)
                    .font(titleFont(size: 20))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(quizResultDescription(for: product))
                    .font(bodyFont(size: 14))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 112), spacing: 8)], spacing: 8) {
                    Button {
                        TallaTelemetry.shared.track("recommendation_to_product_conversion", properties: ["source": "taste_quiz", "product": product.name])
                        addToCart(product: product)
                    } label: {
                        Text(AppLocalization.text("add_to_bag", fallback: "Add to Bag"))
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                            .textCase(.uppercase)
                            .foregroundColor(Color(hex: 0x0A0804))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(TallaTheme.Colors.accent)
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!product.isAvailableForSale || selectedVariant(for: product) == nil)

                    Button {
                        openShop(category: product.categoryKey)
                    } label: {
                        Text(AppLocalization.text("see_alternatives", fallback: "See Alternatives"))
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                            .textCase(.uppercase)
                            .foregroundColor(primaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(cardFillColor)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(TallaTheme.Colors.accent.opacity(0.18), lineWidth: 1)
                            )
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button {
                        openBrewing()
                    } label: {
                        Text(AppLocalization.text("start_brewing", fallback: "Start Brew"))
                            .font(labelFont(size: 9, weight: .bold))
                            .tracking(appLanguage.layoutDirection == .rightToLeft ? 0 : 1.2)
                            .textCase(.uppercase)
                            .foregroundColor(primaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.62)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(cardFillColor)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(TallaTheme.Colors.accent.opacity(0.18), lineWidth: 1)
                            )
                            .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(TallaTheme.Colors.accent.opacity(isLightAppearance ? 0.09 : 0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    var quizMatchedProduct: Product? {
        quizCandidateProducts.max { lhs, rhs in
            quizScore(for: lhs) < quizScore(for: rhs)
        }
    }

    var quizCandidateProducts: [Product] {
        let candidates = products.filter {
            $0.categoryKey == "coffee-beans" || $0.categoryKey == "arabic-coffee-beans"
        }

        return candidates.isEmpty ? signatureRoastProducts : candidates
    }

    func quizScore(for product: Product) -> Int {
        let text = product.catalogClassificationText.lowercased()
        var score = 0

        switch quizBrewMethod {
        case "v60":
            score += quizTextScore(text, keywords: ["v60", "filter", "pour", "ethiopia", "guji", "washed", "floral", "berry"])
        case "espresso":
            score += quizTextScore(text, keywords: ["espresso", "brazil", "colombia", "chocolate", "caramel", "nut", "body"])
        case "aeropress":
            score += quizTextScore(text, keywords: ["aeropress", "filter", "balanced", "colombia", "sweet", "clean"])
        case "arabic":
            score += quizTextScore(text, keywords: ["arabic", "shamali", "qahwa", "gahwa", "cardamom", "yemen"])
        default:
            break
        }

        switch quizFlavor {
        case "chocolate":
            score += quizTextScore(text, keywords: ["chocolate", "cocoa", "nut", "brazil", "espresso"])
        case "fruity":
            score += quizTextScore(text, keywords: ["fruit", "fruity", "berry", "citrus", "ethiopia", "guji"])
        case "floral":
            score += quizTextScore(text, keywords: ["floral", "jasmine", "tea", "washed", "ethiopia", "guji"])
        case "caramel":
            score += quizTextScore(text, keywords: ["caramel", "toffee", "brown sugar", "sweet", "colombia"])
        default:
            break
        }

        switch quizAdventure {
        case "comfort":
            score += quizTextScore(text, keywords: ["brazil", "colombia", "classic", "balanced", "chocolate"])
        case "curious":
            score += quizTextScore(text, keywords: ["ethiopia", "colombia", "washed", "single-origin", "sweet"])
        case "wild":
            score += quizTextScore(text, keywords: ["guji", "ethiopia", "natural", "anaerobic", "floral", "berry"])
        default:
            break
        }

        if tasteProfileConfigured {
        switch savedTasteProfile.acidity {
        case "low": score += quizTextScore(text, keywords: ["smooth", "low acid", "chocolate", "nutty", "brazil"])
        case "high": score += quizTextScore(text, keywords: ["bright", "acid", "citrus", "floral", "fruit", "ethiopia"])
        default: score += quizTextScore(text, keywords: ["balanced", "clean", "sweet"])
        }

        switch savedTasteProfile.sweetness {
        case "sweet": score += quizTextScore(text, keywords: ["sweet", "caramel", "honey", "chocolate", "brown sugar"])
        default: score += quizTextScore(text, keywords: ["clean", "tea", "floral"])
        }

        switch savedTasteProfile.body {
        case "light": score += quizTextScore(text, keywords: ["tea", "clean", "floral", "washed"])
        case "full": score += quizTextScore(text, keywords: ["body", "rich", "espresso", "chocolate", "nutty"])
        default: score += quizTextScore(text, keywords: ["balanced", "smooth"])
        }

        switch savedTasteProfile.roast {
        case "light": score += quizTextScore(text, keywords: ["light", "washed", "floral", "fruit"])
        case "dark": score += quizTextScore(text, keywords: ["dark", "bold", "roast", "espresso"])
        default: score += quizTextScore(text, keywords: ["medium", "balanced", "sweet"])
        }

        if savedTasteProfile.temperature == "iced" {
            score += quizTextScore(text, keywords: ["iced", "cold", "summer", "refreshing"])
        }

        if savedTasteProfile.style == "arabic" {
            score += quizTextScore(text, keywords: ["arabic", "qahwa", "cardamom", "yemen", "shamali"])
        } else {
            score += quizTextScore(text, keywords: ["single-origin", "specialty", "washed", "natural"])
        }
        }

        if product.isAvailableForSale {
            score += 3
        }

        return score
    }

    func quizTextScore(_ text: String, keywords: [String]) -> Int {
        keywords.reduce(0) { partialResult, keyword in
            partialResult + (text.contains(keyword) ? 4 : 0)
        }
    }

    func quizResultDescription(for product: Product) -> String {
        let flavorText: String
        switch quizFlavor {
        case "chocolate":
            flavorText = "Chocolate-led, rounded and easy to love"
        case "floral":
            flavorText = "Floral, aromatic and elegant"
        case "caramel":
            flavorText = "Sweet, caramel-like and comforting"
        default:
            flavorText = "Fruity, bright and expressive"
        }

        let brewText: String
        switch quizBrewMethod {
        case "espresso":
            brewText = "espresso"
        case "aeropress":
            brewText = "AeroPress"
        case "arabic":
            brewText = "Arabic coffee"
        default:
            brewText = "V60"
        }

        return "\(flavorText), and a strong fit for \(brewText)."
    }

}
