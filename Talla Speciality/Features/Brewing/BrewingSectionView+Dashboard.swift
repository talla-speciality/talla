import Foundation
import SwiftUI
#if canImport(PhotosUI)
import PhotosUI
#endif
#if canImport(FoundationModels)
import FoundationModels
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(WatchConnectivity) && os(iOS)
import WatchConnectivity
#endif
#if canImport(UIKit)
import UIKit
#endif


extension BrewingSectionView {
    var brewingDashboardContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            primaryBrewActionCard
            dashboardContinueSection
            dashboardSavedRecipesSection
            dashboardQuickToolsSection
            dashboardBrowseMethodsSection
        }
    }

    var primaryBrewActionCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0x2B170F))
                    .frame(width: 46, height: 46)
                    .background(accentColor)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalization.text("create_brew_recipe", fallback: "Create a Brew Recipe"))
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 25 : 30))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(AppLocalization.text("create_brew_recipe_detail", fallback: "Tell Talla about your coffee, equipment, and taste goal. We’ll build a recipe around them."))
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button {
                    activeDashboardDestination = .createRecipe
                } label: {
                    Label(AppLocalization.text("create_recipe", fallback: "Create Recipe"), systemImage: "plus")
                        .font(Font.custom("AvenirNext-Bold", size: 12))
                        .tracking(AppLocalization.letterSpacing(1.2))
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                        .foregroundColor(Color(hex: 0x2B170F))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(accentColor)
                        .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)

                if coffeeMemoryEnabled && roastDateOCREnabled {
                    Button {
                        activeDashboardDestination = .scanCoffeeBag
                    } label: {
                    Text(AppLocalization.text("scan_coffee_bag", fallback: "Scan Coffee Bag"))
                        .font(Font.custom("AvenirNext-Bold", size: 12))
                        .tracking(AppLocalization.letterSpacing(1.2))
                        .textCase(.uppercase)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .foregroundColor(primaryTextColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(cardFillColor)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(accentColor.opacity(0.22), lineWidth: 1)
                        )
                        .clipShape(Capsule(style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    var dashboardContinueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashboardSectionTitle(
                isBrewModeRunning || brewModeElapsedSeconds > 0
                    ? AppLocalization.text("continue_active_brew", fallback: "Continue Brew")
                    : AppLocalization.text("brew_again", fallback: "Brew Again")
            )

            let latest = brewHistoryItems.first
            Button {
                if let latest {
                    applySavedRecipe(latest, start: true)
                } else if let profile = selectedGuideProfile {
                    applyGuideProfile(profile, start: true)
                } else {
                    isFocusedBrewPresented = true
                }
            } label: {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(latest?.title ?? currentBrewRecipeTitle)
                                .font(Font.custom("Georgia-Bold", size: isCompact ? 21 : 24))
                                .foregroundColor(primaryTextColor)
                                .lineLimit(2)
                                .minimumScaleFactor(0.82)

                            Text(dashboardBrewMetaLine(for: latest))
                                .font(Font.custom("AvenirNext-Regular", size: 13))
                                .foregroundColor(secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "arrow.forward")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(accentColor)
                            .frame(width: 36, height: 36)
                            .background(accentColor.opacity(0.10))
                            .clipShape(Circle())
                            .accessibilityHidden(true)
                    }

                    HStack(spacing: 8) {
                        dashboardPill("\(formattedRatioValue(latest?.coffeeGrams ?? validCoffeeAmount)) g")
                        dashboardPill("1:\(formattedRatioValue(latest?.ratio ?? validRatioValue))")
                        dashboardPill(AppLocalization.text("last_used_recently", fallback: "Last used recently"))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(accentColor.opacity(0.16), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    var dashboardSavedRecipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashboardSectionTitle(AppLocalization.text("saved_recipes", fallback: "Saved Recipes"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if brewHistoryItems.isEmpty {
                        ForEach(brewGuideProfiles) { profile in
                            savedDashboardProfileCard(profile)
                        }
                    } else {
                        ForEach(Array(brewHistoryItems.prefix(6).enumerated()), id: \.offset) { _, recipe in
                            savedDashboardRecipeCard(recipe)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    var dashboardQuickToolsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashboardSectionTitle(AppLocalization.text("quick_tools", fallback: "Quick Tools"))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 138 : 168), spacing: 12)], spacing: 12) {
                quickToolButton(
                    title: AppLocalization.text("ratio_calculator", fallback: "Ratio Calculator"),
                    detail: AppLocalization.text("ratio_calculator_detail_short", fallback: "Dose and water"),
                    systemImage: "scalemass.fill",
                    destination: .ratioCalculator
                )
                quickToolButton(
                    title: AppLocalization.text("brew_timer", fallback: "Brew Timer"),
                    detail: AppLocalization.text("brew_timer_detail_short", fallback: "Guided pours"),
                    systemImage: "timer",
                    destination: .brewTimer
                )
                quickToolButton(
                    title: AppLocalization.text("coffee_journal", fallback: "Coffee Journal"),
                    detail: AppLocalization.text("coffee_journal_detail_short", fallback: "Taste notes"),
                    systemImage: "book.closed.fill",
                    destination: .coffeeJournal
                )
                quickToolButton(
                    title: AppLocalization.text("brew_coach", fallback: "Brew Coach"),
                    detail: AppLocalization.text("brew_coach_detail_short", fallback: "Tune the cup"),
                    systemImage: "brain.head.profile",
                    destination: .brewCoach
                )
            }
        }
    }

    var dashboardBrowseMethodsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            dashboardSectionTitle(AppLocalization.text("browse_methods", fallback: "Browse Methods"))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 138 : 166), spacing: 12)], spacing: 12) {
                methodFamilyButton(title: AppLocalization.text("pour_over", fallback: "Pour Over"), systemImage: "drop.fill", keywords: ["pour", "v60", "chemex", "filter"])
                methodFamilyButton(title: AppLocalization.text("immersion", fallback: "Immersion"), systemImage: "cylinder.split.1x2.fill", keywords: ["immersion", "press", "aeropress"])
                methodFamilyButton(title: AppLocalization.text("traditional", fallback: "Traditional"), systemImage: "flame.fill", keywords: ["traditional", "arabic", "dallah"])
                methodFamilyButton(title: AppLocalization.text("cold_brew", fallback: "Cold Brew"), systemImage: "snowflake", keywords: ["cold"])
                methodFamilyButton(title: AppLocalization.text("espresso", fallback: "Espresso"), systemImage: "cup.and.saucer.fill", keywords: ["espresso"])
            }
        }
    }

    func dashboardSectionTitle(_ title: String) -> some View {
        Text(title)
            .font(sectionTitleFont)
            .tracking(AppLocalization.letterSpacing(2.2))
            .textCase(.uppercase)
            .foregroundColor(accentColor)
            .accessibilityAddTraits(.isHeader)
    }

    func dashboardPill(_ title: String) -> some View {
        Text(title)
            .font(Font.custom("AvenirNext-Bold", size: 10))
            .tracking(AppLocalization.letterSpacing(0.8))
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.74)
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accentColor.opacity(0.10))
            .clipShape(Capsule(style: .continuous))
    }

    func dashboardBrewMetaLine(for recipe: BrewRecipeRecord?) -> String {
        let method = selectedBrewModeMethod?.name ?? AppLocalization.text("filter", fallback: "Filter")
        let coffee = formattedRatioValue(recipe?.coffeeGrams ?? validCoffeeAmount)
        let ratio = formattedRatioValue(recipe?.ratio ?? validRatioValue)
        return "\(method) · \(coffee) g · 1:\(ratio)"
    }

    func savedDashboardRecipeCard(_ recipe: BrewRecipeRecord) -> some View {
        Button {
            applySavedRecipe(recipe, start: true)
        } label: {
            savedDashboardCardContent(
                title: recipe.title,
                brewer: selectedBrewModeMethod?.name ?? AppLocalization.text("filter", fallback: "Filter"),
                dose: "\(formattedRatioValue(recipe.coffeeGrams ?? validCoffeeAmount)) g",
                ratio: "1:\(formattedRatioValue(recipe.ratio ?? validRatioValue))",
                time: formattedTimerTime(brewModeTotalSeconds),
                rating: AppLocalization.text("saved", fallback: "Saved")
            )
        }
        .buttonStyle(.plain)
    }

    func savedDashboardProfileCard(_ profile: BrewGuideProfile) -> some View {
        Button {
            applyGuideProfile(profile, start: true)
        } label: {
            savedDashboardCardContent(
                title: profile.title,
                brewer: profile.methodKeywords.first?.capitalized ?? AppLocalization.text("filter", fallback: "Filter"),
                dose: "\(formattedRatioValue(profile.coffeeGrams)) g",
                ratio: "1:\(formattedRatioValue(profile.ratio))",
                time: profile.time,
                rating: "4.8"
            )
        }
        .buttonStyle(.plain)
    }

    func savedDashboardCardContent(title: String, brewer: String, dose: String, ratio: String, time: String, rating: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Font.custom("Georgia-Bold", size: 18))
                .foregroundColor(primaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(brewer)
                .font(Font.custom("AvenirNext-Regular", size: 12))
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 5) {
                Text("\(dose) · \(ratio)")
                Text("\(time) · ★ \(rating)")
            }
            .font(Font.custom("AvenirNext-Bold", size: 10))
            .tracking(AppLocalization.letterSpacing(0.8))
            .textCase(.uppercase)
            .foregroundColor(accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.76)

            Spacer(minLength: 0)

            Text(AppLocalization.text("brew", fallback: "Brew"))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .tracking(AppLocalization.letterSpacing(1.2))
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0x2B170F))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(accentColor)
                .clipShape(Capsule(style: .continuous))
        }
        .padding(14)
        .frame(width: 178, height: 178, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    func quickToolButton(title: String, detail: String, systemImage: String, destination: BrewingDashboardDestination) -> some View {
        Button {
            activeDashboardDestination = destination
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 34, height: 34)
                    .background(accentColor.opacity(0.10))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 13))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func methodFamilyButton(title: String, systemImage: String, keywords: [String]) -> some View {
        Button {
            openMethodFamily(keywords: keywords, fallbackCategory: title)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.10))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 13))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 0)

                Image(systemName: "chevron.forward")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(tertiaryTextColor)
                    .accessibilityHidden(true)
            }
            .padding(13)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(cardFillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentColor.opacity(0.14), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func openMethodFamily(keywords: [String], fallbackCategory: String) {
        let method = displayedMethods.first { method in
            let source = ([method.name, method.summary, method.detail] + method.categories)
                .joined(separator: " ")
                .lowercased()
            return keywords.contains { source.contains($0) }
        }

        if let articleURL = method?.articleURL {
            openArticleAction(articleURL)
        } else if let category = brewingCategories.first(where: { $0.localizedCaseInsensitiveContains(fallbackCategory) || fallbackCategory.localizedCaseInsensitiveContains($0) }) {
            activeCategory = category
        }
    }

    func dashboardDestinationView(_ destination: BrewingDashboardDestination) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch destination {
                    case .createRecipe:
                        createBrewRecipeFlow(startsWithScan: false)
                    case .scanCoffeeBag:
                        createBrewRecipeFlow(startsWithScan: true)
                    case .ratioCalculator:
                        goldenRatioSection
                    case .brewTimer:
                        guidedBrewModeSection
                    case .coffeeJournal:
                        coffeeJournalSection
                    case .coffeeLibrary:
                        CoffeeLibraryView(brewCoffeeAction: { coffee in
                            brewRecipeName = coffee.productName
                            selectedPurchasedCoffeeID = coffee.id
                            activeDashboardDestination = .brewTimer
                        }, reorderCoffeeAction: { lot in
                            guard let productID = lot.productID else { return }
                            reorderCoffeeAction(productID)
                        })
                    case .brewCoach:
                        if let selectedGuideProfile {
                            brewCoachCard(for: selectedGuideProfile)
                        }
                    case .espressoWorkspace:
                        EspressoWorkspaceView(accent: accentColor, background: brewBackgroundColor, surface: brewSurfaceColor, primary: brewPrimaryTextColor, secondary: brewSecondaryTextColor)
                    case .cuppingMode:
                        CuppingWorkspaceView(isSignedIn: isCustomerSignedIn, accent: accentColor, background: brewBackgroundColor, surface: brewSurfaceColor, primary: brewPrimaryTextColor, secondary: brewSecondaryTextColor)
                    case .communityRecipes:
                        CommunityRecipesView(isSignedIn: isCustomerSignedIn, accent: accentColor, background: brewBackgroundColor, surface: brewSurfaceColor, primary: brewPrimaryTextColor, secondary: brewSecondaryTextColor)
                    case .privacyControls:
                        PrivacyControlsView(accent: accentColor, background: brewBackgroundColor, primary: brewPrimaryTextColor, secondary: brewSecondaryTextColor)
                    }
                }
                .frame(maxWidth: brewColumnMaxWidth, alignment: .leading)
                .padding(.horizontal, isCompact ? 22 : 28)
                .padding(.vertical, 26)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(brewBackgroundColor.ignoresSafeArea())
            .navigationTitle(destinationTitle(destination))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppLocalization.text("done", fallback: "Done")) {
                        activeDashboardDestination = nil
                    }
                    .font(Font.custom("AvenirNext-Bold", size: 13))
                    .foregroundColor(accentColor)
                }
            }
            .toolbar(.hidden, for: .tabBar)
        }
    }

    func destinationTitle(_ destination: BrewingDashboardDestination) -> String {
        switch destination {
        case .createRecipe:
            return AppLocalization.text("create_recipe", fallback: "Create Recipe")
        case .scanCoffeeBag:
            return AppLocalization.text("scan_coffee_bag", fallback: "Scan Coffee Bag")
        case .ratioCalculator:
            return AppLocalization.text("ratio_calculator", fallback: "Ratio Calculator")
        case .brewTimer:
            return AppLocalization.text("brew_timer", fallback: "Brew Timer")
        case .coffeeJournal:
            return AppLocalization.text("coffee_journal", fallback: "Coffee Journal")
        case .coffeeLibrary:
            return AppLocalization.text("coffee_inventory", fallback: "Coffee Inventory")
        case .brewCoach:
            return AppLocalization.text("brew_coach", fallback: "Brew Coach")
        case .espressoWorkspace:
            return "Espresso Workspace"
        case .cuppingMode:
            return AppLocalization.text("cupping_mode", fallback: "Cupping Mode")
        case .communityRecipes:
            return AppLocalization.text("community_recipes", fallback: "Community Recipes")
        case .privacyControls:
            return AppLocalization.text("privacy_controls", fallback: "Privacy & Explanations")
        }
    }

}
