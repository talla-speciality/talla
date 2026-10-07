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
    func createBrewRecipeFlow(startsWithScan: Bool) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            createRecipeProgressHeader

            createRecipeStepContent

            if let createRecipeValidationMessage, createRecipeStep != .generating {
                Text(createRecipeValidationMessage)
                    .font(.system(size: 13))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(brewAccentColor.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(brewAccentColor.opacity(0.22), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            if createRecipeStep != .generating && createRecipeStep != .recipeDetail {
                createRecipeBottomControls
            }
        }
        .onAppear {
            if startsWithScan && coffeeDetailsMode == nil {
                prepareNewRecipeJourney(startsWithScan: true)
                coffeeDetailsMode = .scan
            } else if isBrewProfileComplete && createRecipeStep.rawValue < CreateRecipeStep.coffeeDetails.rawValue {
                prepareNewRecipeJourney(startsWithScan: false)
            }
        }
#if canImport(PhotosUI)
        .onChange(of: coffeeBagPhotoSelection) { _, selection in
            Task { await loadCoffeeBagPhoto(selection) }
        }
#endif
#if canImport(UIKit)
        .fullScreenCover(isPresented: $isCoffeeBagCameraPresented) {
            CoffeeBagCameraPicker { image in
                handleCoffeeBagImage(image)
            }
            .ignoresSafeArea()
        }
#endif
    }

    /// Keeps the recipe flow's large, conditional SwiftUI view types behind a
    /// stable runtime boundary. Without this erasure, resolving the nested
    /// generic type can exhaust the main-thread stack on device.
    var createRecipeStepContent: AnyView {
        switch createRecipeStep {
        case .experience, .brewer, .tasteGoal, .coffeeDetails:
            AnyView(createRecipeCoffeeDetailsStep)
        case .equipment:
            AnyView(createRecipeEquipmentStep)
        case .generating:
            AnyView(recipeGenerationLoadingScreen)
        case .recipeDetail:
            AnyView(generatedRecipeDetailScreen)
        }
    }

    var createRecipeProgressHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(createRecipeJourneyProgressText)
                    .font(brewEyebrowFont)
                    .tracking(AppLocalization.letterSpacing(1.4))
                    .textCase(.uppercase)
                    .foregroundColor(brewAccentColor)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(brewBorderColor)
                        Rectangle()
                            .fill(brewAccentColor)
                            .frame(width: max(12, proxy.size.width * createRecipeProgressFraction))
                    }
                }
                .frame(height: 2)
            }

            Text(AppLocalization.text("create_brew_recipe", fallback: "Create Brew Recipe"))
                .font(Font.custom("Georgia-Bold", size: isCompact ? 28 : 32))
                .foregroundColor(brewPrimaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            Text(AppLocalization.text("create_recipe_focus_detail", fallback: "A calm recipe builder for your coffee, tools, and taste goal."))
                .font(brewReadingFont)
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    var createRecipeProgressFraction: Double {
        switch createRecipeStep {
        case .coffeeDetails:
            return 0.25
        case .equipment:
            return 0.50
        case .generating:
            return 0.75
        case .recipeDetail:
            return 1.0
        default:
            return Double(min(createRecipeStep.rawValue, 5)) / 5.0
        }
    }

    var createRecipeJourneyProgressText: String {
        switch createRecipeStep {
        case .coffeeDetails:
            return "COFFEE INPUT"
        case .equipment:
            return "BREW SETUP"
        case .generating:
            return "GENERATION"
        case .recipeDetail:
            return "RECIPE RESULT"
        default:
            return createRecipeStep.progressText
        }
    }

    var recipeGenerationStages: [RecipeGenerationStage] {
        [
            RecipeGenerationStage(
                id: 0,
                title: AppLocalization.text("reading_the_coffee", fallback: "Reading the coffee"),
                checks: [
                    AppLocalization.text("generation_reading_coffee_detail", fallback: "Origin · altitude · process · roast")
                ]
            ),
            RecipeGenerationStage(
                id: 1,
                title: AppLocalization.text("understanding_extraction", fallback: "Understanding the extraction"),
                checks: [
                    AppLocalization.text("generation_extraction_detail", fallback: "Density · solubility · flavour goal")
                ]
            ),
            RecipeGenerationStage(
                id: 2,
                title: AppLocalization.text("matching_equipment", fallback: "Matching your equipment"),
                checks: [
                    AppLocalization.text("generation_equipment_detail", fallback: "Brewer · filter · grinder")
                ]
            ),
            RecipeGenerationStage(
                id: 3,
                title: AppLocalization.text("building_pour_structure", fallback: "Building the pour structure"),
                checks: [
                    AppLocalization.text("generation_pour_structure_detail", fallback: "Grind · temperature · bloom · flow")
                ]
            ),
            RecipeGenerationStage(
                id: 4,
                title: AppLocalization.text("validating_recipe", fallback: "Validating the recipe"),
                checks: [
                    AppLocalization.text("generation_validation_detail", fallback: "Checking totals, timing, and practical limits")
                ]
            )
        ]
    }

    var recipeGenerationLoadingScreen: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalization.text("building_your_recipe", fallback: "Building your recipe"))
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 32 : 40))
                    .foregroundColor(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(displayCoffeeName)
                    .font(Font.custom("AvenirNext-Bold", size: 14))
                    .tracking(AppLocalization.letterSpacing(1.2))
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }

            VStack(alignment: .leading, spacing: 10) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(accentColor.opacity(0.16))
                        Capsule(style: .continuous)
                            .fill(accentColor)
                            .frame(width: proxy.size.width * recipeGenerationProgress)
                    }
                }
                .frame(height: 8)

                Text("\(Int(recipeGenerationProgress * 100))%")
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(AppLocalization.letterSpacing(1.2))
                    .textCase(.uppercase)
                    .foregroundColor(tertiaryTextColor)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AppLocalization.text("recipe_generation_progress", fallback: "Recipe generation progress"))
            .accessibilityValue("\(Int(recipeGenerationProgress * 100)) percent")

            VStack(spacing: 12) {
                ForEach(recipeGenerationStages) { stage in
                    recipeGenerationStageRow(stage)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .task(id: recipeGenerationTaskID) {
            await runRecipeGenerationSequence()
        }
    }

    func recipeGenerationStageRow(_ stage: RecipeGenerationStage) -> some View {
        let isComplete = stage.id < recipeGenerationStageIndex
        let isActive = stage.id == recipeGenerationStageIndex

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isComplete ? accentColor : accentColor.opacity(isActive ? 0.18 : 0.08))
                    .frame(width: 34, height: 34)

                Image(systemName: isComplete ? "checkmark" : isActive ? "sparkle" : "circle")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isComplete ? Color(hex: 0x2B170F) : accentColor)
                    .symbolEffect(.pulse, value: recipeGenerationStageIndex)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 8) {
                Text(stage.title)
                    .font(Font.custom("Georgia-Bold", size: 18))
                    .foregroundColor(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 118), spacing: 6)], alignment: .leading, spacing: 6) {
                    ForEach(stage.checks, id: \.self) { check in
                        HStack(spacing: 5) {
                            Circle()
                                .fill(isComplete || isActive ? accentColor : tertiaryTextColor.opacity(0.45))
                                .frame(width: 5, height: 5)
                            Text(check)
                                .font(Font.custom("AvenirNext-Regular", size: 12))
                                .foregroundColor(isComplete || isActive ? secondaryTextColor : tertiaryTextColor)
                                .lineLimit(2)
                                .minimumScaleFactor(0.78)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(isActive ? accentColor.opacity(0.09) : cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isActive ? accentColor.opacity(0.38) : accentColor.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .opacity(stage.id <= recipeGenerationStageIndex ? 1 : 0.62)
        .animation(.easeInOut(duration: 0.28), value: recipeGenerationStageIndex)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stage.title)
        .accessibilityValue(isComplete ? AppLocalization.text("complete", fallback: "Complete") : isActive ? AppLocalization.text("in_progress", fallback: "In progress") : AppLocalization.text("waiting", fallback: "Waiting"))
    }

    var generatedRecipeDetailScreen: some View {
        VStack(alignment: .leading, spacing: 26) {
            generatedRecipeHeader
            generatedRecipePrimaryParametersSection
            generatedRecipeFactsSection
            generatedRecipePourSequenceSection
            generatedRecipeActionSection
            generatedRecipeScienceSection
            generatedRecipeNotesSection
            generatedRecipeExpectedCupSection
            generatedCoffeeHistorySection
            generatedRecipeAfterBrewSection
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }

    var generatedRecipeHeader: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                brewSectionLabel(AppLocalization.text("your_recipe", fallback: "Your Recipe"))
                Spacer(minLength: 0)
                recipeTextButton(AppLocalization.text("edit", fallback: "Edit")) {
                    createRecipeStep = .equipment
                }
                recipeTextButton(AppLocalization.text("save", fallback: "Save")) {
                    saveCurrentRecipe()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(generatedRecipeTitle)
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 31 : 38))
                    .foregroundColor(brewPrimaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(displayCoffeeName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(generatedBrewerName) · \(generatedTasteGoalName)")
                    .font(.system(size: 14))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(generatedConfidenceLabel)
                .font(brewEyebrowFont)
                .tracking(AppLocalization.letterSpacing(1.4))
                .textCase(.uppercase)
                .foregroundColor(brewAccentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(brewAccentColor.opacity(0.34), lineWidth: 1)
                )

            Text(AppLocalization.text("first_recipe_refine_explanation", fallback: "This is the first recipe for this coffee. Rate the cup afterwards and Talla will refine the next version."))
                .font(brewReadingFont)
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .contain)
    }

    var generatedRecipePrimaryParametersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("primary_parameters", fallback: "Primary Parameters"))

            HStack(alignment: .top, spacing: 0) {
                primaryParameterColumn(
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    value: generatedGrindDescription,
                    detail: generatedGrinderSetting,
                    minusAction: { adjustGeneratedGrind(by: -1) },
                    plusAction: { adjustGeneratedGrind(by: 1) }
                )
                recipeVerticalDivider
                primaryParameterColumn(
                    title: AppLocalization.text("temperature", fallback: "Temperature"),
                    value: isClassicColdBrewRecipe ? "Room temp" : "\(generatedTemperatureC) °C",
                    detail: isClassicColdBrewRecipe ? "Filtered water" : AppLocalization.text("safe_range_92_94", fallback: "Safe range 92–94 °C"),
                    minusAction: isClassicColdBrewRecipe ? nil : { generatedTemperatureC = max(88, generatedTemperatureC - 1) },
                    plusAction: isClassicColdBrewRecipe ? nil : { generatedTemperatureC = min(98, generatedTemperatureC + 1) }
                )
                recipeVerticalDivider
                primaryParameterColumn(
                    title: AppLocalization.text("target_time", fallback: "Target time"),
                    value: generatedTargetTimeRange,
                    detail: AppLocalization.text("realistic_window", fallback: "Realistic brew window"),
                    minusAction: nil,
                    plusAction: nil
                )
            }
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var generatedRecipeFactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("recipe_facts", fallback: "Recipe Facts"))

            VStack(spacing: 0) {
                recipeFactRow(title: AppLocalization.text("coffee_dose", fallback: "Coffee dose"), value: "\(formattedRatioValue(validCoffeeAmount)) g")
                recipeDivider
                recipeFactRow(title: AppLocalization.text("ratio", fallback: "Ratio"), value: "1:\(formattedRatioValue(validRatioValue))")
                recipeDivider
                recipeFactRow(title: isV60IcedRecipe ? "Hot brewing water" : AppLocalization.text("total_water", fallback: "Total water"), value: "\(formattedWholeGram(recipeBrewingWaterAmount)) g")
                if isV60IcedRecipe {
                    recipeDivider
                    recipeFactRow(title: "Ice in server", value: "\(formattedWholeGram(recipeIceAmount)) g")
                }
                if isClassicColdBrewRecipe {
                    recipeDivider
                    recipeFactRow(title: "Serving dilution", value: "1 part concentrate : 2 parts water or milk")
                    recipeDivider
                    recipeFactRow(title: "Ice per serving", value: "About 100 g")
                }
                recipeDivider
                recipeFactRow(title: AppLocalization.text("expected_beverage", fallback: "Expected beverage"), value: "\(formattedWholeGram(expectedBeverageAmount)) g")
                recipeDivider
                recipeFactRow(title: AppLocalization.text("agitation", fallback: "Agitation"), value: generatedAgitationLevel)
                if !isClassicColdBrewRecipe {
                    recipeDivider
                    recipeFactRow(title: AppLocalization.text("bloom_amount", fallback: "Bloom amount"), value: "\(formattedWholeGram(bloomWaterAmount)) g")
                    recipeDivider
                    recipeFactRow(title: AppLocalization.text("bloom_duration", fallback: "Bloom duration"), value: "\(bloomDurationSeconds) s")
                    recipeDivider
                    recipeFactRow(title: AppLocalization.text("number_of_pours", fallback: "Number of pours"), value: "\(recipePourCount)")
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

    var generatedRecipePourSequenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("pour_sequence", fallback: "Pour Sequence"))

            VStack(spacing: 0) {
                if !isCompact {
                    recipePourTableHeader
                    recipeDivider
                }
                ForEach(generatedPourRows) { row in
                    generatedPourTableRow(row)
                    if row.id != generatedPourRows.last?.id {
                        recipeDivider
                    }
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

    var generatedRecipeActionSection: some View {
        VStack(spacing: 10) {
            Button {
                activeDashboardDestination = nil
                isFocusedBrewPresented = true
            } label: {
                Text(AppLocalization.text("start_guided_brew", fallback: "Start Guided Brew"))
                    .font(.system(size: 13, weight: .semibold))
                    .tracking(AppLocalization.letterSpacing(1.2))
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x1C1A17))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(brewAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                secondaryRecipeAction(title: AppLocalization.text("share", fallback: "Share")) {
                    copyGeneratedRecipeToClipboard()
                }
                secondaryRecipeAction(title: AppLocalization.text("copy", fallback: "Copy")) {
                    copyGeneratedRecipeToClipboard()
                }
                secondaryRecipeAction(title: AppLocalization.text("save_recipe", fallback: "Save Recipe")) {
                    saveCurrentRecipe()
                }
            }
        }
    }

    var generatedRecipeScienceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("brew_science", fallback: "Brew Science"))

            VStack(spacing: 0) {
                scienceTopicCard(id: "temperature", title: AppLocalization.text("why_this_temperature", fallback: "Why this temperature"), summary: restoredTemperatureReason ?? smartRecipe.temperatureReason, more: "Recommended range: \(smartRecipe.temperatureRange). Talla considered the \(coffeeRoastLevel.lowercased()) roast, \(coffeeProcess.isEmpty ? "unknown process" : coffeeProcess.lowercased()), altitude, roast age, brew mode, and your \(generatedTasteGoalName.lowercased()) goal.")
                recipeDivider
                scienceTopicCard(id: "grind", title: AppLocalization.text("why_this_grind", fallback: "Why this grind"), summary: "\(generatedGrindDescription) at about \(smartRecipe.grindMicrons) μm matches this dose, brewer, process, and taste goal.", more: "Your \(recipeGrinder.isEmpty ? "grinder" : recipeGrinder) starting point is \(generatedGrinderSetting). Talla Dial-In will move this in small steps when a brew tastes sour, bitter, dry, fast, or slow.")
                recipeDivider
                scienceTopicCard(id: "ratio", title: AppLocalization.text("why_this_ratio", fallback: "Why this ratio"), summary: "1:\(formattedRatioValue(validRatioValue)) produces \(formattedWholeGram(validWaterAmount)) g total water from \(formattedRatioValue(validCoffeeAmount)) g coffee.", more: isV60IcedRecipe ? "For iced brewing, Talla preserves that ratio by splitting the total into \(formattedWholeGram(recipeBrewingWaterAmount)) g hot water and \(formattedWholeGram(recipeIceAmount)) g ice." : "The expected beverage is about \(formattedWholeGram(expectedBeverageAmount)) g after allowing for coffee-bed retention.")
                recipeDivider
                scienceTopicCard(id: "recipe", title: AppLocalization.text("why_this_recipe", fallback: "Why this recipe"), summary: generatedApproachNotes, more: generatedDecisionExplanation)
                recipeDivider
                scienceTopicCard(id: "process", title: AppLocalization.text("process_considerations", fallback: "Process considerations"), summary: generatedProcessConsiderationSummary, more: "The process changes bloom duration, temperature, grind, agitation, and pour style. This recipe uses a \(bloomDurationSeconds)-second bloom and \(generatedAgitationLevel.lowercased()) agitation rather than applying one generic method to every coffee.")
            }
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var generatedRecipeExpectedCupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("expected_cup", fallback: "Expected Cup"))

            VStack(spacing: 0) {
                recipeFactRow(title: AppLocalization.text("acidity", fallback: "Acidity"), value: expectedCupAcidity)
                recipeDivider
                recipeFactRow(title: AppLocalization.text("sweetness", fallback: "Sweetness"), value: expectedCupSweetness)
                recipeDivider
                recipeFactRow(title: AppLocalization.text("body", fallback: "Body"), value: expectedCupBody)
                recipeDivider
                recipeFactRow(title: AppLocalization.text("clarity", fallback: "Clarity"), value: expectedCupClarity)
            }
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(expectedCupFlavourExpression)
                .font(brewReadingFont)
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    var generatedCoffeeHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("coffee_history", fallback: "This coffee’s history"))

            VStack(alignment: .leading, spacing: 12) {
                if let calibration = activeCoffeeCalibration {
                    Label(
                        "Talla has learned from \(calibration.calibration.brewCount) previous refinement\(calibration.calibration.brewCount == 1 ? "" : "s") for this coffee.",
                        systemImage: "brain.head.profile"
                    )
                    .font(Font.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundColor(accentColor)

                    if !calibration.calibration.lastFeedback.isEmpty {
                        Text(String(format: AppLocalization.text("latest_feedback_format", fallback: "Latest feedback: %@"), calibration.calibration.lastFeedback.joined(separator: AppLocalization.currentLanguage.effectiveLanguageCode == "ar" ? "، " : ", ")))
                            .font(bodyFont)
                            .foregroundColor(secondaryTextColor)
                    }
                }

                if currentCoffeeHistory.isEmpty {
                    Text(AppLocalization.text("first_brew_history", fallback: "This is the first saved brew for this coffee. Rate it afterwards and Talla will build its calibration history here."))
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                } else {
                    ForEach(Array(currentCoffeeHistory.prefix(5).enumerated()), id: \.element.id) { index, recipe in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(Font.custom("AvenirNext-Bold", size: 11))
                                .foregroundColor(accentColor)
                                .frame(width: 26, height: 26)
                                .background(accentColor.opacity(0.10))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(recipe.title)
                                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                                    .foregroundColor(primaryTextColor)
                                Text(recipe.detail)
                                    .font(Font.custom("AvenirNext-Regular", size: 12))
                                    .foregroundColor(secondaryTextColor)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(brewSurfaceColor)
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(brewBorderColor, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    var generatedRecipeNotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            recipeSectionHeading(AppLocalization.text("brew_notes", fallback: "Brew Notes"))

            Text(generatedApproachNotes)
                .font(brewReadingFont)
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $generatedRecipeNotes)
                .font(.system(size: 14))
                .foregroundColor(brewPrimaryTextColor)
                .frame(minHeight: 96)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityLabel(AppLocalization.text("notes_before_brewing", fallback: "Notes before brewing"))
        }
    }

    var generatedRecipeAfterBrewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            recipeSectionHeading(AppLocalization.text("after_the_brew", fallback: "After the Brew"))

            VStack(alignment: .leading, spacing: 12) {
                Text(AppLocalization.text("brewed_it", fallback: "Brewed it?"))
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)

                VStack(spacing: 0) {
                    brewingLinkedRow(title: AppLocalization.text("open_brew_coach", fallback: "Open Brew Coach"), detail: AppLocalization.text("open_brew_coach_detail", fallback: "Get a small adjustment for the next cup."), value: nil) {
                        activeDashboardDestination = .brewCoach
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("rate_this_brew", fallback: "Rate this brew"), detail: AppLocalization.text("rate_this_brew_detail", fallback: "Tell Talla how the cup tasted."), value: nil) {
                        brewModeElapsedSeconds = brewModeTotalSeconds
                        isBrewModeRunning = false
                        isFocusedBrewPresented = true
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("add_tasting_notes", fallback: "Add tasting notes"), detail: AppLocalization.text("add_tasting_notes_detail", fallback: "Capture what stood out before saving."), value: nil) {
                        generatedRecipeNotes = generatedRecipeNotes.isEmpty ? AppLocalization.text("tasting_notes_prompt", fallback: "Tasting notes: ") : generatedRecipeNotes
                    }
                    brewDivider
                    brewingLinkedRow(title: AppLocalization.text("save_to_journal", fallback: "Save to Journal"), detail: AppLocalization.text("save_to_journal_detail", fallback: "Store this recipe and brew notes."), value: nil) {
                        saveCurrentRecipe()
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

    func recipeTextButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .tracking(AppLocalization.letterSpacing(1.1))
                .textCase(.uppercase)
                .foregroundColor(brewAccentColor)
        }
        .buttonStyle(.plain)
    }

    func recipeIconButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(brewPrimaryTextColor)
                .frame(width: 40, height: 40)
                .background(brewSurfaceColor)
                .overlay(
                    Circle()
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    func recipeSectionHeading(_ title: String) -> some View {
        Text(title)
            .font(brewEyebrowFont)
            .tracking(AppLocalization.letterSpacing(1.8))
            .textCase(.uppercase)
            .foregroundColor(brewAccentColor)
    }

    var recipeDivider: some View {
        Rectangle()
            .fill(brewBorderColor)
            .frame(height: 1)
    }

    var recipeVerticalDivider: some View {
        Rectangle()
            .fill(brewBorderColor)
            .frame(width: 1)
            .padding(.vertical, 14)
    }

    func primaryParameterColumn(
        title: String,
        value: String,
        detail: String,
        minusAction: (() -> Void)?,
        plusAction: (() -> Void)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(brewEyebrowFont)
                .tracking(AppLocalization.letterSpacing(1.2))
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(value)
                .font(.system(size: isCompact ? 19 : 22, weight: .semibold, design: .rounded))
                .foregroundColor(brewPrimaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(detail)
                .font(.system(size: 12))
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            if minusAction != nil || plusAction != nil {
                HStack(spacing: 8) {
                    parameterAdjustButton(systemImage: "minus", action: minusAction)
                    parameterAdjustButton(systemImage: "plus", action: plusAction)
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    func parameterAdjustButton(systemImage: String, action: (() -> Void)?) -> some View {
        Button {
            action?()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(action == nil ? brewSecondaryTextColor.opacity(0.45) : brewPrimaryTextColor)
                .frame(width: 34, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
        .accessibilityLabel(systemImage == "minus" ? AppLocalization.text("decrease", fallback: "Decrease") : AppLocalization.text("increase", fallback: "Increase"))
    }

    func recipeFactRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(title)
                .font(brewEyebrowFont)
                .tracking(AppLocalization.letterSpacing(1.0))
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(brewPrimaryTextColor)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .accessibilityElement(children: .combine)
    }

    var recipePourTableHeader: some View {
        HStack(spacing: 10) {
            tableHeaderText(AppLocalization.text("step", fallback: "Step"), width: 160, alignment: .leading)
            tableHeaderText(AppLocalization.text("water_added", fallback: "Water added"), width: 92)
            tableHeaderText(AppLocalization.text("total_target", fallback: "Total target"), width: 92)
            tableHeaderText(AppLocalization.text("flow", fallback: "Flow"), width: 88)
            tableHeaderText(AppLocalization.text("start_time", fallback: "Start time"), width: 78)
            tableHeaderText(AppLocalization.text("duration", fallback: "Duration"), width: 78)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    func tableHeaderText(_ text: String, width: CGFloat, alignment: Alignment = .trailing) -> some View {
        Text(text)
            .font(brewEyebrowFont)
            .tracking(AppLocalization.letterSpacing(0.7))
            .textCase(.uppercase)
            .foregroundColor(brewSecondaryTextColor)
            .frame(width: width, alignment: alignment)
    }

    func generatedPourTableRow(_ row: GeneratedPourRow) -> some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(String(format: "%02d", row.id))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(brewAccentColor)
                            .frame(width: 28, alignment: .leading)

                        Text(row.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)

                        Spacer(minLength: 8)

                        Text(formattedTimerTime(row.startTime))
                            .font(.system(size: 12, weight: .semibold, design: .monospaced))
                            .foregroundColor(brewAccentColor)
                    }

                    Text(row.instruction)
                        .font(.system(size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        recipeTinyValue(AppLocalization.text("water", fallback: "Water"), row.waterAdded.map { "\($0) g" } ?? "—")
                        recipeTinyValue(AppLocalization.text("total", fallback: "Total"), row.cumulativeWater.map { "\($0) g" } ?? "—")
                        recipeTinyValue(AppLocalization.text("flow", fallback: "Flow"), row.flowRate)
                        recipeTinyValue(AppLocalization.text("duration", fallback: "Duration"), generatedPourDurationText(for: row))
                    }
                }
                .padding(14)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Text("\(String(format: "%02d", row.id)) \(row.title)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(brewPrimaryTextColor)
                            .frame(width: 160, alignment: .leading)
                        tableValueText(row.waterAdded.map { "\($0) g" } ?? "—", width: 92)
                        tableValueText(row.cumulativeWater.map { "\($0) g" } ?? "—", width: 92)
                        tableValueText(row.flowRate, width: 88)
                        tableValueText(formattedTimerTime(row.startTime), width: 78)
                        tableValueText(generatedPourDurationText(for: row), width: 78)
                    }

                    Text(row.instruction)
                        .font(.system(size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                }
                .padding(14)
            }
        }
        .accessibilityElement(children: .combine)
    }

    func tableValueText(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundColor(brewPrimaryTextColor)
            .frame(width: width, alignment: .trailing)
            .lineLimit(1)
            .minimumScaleFactor(0.72)
    }

    func recipeTinyValue(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(AppLocalization.letterSpacing(0.8))
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(brewPrimaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func generatedPourDurationText(for row: GeneratedPourRow) -> String {
        guard let index = generatedPourRows.firstIndex(where: { $0.id == row.id }) else {
            return "—"
        }
        let nextStart = index + 1 < generatedPourRows.count ? generatedPourRows[index + 1].startTime : brewModeTotalSeconds
        let duration = max(nextStart - row.startTime, 0)
        return duration == 0 ? "—" : "\(duration) s"
    }

    func secondaryRecipeAction(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(AppLocalization.letterSpacing(1.0))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .foregroundColor(brewPrimaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func adjustableRecipeValueCard(title: String, value: String, detail: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(accentColor)
                        .frame(width: 32, height: 32)
                        .background(accentColor.opacity(0.10))
                        .clipShape(Circle())
                        .accessibilityHidden(true)

                    Spacer(minLength: 0)

                    Image(systemName: "plusminus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(tertiaryTextColor)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(AppLocalization.letterSpacing(1.2))
                    .textCase(.uppercase)
                    .foregroundColor(tertiaryTextColor)

                Text(value)
                    .font(Font.custom("Georgia-Bold", size: 24))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 156, alignment: .leading)
            .background(accentColor.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(accentColor.opacity(0.15), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint(AppLocalization.text("tap_to_adjust", fallback: "Tap to adjust"))
    }

    func recipeInfoRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(AppLocalization.letterSpacing(1.1))
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.74)

            Text(value)
                .font(Font.custom("AvenirNext-Bold", size: 15))
                .foregroundColor(primaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(accentColor.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    func generatedPourRowView(_ row: GeneratedPourRow) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Text("\(row.id)")
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .foregroundColor(accentColor)
                    .monospacedDigit()
                    .frame(width: 24, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(row.title)
                        .font(Font.custom("Georgia-Bold", size: 17))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(row.instruction)
                        .font(Font.custom("AvenirNext-Regular", size: 12))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Text(formattedTimerTime(row.startTime))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .foregroundColor(accentColor)
                    .monospacedDigit()
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 6)], spacing: 6) {
                recipeMiniStat(title: AppLocalization.text("water_added", fallback: "Water"), value: row.waterAdded.map { "\($0) g" } ?? "—")
                recipeMiniStat(title: AppLocalization.text("total", fallback: "Total"), value: row.cumulativeWater.map { "\($0) g" } ?? "—")
                recipeMiniStat(title: AppLocalization.text("flow", fallback: "Flow"), value: row.flowRate)
            }
        }
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    func recipeMiniStat(title: String, value: String) -> some View {
        HStack(spacing: 5) {
            Text(title)
                .font(Font.custom("AvenirNext-Bold", size: 9))
                .tracking(AppLocalization.letterSpacing(0.8))
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)
            Text(value)
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .foregroundColor(primaryTextColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accentColor.opacity(0.07))
        .clipShape(Capsule(style: .continuous))
    }

    func secondaryRecipeAction(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(AppLocalization.letterSpacing(1.0))
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .foregroundColor(primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(cardFillColor)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(accentColor.opacity(0.18), lineWidth: 1)
                )
                .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func scienceTopicCard(id: String, title: String, summary: String, more: String) -> some View {
        let isExpanded = expandedScienceTopics.contains(id)

        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                if isExpanded {
                    expandedScienceTopics.remove(id)
                } else {
                    expandedScienceTopics.insert(id)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(brewSecondaryTextColor)
                        .accessibilityHidden(true)
                }

                Text(summary)
                    .font(.system(size: 13))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                if id == "temperature" {
                    temperatureRangeIndicator
                }

                if isExpanded {
                    Text(more)
                        .font(.system(size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    var temperatureRangeIndicator: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(brewBorderColor)
                    .frame(height: 2)

                Rectangle()
                    .fill(brewAccentColor)
                    .frame(width: proxy.size.width * 0.34, height: 2)
                    .offset(x: proxy.size.width * 0.44)

                Circle()
                    .fill(brewAccentColor)
                    .frame(width: 8, height: 8)
                    .offset(x: max(0, min(proxy.size.width - 8, proxy.size.width * CGFloat(Double(generatedTemperatureC - 88) / 10.0))))
            }
        }
        .frame(height: 10)
        .accessibilityLabel(AppLocalization.text("temperature_range_indicator", fallback: "Temperature range indicator"))
        .accessibilityValue("\(generatedTemperatureC) °C")
    }

    var generatedRecipeTitle: String {
        brewRecipeName.isEmpty ? selectedCreateRecipeTitle : brewRecipeName
    }

    var generatedBrewerName: String {
        brewerChoices.first { $0.id == createRecipeBrewer }?.title ?? AppLocalization.text("filter", fallback: "Filter")
    }

    var generatedTasteGoalName: String {
        createRecipeTasteGoalChoice?.title ?? AppLocalization.text("balanced", fallback: "Balanced")
    }

    var generatedConfidenceLabel: String {
        if createRecipeBrewer == "other" {
            return AppLocalization.text("experimental", fallback: "Experimental")
        }

        switch createRecipeExperience {
        case "dial":
            return AppLocalization.text("personalised", fallback: "Personalised")
        case "automatic", "basics":
            return AppLocalization.text("proven_recipe", fallback: "Proven Recipe")
        default:
            return AppLocalization.text("starting_point", fallback: "Starting Point")
        }
    }

    var generatedGrinderSetting: String {
        smartRecipe.grinderSetting
    }

    var generatedTargetTimeRange: String {
        restoredTargetTimeRange ?? smartRecipe.targetTimeRange
    }

    var isClassicColdBrewRecipe: Bool {
        createRecipeBrewer == "cold" || activeSmartRecipeID == "classic-cold-brew"
    }

    var isV60IcedRecipe: Bool {
        recipeBrewTemperatureMode.caseInsensitiveCompare("Iced") == .orderedSame
            || createRecipeBrewer == "v60-iced"
            || activeSmartRecipeID == "v60-iced"
    }

    var recipeBrewingWaterAmount: Double {
        if isGeneratedRecipeActive {
            return BrewRecipeMath.waterSplit(totalWater: validWaterAmount, isIced: isV60IcedRecipe).brewingWater
        }
        guard let publishedRecipeWaterGrams,
              let publishedRecipeCoffeeGrams,
              publishedRecipeCoffeeGrams > 0 else {
            return isV60IcedRecipe ? validCoffeeAmount * 9 : validWaterAmount
        }
        return publishedRecipeWaterGrams * validCoffeeAmount / publishedRecipeCoffeeGrams
    }

    var recipeIceAmount: Double {
        if isGeneratedRecipeActive {
            return BrewRecipeMath.waterSplit(totalWater: validWaterAmount, isIced: isV60IcedRecipe).ice
        }
        guard let publishedRecipeIceGrams,
              let publishedRecipeCoffeeGrams,
              publishedRecipeCoffeeGrams > 0 else {
            return isV60IcedRecipe ? validCoffeeAmount * 6 : 0
        }
        return publishedRecipeIceGrams * validCoffeeAmount / publishedRecipeCoffeeGrams
    }

    var expectedBeverageAmount: Double {
        if isV60IcedRecipe {
            return validWaterAmount
        }
        return max(validWaterAmount - (validCoffeeAmount * 2.1), 1)
    }

    var bloomWaterAmount: Double {
        smartRecipe.bloomWaterGrams
    }

    var smartBloomMultiplier: Double {
        BrewRecipeMath.suggestedBloomMultiplier(
            roast: coffeeRoastLevel,
            process: coffeeProcess,
            tasteGoal: createRecipeTasteGoal
        )
    }

    var bloomDurationSeconds: Int {
        smartRecipe.bloomDurationSeconds
    }

    var generatedAgitationLevel: String {
        smartRecipe.agitation
    }

    var generatedPourRows: [GeneratedPourRow] {
        (restoredRecipeSteps ?? smartRecipe.steps).map {
            let instruction = restoredRecipeSteps == nil
                ? $0.instruction.replacingOccurrences(of: "\(smartRecipe.temperatureC) °C", with: "\(generatedTemperatureC) °C")
                : $0.instruction
            return GeneratedPourRow(id: $0.id, title: $0.title, waterAdded: $0.waterAdded, cumulativeWater: $0.cumulativeWater, startTime: $0.startTime, flowRate: $0.flowRate, instruction: instruction)
        }
    }

    var smartRecipe: SmartBrewRecipe {
        let altitude = Int(coffeeAltitude.filter { $0.isNumber })
        let days = max(Calendar.current.dateComponents([.day], from: coffeeRoastDate, to: Date()).day ?? 0, 0)
        return SmartBrewRecipeEngine.generate(
            SmartBrewInput(
                coffeeGrams: validCoffeeAmount,
                ratio: validRatioValue,
                brewerID: createRecipeBrewer,
                brewMode: recipeBrewTemperatureMode,
                roast: coffeeRoastLevel,
                process: coffeeProcess,
                tasteGoal: createRecipeTasteGoal,
                altitudeMeters: altitude,
                daysOffRoast: days,
                grinder: recipeGrinder,
                bloomPreference: recipeBloomRatio,
                requestedPourCount: recipePourCount,
                controlMode: recipeBrewControlMode,
                calibration: activeCoffeeCalibration?.calibration
            )
        )
    }

    var coffeeCalibrationRecords: [CoffeeCalibrationRecord] {
        guard let data = storedCoffeeCalibrations.data(using: .utf8),
              let records = try? JSONDecoder().decode([CoffeeCalibrationRecord].self, from: data) else {
            return []
        }
        return records
    }

    var currentCoffeeIdentity: String {
        normalizedCoffeeIdentity(coffeeName)
    }

    func normalizedCoffeeIdentity(_ value: String) -> String {
        var parts = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().split(separator: " ").map(String.init)
        if let last = parts.last, last.first == "v", last.dropFirst().allSatisfy(\.isNumber) {
            parts.removeLast()
        }
        return parts.joined(separator: " ").folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
    }

    var currentCoffeeHistory: [BrewRecipeRecord] {
        let identity = currentCoffeeIdentity
        guard !identity.isEmpty else { return [] }
        return brewHistoryItems.filter {
            guard normalizedCoffeeIdentity($0.title) == identity else { return false }
            guard let recipeMethod = $0.methodID, let selectedBrewModeMethodID else { return true }
            return recipeMethod == selectedBrewModeMethodID
        }
    }

    var currentCoffeeMethodCalibrationIdentity: String {
        let method = selectedBrewModeMethodID?.trimmingCharacters(in: .whitespacesAndNewlines)
        let methodIdentity = method.flatMap { $0.isEmpty ? nil : $0 } ?? "default"
        return [currentCoffeeIdentity, methodIdentity].joined(separator: "::")
    }

    var activeCoffeeCalibration: CoffeeCalibrationRecord? {
        guard !coffeeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return coffeeCalibrationRecords.first { $0.id == currentCoffeeMethodCalibrationIdentity }
            ?? coffeeCalibrationRecords.first { $0.id == currentCoffeeIdentity }
    }

    func persistCoffeeCalibrations(_ records: [CoffeeCalibrationRecord]) {
        guard let data = try? JSONEncoder().encode(Array(records.prefix(50))),
              let payload = String(data: data, encoding: .utf8) else { return }
        storedCoffeeCalibrations = payload
        try? coffeeData.saveCalibrationJSON(payload)
    }

    func rememberTallaDialInCalibration(from changes: [RecipeRevisionChange]) {
        guard !coffeeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var records = coffeeCalibrationRecords
        let identity = currentCoffeeMethodCalibrationIdentity
        let existing = activeCoffeeCalibration?.calibration
        var calibration = existing ?? SmartBrewCalibration(grindMicronOffset: 0, temperatureOffset: 0, pourCountOffset: 0, preferredAgitation: nil, brewCount: 0, lastFeedback: [])

        if let grind = changes.first(where: { $0.id == "grind" }) {
            let order = ["Fine", "Medium-fine", "Medium", "Medium-coarse", "Coarse"]
            let before = order.firstIndex(of: grind.before) ?? 2
            let after = order.firstIndex(of: grind.after) ?? before
            calibration.grindMicronOffset = min(max(calibration.grindMicronOffset + ((after - before) * 35), -140), 140)
        }
        if let temperature = changes.first(where: { $0.id == "temperature" }) {
            let before = Int(temperature.before.filter(\.isNumber)) ?? generatedTemperatureC
            let after = Int(temperature.after.filter(\.isNumber)) ?? before
            calibration.temperatureOffset = min(max(calibration.temperatureOffset + after - before, -4), 4)
        }
        if changes.contains(where: { $0.id == "time" }) {
            calibration.pourCountOffset = min(calibration.pourCountOffset + 1, 2)
        }
        if let agitation = changes.first(where: { $0.id == "agitation" }) {
            calibration.preferredAgitation = agitation.after
        }
        calibration.brewCount += 1
        calibration.lastFeedback = Array((afterBrewSelections.sorted() + afterBrewMoreOfSelections.sorted()).prefix(8))

        let record = CoffeeCalibrationRecord(
            id: identity,
            coffeeName: coffeeName.trimmingCharacters(in: .whitespacesAndNewlines),
            roaster: coffeeRoaster.trimmingCharacters(in: .whitespacesAndNewlines),
            calibration: calibration,
            updatedAt: Date()
        )
        records.removeAll { $0.id == identity }
        persistCoffeeCalibrations([record] + records.sorted { $0.updatedAt > $1.updatedAt })
    }

    func generatedPourStartTime(for index: Int) -> Int {
        switch index {
        case 1: return 10 + bloomDurationSeconds
        case 2: return 75
        case 3: return 110
        default: return 145
        }
    }

    var expectedCupSweetness: String {
        createRecipeTasteGoal == "sweet" ? AppLocalization.text("high", fallback: "High") : AppLocalization.text("medium_high", fallback: "Medium-high")
    }

    var expectedCupAcidity: String {
        createRecipeTasteGoal == "bright" ? AppLocalization.text("lively", fallback: "Lively") : AppLocalization.text("balanced", fallback: "Balanced")
    }

    var expectedCupBody: String {
        createRecipeTasteGoal == "rich" ? AppLocalization.text("full", fallback: "Full") : AppLocalization.text("silky", fallback: "Silky")
    }

    var expectedCupClarity: String {
        createRecipeTasteGoal == "bright" ? AppLocalization.text("very_clear", fallback: "Very clear") : AppLocalization.text("clean", fallback: "Clean")
    }

    var expectedCupFlavourExpression: String {
        if let restoredExpectedCup { return restoredExpectedCup }
        let notes = coffeeTastingNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !notes.isEmpty {
            return "\(smartRecipe.expectedCup) Look for \(notes)."
        }
        return smartRecipe.expectedCup
    }

    func cycleGeneratedGrind() {
        let options = ["Medium-fine", "Medium", "Medium-coarse"]
        guard let index = options.firstIndex(of: generatedGrindDescription) else {
            generatedGrindDescription = options[0]
            return
        }
        generatedGrindDescription = options[(index + 1) % options.count]
    }

    func adjustGeneratedGrind(by offset: Int) {
        let options = ["Fine", "Medium-fine", "Medium", "Medium-coarse", "Coarse"]
        let currentIndex = options.firstIndex(of: generatedGrindDescription) ?? 1
        let nextIndex = max(0, min(options.count - 1, currentIndex + offset))
        generatedGrindDescription = options[nextIndex]
    }

    var generatedProcessConsiderationSummary: String {
        if let restoredApproach { return restoredApproach }
        return smartRecipe.approach
    }

    var generatedApproachNotes: String {
        if let restoredApproach { return restoredApproach }
        let notes = coffeeTastingNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        return notes.isEmpty ? smartRecipe.approach : "\(smartRecipe.approach) Look for \(notes) as the cup cools."
    }

    var generatedDecisionExplanation: String {
        var decisions = [
            "\(generatedBrewerName) determines the pour geometry and flow pattern.",
            "\(coffeeProcess.isEmpty ? "Unknown processing" : coffeeProcess) sets a \(bloomDurationSeconds)-second bloom and \(generatedAgitationLevel.lowercased()) agitation.",
            "The \(formattedRatioValue(validCoffeeAmount)) g dose and 1:\(formattedRatioValue(validRatioValue)) ratio set every cumulative water target."
        ]
        if let calibration = activeCoffeeCalibration {
            decisions.append("Talla Dial-In applied \(calibration.calibration.brewCount) saved refinement\(calibration.calibration.brewCount == 1 ? "" : "s") from earlier brews of this coffee.")
        }
        return decisions.joined(separator: " ")
    }

    func copyGeneratedRecipeToClipboard() {
        let text = generatedRecipeCopyText
#if canImport(UIKit)
        UIPasteboard.general.string = text
#endif
        createRecipeValidationMessage = AppLocalization.text("recipe_copied_friendly", fallback: "Recipe copied. You can paste it wherever you keep brew notes.")
    }

    var generatedRecipeCopyText: String {
        let rows = generatedPourRows.map { row in
            let water = row.cumulativeWater.map { "\($0) g total" } ?? "no brew water"
            return "\(row.id). \(row.title) — \(water) — \(formattedTimerTime(row.startTime))"
        }.joined(separator: "\n")
        let temperature = isClassicColdBrewRecipe ? "Room temperature" : "\(generatedTemperatureC) °C"
        let waterAndIce = isV60IcedRecipe
            ? "Hot water: \(formattedWholeGram(recipeBrewingWaterAmount)) g\nIce in server: \(formattedWholeGram(recipeIceAmount)) g"
            : "Water: \(formattedWholeGram(validWaterAmount)) g"
        let serving = isClassicColdBrewRecipe
            ? "\nServe: 1 part concentrate + 2 parts water or milk over ice"
            : ""

        return """
        \(generatedRecipeTitle)
        Coffee: \(displayCoffeeName)
        Brewer: \(generatedBrewerName)
        Goal: \(generatedTasteGoalName)
        Dose: \(formattedRatioValue(validCoffeeAmount)) g
        Ratio: 1:\(formattedRatioValue(validRatioValue))
        \(waterAndIce)
        Grind: \(generatedGrindDescription)
        Temperature: \(temperature)
        Time: \(generatedTargetTimeRange)\(serving)

        \(rows)
        """
    }

    var displayCoffeeName: String {
        let trimmed = coffeeName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? selectedCreateRecipeTitle : trimmed
    }

    var currentRecipeRecord: BrewRecipeRecord {
        BrewRecipeRecord(
            id: generatedRecipeID,
            title: generatedRecipeTitle,
            detail: generatedRecipeSubtitle,
            coffeeGrams: validCoffeeAmount,
            ratio: validRatioValue,
            totalWaterGrams: validWaterAmount,
            brewingWaterGrams: recipeBrewingWaterAmount,
            iceGrams: recipeIceAmount > 0 ? recipeIceAmount : nil,
            methodID: selectedBrewModeMethodID,
            brewerID: createRecipeBrewer,
            brewMode: recipeBrewTemperatureMode,
            bloomRatio: recipeBloomRatio,
            pourCount: recipePourCount,
            grind: generatedGrindDescription,
            temperatureC: generatedTemperatureC,
            controlMode: recipeBrewControlMode,
            process: coffeeProcess,
            roast: coffeeRoastLevel,
            grinder: recipeGrinder,
            filter: recipeFilterType,
            altitudeMeters: Int(coffeeAltitude.filter { $0.isNumber }),
            tastingNotes: coffeeTastingNotes,
            targetTimeRange: generatedTargetTimeRange,
            temperatureReason: restoredTemperatureReason ?? smartRecipe.temperatureReason,
            expectedCup: expectedCupFlavourExpression,
            approach: generatedApproachNotes,
            steps: generatedPourRows.map {
                SmartBrewStep(id: $0.id, title: $0.title, waterAdded: $0.waterAdded, cumulativeWater: $0.cumulativeWater, startTime: $0.startTime, flowRate: $0.flowRate, instruction: $0.instruction)
            },
            grinderID: coffeeData.equipmentRecords().first(where: { $0.kind == .grinder && $0.name == recipeGrinder })?.id,
            waterProfileID: selectedWaterProfileID,
            temperaturePresetID: selectedTemperaturePresetID
        )
    }

    func saveCurrentRecipe() {
        saveRecipeAction(currentRecipeRecord)
    }

    var generatedRecipeSubtitle: String {
        let brewer = brewerChoices.first { $0.id == createRecipeBrewer }?.title ?? AppLocalization.text("filter", fallback: "Filter")
        return "\(brewer) · \(recipeBrewTemperatureMode) · \(recipeBrewControlMode)"
    }

}
