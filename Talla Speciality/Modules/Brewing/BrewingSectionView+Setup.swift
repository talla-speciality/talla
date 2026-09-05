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
    var brewingEditorialHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("the_craft", fallback: "THE CRAFT"))
                .font(brewEyebrowFont)
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(brewAccentColor)

            Text(AppLocalization.text("brewing_methods", fallback: "Brewing Methods"))
                .font(brewSerifTitleFont)
                .foregroundColor(brewPrimaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Text(AppLocalization.text("brewing_intro_dashboard", fallback: "Build, brew, and refine your perfect cup."))
                .font(brewReadingFont)
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    var brewProfileSetupContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            brewProfileProgressHeader

            Group {
                switch brewProfileStep {
                case .experience:
                    createRecipeQuestionStep(
                        question: AppLocalization.text("brew_profile_experience_question", fallback: "How much coffee brewing have you done?"),
                        choices: brewProfileExperienceChoices,
                        selection: $createRecipeExperience
                    )
                case .brewer:
                    VStack(alignment: .leading, spacing: 18) {
                        createRecipeQuestionStep(
                            question: AppLocalization.text("brew_profile_brewer_question", fallback: "What do you brew with?"),
                            choices: brewProfileBrewerChoices,
                            selection: $createRecipeBrewer
                        )

                        if createRecipeBrewer == "other" {
                            searchableBrewerList
                        }
                    }
                default:
                    createRecipeQuestionStep(
                        question: AppLocalization.text("brew_profile_taste_question", fallback: "How do you like your cup?"),
                        choices: brewProfileTasteChoices,
                        selection: $createRecipeTasteGoal
                    )
                }
            }

            brewProfileBottomControls
        }
    }

    var brewProfileProgressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(brewProfileProgressLabel)
                .font(brewEyebrowFont)
                .tracking(2.4)
                .textCase(.uppercase)
                .foregroundColor(brewAccentColor)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(brewBorderColor)
                    Rectangle()
                        .fill(brewAccentColor)
                        .frame(width: max(18, proxy.size.width * brewProfileProgressFraction))
                }
            }
            .frame(height: 2)
        }
        .accessibilityElement(children: .combine)
    }

    var brewingMinimalHomeContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            if isBrewModeRunning || brewModeElapsedSeconds > 0 {
                VStack(alignment: .leading, spacing: 10) {
                    brewSectionLabel(AppLocalization.text("active_brew", fallback: "Active Brew"))
                    brewingLinkedRow(
                        title: AppLocalization.text("continue_active_brew", fallback: "Continue active brew"),
                        detail: currentBrewRecipeTitle,
                        value: formattedBrewElapsedTime
                    ) {
                        isFocusedBrewPresented = true
                    }
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            primaryBrewEntrySection
            brewScaleConnectionSection
            brewingMinimalRecentRecipes
            brewingLibrarySection
            exploreBrewingGuidesSection
        }
    }

    var primaryBrewEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            brewSectionLabel(AppLocalization.text("start_a_brew", fallback: "Start a Brew"))

            VStack(alignment: .leading, spacing: 14) {
                if hasPreviousBrew {
                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                        Text(lastBrewMethodChoice.title)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)

                        Spacer(minLength: 8)

                        Text(formattedLastBrewDate)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(brewSecondaryTextColor)
                    }

                    Text(primaryBrewEntryDescription)
                        .font(brewReadingFont)
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(primaryBrewEntryDescription)
                        .font(brewReadingFont)
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button {
                    if hasPreviousBrew {
                        startLastGuidedBrew()
                    } else {
                        openMethodSelection()
                    }
                } label: {
                    Text(hasPreviousBrew ? AppLocalization.text("brew_again", fallback: "Brew Again") : AppLocalization.text("choose_method", fallback: "Choose Method"))
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
                .buttonStyle(.plain)
                .foregroundColor(brewingColorScheme == .dark ? brewPrimaryTextColor : .white)
                .background(brewAccentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                if hasPreviousBrew {
                    Button {
                        openMethodSelection()
                    } label: {
                        HStack(spacing: 7) {
                            Text(AppLocalization.text("choose_another_method", fallback: "Choose Another Method"))
                            Image(systemName: "arrow.forward")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(brewAccentColor)
                        .frame(maxWidth: .infinity, minHeight: 34)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    var brewScaleConnectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            brewSectionLabel(AppLocalization.text("brew_scale", fallback: "Brew scale"))

            Button {
                isHomeScalePickerPresented = true
            } label: {
                HStack(spacing: 14) {
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [brewAccentColor.opacity(0.20), brewAccentColor.opacity(0.07)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Image(systemName: "scalemass.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(brewAccentColor)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        Circle()
                            .fill(scaleManager.isConnected ? Color.green : brewSecondaryTextColor.opacity(0.45))
                            .frame(width: 9, height: 9)
                            .overlay(Circle().stroke(brewSurfaceColor, lineWidth: 2))
                            .offset(x: 2, y: 2)
                    }
                    .frame(width: 46, height: 46)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(scaleManager.connectedScaleName ?? AppLocalization.text("add_bluetooth_scale", fallback: "Add a Bluetooth scale"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)
                            .lineLimit(1)

                        Text(scaleManager.isConnected
                             ? AppLocalization.text("scale_ready_live", fallback: "Ready for live weight, flow and tare")
                             : AppLocalization.text("scale_optional", fallback: "Optional · guided brewing works without one"))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(brewSecondaryTextColor)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: "chevron.forward")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(brewAccentColor)
                        .frame(width: 32, height: 32)
                        .background(brewAccentColor.opacity(0.09))
                        .clipShape(Circle())
                }
                .padding(15)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(scaleManager.isConnected ? brewAccentColor.opacity(0.46) : brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(scaleManager.isConnected
                ? AppLocalization.text("manage_bluetooth_scale", fallback: "Manage connected Bluetooth scale")
                : AppLocalization.text("add_bluetooth_scale", fallback: "Add a Bluetooth scale"))
            .accessibilityHint(AppLocalization.text("scale_optional_hint", fallback: "Optional. Guided brewing also works without a scale."))
        }
    }

    var primaryBrewEntryDescription: String {
        if hasPreviousBrew {
            return "\(formattedRatioValue(validCoffeeAmount)) g coffee  ·  1:\(formattedRatioValue(validRatioValue)) ratio"
        }

        return AppLocalization.text(
            "start_brew_description",
            fallback: "Choose your brewing method, add your coffee, and build a recipe around it."
        )
    }

    var brewingMinimalRecentRecipes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                guard !brewHistoryItems.isEmpty else { return }
                withAnimation(.easeInOut(duration: 0.22)) {
                    isRecentRecipesExpanded.toggle()
                }
            } label: {
                HStack(spacing: 10) {
                    brewSectionLabel(AppLocalization.text("recent_recipes", fallback: "Recent Recipes"))
                    Spacer(minLength: 8)
                    if !brewHistoryItems.isEmpty {
                        Text("\(min(brewHistoryItems.count, 4))")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(brewSecondaryTextColor)
                        Image(systemName: isRecentRecipesExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(brewSecondaryTextColor)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if brewHistoryItems.isEmpty {
                VStack(spacing: 0) {
                    Text(AppLocalization.text("no_recent_recipes_yet", fallback: "Your recent recipes will appear after your first saved brew."))
                        .font(brewReadingFont)
                        .foregroundColor(brewSecondaryTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                }
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else if isRecentRecipesExpanded {
                VStack(spacing: 0) {
                    let recipes = brewHistoryItems.prefix(4)
                    ForEach(Array(recipes.enumerated()), id: \.offset) { index, recipe in
                        if index > 0 {
                            brewDivider
                        }
                        brewingLinkedRow(title: recipe.title, detail: recipe.detail, value: AppLocalization.text("brew_again", fallback: "Brew Again")) {
                            applySavedRecipe(recipe, start: true)
                        }
                    }
                }
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    var brewingLibrarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            brewSectionLabel(AppLocalization.text("brew_library", fallback: "Brew Library"))
            brewingMinimalShortcuts
        }
    }

    var brewingMinimalShortcuts: some View {
        VStack(spacing: 0) {
            brewingLinkedRow(title: AppLocalization.text("coffee_journal", fallback: "Coffee Journal"), detail: AppLocalization.text("journal_shortcut_detail", fallback: "Review tasting notes and saved cups."), value: nil) {
                activeDashboardDestination = .coffeeJournal
            }
            brewDivider
            brewingLinkedRow(title: AppLocalization.text("saved_equipment", fallback: "Saved Equipment"), detail: savedEquipmentDetail, value: nil) {
                isSavedEquipmentPresented = true
            }
            brewDivider
            brewingLinkedRow(title: AppLocalization.text("tools", fallback: "Tools"), detail: AppLocalization.text("tools_menu_detail", fallback: "Ratio calculator, timer, journal, and brew coach."), value: nil) {
                isToolsMenuPresented = true
            }
        }
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(brewBorderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    var savedEquipmentDetail: String {
        let grinder = recipeGrinder.trimmingCharacters(in: .whitespacesAndNewlines)
        let grinderText = grinder.isEmpty ? AppLocalization.text("add_grinder", fallback: "Add grinder") : grinder
        return "\(brewProfileBrewerName) · \(grinderText)"
    }

    var savedEquipmentEditor: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(AppLocalization.text("saved_equipment", fallback: "Saved Equipment"))
                        .font(brewSerifTitleFont)
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(AppLocalization.text("saved_equipment_detail", fallback: "Save your brewer, grinder, and filter so new recipes start with your setup."))
                        .font(brewReadingFont)
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    brewerSetupSelector
                    catalogPicker(title: AppLocalization.text("grinder", fallback: "Grinder"), selection: $recipeGrinder, options: grinderCatalog, customPlaceholder: "Other grinder")
                    catalogPicker(title: AppLocalization.text("filter", fallback: "Filter"), selection: $recipeFilterType, options: filterCatalog, customPlaceholder: "Other filter")
                }
                .padding(20)
            }
            .background(brewBackgroundColor.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.text("cancel", fallback: "Cancel")) {
                        restoreSavedEquipmentSelections()
                        isSavedEquipmentPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(AppLocalization.text("save", fallback: "Save")) {
                        persistSavedEquipmentSelections()
                        isSavedEquipmentPresented = false
                    }
                }
            }
        }
    }

    var brewingToolsMenu: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    brewingLinkedRow(title: AppLocalization.text("ratio_calculator", fallback: "Ratio Calculator"), detail: AppLocalization.text("ratio_calculator_detail", fallback: "Dose, ratio, and water totals."), value: nil) {
                        isToolsMenuPresented = false
                        activeDashboardDestination = .ratioCalculator
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("brew_timer", fallback: "Brew Timer"), detail: AppLocalization.text("brew_timer_detail", fallback: "A focused timer for manual recipes."), value: nil) {
                        isToolsMenuPresented = false
                        activeDashboardDestination = .brewTimer
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("coffee_journal", fallback: "Coffee Journal"), detail: AppLocalization.text("coffee_journal_detail", fallback: "Taste notes and brew history."), value: nil) {
                        isToolsMenuPresented = false
                        activeDashboardDestination = .coffeeJournal
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("coffee_inventory", fallback: "Coffee Inventory"), detail: AppLocalization.text("coffee_inventory_detail", fallback: "Lots, roast dates, quantities, and sync conflicts."), value: nil) {
                        isToolsMenuPresented = false
                        activeDashboardDestination = .coffeeLibrary
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("brew_coach", fallback: "Brew Coach"), detail: AppLocalization.text("brew_coach_detail", fallback: "Small adjustments for the next cup."), value: nil) {
                        isToolsMenuPresented = false
                        activeDashboardDestination = .brewCoach
                    }
                }
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(22)
            }
            .background(brewBackgroundColor.ignoresSafeArea())
            .navigationTitle(AppLocalization.text("tools", fallback: "Tools"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var brewingMethodSelectionView: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(AppLocalization.text("choose_brewing_method", fallback: "Choose a Brewing Method"))
                            .font(.system(size: 28, weight: .semibold, design: .serif))
                            .foregroundColor(brewPrimaryTextColor)
                            .accessibilityAddTraits(.isHeader)

                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(brewSecondaryTextColor)
                                .accessibilityHidden(true)
                            TextField(AppLocalization.text("search_methods", fallback: "Search methods"), text: $methodSearchText)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .font(.system(size: 16))
                                .submitLabel(.search)
                        }
                        .frame(minHeight: 46)
                        .padding(.horizontal, 14)
                        .background(brewSurfaceColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(brewBorderColor, lineWidth: 1)
                        )
                    }

                    methodCategorySelector

                    if methodSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        methodChoiceSection(
                            title: AppLocalization.text("recent_methods", fallback: "Recent Methods"),
                            methods: recentMethodChoices
                        )
                        methodChoiceSection(
                            title: AppLocalization.text("favourites", fallback: "Favourites"),
                            methods: deduplicatedFavoriteMethodChoices
                        )
                    }

                    methodChoiceSection(
                        title: AppLocalization.text("popular_methods", fallback: "Popular Methods"),
                        methods: deduplicatedFilteredMethodChoices
                    )
                }
                .padding(.horizontal, 22)
                .padding(.top, 24)
                .padding(.bottom, selectedMethodChoice == nil ? 28 : 112)
                .frame(maxWidth: brewColumnMaxWidth, alignment: .leading)
            }
            .background(brewBackgroundColor.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                if let selectedMethodChoice {
                    VStack(spacing: 10) {
                        brewDivider.padding(.leading, 0)
                        Button {
                            beginBrewSetup(with: selectedMethodChoice)
                        } label: {
                            Text(String(format: AppLocalization.text("start_guided_brew_with_method", fallback: "Start guided brew with %@"), selectedMethodChoice.title))
                                .font(.system(size: 16, weight: .semibold))
                                .frame(maxWidth: .infinity, minHeight: 50)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(brewingColorScheme == .dark ? brewPrimaryTextColor : .white)
                        .background(brewAccentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                        Button {
                            beginCustomRecipeSetup(with: selectedMethodChoice)
                        } label: {
                            Text(AppLocalization.text("customize_recipe", fallback: "Customize recipe"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(brewAccentColor)
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(.plain)

                        .padding(.bottom, 4)
                    }
                        .padding(.horizontal, 22)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                        .background(brewBackgroundColor)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLocalization.text("close", fallback: "Close")) {
                        isMethodSelectionPresented = false
                    }
                    .foregroundColor(brewPrimaryTextColor)
                }
            }
        }
    }

    @ViewBuilder
    var methodCategorySelector: some View {
        if horizontalSizeClass == .compact {
            Menu {
                ForEach(methodCategoryFilters, id: \.self) { category in
                    Button {
                        methodCategoryFilter = category
                    } label: {
                        if methodCategoryFilter == category {
                            Label(category, systemImage: "checkmark")
                        } else {
                            Text(category)
                        }
                    }
                }
            } label: {
                HStack {
                    Text(String(format: AppLocalization.text("category_format", fallback: "Category: %@"), methodCategoryFilter))
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(brewPrimaryTextColor)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, minHeight: 46)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(methodCategoryFilters, id: \.self) { category in
                    Button {
                        methodCategoryFilter = category
                    } label: {
                        Text(category)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(methodCategoryFilter == category ? brewAccentColor : brewSecondaryTextColor)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 14)
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(methodCategoryFilter == category ? brewAccentColor : brewBorderColor.opacity(0.45))
                                    .frame(height: methodCategoryFilter == category ? 2 : 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(methodCategoryFilter == category ? .isSelected : [])
                }
            }
        }
        }
    }

    func methodChoiceSection(title: String, methods: [BrewingMethodChoice]) -> some View {
        Group {
            if !methods.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    brewSectionLabel(title)

                    VStack(spacing: 0) {
                        ForEach(Array(methods.enumerated()), id: \.element.id) { index, method in
                            if index > 0 {
                                brewDivider
                            }
                            brewingMethodRow(method)
                        }
                    }
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }

    func brewingMethodRow(_ method: BrewingMethodChoice) -> some View {
        let isSelected = selectedMethodChoiceID == method.id

        return Button {
            selectedMethodChoiceID = method.id
        } label: {
            HStack(alignment: .center, spacing: 14) {
                Image(systemName: method.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(brewAccentColor)
                    .frame(width: 34, height: 34)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(method.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("\(method.category) · \(method.estimatedTime)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(brewSecondaryTextColor)

                    Text(method.description)
                        .font(.system(size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark" : "chevron.forward")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isSelected ? brewAccentColor : brewSecondaryTextColor)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 76)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? brewAccentColor : Color.clear, lineWidth: 1)
                    .padding(4)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    var exploreBrewingGuidesSection: some View {
        Group {
            if !displayedMethods.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            isBrewingGuidesExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            brewSectionLabel(AppLocalization.text("explore_brewing_guides", fallback: "Explore Brewing Guides"))
                            Spacer(minLength: 8)

                            Text("\(displayedMethods.count)")
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(brewSecondaryTextColor)

                            Image(systemName: isBrewingGuidesExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(brewAccentColor)
                                .accessibilityHidden(true)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if isBrewingGuidesExpanded {
                        if displayedMethods.count > 3 {
                            HStack {
                                Spacer(minLength: 0)
                                Button {
                                    withAnimation(.easeInOut(duration: 0.22)) {
                                        areAllBrewingGuidesVisible.toggle()
                                    }
                                } label: {
                                    Text(areAllBrewingGuidesVisible ? AppLocalization.text("show_less", fallback: "Show Less") : AppLocalization.text("view_all", fallback: "View All"))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(brewAccentColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(visibleBrewingGuides.enumerated()), id: \.element.id) { index, method in
                                if index > 0 {
                                    brewDivider
                                }
                                brewingGuideEntryRow(method)
                            }
                        }
                        .background(brewSurfaceColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(brewBorderColor, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }

    var visibleBrewingGuides: [ContentView.BrewingMethod] {
        areAllBrewingGuidesVisible ? displayedMethods : Array(displayedMethods.prefix(3))
    }

    func brewingGuideEntryRow(_ method: ContentView.BrewingMethod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                selectedBrewModeMethodID = method.id
                activeCategory = method.categories.first ?? activeCategory
            } label: {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(method.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(method.summary)
                            .font(.system(size: 14))
                            .foregroundColor(brewSecondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Text(AppLocalization.text("read_guide", fallback: "Read Guide"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(brewAccentColor)

                    Image(systemName: "chevron.forward")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(brewSecondaryTextColor)
                        .accessibilityHidden(true)
                }
                .frame(minHeight: 60)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                beginBrewSetup(with: methodChoice(from: method))
            } label: {
                Text(AppLocalization.text("use_this_method", fallback: "Use This Method"))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    func brewingFactRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(brewEyebrowFont)
                .foregroundColor(brewSecondaryTextColor)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(brewPrimaryTextColor)
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 36)
    }

    var brewDivider: some View {
        Rectangle()
            .fill(brewBorderColor)
            .frame(height: 1)
            .padding(.leading, 18)
    }

    func brewingInlineMessage(_ message: String) -> some View {
        Text(message)
            .font(brewReadingFont)
            .foregroundColor(brewSecondaryTextColor)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 10)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(brewBorderColor)
                    .frame(height: 1)
            }
    }

    func brewSectionLabel(_ title: String) -> some View {
        Text(title)
            .font(brewEyebrowFont)
            .tracking(2)
            .textCase(.uppercase)
            .foregroundColor(brewAccentColor)
    }

    func brewingLinkedRow(title: String, detail: String, value: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(detail)
                        .font(.system(size: 14))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if let value {
                    Text(value)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(brewAccentColor)
                        .multilineTextAlignment(.trailing)
                }

                Image(systemName: "chevron.forward")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(brewSecondaryTextColor)
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 64)
            .padding(.horizontal, 18)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    var formattedBrewElapsedTime: String {
        formattedTimerTime(brewModeElapsedSeconds)
    }

    var hasPreviousBrew: Bool {
        guard isCustomerSignedIn else { return false }
        return storedLastBrewTimestamp > 0 || !storedLastBrewMethodID.isEmpty || !brewHistoryItems.isEmpty
    }

    var formattedLastBrewDate: String {
        guard storedLastBrewTimestamp > 0 else {
            return AppLocalization.text("recently", fallback: "Recently")
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date(timeIntervalSince1970: storedLastBrewTimestamp))
    }

    var methodCategoryFilters: [String] {
        [
            AppLocalization.text("all", fallback: "All"),
            AppLocalization.text("pour_over", fallback: "Pour Over"),
            AppLocalization.text("immersion", fallback: "Immersion"),
            AppLocalization.text("traditional", fallback: "Traditional"),
            AppLocalization.text("espresso", fallback: "Espresso"),
            AppLocalization.text("cold_brew", fallback: "Cold Brew")
        ]
    }

    var popularMethodChoices: [BrewingMethodChoice] {
        [
            BrewingMethodChoice(id: "v60", title: "V60", category: AppLocalization.text("pour_over", fallback: "Pour Over"), estimatedTime: "3–4 min", description: AppLocalization.text("v60_method_description", fallback: "Clear, precise cups with controlled pouring."), systemImage: "triangle"),
            BrewingMethodChoice(id: "solo", title: "SOLO Dripper", category: AppLocalization.text("pour_over", fallback: "Pour Over"), estimatedTime: "3–4 min", description: AppLocalization.text("solo_method_description", fallback: "Balanced filter brews with a steady, forgiving flow."), systemImage: "trapezoid.and.line.vertical"),
            BrewingMethodChoice(id: "kalita", title: "Kalita Wave", category: AppLocalization.text("pour_over", fallback: "Pour Over"), estimatedTime: "3–4 min", description: AppLocalization.text("kalita_method_description", fallback: "Sweet, even cups from a flat-bottom brewer."), systemImage: "line.3.horizontal.decrease"),
            BrewingMethodChoice(id: "chemex", title: "Chemex", category: AppLocalization.text("pour_over", fallback: "Pour Over"), estimatedTime: "4–6 min", description: AppLocalization.text("chemex_method_description", fallback: "Clean texture and clarity for larger brews."), systemImage: "hourglass"),
            BrewingMethodChoice(id: "aeropress", title: "AeroPress", category: AppLocalization.text("immersion", fallback: "Immersion"), estimatedTime: "2–3 min", description: AppLocalization.text("aeropress_method_description", fallback: "Fast, flexible brewing with gentle pressure."), systemImage: "capsule.portrait"),
            BrewingMethodChoice(id: "french-press", title: "French Press", category: AppLocalization.text("immersion", fallback: "Immersion"), estimatedTime: "4–5 min", description: AppLocalization.text("french_press_method_description", fallback: "Full body and a rounded, comforting cup."), systemImage: "cylinder"),
            BrewingMethodChoice(id: "arabic", title: "Arabic Coffee", category: AppLocalization.text("traditional", fallback: "Traditional"), estimatedTime: "8–12 min", description: AppLocalization.text("arabic_method_description", fallback: "Aromatic traditional brewing with gentle heat."), systemImage: "flame.fill"),
            BrewingMethodChoice(id: "v60-iced", title: "V60 Iced", category: AppLocalization.text("cold_brew", fallback: "Cold Brew"), estimatedTime: "2:15", description: "20 g coffee, 180 g hot water, and 120 g ice with three timed pours.", systemImage: "snowflake"),
            BrewingMethodChoice(id: "cold", title: "Cold Brew", category: AppLocalization.text("cold_brew", fallback: "Cold Brew"), estimatedTime: "12–18 hr", description: AppLocalization.text("cold_brew_method_description", fallback: "Slow extraction for a smooth, low-acidity cup."), systemImage: "snowflake"),
            BrewingMethodChoice(id: "espresso", title: "Espresso", category: AppLocalization.text("espresso", fallback: "Espresso"), estimatedTime: "25–35 sec", description: AppLocalization.text("espresso_method_description", fallback: "Concentrated, pressure-brewed coffee with intensity."), systemImage: "cup.and.saucer.fill")
        ]
    }

    var favoriteMethodChoices: [BrewingMethodChoice] {
        let ids = storedFavoriteBrewMethodIDs
            .split(separator: ",")
            .map(String.init)
        let favourites = ids.compactMap { methodChoice(for: $0) }
        return Array(favourites.prefix(3))
    }

    var recentMethodChoices: [BrewingMethodChoice] {
        var ids: [String] = []
        if !storedLastBrewMethodID.isEmpty {
            ids.append(storedLastBrewMethodID)
        }
        ids.append(storedBrewProfileBrewer)
        ids.append(createRecipeBrewer)

        var seen = Set<String>()
        return ids.compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            return methodChoice(for: id)
        }
        .prefix(3)
        .map { $0 }
    }

    var filteredMethodChoices: [BrewingMethodChoice] {
        let search = methodSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allCategory = AppLocalization.text("all", fallback: "All")

        return popularMethodChoices.filter { method in
            let matchesCategory = methodCategoryFilter == allCategory || method.category == methodCategoryFilter
            let matchesSearch = search.isEmpty
                || method.title.lowercased().contains(search)
                || method.category.lowercased().contains(search)
                || method.description.lowercased().contains(search)
            return matchesCategory && matchesSearch
        }
    }

    var deduplicatedFavoriteMethodChoices: [BrewingMethodChoice] {
        let recentIDs = Set(recentMethodChoices.map(\.id))
        return favoriteMethodChoices.filter { !recentIDs.contains($0.id) }
    }

    var deduplicatedFilteredMethodChoices: [BrewingMethodChoice] {
        guard methodSearchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return filteredMethodChoices
        }
        let shownIDs = Set((recentMethodChoices + deduplicatedFavoriteMethodChoices).map(\.id))
        return filteredMethodChoices.filter { !shownIDs.contains($0.id) }
    }

    var selectedMethodChoice: BrewingMethodChoice? {
        methodChoice(for: selectedMethodChoiceID)
    }

    var lastBrewMethodChoice: BrewingMethodChoice {
        methodChoice(for: storedLastBrewMethodID)
            ?? methodChoice(for: storedBrewProfileBrewer)
            ?? popularMethodChoices[0]
    }

    func methodChoice(for id: String) -> BrewingMethodChoice? {
        popularMethodChoices.first { $0.id == id }
    }

    func methodChoice(from method: ContentView.BrewingMethod) -> BrewingMethodChoice {
        if let exact = methodChoice(for: method.id) {
            return exact
        }

        let source = ([method.id, method.name, method.summary, method.detail] + method.categories)
            .joined(separator: " ")
            .lowercased()

        return popularMethodChoices.first { choice in
            source.contains(choice.id) || source.contains(choice.title.lowercased())
        } ?? BrewingMethodChoice(
            id: method.id,
            title: method.name,
            category: method.categories.first ?? AppLocalization.text("all", fallback: "All"),
            estimatedTime: method.brewTime,
            description: method.summary,
            systemImage: "cup.and.saucer"
        )
    }

    func openMethodSelection() {
        if isCustomerSignedIn {
            selectedMethodChoiceID = storedLastBrewMethodID.isEmpty ? storedBrewProfileBrewer : storedLastBrewMethodID
        } else {
            selectedMethodChoiceID = "v60"
        }
        if methodChoice(for: selectedMethodChoiceID) == nil {
            selectedMethodChoiceID = "v60"
        }
        methodSearchText = ""
        methodCategoryFilter = AppLocalization.text("all", fallback: "All")
        isMethodSelectionPresented = true
    }

    func beginBrewSetup(with method: BrewingMethodChoice, rememberSelection: Bool = true) {
        createRecipeBrewer = method.id
        let displayedMethodID = matchingDisplayedMethodID(for: method)
        selectedBrewModeMethodID = displayedMethodID
        let publishedRecipe = displayedMethods.first { $0.id == displayedMethodID }?.publishedRecipe
        applyPublishedRecipeDefaults(for: method.id, publishedRecipe: publishedRecipe)
        if isCustomerSignedIn {
            storedBrewProfileBrewer = method.id
        }
        if isCustomerSignedIn {
            storedLastBrewMethodID = method.id
            if rememberSelection || storedLastBrewTimestamp == 0 {
                storedLastBrewTimestamp = Date().timeIntervalSince1970
            }
        }

        isMethodSelectionPresented = false

        DispatchQueue.main.async {
            if let guidedMethod = displayedMethods.first(where: { $0.id == displayedMethodID }) {
                selectBrewModeMethod(guidedMethod, start: true)
            } else {
                beginCustomRecipeSetup(with: method, rememberSelection: false)
            }
        }
    }

    func beginCustomRecipeSetup(with method: BrewingMethodChoice, rememberSelection: Bool = true) {
        createRecipeBrewer = method.id
        let displayedMethodID = matchingDisplayedMethodID(for: method)
        selectedBrewModeMethodID = displayedMethodID
        let publishedRecipe = displayedMethods.first { $0.id == displayedMethodID }?.publishedRecipe
        applyPublishedRecipeDefaults(for: method.id, publishedRecipe: publishedRecipe)
        if isCustomerSignedIn {
            storedBrewProfileBrewer = method.id
            storedLastBrewMethodID = method.id
            if rememberSelection || storedLastBrewTimestamp == 0 {
                storedLastBrewTimestamp = Date().timeIntervalSince1970
            }
        }

        prepareNewRecipeJourney(startsWithScan: false)
        isMethodSelectionPresented = false

        DispatchQueue.main.async {
            activeDashboardDestination = .createRecipe
        }
    }

    func startLastGuidedBrew() {
        let methodChoice = lastBrewMethodChoice
        createRecipeBrewer = methodChoice.id
        selectedBrewModeMethodID = matchingDisplayedMethodID(for: methodChoice)

        if isCustomerSignedIn {
            storedBrewProfileBrewer = methodChoice.id
            storedLastBrewMethodID = methodChoice.id
            storedLastBrewTimestamp = Date().timeIntervalSince1970
        }

        if let latestRecipe = brewHistoryItems.first {
            applySavedRecipe(latestRecipe, start: true)
        } else if let methodID = selectedBrewModeMethodID,
                  let method = displayedMethods.first(where: { $0.id == methodID }) {
            selectBrewModeMethod(method, start: true)
        } else {
            brewRecipeName = methodChoice.title
            restartBrewMode()
        }
    }

    func applyPublishedRecipeDefaults(for methodID: String, publishedRecipe: ContentView.BrewingMethod.PublishedRecipe?) {
        usePublishedRecipe(publishedRecipe)

        switch methodID {
        case "cold":
            recipeCoffeeDose = "60"
            recipePreferredRatio = "8"
            recipeBrewTemperatureMode = "Cold"
            recipeBloomRatio = "Auto"
            recipePourCount = 2
            generatedGrindDescription = "Coarse"
            generatedTemperatureC = 20
        case "v60-iced":
            recipeCoffeeDose = "20"
            recipePreferredRatio = "15"
            recipeBrewTemperatureMode = "Iced"
            recipeBloomRatio = "Auto"
            recipePourCount = 3
            generatedGrindDescription = "Medium"
            generatedTemperatureC = 93
        default:
            recipeCoffeeDose = "20"
            recipePreferredRatio = "16"
            recipeBrewTemperatureMode = "Hot"
            recipeBloomRatio = "Auto"
            recipePourCount = 3
            generatedTemperatureC = 93
        }

        if let coffeeGrams = publishedRecipe?.coffeeGrams {
            recipeCoffeeDose = formattedRatioValue(coffeeGrams)
        }
        if let ratio = publishedRecipe?.ratio {
            recipePreferredRatio = formattedRatioValue(ratio)
        }
    }

    func usePublishedRecipe(_ publishedRecipe: ContentView.BrewingMethod.PublishedRecipe?) {
        publishedRecipeCoffeeGrams = publishedRecipe?.coffeeGrams
        publishedRecipeWaterGrams = publishedRecipe?.waterGrams
        publishedRecipeIceGrams = publishedRecipe?.iceGrams
    }

    func matchingDisplayedMethodID(for method: BrewingMethodChoice) -> String? {
        let target = method.title.lowercased()
        let id = method.id.lowercased()

        return displayedMethods.first { displayedMethod in
            let source = ([displayedMethod.id, displayedMethod.name, displayedMethod.summary, displayedMethod.detail] + displayedMethod.categories)
                .joined(separator: " ")
                .lowercased()
            return source.contains(id) || source.contains(target) || target.contains(displayedMethod.name.lowercased())
        }?.id
    }

    func continueRecipeDetail(_ latest: BrewRecipeRecord?) -> String {
        if let latest {
            return latest.detail
        }

        if let profile = selectedGuideProfile {
            return "\(formattedRatioValue(profile.coffeeGrams)) g · 1:\(formattedRatioValue(profile.ratio)) · \(profile.time)"
        }

        return "20 g · 1:16 · 3:30"
    }

    var brewProfileExperienceChoices: [BrewChoice] {
        [
            BrewChoice(id: "starting", title: AppLocalization.text("profile_exp_starting", fallback: "Just starting out"), detail: AppLocalization.text("profile_exp_starting_detail", fallback: "Keep the recipe simple and guide every step."), systemImage: "1.circle"),
            BrewChoice(id: "basics", title: AppLocalization.text("profile_exp_basics", fallback: "I know the basics"), detail: AppLocalization.text("profile_exp_basics_detail", fallback: "Give me reliable starting points with room to adjust."), systemImage: "2.circle"),
            BrewChoice(id: "dial", title: AppLocalization.text("profile_exp_dial", fallback: "I dial in my brews"), detail: AppLocalization.text("profile_exp_dial_detail", fallback: "Give me full control over grind, ratio, temperature, and pours."), systemImage: "3.circle"),
            BrewChoice(id: "automatic", title: AppLocalization.text("profile_exp_auto", fallback: "I use an automatic brewer"), detail: AppLocalization.text("profile_exp_auto_detail", fallback: "Build recipes that can be transferred to my equipment."), systemImage: "4.circle")
        ]
    }

    var brewProfileBrewerChoices: [BrewChoice] {
        [
            BrewChoice(id: "v60", title: "V60", detail: AppLocalization.text("v60_profile_detail", fallback: "Clean cone-style pour-over."), systemImage: "triangle"),
            BrewChoice(id: "solo", title: "SOLO Dripper", detail: AppLocalization.text("solo_profile_detail", fallback: "Precise filter brewing."), systemImage: "trapezoid.and.line.vertical"),
            BrewChoice(id: "kalita", title: "Kalita Wave", detail: AppLocalization.text("kalita_profile_detail", fallback: "Flat-bottom balance and sweetness."), systemImage: "line.3.horizontal.decrease"),
            BrewChoice(id: "chemex", title: "Chemex", detail: AppLocalization.text("chemex_profile_detail", fallback: "Clean texture and larger brews."), systemImage: "hourglass"),
            BrewChoice(id: "origami", title: "Origami", detail: AppLocalization.text("origami_profile_detail", fallback: "Flexible flow and clarity."), systemImage: "diamond"),
            BrewChoice(id: "aeropress", title: "AeroPress", detail: AppLocalization.text("aeropress_profile_detail", fallback: "Pressure-assisted and fast."), systemImage: "capsule.portrait"),
            BrewChoice(id: "french-press", title: "French Press", detail: AppLocalization.text("french_press_profile_detail", fallback: "Immersion body and depth."), systemImage: "cylinder"),
            BrewChoice(id: "espresso", title: "Espresso", detail: AppLocalization.text("espresso_profile_detail", fallback: "Short, concentrated brewing."), systemImage: "cup.and.saucer"),
            BrewChoice(id: "arabic", title: "Arabic coffee", detail: AppLocalization.text("arabic_profile_detail", fallback: "Traditional heat and aroma."), systemImage: "flame"),
            BrewChoice(id: "cold", title: "Cold brew", detail: AppLocalization.text("cold_profile_detail", fallback: "Slow extraction for cold service."), systemImage: "snowflake"),
            BrewChoice(id: "automatic", title: "Automatic brewer", detail: AppLocalization.text("automatic_profile_detail", fallback: "Recipes shaped for equipment transfer."), systemImage: "gearshape.2"),
            BrewChoice(id: "other", title: "Something else", detail: AppLocalization.text("other_profile_detail", fallback: "Search the brewer list."), systemImage: "magnifyingglass")
        ]
    }

    var brewProfileTasteChoices: [BrewChoice] {
        [
            BrewChoice(id: "bright", title: AppLocalization.text("bright_clean", fallback: "Bright & clean"), detail: AppLocalization.text("profile_taste_bright_detail", fallback: "Lively acidity, clarity, and a lighter body."), systemImage: "sparkle"),
            BrewChoice(id: "balanced", title: AppLocalization.text("balanced", fallback: "Balanced"), detail: AppLocalization.text("profile_taste_balanced_detail", fallback: "A little of everything, with nothing dominating."), systemImage: "circle.lefthalf.filled"),
            BrewChoice(id: "sweet", title: AppLocalization.text("sweet_round", fallback: "Sweet & round"), detail: AppLocalization.text("profile_taste_sweet_detail", fallback: "Soft acidity, noticeable sweetness, and a smooth finish."), systemImage: "drop"),
            BrewChoice(id: "rich", title: AppLocalization.text("rich_full", fallback: "Rich & full"), detail: AppLocalization.text("profile_taste_rich_detail", fallback: "More body, depth, and weight."), systemImage: "circle.fill")
        ]
    }

    var searchableBrewerList: some View {
        VStack(alignment: .leading, spacing: 12) {
            createRecipeTextField(
                title: AppLocalization.text("search_brewers", fallback: "Search brewers"),
                placeholder: AppLocalization.text("search_brewers_placeholder", fallback: "Orea, December, Stagg..."),
                text: $brewerSearchText
            )

            VStack(spacing: 0) {
                ForEach(Array(filteredSearchBrewers.enumerated()), id: \.element.id) { index, brewer in
                    if index > 0 {
                        brewDivider
                    }
                    createRecipeChoiceCard(brewer, selection: $createRecipeBrewer)
                }
            }
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var filteredSearchBrewers: [BrewChoice] {
        let extended = [
            BrewChoice(id: "orea", title: "Orea", detail: AppLocalization.text("orea_detail", fallback: "Fast flat-bottom filter brewing."), systemImage: "circle.grid.cross"),
            BrewChoice(id: "stagg", title: "Fellow Stagg", detail: AppLocalization.text("stagg_detail", fallback: "Controlled flow and steady bed depth."), systemImage: "square"),
            BrewChoice(id: "december", title: "December Dripper", detail: AppLocalization.text("december_detail", fallback: "Adjustable flow for filter recipes."), systemImage: "slider.horizontal.3"),
            BrewChoice(id: "clever", title: "Clever Dripper", detail: AppLocalization.text("clever_detail", fallback: "Immersion-first filter brewing."), systemImage: "cup.and.saucer")
        ]
        let query = brewerSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return extended }
        return extended.filter { $0.title.localizedCaseInsensitiveContains(query) || $0.detail.localizedCaseInsensitiveContains(query) }
    }

    var brewProfileProgressLabel: String {
        switch brewProfileStep {
        case .experience:
            return "01 / 03  EXPERIENCE"
        case .brewer:
            return "02 / 03  BREWER"
        default:
            return "03 / 03  TASTE"
        }
    }

    var brewProfileProgressFraction: Double {
        switch brewProfileStep {
        case .experience:
            return 1.0 / 3.0
        case .brewer:
            return 2.0 / 3.0
        default:
            return 1.0
        }
    }

    var brewProfileBottomControls: some View {
        HStack(spacing: 10) {
            Button {
                moveBrewProfileBack()
            } label: {
                Text(brewProfileStep == .experience ? AppLocalization.text("skip", fallback: "Skip") : AppLocalization.text("back", fallback: "Back"))
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 46)
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                moveBrewProfileForward()
            } label: {
                Text(brewProfileStep == .tasteGoal ? AppLocalization.text("finish_setup", fallback: "Finish Setup") : AppLocalization.text("continue", fallback: "Continue"))
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.1)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x1C1A17))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 46)
                    .background(brewAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    var brewProfileBrewerName: String {
        (brewProfileBrewerChoices + filteredSearchBrewers).first { $0.id == createRecipeBrewer }?.title
            ?? brewProfileBrewerChoices.first { $0.id == storedBrewProfileBrewer }?.title
            ?? "V60"
    }

    var brewProfileTasteName: String {
        brewProfileTasteChoices.first { $0.id == createRecipeTasteGoal }?.title
            ?? brewProfileTasteChoices.first { $0.id == storedBrewProfileTaste }?.title
            ?? AppLocalization.text("balanced", fallback: "Balanced")
    }

    func restoreBrewProfileSelections() {
        createRecipeExperience = storedBrewProfileExperience
        createRecipeBrewer = storedBrewProfileBrewer
        createRecipeTasteGoal = storedBrewProfileTaste
        restoreSavedEquipmentSelections()
    }

    func persistBrewProfileSelections() {
        storedBrewProfileExperience = createRecipeExperience
        storedBrewProfileBrewer = createRecipeBrewer
        storedBrewProfileTaste = createRecipeTasteGoal
        persistSavedEquipmentSelections()
        isBrewProfileComplete = true
    }

    func restoreSavedEquipmentSelections() {
        createRecipeBrewer = storedBrewProfileBrewer
        recipeGrinder = storedEquipmentGrinder
        recipeFilterType = storedEquipmentFilter
    }

    func persistSavedEquipmentSelections() {
        storedBrewProfileBrewer = createRecipeBrewer
        storedEquipmentGrinder = recipeGrinder.trimmingCharacters(in: .whitespacesAndNewlines)
        try? coffeeData.saveEquipmentName(kind: .grinder, name: storedEquipmentGrinder)
        storedEquipmentFilter = recipeFilterType.trimmingCharacters(in: .whitespacesAndNewlines)
        recipeGrinder = storedEquipmentGrinder
        recipeFilterType = storedEquipmentFilter
    }

    func moveBrewProfileBack() {
        switch brewProfileStep {
        case .experience:
            persistBrewProfileSelections()
        case .brewer:
            brewProfileStep = .experience
        default:
            brewProfileStep = .brewer
        }
    }

    func moveBrewProfileForward() {
        switch brewProfileStep {
        case .experience:
            brewProfileStep = .brewer
        case .brewer:
            brewProfileStep = .tasteGoal
        default:
            persistBrewProfileSelections()
        }
    }

    func applyRecommendedProfileForBrewProfile() {
        if let profile = recommendedProfileForCreateRecipe {
            applyGuideProfile(profile, start: true)
        } else if let profile = brewGuideProfiles.first(where: { $0.id == "balanced-filter" }) {
            applyGuideProfile(profile, start: true)
        }
    }

    func prepareNewRecipeJourney(startsWithScan: Bool) {
        createRecipeStep = .coffeeDetails
        coffeeDetailsMode = startsWithScan ? .scan : nil
        createRecipeValidationMessage = nil
        recipeGenerationProgress = 0
        recipeGenerationStageIndex = 0
    }

    func consumePendingCoffeeIfNeeded() {
        let name = pendingCoffeeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        coffeeName = name
        coffeeRoaster = "Talla Speciality"
        brewRecipeName = name
        prepareNewRecipeJourney(startsWithScan: false)
        coffeeDetailsMode = .manual
        pendingCoffeeName = ""
        activeDashboardDestination = .createRecipe
    }

    var brewMethodCategories: [(title: String, detail: String, query: String)] {
        [
            (
                AppLocalization.text("pour_over", fallback: "Pour Over"),
                AppLocalization.text("pour_over_detail", fallback: "V60, SOLO Dripper, Kalita, Chemex, and Origami."),
                "Pour Over"
            ),
            (
                AppLocalization.text("immersion", fallback: "Immersion"),
                AppLocalization.text("immersion_detail", fallback: "French press, cupping, and steep-and-release recipes."),
                "Immersion"
            ),
            (
                AppLocalization.text("traditional", fallback: "Traditional"),
                AppLocalization.text("traditional_detail", fallback: "Arabic coffee and slow ceremonial methods."),
                "Traditional"
            ),
            (
                AppLocalization.text("cold_brew", fallback: "Cold Brew"),
                AppLocalization.text("cold_brew_detail", fallback: "Long, gentle extraction for cold service."),
                "Cold Brew"
            ),
            (
                AppLocalization.text("espresso", fallback: "Espresso"),
                AppLocalization.text("espresso_detail", fallback: "Short, concentrated recipes for espresso prep."),
                "Espresso"
            )
        ]
    }

    func openMethodCategory(_ query: String) {
        if brewingCategories.contains(query) {
            activeCategory = query
            return
        }

        if let match = brewingCategories.first(where: { $0.localizedCaseInsensitiveContains(query) || query.localizedCaseInsensitiveContains($0) }) {
            activeCategory = match
        }
    }

}
