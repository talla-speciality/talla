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
    var continueBrewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("continue_or_saved_recipes", fallback: "Continue Last Brew"))
                .font(sectionTitleFont)
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            if let latestBrew = brewHistoryItems.first {
                brewHistoryButton(latestBrew, isPrimary: true)
            } else {
                brewHistoryButton(currentRecipeRecord, isPrimary: true)
            }

            if brewHistoryItems.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalization.text("recent_brews", fallback: "Recent Brews"))
                        .font(Font.custom("AvenirNext-Bold", size: 10))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(tertiaryTextColor)

                    ForEach(Array(brewHistoryItems.dropFirst().prefix(2).enumerated()), id: \.offset) { _, item in
                        brewHistoryButton(item, isPrimary: false)
                    }
                }
            }
        }
        .padding(16)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var goldenRatioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("choose_your_strength", fallback: "Choose your strength"))
                .font(sectionTitleFont)
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            HStack(spacing: 8) {
                strengthRatioButton(ratio: "15", title: AppLocalization.text("strong", fallback: "Strong"))
                strengthRatioButton(ratio: "16", title: AppLocalization.text("balanced", fallback: "Balanced"))
                strengthRatioButton(ratio: "17", title: AppLocalization.text("light", fallback: "Light"))
            }

            ratioCalculatorCard
        }
        .padding(16)
        .background(cardFillColor.opacity(0.72))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var brewingCategoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(brewingCategories, id: \.self) { category in
                    Button {
                        activeCategory = category
                    } label: {
                        Text(category)
                            .font(Font.custom("AvenirNext-Bold", size: 11))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundColor(activeCategory == category ? Color(hex: 0x0A0804) : secondaryTextColor)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(activeCategory == category ? accentColor : cardFillColor)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(accentColor.opacity(activeCategory == category ? 0 : 0.18), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    func methodCard(_ method: ContentView.BrewingMethod) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            brewerIllustration(for: method)

            Text(method.name)
                .font(.system(size: isCompact ? 20 : 22, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundColor(primaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(method.summary)
                .font(Font.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(secondaryTextColor)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(methodMetaLine(for: method))
                .font(Font.custom("AvenirNext-Bold", size: 11))
                .foregroundColor(accentColor)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            HStack(spacing: 10) {
                Button {
                    if let articleURL = method.articleURL {
                        openArticleAction(articleURL)
                    } else {
                        restartBrewMode()
                    }
                } label: {
                    Text(AppLocalization.text("read_guide", fallback: "Read Guide"))
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    selectBrewModeMethod(method, start: true)
                } label: {
                    HStack(spacing: 6) {
                        Text(AppLocalization.text("brew_now", fallback: "Brew Now"))
                            .font(Font.custom("AvenirNext-Bold", size: 10))
                            .tracking(1.2)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    func brewerIllustration(for method: ContentView.BrewingMethod) -> some View {
        let methodText = ([method.name] + method.categories).joined(separator: " ").lowercased()

        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.opacity(0.10))
                .frame(height: 86)

            brewerIcon(for: methodText)
        }
    }

    @ViewBuilder
    func brewerIcon(for methodText: String) -> some View {
        if methodText.contains("chemex") {
            chemexIcon
        } else if methodText.contains("aeropress") || methodText.contains("aero press") {
            aeroPressIcon
        } else if methodText.contains("french") || methodText.contains("press") || methodText.contains("immersion") {
            frenchPressIcon
        } else if methodText.contains("arabic") || methodText.contains("dallah") || methodText.contains("traditional") {
            dallahIcon
        } else if methodText.contains("siphon") || methodText.contains("syphon") {
            siphonIcon
        } else if methodText.contains("cold") {
            coldBrewIcon
        } else {
            v60Icon
        }
    }

    var v60Icon: some View {
        VStack(spacing: 0) {
            Path { path in
                path.move(to: CGPoint(x: 8, y: 0))
                path.addLine(to: CGPoint(x: 62, y: 0))
                path.addLine(to: CGPoint(x: 49, y: 38))
                path.addLine(to: CGPoint(x: 21, y: 38))
                path.closeSubpath()
            }
            .fill(accentColor)
            .frame(width: 70, height: 38)

            Capsule()
                .fill(accentColor.opacity(0.34))
                .frame(width: 56, height: 8)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_v60_cone", fallback: "V60 cone"))
    }

    var chemexIcon: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 24, y: 0))
                path.addLine(to: CGPoint(x: 48, y: 0))
                path.addLine(to: CGPoint(x: 42, y: 22))
                path.addLine(to: CGPoint(x: 58, y: 58))
                path.addLine(to: CGPoint(x: 14, y: 58))
                path.addLine(to: CGPoint(x: 30, y: 22))
                path.closeSubpath()
            }
            .stroke(accentColor, lineWidth: 4)
            .frame(width: 72, height: 60)

            Capsule()
                .fill(accentColor)
                .frame(width: 34, height: 8)
                .offset(y: 7)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_chemex", fallback: "Chemex"))
    }

    var aeroPressIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(accentColor, lineWidth: 4)
                .frame(width: 36, height: 58)

            Capsule()
                .fill(accentColor)
                .frame(width: 54, height: 8)
                .offset(y: -34)

            Capsule()
                .fill(accentColor.opacity(0.35))
                .frame(width: 44, height: 8)
                .offset(y: 34)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_aeropress", fallback: "AeroPress"))
    }

    var frenchPressIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(accentColor, lineWidth: 3)
                .frame(width: 42, height: 50)

            Rectangle()
                .fill(accentColor)
                .frame(width: 32, height: 3)
                .offset(y: -31)

            Capsule()
                .fill(accentColor)
                .frame(width: 5, height: 28)
                .offset(y: -19)

            Path { path in
                path.move(to: CGPoint(x: 58, y: 28))
                path.addQuadCurve(to: CGPoint(x: 58, y: 46), control: CGPoint(x: 74, y: 36))
            }
            .stroke(accentColor, lineWidth: 4)
            .frame(width: 82, height: 62)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_french_press", fallback: "French press"))
    }

    var dallahIcon: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 34, y: 8))
                path.addQuadCurve(to: CGPoint(x: 26, y: 52), control: CGPoint(x: 15, y: 24))
                path.addQuadCurve(to: CGPoint(x: 54, y: 52), control: CGPoint(x: 40, y: 64))
                path.addQuadCurve(to: CGPoint(x: 44, y: 8), control: CGPoint(x: 64, y: 24))
                path.closeSubpath()
            }
            .fill(accentColor)
            .frame(width: 76, height: 64)

            Path { path in
                path.move(to: CGPoint(x: 49, y: 18))
                path.addQuadCurve(to: CGPoint(x: 72, y: 8), control: CGPoint(x: 66, y: 4))
                path.addQuadCurve(to: CGPoint(x: 60, y: 26), control: CGPoint(x: 72, y: 23))
            }
            .stroke(accentColor, lineWidth: 5)
            .frame(width: 84, height: 64)

            Capsule()
                .fill(accentColor)
                .frame(width: 8, height: 20)
                .offset(y: -34)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_arabic_dallah", fallback: "Arabic dallah"))
    }

    var siphonIcon: some View {
        ZStack {
            Circle()
                .stroke(accentColor, lineWidth: 4)
                .frame(width: 34, height: 34)
                .offset(y: -18)

            Circle()
                .stroke(accentColor, lineWidth: 4)
                .frame(width: 42, height: 42)
                .offset(y: 20)

            Rectangle()
                .fill(accentColor)
                .frame(width: 5, height: 30)

            Capsule()
                .fill(accentColor.opacity(0.35))
                .frame(width: 54, height: 7)
                .offset(y: 46)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_siphon", fallback: "Siphon"))
    }

    var coldBrewIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(accentColor, lineWidth: 4)
                .frame(width: 34, height: 58)

            Capsule()
                .fill(accentColor)
                .frame(width: 22, height: 8)
                .offset(y: -34)

            Circle()
                .fill(accentColor)
                .frame(width: 7, height: 7)
                .offset(x: 28, y: -12)

            Circle()
                .fill(accentColor.opacity(0.6))
                .frame(width: 6, height: 6)
                .offset(x: 34, y: 12)

            Image(systemName: "snowflake")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(accentColor)
                .offset(x: -30, y: 0)
        }
        .accessibilityLabel(AppLocalization.text("accessibility_cold_brew_bottle", fallback: "Cold-brew bottle"))
    }

    func methodMetaLine(for method: ContentView.BrewingMethod) -> String {
        let category = method.categories.first ?? AppLocalization.text("brewing_guide", fallback: "Brewing Guide")
        return [method.brewTime, method.difficulty, category]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " · ")
    }

    func methodTag(_ title: String) -> some View {
        Text(title)
            .font(Font.custom("AvenirNext-Bold", size: 10))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundColor(accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accentColor.opacity(0.1))
            .clipShape(Capsule())
    }

    var selectedGuideProfile: BrewGuideProfile? {
        brewGuideProfiles.first { $0.id == selectedGuideProfileID } ?? brewGuideProfiles.first
    }

    var activeSmartRecipe: BrewGuideProfile? {
        guard let activeSmartRecipeID else { return nil }
        return brewGuideProfiles.first { $0.id == activeSmartRecipeID }
    }

    var currentBrewRecipeTitle: String {
        if isGeneratedRecipeActive, !brewRecipeName.isEmpty {
            return brewRecipeName
        }
        return activeSmartRecipe?.title ?? selectedBrewModeMethod?.name ?? AppLocalization.text("custom_brew", fallback: "Custom Brew")
    }

    func matchingMethod(for profile: BrewGuideProfile) -> ContentView.BrewingMethod? {
        displayedMethods.first { method in
            let source = ([method.name, method.summary, method.detail, method.difficulty, method.brewTime] + method.categories)
                .joined(separator: " ")
                .lowercased()
            return profile.methodKeywords.contains { source.contains($0) }
        } ?? displayedMethods.first
    }

    func applyGuideProfile(_ profile: BrewGuideProfile, start: Bool) {
        restoredBrewTotalSeconds = nil
        ratioCoffeeInput = formattedRatioValue(profile.coffeeGrams)
        ratioValueInput = formattedRatioValue(profile.ratio)
        selectedGuideProfileID = profile.id
        activeSmartRecipeID = profile.id

        if let method = matchingMethod(for: profile) {
            usePublishedRecipe(method.publishedRecipe)
            if let coffeeGrams = method.publishedRecipe?.coffeeGrams {
                ratioCoffeeInput = formattedRatioValue(coffeeGrams)
            }
            if let ratio = method.publishedRecipe?.ratio {
                ratioValueInput = formattedRatioValue(ratio)
            }
            selectBrewModeMethod(method, start: start, usesSmartRecipe: true)
        } else if start {
            usePublishedRecipe(nil)
            restartBrewMode()
        }

        brewRecipeName = profile.title
    }

    func applySavedRecipe(_ recipe: BrewRecipeRecord, start: Bool) {
        restoredBrewTotalSeconds = nil
        activeSmartRecipeID = nil
        generatedRecipeID = recipe.id
        isGeneratedRecipeActive = recipe.brewMode != nil || recipe.brewerID != nil
        brewRecipeName = recipe.title
        coffeeName = recipe.title
        if let coffeeGrams = recipe.coffeeGrams {
            ratioCoffeeInput = formattedRatioValue(coffeeGrams)
        }
        if let ratio = recipe.ratio {
            ratioValueInput = formattedRatioValue(ratio)
        }

        if let brewerID = recipe.brewerID { createRecipeBrewer = brewerID }
        if let brewMode = recipe.brewMode { recipeBrewTemperatureMode = brewMode }
        if let bloomRatio = recipe.bloomRatio { recipeBloomRatio = bloomRatio }
        if let pourCount = recipe.pourCount { recipePourCount = pourCount }
        if let grind = recipe.grind { generatedGrindDescription = grind }
        if let temperatureC = recipe.temperatureC { generatedTemperatureC = temperatureC }
        if let controlMode = recipe.controlMode { recipeBrewControlMode = controlMode }
        if let process = recipe.process { coffeeProcess = process }
        if let roast = recipe.roast { coffeeRoastLevel = roast }
        if let grinder = recipe.grinder { recipeGrinder = grinder }
        if let filter = recipe.filter { recipeFilterType = filter }
        if let altitude = recipe.altitudeMeters { coffeeAltitude = String(altitude) }
        if let tastingNotes = recipe.tastingNotes { coffeeTastingNotes = tastingNotes }
        restoredRecipeSteps = recipe.steps
        restoredTargetTimeRange = recipe.targetTimeRange
        restoredTemperatureReason = recipe.temperatureReason
        restoredExpectedCup = recipe.expectedCup
        restoredApproach = recipe.approach
        usePublishedRecipe(nil)

        if let method = displayedMethods.first(where: { $0.id == recipe.methodID })
            ?? displayedMethods.first(where: { recipe.title.localizedCaseInsensitiveContains($0.name) || $0.name.localizedCaseInsensitiveContains(recipe.title) }) {
            selectBrewModeMethod(method, start: start, preserveRecipeIdentity: true)
        } else if start {
            restartBrewMode()
        }
    }

    @MainActor
    func generateBrewCoachAnswer(for profile: BrewGuideProfile) async {
        guard !isGeneratingBrewCoachAnswer else { return }
        isGeneratingBrewCoachAnswer = true
        defer { isGeneratingBrewCoachAnswer = false }

        let question = brewCoachQuestion.trimmingCharacters(in: .whitespacesAndNewlines)

#if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            if let aiAnswer = try? await foundationBrewCoachAnswer(profile: profile, question: question) {
                brewCoachAnswer = aiAnswer
                brewModeHapticTrigger += 1
                return
            }
        }
