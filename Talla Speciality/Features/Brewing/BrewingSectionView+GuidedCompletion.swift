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
    var bluetoothScalePickerFootnote: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(brewAccentColor)
                .padding(.top, 1)

            Text(AppLocalization.text("scale_optional_detail", fallback: "A scale is optional. You can close this sheet and continue with the guided timer at any time."))
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 2)
        .accessibilityElement(children: .combine)
    }

    func focusedMetricRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 11))
                .tracking(AppLocalization.letterSpacing(1.0))
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)

            Spacer(minLength: 12)

            Text(value)
                .font(Font.custom("AvenirNext-DemiBold", size: 15))
                .foregroundColor(brewPrimaryTextColor)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(brewBorderColor.opacity(0.7))
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }

    var focusedNextStepPreview: some View {
        Group {
            if let nextBrewModeStep {
                Text(String(format: AppLocalization.text("next_step_preview_format", fallback: "Next: %@ at %@"), nextStepWaterTargetText(nextBrewModeStep), formattedTimerTime(nextBrewModeStep.time)))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(AppLocalization.text("next_complete_preview", fallback: "Next: Complete"))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewSecondaryTextColor)
            }
        }
    }

    var focusedBrewTimeline: some View {
        HStack(spacing: 8) {
            ForEach(Array(brewModeSteps.enumerated()), id: \.element.id) { index, step in
                let isComplete = index < currentBrewModeStepIndex
                let isCurrent = index == currentBrewModeStepIndex

                HStack(spacing: 8) {
                    Text(isComplete ? "✓" : "\(index + 1)")
                        .font(Font.custom("AvenirNext-DemiBold", size: 10))
                        .foregroundColor(isCurrent ? brewAccentColor : isComplete ? brewPrimaryTextColor : brewSecondaryTextColor.opacity(0.75))
                        .frame(width: 18, height: 18)

                    if index < brewModeSteps.count - 1 {
                        Rectangle()
                            .fill(isComplete ? brewAccentColor.opacity(0.75) : brewBorderColor)
                            .frame(height: isCurrent ? 2 : 1)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(step.title)
                .accessibilityValue(isComplete ? AppLocalization.text("complete", fallback: "Complete") : isCurrent ? AppLocalization.text("current", fallback: "Current") : AppLocalization.text("upcoming", fallback: "Upcoming"))
            }
        }
    }

    var focusedAfterBrewView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                focusedCompletionTopBar
                focusedBrewCompletionSummary
                if capturedBrewSamples.contains(where: { $0.kind == .weight }) {
                    BrewTelemetryChart(samples: capturedBrewSamples, accent: brewAccentColor)
                        .frame(height: isCompact ? 132 : 170)
                }

                if isAfterBrewFeedbackExpanded {
                    Text(AppLocalization.text("how_did_this_cup_taste", fallback: "How did this cup taste?"))
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 30 : 38))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)

                    afterBrewChangeSection
                    afterBrewMoreOfSection
                    afterBrewNotesSection

                    if !recipeRevisionChanges.isEmpty {
                        afterBrewRevisionSection
                    }

                    afterBrewActions
                } else {
                    brewMeasurementActions
                    focusedCompletionActions
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
    }

    var focusedCompletionTopBar: some View {
        HStack {
            Spacer()

            Button {
                isFocusedBrewPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(width: 44, height: 44)
                    .background(brewSurfaceColor)
                    .overlay(
                        Circle()
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))
        }
    }

    var focusedBrewCompletionSummary: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalization.text("brew_complete", fallback: "Brew complete"))
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 38 : 52))
                    .foregroundColor(brewPrimaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(displayCoffeeName)
                    .font(Font.custom("AvenirNext-Regular", size: 16))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                focusedMetricRow(title: AppLocalization.text("final_brew_time", fallback: "Final brew time"), value: formattedTimerTime(brewModeElapsedSeconds))
                focusedMetricRow(title: AppLocalization.text("target_range", fallback: "Target range"), value: generatedTargetTimeRange)
                focusedMetricRow(title: AppLocalization.text("difference_from_target", fallback: "Difference from target"), value: brewCompletionDifferenceText)
                if let caffeineMilligrams = TallaCaffeineEstimator.estimate(
                    milligramsForDoseGrams: validCoffeeAmount,
                    method: selectedBrewModeMethod?.name ?? "Filter"
                ) {
                    focusedMetricRow(
                        title: AppLocalization.text("estimated_caffeine", fallback: "Estimated caffeine"),
                        value: "\(Int(caffeineMilligrams)) mg"
                    )
                }
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(brewBorderColor)
                    .frame(height: 1)
            }
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(brewBorderColor)
                    .frame(height: 1)
            }
        }
    }

    var focusedCompletionActions: some View {
        VStack(spacing: 10) {
            Button {
                isAfterBrewFeedbackExpanded = true
                brewStepHaptic(strong: false)
            } label: {
                Text(AppLocalization.text("refine_next_brew", fallback: "Refine Next Brew"))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewAccentForegroundColor)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(brewAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                isFocusedBrewPresented = false
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(220))
                    activeDashboardDestination = .brewCoach
                }
            } label: {
                Text(AppLocalization.text("open_brew_coach", fallback: "Open Brew Coach"))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                saveAfterBrewToJournal()
            } label: {
                Text(AppLocalization.text("save_to_journal", fallback: "Save to Journal"))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    var afterBrewChangeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalization.text("cup_taste_prompt", fallback: "Select every note that fits. Talla will change only what needs changing."))
                .font(Font.custom("AvenirNext-Regular", size: 15))
                .foregroundColor(brewSecondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 142 : 164), spacing: 8)], spacing: 8) {
                ForEach(afterBrewFeedbackOptions, id: \.self) { option in
                    afterBrewChip(option, selection: $afterBrewSelections)
                }
            }
        }
    }

    var afterBrewMoreOfSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("what_would_you_like_more_of", fallback: "What would you like more of?"))
                .font(Font.custom("AvenirNext-DemiBold", size: 16))
                .foregroundColor(brewPrimaryTextColor)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 120 : 148), spacing: 8)], spacing: 8) {
                ForEach(afterBrewMoreOfOptions, id: \.self) { option in
                    afterBrewChip(option, selection: $afterBrewMoreOfSelections)
                }
            }
        }
    }

    var afterBrewNotesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("tasting_notes_optional", fallback: "Tasting notes optional"))
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(AppLocalization.letterSpacing(1.8))
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            TextEditor(text: $afterBrewNotes)
                .font(Font.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(primaryTextColor)
                .frame(minHeight: 112)
                .scrollContentBackground(.hidden)
                .padding(12)
                .background(cardFillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(accentColor.opacity(0.14), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityLabel(AppLocalization.text("tasting_notes", fallback: "Tasting notes"))
        }
    }

    var afterBrewRevisionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalization.text("tallas_next_adjustment", fallback: "Talla’s next adjustment"))
                .font(Font.custom("Georgia-Bold", size: 24))
                .foregroundColor(brewPrimaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(recipeRevisionChanges) { change in
                VStack(alignment: .leading, spacing: 8) {
                    Text(change.title)
                        .font(brewEyebrowFont)
                        .foregroundColor(brewAccentColor)

                    Text("\(change.before) → \(change.after)")
                        .font(Font.custom("AvenirNext-DemiBold", size: 16))
                        .foregroundColor(brewPrimaryTextColor)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)

                    Text(change.reason)
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(brewSecondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(brewBorderColor.opacity(0.75))
                        .frame(height: 1)
                }
            }

            focusedRecipeCard

            if let revisedRecipeVersionTitle {
                Text(String(format: AppLocalization.text("saved_new_recipe_version", fallback: "Saved as a new version: %@"), revisedRecipeVersionTitle))
                    .font(Font.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundColor(brewAccentColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var focusedRecipeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(brewRecipeName.isEmpty ? AppLocalization.text("talla_brew", fallback: "Talla Brew") : brewRecipeName)
                    .font(Font.custom("Georgia-Bold", size: 22))
                    .foregroundColor(brewPrimaryTextColor)
                    .lineLimit(2)

                Spacer(minLength: 8)

                Image(systemName: "bookmark.fill")
                    .foregroundColor(brewAccentColor)
                    .accessibilityHidden(true)
            }

            HStack(spacing: 8) {
                brewRecipeStat(AppLocalization.text("method", fallback: "Method"), selectedBrewModeMethod?.name ?? AppLocalization.text("filter", fallback: "Filter"))
                brewRecipeStat(AppLocalization.text("dose", fallback: "Dose"), "\(formattedRatioValue(validCoffeeAmount)) g")
                brewRecipeStat(AppLocalization.text("ratio", fallback: "Ratio"), "1:\(formattedRatioValue(validRatioValue))")
            }

            Button(action: saveCurrentRecipe) {
                Label(AppLocalization.text("save_recipe", fallback: "Save Recipe"), systemImage: "bookmark.fill")
                    .font(Font.custom("AvenirNext-DemiBold", size: 13))
                    .foregroundColor(brewAccentForegroundColor)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(brewAccentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(brewSurfaceColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(brewBorderColor, lineWidth: 1))
    }

    func brewRecipeStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundColor(brewSecondaryTextColor)
                .textCase(.uppercase)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(brewPrimaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var afterBrewActions: some View {
        VStack(spacing: 10) {
            if let productID = completedBrewProductID {
                afterBrewActionButton(
                    title: AppLocalization.text("reorder_this_coffee", fallback: "Reorder this coffee"),
                    isPrimary: true
                ) {
                    reorderCoffeeAction(productID)
                }
            }
            brewMeasurementActions
            recipeAdjustmentActions
        }
    }

    var completedBrewProductID: String? {
        guard let purchasedCoffeeID = selectedPurchasedCoffeeID,
              let purchase = coffeeData.inventory().first(where: { $0.id == purchasedCoffeeID }),
              let lotID = purchase.lotID else { return nil }
        return coffeeData.beanLots().first(where: { $0.id == lotID })?.productID
    }

    @ViewBuilder
    var brewMeasurementActions: some View {
            HStack(spacing: 8) {
                Button {
                    BrewReferenceStore.save(capturedBrewSamples)
                    UserDefaults.standard.set(true, forKey: "talla.brewing.hasReferenceCurve.v1")
                    UserDefaults.standard.set(true, forKey: "talla.brewing.referencePending.v1")
                } label: {
                    Label("Mark as best", systemImage: "star.fill")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.tallaSecondary)

                Button {
                    isAfterBrewFeedbackExpanded = false
                    restartBrewMode()
                } label: {
                    Label("Repeat best", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.tallaPrimary)
            }

            if !BrewReferenceStore.load().isEmpty {
                BrewTelemetryComparisonChart(reference: BrewReferenceStore.load(), attempt: capturedBrewSamples)
                    .frame(height: isCompact ? 112 : 150)
            }

            BrewShareCardView(title: brewRecipeName.isEmpty ? "Talla Brew" : brewRecipeName,
                              method: selectedBrewModeMethod?.name ?? "Brew",
                              finalWeight: capturedBrewSamples.last(where: { $0.kind == .weight })?.value,
                              duration: Double(brewModeElapsedSeconds))
                .frame(minHeight: 92)

            if let payload = ShareableBrewCard(
                title: brewRecipeName.isEmpty ? "Talla Brew" : brewRecipeName,
                method: selectedBrewModeMethod?.name ?? "Brew",
                doseGrams: validCoffeeAmount,
                finalWeightGrams: capturedBrewSamples.last(where: { $0.kind == .weight })?.value,
                durationSeconds: Double(brewModeElapsedSeconds),
                curve: capturedBrewSamples.filter { $0.kind == .weight }.map { BrewCurvePoint(id: UUID(), seconds: Double($0.elapsedMilliseconds) / 1000, weightGrams: $0.value, flowGramsPerSecond: nil) },
                isReference: false
            ).payload,
               let shareText = String(data: payload, encoding: .utf8) {
                ShareLink(item: shareText, subject: Text("My Talla brew"), message: Text("Measured brew curve")) {
                    Label("Share brew card", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.tallaSecondary)
            }
    }

    var recipeAdjustmentActions: some View {
        VStack(spacing: 10) {
            if recipeRevisionChanges.isEmpty {
                afterBrewActionButton(
                    title: AppLocalization.text("show_next_adjustment", fallback: "Show Talla’s next adjustment"),
                    isPrimary: true
                ) {
                    prepareNextBrewAdjustment()
                }
            } else {
                afterBrewActionButton(
                    title: AppLocalization.text("save_as_version_2", fallback: "Save as Version 2"),
                    isPrimary: true
                ) {
                    saveRevisedRecipeVersion()
                }

                afterBrewActionButton(
                    title: AppLocalization.text("brew_revised_recipe", fallback: "Brew Revised Recipe"),
                    isPrimary: false
                ) {
                    brewRevisedRecipe()
                }
            }

            afterBrewActionButton(
                title: AppLocalization.text("keep_original", fallback: "Keep Original"),
                isPrimary: false
            ) {
                keepOriginalRecipe()
            }
        }
    }

    var afterBrewFeedbackOptions: [String] {
        [
            "Bright and pleasant",
            "Too sour",
            "Balanced",
            "Sweet",
            "Too bitter",
            "Too weak",
            "Too heavy",
            "Dry or astringent",
            "Flat",
            "Brewed too quickly",
            "Brewed too slowly"
        ]
    }

    var afterBrewMoreOfOptions: [String] {
        [
            "Sweetness",
            "Clarity",
            "Body",
            "Acidity",
            "Balance"
        ]
    }

    func afterBrewChip(_ option: String, selection: Binding<Set<String>>) -> some View {
        let isSelected = selection.wrappedValue.contains(option)

        return Button {
            if isSelected {
                selection.wrappedValue.remove(option)
            } else {
                selection.wrappedValue.insert(option)
            }
            recipeRevisionChanges = []
            revisedRecipeVersionTitle = nil
            brewStepHaptic(strong: false)
        } label: {
            Text(option)
                .font(Font.custom("AvenirNext-DemiBold", size: 12))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundColor(isSelected ? Color(hex: 0x1C1A17) : brewPrimaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .background(isSelected ? brewAccentColor.opacity(0.32) : brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? brewAccentColor : brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    func saveAfterBrewToJournal() {
        saveAfterBrewJournalEntryIfNeeded()
        saveCurrentRecipe()
        clearPersistedBrewSession()
        brewModeRunID = UUID()
        isBrewModeRunning = false
        brewModeElapsedSeconds = 0
        isFocusedBrewPresented = false

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            activeDashboardDestination = .coffeeJournal
        }
    }

    func afterBrewActionButton(title: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 14))
                .foregroundColor(isPrimary ? brewAccentForegroundColor : brewPrimaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(isPrimary ? brewAccentColor : brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isPrimary ? Color.clear : brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func prepareNextBrewAdjustment() {
        saveAfterBrewJournalEntryIfNeeded()
        recipeRevisionChanges = conservativeRecipeChanges()
        revisedRecipeVersionTitle = nil
        brewStepHaptic(strong: true)
    }

    func improveNextBrew() {
        saveAfterBrewJournalEntryIfNeeded()

        let changes = conservativeRecipeChanges()
        recipeRevisionChanges = changes

        saveRevisedRecipeVersion()
    }

    func saveRevisedRecipeVersion() {
        saveAfterBrewJournalEntryIfNeeded()

        if recipeRevisionChanges.isEmpty {
            recipeRevisionChanges = conservativeRecipeChanges()
        }

        let baseTitle = brewRecipeName.isEmpty ? currentBrewRecipeTitle : brewRecipeName
        let versionTitle = "\(baseTitle) v\(brewHistoryItems.count + 2)"
        revisedRecipeVersionTitle = versionTitle

        rememberTallaDialInCalibration(from: recipeRevisionChanges)
        applyRecipeRevisionChanges(recipeRevisionChanges)

        brewRecipeName = versionTitle
        saveCurrentRecipe()
        brewStepHaptic(strong: true)
    }

    func brewRevisedRecipe() {
        saveRevisedRecipeVersion()
        brewImprovedRecipeAgain()
    }

    func keepOriginalRecipe() {
        saveAfterBrewJournalEntryIfNeeded()
        saveCurrentRecipe()
        clearPersistedBrewSession()
        brewModeRunID = UUID()
        isBrewModeRunning = false
        brewModeElapsedSeconds = 0
        isFocusedBrewPresented = false
    }

    func applyRecipeRevisionChanges(_ changes: [RecipeRevisionChange]) {
        restoredRecipeSteps = nil
        restoredTargetTimeRange = nil
        restoredTemperatureReason = nil
        restoredExpectedCup = nil
        restoredApproach = nil
        if let grindChange = changes.first(where: { $0.id == "grind" }) {
            generatedGrindDescription = grindChange.after
        }

        if let temperatureChange = changes.first(where: { $0.id == "temperature" }) {
            generatedTemperatureC = Int(temperatureChange.after.filter(\.isNumber)) ?? generatedTemperatureC
        }

        if let ratioChange = changes.first(where: { $0.id == "ratio" }),
           let newRatio = ratioChange.after.split(separator: ":").last {
            ratioValueInput = String(newRatio)
        }

        if changes.contains(where: { $0.id == "time" }) {
            recipePourCount = min(recipePourCount + 1, 5)
        }
    }

    func saveAfterBrewJournalEntryIfNeeded() {
        guard !isAfterBrewSavedToJournal else { return }
        let feedbackTags = Array(afterBrewSelections.union(afterBrewMoreOfSelections)).sorted()
        guidedBrewCompletedAction(selectedBrewModeMethod, validCoffeeAmount, validRatioValue, validWaterAmount, brewModeElapsedSeconds, selectedPurchasedCoffeeID, capturedBrewSamples, feedbackTags, afterBrewNotes)
        isAfterBrewSavedToJournal = true
    }

    func brewImprovedRecipeAgain() {
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        lastPrePourCueStepID = nil
        lastScaleAutoAdvancedStepID = nil
        scaleStepOverrideIndex = nil
        didCompleteBrewFromScale = false
        brewModeBackgroundDate = nil
        restoredBrewTotalSeconds = nil
        recipeRevisionChanges = []
        revisedRecipeVersionTitle = nil
        isAfterBrewSavedToJournal = false
        startBrewModeSession()
    }

    func resetAfterBrewFeedbackState() {
        afterBrewRating = 0
        afterBrewSelections = []
        afterBrewMoreOfSelections = []
        afterBrewNotes = ""
        recipeRevisionChanges = []
        revisedRecipeVersionTitle = nil
        isAfterBrewSavedToJournal = false
        isAfterBrewFeedbackExpanded = false
    }

    func conservativeRecipeChanges() -> [RecipeRevisionChange] {
        if afterBrewSelections.contains("Balanced") || afterBrewSelections.contains("Sweet") || afterBrewSelections.contains("Bright and pleasant") {
            guard afterBrewMoreOfSelections.isEmpty else {
                return conservativeMoreOfChanges(currentRatio: max(validRatioValue, 1))
            }

            return [
                RecipeRevisionChange(
                    id: "same",
                    title: AppLocalization.text("recipe", fallback: "Recipe"),
                    before: AppLocalization.text("current_version", fallback: "Current version"),
                    after: AppLocalization.text("saved_unchanged", fallback: "Saved unchanged"),
                    reason: AppLocalization.text("perfect_reason", fallback: "You marked the cup as perfect, so Talla keeps the recipe intact and saves a repeatable version.")
                )
            ]
        }

        var changes: [RecipeRevisionChange] = []
        let selected = afterBrewSelections
        let moreOf = afterBrewMoreOfSelections
        let currentRatio = max(validRatioValue, 1)

        if selected.contains("Too sour") {
            changes.append(
                RecipeRevisionChange(
                    id: "grind",
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    before: generatedGrindDescription,
                    after: finerGrind(from: generatedGrindDescription),
                    reason: AppLocalization.text("too_sour_grind_reason", fallback: "A slightly finer grind raises extraction gently before changing several variables.")
                )
            )
            if selected.contains("Brewed too quickly") {
                changes.append(timeChange(after: "3:05–3:35", reason: AppLocalization.text("too_fast_time_reason", fallback: "The brew finished fast, so the next version aims for a little more contact time.")))
            }
            return uniqueChanges(changes)
        }

        if selected.contains("Too bitter") || selected.contains("Dry or astringent") {
            changes.append(
                RecipeRevisionChange(
                    id: "grind",
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    before: generatedGrindDescription,
                    after: coarserGrind(from: generatedGrindDescription),
                    reason: AppLocalization.text("too_bitter_grind_reason", fallback: "A slightly coarser grind lowers extraction without flattening the cup.")
                )
            )
            if generatedTemperatureC > 92 {
                changes.append(
                    RecipeRevisionChange(
                        id: "temperature",
                        title: AppLocalization.text("temperature", fallback: "Temperature"),
                        before: "\(generatedTemperatureC) °C",
                        after: "\(generatedTemperatureC - 1) °C",
                        reason: AppLocalization.text("too_bitter_temp_reason", fallback: "A small temperature drop softens bitterness while staying in a safe brewing range.")
                    )
                )
            }
            return uniqueChanges(changes)
        }

        if selected.contains("Too weak") {
            changes.append(
                RecipeRevisionChange(
                    id: "ratio",
                    title: AppLocalization.text("ratio", fallback: "Ratio"),
                    before: "1:\(formattedRatioValue(currentRatio))",
                    after: "1:\(formattedRatioValue(max(currentRatio - 1, 12)))",
                    reason: AppLocalization.text("too_weak_ratio_reason", fallback: "A slightly stronger ratio adds concentration without overcomplicating the brew.")
                )
            )
            return uniqueChanges(changes)
        }

        if selected.contains("Too heavy") {
            changes.append(
                RecipeRevisionChange(
                    id: "grind",
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    before: generatedGrindDescription,
                    after: coarserGrind(from: generatedGrindDescription),
                    reason: AppLocalization.text("too_heavy_grind_reason", fallback: "A coarser grind and gentler flow reduce weight while keeping sweetness.")
                )
            )
            changes.append(
                RecipeRevisionChange(
                    id: "agitation",
                    title: AppLocalization.text("agitation", fallback: "Agitation"),
                    before: generatedAgitationLevel,
                    after: AppLocalization.text("gentle", fallback: "Gentle"),
                    reason: AppLocalization.text("too_heavy_agitation_reason", fallback: "Lower agitation keeps fines from clogging the brew bed.")
                )
            )
            return uniqueChanges(changes)
        }

        if selected.contains("Flat") || moreOf.contains("Clarity") || moreOf.contains("Acidity") {
            changes.append(
                RecipeRevisionChange(
                    id: "temperature",
                    title: AppLocalization.text("temperature", fallback: "Temperature"),
                    before: "\(generatedTemperatureC) °C",
                    after: "\(min(generatedTemperatureC + 1, 94)) °C",
                    reason: AppLocalization.text("flat_temp_reason", fallback: "A small heat increase can lift clarity without making the recipe aggressive.")
                )
            )
            return uniqueChanges(changes)
        }

        if selected.contains("Brewed too quickly") {
            changes.append(
                RecipeRevisionChange(
                    id: "grind",
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    before: generatedGrindDescription,
                    after: finerGrind(from: generatedGrindDescription),
                    reason: AppLocalization.text("too_fast_grind_reason", fallback: "A slightly finer grind slows flow before changing dose or ratio.")
                )
            )
            return uniqueChanges(changes)
        }

        if selected.contains("Brewed too slowly") {
            changes.append(
                RecipeRevisionChange(
                    id: "grind",
                    title: AppLocalization.text("grind", fallback: "Grind"),
                    before: generatedGrindDescription,
                    after: coarserGrind(from: generatedGrindDescription),
                    reason: AppLocalization.text("too_slow_grind_reason", fallback: "A slightly coarser grind helps the brew finish cleanly without changing the cup style.")
                )
            )
            return uniqueChanges(changes)
        }

        if moreOf.contains("Sweetness") {
            changes.append(timeChange(after: "3:05–3:35", reason: AppLocalization.text("sweeter_time_reason", fallback: "A little more contact time often brings sweetness forward. Keep the rest stable for comparison.")))
            return uniqueChanges(changes)
        }

        if moreOf.contains("Body") {
            changes.append(
                RecipeRevisionChange(
                    id: "ratio",
                    title: AppLocalization.text("ratio", fallback: "Ratio"),
                    before: "1:\(formattedRatioValue(currentRatio))",
                    after: "1:\(formattedRatioValue(max(currentRatio - 1, 12)))",
                    reason: AppLocalization.text("more_body_ratio_reason", fallback: "A modestly stronger ratio adds body while preserving the same workflow.")
                )
            )
            return uniqueChanges(changes)
        }

        if moreOf.contains("Balance") {
            changes.append(
                RecipeRevisionChange(
                    id: "time",
                    title: AppLocalization.text("target_time", fallback: "Target time"),
                    before: generatedTargetTimeRange,
                    after: "3:00–3:30",
                    reason: AppLocalization.text("more_balance_time_reason", fallback: "A tighter target keeps the next brew centred without changing grind, temperature, and ratio together.")
                )
            )
            return uniqueChanges(changes)
        }

        return [
            RecipeRevisionChange(
                id: "notes",
                title: AppLocalization.text("recipe_notes", fallback: "Recipe notes"),
                before: AppLocalization.text("first_version", fallback: "First version"),
                after: AppLocalization.text("new_version_saved", fallback: "New version saved"),
                reason: AppLocalization.text("notes_only_reason", fallback: "No flaw was selected, so Talla saves the tasting notes as the next recipe version.")
            )
        ]
    }

    func conservativeMoreOfChanges(currentRatio: Double) -> [RecipeRevisionChange] {
        if afterBrewMoreOfSelections.contains("Sweetness") {
            return [timeChange(after: "3:05–3:35", reason: AppLocalization.text("sweeter_time_reason", fallback: "A little more contact time often brings sweetness forward. Keep the rest stable for comparison."))]
        }

        if afterBrewMoreOfSelections.contains("Clarity") || afterBrewMoreOfSelections.contains("Acidity") {
            return [
                RecipeRevisionChange(
                    id: "temperature",
                    title: AppLocalization.text("temperature", fallback: "Temperature"),
                    before: "\(generatedTemperatureC) °C",
                    after: "\(min(generatedTemperatureC + 1, 94)) °C",
                    reason: AppLocalization.text("clarity_temp_reason", fallback: "A one-degree lift can brighten the cup while keeping the rest of the recipe comparable.")
                )
            ]
        }

        if afterBrewMoreOfSelections.contains("Body") {
            return [
                RecipeRevisionChange(
                    id: "ratio",
                    title: AppLocalization.text("ratio", fallback: "Ratio"),
                    before: "1:\(formattedRatioValue(currentRatio))",
                    after: "1:\(formattedRatioValue(max(currentRatio - 1, 12)))",
                    reason: AppLocalization.text("more_body_ratio_reason", fallback: "A modestly stronger ratio adds body while preserving the same workflow.")
                )
            ]
        }

        return [
            RecipeRevisionChange(
                id: "time",
                title: AppLocalization.text("target_time", fallback: "Target time"),
                before: generatedTargetTimeRange,
                after: "3:00–3:30",
                reason: AppLocalization.text("more_balance_time_reason", fallback: "A tighter target keeps the next brew centred without changing grind, temperature, and ratio together.")
            )
        ]
    }

    func timeChange(after: String, reason: String) -> RecipeRevisionChange {
        RecipeRevisionChange(
            id: "time",
            title: AppLocalization.text("final_target_time", fallback: "Final target time"),
            before: generatedTargetTimeRange,
            after: after,
            reason: reason
        )
    }

    func uniqueChanges(_ changes: [RecipeRevisionChange]) -> [RecipeRevisionChange] {
        var seen = Set<String>()
        return changes.filter { change in
            guard !seen.contains(change.id) else { return false }
            seen.insert(change.id)
            return true
        }
    }

    func finerGrind(from grind: String) -> String {
        switch grind {
        case "Medium-coarse": return "Medium"
        case "Medium": return "Medium-fine"
        case "Medium-fine": return "Fine-medium"
        default: return "Medium-fine"
        }
    }

    func coarserGrind(from grind: String) -> String {
        switch grind {
        case "Fine-medium": return "Medium-fine"
        case "Medium-fine": return "Medium"
        case "Medium": return "Medium-coarse"
        default: return "Medium"
        }
    }

    var focusedBrewControls: some View {
        VStack(spacing: 10) {
            focusedControlButton(
                title: brewModePauseResumeTitle,
                systemImage: isBrewModeRunning ? "pause.fill" : "play.fill",
                isPrimary: true
            ) {
                toggleBrewMode()
            }

            HStack(spacing: 8) {
                focusedControlButton(
                    title: AppLocalization.text("previous", fallback: "Previous"),
                    systemImage: "chevron.backward",
                    isPrimary: false
                ) {
                    previousBrewModeStep()
                }

                focusedControlButton(
                    title: AppLocalization.text("next", fallback: "Next"),
                    systemImage: "chevron.forward",
                    isPrimary: false
                ) {
                    skipBrewModeStep()
                }

                focusedControlButton(
                    title: AppLocalization.text("end_brew", fallback: "End Brew"),
                    systemImage: "xmark",
                    isPrimary: false
                ) {
                    requestEndFocusedBrew()
                }
            }
        }
    }

    func focusedControlButton(title: String, systemImage: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Font.custom("AvenirNext-DemiBold", size: isPrimary ? 14 : 12))
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .foregroundColor(isPrimary ? brewAccentForegroundColor : brewPrimaryTextColor)
                .frame(maxWidth: .infinity)
                .frame(minHeight: isPrimary ? 54 : 50)
                .background(isPrimary ? brewAccentColor : brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(isPrimary ? Color.clear : brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

}
