import Foundation
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(UIKit)
import UIKit
#endif

#if canImport(ActivityKit)
struct TallaBrewActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let elapsedSeconds: Int
        let timerStartDate: Date
        let currentStep: String
        let nextStep: String
        let currentWaterGrams: Double
        let isPaused: Bool
    }

    let methodName: String
    let coffeeGrams: Double
    let ratio: Double
    let totalWaterGrams: Double
    let totalSeconds: Int
}
#endif

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
    let brewHistoryItems: [(title: String, detail: String, coffeeGrams: Double?, ratio: Double?)]
    let titleFont: Font
    let sectionTitleFont: Font
    let bodyFont: Font
    let labelFont: Font
    let saveRecipeAction: () -> Void
    let openArticleAction: (URL) -> Void
    let guidedBrewCompletedAction: (ContentView.BrewingMethod?, Double, Double, Double, Int) -> Void
    let brewTimerSection: AnyView
    let coffeeJournalSection: AnyView
    let loadingView: AnyView
    @State private var isBrewModeRunning = false
    @State private var brewModeElapsedSeconds = 0
    @State private var brewModeRunID = UUID()
    @State private var lastCueStepIndex = -1
    @State private var brewModeHapticTrigger = 0
    @State private var selectedBrewModeMethodID: String?
    @State private var isFocusedBrewPresented = false
    @State private var isEndBrewConfirmationPresented = false
#if canImport(ActivityKit)
    @State private var brewLiveActivity: Activity<TallaBrewActivityAttributes>?