#endif

        brewCoachAnswer = fallbackBrewCoachAnswer(profile: profile, question: question)
        brewModeHapticTrigger += 1
    }

    func fallbackBrewCoachAnswer(profile: BrewGuideProfile, question: String) -> String {
        let normalized = question.lowercased()
        let savedRecipeHint = brewHistoryItems.first.map { " Your latest saved recipe is \($0.title), so compare this cup against that note." } ?? ""

        if normalized.contains("sweet") || normalized.contains("حلو") {
            return "For \(profile.title), keep \(formattedRatioValue(profile.coffeeGrams)) g coffee at 1:\(formattedRatioValue(profile.ratio)), grind slightly finer, and slow the middle pour. Sweetness usually improves when extraction is even.\(savedRecipeHint)"
        }

        if normalized.contains("acid") || normalized.contains("sour") || normalized.contains("sharp") {
            return "If the cup is sharp, raise extraction: use a slightly finer grind, hotter water, or a longer contact time. Change one thing only, then save the result as a recipe."
        }

        if normalized.contains("bitter") || normalized.contains("dry") {
            return "If it tastes bitter or dry, lower extraction: grind a little coarser, pour faster, or stop the brew earlier. Keep the same dose so the change is easy to read."
        }

        if normalized.contains("body") || normalized.contains("heavy") || normalized.contains("strong") {
            return "For more body, use a stronger ratio like 1:15 and keep agitation gentle. For a cleaner cup, move back to 1:16 or 1:17 and pour softer."
        }

        if normalized.contains("fast") || normalized.contains("quick") {
            return "If \(profile.title) finished too fast, grind finer first. For filter brews, also pour a little slower and keep the water stream lower. Keep the same dose and ratio so the next cup is easy to compare."
        }

        if normalized.contains("slow") || normalized.contains("slowly") {
            return "If \(profile.title) finished too slowly, grind coarser first. For filter brews, reduce heavy agitation and avoid choking the filter. Keep the water target the same, then taste before changing ratio."
        }

        return "\(profile.title) is a good baseline for \(profile.goal.lowercased()). Start at \(formattedRatioValue(profile.coffeeGrams)) g coffee, 1:\(formattedRatioValue(profile.ratio)), \(profile.grind) grind, and \(profile.time). Taste, adjust one variable, then save the recipe.\(savedRecipeHint)"
    }

