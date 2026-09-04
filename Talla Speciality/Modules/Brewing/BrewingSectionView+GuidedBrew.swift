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
                        Text("\(AppLocalization.text("method", fallback: "Method")): \(currentBrewRecipeTitle)")
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
                    .tracking(1.5)
                    .textCase(.uppercase)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
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
                    .foregroundColor(Color(hex: 0x0A0804))
                    .frame(width: 38, height: 38)
                    .background(accentColor)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 5) {
                    Text(AppLocalization.text("smart_brew_guide", fallback: "Smart Brew Guide"))
                        .font(sectionTitleFont)
                        .tracking(2.2)
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
                .tracking(1.8)
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
                .tracking(1.8)
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
                        .tracking(1.1)
                        .textCase(.uppercase)
                        .foregroundColor(accentColor)
                }

                Text(recipe.title)
                    .font(Font.custom("Georgia-Bold", size: 16))
                    .foregroundColor(primaryTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(recipe.detail)
                    .font(Font.custom("AvenirNext-Regular", size: 12))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(width: 184, alignment: .leading)
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
                        .foregroundColor(isSelected ? Color(hex: 0x0A0804) : accentColor)
                        .frame(width: 30, height: 30)
                        .background(isSelected ? Color(hex: 0x0A0804).opacity(0.08) : accentColor.opacity(0.10))
                        .clipShape(Circle())

                    Spacer(minLength: 0)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(hex: 0x0A0804))
                    }
                }

                Text(profile.title)
                    .font(Font.custom("Georgia-Bold", size: 17))
                    .foregroundColor(isSelected ? Color(hex: 0x0A0804) : primaryTextColor)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                Text("\(formattedRatioValue(profile.coffeeGrams)) g · 1:\(formattedRatioValue(profile.ratio)) · \(profile.time)")
                    .font(Font.custom("AvenirNext-Bold", size: 10))
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundColor(isSelected ? Color(hex: 0x0A0804).opacity(0.75) : accentColor)
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
                        .foregroundColor(Color(hex: 0x0A0804))
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
                    .tracking(1.8)
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
                                .foregroundColor(Color(hex: 0x0A0804))
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
                    .tracking(1.2)
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
                    .tracking(1.1)
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
                        .tracking(1.6)
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
                        .foregroundColor(Color(hex: 0x0A0804))
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
                    .tracking(0.7)
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
            let usesLandscapeLayout = proxy.size.width >= 900 && proxy.size.width > proxy.size.height

            Group {
                if usesLandscapeLayout {
                    focusedLandscapeLiveBrewView
                } else {
                    focusedPortraitLiveBrewView
                }
            }
            .frame(maxWidth: usesLandscapeLayout ? 1180 : 820, maxHeight: .infinity, alignment: .top)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, usesLandscapeLayout ? 32 : 22)
            .safeAreaPadding(.top, 10)
            .safeAreaPadding(.bottom, 14)
        }
    }

    var focusedPortraitLiveBrewView: some View {
        VStack(alignment: .leading, spacing: 0) {
            focusedBrewTopArea

            focusedBrewTimeline
                .padding(.top, 20)

            Spacer(minLength: 22)

            if brewModeElapsedSeconds == 0 && !isBrewModeRunning {
                focusedPrepareBrewContent
                    .transition(.opacity)
            } else {
                focusedActiveBrewContent
                    .transition(.opacity)
            }

            Spacer(minLength: 22)

            focusedBrewControls
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
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(brewAccentColor.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func tareConnectedScale() {
        guard scaleManager.isConnected else {
            isScalePickerPresented = true
            return
        }

        scaleManager.tare()
        brewStepHaptic(strong: false)
    }

    func scaleLiveMetric(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .font(Font.custom("AvenirNext-DemiBold", size: 9))
                .textCase(.uppercase)
                .foregroundColor(brewSecondaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .font(Font.custom("AvenirNext-DemiBold", size: 15))
                .monospacedDigit()
                .foregroundColor(brewPrimaryTextColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    func bluetoothScalePicker(onDone: @escaping () -> Void) -> some View {
        NavigationStack {
            ZStack {
                brewBackgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        bluetoothScalePickerHero
                        bluetoothScalePickerStatus

                        if !scaleManager.discoveredScales.isEmpty && !scaleManager.isConnected {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(AppLocalization.text("nearby_scales", fallback: "Nearby scales"))
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(brewPrimaryTextColor)

                                    Spacer()

                                    Button {
                                        scaleManager.scan()
                                    } label: {
                                        Label(AppLocalization.text("refresh", fallback: "Refresh"), systemImage: "arrow.clockwise")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(brewAccentColor)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(scaleManager.connectionState == .scanning)
                                }

                                ForEach(scaleManager.discoveredScales) { scale in
                                    bluetoothScaleDeviceRow(scale)
                                }
                            }
                        }

                        bluetoothScalePickerFootnote
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle(AppLocalization.text("bluetooth_scale", fallback: "Bluetooth scale"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppLocalization.text("done", fallback: "Done")) {
                        onDone()
                    }
                }
            }
            .tint(brewAccentColor)
            .task {
                if !scaleManager.isConnected {
                    scaleManager.scan()
                }
            }
            .onDisappear {
                scaleManager.stopScanning()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(brewBackgroundColor)
    }

    func floatingBluetoothScalePicker(onDone: @escaping () -> Void) -> some View {
        GeometryReader { proxy in
            let panelHeight = min(max(proxy.size.height * 0.66, 560), proxy.size.height - 28)

            ZStack(alignment: .bottom) {
                Color.black.opacity(0.46)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onDone()
                    }

                bluetoothScalePicker(onDone: onDone)
                    .frame(height: panelHeight)
                    .background(brewBackgroundColor)
                    .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .stroke(Color.white.opacity(brewingColorScheme == .dark ? 0.10 : 0.58), lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.24), radius: 24, x: 0, y: 10)
                    .padding(.horizontal, 14)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom, 8))
            }
        }
        .ignoresSafeArea()
    }

    var bluetoothScalePickerHero: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [brewAccentColor.opacity(0.24), brewAccentColor.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 23, weight: .semibold))
                        .foregroundColor(brewAccentColor)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalization.text("brew_companion", fallback: "Brew companion"))
                        .font(brewEyebrowFont)
                        .tracking(1.8)
                        .foregroundColor(brewAccentColor)

                    Text(AppLocalization.text("live_measurements_less_guesswork", fallback: "Live measurements, less guesswork"))
                        .font(Font.custom("Georgia-Bold", size: 21))
                        .foregroundColor(brewPrimaryTextColor)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(AppLocalization.text("scale_connect_detail", fallback: "Connect once for live weight, flow rate and quick tare throughout every guided brew."))
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(brewSecondaryTextColor)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(scaleBrandLogoAssets, id: \.self) { assetName in
                    scaleBrandBadge(assetName: assetName)
                        .frame(maxWidth: 74, maxHeight: 18)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .padding(.horizontal, 8)
                        .background(brewAccentColor.opacity(0.085))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .accessibilityLabel(scaleBrandDisplayName(forLogoAsset: assetName))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    var bluetoothScalePickerStatus: some View {
        switch scaleManager.connectionState {
        case .connected(let name):
            VStack(spacing: 14) {
                scalePickerStatusCard(
                    icon: "checkmark.circle.fill",
                    title: name,
                    detail: AppLocalization.text("connected_ready_next_brew", fallback: "Connected and ready for your next brew"),
                    tint: brewAccentColor
                )

                HStack(spacing: 0) {
                    scalePickerLiveMetric(
                        label: AppLocalization.text("weight", fallback: "Weight"),
                        value: String(format: "%.1f", scaleManager.weightGrams),
                        unit: "g"
                    )

                    Rectangle()
                        .fill(brewBorderColor)
                        .frame(width: 1, height: 38)

                    scalePickerLiveMetric(
                        label: AppLocalization.text("flow_rate", fallback: "Flow rate"),
                        value: String(format: "%.1f", scaleManager.flowRateGramsPerSecond),
                        unit: "g/s"
                    )
                }
                .padding(.vertical, 12)
                .background(brewSurfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(brewBorderColor, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                HStack(spacing: 10) {
                    Button {
                        scaleManager.tare()
                    } label: {
                        Label(AppLocalization.text("tare", fallback: "Tare"), systemImage: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity, minHeight: 42)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)
                    .background(brewSurfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(brewBorderColor, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    Button(role: .destructive) {
                        scaleManager.disconnect()
                    } label: {
                        Text(AppLocalization.text("disconnect", fallback: "Disconnect"))
                            .frame(maxWidth: .infinity, minHeight: 42)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.red.opacity(0.82))
                    .background(Color.red.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

        case .scanning:
            scalePickerStatusCard(
                icon: "dot.radiowaves.left.and.right",
                title: AppLocalization.text("looking_for_scales", fallback: "Looking for scales"),
                detail: AppLocalization.text("keep_scale_awake", fallback: "Keep your scale awake and close to this iPhone."),
                tint: brewAccentColor,
                showsProgress: true
            )

        case .connecting(let name):
            scalePickerStatusCard(
                icon: "link",
                title: String(format: AppLocalization.text("connecting_to_format", fallback: "Connecting to %@"), name),
                detail: AppLocalization.text("connection_takes_moment", fallback: "This usually takes only a moment."),
                tint: brewAccentColor,
                showsProgress: true
            )

        case .failed(let message):
            VStack(spacing: 12) {
                scalePickerStatusCard(
                    icon: "exclamationmark.triangle.fill",
                    title: message.hasPrefix("No supported scale")
                        ? AppLocalization.text("no_scales_found", fallback: "No scales found")
                        : AppLocalization.text("connection_issue", fallback: "Connection issue"),
                    detail: message,
                    tint: Color.orange
                )
                scalePickerScanButton(title: AppLocalization.text("scan_again", fallback: "Scan again"))
            }

        case .disconnected:
            if scaleManager.discoveredScales.isEmpty {
                VStack(spacing: 12) {
                    scalePickerStatusCard(
                        icon: "power",
                        title: AppLocalization.text("scale_ready_when_you_are", fallback: "Ready when you are"),
                        detail: AppLocalization.text("scale_turn_on_detail", fallback: "Turn on your scale, then scan for nearby devices."),
                        tint: brewSecondaryTextColor
                    )
                    scalePickerScanButton(title: AppLocalization.text("scan_for_scales", fallback: "Scan for scales"))
                }
            }
        }
    }

    func scalePickerLiveMetric(label: String, value: String, unit: String) -> some View {
        VStack(spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .tracking(0.8)
                .foregroundColor(brewSecondaryTextColor)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(brewPrimaryTextColor)
                    .contentTransition(.numericText())

                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(brewSecondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value) \(unit)")
    }

    func scalePickerStatusCard(
        icon: String,
        title: String,
        detail: String,
        tint: Color,
        showsProgress: Bool = false
    ) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(tint.opacity(0.11))

                if showsProgress {
                    ProgressView()
                        .tint(tint)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(tint)
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(brewPrimaryTextColor)

                Text(detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(brewSecondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(brewSurfaceColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(brewBorderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func scalePickerScanButton(title: String) -> some View {
        Button {
            scaleManager.scan()
        } label: {
            Label(title, systemImage: "arrow.clockwise")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: 0x1C1A17))
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(brewAccentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    func bluetoothScaleDeviceRow(_ scale: DiscoveredCoffeeScale) -> some View {
        Button {
            scaleManager.connect(to: scale.id)
        } label: {
            HStack(spacing: 13) {
                scaleBrandBadge(assetName: scaleBrandLogoAsset(for: scale))
                    .frame(width: 52, height: 22)
                    .frame(width: 68, height: 52)
                    .background(brewAccentColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(scale.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(brewPrimaryTextColor)
                        .lineLimit(1)

                    Text(scale.modelName)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(brewSecondaryTextColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Image(systemName: "arrow.forward")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(brewAccentColor)
                    .frame(width: 30, height: 30)
                    .background(brewAccentColor.opacity(0.09))
                    .clipShape(Circle())
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(brewSurfaceColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(brewBorderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(
            format: AppLocalization.text("connect_to_scale_accessibility_format", fallback: "Connect to %@, %@"),
            scale.name,
            scale.modelName
        ))
    }

    var scaleBrandLogoAssets: [String] {
        [
            "ScaleLogoAcaia",
            "ScaleLogoBookoo",
            "ScaleLogoGoatStory",
            "ScaleLogoHiroia",
            "ScaleLogoMantabrew",
            "ScaleLogoTimemore"
        ]
    }

    @ViewBuilder
    func scaleBrandBadge(assetName: String) -> some View {
        if assetName == "ScaleLogoTimemore" {
            Text("TIMEMORE")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(0.5)
                .foregroundColor(brewAccentColor)
        } else {
            Image(assetName)
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .foregroundColor(brewAccentColor)
        }
    }

    func scaleBrandLogoAsset(for scale: DiscoveredCoffeeScale) -> String {
        if scale.id.hasPrefix("bookoo:") { return "ScaleLogoBookoo" }
        if scale.id.hasPrefix("gina:") { return "ScaleLogoGoatStory" }
        if scale.id.hasPrefix("hiroia:") { return "ScaleLogoHiroia" }
        if scale.id.hasPrefix("mantabrew:") { return "ScaleLogoMantabrew" }
        if scale.id.hasPrefix("timemore:") { return "ScaleLogoTimemore" }
        return "ScaleLogoAcaia"
    }

    func scaleBrandDisplayName(forLogoAsset assetName: String) -> String {
        switch assetName {
        case "ScaleLogoBookoo": return "BOOKOO"
        case "ScaleLogoGoatStory": return "GOAT STORY"
        case "ScaleLogoHiroia": return "HIROIA"
        case "ScaleLogoMantabrew": return "MANTABREW"
        case "ScaleLogoTimemore": return "TIMEMORE"
        default: return "Acaia"
        }
    }

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
                .tracking(1.0)
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
                    .foregroundColor(Color(hex: 0x1C1A17))
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
                .tracking(1.8)
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

            if let revisedRecipeVersionTitle {
                Text(String(format: AppLocalization.text("saved_new_recipe_version", fallback: "Saved as a new version: %@"), revisedRecipeVersionTitle))
                    .font(Font.custom("AvenirNext-DemiBold", size: 12))
                    .foregroundColor(brewAccentColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    var afterBrewActions: some View {
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
                .foregroundColor(isPrimary ? Color(hex: 0x1C1A17) : brewPrimaryTextColor)
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
        guidedBrewCompletedAction(selectedBrewModeMethod, validCoffeeAmount, validRatioValue, validWaterAmount, brewModeElapsedSeconds)
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
                .foregroundColor(isPrimary ? Color(hex: 0x1C1A17) : brewPrimaryTextColor)
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