#endif

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
                guidedBrewModeSection
                continueBrewSection
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
        .fullScreenCover(isPresented: $isFocusedBrewPresented) {
            focusedBrewModeView
        }
        .onChange(of: isBrewModeRunning) { _, isRunning in
            setBrewIdleTimerDisabled(isRunning)
        }
        .onDisappear {
            setBrewIdleTimerDisabled(false)
            endBrewLiveActivity()
        }
    }

    private var guidedBrewModeSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 38, height: 38)
                    .background(accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(AppLocalization.text("start_guided_brew", fallback: "Start a Guided Brew"))
                        .font(sectionTitleFont)
                        .tracking(2.2)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("guided_brew_mode_detail", fallback: "Choose a method, adjust your coffee, and follow every pour."))
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    if let selectedBrewModeMethod {
                        Text("\(AppLocalization.text("using", fallback: "Using")) \(selectedBrewModeMethod.name) · \(methodMetaLine(for: selectedBrewModeMethod))")
                            .font(Font.custom("AvenirNext-Bold", size: 11))
                            .foregroundColor(accentColor)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }
            }

            if !displayedMethods.isEmpty {
                Menu {
                    ForEach(displayedMethods) { method in
                        Button {
                            selectBrewModeMethod(method, start: false)
                        } label: {
                            HStack {
                                Text(method.name)
                                if selectedBrewModeMethod?.id == method.id {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("\(AppLocalization.text("method", fallback: "Method")): \(selectedBrewModeMethod?.name ?? AppLocalization.text("custom_brew", fallback: "Custom Brew"))")
                            .font(Font.custom("AvenirNext-Bold", size: 11))
                            .tracking(1.1)
                            .textCase(.uppercase)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(primaryTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(cardFillColor)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(accentColor.opacity(0.18), lineWidth: 1)
                    )
                    .clipShape(Capsule(style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                ratioInputField(title: AppLocalization.text("coffee_grams", fallback: "Coffee (g)"), text: $ratioCoffeeInput)
                ratioInputField(title: AppLocalization.text("ratio", fallback: "Ratio"), text: $ratioValueInput)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(AppLocalization.text("choose_your_strength", fallback: "Choose your strength"))
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(1.8)
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                HStack(spacing: 8) {
                    strengthRatioButton(ratio: "15", title: AppLocalization.text("strong", fallback: "Strong"))
                    strengthRatioButton(ratio: "16", title: AppLocalization.text("balanced", fallback: "Balanced"))
                    strengthRatioButton(ratio: "17", title: AppLocalization.text("light", fallback: "Light"))
                }
            }

            guidedBrewSetupSummary

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 14) {
                    pouringProgressView
                        .frame(width: 92, height: 92)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(formattedTimerTime(brewModeElapsedSeconds))
                            .font(Font.custom("Georgia-Bold", size: isCompact ? 30 : 36))
                            .monospacedDigit()
                            .foregroundColor(primaryTextColor)
                            .contentTransition(.numericText())

                        Text(AppLocalization.text("guided_brew_live_timer", fallback: "Live brew timer"))
                            .font(Font.custom("AvenirNext-Bold", size: 10))
                            .tracking(1.4)
                            .textCase(.uppercase)
                            .foregroundColor(accentColor)
                    }

                    Spacer(minLength: 0)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(currentBrewModeStep.title)
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 24 : 28))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .symbolEffect(.pulse, value: brewModeHapticTrigger)

                    Text(currentBrewModeStep.detail)
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accentColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(AppLocalization.text("current_target", fallback: "Current target:"))
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(tertiaryTextColor)

                    Text("\(formattedWholeGram(currentWaterTarget)) / \(formattedWholeGram(validWaterAmount)) g")
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 24 : 28))
                        .foregroundColor(accentColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                if let nextBrewModeStep {
                    Text("\(AppLocalization.text("next", fallback: "Next")): \(nextBrewModeStep.title) \(AppLocalization.text("at", fallback: "at")) \(formattedTimerTime(nextBrewModeStep.time))")
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Label(AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."), systemImage: "cup.and.saucer.fill")
                        .font(Font.custom("AvenirNext-Bold", size: 13))
                        .foregroundColor(accentColor)
                        .symbolEffect(.bounce, value: brewModeHapticTrigger)
                }
            }

            HStack(spacing: 10) {
                Button {
                    toggleBrewMode()
                } label: {
                    Label(
                        brewModePrimaryActionTitle,
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
                    skipBrewModeStep()
                } label: {
                    Image(systemName: "forward.fill")
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
                .accessibilityLabel(AppLocalization.text("skip_step", fallback: "Skip step"))

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

    private var guidedBrewSetupSummary: some View {
        HStack(spacing: 10) {
            guidedBrewSetupMetric(
                title: AppLocalization.text("water", fallback: "Water"),
                value: "\(formattedWholeGram(validWaterAmount)) g",
                systemImage: "drop.fill"
            )

            guidedBrewSetupMetric(
                title: AppLocalization.text("brew_time", fallback: "Brew time"),
                value: formattedTimerTime(brewModeTotalSeconds),
                systemImage: "timer"
            )
        }
    }

    private func guidedBrewSetupMetric(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(accentColor)
                .frame(width: 28, height: 28)
                .background(accentColor.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 9))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(tertiaryTextColor)

                Text(value)
                    .font(Font.custom("AvenirNext-Bold", size: 14))
                    .foregroundColor(primaryTextColor)
                    .monospacedDigit()
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var focusedBrewModeView: some View {
        ZStack {
            LinearGradient(
                colors: [cardFillColor, cardFillColor.opacity(0.96), accentColor.opacity(0.10)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(AppLocalization.text("guided_brew", fallback: "Guided Brew"))
                            .font(Font.custom("AvenirNext-Bold", size: 11))
                            .tracking(2.2)
                            .textCase(.uppercase)
                            .foregroundColor(accentColor)

                        Text(selectedBrewModeMethod?.name ?? AppLocalization.text("custom_brew", fallback: "Custom Brew"))
                            .font(Font.custom("Georgia-Bold", size: 24))
                            .foregroundColor(primaryTextColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }

                    Spacer(minLength: 0)

                    Button {
                        requestEndFocusedBrew()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(primaryTextColor)
                            .frame(width: 42, height: 42)
                            .background(cardFillColor)
                            .overlay(
                                Circle()
                                    .stroke(accentColor.opacity(0.18), lineWidth: 1)
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(AppLocalization.text("close", fallback: "Close"))
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 18) {
                    Text(currentBrewModeStep.title)
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 34 : 42))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                        .symbolEffect(.pulse, value: brewModeHapticTrigger)

                    Text(currentBrewModeStep.detail)
                        .font(Font.custom("AvenirNext-Regular", size: 16))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(alignment: .center, spacing: 20) {
                    focusedPouringProgressView
                        .frame(width: 118, height: 118)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(formattedTimerTime(brewModeElapsedSeconds))
                            .font(Font.custom("Georgia-Bold", size: isCompact ? 56 : 68))
                            .monospacedDigit()
                            .foregroundColor(primaryTextColor)
                            .contentTransition(.numericText())

                        Text(AppLocalization.text("large_timer", fallback: "Large timer"))
                            .font(Font.custom("AvenirNext-Bold", size: 10))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundColor(accentColor)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalization.text("current_water_target", fallback: "Current water target"))
                        .font(Font.custom("AvenirNext-Bold", size: 10))
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundColor(tertiaryTextColor)

                    Text("\(formattedWholeGram(currentWaterTarget)) / \(formattedWholeGram(validWaterAmount)) g")
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 34 : 40))
                        .monospacedDigit()
                        .foregroundColor(accentColor)
                        .contentTransition(.numericText())
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(accentColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                if let nextBrewModeStep {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(AppLocalization.text("next_step", fallback: "Next step"))
                            .font(Font.custom("AvenirNext-Bold", size: 10))
                            .tracking(1.6)
                            .textCase(.uppercase)
                            .foregroundColor(tertiaryTextColor)

                        Text("\(nextBrewModeStep.title) at \(formattedTimerTime(nextBrewModeStep.time))")
                            .font(Font.custom("AvenirNext-Regular", size: 15))
                            .foregroundColor(secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    Label(AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."), systemImage: "cup.and.saucer.fill")
                        .font(Font.custom("AvenirNext-Bold", size: 15))
                        .foregroundColor(accentColor)
                        .symbolEffect(.bounce, value: brewModeHapticTrigger)
                }

                Spacer(minLength: 0)

                focusedBrewControls
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 28)
        }
        .interactiveDismissDisabled(isBrewModeRunning || brewModeElapsedSeconds > 0)
        .confirmationDialog(
            AppLocalization.text("end_brew_question", fallback: "End this brew?"),
            isPresented: $isEndBrewConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppLocalization.text("end_brew", fallback: "End Brew"), role: .destructive) {
                endFocusedBrew()
            }

            Button(AppLocalization.text("cancel", fallback: "Cancel"), role: .cancel) { }
        } message: {
            Text(AppLocalization.text("end_brew_detail", fallback: "Your current timer progress will stop."))
        }
        .sensoryFeedback(.selection, trigger: brewModeHapticTrigger)
    }

    private var focusedPouringProgressView: some View {
        ZStack {
            Circle()
                .stroke(accentColor.opacity(0.14), lineWidth: 12)

            Circle()
                .trim(from: 0, to: brewModeProgress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.35), value: brewModeProgress)

            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(accentColor)
                    .symbolEffect(.pulse, value: brewModeHapticTrigger)

                Text("\(Int(brewModeProgress * 100))%")
                    .font(Font.custom("AvenirNext-Bold", size: 12))
                    .foregroundColor(secondaryTextColor)
            }
        }
    }

    private var focusedBrewControls: some View {
        VStack(spacing: 12) {
            Button {
                toggleBrewMode()
            } label: {
                Label(
                    brewModePrimaryActionTitle,
                    systemImage: isBrewModeRunning ? "pause.fill" : "play.fill"
                )
                .font(Font.custom("AvenirNext-Bold", size: 13))
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundColor(Color(hex: 0x0A0804))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(accentColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                focusedControlButton(
                    title: AppLocalization.text("skip", fallback: "Skip"),
                    systemImage: "forward.fill"
                ) {
                    skipBrewModeStep()
                }

                focusedControlButton(
                    title: AppLocalization.text("restart", fallback: "Restart"),
                    systemImage: "arrow.counterclockwise"
                ) {
                    restartBrewMode()
                }

                focusedControlButton(
                    title: AppLocalization.text("end_brew", fallback: "End Brew"),
                    systemImage: "xmark.circle.fill"
                ) {
                    requestEndFocusedBrew()
                }
            }
        }
    }

    private func focusedControlButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(1.0)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
                .foregroundColor(primaryTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(cardFillColor)
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(accentColor.opacity(0.18), lineWidth: 1)
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var brewingToolShortcuts: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
            toolShortcut(
                title: AppLocalization.text("calculator", fallback: "Calculator"),
                systemImage: "function",
                detail: "\(formattedWholeGram(calculatedWaterAmount)) g"
            )
            toolShortcut(
                title: AppLocalization.text("timer", fallback: "Timer"),
                systemImage: "timer",
                detail: formattedTimerTime(210)
            )
            toolShortcut(
                title: AppLocalization.text("journal", fallback: "Journal"),
                systemImage: "book.closed.fill",
                detail: AppLocalization.text("save_recipe", fallback: "Save Recipe")
            )
        }
    }

    private func toolShortcut(title: String, systemImage: String, detail: String) -> some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(accentColor)
                .frame(width: 28, height: 28)
                .background(accentColor.opacity(0.10))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)

                Text(detail)
                    .font(Font.custom("AvenirNext-Regular", size: 11))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.14), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var continueBrewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLocalization.text("continue_or_saved_recipes", fallback: "Continue Last Brew"))
                .font(sectionTitleFont)
                .tracking(2.2)
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            if let latestBrew = brewHistoryItems.first {
                brewHistoryButton(latestBrew, isPrimary: true)
            } else {
                brewHistoryButton(
                    (
                        title: selectedBrewModeMethod?.name ?? AppLocalization.text("custom_brew", fallback: "Custom Brew"),
                        detail: "\(formattedRatioValue(validCoffeeAmount)) g - 1:\(formattedRatioValue(validRatioValue))",
                        coffeeGrams: validCoffeeAmount,
                        ratio: validRatioValue
                    ),
                    isPrimary: true
                )
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

    private var goldenRatioSection: some View {
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
                        Text(AppLocalization.text("start_brewing", fallback: "Start Brewing"))
                            .font(Font.custom("AvenirNext-Bold", size: 10))
                            .tracking(1.2)
                            .textCase(.uppercase)
                        Image(systemName: "arrow.forward")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color(hex: 0x0A0804))
                    .padding(.horizontal, 10)
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

    private func brewerIllustration(for method: ContentView.BrewingMethod) -> some View {
        let methodText = ([method.name] + method.categories).joined(separator: " ").lowercased()

        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accentColor.opacity(0.10))
                .frame(height: 86)

            brewerIcon(for: methodText)
        }
    }

    @ViewBuilder
    private func brewerIcon(for methodText: String) -> some View {
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

    private var v60Icon: some View {
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
        .accessibilityLabel("V60 cone")
    }

    private var chemexIcon: some View {
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
        .accessibilityLabel("Chemex")
    }

    private var aeroPressIcon: some View {
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
        .accessibilityLabel("AeroPress")
    }

    private var frenchPressIcon: some View {
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
        .accessibilityLabel("French press")
    }

    private var dallahIcon: some View {
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
        .accessibilityLabel("Arabic dallah")
    }

    private var siphonIcon: some View {
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
        .accessibilityLabel("Siphon")
    }

    private var coldBrewIcon: some View {
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
        .accessibilityLabel("Cold-brew bottle")
    }

    private func methodMetaLine(for method: ContentView.BrewingMethod) -> String {
        let category = method.categories.first ?? AppLocalization.text("brewing_guide", fallback: "Brewing Guide")
        return [method.brewTime, method.difficulty, category]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " · ")
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

    private var selectedBrewModeMethod: ContentView.BrewingMethod? {
        if let selectedBrewModeMethodID,
           let method = displayedMethods.first(where: { $0.id == selectedBrewModeMethodID }) {
            return method
        }

        return displayedMethods.first
    }

    private var brewModeTotalSeconds: Int {
        selectedBrewModeMethod.flatMap { seconds(from: $0.brewTime) } ?? 210
    }

    private var brewModeProgress: Double {
        min(Double(brewModeElapsedSeconds) / Double(brewModeTotalSeconds), 1)
    }

    private var currentBrewModeStepIndex: Int {
        brewModeSteps.lastIndex { brewModeElapsedSeconds >= $0.time } ?? 0
    }

    private var currentBrewModeStep: BrewModeStep {
        brewModeSteps[min(currentBrewModeStepIndex, brewModeSteps.count - 1)]
    }

    private var nextBrewModeStep: BrewModeStep? {
        let nextIndex = currentBrewModeStepIndex + 1
        guard brewModeElapsedSeconds < brewModeTotalSeconds, brewModeSteps.indices.contains(nextIndex) else {
            return nil
        }

        return brewModeSteps[nextIndex]
    }

    private var currentWaterTarget: Double {
        if let waterTarget = currentBrewModeStep.waterTarget {
            return waterTarget
        }

        return brewModeSteps
            .prefix(currentBrewModeStepIndex + 1)
            .compactMap(\.waterTarget)
            .last ?? 0
    }

    private var brewModePrimaryActionTitle: String {
        if isBrewModeRunning {
            return AppLocalization.text("pause", fallback: "Pause")
        }

        if brewModeElapsedSeconds >= brewModeTotalSeconds {
            return AppLocalization.text("brew_again", fallback: "Brew Again")
        }

        if brewModeElapsedSeconds > 0 {
            return AppLocalization.text("resume", fallback: "Resume")
        }

        return AppLocalization.text("start", fallback: "Start")
    }

    private var brewModeSteps: [BrewModeStep] {
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

    private var pourOverBrewModeSteps: [BrewModeStep] {
        let bloomWater = min(validWaterAmount, validCoffeeAmount * 3)
        let firstPourWater = min(validWaterAmount, max(bloomWater, validWaterAmount * 0.56))

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

    private var immersionBrewModeSteps: [BrewModeStep] {
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

    private var traditionalBrewModeSteps: [BrewModeStep] {
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

    private var coldBrewModeSteps: [BrewModeStep] {
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

    private func brewHistoryButton(_ item: (title: String, detail: String, coffeeGrams: Double?, ratio: Double?), isPrimary: Bool) -> some View {
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

    private func selectBrewModeMethod(_ method: ContentView.BrewingMethod, start: Bool) {
        selectedBrewModeMethodID = method.id
        brewRecipeName = method.name
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        brewModeRunID = UUID()
        isBrewModeRunning = false
        endBrewLiveActivity()
        brewModeHapticTrigger += 1

        if start {
            startBrewModeSession()
        }
    }

    private func toggleBrewMode() {
        if isBrewModeRunning {
            brewModeRunID = UUID()
            isBrewModeRunning = false
            updateBrewLiveActivity(isPaused: true)
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
        endBrewLiveActivity()
        startBrewModeSession()
    }

    private func skipBrewModeStep() {
        guard let nextBrewModeStep else {
            brewModeElapsedSeconds = brewModeTotalSeconds
            isBrewModeRunning = false
            brewModeHapticTrigger += 1
            updateBrewLiveActivity(isPaused: false)
            guidedBrewCompletedAction(selectedBrewModeMethod, validCoffeeAmount, validRatioValue, validWaterAmount, brewModeTotalSeconds)
            endBrewLiveActivity(after: 30)
            return
        }

        brewModeElapsedSeconds = nextBrewModeStep.time
        lastCueStepIndex = currentBrewModeStepIndex
        updateBrewLiveActivity(isPaused: !isBrewModeRunning)
        brewModeHapticTrigger += 1
    }

    private func startBrewModeSession() {
        let runID = UUID()
        brewModeRunID = runID
        isBrewModeRunning = true
        isFocusedBrewPresented = true
        brewModeHapticTrigger += 1
        startOrUpdateBrewLiveActivity()

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
            updateBrewLiveActivity(isPaused: false)
            return
        }

        brewModeElapsedSeconds += 1
        let stepIndex = currentBrewModeStepIndex

        if stepIndex != lastCueStepIndex {
            lastCueStepIndex = stepIndex
            brewModeHapticTrigger += 1
        }

        updateBrewLiveActivity(isPaused: false)

        if brewModeElapsedSeconds >= brewModeTotalSeconds {
            isBrewModeRunning = false
            brewModeHapticTrigger += 1
            guidedBrewCompletedAction(selectedBrewModeMethod, validCoffeeAmount, validRatioValue, validWaterAmount, brewModeTotalSeconds)
            endBrewLiveActivity(after: 30)
        }
    }

    private func requestEndFocusedBrew() {
        if isBrewModeRunning || brewModeElapsedSeconds > 0 {
            isEndBrewConfirmationPresented = true
        } else {
            isFocusedBrewPresented = false
        }
    }

    private func endFocusedBrew() {
        brewModeRunID = UUID()
        isBrewModeRunning = false
        brewModeElapsedSeconds = 0
        lastCueStepIndex = -1
        isFocusedBrewPresented = false
        endBrewLiveActivity()
        setBrewIdleTimerDisabled(false)
    }

    private func setBrewIdleTimerDisabled(_ isDisabled: Bool) {
#if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = isDisabled
#endif
    }

    private func startOrUpdateBrewLiveActivity() {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *), ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        if brewLiveActivity == nil {
            let attributes = TallaBrewActivityAttributes(
                methodName: selectedBrewModeMethod?.name ?? AppLocalization.text("custom_brew", fallback: "Custom Brew"),
                coffeeGrams: validCoffeeAmount,
                ratio: validRatioValue,
                totalWaterGrams: validWaterAmount,
                totalSeconds: brewModeTotalSeconds
            )
            let content = ActivityContent(
                state: brewLiveActivityState(isPaused: false),
                staleDate: Date().addingTimeInterval(TimeInterval(max(brewModeTotalSeconds - brewModeElapsedSeconds + 60, 60))),
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

    private func updateBrewLiveActivity(isPaused: Bool) {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *), let brewLiveActivity else { return }

        let content = ActivityContent(
            state: brewLiveActivityState(isPaused: isPaused),
            staleDate: Date().addingTimeInterval(TimeInterval(max(brewModeTotalSeconds - brewModeElapsedSeconds + 60, 60))),
            relevanceScore: 100
        )

        Task {
            await brewLiveActivity.update(content)
        }
#endif
    }

    private func endBrewLiveActivity(after seconds: Double = 0) {
#if canImport(ActivityKit)
        guard #available(iOS 16.1, *), let brewLiveActivity else { return }

        let finalContent = ActivityContent(
            state: brewLiveActivityState(isPaused: false),
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
    @available(iOS 16.1, *)
    private func brewLiveActivityState(isPaused: Bool) -> TallaBrewActivityAttributes.ContentState {
        TallaBrewActivityAttributes.ContentState(
            elapsedSeconds: brewModeElapsedSeconds,
            timerStartDate: Date().addingTimeInterval(-Double(brewModeElapsedSeconds)),
            currentStep: currentBrewModeStep.title,
            nextStep: nextBrewModeStep?.title ?? AppLocalization.text("brew_ready_message", fallback: "Your brew is ready. Enjoy it slowly."),
            currentWaterGrams: currentWaterTarget,
            isPaused: isPaused
        )
    }
#endif

    private func formattedTimerTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func stepTime(_ fraction: Double, minimum: Int) -> Int {
        min(max(Int(Double(brewModeTotalSeconds) * fraction), minimum), max(brewModeTotalSeconds - 1, 0))
    }

    private func seconds(from brewTime: String) -> Int? {
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
                ratioInputField(
                    title: AppLocalization.text("recipe_name", fallback: "Recipe Name"),
                    text: $brewRecipeName,
                    placeholder: AppLocalization.text("name_this_recipe", fallback: "Name this recipe"),
                    keyboardType: .default
                )

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

    private func strengthRatioButton(ratio: String, title: String) -> some View {
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

    private func ratioInputField(title: String, text: Binding<String>, placeholder: String = "0", keyboardType: UIKeyboardType = .decimalPad) -> some View {
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

    private func formattedRatioValue(_ value: Double) -> String {
        if value == 0 { return "0" }
        if value.rounded() == value { return String(Int(value)) }
        return String(format: "%.1f", value)
    }

    private func formattedWholeGram(_ value: Double) -> String {
        String(Int(value.rounded()))
    }
}
