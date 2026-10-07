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
    var guidedBrewModeSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: 0x151515))
                    .frame(width: 38, height: 38)
                    .background(accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(AppLocalization.text("start_guided_brew", fallback: "Start a Guided Brew"))
                        .font(sectionTitleFont)
                        .tracking(AppLocalization.letterSpacing(2.2))
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
                        Text("\(AppLocalization.text("method", fallback: "Method")): \(currentBrewRecipeTitle)")
                            .font(Font.custom("AvenirNext-Bold", size: 11))
                            .tracking(AppLocalization.letterSpacing(1.1))
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
                    .tracking(AppLocalization.letterSpacing(1.8))
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
                            .tracking(AppLocalization.letterSpacing(1.4))
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
                        .tracking(AppLocalization.letterSpacing(1.2))
                        .textCase(.uppercase)
                        .foregroundColor(tertiaryTextColor)

                    Text("\(formattedWholeGram(currentWaterTarget)) / \(formattedWholeGram(brewModeWaterAmount)) g")
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
                    handleBrewModePrimaryAction()
                } label: {
                    Label(
                        brewModePrimaryActionTitle,
                        systemImage: brewModePrimaryActionIcon
                    )
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(AppLocalization.letterSpacing(1.5))
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .foregroundColor(Color(hex: 0x151515))
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

                Button(action: saveCurrentRecipe) {
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

    var smartBrewGuideSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(hex: 0x151515))
                    .frame(width: 38, height: 38)
                    .background(accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(AppLocalization.text("smart_brew_guide", fallback: "Smart Brew Guide"))
                        .font(sectionTitleFont)
                        .tracking(AppLocalization.letterSpacing(2.2))
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("smart_brew_guide_detail", fallback: "Pulls your saved recipes, suggests proven starting points, and explains what to adjust next."))
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !brewHistoryItems.isEmpty {
                savedRecipeShelf
            }

            bestRecipeShelf

            if let selectedGuideProfile {
                guideProfileDetail(selectedGuideProfile)
                brewCoachCard(for: selectedGuideProfile)
            }
        }
        .padding(18)
        .background(cardFillColor)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.18), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    var savedRecipeShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("your_recipes", fallback: "Your recipes"))
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(AppLocalization.letterSpacing(1.8))
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(brewHistoryItems.prefix(5).enumerated()), id: \.offset) { _, recipe in
                        savedRecipeGuideButton(recipe)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    var bestRecipeShelf: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("best_recipes", fallback: "Best recipes"))
                .font(Font.custom("AvenirNext-Bold", size: 10))
                .tracking(AppLocalization.letterSpacing(1.8))
                .textCase(.uppercase)
                .foregroundColor(accentColor)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 142 : 168), spacing: 10)], spacing: 10) {
                ForEach(brewGuideProfiles) { profile in
                    brewGuideProfileButton(profile)
                }
            }
        }
    }

    func savedRecipeGuideButton(_ recipe: BrewRecipeRecord) -> some View {
        Button {
            applySavedRecipe(recipe, start: false)
        } label: {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("saved", fallback: "Saved"))
                        .font(Font.custom("AvenirNext-Bold", size: 9))
                        .tracking(AppLocalization.letterSpacing(1.1))
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                }

                Text(recipe.title)
                    .font(Font.custom("Georgia-Bold", size: 16))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text(recipe.detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(minWidth: 184, maxWidth: 260, alignment: .leading)
            .background(accentColor.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func brewGuideProfileButton(_ profile: BrewGuideProfile) -> some View {
        let isSelected = selectedGuideProfileID == profile.id

        return Button {
            selectedGuideProfileID = profile.id
            expandedGuideProfileID = profile.id
            brewCoachAnswer = nil
            applyGuideProfile(profile, start: false)
        } label: {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Image(systemName: profile.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isSelected ? Color(hex: 0x151515) : accentColor)
                        .frame(width: 30, height: 30)
                        .background(isSelected ? Color(hex: 0x151515).opacity(0.08) : accentColor.opacity(0.10))
                        .clipShape(Circle())

                    Spacer(minLength: 0)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: 0x151515))
                    }
                }

                Text(profile.title)
                    .font(Font.custom("Georgia-Bold", size: 17))
                    .foregroundColor(isSelected ? Color(hex: 0x151515) : primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text("\(formattedRatioValue(profile.coffeeGrams)) g · 1:\(formattedRatioValue(profile.ratio)) · \(profile.time)")
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(AppLocalization.letterSpacing(0.8))
                    .textCase(.uppercase)
                    .foregroundColor(isSelected ? Color(hex: 0x151515).opacity(0.75) : accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
            .background(isSelected ? accentColor : accentColor.opacity(0.07))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(accentColor.opacity(isSelected ? 0 : 0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func guideProfileDetail(_ profile: BrewGuideProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile.title)
                        .font(Font.custom("Georgia-Bold", size: isCompact ? 24 : 28))
                        .foregroundColor(primaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(profile.subtitle)
                        .font(bodyFont)
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                Button {
                    applyGuideProfile(profile, start: true)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x151515))
                        .frame(width: 42, height: 42)
                        .background(accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(AppLocalization.text("start_guided_brew", fallback: "Start a Guided Brew"))
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], spacing: 8) {
                guideMetric(title: AppLocalization.text("coffee_grams", fallback: "Coffee (g)"), value: "\(formattedRatioValue(profile.coffeeGrams)) g", systemImage: "scalemass.fill")
                guideMetric(title: AppLocalization.text("ratio", fallback: "Ratio"), value: "1:\(formattedRatioValue(profile.ratio))", systemImage: "drop.fill")
                guideMetric(title: AppLocalization.text("grind", fallback: "Grind"), value: profile.grind, systemImage: "circle.grid.3x3.fill")
                guideMetric(title: AppLocalization.text("temperature", fallback: "Temp"), value: profile.temperature, systemImage: "thermometer.medium")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(AppLocalization.text("learn_why", fallback: "Learn why"))
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(AppLocalization.letterSpacing(1.8))
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)

                ForEach(profile.learningNotes, id: \.self) { note in
                    Label(note, systemImage: "lightbulb.fill")
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedGuideProfileID == profile.id },
                    set: { expandedGuideProfileID = $0 ? profile.id : nil }
                )
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(profile.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(index + 1)")
                                .font(Font.custom("AvenirNext-Bold", size: 11))
                                .foregroundColor(Color(hex: 0x151515))
                                .frame(width: 24, height: 24)
                                .background(accentColor)
                                .clipShape(Circle())

                            Text(step)
                                .font(Font.custom("AvenirNext-Regular", size: 13))
                                .foregroundColor(secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 8)
            } label: {
                Text(AppLocalization.text("show_brew_steps", fallback: "Show brew steps"))
                    .font(Font.custom("AvenirNext-Bold", size: 11))
                    .tracking(AppLocalization.letterSpacing(1.2))
                    .textCase(.uppercase)
                    .foregroundColor(accentColor)
            }
        }
        .padding(14)
        .background(accentColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    func guideMetric(title: String, value: String, systemImage: String) -> some View {
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
                    .tracking(AppLocalization.letterSpacing(1.1))
                    .textCase(.uppercase)
                    .foregroundColor(tertiaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(value)
                    .font(Font.custom("AvenirNext-Bold", size: 13))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.74)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(cardFillColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func brewCoachCard(for profile: BrewGuideProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.10))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("ai_brew_coach", fallback: "AI Brew Coach"))
                        .font(Font.custom("AvenirNext-Bold", size: 11))
                        .tracking(AppLocalization.letterSpacing(1.6))
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)

                    Text(AppLocalization.text("ai_brew_coach_detail", fallback: "Ask how to tune sweetness, body, acidity, grind, or timing."))
                        .font(Font.custom("AvenirNext-Regular", size: 13))
                        .foregroundColor(secondaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: isCompact ? 132 : 154), spacing: 8)], spacing: 8) {
                ForEach(brewCoachSuggestions, id: \.self) { suggestion in
                    brewCoachSuggestionButton(suggestion, profile: profile)
                }
            }

            HStack(spacing: 8) {
                TextField(AppLocalization.text("brew_coach_placeholder", fallback: "Example: make it sweeter"), text: $brewCoachQuestion)
                    .font(Font.custom("AvenirNext-Regular", size: 13))
                    .foregroundColor(primaryTextColor)
                    .submitLabel(.done)
                    .onSubmit {
                        Task { await generateBrewCoachAnswer(for: profile) }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(cardFillColor)
                    .clipShape(Capsule(style: .continuous))

                Button {
                    Task { await generateBrewCoachAnswer(for: profile) }
                } label: {
                    Image(systemName: isGeneratingBrewCoachAnswer ? "hourglass" : "arrow.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: 0x151515))
                        .frame(width: 40, height: 40)
                        .background(accentColor)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isGeneratingBrewCoachAnswer)
            }

            if let brewCoachAnswer {
                Text(brewCoachAnswer)
                    .font(Font.custom("AvenirNext-Regular", size: 14))
                    .foregroundColor(primaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(14)
        .background(accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    var brewCoachSuggestions: [String] {
        [
            AppLocalization.text("brew_prompt_sweeter", fallback: "Make it sweeter"),
            AppLocalization.text("brew_prompt_reduce_acidity", fallback: "Reduce acidity"),
            AppLocalization.text("brew_prompt_more_body", fallback: "More body"),
            AppLocalization.text("brew_prompt_too_fast", fallback: "Brew finished too fast"),
            AppLocalization.text("brew_prompt_too_slow", fallback: "Brew finished too slowly")
        ]
    }

    func brewCoachSuggestionButton(_ suggestion: String, profile: BrewGuideProfile) -> some View {
        Button {
            brewCoachQuestion = suggestion
            Task { await generateBrewCoachAnswer(for: profile) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .bold))

                Text(suggestion)
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(AppLocalization.letterSpacing(0.7))
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }
            .foregroundColor(primaryTextColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(cardFillColor)
            .overlay(
                Capsule(style: .continuous)
                    .stroke(accentColor.opacity(0.16), lineWidth: 1)
            )
            .clipShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isGeneratingBrewCoachAnswer)
    }

    var pouringProgressView: some View {
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

    var guidedBrewSetupSummary: some View {
        VStack(spacing: 10) {
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

            if let activeSmartRecipe {
                HStack(spacing: 10) {
                    guidedBrewSetupMetric(
                        title: AppLocalization.text("grind", fallback: "Grind"),
                        value: activeSmartRecipe.grind,
                        systemImage: "circle.grid.3x3.fill"
                    )

                    guidedBrewSetupMetric(
                        title: AppLocalization.text("temperature", fallback: "Temp"),
                        value: activeSmartRecipe.temperature,
                        systemImage: "thermometer.medium"
                    )
                }
            }
        }
    }

    func guidedBrewSetupMetric(title: String, value: String, systemImage: String) -> some View {
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
                    .tracking(AppLocalization.letterSpacing(1.2))
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

    var focusedBrewModeView: some View {
        ZStack {
            brewBackgroundColor
            .ignoresSafeArea()

            if (brewModeElapsedSeconds >= brewModeTotalSeconds || didCompleteBrewFromScale) && !isBrewModeRunning {
                focusedAfterBrewView
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                focusedLiveBrewView
                    .transition(.opacity)
            }
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
        .confirmationDialog(
            AppLocalization.text("restart_brew_question", fallback: "Restart this brew?"),
            isPresented: $isBrewRestartConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(AppLocalization.text("restart_brew", fallback: "Restart Brew"), role: .destructive) {
                restartBrewMode()
            }

            Button(AppLocalization.text("cancel", fallback: "Cancel"), role: .cancel) { }
        } message: {
            Text(AppLocalization.text("restart_brew_detail", fallback: "Timer and step progress will return to the beginning."))
        }
        .sensoryFeedback(.selection, trigger: brewModeHapticTrigger)
        .toolbar(.hidden, for: .tabBar)
        .fullScreenCover(isPresented: $isScalePickerPresented) {
            floatingBluetoothScalePicker {
                isScalePickerPresented = false
            }
            .presentationBackground(.clear)
        }
    }

    var focusedLiveBrewView: some View {
        GeometryReader { proxy in
            // The folded Duo outer display is a compact landscape window
            // (roughly 740 points wide), so it must use the landscape brew
            // workspace instead of the vertically scrolling phone layout.
            let isLandscape = proxy.size.width > proxy.size.height
            Group {
                if isLandscape {
                    focusedDuoLandscapeLiveBrewView
                } else {
                    focusedPortraitLiveBrewView
                }
            }
            .frame(maxWidth: 1180, maxHeight: .infinity, alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, isLandscape ? 12 : 16)
            .safeAreaPadding(.top, isLandscape ? 8 : 6)
            .safeAreaPadding(.bottom, isLandscape ? 10 : 8)
        }
    }

    var focusedDuoPortraitLiveBrewView: some View {
        VStack(alignment: .leading, spacing: 6) {
            focusedBrewTopArea
            focusedBrewTimeline

            Group {
                if brewModeElapsedSeconds == 0 && !isBrewModeRunning {
                    focusedDuoPortraitPrepareContent
                } else {
                    focusedDuoPortraitActiveContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Spacer(minLength: 4)
            focusedBrewControls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    var focusedDuoPortraitPrepareContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppLocalization.text("prepare", fallback: "Prepare"))
                .font(brewEyebrowFont)
                .foregroundColor(brewAccentColor)

            Text(AppLocalization.text("rinse_and_preheat", fallback: "Rinse and preheat"))
                .font(Font.custom("Georgia-Bold", size: 30))
                .foregroundColor(brewPrimaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(AppLocalization.text("rinse_preheat_explanation", fallback: "Rinse the filter, warm the brewer, and discard the rinse water."))
                .font(Font.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            focusedScaleSetupCard

            Button {
                if scaleManager.isConnected { tareConnectedScale() }
                startBrewModeSession()
            } label: {
                Label(
                    scaleManager.isConnected
                        ? AppLocalization.text("tare_and_start", fallback: "Tare & Start")
                        : AppLocalization.text("ready", fallback: "Ready"),
                    systemImage: scaleManager.isConnected ? "arrow.counterclockwise" : "play.fill"
                )
                .font(Font.custom("AvenirNext-DemiBold", size: 13))
                .foregroundColor(Color(hex: 0x1C1A17))
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(brewAccentColor)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    var focusedDuoPortraitActiveContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentBrewPhaseName)
                        .font(brewEyebrowFont)
                        .foregroundColor(brewAccentColor)
                    Text(formattedTimerTime(brewModeElapsedSeconds))
                        .font(Font.custom("AvenirNext-DemiBold", size: 54))
                        .monospacedDigit()
                        .foregroundColor(brewPrimaryTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
                Text(primaryWaterTargetText)
                    .font(Font.custom("Georgia-Bold", size: 28))
                    .foregroundColor(brewPrimaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Text(focusedBrewGuidanceText)
                .font(Font.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            if scaleManager.isConnected {
                focusedScaleLiveCard
            }

            focusedDuoCompactMetricRows

            focusedNextStepPreview
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    var focusedDuoCompactMetricRows: some View {
        VStack(spacing: 0) {
            focusedDuoCompactMetricRow(title: AppLocalization.text("target", fallback: "Target"), value: "\(formattedWholeGram(currentWaterTarget)) g")
            focusedDuoCompactMetricRow(title: AppLocalization.text("added_this_step", fallback: "Added this step"), value: "\(formattedWholeGram(waterAddedThisStep)) g")
            focusedDuoCompactMetricRow(title: AppLocalization.text("suggested_flow", fallback: "Suggested flow"), value: currentSuggestedFlow)
            focusedDuoCompactMetricRow(title: AppLocalization.text("target_completion_time", fallback: "Target completion time"), value: currentTargetCompletionTime)

            if currentBrewPhaseName == AppLocalization.text("bloom", fallback: "Bloom") {
                focusedDuoCompactMetricRow(title: AppLocalization.text("bloom_duration", fallback: "Bloom duration"), value: focusedBloomDurationText)
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

    func focusedDuoCompactMetricRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 9))
                .tracking(AppLocalization.letterSpacing(0.8))
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)

            Spacer(minLength: 8)

            Text(value)
                .font(Font.custom("AvenirNext-DemiBold", size: 13))
                .foregroundColor(brewPrimaryTextColor)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        }
        .frame(minHeight: 32)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(brewBorderColor.opacity(0.7))
                .frame(height: 1)
        }
        .accessibilityElement(children: .combine)
    }

    var focusedDuoLandscapeLiveBrewView: some View {
        VStack(alignment: .leading, spacing: 8) {
            focusedBrewTopArea

            focusedBrewTimeline

            HStack(alignment: .top, spacing: 16) {
                Group {
                    if brewModeElapsedSeconds == 0 && !isBrewModeRunning {
                        focusedDuoPortraitPrepareContent
                    } else {
                        focusedDuoLandscapeActiveContent
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                focusedBrewControls
                    .frame(width: 214, alignment: .top)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea(.container, edges: .horizontal)
    }

    var focusedDuoLandscapeActiveContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentBrewPhaseName)
                        .font(brewEyebrowFont)
                        .foregroundColor(brewAccentColor)

                    Text(formattedTimerTime(brewModeElapsedSeconds))
                        .font(Font.custom("AvenirNext-DemiBold", size: 64))
                        .monospacedDigit()
                        .foregroundColor(brewPrimaryTextColor)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }

                Spacer(minLength: 8)

                Text(primaryWaterTargetText)
                    .font(Font.custom("Georgia-Bold", size: 28))
                    .foregroundColor(brewPrimaryTextColor)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AppLocalization.text("elapsed_timer", fallback: "Elapsed timer"))
            .accessibilityValue("\(formattedTimerTime(brewModeElapsedSeconds)), \(currentBrewPhaseName)")

            Text(focusedBrewGuidanceText)
                .font(Font.custom("AvenirNext-Regular", size: 14))
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            if scaleManager.isConnected {
                focusedScaleLiveCard
            }

            Toggle(isOn: $isVoiceGuidanceEnabled) {
                Label(
                    AppLocalization.text("voice_guidance", fallback: "Voice guidance"),
                    systemImage: "speaker.wave.2.fill"
                )
                .font(Font.custom("AvenirNext-DemiBold", size: 12))
                .foregroundColor(brewPrimaryTextColor)
            }
            .tint(brewAccentColor)
            .accessibilityIdentifier("guided-brew.voice-guidance")

            focusedBrewMetricRows
                .frame(maxHeight: 190)

            focusedNextStepPreview
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    var focusedPortraitLiveBrewView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                focusedBrewTopArea

                focusedBrewTimeline
                    .padding(.top, 4)

                if brewModeElapsedSeconds == 0 && !isBrewModeRunning {
                    focusedPrepareBrewContent
                        .transition(.opacity)
                } else {
                    focusedActiveBrewContent
                        .transition(.opacity)
                }

            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(.bottom, 20)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            focusedBrewControls
                .padding(.top, isCompact ? 6 : 10)
                .padding(.bottom, isCompact ? 2 : 6)
                .background(.ultraThinMaterial)
        }
    }

    var focusedLandscapeLiveBrewView: some View {
        VStack(alignment: .leading, spacing: 0) {
            focusedBrewTopArea

            focusedBrewTimeline
                .padding(.top, 12)

            Spacer(minLength: 14)

            if brewModeElapsedSeconds == 0 && !isBrewModeRunning {
                focusedPrepareBrewContent
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            } else {
                focusedLandscapeActiveBrewContent
                    .transition(.opacity)
            }

            Spacer(minLength: 14)

            focusedBrewControls
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
        }
    }

    var focusedLandscapeActiveBrewContent: some View {
        HStack(alignment: .top, spacing: 34) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(currentBrewPhaseName)
                        .font(brewEyebrowFont)
                        .foregroundColor(brewAccentColor)

                    Text(formattedTimerTime(brewModeElapsedSeconds))
                        .font(Font.custom("AvenirNext-DemiBold", size: 72))
                        .monospacedDigit()
                        .foregroundColor(brewPrimaryTextColor)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(AppLocalization.text("elapsed_timer", fallback: "Elapsed timer"))
                .accessibilityValue("\(formattedTimerTime(brewModeElapsedSeconds)), \(currentBrewPhaseName)")

                VStack(alignment: .leading, spacing: 8) {
                    Text(primaryWaterTargetText)
                        .font(Font.custom("Georgia-Bold", size: 38))
                        .foregroundColor(brewPrimaryTextColor)
                        .monospacedDigit()
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)

                    Text(focusedBrewGuidanceText)
                        .font(Font.custom("AvenirNext-Regular", size: 16))
                        .foregroundColor(brewSecondaryTextColor)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if scaleManager.isConnected {
                    focusedScaleLiveCard
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            VStack(alignment: .leading, spacing: 14) {
                focusedBrewMetricRows
                focusedNextStepPreview
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    var focusedBrewTopArea: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                requestEndFocusedBrew()
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

            VStack(alignment: .leading, spacing: 5) {
                Text(currentBrewRecipeTitle)
                    .font(Font.custom("AvenirNext-DemiBold", size: 16))
                    .foregroundColor(brewPrimaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Text(displayCoffeeName)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(brewSecondaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)

            Button {
                if scaleManager.isConnected {
                    tareConnectedScale()
                } else {
                    isScalePickerPresented = true
                }
            } label: {
                VStack(spacing: 1) {
                    Image(systemName: scaleManager.isConnected ? "scalemass.fill" : "scalemass")
                        .font(.system(size: 13, weight: .semibold))

                    Text(
                        scaleManager.isConnected
                            ? AppLocalization.text("tare", fallback: "Tare")
                            : AppLocalization.text("scale", fallback: "Scale")
                    )
                    .font(Font.custom("AvenirNext-DemiBold", size: 7))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
                .foregroundColor(scaleManager.isConnected ? brewAccentColor : brewPrimaryTextColor)
                .frame(width: 44, height: 44)
                .background(brewSurfaceColor)
                .overlay(
                    Circle()
                        .stroke(scaleManager.isConnected ? brewAccentColor.opacity(0.65) : brewBorderColor, lineWidth: 1)
                )
                .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                scaleManager.isConnected
                    ? AppLocalization.text("tare_connected_scale", fallback: "Tare connected scale")
                    : AppLocalization.text("connect_bluetooth_scale", fallback: "Connect Bluetooth scale")
            )

            Text(String(format: AppLocalization.text("step_count_format", fallback: "Step %1$d of %2$d"), currentBrewModeStepIndex + 1, brewModeSteps.count))
                .font(Font.custom("AvenirNext-DemiBold", size: 11))
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Menu {
                Button {
                    isBrewRestartConfirmationPresented = true
                } label: {
                    Label(AppLocalization.text("restart", fallback: "Restart"), systemImage: "arrow.counterclockwise")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .frame(width: 44, height: 44)
                    .background(brewSurfaceColor)
                    .overlay(
                        Circle()
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .accessibilityLabel(AppLocalization.text("more", fallback: "More"))
        }
    }

    var focusedPrepareBrewContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(AppLocalization.text("prepare", fallback: "Prepare"))
                .font(brewEyebrowFont)
                .foregroundColor(brewAccentColor)

            VStack(alignment: .leading, spacing: 10) {
                Text(AppLocalization.text("rinse_and_preheat", fallback: "Rinse and preheat"))
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 36 : 48))
                    .foregroundColor(brewPrimaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(AppLocalization.text("rinse_preheat_explanation", fallback: "Rinse the filter, warm the brewer, and discard the rinse water."))
                    .font(Font.custom("AvenirNext-Regular", size: 17))
                    .foregroundColor(brewSecondaryTextColor)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            focusedScaleSetupCard

            Button {
                if scaleManager.isConnected {
                    tareConnectedScale()
                }
                startBrewModeSession()
            } label: {
                Label(
                    scaleManager.isConnected
                        ? AppLocalization.text("tare_and_start", fallback: "Tare & Start")
                        : AppLocalization.text("ready", fallback: "Ready"),
                    systemImage: scaleManager.isConnected ? "arrow.counterclockwise" : "play.fill"
                )
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(Color(hex: 0x1C1A17))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(brewAccentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityHint(AppLocalization.text("starts_guided_brew_timer", fallback: "Starts the guided brew timer."))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var focusedActiveBrewContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(currentBrewPhaseName)
                    .font(brewEyebrowFont)
                    .foregroundColor(brewAccentColor)

                Text(formattedTimerTime(brewModeElapsedSeconds))
                    .font(Font.custom("AvenirNext-DemiBold", size: isCompact ? 74 : 104))
                    .monospacedDigit()
                    .foregroundColor(brewPrimaryTextColor)
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(AppLocalization.text("elapsed_timer", fallback: "Elapsed timer"))
            .accessibilityValue("\(formattedTimerTime(brewModeElapsedSeconds)), \(currentBrewPhaseName)")

            VStack(alignment: .leading, spacing: 12) {
                Text(primaryWaterTargetText)
                    .font(Font.custom("Georgia-Bold", size: isCompact ? 38 : 52))
                    .foregroundColor(brewPrimaryTextColor)
                    .monospacedDigit()
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                Text(focusedBrewGuidanceText)
                    .font(Font.custom("AvenirNext-Regular", size: 17))
                    .foregroundColor(brewSecondaryTextColor)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if scaleManager.isConnected {
                focusedScaleLiveCard
            }

            focusedBrewMetricRows
            focusedNextStepPreview
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var focusedBrewMetricRows: some View {
        VStack(spacing: 0) {
            focusedMetricRow(title: AppLocalization.text("target", fallback: "Target"), value: "\(formattedWholeGram(currentWaterTarget)) g")
            focusedMetricRow(title: AppLocalization.text("added_this_step", fallback: "Added this step"), value: "\(formattedWholeGram(waterAddedThisStep)) g")
            focusedMetricRow(title: AppLocalization.text("suggested_flow", fallback: "Suggested flow"), value: currentSuggestedFlow)
            focusedMetricRow(title: AppLocalization.text("target_completion_time", fallback: "Target completion time"), value: currentTargetCompletionTime)

            if currentBrewPhaseName == AppLocalization.text("bloom", fallback: "Bloom") {
                focusedMetricRow(title: AppLocalization.text("bloom_duration", fallback: "Bloom duration"), value: focusedBloomDurationText)
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

    var focusedScaleSetupCard: some View {
        HStack(spacing: 12) {
            Image(systemName: scaleManager.isConnected ? "checkmark.circle.fill" : "scalemass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(scaleManager.isConnected ? brewAccentColor : brewSecondaryTextColor)

            VStack(alignment: .leading, spacing: 3) {
                Text(scaleManager.connectedScaleName ?? AppLocalization.text("bluetooth_scale", fallback: "Bluetooth Scale"))
                    .font(Font.custom("AvenirNext-DemiBold", size: 14))
                    .foregroundColor(brewPrimaryTextColor)

                Text(scaleManager.isConnected
                    ? AppLocalization.text("scale_connected_live", fallback: "Connected · live weight ready")
                    : AppLocalization.text("scale_connect_live", fallback: "Connect for live weight and flow"))
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(brewSecondaryTextColor)
            }

            Spacer(minLength: 8)

            if scaleManager.isConnected {
                Button(AppLocalization.text("tare", fallback: "Tare")) {
                    tareConnectedScale()
                }
                .font(Font.custom("AvenirNext-DemiBold", size: 13))
                .foregroundColor(brewAccentColor)
            } else {
                Button(AppLocalization.text("connect", fallback: "Connect")) {
                    isScalePickerPresented = true
                }
                .font(Font.custom("AvenirNext-DemiBold", size: 13))
                .foregroundColor(brewAccentColor)
            }
        }
        .padding(14)
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(brewBorderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    var focusedScaleLiveCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 0) {
            scaleLiveMetric(
                title: AppLocalization.text("live_weight", fallback: "Live weight"),
                value: String(format: "%.1f g", scaleManager.weightGrams)
            )

            Rectangle()
                .fill(brewBorderColor)
                .frame(width: 1, height: 42)

            scaleLiveMetric(
                title: AppLocalization.text("to_target", fallback: "To target"),
                value: String(format: "%.1f g", max(currentWaterTarget - scaleManager.weightGrams, 0))
            )

            Rectangle()
                .fill(brewBorderColor)
                .frame(width: 1, height: 42)

            scaleLiveMetric(
                title: AppLocalization.text("flow", fallback: "Flow"),
                value: String(format: "%.1f g/s", scaleManager.flowRateGramsPerSecond)
            )
            }
            .padding(.vertical, 12)
            if capturedBrewSamples.contains(where: { $0.kind == .weight }) {
                BrewTelemetryChart(samples: capturedBrewSamples, accent: brewAccentColor)
                    .frame(height: isCompact ? 92 : 120)
            }
        }
        .padding(10)
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(brewAccentColor.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

}
