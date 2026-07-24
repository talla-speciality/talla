import Foundation
import SwiftUI

struct BrewingSectionView: View {
    private struct BrewModeStep: Identifiable {
        let id: Int
        let time: Int
        let title: String
        let detail: String
        let waterTarget: Double?
    }

    let isCompact: Bool
    let primaryTextColor: Color
    let secondaryTextColor: Color
    let tertiaryTextColor: Color
    let cardFillColor: Color
    let accentColor: Color
    let displayedMethods: [ContentView.BrewingMethod]
    let brewingCategories: [String]
    let gridColumns: [GridItem]
    let isLoadingMethods: Bool
    let methodsAreEmpty: Bool
    let methodsError: String?
    @Binding var activeCategory: String
    @Binding var ratioCoffeeInput: String
    @Binding var ratioValueInput: String
    @Binding var brewRecipeName: String
    let calculatedWaterAmount: Double
    let ratioCoffeeAmount: Double
    let ratioValue: Double
    let brewHistoryItems: [(title: String, detail: String)]
    let titleFont: Font
    let sectionTitleFont: Font
    let bodyFont: Font
    let labelFont: Font
    let saveRecipeAction: () -> Void
    let openArticleAction: (URL) -> Void
    let brewTimerSection: AnyView
    let coffeeJournalSection: AnyView
    let loadingView: AnyView
    @State private var isBrewModeRunning = false
    @State private var brewModeElapsedSeconds = 0
    @State private var brewModeRunID = UUID()
    @State private var lastCueStepIndex = -1
    @State private var brewModeHapticTrigger = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 6) {
                Text(AppLocalization.text("the_craft", fallback: "The craft"))
                    .font(labelFont)
                    .tracking(4)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                Text(AppLocalization.text("brewing_methods", fallback: "BREWING METHODS"))
                    .font(titleFont)
                    .tracking(1)
                    .foregroundColor(primaryTextColor)

                Text(AppLocalization.text("brewing_intro", fallback: "Guides for making better coffee at home."))
                    .font(.system(size: 16, weight: .light, design: .serif))
                    .italic()
                    .foregroundColor(tertiaryTextColor)
                    .padding(.top, 6)
            }

            if isLoadingMethods && methodsAreEmpty {
                loadingView
            } else {
                goldenRatioSection
                guidedBrewModeSection
                brewTimerSection
                coffeeJournalSection
                brewingCategoriesSection

                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(displayedMethods) { method in
                        methodCard(method)
                    }
                }
            }

            if let methodsError {
                Text(methodsError)
                    .font(bodyFont)
                    .foregroundColor(secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var guidedBrewModeSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                pouringProgressView

                VStack(alignment: .leading, spacing: 6) {
                    Text(AppLocalization.text("guided_brew_mode", fallback: "Guided Brew Mode"))
                        .font(sectionTitleFont)
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("guided_brew_mode_detail", fallback: "Follow each pour with automatic water targets, pause controls and gentle haptic cues."))
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                ratioInputField(title: AppLocalization.text("coffee_grams", fallback: "Coffee (g)"), text: $ratioCoffeeInput)
                ratioInputField(title: AppLocalization.text("ratio", fallback: "Ratio"), text: $ratioValueInput)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(formattedTimerTime(brewModeElapsedSeconds))
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 30 : 36))
                    .monospacedDigit()
                    .foregroundColor(primaryTextColor)
                    .contentTransition(.numericText())

                Spacer(minLength: 10)

                Text("\(formattedRatioValue(validWaterAmount)) g water")
                    .font(Font.custom("AvenirNext-Bold", size: 12))
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(brewModeSteps.indices, id: \.self) { index in
                    brewModeStepRow(brewModeSteps[index], index: index)
                }
            }

            HStack(spacing: 10) {
                Button {
                    toggleBrewMode()
                } label: {
                    Label(
                        isBrewModeRunning
                            ? AppLocalization.text("pause", fallback: "Pause")
                            : AppLocalization.text("start", fallback: "Start"),
                        systemImage: isBrewModeRunning ? "pause.fill" : "play.fill"
                    )
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    restartBrewMode()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 44, height: 44)
                        .background(cardFillColor)
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("brew_again", fallback: "Brew again"))

                Button(action: saveRecipeAction) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(primaryTextColor)
                        .frame(width: 44, height: 44)
                        .background(cardFillColor)
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.18), lineWidth: 1)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("save_recipe", fallback: "Save Recipe"))
            }

            if !brewHistoryItems.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(AppLocalization.text("brew_again_history", fallback: "Brew Again"))
                        .font(Font.custom("AvenirNext-Bold", size: 10))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    ForEach(brewHistoryItems.indices, id: \.self) { index in
                        brewHistoryButton(brewHistoryItems[index])
                    }
                }
            }
        }
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .sensoryFeedback(.selection, trigger: brewModeHapticTrigger)
    }

    private var pouringProgressView: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.14), lineWidth: 9)

            Circle()
                .trim(from: 0, to: brewModeProgress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: brewModeProgress)

            Image(systemName: "drop.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(accentColor)
                .offset(y: isBrewModeRunning ? -4 : 0)
                .symbolEffect(.pulse, value: brewModeHapticTrigger)
        }
        .frame(width: 64, height: 64)
    }

    private var goldenRatioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLocalization.text("golden_ratio", fallback: "THE GOLDEN RATIO"))
                .font(.system(size: 24, weight: .bold, design: .serif))
                .tracking(2)
                .foregroundColor(primaryTextColor)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 12)], spacing: 12) {
                ratioCard(ratio: "1:15", label: AppLocalization.text("strong_bold", fallback: "Strong & Bold"))
                ratioCard(ratio: "1:16", label: AppLocalization.text("balanced", fallback: "Balanced"))
                ratioCard(ratio: "1:17", label: AppLocalization.text("light_bright", fallback: "Light & Bright"), showsDivider: false)
            }

            Text(AppLocalization.text("ratio_copy", fallback: "Coffee to water ratio. Adjust to your taste based on roast level and brew method."))
                .font(.system(size: 15, weight: .light, design: .serif))
                .italic()
                .foregroundColor(tertiaryTextColor)
                .padding(.top, 6)

            ratioCalculatorCard
        }
        .padding(24)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(accentColor.opacity(0.2), lineWidth: 1)
        )
    }

    private var brewingCategoriesSection: some View {
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

    private func methodCard(_ method: ContentView.BrewingMethod) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(accentColor.opacity(0.12))
                        .frame(width: 56, height: 56)

                    Image(systemName: method.symbol)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(accentColor)
                }

                Spacer()

                methodTag(method.articleURL == nil
                    ? AppLocalization.text("in_app_guide", fallback: "In-App Guide")
                    : AppLocalization.text("coffee_journal", fallback: "Coffee Journal"))
            }

            Text(method.name)
                .font(.system(size: 22, weight: .bold, design: .serif))
                .tracking(1)
                .foregroundColor(primaryTextColor)

            Text(method.summary)
                .font(Font.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(secondaryTextColor)
                .fixedSize(horizontal: false, vertical: true)

            if !method.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        methodTag(method.brewTime)
                        methodTag(method.difficulty)

                        ForEach(method.categories, id: \.self) { category in
                            methodTag(category)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                brewingDetail(title: AppLocalization.text("source", fallback: "Source"), value: method.detail)
                brewingDetail(
                    title: AppLocalization.text("guide", fallback: "Guide"),
                    value: method.articleURL == nil
                        ? AppLocalization.text("in_app_guide", fallback: "In-app guide")
                        : AppLocalization.text("coffee_journal_article", fallback: "Coffee journal article")
                )
            }

            HStack {
                Text(method.articleURL == nil
                    ? AppLocalization.text("use_built_in_guide", fallback: "Use the built-in guide below.")
                    : AppLocalization.text("open_full_guide", fallback: "Open the full brew guide."))
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)

                Spacer()

                if let articleURL = method.articleURL {
                    Button {
                        openArticleAction(articleURL)
                    } label: {
                        HStack(spacing: 6) {
                            Text(AppLocalization.text("open_guide", fallback: "Open Guide"))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(AppLocalization.text("in_app", fallback: "In App"))
                        .font(Font.custom("AvenirNext-Bold", size: 10))
                        .tracking(1.8)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(accentColor.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func methodTag(_ title: String) -> some View {
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

    private var validCoffeeAmount: Double {
        ratioCoffeeAmount > 0 ? ratioCoffeeAmount : 20
    }

    private var validRatioValue: Double {
        ratioValue > 0 ? ratioValue : 16
    }

    private var validWaterAmount: Double {
        max(validCoffeeAmount * validRatioValue, 1)
    }

    private var brewModeTotalSeconds: Int {
        210
    }

    private var brewModeProgress: Double {
        min(Double(brewModeElapsedSeconds) / Double(brewModeTotalSeconds), 1)
    }

    private var currentBrewModeStepIndex: Int {
        brewModeSteps.lastIndex { brewModeElapsedSeconds >= $0.time } ?? 0
    }

    private var brewModeSteps: [BrewModeStep] {
        let bloomWater = min(validWaterAmount, validCoffeeAmount * 3)
        let firstPourWater = min(validWaterAmount, max(bloomWater, validWaterAmount * 0.56))

        return [
            BrewModeStep(
                id: 0,
                time: 0,
                title: "Add \(formattedRatioValue(validCoffeeAmount)) g coffee",
                detail: AppLocalization.text("brew_mode_step_grind", fallback: "Level the bed, start the timer, and get ready to bloom."),
                waterTarget: nil
            ),
            BrewModeStep(
                id: 1,
                time: 10,
                title: "Pour to \(formattedRatioValue(bloomWater)) g",
                detail: AppLocalization.text("brew_mode_step_bloom", fallback: "Cover all grounds and let the coffee bloom."),
                waterTarget: bloomWater
            ),
            BrewModeStep(
                id: 2,
                time: 45,
                title: "Continue pouring to \(formattedRatioValue(firstPourWater)) g",
                detail: AppLocalization.text("brew_mode_step_main_pour", fallback: "Pour slowly in circles and keep the bed even."),
                waterTarget: firstPourWater
            ),
            BrewModeStep(
                id: 3,
                time: 90,
                title: "Finish at \(formattedRatioValue(validWaterAmount)) g",
                detail: AppLocalization.text("brew_mode_step_finish_pour", fallback: "Use the remaining water and let the drawdown settle."),
                waterTarget: validWaterAmount
            ),
            BrewModeStep(
                id: 4,
                time: 165,
                title: AppLocalization.text("brew_mode_step_serve_title", fallback: "Serve and taste"),
                detail: AppLocalization.text("brew_mode_step_serve_detail", fallback: "Swirl, pour, and save the recipe if this cup worked."),
                waterTarget: nil
            )
        ]
    }

    private func brewModeStepRow(_ step: BrewModeStep, index: Int) -> some View {
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

    private func brewHistoryButton(_ item: (title: String, detail: String)) -> some View {
        Button {
            brewRecipeName = item.title
            restartBrewMode()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 28, height: 28)
                    .background(accentColor.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(Font.custom("AvenirNext-Bold", size: 13))
                        .foregroundColor(primaryTextColor)
                        .lineLimit(1)

                    Text(item.detail)
                        .font(Font.custom("AvenirNext-Regular", size: 12))
                        .foregroundColor(secondaryTextColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .background(accentColor.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func toggleBrewMode() {
        if isBrewModeRunning {
            brewModeRunID = UUID()
            isBrewModeRunning = false
            brewModeHapticTrigger += 1
            return
        }

        if brewModeElapsedSeconds >= brewModeTotalSeconds {
            brewModeElapsedSeconds = 0
            lastCueStepIndex = -1
        }

        startBrewModeSession()
    }

    private func restartBrewMode() {
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        startBrewModeSession()
    }

    private func startBrewModeSession() {
        let runID = UUID()
        brewModeRunID = runID
        isBrewModeRunning = true
        brewModeHapticTrigger += 1

        Task { @MainActor in
            while isBrewModeRunning && brewModeRunID == runID && brewModeElapsedSeconds < brewModeTotalSeconds {
                try? await Task.sleep(for: .seconds(1))
                guard isBrewModeRunning, brewModeRunID == runID else { return }
                tickBrewMode()
            }
        }
    }

    private func tickBrewMode() {
        guard isBrewModeRunning else { return }

        if brewModeElapsedSeconds >= brewModeTotalSeconds {
            isBrewModeRunning = false
            brewModeHapticTrigger += 1
            return
        }

        brewModeElapsedSeconds += 1
        let stepIndex = currentBrewModeStepIndex

        if stepIndex != lastCueStepIndex {
            lastCueStepIndex = stepIndex
            brewModeHapticTrigger += 1
        }
    }

    private func formattedTimerTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private var ratioCalculatorCard: some View {
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
                ratioInputField(title: AppLocalization.text("recipe_name", fallback: "Recipe Name"), text: $brewRecipeName, keyboardType: .default)

                Button(action: saveRecipeAction) {
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

    private func brewingDetail(title: String, value: String) -> some View {
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

    private func ratioCard(ratio: String, label: String, showsDivider: Bool = true) -> some View {
        VStack(spacing: 6) {
            Text(ratio)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(accentColor)

            Text(label)
                .font(.system(size: 10, weight: .light))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)
        }
        .frame(maxWidth: .infinity)
        .overlay(alignment: .trailing) {
            if showsDivider {
                Rectangle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 1)
            }
        }
    }

    private func ratioInputField(title: String, text: Binding<String>, keyboardType: UIKeyboardType = .decimalPad) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 10))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundColor(tertiaryTextColor)

            TextField("0", text: text)
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

    private func formattedRatioValue(_ value: Double) -> String {
        if value == 0 { return "0" }
        if value.rounded() == value { return String(Int(value)) }
        return String(format: "%.1f", value)
    }
}