#if canImport(FoundationModels)
    @available(iOS 26.0, macOS 26.0, *)
    func foundationBrewCoachAnswer(profile: BrewGuideProfile, question: String) async throws -> String {
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { throw BrewCoachError.unavailable }

        let savedRecipes = brewHistoryItems
            .prefix(5)
            .map { "- \($0.title): \($0.detail)" }
            .joined(separator: "\n")
        let savedContext = savedRecipes.isEmpty ? "No saved recipes yet." : savedRecipes

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You are Talla Speciality's brew coach. Give practical coffee brewing advice only. Use the selected recipe and saved recipes as context. Keep the answer under 60 words. Do not invent medical, health, or store policy claims.
            """
        )

        let prompt = """
        Selected recipe:
        \(profile.title)
        Dose: \(formattedRatioValue(profile.coffeeGrams)) g
        Ratio: 1:\(formattedRatioValue(profile.ratio))
        Grind: \(profile.grind)
        Temperature: \(profile.temperature)
        Time: \(profile.time)
        Goal: \(profile.goal)

        Saved recipes:
        \(savedContext)

        Customer question: \(question.isEmpty ? "What should I do next to improve this brew?" : question)
        """

        let response = try await session.respond(to: prompt)
        let answer = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !answer.isEmpty else { throw BrewCoachError.unavailable }
        return answer
    }
#endif

    enum BrewCoachError: Error {
        case unavailable
    }

    var validCoffeeAmount: Double {
        ratioCoffeeAmount > 0 ? ratioCoffeeAmount : 20
    }

    var createRecipeCoffeeAmount: Double {
        let value = Double(recipeCoffeeDose.replacingOccurrences(of: ",", with: ".")) ?? 0
        return value > 0 ? value : 20
    }

    var createRecipeRatioValue: Double {
        let value = Double(recipePreferredRatio.replacingOccurrences(of: ",", with: ".")) ?? 0
        return value > 0 ? value : 16
    }

    var validRatioValue: Double {
        ratioValue > 0 ? ratioValue : 16
    }

    var validWaterAmount: Double {
        max(validCoffeeAmount * validRatioValue, 1)
    }

    var brewModeWaterAmount: Double {
        isV60IcedRecipe ? recipeBrewingWaterAmount : validWaterAmount
    }

    var selectedBrewModeMethod: ContentView.BrewingMethod? {
        if let selectedBrewModeMethodID,
           let method = displayedMethods.first(where: { $0.id == selectedBrewModeMethodID }) {
            return method
        }

        return displayedMethods.first
    }

    var brewModeTotalSeconds: Int {
        if isGeneratedRecipeActive {
            return max((generatedPourRows.last?.startTime ?? 165) + 45, 1)
        }
        if let activeSmartRecipe {
            return activeSmartRecipe.targetSeconds
        }

        if let methodSeconds = selectedBrewModeMethod.flatMap({ seconds(from: $0.brewTime) }) {
            return methodSeconds
        }

        return restoredBrewTotalSeconds ?? 210
    }

    var brewModeProgress: Double {
        min(Double(brewModeElapsedSeconds) / Double(brewModeTotalSeconds), 1)
    }

    var currentBrewModeStepIndex: Int {
        let timedIndex = brewModeSteps.lastIndex { brewModeElapsedSeconds >= $0.time } ?? 0
        return min(max(timedIndex, scaleStepOverrideIndex ?? 0), brewModeSteps.count - 1)
    }

    var currentBrewModeStep: BrewModeStep {
        brewModeSteps[min(currentBrewModeStepIndex, brewModeSteps.count - 1)]
    }

    var nextBrewModeStep: BrewModeStep? {
        guard !didCompleteBrewFromScale else { return nil }
        let nextIndex = currentBrewModeStepIndex + 1
        guard brewModeElapsedSeconds < brewModeTotalSeconds, brewModeSteps.indices.contains(nextIndex) else {
            return nil
        }

        return brewModeSteps[nextIndex]
    }

    var currentWaterTarget: Double {
        if let waterTarget = currentBrewModeStep.waterTarget {
            return waterTarget
        }

        return brewModeSteps
            .prefix(currentBrewModeStepIndex + 1)
            .compactMap(\.waterTarget)
            .last ?? 0
    }

    var previousWaterTarget: Double {
        guard currentBrewModeStepIndex > 0 else { return 0 }
        return brewModeSteps
            .prefix(currentBrewModeStepIndex)
            .compactMap(\.waterTarget)
            .last ?? 0
    }

    var waterAddedThisStep: Double {
        max(currentWaterTarget - previousWaterTarget, 0)
    }

    var primaryWaterTargetText: String {
        guard currentWaterTarget > 0 else {
            return AppLocalization.text("prepare_the_brewer", fallback: "Prepare the brewer")
        }
        return "\(AppLocalization.text("pour_to", fallback: "Pour to")) \(formattedWholeGram(currentWaterTarget)) g"
    }

    var currentSuggestedFlow: String {
        if isGeneratedRecipeActive,
           let row = generatedPourRows.first(where: { $0.id == currentBrewModeStep.id }) {
            return row.flowRate
        }
        let title = currentBrewModeStep.title.lowercased()
        if currentWaterTarget <= 0 { return "—" }
        if title.contains("bloom") { return "2–3 g/s" }
        if title.contains("final") { return "3–4 g/s" }
        return "3–4 g/s"
    }

    func handleSmartScaleWeightChange(previousWeight: Double, currentWeight: Double) {
        guard isGeneratedRecipeActive,
              lastScaleAutoAdvancedStepID != currentBrewModeStep.id,
              let row = generatedPourRows.first(where: { $0.id == currentBrewModeStep.id }),
              let target = currentBrewModeStep.waterTarget,
              SmartScaleGuidanceRules.shouldAdvance(
                isConnected: scaleManager.isConnected,
                isRunning: isBrewModeRunning,
                waterAdded: row.waterAdded,
                stepTitle: row.title,
                previousWeight: previousWeight,
                currentWeight: currentWeight,
                targetWeight: target
              ) else { return }

        let completedIndex = currentBrewModeStepIndex
        lastScaleAutoAdvancedStepID = currentBrewModeStep.id
        let hasLaterPour = generatedPourRows.dropFirst(completedIndex + 1).contains { $0.waterAdded != nil }
        if brewModeSteps.indices.contains(completedIndex + 1) {
            scaleStepOverrideIndex = completedIndex + 1
        }
        lastCueStepIndex = currentBrewModeStepIndex
        lastPrePourCueStepID = nil

        if !hasLaterPour {
            completeBrewModeSession(preserveElapsedTime: true, completedFromScale: true)
            return
        }

        updateBrewLiveActivity(isPaused: !isBrewModeRunning)
        sendBrewWatchUpdate(action: "update", isPaused: !isBrewModeRunning)
        persistActiveBrewSession()
        brewStepHaptic(strong: true)
    }

    var brewModePauseResumeTitle: String {
        if isBrewModeRunning {
            return AppLocalization.text("pause", fallback: "Pause")
        }

        if brewModeElapsedSeconds > 0 {
            return AppLocalization.text("resume", fallback: "Resume")
        }

        return AppLocalization.text("start", fallback: "Start")
    }

    var focusedBrewGuidanceText: String {
        let title = currentBrewModeStep.title.lowercased()

        if title.contains("bloom") {
            return AppLocalization.text("focused_bloom_guidance", fallback: "Pour evenly until every ground is saturated, then let the coffee open before the next pour.")
        }

        if currentWaterTarget > 0 {
            return currentBrewModeStep.detail.isEmpty
                ? AppLocalization.text("focused_pour_guidance", fallback: "Pour steadily through the centre, then widen into small circles.")
                : currentBrewModeStep.detail
        }

        return currentBrewModeStep.detail
    }

    var currentTargetCompletionTime: String {
        if let nextBrewModeStep {
            return formattedTimerTime(nextBrewModeStep.time)
        }

        return formattedTimerTime(brewModeTotalSeconds)
    }

    var focusedBloomDurationText: String {
        let bloomStart = currentBrewModeStep.time
        let bloomEnd = nextBrewModeStep?.time ?? min(bloomStart + 45, brewModeTotalSeconds)
        let duration = max(bloomEnd - bloomStart, 0)

        if duration >= 35 {
            return "35–45 seconds"
        }

        return "\(duration) seconds"
    }

    var brewCompletionDifferenceText: String {
        let difference = brewModeElapsedSeconds - brewModeTotalSeconds

        if difference == 0 {
            return AppLocalization.text("on_target", fallback: "On target")
        }

        let formattedDifference = formattedTimerTime(abs(difference))
        if difference > 0 {
            return String(format: AppLocalization.text("over_target_format", fallback: "%@ over"), formattedDifference)
        }

        return String(format: AppLocalization.text("under_target_format", fallback: "%@ under"), formattedDifference)
    }

    var currentBrewPhaseName: String {
        if brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale {
            return AppLocalization.text("complete", fallback: "Complete")
        }

        let title = currentBrewModeStep.title.lowercased()
        let detail = currentBrewModeStep.detail.lowercased()

        if title.contains("rinse") || title.contains("preheat") || title.contains("prepare") {
            return AppLocalization.text("prepare", fallback: "Prepare")
        }
        if title.contains("bloom") {
            return AppLocalization.text("bloom", fallback: "Bloom")
        }
        if title.contains("wait") || detail.contains("wait") || detail.contains("steep") {
            return AppLocalization.text("wait", fallback: "Wait")
        }
        if nextBrewModeStep == nil {
            return AppLocalization.text("drawdown", fallback: "Drawdown")
        }
        if currentWaterTarget > 0 {
            return AppLocalization.text("pour", fallback: "Pour")
        }
        return AppLocalization.text("prepare", fallback: "Prepare")
    }

    func nextStepWaterTargetText(_ step: BrewModeStep) -> String {
        if let target = step.waterTarget {
            return "\(AppLocalization.text("pour_to", fallback: "Pour to")) \(formattedWholeGram(target)) g"
        }
        return step.title
    }

    var brewModePrimaryActionTitle: String {
        if isBrewModeRunning {
            return AppLocalization.text("pause", fallback: "Pause")
        }

        if brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale {
            return AppLocalization.text("rate_this_brew_save", fallback: "Rate This Brew & Save")
        }

        if brewModeElapsedSeconds > 0 {
            return AppLocalization.text("resume", fallback: "Resume")
        }

        if activeSmartRecipe != nil {
            return String(
                format: AppLocalization.text("start_named_brew", fallback: "Start %@ Brew"),
                currentBrewRecipeTitle
            )
        }

        return AppLocalization.text("start", fallback: "Start")
    }

    var brewModePrimaryActionIcon: String {
        if isBrewModeRunning {
            return "pause.fill"
        }

        if brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale {
            return "star.fill"
        }

        return "play.fill"
    }

    var brewModeSteps: [BrewModeStep] {
        if isGeneratedRecipeActive {
            return generatedPourRows.map { row in
                BrewModeStep(
                    id: row.id,
                    time: row.startTime,
                    title: row.title,
                    detail: row.instruction,
                    waterTarget: row.cumulativeWater.map(Double.init)
                )
            }
        }
        if let activeSmartRecipe {
            return smartRecipeBrewModeSteps(for: activeSmartRecipe)
        }

        let method = selectedBrewModeMethod
        let categoryText = (method?.categories.joined(separator: " ") ?? method?.name ?? "").lowercased()

        if categoryText.contains("cold") {
            return coldBrewModeSteps
        }

        if categoryText.contains("traditional") || categoryText.contains("arabic") {
            return traditionalBrewModeSteps
        }

        if categoryText.contains("immersion") || categoryText.contains("press") {
            return immersionBrewModeSteps
        }

        return pourOverBrewModeSteps
    }

    func smartRecipeBrewModeSteps(for profile: BrewGuideProfile) -> [BrewModeStep] {
        switch profile.id {
        case "v60-iced":
            let hotWater = recipeBrewingWaterAmount
            let ice = recipeIceAmount
            let bloom = hotWater * 50 / 180
            let secondTarget = hotWater * 120 / 180
            return [
                BrewModeStep(id: 0, time: 0, title: "Add \(formattedWholeGram(ice)) g ice", detail: "Put the brewing ice in the server, rinse the filter, and add \(formattedRatioValue(validCoffeeAmount)) g medium-ground coffee.", waterTarget: nil),
                BrewModeStep(id: 1, time: 5, title: "Bloom to \(formattedWholeGram(bloom)) g", detail: "Pour at 93 °C, wet every ground, and wait 10–15 seconds.", waterTarget: bloom),
                BrewModeStep(id: 2, time: 45, title: "Pour to \(formattedWholeGram(secondTarget)) g", detail: "Add water in slow circles.", waterTarget: secondTarget),
                BrewModeStep(id: 3, time: 90, title: "Finish at \(formattedWholeGram(hotWater)) g", detail: "Add the final hot water.", waterTarget: hotWater),
                BrewModeStep(id: 4, time: 135, title: "Swirl and serve over ice", detail: "Swirl the server so the brewing ice melts evenly, then pour over fresh ice.", waterTarget: hotWater)
            ]
        case "classic-cold-brew":
            let brewingWater = recipeBrewingWaterAmount
            return [
                BrewModeStep(id: 0, time: 0, title: "Add \(formattedRatioValue(validCoffeeAmount)) g coarse coffee", detail: "Use a clean jar or cold-brew bottle.", waterTarget: nil),
                BrewModeStep(id: 1, time: 30, title: "Pour to \(formattedWholeGram(brewingWater)) g", detail: "Use room-temperature filtered water and stir until every ground is wet.", waterTarget: brewingWater),
                BrewModeStep(id: 2, time: 60, title: "Steep covered", detail: "Leave at room temperature for 12–16 hours.", waterTarget: brewingWater),
                BrewModeStep(id: 3, time: 43_200, title: "Ready to filter", detail: "At 12 hours, taste the concentrate. Continue up to 16 hours for more strength.", waterTarget: brewingWater),
                BrewModeStep(id: 4, time: 50_400, title: "Filter and serve over ice", detail: "Use 1 part concentrate to 2 parts water or milk. A good serving is 100 g concentrate, 200 g mixer, and about 100 g ice.", waterTarget: brewingWater)
            ]
        case "balanced-filter":
            return [
                BrewModeStep(
                    id: 0,
                    time: 0,
                    title: "Add 20 g coffee",
                    detail: "Use a medium-fine grind, rinse the filter, warm the brewer, and level the bed.",
                    waterTarget: nil
                ),
                BrewModeStep(
                    id: 1,
                    time: 10,
                    title: "Bloom to 60 g",
                    detail: "Pour just enough 92–94 °C water to wet every ground, then let gas release.",
                    waterTarget: 60
                ),
                BrewModeStep(
                    id: 2,
                    time: 45,
                    title: "Pour to 220 g",
                    detail: "Use slow circles, keep the slurry even, and avoid pouring hard on the filter wall.",
                    waterTarget: 220
                ),
                BrewModeStep(
                    id: 3,
                    time: 90,
                    title: "Finish at 320 g",
                    detail: "Top up gently to the final 1:16 target and let the bed settle flat.",
                    waterTarget: 320
                ),
                BrewModeStep(
                    id: 4,
                    time: 210,
                    title: "Taste and save",
                    detail: "Target 3:30. If the cup is sweet and clean, save this recipe for next time.",
                    waterTarget: 320
                )
            ]
        case "espresso-base":
            return [
                BrewModeStep(id: 0, time: 0, title: "Dose 18 g coffee", detail: "Grind fine, distribute evenly, and tamp level.", waterTarget: nil),
                BrewModeStep(id: 1, time: 5, title: "Start the shot", detail: "Watch for an even flow across the basket.", waterTarget: nil),
                BrewModeStep(id: 2, time: 20, title: "Track the yield", detail: "Aim for the stream to stay steady and sweet, not pale too early.", waterTarget: nil),
                BrewModeStep(id: 3, time: 30, title: "Stop at 36 g", detail: "Taste before changing the next shot. Adjust grind first.", waterTarget: nil)
            ]
        case "french-press-sweet":
            return [
                BrewModeStep(id: 0, time: 0, title: "Add 24 g coffee", detail: "Use a coarse grind and preheat the press.", waterTarget: nil),
                BrewModeStep(id: 1, time: 10, title: "Pour to 360 g", detail: "Saturate all grounds, then stir gently.", waterTarget: 360),
                BrewModeStep(id: 2, time: 60, title: "Let sweetness build", detail: "Leave the slurry still while the coffee extracts.", waterTarget: 360),
                BrewModeStep(id: 3, time: 210, title: "Break and skim", detail: "Break the crust, skim the foam, then press slowly.", waterTarget: 360),
                BrewModeStep(id: 4, time: 240, title: "Serve fully", detail: "Pour everything out so it stops extracting in the brewer.", waterTarget: 360)
            ]
        case "arabic-majlis":
            return [
                BrewModeStep(id: 0, time: 0, title: "Measure 18 g coffee", detail: "Use a medium-coarse grind and prepare your spices if using them.", waterTarget: nil),
                BrewModeStep(id: 1, time: 45, title: "Add 324 g water", detail: "Heat gently and avoid a hard boil.", waterTarget: 324),
                BrewModeStep(id: 2, time: 150, title: "Simmer low", detail: "Keep heat calm so aroma develops without harshness.", waterTarget: 324),
                BrewModeStep(id: 3, time: 360, title: "Add spices and rest", detail: "Finish aromatics near the end, then let sediment settle.", waterTarget: 324),
                BrewModeStep(id: 4, time: 480, title: "Serve slowly", detail: "Pour cleanly into the dallah or cups.", waterTarget: 324)
            ]
        default:
            return pourOverBrewModeSteps
        }
    }

    var pourOverBrewModeSteps: [BrewModeStep] {
        let bloomWater = min(validWaterAmount, validCoffeeAmount * 3)
        let firstPourWater = min(validWaterAmount, max(bloomWater, roundedBrewTarget(validWaterAmount * 0.56)))

        return [
            BrewModeStep(
                id: 0,
                time: 0,
                title: "Add \(formattedWholeGram(validCoffeeAmount)) g coffee",
                detail: AppLocalization.text("brew_mode_step_grind", fallback: "Level the bed, start the timer, and get ready to bloom."),
                waterTarget: nil
            ),
            BrewModeStep(
                id: 1,
                time: 10,
                title: "Pour to \(formattedWholeGram(bloomWater)) g",
                detail: AppLocalization.text("brew_mode_step_bloom", fallback: "Cover all grounds and let the coffee bloom."),
                waterTarget: bloomWater
            ),
            BrewModeStep(
                id: 2,
                time: stepTime(0.22, minimum: 45),
                title: "Continue pouring to \(formattedWholeGram(firstPourWater)) g",
                detail: AppLocalization.text("brew_mode_step_main_pour", fallback: "Pour slowly in circles and keep the bed even."),
                waterTarget: firstPourWater
            ),
            BrewModeStep(
                id: 3,
                time: stepTime(0.43, minimum: 90),
                title: "Finish at \(formattedWholeGram(validWaterAmount)) g",
                detail: AppLocalization.text("brew_mode_step_finish_pour", fallback: "Use the remaining water and let the drawdown settle."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 4,
                time: stepTime(0.79, minimum: 165),
                title: AppLocalization.text("brew_mode_step_serve_title", fallback: "Serve and taste"),
                detail: AppLocalization.text("brew_mode_step_serve_detail", fallback: "Swirl, pour, and save the recipe if this cup worked."),
                waterTarget: nil
            )
        ]
    }

    var immersionBrewModeSteps: [BrewModeStep] {
        [
            BrewModeStep(
                id: 0,
                time: 0,
                title: "Add \(formattedWholeGram(validCoffeeAmount)) g coffee",
                detail: selectedBrewModeMethod?.summary ?? AppLocalization.text("immersion_step_add", fallback: "Use a medium-coarse grind and level the bed."),
                waterTarget: nil
            ),
            BrewModeStep(
                id: 1,
                time: 10,
                title: "Pour to \(formattedWholeGram(validWaterAmount)) g",
                detail: AppLocalization.text("immersion_step_pour", fallback: "Add all the water, saturate the grounds, and stir gently."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 2,
                time: stepTime(0.25, minimum: 60),
                title: AppLocalization.text("immersion_step_steep", fallback: "Let it steep"),
                detail: AppLocalization.text("immersion_step_steep_detail", fallback: "Keep the slurry still and let sweetness build."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 3,
                time: stepTime(0.82, minimum: 180),
                title: AppLocalization.text("immersion_step_finish", fallback: "Press or filter"),
                detail: AppLocalization.text("immersion_step_finish_detail", fallback: "Move slowly, then pour into a warm cup."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 4,
                time: stepTime(0.95, minimum: 210),
                title: AppLocalization.text("brew_mode_step_serve_title", fallback: "Serve and taste"),
                detail: AppLocalization.text("brew_mode_step_serve_detail", fallback: "Swirl, pour, and save the recipe if this cup worked."),
                waterTarget: nil
            )
        ]
    }

    var traditionalBrewModeSteps: [BrewModeStep] {
        [
            BrewModeStep(
                id: 0,
                time: 0,
                title: "Measure \(formattedWholeGram(validCoffeeAmount)) g coffee",
                detail: selectedBrewModeMethod?.summary ?? AppLocalization.text("traditional_step_measure", fallback: "Prepare your pot, coffee, and spices before heating."),
                waterTarget: nil
            ),
            BrewModeStep(
                id: 1,
                time: stepTime(0.10, minimum: 45),
                title: "Add \(formattedWholeGram(validWaterAmount)) g water",
                detail: AppLocalization.text("traditional_step_water", fallback: "Bring the water up gently before adding coffee."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 2,
                time: stepTime(0.36, minimum: 150),
                title: AppLocalization.text("traditional_step_simmer", fallback: "Simmer gently"),
                detail: AppLocalization.text("traditional_step_simmer_detail", fallback: "Keep the heat low and let the aroma develop."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 3,
                time: stepTime(0.72, minimum: 300),
                title: AppLocalization.text("traditional_step_settle", fallback: "Let it settle"),
                detail: AppLocalization.text("traditional_step_settle_detail", fallback: "Rest briefly so the cup pours cleanly."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 4,
                time: stepTime(0.92, minimum: 420),
                title: AppLocalization.text("traditional_step_serve", fallback: "Serve slowly"),
                detail: AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."),
                waterTarget: nil
            )
        ]
    }

    var coldBrewModeSteps: [BrewModeStep] {
        [
            BrewModeStep(
                id: 0,
                time: 0,
                title: "Add \(formattedWholeGram(validCoffeeAmount)) g coffee",
                detail: selectedBrewModeMethod?.summary ?? AppLocalization.text("cold_step_add", fallback: "Use a coarse grind and a clean jar or brewer."),
                waterTarget: nil
            ),
            BrewModeStep(
                id: 1,
                time: 30,
                title: "Pour to \(formattedWholeGram(validWaterAmount)) g",
                detail: AppLocalization.text("cold_step_pour", fallback: "Add water slowly and make sure all grounds are wet."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 2,
                time: stepTime(0.05, minimum: 120),
                title: AppLocalization.text("cold_step_steep", fallback: "Start steeping"),
                detail: AppLocalization.text("cold_step_steep_detail", fallback: "Cover and leave it chilled or at room temperature."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 3,
                time: stepTime(0.92, minimum: 600),
                title: AppLocalization.text("cold_step_filter", fallback: "Filter the brew"),
                detail: AppLocalization.text("cold_step_filter_detail", fallback: "Filter gently, then dilute or serve over ice."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 4,
                time: stepTime(0.98, minimum: 660),
                title: AppLocalization.text("cold_step_serve", fallback: "Serve chilled"),
                detail: AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."),
                waterTarget: nil
            )
        ]
    }

    func brewModeStepRow(_ step: BrewModeStep, index: Int) -> some View {
        let isActive = index == currentBrewModeStepIndex
        let isComplete = brewModeElapsedSeconds > step.time && index < currentBrewModeStepIndex

        return HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isActive ? accentColor : accentColor.opacity(isComplete ? 0.26 : 0.1))
                    .frame(width: 30, height: 30)

                Image(systemName: isComplete ? "checkmark" : "drop.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isActive ? Color(hex: 0x0A0804) : accentColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(formattedTimerTime(step.time)) - \(step.title)")
                    .font(Font.custom("AvenirNext-Bold", size: isActive ? 14 : 13))
                    .foregroundColor(isActive ? primaryTextColor : secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(step.detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(tertiaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isActive ? accentColor.opacity(0.12) : accentColor.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func brewHistoryButton(_ item: BrewRecipeRecord, isPrimary: Bool) -> some View {
        Button {
            brewRecipeName = item.title
            if let coffeeGrams = item.coffeeGrams {
                ratioCoffeeInput = formattedRatioValue(coffeeGrams)
            }
            if let ratio = item.ratio {
                ratioValueInput = formattedRatioValue(ratio)
            }
            restartBrewMode()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isPrimary ? Color(hex: 0x0A0804) : accentColor)
                    .frame(width: 28, height: 28)
                    .background(isPrimary ? Color(hex: 0x0A0804).opacity(0.10) : accentColor.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(Font.custom("AvenirNext-Bold", size: isPrimary ? 14 : 13))
                        .foregroundColor(isPrimary ? Color(hex: 0x0A0804) : primaryTextColor)
                        .lineLimit(1)

                    Text(item.detail)
                        .font(Font.custom("AvenirNext-Regular", size: 12))
                        .foregroundColor(isPrimary ? Color(hex: 0x0A0804).opacity(0.72) : secondaryTextColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                Text(AppLocalization.text("brew_again", fallback: "Brew Again"))
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(isPrimary ? Color(hex: 0x0A0804) : accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(isPrimary ? Color(hex: 0x0A0804).opacity(0.08) : accentColor.opacity(0.10))
                    .clipShape(Capsule(style: .continuous))
            }
            .padding(isPrimary ? 14 : 12)
            .background(isPrimary ? accentColor : accentColor.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func selectBrewModeMethod(
        _ method: ContentView.BrewingMethod,
        start: Bool,
        usesSmartRecipe: Bool = false,
        preserveRecipeIdentity: Bool = false
    ) {
        restoredBrewTotalSeconds = nil
        if !usesSmartRecipe {
            activeSmartRecipeID = nil
        }

        selectedBrewModeMethodID = method.id
        if !preserveRecipeIdentity {
            brewRecipeName = method.name
            isGeneratedRecipeActive = false
        }
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        brewModeBackgroundDate = nil
        brewModeRunID = UUID()
        isBrewModeRunning = false
        endBrewLiveActivity()
        brewModeHapticTrigger += 1

        if start {
            startBrewModeSession()
        }
    }

    func toggleBrewMode() {
        if isBrewModeRunning {
            brewModeRunID = UUID()
            isBrewModeRunning = false
            scaleManager.pauseTimer()
            updateBrewLiveActivity(isPaused: true)
            sendBrewWatchUpdate(action: "update", isPaused: true, allowBackgroundTransfer: true)
            brewModeHapticTrigger += 1
            return
        }

        if brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale {
            brewModeElapsedSeconds = 0
            lastCueStepIndex = -1
            lastPrePourCueStepID = nil
            lastScaleAutoAdvancedStepID = nil
            scaleStepOverrideIndex = nil
            didCompleteBrewFromScale = false
        }

        startBrewModeSession()
    }

    func handleBrewModePrimaryAction() {
        if !isBrewModeRunning, (brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale) {
            guidedBrewCompletedAction(selectedBrewModeMethod, validCoffeeAmount, validRatioValue, validWaterAmount, brewModeElapsedSeconds)
            clearPersistedBrewSession()
            isFocusedBrewPresented = false
            brewModeHapticTrigger += 1
            return
        }

        toggleBrewMode()
    }

    func restartBrewMode() {
        scaleManager.stopTimer()
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        brewModeBackgroundDate = nil
        endBrewLiveActivity()
        startBrewModeSession()
    }

    func previousBrewModeStep() {
        let previousIndex = max(currentBrewModeStepIndex - 1, 0)
        brewModeElapsedSeconds = brewModeSteps[previousIndex].time
        lastCueStepIndex = previousIndex
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = previousIndex
        didCompleteBrewFromScale = false
        updateBrewLiveActivity(isPaused: !isBrewModeRunning)
        sendBrewWatchUpdate(action: "update", isPaused: !isBrewModeRunning)
        brewStepHaptic(strong: false)
    }

    func skipBrewModeStep() {
        guard let nextBrewModeStep else {
            completeBrewModeSession()
            return
        }

        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        brewModeElapsedSeconds = nextBrewModeStep.time
        lastCueStepIndex = currentBrewModeStepIndex
        lastPrePourCueStepID = nil
        updateBrewLiveActivity(isPaused: !isBrewModeRunning)
        sendBrewWatchUpdate(action: "update", isPaused: !isBrewModeRunning)
        brewStepHaptic(strong: false)
    }

    func startBrewModeSession() {
        if activeDashboardDestination != nil {
            activeDashboardDestination = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                startBrewModeSession()
            }
            return
        }

        if brewModeElapsedSeconds == 0 {
            resetAfterBrewFeedbackState()
            lastScaleAutoAdvancedStepID = nil
            scaleStepOverrideIndex = nil
            didCompleteBrewFromScale = false
        }

        let runID = UUID()
        brewModeRunID = runID
        isBrewModeRunning = true
        isFocusedBrewPresented = true
        brewModeBackgroundDate = nil
        scaleManager.startTimer()
        brewStepHaptic(strong: false)
        startOrUpdateBrewLiveActivity()
        sendBrewWatchUpdate(action: "start", isPaused: false, allowBackgroundTransfer: true)
        persistActiveBrewSession()

        Task { @MainActor in
            while isBrewModeRunning && brewModeRunID == runID && brewModeElapsedSeconds < brewModeTotalSeconds {
                try? await Task.sleep(for: .seconds(1))
                guard isBrewModeRunning, brewModeRunID == runID else { return }
                tickBrewMode()
            }
        }
    }

    func tickBrewMode() {
        guard isBrewModeRunning else { return }

        if brewModeElapsedSeconds >= brewModeTotalSeconds {
            completeBrewModeSession()
            return
        }

        brewModeElapsedSeconds += 1
        let stepIndex = currentBrewModeStepIndex

        if stepIndex != lastCueStepIndex {
            lastCueStepIndex = stepIndex
            lastPrePourCueStepID = nil
            brewStepHaptic(strong: false)
        }

        if let nextBrewModeStep,
           nextBrewModeStep.waterTarget != nil,
           nextBrewModeStep.time - brewModeElapsedSeconds == 5,
           lastPrePourCueStepID != nextBrewModeStep.id {
            lastPrePourCueStepID = nextBrewModeStep.id
            brewStepHaptic(strong: true)
        }

        updateBrewLiveActivity(isPaused: false)
        sendBrewWatchUpdate(action: "update", isPaused: false)

        if brewModeElapsedSeconds >= brewModeTotalSeconds {
            completeBrewModeSession()
        }
    }

    func completeBrewModeSession(
        dismissLiveActivityAfter seconds: Double = 8,
        preserveElapsedTime: Bool = false,
        completedFromScale: Bool = false
    ) {
        if !preserveElapsedTime {
            brewModeElapsedSeconds = brewModeTotalSeconds
        }
        didCompleteBrewFromScale = completedFromScale
        TallaTelemetry.shared.track("brew_timer_completed", properties: [
            "method": selectedBrewModeMethod?.name ?? "custom",
            "duration_seconds": String(brewModeElapsedSeconds),
            "scale_assisted": String(completedFromScale)
        ])
        brewModeRunID = UUID()
        isBrewModeRunning = false
        brewModeBackgroundDate = nil
        scaleManager.pauseTimer()
        lastCueStepIndex = currentBrewModeStepIndex
        lastPrePourCueStepID = nil
        brewStepHaptic(strong: true, completion: true)
        persistActiveBrewSession()
        updateBrewLiveActivity(isPaused: true)
        sendBrewWatchUpdate(action: "end", isPaused: true, allowBackgroundTransfer: true)
        endBrewLiveActivity(after: seconds)
        setBrewIdleTimerDisabled(false)
    }

    func requestEndFocusedBrew() {
        if isBrewModeRunning || brewModeElapsedSeconds > 0 {
            isEndBrewConfirmationPresented = true
        } else {
            isFocusedBrewPresented = false
        }
    }

    func endFocusedBrew() {
        brewModeRunID = UUID()
        isBrewModeRunning = false
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        brewModeBackgroundDate = nil
        restoredBrewTotalSeconds = nil
        isFocusedBrewPresented = false
        scaleManager.stopTimer()
        endBrewLiveActivity()
        sendBrewWatchUpdate(action: "end", isPaused: false, allowBackgroundTransfer: true)
        clearPersistedBrewSession()
        setBrewIdleTimerDisabled(false)
    }

    func updateBrewIdleTimerState() {
        setBrewIdleTimerDisabled(isFocusedBrewPresented && (isBrewModeRunning || brewModeElapsedSeconds > 0))
    }

    func handleBrewScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background, .inactive:
            if isBrewModeRunning {
                if brewModeBackgroundDate == nil {
                    brewModeBackgroundDate = Date()
                }
                persistActiveBrewSession()
                updateBrewLiveActivity(isPaused: false)
                sendBrewWatchUpdate(action: "update", isPaused: false, allowBackgroundTransfer: true)
            }
        case .active:
            guard isBrewModeRunning, let brewModeBackgroundDate else { return }
            let elapsedDelta = max(Int(Date().timeIntervalSince(brewModeBackgroundDate)), 0)
            self.brewModeBackgroundDate = nil
            guard elapsedDelta > 0 else { return }
            brewModeElapsedSeconds = min(brewModeElapsedSeconds + elapsedDelta, brewModeTotalSeconds)
            lastCueStepIndex = currentBrewModeStepIndex
            persistActiveBrewSession()
            updateBrewLiveActivity(isPaused: false)
            sendBrewWatchUpdate(action: "update", isPaused: false)
            if brewModeElapsedSeconds >= brewModeTotalSeconds {
                completeBrewModeSession()
            }
        @unknown default:
            break
        }
    }

    func brewStepHaptic(strong: Bool, completion: Bool = false) {
        brewModeHapticTrigger += 1
#if canImport(UIKit)
        if completion {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if strong {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        }
#endif
    }

    func setBrewIdleTimerDisabled(_ isDisabled: Bool) {
#if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = isDisabled
#endif
    }

    func persistActiveBrewSession() {
        guard isCustomerSignedIn else {
            clearPersistedBrewSession()
            return
        }

        guard isFocusedBrewPresented || isBrewModeRunning || brewModeElapsedSeconds > 0 else {
            clearPersistedBrewSession()
            return
        }

        let snapshot = PersistedBrewSession(
            savedAt: Date(),
            isPresented: isFocusedBrewPresented,
            isRunning: isBrewModeRunning,
            elapsedSeconds: brewModeElapsedSeconds,
            totalSeconds: brewModeTotalSeconds,
            selectedMethodID: selectedBrewModeMethodID,
            activeSmartRecipeID: activeSmartRecipeID,
            selectedGuideProfileID: selectedGuideProfileID,
            brewRecipeName: brewRecipeName,
            ratioCoffeeInput: ratioCoffeeInput,
            ratioValueInput: ratioValueInput,
            createRecipeExperience: createRecipeExperience,
            createRecipeBrewer: createRecipeBrewer,
            createRecipeTasteGoal: createRecipeTasteGoal,
            generatedGrindDescription: generatedGrindDescription,
            generatedTemperatureC: generatedTemperatureC,
            recipePourCount: recipePourCount,
            scaleStepOverrideIndex: scaleStepOverrideIndex,
            didCompleteBrewFromScale: didCompleteBrewFromScale
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: BrewSessionStorage.activeSessionKey)
    }

    func restorePersistedBrewSessionIfNeeded() {
        guard isCustomerSignedIn else {
            resetVisibleBrewSession()
            hasRestoredPersistedBrewSession = true
            return
        }

        guard !hasRestoredPersistedBrewSession else { return }
        hasRestoredPersistedBrewSession = true

        guard
            let data = UserDefaults.standard.data(forKey: BrewSessionStorage.activeSessionKey),
            let snapshot = try? JSONDecoder().decode(PersistedBrewSession.self, from: data)
        else {
            return
        }

        selectedBrewModeMethodID = snapshot.selectedMethodID
        activeSmartRecipeID = snapshot.activeSmartRecipeID
        selectedGuideProfileID = snapshot.selectedGuideProfileID
        brewRecipeName = snapshot.brewRecipeName
        ratioCoffeeInput = snapshot.ratioCoffeeInput
        ratioValueInput = snapshot.ratioValueInput
        createRecipeExperience = snapshot.createRecipeExperience
        createRecipeBrewer = snapshot.createRecipeBrewer
        createRecipeTasteGoal = snapshot.createRecipeTasteGoal
        generatedGrindDescription = snapshot.generatedGrindDescription
        generatedTemperatureC = snapshot.generatedTemperatureC
        recipePourCount = snapshot.recipePourCount
        scaleStepOverrideIndex = snapshot.scaleStepOverrideIndex
        didCompleteBrewFromScale = snapshot.didCompleteBrewFromScale ?? false
        restoredBrewTotalSeconds = snapshot.totalSeconds

        let backgroundDelta = snapshot.isRunning ? max(Int(Date().timeIntervalSince(snapshot.savedAt)), 0) : 0
        brewModeElapsedSeconds = min(snapshot.elapsedSeconds + backgroundDelta, brewModeTotalSeconds)
        lastCueStepIndex = currentBrewModeStepIndex
        lastPrePourCueStepID = nil
        brewModeBackgroundDate = nil

        if snapshot.isPresented || brewModeElapsedSeconds > 0 || didCompleteBrewFromScale {
            isFocusedBrewPresented = true
        }

        if snapshot.isRunning && !didCompleteBrewFromScale && brewModeElapsedSeconds < brewModeTotalSeconds {
            startBrewModeSession()
        } else {
            isBrewModeRunning = false
            updateBrewLiveActivity(isPaused: false)
        }
    }

    func resetVisibleBrewSession() {
        isFocusedBrewPresented = false
        isBrewModeRunning = false
        brewModeElapsedSeconds = 0
        selectedBrewModeMethodID = nil
        activeSmartRecipeID = nil
        restoredBrewTotalSeconds = nil
        brewModeBackgroundDate = nil
        lastCueStepIndex = -1
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        endBrewLiveActivity()
        sendBrewWatchUpdate(action: "end", isPaused: false, allowBackgroundTransfer: true)
        setBrewIdleTimerDisabled(false)
        clearPersistedBrewSession()
    }

    func clearPersistedBrewSession() {
        UserDefaults.standard.removeObject(forKey: BrewSessionStorage.activeSessionKey)
    }

#if canImport(WatchConnectivity) && os(iOS)
    func sendBrewWatchUpdate(action: String, isPaused: Bool, allowBackgroundTransfer: Bool = false) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated,
              session.isPaired,
              session.isWatchAppInstalled else { return }

        let payload: [String: Any] = [
            "brewActivity": action,
            "methodName": currentBrewRecipeTitle,
            "coffeeGrams": validCoffeeAmount,
            "ratio": validRatioValue,
            "totalWaterGrams": brewModeWaterAmount,
            "totalSeconds": brewModeTotalSeconds,
            "elapsedSeconds": brewModeElapsedSeconds,
            "currentStep": currentBrewModeStep.title,
            "nextStep": nextBrewModeStep?.title ?? AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."),
            "currentWaterGrams": currentWaterTarget,
            "isPaused": isPaused,
            "stepTimes": brewModeSteps.map(\.time),
            "stepTitles": brewModeSteps.map(\.title),
            "stepWaterTargets": brewModeSteps.map { $0.waterTarget ?? -1 }
        ]

        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil)
        } else if allowBackgroundTransfer {
            session.transferUserInfo(payload)
        }
    }
#else
    func sendBrewWatchUpdate(action: String, isPaused: Bool, allowBackgroundTransfer: Bool = false) { }
#endif

    func startOrUpdateBrewLiveActivity() {
#if canImport(ActivityKit)
        guard shouldUseBrewLiveActivity, #available(iOS 16.1, *), ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if brewLiveActivity == nil {
            let attributes = TallaBrewActivityAttributes(
                methodName: currentBrewRecipeTitle,
                coffeeGrams: validCoffeeAmount,
                ratio: validRatioValue,
                totalWaterGrams: brewModeWaterAmount,
                totalSeconds: brewModeTotalSeconds,
                languageCode: AppLocalization.currentLanguage.effectiveLanguageCode
            )
            let content = ActivityContent(
                state: brewLiveActivityState(isPaused: false),
                staleDate: Date().addingTimeInterval(TimeInterval(max(brewModeTotalSeconds - brewModeElapsedSeconds, 1))),
                relevanceScore: 100
            )

            do {
                brewLiveActivity = try Activity<TallaBrewActivityAttributes>.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            } catch {
                brewLiveActivity = nil
            }
        } else {
            updateBrewLiveActivity(isPaused: false)
        }
#endif
    }

    func updateBrewLiveActivity(isPaused: Bool) {
#if canImport(ActivityKit)
        guard shouldUseBrewLiveActivity, #available(iOS 16.1, *), let brewLiveActivity else { return }

        let content = ActivityContent(
            state: brewLiveActivityState(isPaused: isPaused),
            staleDate: Date().addingTimeInterval(TimeInterval(max(brewModeTotalSeconds - brewModeElapsedSeconds, 1))),
            relevanceScore: 100
        )

        Task {
            await brewLiveActivity.update(content)
        }
#endif
    }

    func endBrewLiveActivity(after seconds: Double = 0) {
#if canImport(ActivityKit)
        guard shouldUseBrewLiveActivity, #available(iOS 16.1, *), let brewLiveActivity else { return }

        let finalContent = ActivityContent(
            state: brewLiveActivityState(isPaused: true),
            staleDate: nil,
            relevanceScore: 100
        )
        self.brewLiveActivity = nil

        Task {
            if seconds > 0 {
                await brewLiveActivity.end(finalContent, dismissalPolicy: .after(Date().addingTimeInterval(seconds)))
            } else {
                await brewLiveActivity.end(finalContent, dismissalPolicy: .immediate)
            }
        }
#endif
    }

#if canImport(ActivityKit)
    var shouldUseBrewLiveActivity: Bool {
#if canImport(UIKit)
        UIDevice.current.userInterfaceIdiom == .phone
#else
        false
#endif
    }

    @available(iOS 16.1, *)
    func brewLiveActivityState(isPaused: Bool) -> TallaBrewActivityAttributes.ContentState {
        TallaBrewActivityAttributes.ContentState(
            elapsedSeconds: brewModeElapsedSeconds,
            timerStartDate: Date().addingTimeInterval(-Double(brewModeElapsedSeconds)),
            currentStep: currentBrewModeStep.title,
            nextStep: nextBrewModeStep?.title ?? AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."),
            currentWaterGrams: currentWaterTarget,
            isPaused: isPaused,
            stepTimes: brewModeSteps.map(\.time),
            stepTitles: brewModeSteps.map(\.title),
            stepWaterTargets: brewModeSteps.map { $0.waterTarget ?? -1 }
        )
    }
#endif

    func formattedTimerTime(_ seconds: Int) -> String {
        if seconds >= 3_600 {
            let hours = seconds / 3_600
            let minutes = (seconds % 3_600) / 60
            return String(format: "%d:%02d hr", hours, minutes)
        }
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    func stepTime(_ fraction: Double, minimum: Int) -> Int {
        min(max(Int(Double(brewModeTotalSeconds) * fraction), minimum), max(brewModeTotalSeconds - 1, 0))
    }

    func seconds(from brewTime: String) -> Int? {
        let lowercasedTime = brewTime.lowercased()
        let matches = lowercasedTime.matches(of: /\d+(?:\.\d+)?/)
            .compactMap { Double($0.output) }

        guard !matches.isEmpty else { return nil }

        let value = matches.reduce(0, +) / Double(matches.count)

        if lowercasedTime.contains("hr") || lowercasedTime.contains("hour") {
            return max(Int(value * 3600), 60)
        }

        if lowercasedTime.contains("sec") {
            return max(Int(value), 30)
        }

        return max(Int(value * 60), 60)
    }

    var ratioCalculatorCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("ratio_calculator", fallback: "RATIO CALCULATOR"))
                .font(sectionTitleFont)
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            HStack(spacing: 12) {
                ratioInputField(title: AppLocalization.text("coffee_grams", fallback: "Coffee (g)"), text: $ratioCoffeeInput)
                ratioInputField(title: AppLocalization.text("ratio", fallback: "Ratio"), text: $ratioValueInput)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(formattedRatioValue(calculatedWaterAmount)) g")
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 26 : 30))
                    .foregroundColor(primaryTextColor)

                Text(AppLocalization.text("water", fallback: "water"))
                    .font(Font.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(secondaryTextColor)
            }

            Text(String(
                format: AppLocalization.text("ratio_based_on", fallback: "Based on %@ g coffee at 1:%@."),
                formattedRatioValue(ratioCoffeeAmount),
                formattedRatioValue(ratioValue)
            ))
                .font(Font.custom("AvenirNext-Regular", size: 13))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                ratioInputField(
                    title: AppLocalization.text("recipe_name", fallback: "Recipe Name"),
                    text: $brewRecipeName,
                    placeholder: AppLocalization.text("name_this_recipe", fallback: "Name this recipe"),
                    keyboardType: .default
                )

                Button(action: saveCurrentRecipe) {
                    Text(AppLocalization.text("save_recipe", fallback: "Save Recipe"))
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(2)
                        .textCase(.uppercase)
                        .foregroundColor(Color(hex: 0x0A0804))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(accentColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func brewingDetail(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .light))
                .tracking(3)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)

            Text(value)
                .font(Font.custom("AvenirNext-Bold", size: 13))
                .foregroundColor(accentColor)
        }
    }

    func strengthRatioButton(ratio: String, title: String) -> some View {
        let isSelected = ratioValueInput.trimmingCharacters(in: .whitespacesAndNewlines) == ratio

        return Button {
            ratioValueInput = ratio
        } label: {
            VStack(spacing: 3) {
                Text("1:\(ratio)")
                    .font(Font.custom("AvenirNext-Bold", size: 12))
                    .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)

                Text(title)
                    .font(Font.custom("AvenirNext-DemiBold", size: 10))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .foregroundColor(isSelected ? Color(hex: 0x0A0804).opacity(0.72) : tertiaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? accentColor : cardFillColor)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(accentColor.opacity(isSelected ? 0.0 : 0.20), lineWidth: 1)
            )
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func ratioInputField(title: String, text: Binding<String>, placeholder: String = "0", keyboardType: UIKeyboardType = .decimalPad) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 10))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .font(Font.custom("AvenirNext-Regular", size: 16))
                .foregroundColor(primaryTextColor)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(accentColor.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func formattedRatioValue(_ value: Double) -> String {
        if value == 0 { return "0" }
        if value.rounded() == value { return String(Int(value)) }
        return String(format: "%.1f", value)
    }

    func formattedWholeGram(_ value: Double) -> String {
        String(Int(value.rounded()))
    }

    func roundedBrewTarget(_ value: Double) -> Double {
        (value / 10).rounded() * 10
    }
}
